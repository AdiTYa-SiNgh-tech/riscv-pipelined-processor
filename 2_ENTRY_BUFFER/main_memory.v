// =============================================================================
// main_memory.v — Simulated Main Memory with Configurable Latency
// =============================================================================
// 256-word (1 KB) memory with parameterizable access latency (default 20 cycles).
// Interface:  req (strobe) + we + addr + wdata  →  rdata + ready
// A new request is accepted only when the unit is IDLE.
// =============================================================================

module main_memory #(
    parameter LATENCY = 20       // Access latency in clock cycles
)(
    input             clk,
    input             rst,
    input             req,       // Request strobe (hold high for 1 cycle)
    input             we,        // Write enable (1 = write, 0 = read)
    input      [31:0] addr,
    input      [31:0] wdata,
    output reg [31:0] rdata,
    output reg        ready      // Pulses high for 1 cycle when done
);

    reg [31:0] mem [0:255];

    // Latency counter
    localparam CNT_W = $clog2(LATENCY + 1);
    reg [CNT_W-1:0] counter;

    // Saved request info
    reg        active;
    reg        saved_we;
    reg [31:0] saved_addr;
    reg [31:0] saved_wdata;

    wire [7:0] word_addr = addr[9:2];
    wire [7:0] saved_word_addr = saved_addr[9:2];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter     <= 0;
            active      <= 0;
            ready       <= 0;
            rdata       <= 32'd0;
            saved_we    <= 0;
            saved_addr  <= 0;
            saved_wdata <= 0;
        end else begin
            ready <= 1'b0;  // default: deassert ready

            if (!active && req) begin
                // Accept a new request
                active      <= 1'b1;
                counter     <= LATENCY - 1;
                saved_we    <= we;
                saved_addr  <= addr;
                saved_wdata <= wdata;
            end else if (active) begin
                if (counter == 0) begin
                    // Latency elapsed — complete the operation
                    if (saved_we)
                        mem[saved_word_addr] <= saved_wdata;
                    else
                        rdata <= mem[saved_word_addr];
                    ready  <= 1'b1;
                    active <= 1'b0;
                end else begin
                    counter <= counter - 1;
                end
            end
        end
    end

endmodule
