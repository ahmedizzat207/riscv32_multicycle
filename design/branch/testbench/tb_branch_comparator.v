`timescale 1ns / 1ps
// ============================================================================
// Testbench: tb_branch_comparator
// Module Under Test: branch_comparator / STAGE2_BRANCH_COMPARATOR
// Project: ChampionCHIP eXperience (Phase 2 Challenge) - Equipe 15
// ============================================================================

module tb_branch_comparator;

    // Stimulus Signals
    reg  [31:0] a_i;
    reg  [31:0] b_i;
    reg  [2:0]  funct3_i;
    wire        branch_taken_o;

    // Instantiate DUT
    branch_comparator dut (
        .a_i            (a_i),
        .b_i            (b_i),
        .funct3_i       (funct3_i),
        .branch_taken_o (branch_taken_o)
    );

    initial begin
        $dumpfile("branch_comparator_tb.vcd");
        $dumpvars(0, tb_branch_comparator);

        $display("=========================================================");
        $display(" Starting Branch Unit Testbench (tb_branch_comparator)");
        $display("=========================================================");

        // TC1: [BEQ Equal]
        a_i = 32'd10; b_i = 32'd10; funct3_i = 3'b000; #10;
        $display("TC1 [BEQ Equal   ] : A = %0d, B = %0d | Taken = %0d (Expected: 1)", a_i, b_i, branch_taken_o);

        // TC2: [BNE Not Equal]
        a_i = 32'd10; b_i = 32'd11; funct3_i = 3'b001; #10;
        $display("TC2 [BNE Not Equal] : A = %0d, B = %0d | Taken = %0d (Expected: 1)", a_i, b_i, branch_taken_o);

        // TC3: [BLT Signed]
        a_i = -32'd5; b_i = 32'd10; funct3_i = 3'b100; #10;
        $display("TC3 [BLT Signed  ] : A = %0d, B = %0d | Taken = %0d (Expected: 1)", $signed(a_i), $signed(b_i), branch_taken_o);

        // TC4: [BGE Signed]
        a_i = -32'd5; b_i = 32'd10; funct3_i = 3'b101; #10;
        $display("TC4 [BGE Signed  ] : A = %0d, B = %0d | Taken = %0d (Expected: 0)", $signed(a_i), $signed(b_i), branch_taken_o);

        // TC5: [BLTU Unsigned]
        a_i = 32'hFFFFFFFF; b_i = 32'h00000001; funct3_i = 3'b110; #10;
        $display("TC5 [BLTU Unsign ] : A = 0x%08h, B = 0x%08h | Taken = %0d (Expected: 0)", a_i, b_i, branch_taken_o);

        // TC6: [BGEU Unsigned]
        a_i = 32'hFFFFFFFF; b_i = 32'h00000001; funct3_i = 3'b111; #10;
        $display("TC6 [BGEU Unsign ] : A = 0x%08h, B = 0x%08h | Taken = %0d (Expected: 1)", a_i, b_i, branch_taken_o);

        // --------------------------------------------------------------------
        // TODO: Add any additional test vectors here
        // --------------------------------------------------------------------

        $display("=========================================================");
        $display(" Testbench completed successfully.");
        $display("=========================================================");
        $finish;
    end

endmodule
