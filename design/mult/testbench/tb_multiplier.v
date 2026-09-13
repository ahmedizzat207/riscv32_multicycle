`timescale 1ns / 1ps
// ============================================================================
// Testbench: tb_multiplier
// Module Under Test: multiplier_sequential / STAGE2_MULT
// Project: ChampionCHIP eXperience (Phase 2 Challenge) - Equipe 15
// ============================================================================

module tb_multiplier;

    // Clock and Reset Signals
    reg         clk_i;
    reg         rst_i;

    // Control Interface
    reg         start_i;
    reg  [2:0]  funct3_i;
    reg  [31:0] operand_a_i;
    reg  [31:0] operand_b_i;

    // Output Signals
    wire [31:0] result_o;
    wire        busy_o;
    wire        done_o;

    // Instantiate DUT
    multiplier_sequential dut (
        .clk_i       (clk_i),
        .rst_i       (rst_i),
        .start_i     (start_i),
        .funct3_i    (funct3_i),
        .operand_a_i (operand_a_i),
        .operand_b_i (operand_b_i),
        .result_o    (result_o),
        .busy_o      (busy_o),
        .done_o      (done_o)
    );

    // Clock Generation (10ns period -> 100MHz)
    always #5 clk_i = ~clk_i;

    // Task to trigger and wait for multiplication completion
    task run_multiplication;
        input [2:0]  f3;
        input [31:0] a;
        input [31:0] b;
        begin
            @(posedge clk_i);
            funct3_i    = f3;
            operand_a_i = a;
            operand_b_i = b;
            start_i     = 1'b1;
            @(posedge clk_i);
            start_i     = 1'b0;

            // Wait for done_o pulse
            while (!done_o) @(posedge clk_i);
            @(posedge clk_i);
        end
    endtask

    initial begin
        $dumpfile("multiplier_tb.vcd");
        $dumpvars(0, tb_multiplier);

        // Initialize signals
        clk_i       = 1'b0;
        rst_i       = 1'b1;
        start_i     = 1'b0;
        funct3_i    = 3'b000;
        operand_a_i = 32'd0;
        operand_b_i = 32'd0;

        $display("=========================================================");
        $display(" Starting Sequential Multiplier Testbench (tb_multiplier)");
        $display("=========================================================");

        #20;
        rst_i = 1'b0;
        #10;

        // --------------------------------------------------------------------
        // TODO: Fill in custom multiplier test cases for:
        // 1. MUL    (funct3 = 3'b000)
        // 2. MULH   (funct3 = 3'b001, signed x signed upper)
        // 3. MULHSU (funct3 = 3'b010, signed x unsigned upper)
        // 4. MULHU  (funct3 = 3'b011, unsigned x unsigned upper)
        // --------------------------------------------------------------------

        // Example Test: MUL (5 x 6 = 30)
        $display("[Test 1: MUL] 5 * 6");
        run_multiplication(3'b000, 32'd5, 32'd6);
        $display("  -> Result = %0d (Expected: 30)", result_o);

        // Example Test: MULH with signed negative operand
        $display("[Test 2: MULH] (-5) * 6");
        run_multiplication(3'b001, -32'd5, 32'd6);
        $display("  -> Result = 0x%08h", result_o);

        #50;
        $display("=========================================================");
        $display(" Multiplier Testbench Finished");
        $display("=========================================================");
        $finish;
    end

endmodule
