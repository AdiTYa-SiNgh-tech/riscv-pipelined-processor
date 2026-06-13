`timescale 1ns / 1ps

// =============================================================================
// fpga_top.v — Zybo Z7-10 Top-Level: 2-ENTRY BUFFER (WB_DEPTH=2, MEM_LATENCY=5)
// =============================================================================

module fpga_top (
    input  wire       clk_125mhz,
    input  wire       btn_rst,
    output wire [3:0] led
);

    reg [25:0] clk_div;
    always @(posedge clk_125mhz or posedge btn_rst) begin
        if (btn_rst) clk_div <= 26'd0;
        else         clk_div <= clk_div + 1;
    end
    wire proc_clk = clk_div[5];

    wire cache_stall;

    pipelined_riscv #(
        .WB_DEPTH   (2),
        .MEM_LATENCY(5)
    ) CPU (
        .clk            (proc_clk),
        .rst            (btn_rst),
        .cache_stall_out(cache_stall)
    );

    assign led[0] = cache_stall;
    assign led[1] = (CPU.RF.registers[15] == 32'd0);
    assign led[2] = (CPU.RF.registers[20] == 32'd3);
    assign led[3] = clk_div[23];

endmodule
