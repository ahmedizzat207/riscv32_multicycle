`timescale 1ns / 1ps
// ============================================================================
// Testbench: tb_imm_gen
// Module Under Test: imm_generator / STAGE2_IMM_GEN
// Project: ChampionCHIP eXperience (Phase 2 Challenge) - Equipe 15
// ============================================================================

module tb_imm_gen;

    // Stimulus Signals
    reg  [31:0] inst_i;
    wire [31:0] imm_out_o;

    // Instantiate DUT
    imm_generator dut (
        .inst_i    (inst_i),
        .imm_out_o (imm_out_o)
    );

    initial begin
        $dumpfile("imm_gen_tb.vcd");
        $dumpvars(0, tb_imm_gen);

        $display("=========================================================");
        $display(" Starting Immediate Generator Testbench (tb_imm_gen)");
        $display("=========================================================");

        // TC1 [I-Type ADDI]
        inst_i = 32'hFF610093; #10;
        $display("TC1 [I-Type ADDI  ] : Inst = 0x%08h | Imm = %0d (0x%08h)", inst_i, $signed(imm_out_o), imm_out_o);

        // TC2 [S-Type SW]
        inst_i = 32'h00512423; #10;
        $display("TC2 [S-Type SW    ] : Inst = 0x%08h | Imm = %0d (0x%08h)", inst_i, $signed(imm_out_o), imm_out_o);

        // TC3 [B-Type BEQ]
        inst_i = 32'hFE2088E3; #10;
        $display("TC3 [B-Type BEQ   ] : Inst = 0x%08h | Imm = %0d (0x%08h)", inst_i, $signed(imm_out_o), imm_out_o);

        // TC4 [U-Type LUI]
        inst_i = 32'h12345537; #10;
        $display("TC4 [U-Type LUI   ] : Inst = 0x%08h | Imm = %0d (0x%08h)", inst_i, imm_out_o, imm_out_o);

        // TC5 [J-Type JAL]
        inst_i = 32'h080000EF; #10;
        $display("TC5 [J-Type JAL   ] : Inst = 0x%08h | Imm = %0d (0x%08h)", inst_i, $signed(imm_out_o), imm_out_o);

        // TC6 [I-Type ECALL]
        inst_i = 32'h00000073; #10;
        $display("TC6 [I-Type ECALL ] : Inst = 0x%08h | Imm = %0d (0x%08h)", inst_i, imm_out_o, imm_out_o);

        // TC7 [I-Type EBREAK]
        inst_i = 32'h00100073; #10;
        $display("TC7 [I-Type EBREAK] : Inst = 0x%08h | Imm = %0d (0x%08h)", inst_i, imm_out_o, imm_out_o);

        // TC8 [I-Type FENCE]
        inst_i = 32'h0FF0000F; #10;
        $display("TC8 [I-Type FENCE ] : Inst = 0x%08h | Imm = %0d (0x%08h)", inst_i, imm_out_o, imm_out_o);

        // --------------------------------------------------------------------
        // TODO: Add any additional test instructions here
        // --------------------------------------------------------------------

        $display("=========================================================");
        $display(" Testbench completed successfully.");
        $display("=========================================================");
        $finish;
    end

endmodule
