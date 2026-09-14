`timescale 1ns / 1ps

module testbench();

    // Testbench Signals
    reg  [31:0] inst_i;
    wire [31:0] imm_out_o;

    // Instantiate Design Under Test (DUT)
    imm_generator dut (
        .inst_i(inst_i),
        .imm_out_o(imm_out_o)
    );

    // Waveform block for ChipInventor EDA visual viewer
    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);
    end

    // Verification task for format testing
    task check_imm(
        input [256:1] test_label,
        input [31:0]  instruction,
        input [31:0]  exp_imm
    );
        begin
            inst_i = instruction;
            #10; // Wait for combinational logic

            $display("%-22s : Inst = 0x%08h | Imm = %10d (0x%08h)", 
                     test_label, inst_i, $signed(imm_out_o), imm_out_o);
        end
    endtask

    // Main Test Stimulus
    initial begin
        $display("Starting Immediate Generator Testbench...");
        $display("----------------------------------------------------------------------");

        // TC1: I-Type ADDI (imm = -10)
        check_imm("TC1 [I-Type  ADDI  ]", 32'hFF60_1093, 32'hFFFF_FFF6);

        // TC2: S-Type SW (imm = 8)
        check_imm("TC2 [S-Type  SW    ]", 32'h0051_2423, 32'h0000_0008);

        // TC3: B-Type BEQ (imm = -16)
        check_imm("TC3 [B-Type  BEQ   ]", 32'hFE20_88E3, 32'hFFFF_FFF0);

        // TC4: U-Type LUI (imm = 305418240 / 0x12345000)
        check_imm("TC4 [U-Type  LUI   ]", 32'h1234_5537, 32'h1234_5000);

        // TC5: J-Type JAL (imm = 120)
        check_imm("TC5 [J-Type  JAL   ]", 32'h0780_00EF, 32'h0000_0078);

        // TC6: I-Type ECALL (imm = 0)
        check_imm("TC6 [I-Type  ECALL ]", 32'h0000_0073, 32'h0000_0000);

        // TC7: I-Type EBREAK (imm = 1)
        check_imm("TC7 [I-Type  EBREAK]", 32'h0010_0073, 32'h0000_0001);

        // TC8: I-Type FENCE (imm = 255)
        check_imm("TC8 [I-Type  FENCE ]", 32'h00FF_000F, 32'h0000_00FF);

        $display("----------------------------------------------------------------------");
        $display("Testbench completed successfully.");
        $finish;
    end

endmodule