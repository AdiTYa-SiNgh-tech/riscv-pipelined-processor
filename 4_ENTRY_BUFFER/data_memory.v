module data_memory (
    input         clk,
    input         mem_read,
    input         mem_write,
    input  [31:0] addr,
    input  [31:0] write_data,
    output [31:0] read_data
);
    reg [31:0] mem [0:255];

    // Combinational read
    assign read_data = mem_read ? mem[addr[9:2]] : 32'd0;

    // Synchronous write
    always @(posedge clk) begin
        if (mem_write)
            mem[addr[9:2]] <= write_data;
    end
endmodule
