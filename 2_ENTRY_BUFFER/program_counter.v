module program_counter (
    input         clk,
    input         rst,
    input         pc_write,   // 0 = stall, 1 = update
    input  [31:0] pc_in,
    output reg [31:0] pc_out
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_out <= 32'h0000_0000;
        else if (pc_write)
            pc_out <= pc_in;
    end
endmodule
