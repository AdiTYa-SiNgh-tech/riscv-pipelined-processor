module instruction_memory (
    input  [31:0] addr,
    output [31:0] instruction
);
    reg [31:0] mem [0:255];

    initial begin
        $readmemh("C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/2_entry_buffer/instructions_p9.mem", mem);
    end

    // Word-aligned access (address divided by 4)
    assign instruction = mem[addr[9:2]];
endmodule
