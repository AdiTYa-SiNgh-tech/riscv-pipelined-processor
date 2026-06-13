`timescale 1ns / 1ps

// =============================================================================
// fpga_top.v — Zybo Z7-10 Top-Level: NO BUFFER (WB_DEPTH=0, MEM_LATENCY=8)
// =============================================================================
// LD0 = stall signal (ON while cache is stalling)
// LD1 = program finished (x15 loop counter == 0)
// LD2 = result correct (x20 == 3)
// LD3 = heartbeat (slow blink — proves clock is alive)
// BTN0 = reset (active high)
// =============================================================================

module fpga_top (
    input  wire       clk_125mhz,   // 125 MHz system clock (Zybo Z7)
    input  wire       btn_rst,      // BTN0 = reset
    output wire [3:0] led           // 4 LEDs
);

    // ---- Clock divider: 125 MHz → ~1.9 MHz processor clock (bit [5]) ----
    reg [25:0] clk_div;
    always @(posedge clk_125mhz or posedge btn_rst) begin
        if (btn_rst) clk_div <= 26'd0;
        else         clk_div <= clk_div + 1;
    end
    (* mark_debug = "true" *) wire proc_clk = clk_div[5]; // ~1.9 MHz — finishes 25k cycles in ~13 ms

    // ---- Processor: No Buffer ----
    (* mark_debug = "true" *) wire cache_stall;

    pipelined_riscv #(
        .WB_DEPTH   (0),
        .MEM_LATENCY(8)
    ) CPU (
        .clk            (proc_clk),
        .rst            (btn_rst),
        .cache_stall_out(cache_stall)
    );

    // ---- LED Outputs ----
    assign led[0] = cache_stall;                              // stall activity
    assign led[1] = (CPU.RF.registers[15] == 32'd0);         // loop done
    assign led[2] = (CPU.RF.registers[20] == 32'd3);         // result correct
    assign led[3] = clk_div[23];                              // heartbeat ~7 Hz

endmodule
