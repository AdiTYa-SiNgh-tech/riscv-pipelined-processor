module alu (
    input  [31:0] a,
    input  [31:0] b,
    input  [3:0]  alu_ctrl,
    output reg [31:0] result,
    output        zero
);
    assign zero = (result == 32'd0);

    always @(*) begin
        case (alu_ctrl)
            4'd0:  result = a + b;                              // ADD
            4'd1:  result = a - b;                              // SUB
            4'd2:  result = a << b[4:0];                        // SLL
            4'd3:  result = ($signed(a) < $signed(b)) ? 1 : 0;  // SLT
            4'd4:  result = (a < b) ? 1 : 0;                    // SLTU
            4'd5:  result = a ^ b;                              // XOR
            4'd6:  result = a >> b[4:0];                        // SRL
            4'd7:  result = $signed(a) >>> b[4:0];              // SRA
            4'd8:  result = a | b;                              // OR
            4'd9:  result = a & b;                              // AND
            default: result = 32'd0;
        endcase
    end
endmodule
