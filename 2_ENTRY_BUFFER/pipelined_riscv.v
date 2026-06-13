
// =============================================================================
// pipelined_riscv.v — 5-Stage Pipelined RISC-V with Cache Subsystem
// =============================================================================
// Modified version: replaces direct data_memory with cache_controller.
// Parameter WB_DEPTH controls write-buffer depth (0, 2, 4).
// cache_stall is OR-ed with load-use stall to stall the entire pipeline.
// =============================================================================

module pipelined_riscv #(
    parameter WB_DEPTH    = 2,
    parameter MEM_LATENCY = 20
)(
    input  clk,
    input  rst,
    output cache_stall_out   // Expose for stall counting in testbench
);

    // ===================================================================
    //                       WIRE DECLARATIONS
    // ===================================================================

    // -- IF Stage --
    wire [31:0] pc_current, pc_next, pc_plus4_IF, instruction_IF;
    wire        pc_write_en, if_id_write_en;

    // -- IF/ID outputs --
    wire [31:0] if_id_pc, if_id_pc_plus4, if_id_instruction;

    // -- ID Stage (decoded fields) --
    wire [6:0]  opcode_ID   = if_id_instruction[6:0];
    wire [4:0]  rd_ID       = if_id_instruction[11:7];
    wire [2:0]  funct3_ID   = if_id_instruction[14:12];
    wire [4:0]  rs1_ID      = if_id_instruction[19:15];
    wire [4:0]  rs2_ID      = if_id_instruction[24:20];
    wire [6:0]  funct7_ID   = if_id_instruction[31:25];

    wire [31:0] read_data1_ID, read_data2_ID, imm_ID;

    // Control signals from control unit
    wire        reg_write_ID, mem_read_ID, mem_write_ID, alu_src_ID;
    wire [1:0]  mem_to_reg_ID, alu_src_a_ID, alu_op_ID;
    wire        branch_ID, jump_ID, jalr_ID;

    // Hazard & stall
    wire        load_use_stall, pc_src;
    wire        cache_stall;
    wire        pipeline_stall;

    // Combined stall: load-use OR cache stall
    assign pipeline_stall = load_use_stall | cache_stall;
    assign cache_stall_out = cache_stall;
    
    // Global stall means the cache is freezing the whole pipeline.
    wire        global_stall = cache_stall;
    wire        real_flush   = pc_src & ~global_stall;

    // Control signals after hazard mux (bubble insertion for load-use ONLY)
    // Note: cache stall completely freezes the pipeline registers, so we don't
    // need to insert bubble zeros for cache stall, just for load-use stall.
    wire        reg_write_hz  = load_use_stall ? 1'b0 : reg_write_ID;
    wire [1:0]  mem_to_reg_hz = load_use_stall ? 2'b0 : mem_to_reg_ID;
    wire        mem_read_hz   = load_use_stall ? 1'b0 : mem_read_ID;
    wire        mem_write_hz  = load_use_stall ? 1'b0 : mem_write_ID;
    wire        alu_src_hz    = load_use_stall ? 1'b0 : alu_src_ID;
    wire [1:0]  alu_src_a_hz  = load_use_stall ? 2'b0 : alu_src_a_ID;
    wire        branch_hz     = load_use_stall ? 1'b0 : branch_ID;
    wire        jump_hz       = load_use_stall ? 1'b0 : jump_ID;
    wire        jalr_hz       = load_use_stall ? 1'b0 : jalr_ID;
    wire [1:0]  alu_op_hz     = load_use_stall ? 2'b0 : alu_op_ID;

    // -- ID/EX outputs --
    wire        ex_reg_write, ex_mem_read, ex_mem_write, ex_alu_src;
    wire [1:0]  ex_mem_to_reg, ex_alu_src_a, ex_alu_op;
    wire        ex_branch, ex_jump, ex_jalr;
    wire [31:0] ex_pc, ex_pc_plus4, ex_read_data1, ex_read_data2, ex_imm;
    wire [4:0]  ex_rs1, ex_rs2, ex_rd;
    wire [2:0]  ex_funct3;
    wire [6:0]  ex_funct7;

    // -- EX Stage --
    wire [1:0]  forward_a, forward_b;
    wire [31:0] forwarded_a, forwarded_b;
    wire [31:0] alu_input_a, alu_input_b;
    wire [3:0]  alu_ctrl;
    wire [31:0] alu_result_EX;
    wire        alu_zero;
    wire [31:0] branch_target_EX, jalr_target_EX, pc_target;
    wire        branch_taken;

    // -- EX/MEM outputs --
    wire        mem_reg_write, mem_mem_read, mem_mem_write;
    wire [1:0]  mem_mem_to_reg;
    wire [31:0] mem_alu_result, mem_write_data, mem_pc_plus4;
    wire [4:0]  mem_rd;

    // -- MEM Stage --
    wire [31:0] mem_read_data_MEM;

    // -- MEM/WB outputs --
    wire        wb_reg_write;
    wire [1:0]  wb_mem_to_reg;
    wire [31:0] wb_alu_result, wb_mem_read_data, wb_pc_plus4;
    wire [4:0]  wb_rd;

    // -- WB Stage --
    wire [31:0] wb_write_data;

    // ===================================================================
    //                     IF STAGE (Instruction Fetch)
    // ===================================================================

    assign pc_plus4_IF = pc_current + 32'd4;
    assign pc_next     = pc_src ? pc_target : pc_plus4_IF;
    assign pc_write_en   = ~global_stall & (~load_use_stall | real_flush);
    assign if_id_write_en = ~global_stall & (~load_use_stall);

    program_counter PC (
        .clk      (clk),
        .rst      (rst),
        .pc_write (pc_write_en),
        .pc_in    (pc_next),
        .pc_out   (pc_current)
    );

    instruction_memory IMEM (
        .addr        (pc_current),
        .instruction (instruction_IF)
    );

    // ===================================================================
    //                     IF/ID PIPELINE REGISTER
    // ===================================================================

    if_id_reg IF_ID (
        .clk             (clk),
        .rst             (rst),
        .if_id_write     (if_id_write_en),
        .flush           (real_flush),
        .pc_in           (pc_current),
        .pc_plus4_in     (pc_plus4_IF),
        .instruction_in  (instruction_IF),
        .pc_out          (if_id_pc),
        .pc_plus4_out    (if_id_pc_plus4),
        .instruction_out (if_id_instruction)
    );

    // ===================================================================
    //                     ID STAGE (Instruction Decode)
    // ===================================================================

    register_file RF (
        .clk        (clk),
        .rst        (rst),
        .reg_write  (wb_reg_write),
        .read_reg1  (rs1_ID),
        .read_reg2  (rs2_ID),
        .write_reg  (wb_rd),
        .write_data (wb_write_data),
        .read_data1 (read_data1_ID),
        .read_data2 (read_data2_ID)
    );

    imm_gen IMMGEN (
        .instruction (if_id_instruction),
        .imm_out     (imm_ID)
    );

    control_unit CTRL (
        .opcode     (opcode_ID),
        .reg_write  (reg_write_ID),
        .mem_to_reg (mem_to_reg_ID),
        .mem_read   (mem_read_ID),
        .mem_write  (mem_write_ID),
        .alu_src    (alu_src_ID),
        .alu_src_a  (alu_src_a_ID),
        .branch     (branch_ID),
        .jump       (jump_ID),
        .jalr       (jalr_ID),
        .alu_op     (alu_op_ID)
    );

    hazard_detection_unit HDU (
        .id_ex_mem_read (ex_mem_read),
        .id_ex_rd       (ex_rd),
        .if_id_rs1      (rs1_ID),
        .if_id_rs2      (rs2_ID),
        .stall          (load_use_stall)
    );

    // ===================================================================
    //                     ID/EX PIPELINE REGISTER
    // ===================================================================

    id_ex_reg ID_EX (
        .clk            (clk),
        .rst            (rst),
        .stall          (global_stall),
        .flush          (real_flush),
        // Control in (after hazard mux)
        .reg_write_in   (reg_write_hz),
        .mem_to_reg_in  (mem_to_reg_hz),
        .mem_read_in    (mem_read_hz),
        .mem_write_in   (mem_write_hz),
        .alu_src_in     (alu_src_hz),
        .alu_src_a_in   (alu_src_a_hz),
        .branch_in      (branch_hz),
        .jump_in        (jump_hz),
        .jalr_in        (jalr_hz),
        .alu_op_in      (alu_op_hz),
        // Data in
        .pc_in          (if_id_pc),
        .pc_plus4_in    (if_id_pc_plus4),
        .read_data1_in  (read_data1_ID),
        .read_data2_in  (read_data2_ID),
        .imm_in         (imm_ID),
        .rs1_in         (rs1_ID),
        .rs2_in         (rs2_ID),
        .rd_in          (rd_ID),
        .funct3_in      (funct3_ID),
        .funct7_in      (funct7_ID),
        // Control out
        .reg_write_out  (ex_reg_write),
        .mem_to_reg_out (ex_mem_to_reg),
        .mem_read_out   (ex_mem_read),
        .mem_write_out  (ex_mem_write),
        .alu_src_out    (ex_alu_src),
        .alu_src_a_out  (ex_alu_src_a),
        .branch_out     (ex_branch),
        .jump_out       (ex_jump),
        .jalr_out       (ex_jalr),
        .alu_op_out     (ex_alu_op),
        // Data out
        .pc_out         (ex_pc),
        .pc_plus4_out   (ex_pc_plus4),
        .read_data1_out (ex_read_data1),
        .read_data2_out (ex_read_data2),
        .imm_out        (ex_imm),
        .rs1_out        (ex_rs1),
        .rs2_out        (ex_rs2),
        .rd_out         (ex_rd),
        .funct3_out     (ex_funct3),
        .funct7_out     (ex_funct7)
    );

    // ===================================================================
    //                     EX STAGE (Execute)
    // ===================================================================

    // --- Forwarding Unit ---
    forwarding_unit FWD (
        .id_ex_rs1        (ex_rs1),
        .id_ex_rs2        (ex_rs2),
        .ex_mem_reg_write (mem_reg_write),
        .ex_mem_rd        (mem_rd),
        .mem_wb_reg_write (wb_reg_write),
        .mem_wb_rd        (wb_rd),
        .forward_a        (forward_a),
        .forward_b        (forward_b)
    );

    // --- Forwarding Muxes ---
    assign forwarded_a = (forward_a == 2'b10) ? mem_alu_result :
                         (forward_a == 2'b01) ? wb_write_data  :
                         ex_read_data1;

    assign forwarded_b = (forward_b == 2'b10) ? mem_alu_result :
                         (forward_b == 2'b01) ? wb_write_data  :
                         ex_read_data2;

    // --- ALU Input A Mux (alu_src_a) ---
    assign alu_input_a = (ex_alu_src_a == 2'b01) ? ex_pc   :  // AUIPC
                         (ex_alu_src_a == 2'b10) ? 32'd0   :  // LUI
                         forwarded_a;                          // Register

    // --- ALU Input B Mux (alu_src) ---
    assign alu_input_b = ex_alu_src ? ex_imm : forwarded_b;

    // --- ALU Control ---
    alu_control ALUCTRL (
        .alu_op   (ex_alu_op),
        .funct3   (ex_funct3),
        .funct7   (ex_funct7),
        .alu_ctrl (alu_ctrl)
    );

    // --- ALU ---
    alu ALU_UNIT (
        .a        (alu_input_a),
        .b        (alu_input_b),
        .alu_ctrl (alu_ctrl),
        .result   (alu_result_EX),
        .zero     (alu_zero)
    );

    // --- Branch Target ---
    assign branch_target_EX = ex_pc + ex_imm;
    assign jalr_target_EX   = alu_result_EX & 32'hFFFFFFFE; // Clear LSB

    // --- Branch Comparison ---
    branch_unit BRU (
        .rs1_data     (forwarded_a),
        .rs2_data     (forwarded_b),
        .funct3       (ex_funct3),
        .branch_taken (branch_taken)
    );

    // --- PC Source & Target ---
    assign pc_target = ex_jalr ? jalr_target_EX : branch_target_EX;
    assign pc_src    = (ex_branch & branch_taken) | ex_jump;

    // ===================================================================
    //                     EX/MEM PIPELINE REGISTER
    // ===================================================================

    ex_mem_reg EX_MEM (
        .clk            (clk),
        .rst            (rst),
        .stall          (global_stall),
        .reg_write_in   (ex_reg_write),
        .mem_to_reg_in  (ex_mem_to_reg),
        .mem_read_in    (ex_mem_read),
        .mem_write_in   (ex_mem_write),
        .alu_result_in  (alu_result_EX),
        .write_data_in  (forwarded_b),
        .pc_plus4_in    (ex_pc_plus4),
        .rd_in          (ex_rd),
        .reg_write_out  (mem_reg_write),
        .mem_to_reg_out (mem_mem_to_reg),
        .mem_read_out   (mem_mem_read),
        .mem_write_out  (mem_mem_write),
        .alu_result_out (mem_alu_result),
        .write_data_out (mem_write_data),
        .pc_plus4_out   (mem_pc_plus4),
        .rd_out         (mem_rd)
    );

    // ===================================================================
    //                     MEM STAGE — Cache Subsystem
    // ===================================================================

    cache_controller #(
        .WB_DEPTH   (WB_DEPTH),
        .MEM_LATENCY(MEM_LATENCY)
    ) CACHE_CTRL (
        .clk       (clk),
        .rst       (rst),
        .mem_read  (mem_mem_read),
        .mem_write (mem_mem_write),
        .addr      (mem_alu_result),
        .wdata     (mem_write_data),
        .rdata     (mem_read_data_MEM),
        .stall     (cache_stall)
    );

    // ===================================================================
    //                     MEM/WB PIPELINE REGISTER
    // ===================================================================

    mem_wb_reg MEM_WB (
        .clk              (clk),
        .rst              (rst),
        .stall            (global_stall),
        .reg_write_in     (mem_reg_write),
        .mem_to_reg_in    (mem_mem_to_reg),
        .alu_result_in    (mem_alu_result),
        .mem_read_data_in (mem_read_data_MEM),
        .pc_plus4_in      (mem_pc_plus4),
        .rd_in            (mem_rd),
        .reg_write_out    (wb_reg_write),
        .mem_to_reg_out   (wb_mem_to_reg),
        .alu_result_out   (wb_alu_result),
        .mem_read_data_out(wb_mem_read_data),
        .pc_plus4_out     (wb_pc_plus4),
        .rd_out           (wb_rd)
    );

    // ===================================================================
    //                     WB STAGE (Write Back)
    // ===================================================================

    assign wb_write_data = (wb_mem_to_reg == 2'b01) ? wb_mem_read_data :
                           (wb_mem_to_reg == 2'b10) ? wb_pc_plus4     :
                           wb_alu_result;

endmodule
