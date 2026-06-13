// =============================================================================
// l1_cache.v — 8-Line Direct-Mapped Write-Through L1 Data Cache
// =============================================================================
// Word-granularity (each line = 1 word = 32 bits).
// Index = addr[4:2]  (8 lines → 3 bits)
// Tag   = addr[31:5] (remaining upper bits)
//
// Read:  combinational hit check; returns data on hit.
// Write: updates cache line unconditionally (write-allocate); caller must
//        propagate the write to main memory (write-through policy).
// Fill:  controller can fill a line after a read-miss completes.
// =============================================================================

module l1_cache (
    input             clk,
    input             rst,

    // CPU-side interface
    input      [31:0] addr,
    input      [31:0] wdata,
    input             read_en,
    input             write_en,

    // Hit / data outputs
    output            hit,
    output     [31:0] rdata,

    // Fill interface (from main memory on read miss)
    input             fill_en,
    input      [31:0] fill_data
);

    localparam NUM_LINES = 8;
    localparam IDX_W     = 3;   // log2(8)
    localparam TAG_W     = 27;  // 32 - 3 (index) - 2 (byte offset)

    reg [31:0]     data_array [0:NUM_LINES-1];
    reg [TAG_W-1:0] tag_array [0:NUM_LINES-1];
    reg              valid     [0:NUM_LINES-1];

    wire [IDX_W-1:0] index = addr[4:2];
    wire [TAG_W-1:0] tag   = addr[31:5];

    // ---- Combinational read / hit check ----
    assign hit   = valid[index] && (tag_array[index] == tag);
    assign rdata = data_array[index];

    // ---- Synchronous write / fill ----
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < NUM_LINES; i = i + 1) begin
                valid[i]      <= 1'b0;
                tag_array[i]  <= {TAG_W{1'b0}};
                data_array[i] <= 32'd0;
            end
        end else begin
            if (write_en) begin
                // Write-allocate: update cache line unconditionally
                data_array[index] <= wdata;
                tag_array[index]  <= tag;
                valid[index]      <= 1'b1;
            end else if (fill_en) begin
                // Fill from main memory after read miss
                data_array[index] <= fill_data;
                tag_array[index]  <= tag;
                valid[index]      <= 1'b1;
            end
        end
    end

endmodule
