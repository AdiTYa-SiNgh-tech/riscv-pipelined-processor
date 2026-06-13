module alu_control (
    input  [1:0] alu_op,
    input  [2:0] funct3,
    input  [6:0] funct7,
    output reg [3:0] alu_ctrl
);
    // ALU Operations: 0=ADD, 1=SUB, 2=SLL, 3=SLT, 4=SLTU, 5=XOR, 6=SRL, 7=SRA, 8=OR, 9=AND
    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = 4'd0; // ADD (load/store/LUI/AUIPC/JALR)
            2'b01: alu_ctrl = 4'd1; // SUB (branch comparison - unused by ALU)
            2'b10: begin             // R-type
                case (funct3)
                    3'b000: alu_ctrl = (funct7[5]) ? 4'd1 : 4'd0; // ADD/SUB
                    3'b001: alu_ctrl = 4'd2;  // SLL
                    3'b010: alu_ctrl = 4'd3;  // SLT
                    3'b011: alu_ctrl = 4'd4;  // SLTU
                    3'b100: alu_ctrl = 4'd5;  // XOR
                    3'b101: alu_ctrl = (funct7[5]) ? 4'd7 : 4'd6; // SRA/SRL
                    3'b110: alu_ctrl = 4'd8;  // OR
                    3'b111: alu_ctrl = 4'd9;  // AND
                    default: alu_ctrl = 4'd0;
                endcase
            end
            2'b11: begin             // I-type ALU
                case (funct3)
                    3'b000: alu_ctrl = 4'd0;  // ADDI
                    3'b001: alu_ctrl = 4'd2;  // SLLI
                    3'b010: alu_ctrl = 4'd3;  // SLTI
                    3'b011: alu_ctrl = 4'd4;  // SLTIU
                    3'b100: alu_ctrl = 4'd5;  // XORI
                    3'b101: alu_ctrl = (funct7[5]) ? 4'd7 : 4'd6; // SRAI/SRLI
                    3'b110: alu_ctrl = 4'd8;  // ORI
                    3'b111: alu_ctrl = 4'd9;  // ANDI
                    default: alu_ctrl = 4'd0;
                endcase
            end
            default: alu_ctrl = 4'd0;
        endcase
    end
endmodule
