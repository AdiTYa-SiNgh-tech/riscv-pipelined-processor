module id_ex_reg (
    input         clk,
    input         rst,
    input         stall,
    input         flush,
    // Control signals in
    input         reg_write_in,
    input  [1:0]  mem_to_reg_in,
    input         mem_read_in,
    input         mem_write_in,
    input         alu_src_in,
    input  [1:0]  alu_src_a_in,
    input         branch_in,
    input         jump_in,
    input         jalr_in,
    input  [1:0]  alu_op_in,
    // Data in
    input  [31:0] pc_in,
    input  [31:0] pc_plus4_in,
    input  [31:0] read_data1_in,
    input  [31:0] read_data2_in,
    input  [31:0] imm_in,
    input  [4:0]  rs1_in,
    input  [4:0]  rs2_in,
    input  [4:0]  rd_in,
    input  [2:0]  funct3_in,
    input  [6:0]  funct7_in,
    // Control signals out
    output reg        reg_write_out,
    output reg [1:0]  mem_to_reg_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg        alu_src_out,
    output reg [1:0]  alu_src_a_out,
    output reg        branch_out,
    output reg        jump_out,
    output reg        jalr_out,
    output reg [1:0]  alu_op_out,
    // Data out
    output reg [31:0] pc_out,
    output reg [31:0] pc_plus4_out,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] imm_out,
    output reg [4:0]  rs1_out,
    output reg [4:0]  rs2_out,
    output reg [4:0]  rd_out,
    output reg [2:0]  funct3_out,
    output reg [6:0]  funct7_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            reg_write_out  <= 0; mem_to_reg_out <= 0; mem_read_out <= 0;
            mem_write_out  <= 0; alu_src_out    <= 0; alu_src_a_out <= 0;
            branch_out     <= 0; jump_out       <= 0; jalr_out     <= 0;
            alu_op_out     <= 0;
            pc_out         <= 0; pc_plus4_out   <= 0;
            read_data1_out <= 0; read_data2_out <= 0; imm_out      <= 0;
            rs1_out        <= 0; rs2_out        <= 0; rd_out       <= 0;
            funct3_out     <= 0; funct7_out     <= 0;
        end else if (!stall) begin
            reg_write_out  <= reg_write_in;  mem_to_reg_out <= mem_to_reg_in;
            mem_read_out   <= mem_read_in;   mem_write_out  <= mem_write_in;
            alu_src_out    <= alu_src_in;    alu_src_a_out  <= alu_src_a_in;
            branch_out     <= branch_in;     jump_out       <= jump_in;
            jalr_out       <= jalr_in;       alu_op_out     <= alu_op_in;
            pc_out         <= pc_in;         pc_plus4_out   <= pc_plus4_in;
            read_data1_out <= read_data1_in; read_data2_out <= read_data2_in;
            imm_out        <= imm_in;
            rs1_out        <= rs1_in;        rs2_out        <= rs2_in;
            rd_out         <= rd_in;
            funct3_out     <= funct3_in;     funct7_out     <= funct7_in;
        end
    end
endmodule
