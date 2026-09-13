// ============================================================================
// STAGE2_DATAPATH: ChipInventor Stage 2 Multicycle Datapath
// ============================================================================
// Interconnects Register File, ALU, Multiplier, CRC unit, LSU, Unified Memory,
// Branch Comparator, Immediate Generator, and pipeline latch registers.
// ============================================================================

module STAGE2_DATAPATH (
    input  wire [2:0]  i_Branch_Sel,
    input  wire [3:0]  i_Alu_Sel,
    input  wire [2:0]  i_Mult_Sel,
    input  wire [3:0]  i_Crc_sel,
    input  wire [1:0]  i_Src_B_Sel,
    input  wire [1:0]  i_Src_A_Sel,
    input  wire        i_Clk,
    input  wire        i_Rst,
    input  wire        i_IR_Write,
    input  wire        i_MDR_Write,
    input  wire        i_lorD,
    input  wire        i_PC_Sel,
    input  wire        i_DMEM_REG_Sel,
    output wire        o_branch_taken,
    output wire        o_mult_done,
    output wire        o_mult_busy,
    input  wire [1:0]  i_Write_Back_Sel,
    input  wire        i_mult_start,
    input  wire        i_oe,
    input  wire        i_Reg_Write,
    input  wire        i_Rs_Write,
    input  wire        i_Mem_Write,
    input  wire        i_PC_Write,
    input  wire        i_PC_Write_Cond,
    output wire [31:0] o_Instruction,
    output wire [31:0] exeout_o
);

    // Internal Wires
    wire [31:0] w_1;   // ALU input A
    wire [31:0] w_2;   // ALU input B
    wire [15:0] w_3;   // CRC data output
    wire [31:0] w_6;   // Multiplier result
    wire [31:0] w_7;   // Register file write data (from DMEM_TO_REG_MUX)
    wire [31:0] w_8;   // Latched instruction word (IR output)
    wire [31:0] w_9;   // Register file port 1 read data
    wire [31:0] w_10;  // Register file port 2 read data
    wire [31:0] w_11;  // Latched rs1 register output
    wire [31:0] w_12;  // Latched rs2 register output
    wire [31:0] w_16;  // Combinational ALU output
    wire [31:0] w_18;  // Memory address (from ADDR_MUX)
    wire [31:0] w_19;  // Memory write data (from LSU)
    wire [3:0]  w_20;  // Memory byte-write mask (from LSU)
    wire [31:0] w_21;  // Unified memory read data
    wire [31:0] w_24;  // Sign-extended immediate (from imm_generator)
    wire [31:0] w_25;  // Loaded data from memory aligned by LSU
    wire [31:0] w_26;  // MDR output
    wire [31:0] w_31;  // Next PC value
    wire [31:0] w_32;  // Current PC output
    wire [31:0] w_34;  // ALUOut / exeout_o (from EXECUTE_RESULT_REG)
    wire [31:0] w_37;  // Result from MUX3_32 (ALU, MULT, CRC)
    wire [2:0]  w_45;  // op_size (funct3)

    // Interface Assigns
    assign o_Instruction[31:0] = w_8;
    assign exeout_o[31:0]       = w_34;

    // Instances of Modules
    STAGE2_CRC blkProj14952_41 (
        .crc_op_i   (i_Crc_sel[3:0]),
        .rs1_i      (w_1),
        .rs2_i      (w_2),
        .crc_data_o (w_3)
    );

    STAGE2_MULT blkProj14991_42 (
        .funct3_i    (i_Mult_Sel[2:0]),
        .clk_i       (i_Clk),
        .rst_i       (i_Rst),
        .done_o      (o_mult_done),
        .busy_o      (o_mult_busy),
        .start_i     (i_mult_start),
        .operand_a_i (w_1),
        .operand_b_i (w_2),
        .result_o    (w_6)
    );

    REGISTER_FILE #(.p_DATA_MEM_SIZE(2**10)) blk2116_47 (
        .i_Clk          (i_Clk),
        .i_Rst          (i_Rst),
        .i_Write_Enable (i_Reg_Write),
        .i_Data_Rd      (w_7),
        .i_Instruction  (w_8),
        .o_Data_Rs_1    (w_9),
        .o_Data_Rs_2    (w_10)
    );

    rs1_reg blk3994_49 (
        .clk_i      (i_Clk),
        .rst_i      (i_Rst),
        .en_i       (i_Rs_Write),
        .rs1_data_i (w_9),
        .rs1_data_o (w_11)
    );

    rs2_reg blk3995_50 (
        .clk_i      (i_Clk),
        .rst_i      (i_Rst),
        .en_i       (i_Rs_Write),
        .rs2_data_i (w_10),
        .rs2_data_o (w_12)
    );

    STAGE2_ALU blkProj14268_54 (
        .i_Sel (i_Alu_Sel[3:0]),
        .i_A   (w_1),
        .i_B   (w_2),
        .o_Q   (w_16)
    );

    STAGE2_UNIFIED_MEMORY blkProj14963_55 (
        .i_Clk          (i_Clk),
        .i_OE           (i_oe),
        .i_Write_Enable (i_Mem_Write),
        .i_Address      (w_18),
        .i_Data         (w_19),
        .i_Byte_Write   (w_20),
        .o_Data         (w_21)
    );

    STAGE2_IMM_GEN blkProj14957_56 (
        .inst_i    (w_8),
        .imm_out_o (w_24)
    );

    mem_data_reg blk4000_70 (
        .i_Clk       (i_Clk),
        .i_Rst       (i_Rst),
        .i_MDR_Write (i_MDR_Write),
        .i_Data      (w_25),
        .o_Data      (w_26)
    );

    inst_reg blk3999_71 (
        .i_Clk         (i_Clk),
        .i_Rst         (i_Rst),
        .i_IR_Write    (i_IR_Write),
        .o_Instruction (w_8),
        .i_Instruction (w_21)
    );

    PC blk4086_75 (
        .clk_i          (i_Clk),
        .rst_i          (i_Rst),
        .pc_write_i     (i_PC_Write),
        .pcwrite_cond_i (i_PC_Write_Cond),
        .pc_next_i      (w_31),
        .pc_o           (w_32)
    );

    PC_Next_MUX blk4089_79 (
        .PC_Sel     (i_PC_Sel),
        .ALU_Result (w_16),
        .PC_Next    (w_31),
        .ALU_Out    (w_34)
    );

    ADDR_MUX blk4087_84 (
        .lorD     (i_lorD),
        .Addr     (w_18),
        .PC_o     (w_32),
        .ALUOut_o (w_34)
    );

    DMEM_TO_REG_MUX blk4091_85 (
        .DMEM_REG_Sel (i_DMEM_REG_Sel),
        .Data_o       (w_7),
        .DMEM         (w_26),
        .ALUOut_o     (w_34)
    );

    EXECUTE_RESULT_REG blk4088_100 (
        .clk_i        (i_Clk),
        .rst_i        (i_Rst),
        .exeout_o     (w_34),
        .exe_result_i (w_37)
    );

    STAGE2_LSU_UNIT blkProj15103_101 (
        .core_data_o    (w_12),
        .mem_data_i     (w_19),
        .byte_write_i   (w_20),
        .mem_data_o     (w_21),
        .core_data_i    (w_25),
        .core_address_o (w_34),
        .op_size_o      (w_45)
    );

    op_size_decoder blk4137_103 (
        .inst_i    (w_8),
        .op_size_o (w_45)
    );

    MUX3_32 blk3989_105 (
        .Sel    (i_Write_Back_Sel[1:0]),
        .CRC    (w_3),
        .MULT   (w_6),
        .ALU    (w_16),
        .Result (w_37)
    );

    MUX_SRC_A blk3997_110 (
        .Src_A_Sel (i_Src_A_Sel[1:0]),
        .Src_A     (w_1),
        .Rs_1      (w_11),
        .PC        (w_32),
        .ALUOut    (w_34)
    );

    MUX_SRC_B blk3998_111 (
        .Src_B_Sel (i_Src_B_Sel[1:0]),
        .Src_B     (w_2),
        .Rs_2      (w_12),
        .Imm       (w_24)
    );

    STAGE2_BRANCH_COMPARATOR blkProj14958_112 (
        .funct3_i       (i_Branch_Sel[2:0]),
        .branch_taken_o (o_branch_taken),
        .a_i            (w_1),
        .b_i            (w_2)
    );

endmodule
