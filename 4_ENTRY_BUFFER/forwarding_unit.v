module forwarding_unit (
    input  [4:0] id_ex_rs1,
    input  [4:0] id_ex_rs2,
    // From EX/MEM stage
    input        ex_mem_reg_write,
    input  [4:0] ex_mem_rd,
    // From MEM/WB stage
    input        mem_wb_reg_write,
    input  [4:0] mem_wb_rd,
    // Forwarding select signals
    output reg [1:0] forward_a,  // 00=ID/EX, 10=EX/MEM, 01=MEM/WB
    output reg [1:0] forward_b
);
    // Forward A (for rs1)
    always @(*) begin
        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1))
            forward_a = 2'b10;  // Forward from EX/MEM
        else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs1))
            forward_a = 2'b01;  // Forward from MEM/WB
        else
            forward_a = 2'b00;  // No forwarding
    end

    // Forward B (for rs2)
    always @(*) begin
        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2))
            forward_b = 2'b10;  // Forward from EX/MEM
        else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs2))
            forward_b = 2'b01;  // Forward from MEM/WB
        else
            forward_b = 2'b00;  // No forwarding
    end
endmodule
