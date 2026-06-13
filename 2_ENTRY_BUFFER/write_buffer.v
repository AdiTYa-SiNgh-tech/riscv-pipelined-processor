// =============================================================================
// write_buffer.v — Parameterized Circular FIFO Write Buffer with Snoop
// =============================================================================
// DEPTH = 0 : buffer is bypassed (full always asserted, empty always asserted)
// DEPTH = 2 : 2-entry buffer
// DEPTH = 4 : 4-entry buffer
//
// Each entry: {addr[31:0], data[31:0]}
// CAM-style snoop: given a read address, returns newest matching data.
// =============================================================================

module write_buffer #(
    parameter DEPTH = 4
)(
    input             clk,
    input             rst,

    // Enqueue interface (from cache controller on store)
    input             enqueue,
    input      [31:0] enq_addr,
    input      [31:0] enq_data,

    // Dequeue interface (to main memory drain)
    input             dequeue,
    output     [31:0] deq_addr,
    output     [31:0] deq_data,

    // Status
    output            full,
    output            empty,

    // Snoop interface (for read hits in the buffer)
    input      [31:0] snoop_addr,
    output            snoop_hit,
    output     [31:0] snoop_data
);

generate
if (DEPTH == 0) begin : gen_no_buffer
    // ---- Depth-0: no buffer, always full & empty ----
    assign full       = 1'b1;
    assign empty      = 1'b1;
    assign deq_addr   = 32'd0;
    assign deq_data   = 32'd0;
    assign snoop_hit  = 1'b0;
    assign snoop_data = 32'd0;

end else begin : gen_buffer
    // ---- Actual circular buffer ----
    localparam PTR_W = $clog2(DEPTH);

    reg [31:0] buf_addr [0:DEPTH-1];
    reg [31:0] buf_data [0:DEPTH-1];
    reg        buf_valid[0:DEPTH-1];

    reg [PTR_W:0] head;   // points to oldest entry (dequeue side)
    reg [PTR_W:0] tail;   // points to next free slot (enqueue side)
    reg [PTR_W:0] count;  // number of valid entries

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    // Dequeue outputs (head entry)
    assign deq_addr = buf_addr[head[PTR_W-1:0]];
    assign deq_data = buf_data[head[PTR_W-1:0]];

    // ---- Snoop logic (CAM — find newest match) ----
    // Search from tail-1 backwards to head for the first address match
    reg            snoop_found;
    reg [31:0]     snoop_result;
    integer        s;
    reg [PTR_W:0]  scan_idx;

    always @(*) begin
        snoop_found  = 1'b0;
        snoop_result = 32'd0;
        // Scan from newest (tail-1) to oldest (head)
        for (s = 0; s < DEPTH; s = s + 1) begin
            scan_idx = tail - 1 - s;
            if (!snoop_found && (s < count)) begin
                if (buf_valid[scan_idx[PTR_W-1:0]] &&
                    buf_addr[scan_idx[PTR_W-1:0]] == snoop_addr) begin
                    snoop_found  = 1'b1;
                    snoop_result = buf_data[scan_idx[PTR_W-1:0]];
                end
            end
        end
    end

    assign snoop_hit  = snoop_found;
    assign snoop_data = snoop_result;

    // ---- Enqueue / Dequeue logic ----
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            head  <= 0;
            tail  <= 0;
            count <= 0;
            for (i = 0; i < DEPTH; i = i + 1) begin
                buf_valid[i] <= 1'b0;
                buf_addr[i]  <= 32'd0;
                buf_data[i]  <= 32'd0;
            end
        end else begin
            // Simultaneous enq + deq
            if (enqueue && dequeue && !empty) begin
                buf_addr[tail[PTR_W-1:0]]  <= enq_addr;
                buf_data[tail[PTR_W-1:0]]  <= enq_data;
                buf_valid[tail[PTR_W-1:0]] <= 1'b1;
                buf_valid[head[PTR_W-1:0]] <= 1'b0;
                tail <= tail + 1;
                head <= head + 1;
                // count stays the same
            end else begin
                if (enqueue && !full) begin
                    buf_addr[tail[PTR_W-1:0]]  <= enq_addr;
                    buf_data[tail[PTR_W-1:0]]  <= enq_data;
                    buf_valid[tail[PTR_W-1:0]] <= 1'b1;
                    tail  <= tail + 1;
                    count <= count + 1;
                end
                if (dequeue && !empty) begin
                    buf_valid[head[PTR_W-1:0]] <= 1'b0;
                    head  <= head + 1;
                    count <= count - 1;
                end
            end
        end
    end

end
endgenerate

endmodule
