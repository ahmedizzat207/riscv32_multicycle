`timescale 1ns / 1ps
// ============================================================================
// Testbench: tb_control_unit
// Module Under Test: CONTROL_UNIT_3 / STAGE2_CONTROL_UNIT
// Project: ChampionCHIP eXperience (Phase 2 Challenge) - Equipe 15
// ============================================================================

module tb_control_unit;

    // Clock and Reset Signals
    reg         clk_i;
    reg         rst_i;

    // Inputs to Control Unit
    reg  [31:0] instr_i;
    reg         branch_taken_i;
    reg         mult_busy_i;
    reg         mult_done_i;

    // Outputs from Control Unit
    wire [2:0]  o_Branch_Sel;
    wire [3:0]  o_Alu_Sel;
    wire [2:0]  o_Mult_Sel;
    wire [3:0]  o_Crc_sel;
    wire [1:0]  o_Src_B_Sel;
    wire [1:0]  o_Src_A_Sel;
    wire        o_IR_Write;
    wire        o_MDR_Write;
    wire        o_lorD;
    wire        o_PC_Sel;
    wire        o_DMEM_REG_Sel;
    wire [1:0]  o_Write_Back_Sel;
    wire        o_mult_start;
    wire        o_oe;
    wire        o_Reg_Write;
    wire        o_Rs_Write;
    wire        o_Mem_Write;
    wire        o_PC_Write;
    wire        o_PC_Write_Cond;

    // Instantiate the DUT
    CONTROL_UNIT_3 dut (
        .clk_i            (clk_i),
        .rst_i            (rst_i),
        .instr_i          (instr_i),
        .branch_taken_i   (branch_taken_i),
        .mult_busy_i      (mult_busy_i),
        .mult_done_i      (mult_done_i),
        .o_Branch_Sel     (o_Branch_Sel),
        .o_Alu_Sel        (o_Alu_Sel),
        .o_Mult_Sel       (o_Mult_Sel),
        .o_Crc_sel        (o_Crc_sel),
        .o_Src_B_Sel      (o_Src_B_Sel),
        .o_Src_A_Sel      (o_Src_A_Sel),
        .o_IR_Write       (o_IR_Write),
        .o_MDR_Write      (o_MDR_Write),
        .o_lorD           (o_lorD),
        .o_PC_Sel         (o_PC_Sel),
        .o_DMEM_REG_Sel   (o_DMEM_REG_Sel),
        .o_Write_Back_Sel (o_Write_Back_Sel),
        .o_mult_start     (o_mult_start),
        .o_oe             (o_oe),
        .o_Reg_Write      (o_Reg_Write),
        .o_Rs_Write       (o_Rs_Write),
        .o_Mem_Write      (o_Mem_Write),
        .o_PC_Write       (o_PC_Write),
        .o_PC_Write_Cond  (o_PC_Write_Cond)
    );

    // Clock Generation (10ns period -> 100MHz)
    always #5 clk_i = ~clk_i;

    integer pass_count = 0;
    integer fail_count = 0;

    initial begin
        $dumpfile("control_unit_tb.vcd");
        $dumpvars(0, tb_control_unit);

        // Initialize signals
        clk_i          = 1'b0;
        rst_i          = 1'b1;
        instr_i        = 32'h00000013; // NOP
        branch_taken_i = 1'b0;
        mult_busy_i    = 1'b0;
        mult_done_i    = 1'b0;

        $display("=========================================================");
        $display(" Starting Control Unit Testbench (tb_control_unit)");
        $display("=========================================================");

        // Apply Reset
        #15;
        rst_i = 1'b0;
        #10;

        // --------------------------------------------------------------------
        // TODO: Add test stimulus for:
        // 1. ADD (R-Type)
        // 2. ADDI (I-Type)
        // 3. LUI / AUIPC (U-Type)
        // 4. LW (Load) & SW (Store)
        // 5. BEQ (Branch taken / not taken)
        // 6. JAL / JALR (Jumps)
        // 7. MUL / MULH / MULHSU / MULHU (Multiplication handshake)
        // 8. CRCB / CRCH / CRCW (CRC operations)
        // 9. FENCE / ECALL / EBREAK (System)
        // --------------------------------------------------------------------

        #500;
        $display("=========================================================");
        $display(" Control Unit Testbench Finished");
        $display("=========================================================");
        $finish;
    end

endmodule
