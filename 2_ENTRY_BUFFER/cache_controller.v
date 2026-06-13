// =============================================================================
// cache_controller.v — FSM Cache Controller
// =============================================================================
// Orchestrates L1 cache, write buffer, and main memory.
//
// States:
//   IDLE       — service hits; background-drain write buffer
//   READ_MISS  — waiting for main memory to return read data
//   WB_DRAIN   — draining one write-buffer entry to main memory (when full
//                or background drain)
//   WRITE_WAIT — write buffer was full on a store; drain one entry first
//
// Parameter WB_DEPTH: 0 = no buffer, 2, or 4.
// =============================================================================

module cache_controller #(
    parameter WB_DEPTH   = 4,
    parameter MEM_LATENCY = 20
)(
    input             clk,
    input             rst,

    // CPU interface (from MEM pipeline stage)
    input             mem_read,
    input             mem_write,
    input      [31:0] addr,
    input      [31:0] wdata,
    output reg [31:0] rdata,
    output reg        stall
);

    // ---- State encoding ----
    localparam S_IDLE       = 3'd0;
    localparam S_READ_MISS  = 3'd1;
    localparam S_WB_DRAIN   = 3'd2;
    localparam S_WRITE_WAIT = 3'd3;
    localparam S_WRITE_ENQ  = 3'd4;

    reg [2:0] state, next_state;

    // ---- L1 Cache signals ----
    wire        cache_hit;
    wire [31:0] cache_rdata;
    reg         cache_read_en;
    reg         cache_write_en;
    reg         cache_fill_en;
    reg  [31:0] cache_fill_data;

    // ---- Write Buffer signals ----
    reg         wb_enqueue;
    reg         wb_dequeue;
    wire        wb_full;
    wire        wb_empty;
    wire [31:0] wb_deq_addr;
    wire [31:0] wb_deq_data;
    wire        wb_snoop_hit;
    wire [31:0] wb_snoop_data;

    // ---- Main Memory signals ----
    reg         mm_req;
    reg         mm_we;
    reg  [31:0] mm_addr;
    reg  [31:0] mm_wdata;
    wire [31:0] mm_rdata;
    wire        mm_ready;

    // ---- Saved request (for multi-cycle operations) ----
    reg         saved_mem_read;
    reg         saved_mem_write;
    reg  [31:0] saved_addr;
    reg  [31:0] saved_wdata;

    // ---- Instantiate sub-modules ----
    l1_cache CACHE (
        .clk       (clk),
        .rst       (rst),
        .addr      (addr),
        .wdata     (wdata),
        .read_en   (cache_read_en),
        .write_en  (cache_write_en),
        .hit       (cache_hit),
        .rdata     (cache_rdata),
        .fill_en   (cache_fill_en),
        .fill_data (cache_fill_data)
    );

    write_buffer #(.DEPTH(WB_DEPTH)) WB (
        .clk        (clk),
        .rst        (rst),
        .enqueue    (wb_enqueue),
        .enq_addr   (addr),
        .enq_data   (wdata),
        .dequeue    (wb_dequeue),
        .deq_addr   (wb_deq_addr),
        .deq_data   (wb_deq_data),
        .full       (wb_full),
        .empty      (wb_empty),
        .snoop_addr (addr),
        .snoop_hit  (wb_snoop_hit),
        .snoop_data (wb_snoop_data)
    );

    main_memory #(.LATENCY(MEM_LATENCY)) MMEM (
        .clk   (clk),
        .rst   (rst),
        .req   (mm_req),
        .we    (mm_we),
        .addr  (mm_addr),
        .wdata (mm_wdata),
        .rdata (mm_rdata),
        .ready (mm_ready)
    );

    // ---- FSM: state register ----
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // ---- Save request on transition out of IDLE ----
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            saved_mem_read  <= 0;
            saved_mem_write <= 0;
            saved_addr      <= 0;
            saved_wdata     <= 0;
        end else if (state == S_IDLE) begin
            saved_mem_read  <= mem_read;
            saved_mem_write <= mem_write;
            saved_addr      <= addr;
            saved_wdata     <= wdata;
        end
    end

    // ---- FSM: next state + output logic ----
    always @(*) begin
        // Defaults
        next_state      = state;
        stall           = 1'b0;
        rdata           = 32'd0;
        cache_read_en   = 1'b0;
        cache_write_en  = 1'b0;
        cache_fill_en   = 1'b0;
        cache_fill_data = 32'd0;
        wb_enqueue      = 1'b0;
        wb_dequeue      = 1'b0;
        mm_req          = 1'b0;
        mm_we           = 1'b0;
        mm_addr         = 32'd0;
        mm_wdata        = 32'd0;

        case (state)
            // ==============================================================
            S_IDLE: begin
                if (mem_read) begin
                    cache_read_en = 1'b1;
                    // Check write buffer first (has newest data)
                    if (wb_snoop_hit) begin
                        rdata      = wb_snoop_data;
                        stall      = 1'b0;
                        next_state = S_IDLE;
                    end else if (cache_hit) begin
                        rdata      = cache_rdata;
                        stall      = 1'b0;
                        next_state = S_IDLE;
                    end else begin
                        // Read miss — go fetch from main memory
                        stall      = 1'b1;
                        mm_req     = 1'b1;
                        mm_we      = 1'b0;
                        mm_addr    = addr;
                        next_state = S_READ_MISS;
                    end
                end else if (mem_write) begin
                    // Write: update cache, try to enqueue into write buffer
                    cache_write_en = 1'b1;
                    if (WB_DEPTH == 0) begin
                        // No buffer — must write directly to main memory
                        stall      = 1'b1;
                        mm_req     = 1'b1;
                        mm_we      = 1'b1;
                        mm_addr    = addr;
                        mm_wdata   = wdata;
                        next_state = S_WB_DRAIN;  // reuse drain state to wait for mm_ready
                    end else if (!wb_full) begin
                        // Enqueue into write buffer — no stall!
                        wb_enqueue = 1'b1;
                        stall      = 1'b0;
                        next_state = S_IDLE;
                    end else begin
                        // Buffer full — need to drain one entry first
                        stall      = 1'b1;
                        mm_req     = 1'b1;
                        mm_we      = 1'b1;
                        mm_addr    = wb_deq_addr;
                        mm_wdata   = wb_deq_data;
                        next_state = S_WRITE_WAIT;
                    end
                end else begin
                    // No CPU request — background drain write buffer
                    if (!wb_empty) begin
                        mm_req   = 1'b1;
                        mm_we    = 1'b1;
                        mm_addr  = wb_deq_addr;
                        mm_wdata = wb_deq_data;
                        next_state = S_WB_DRAIN;
                    end
                end
            end

            // ==============================================================
            S_READ_MISS: begin
                stall = 1'b1;
                if (mm_ready) begin
                    // Fill cache line and return data
                    cache_fill_en   = 1'b1;
                    cache_fill_data = mm_rdata;
                    rdata           = mm_rdata;
                    stall           = 1'b0;
                    next_state      = S_IDLE;
                end
            end

            // ==============================================================
            S_WB_DRAIN: begin
                // Background drain or no-buffer direct write
                // If a CPU request comes in during drain, stall it
                if (mm_ready) begin
                    wb_dequeue = 1'b1;
                    stall      = 1'b0;   // Drop stall so pipeline can advance
                    next_state = S_IDLE;
                end else begin
                    stall = (mem_read || mem_write) ? 1'b1 : 1'b0;
                end
            end

            // ==============================================================
            S_WRITE_WAIT: begin
                // Waiting for drain of one entry so we can enqueue the new store
                stall = 1'b1;
                if (mm_ready) begin
                    // Drain the old entry
                    wb_dequeue = 1'b1;
                    // Now enqueue the new store (using saved values)
                    wb_enqueue = 1'b1;
                    stall      = 1'b0;
                    next_state = S_IDLE;
                end
            end

            default: next_state = S_IDLE;
        endcase
    end

endmodule
