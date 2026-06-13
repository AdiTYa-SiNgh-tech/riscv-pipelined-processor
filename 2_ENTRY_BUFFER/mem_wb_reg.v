module mem_wb_reg (
    input         clk,
    input         rst,
    input         stall,
    // Control signals in
    input         reg_write_in,
    input  [1:0]  mem_to_reg_in,
    // Data in
    input  [31:0] alu_result_in,
    input  [31:0] mem_read_data_in,
    input  [31:0] pc_plus4_in,
    input  [4:0]  rd_in,
    // Control signals out
    output reg        reg_write_out,
    output reg [1:0]  mem_to_reg_out,
    // Data out
    output reg [31:0] alu_result_out,
    output reg [31:0] mem_read_data_out,
    output reg [31:0] pc_plus4_out,
    output reg [4:0]  rd_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_write_out     <= 0; mem_to_reg_out    <= 0;
            alu_result_out    <= 0; mem_read_data_out <= 0;
            pc_plus4_out      <= 0; rd_out            <= 0;
        end else if (!stall) begin
            reg_write_out     <= reg_write_in;     mem_to_reg_out    <= mem_to_reg_in;
            alu_result_out    <= alu_result_in;     mem_read_data_out <= mem_read_data_in;
            pc_plus4_out      <= pc_plus4_in;      rd_out            <= rd_in;
        end
    end
endmodule
