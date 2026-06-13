module register_file (
    input         clk,
    input         rst,
    input         reg_write,
    input  [4:0]  read_reg1,
    input  [4:0]  read_reg2,
    input  [4:0]  write_reg,
    input  [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2
);
    reg [31:0] registers [0:31];
    integer i;

    // Combinational read
    assign read_data1 = (read_reg1 == 5'd0) ? 32'd0 : registers[read_reg1];
    assign read_data2 = (read_reg2 == 5'd0) ? 32'd0 : registers[read_reg2];

    // Write on negative edge to support WB-to-ID forwarding
    always @(negedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'd0;
        end else if (reg_write && write_reg != 5'd0) begin
            registers[write_reg] <= write_data;
        end
    end
endmodule
