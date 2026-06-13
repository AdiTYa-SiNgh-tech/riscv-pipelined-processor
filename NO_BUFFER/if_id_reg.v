module if_id_reg (
    input         clk,
    input         rst,
    input         if_id_write,  // 0 = stall (hold), 1 = normal write
    input         flush,        // 1 = insert bubble (NOP)
    input  [31:0] pc_in,
    input  [31:0] pc_plus4_in,
    input  [31:0] instruction_in,
    output reg [31:0] pc_out,
    output reg [31:0] pc_plus4_out,
    output reg [31:0] instruction_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            pc_out          <= 32'd0;
            pc_plus4_out    <= 32'd0;
            instruction_out <= 32'h00000013; // NOP (addi x0, x0, 0)
        end else if (if_id_write) begin
            pc_out          <= pc_in;
            pc_plus4_out    <= pc_plus4_in;
            instruction_out <= instruction_in;
        end
        // else: hold current values (stall)
    end
endmodule
