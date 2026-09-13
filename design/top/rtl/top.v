// ============================================================================
// top: ChipInventor RVBL-2 Multicycle Core Top-Level Module
// ============================================================================
// ChampionCHIP eXperience (Phase 2 Challenge) - Equipe 15
// Top-level integration module connecting STAGE2_CONTROL_UNIT and STAGE2_DATAPATH.
// Target Synthesis Module for OpenLane ASIC implementation flow.
// ============================================================================

module top (
    input  wire        i_clk,
    input  wire        i_rst,
    output wire [31:0] o_Instruction,
    output wire [31:0] o_exeout
);

    // Internal Control & Status Interconnects
    wire        w_1;   // branch_taken
    wire [31:0] w_2;   // instruction word
    wire        w_3;   // mult_busy
    wire        w_4;   // mult_done
    wire [2:0]  w_5;   // Branch_Sel
    wire [3:0]  w_6;   // Alu_Sel
    wire [2:0]  w_7;   // Mult_Sel
    wire [3:0]  w_8;   // Crc_Sel
    wire [1:0]  w_9;   // Src_B_Sel
    wire [1:0]  w_10;  // Src_A_Sel
    wire        w_11;  // IR_Write
    wire        w_12;  // MDR_Write
    wire        w_13;  // lorD
    wire        w_14;  // PC_Sel
    wire        w_15;  // DMEM_REG_Sel
    wire [1:0]  w_16;  // Write_Back_Sel
    wire        w_17;  // mult_start
    wire        w_18;  // oe
    wire        w_19;  // Rs_Write
    wire        w_20;  // Reg_Write
    wire        w_21;  // Mem_Write
    wire        w_22;  // PC_Write
    wire        w_23;  // PC_Write_Cond

    // Interface Assigns
    assign o_Instruction[31:0] = w_2;

    // Instances of Sub-Modules
    STAGE2_CONTROL_UNIT blkProj14523_5 (
        .clk_i            (i_clk),
        .rst_i            (i_rst),
        .branch_taken_i   (w_1),
        .inst_i           (w_2),
        .mult_busy_i      (w_3),
        .mult_done_i      (w_4),
        .o_Branch_Sel     (w_5),
        .o_Alu_Sel        (w_6),
        .o_Mult_Sel       (w_7),
        .o_Crc_Sel        (w_8),
        .o_Src_B_Sel      (w_9),
        .o_Src_A_Sel      (w_10),
        .o_IR_Write       (w_11),
        .o_MDR_Write      (w_12),
        .o_lorD           (w_13),
        .o_PC_Sel         (w_14),
        .o_DMEM_REG_Sel   (w_15),
        .o_Write_Back_Sel (w_16),
        .o_mult_start     (w_17),
        .o_oe             (w_18),
        .o_Rs_Write       (w_19),
        .o_Reg_Write      (w_20),
        .o_Mem_Write      (w_21),
        .o_PC_Write       (w_22),
        .o_PC_Write_Cond  (w_23)
    );

    STAGE2_DATAPATH blkProj14999_7 (
        .i_Clk            (i_clk),
        .i_Rst            (i_rst),
        .o_Instruction    (w_2),
        .exeout_o         (o_exeout[31:0]),
        .o_branch_taken   (w_1),
        .o_mult_busy      (w_3),
        .o_mult_done      (w_4),
        .i_Branch_Sel     (w_5),
        .i_Alu_Sel        (w_6),
        .i_Mult_Sel       (w_7),
        .i_Crc_sel        (w_8),
        .i_Src_B_Sel      (w_9),
        .i_Src_A_Sel      (w_10),
        .i_IR_Write       (w_11),
        .i_MDR_Write      (w_12),
        .i_lorD           (w_13),
        .i_PC_Sel         (w_14),
        .i_DMEM_REG_Sel   (w_15),
        .i_Write_Back_Sel (w_16),
        .i_mult_start     (w_17),
        .i_oe             (w_18),
        .i_Rs_Write       (w_19),
        .i_Reg_Write      (w_20),
        .i_Mem_Write      (w_21),
        .i_PC_Write       (w_22),
        .i_PC_Write_Cond  (w_23)
    );

endmodule
