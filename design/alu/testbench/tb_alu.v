`timescale 1ns / 1ps

module testbench();

    // Testbench Signals
    reg  signed [31:0] i_A;
    reg  signed [31:0] i_B;
    reg         [3:0]  i_Sel;
    wire signed [31:0] o_Q;

    // Instantiate Design Under Test (DUT)
    ALU dut (
        .i_A(i_A),
        .i_B(i_B),
        .i_Sel(i_Sel),
        .o_Q(o_Q)
    );

    // Waveform dump for ChipInventor EDA visual viewer
    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);
    end

    // Test Stimulus
    initial begin
        $display("Starting RISC-V ALU Verification Testbench");
        $display("**************************************************");

        // TC1: PASS_B (4'h0)
        i_A = 32'h12345678; i_B = 32'habcdef01; i_Sel = 4'h0; #10;
        $display("[TC1  PASS_B ] | a: 0x%08h, b: 0x%08h -> Result: 0x%08h", i_A, i_B, o_Q);

        // TC2: ADD (4'h1)
        i_A = 32'd5; i_B = 32'd3; i_Sel = 4'h1; #10;
        $display("[TC2  ADD    ] | a: %0d, b: %0d -> Result: %0d", i_A, i_B, o_Q);

        // TC3: SUB (4'h2)
        i_A = 32'd5; i_B = 32'd10; i_Sel = 4'h2; #10;
        $display("[TC3  SUB    ] | a: %0d, b: %0d -> Result: %0d (0x%08h)", i_A, i_B, o_Q, o_Q);

        // TC4: AND (4'h3)
        i_A = 32'hf0f0f0f0; i_B = 32'h00ff00ff; i_Sel = 4'h3; #10;
        $display("[TC4  AND    ] | a: 0x%08h, b: 0x%08h -> Result: 0x%08h", i_A, i_B, o_Q);

        // TC5: OR (4'h4)
        i_A = 32'hf0f0f0f0; i_B = 32'h00ff00ff; i_Sel = 4'h4; #10;
        $display("[TC5  OR     ] | a: 0x%08h, b: 0x%08h -> Result: 0x%08h", i_A, i_B, o_Q);

        // TC6: XOR (4'h5)
        i_A = 32'hffffffff; i_B = 32'h12345678; i_Sel = 4'h5; #10;
        $display("[TC6  XOR    ] | a: 0x%08h, b: 0x%08h -> Result: 0x%08h", i_A, i_B, o_Q);

        // TC7: SLL (4'h6)
        i_A = 32'h00000001; i_B = 32'd4; i_Sel = 4'h6; #10;
        $display("[TC7  SLL    ] | a: 0x%08h << %0d -> Result: 0x%08h", i_A, i_B[4:0], o_Q);

        // TC8: SRL (4'h7)
        i_A = 32'h80000000; i_B = 32'd4; i_Sel = 4'h7; #10;
        $display("[TC8  SRL    ] | a: 0x%08h >> %0d -> Result: 0x%08h", i_A, i_B[4:0], o_Q);

        // TC9: SRA (4'h8)
        i_A = 32'h80000010; i_B = 32'd4; i_Sel = 4'h8; #10;
        $display("[TC9  SRA    ] | a: 0x%08h >>> %0d -> Result: 0x%08h", i_A, i_B[4:0], o_Q);

        // TC10: SLT (4'h9)
        i_A = -32'd2; i_B = 32'd5; i_Sel = 4'h9; #10;
        $display("[TC10 SLT    ] | a: %0d < b: %0d -> Result: %0d", i_A, i_B, o_Q);

        // TC11: SLTU (4'hA)
        i_A = 32'hfffffffe; i_B = 32'd5; i_Sel = 4'hA; #10;
        $display("[TC11 SLTU   ] | a: %0u < b: %0d -> Result: %0d", $unsigned(i_A), i_B, o_Q);

        $display("**************************************************");
        $display("ALU Testbench Execution Finished");
        $finish;
    end

endmodule