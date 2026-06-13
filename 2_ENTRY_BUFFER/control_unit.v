module control_unit (
    input  [6:0] opcode,
    output reg       reg_write,
    output reg [1:0] mem_to_reg,   // 00=ALU, 01=Mem, 10=PC+4
    output reg       mem_read,
    output reg       mem_write,
    output reg       alu_src,      // 0=rs2, 1=imm
    output reg [1:0] alu_src_a,    // 00=rs1, 01=PC, 10=zero
    output reg       branch,
    output reg       jump,
    output reg       jalr,
    output reg [1:0] alu_op        // 00=ADD, 01=Branch, 10=R-type, 11=I-type
);
    always @(*) begin
        // Defaults
        reg_write  = 0; mem_to_reg = 2'b00; mem_read = 0; mem_write = 0;
        alu_src    = 0; alu_src_a  = 2'b00; branch   = 0; jump     = 0;
        jalr       = 0; alu_op    = 2'b00;

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1; alu_op = 2'b10;
            end
            7'b0010011: begin // I-type ALU
                reg_write = 1; alu_src = 1; alu_op = 2'b11;
            end
            7'b0000011: begin // Load
                reg_write = 1; mem_to_reg = 2'b01; mem_read = 1;
                alu_src = 1; alu_op = 2'b00;
            end
            7'b0100011: begin // Store
                mem_write = 1; alu_src = 1; alu_op = 2'b00;
            end
            7'b1100011: begin // Branch
                branch = 1; alu_op = 2'b01;
            end
            7'b1101111: begin // JAL
                reg_write = 1; mem_to_reg = 2'b10; jump = 1;
            end
            7'b1100111: begin // JALR
                reg_write = 1; mem_to_reg = 2'b10; alu_src = 1;
                jump = 1; jalr = 1; alu_op = 2'b00;
            end
            7'b0110111: begin // LUI
                reg_write = 1; alu_src = 1; alu_src_a = 2'b10;
                alu_op = 2'b00;
            end
            7'b0010111: begin // AUIPC
                reg_write = 1; alu_src = 1; alu_src_a = 2'b01;
                alu_op = 2'b00;
            end
            default: ; // NOP - all zeros
        endcase
    end
endmodule
