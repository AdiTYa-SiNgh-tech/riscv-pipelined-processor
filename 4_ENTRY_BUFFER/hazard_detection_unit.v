module hazard_detection_unit (
    input        id_ex_mem_read,  // Is instruction in EX a load?
    input  [4:0] id_ex_rd,        // Destination register in EX
    input  [4:0] if_id_rs1,       // Source register 1 in ID
    input  [4:0] if_id_rs2,       // Source register 2 in ID
    output       stall            // 1 = stall pipeline (load-use hazard)
);
    // Load-use hazard detection
    // If instruction in EX is a load AND its destination matches
    // a source register of the instruction currently in ID
    assign stall = id_ex_mem_read &&
                   (id_ex_rd != 5'd0) &&
                   ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2));
endmodule
