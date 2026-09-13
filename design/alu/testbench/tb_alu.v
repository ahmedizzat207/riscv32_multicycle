`timescale 1ns / 1ps
// ============================================================================
// Testbench: tb_alu
// Module Under Test: ALU / STAGE2_ALU (11 Supported Operations)
// Project: ChampionCHIP eXperience (Phase 2 Challenge) - Equipe 15
// ============================================================================

module tb_alu;

    // Testbench Stimulus Signals
    reg  signed [31:0] i_A;
    reg  signed [31:0] i_B;
    reg  [3:0]         i_Sel;
    wire signed [31:0] o_Q;

    // ALU Opcode Localparams
    localparam c_ALU_OP_PASS_B = 4'h0;
    localparam c_ALU_OP_ADD    = 4'h1;
    localparam c_ALU_OP_SUB    = 4'h2;
    localparam c_ALU_OP_AND    = 4'h3;
    localparam c_ALU_OP_OR     = 4'h4;
    localparam c_ALU_OP_XOR    = 4'h5;
    localparam c_ALU_OP_SLL    = 4'h6;
    localparam c_ALU_OP_SRL    = 4'h7;
    localparam c_ALU_OP_MRS    = 4'h8; // SRA
    localparam c_ALU_OP_SLT    = 4'h9;
    localparam c_ALU_OP_SLTU   = 4'hA;

    // Instantiate DUT
    ALU dut (
        .i_A   (i_A),
        .i_B   (i_B),
        .i_Sel (i_Sel),
        .o_Q   (o_Q)
    );

    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, tb_alu);

        $display("=========================================================");
        $display(" Starting RISC-V ALU Verification Testbench (tb_alu)");
        $display("=========================================================");

        // TC1: PASS_B
        i_A = 32'h12345678; i_B = 32'hABCDEF01; i_Sel = c_ALU_OP_PASS_B; #10;
        $display("[TC1 PASS_B] a: 0x%08h, b: 0x%08h -> Result: 0x%08h", i_A, i_B, o_Q);

        // TC2: ADD
        i_A = 32'd5; i_B = 32'd3; i_Sel = c_ALU_OP_ADD; #10;
        $display("[TC2 ADD   ] a: %0d, b: %0d -> Result: %0d", i_A, i_B, o_Q);

        // TC3: SUB
        i_A = 32'd5; i_B = 32'd10; i_Sel = c_ALU_OP_SUB; #10;
        $display("[TC3 SUB   ] a: %0d, b: %0d -> Result: %0d (0x%08h)", i_A, i_B, o_Q, o_Q);

        // TC4: AND
        i_A = 32'hF0F0F0F0; i_B = 32'h00FF00FF; i_Sel = c_ALU_OP_AND; #10;
        $display("[TC4 AND   ] a: 0x%08h, b: 0x%08h -> Result: 0x%08h", i_A, i_B, o_Q);

        // TC5: OR
        i_A = 32'hF0F0F0F0; i_B = 32'h00FF00FF; i_Sel = c_ALU_OP_OR; #10;
        $display("[TC5 OR    ] a: 0x%08h, b: 0x%08h -> Result: 0x%08h", i_A, i_B, o_Q);

        // TC6: XOR
        i_A = 32'hFFFFFFFF; i_B = 32'h12345678; i_Sel = c_ALU_OP_XOR; #10;
        $display("[TC6 XOR   ] a: 0x%08h, b: 0x%08h -> Result: 0x%08h", i_A, i_B, o_Q);

        // TC7: SLL
        i_A = 32'h00000001; i_B = 32'd4; i_Sel = c_ALU_OP_SLL; #10;
        $display("[TC7 SLL   ] a: 0x%08h << %0d -> Result: 0x%08h", i_A, i_B[4:0], o_Q);

        // TC8: SRL
        i_A = 32'h80000000; i_B = 32'd4; i_Sel = c_ALU_OP_SRL; #10;
        $display("[TC8 SRL   ] a: 0x%08h >> %0d -> Result: 0x%08h", i_A, i_B[4:0], o_Q);

        // TC9: SRA (MRS)
        i_A = 32'h80000010; i_B = 32'd4; i_Sel = c_ALU_OP_MRS; #10;
        $display("[TC9 SRA   ] a: 0x%08h >>> %0d -> Result: 0x%08h", i_A, i_B[4:0], o_Q);

        // TC10: SLT
        i_A = -32'd2; i_B = 32'd5; i_Sel = c_ALU_OP_SLT; #10;
        $display("[TC10 SLT  ] a: %0d < b: %0d -> Result: %0d", i_A, i_B, o_Q);

        // TC11: SLTU
        i_A = 32'hFFFFFFFE; i_B = 32'd5; i_Sel = c_ALU_OP_SLTU; #10;
        $display("[TC11 SLTU ] a: %0u < b: %0u -> Result: %0d", $unsigned(i_A), $unsigned(i_B), o_Q);

        // --------------------------------------------------------------------
        // TODO: Add any additional custom or corner-case test vectors here
        // --------------------------------------------------------------------

        $display("=========================================================");
        $display(" ALU Testbench Execution Finished");
        $display("=========================================================");
        $finish;
    end

endmodule
