`timescale 1ns / 1ps

// =============================================================================
// tb_write_buffer.v — Testbench: NO BUFFER Configuration (WB_DEPTH=0)
// =============================================================================
// Instantiates ONLY the no-buffer processor (WB_DEPTH=0, MEM_LATENCY=8).
// Runs for 25,000 cycles. Expected stall count: ~8000.
// =============================================================================

module tb_write_buffer;

    reg clk;
    reg rst;

    wire stall_0;

    integer stall_count_0;
    integer cycle_count;

    // ---- Processor Instance: No Buffer (DEPTH=0, MEM_LATENCY=8) ----
    pipelined_riscv #(.WB_DEPTH(0), .MEM_LATENCY(8)) CPU_WB0 (
        .clk            (clk),
        .rst            (rst),
        .cache_stall_out(stall_0)
    );

    // ---- Clock generation: 10ns period (100 MHz) ----
    initial clk = 0;
    always #5 clk = ~clk;

    // ---- Stall and cycle counting ----
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count    <= cycle_count + 1;
            if (stall_0) stall_count_0 <= stall_count_0 + 1;
        end
    end

    // ---- Test Sequence ----
    initial begin
        $dumpfile("write_buffer_no_buf.vcd");
        $dumpvars(0, tb_write_buffer);

        stall_count_0 = 0;
        cycle_count   = 0;

        rst = 1;
        #30;
        rst = 0;

        // Run for 250,000 ns = 25,000 cycles
        #250000;

        $display("");
        $display("================================================================");
        $display("     P9: WRITE BUFFER PERFORMANCE — NO BUFFER (WB_DEPTH=0)");
        $display("================================================================");
        $display("  Memory Latency       : 8 cycles");
        $display("  Buffer Depth         : 0 (No Buffer)");
        $display("  Loop iterations      : 200");
        $display("  Stores per iteration : 5");
        $display("  Total store ops      : 1000");
        $display("================================================================");
        $display("");
        $display("  %-25s %10s", "Metric", "No Buffer");
        $display("  %-25s %10s", "-------------------------", "----------");
        $display("  %-25s %10d", "Total Cycles", cycle_count);
        $display("  %-25s %10d", "Cache Stall Cycles", stall_count_0);
        $display("  %-25s %9d%%", "Stall Percentage",
                 (cycle_count > 0) ? (stall_count_0 * 100 / cycle_count) : 0);
        $display("================================================================");

        $display("");
        $display("================================================================");
        $display("  Correctness Check (No Buffer — WB_DEPTH=0)");
        $display("================================================================");
        $display("  x1  (expected  1) = %0d  %s", CPU_WB0.RF.registers[1],
                 (CPU_WB0.RF.registers[1] ==  1) ? "PASS" : "FAIL");
        $display("  x2  (expected  2) = %0d  %s", CPU_WB0.RF.registers[2],
                 (CPU_WB0.RF.registers[2] ==  2) ? "PASS" : "FAIL");
        $display("  x3  (expected  3) = %0d  %s", CPU_WB0.RF.registers[3],
                 (CPU_WB0.RF.registers[3] ==  3) ? "PASS" : "FAIL");
        $display("  x4  (expected  4) = %0d  %s", CPU_WB0.RF.registers[4],
                 (CPU_WB0.RF.registers[4] ==  4) ? "PASS" : "FAIL");
        $display("  x5  (expected  5) = %0d  %s", CPU_WB0.RF.registers[5],
                 (CPU_WB0.RF.registers[5] ==  5) ? "PASS" : "FAIL");
        $display("  x15 (expected  0) = %0d  %s", CPU_WB0.RF.registers[15],
                 (CPU_WB0.RF.registers[15] ==  0) ? "PASS" : "FAIL");
        $display("  x20 (expected  3) = %0d  %s", CPU_WB0.RF.registers[20],
                 (CPU_WB0.RF.registers[20] ==  3) ? "PASS" : "FAIL");
        $display("================================================================");

        $finish;
    end

endmodule
