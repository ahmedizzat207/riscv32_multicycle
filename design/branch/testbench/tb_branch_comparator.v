`timescale 1ns / 1ps

module testbench();

    // Testbench Signals
    reg  [31:0] a_i;
    reg  [31:0] b_i;
    reg  [2:0]  funct3_i;
    wire        branch_taken_o;

    // Instantiate Design Under Test (DUT)
    branch_comparator dut (
        .a_i(a_i),
        .b_i(b_i),
        .funct3_i(funct3_i),
        .branch_taken_o(branch_taken_o)
    );

    // Waveform block for ChipInventor EDA visual viewer
    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);
    end

    // Verification task for branch condition testing
    task check_branch(
        input [256:1] test_label,
        input [31:0]  val_a,
        input [31:0]  val_b,
        input [2:0]   f3,
        input         exp_taken
    );
        begin
            a_i      = val_a;
            b_i      = val_b;
            funct3_i = f3;
            #10; // Wait for combinational propagation

            if ($signed(val_a) < 0 || $signed(val_b) < 0) begin
                $display("%-20s : A = %10d, B = %10d | Taken = %0d (Expected: %0d)", 
                         test_label, $signed(val_a), $signed(val_b), branch_taken_o, exp_taken);
            end else if (val_a > 32'h0000_FFFF || val_b > 32'h0000_FFFF) begin
                $display("%-20s : A = 0x%08h, B = 0x%08h | Taken = %0d (Expected: %0d)", 
                         test_label, val_a, val_b, branch_taken_o, exp_taken);
            end else begin
                $display("%-20s : A = %10d, B = %10d | Taken = %0d (Expected: %0d)", 
                         test_label, val_a, val_b, branch_taken_o, exp_taken);
            end
        end
    endtask

    // Main Test Stimulus
    initial begin
        $display("Starting Branch Unit Testbench...");
        $display("----------------------------------------------------------------------");

        // TC1: BEQ Equal (funct3 = 3'b000)
        check_branch("TC1 [BEQ  Equal]", 32'd10, 32'd10, 3'b000, 1'b1);

        // TC2: BNE Not Equal (funct3 = 3'b001)
        check_branch("TC2 [BNE  Not Equal]", 32'd10, 32'd11, 3'b001, 1'b1);

        // TC3: BLT Signed (funct3 = 3'b100)
        check_branch("TC3 [BLT  Signed]", -32'd5, 32'd10, 3'b100, 1'b1);

        // TC4: BGE Signed (funct3 = 3 me 101)
        check_branch("TC4 [BGE  Signed]", -32'd5, 32'd10, 3'b101, 1'b0);

        // TC5: BLTU Unsigned (funct3 = 3'b110)
        check_branch("TC5 [BLTU Unsigned]", 32'hFFFF_FFFF, 32'h0000_0001, 3'b110, 1'b0);

        // TC6: BGEU Unsigned (funct3 = 3'b111)
        check_branch("TC6 [BGEU Unsigned]", 32'hFFFF_FFFF, 32'h0000_0001, 3'b111, 1 me 1);

        $display("----------------------------------------------------------------------");
        $display("Testbench completed successfully.");
        $finish;
    end

endmodule