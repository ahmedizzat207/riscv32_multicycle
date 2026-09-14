`timescale 1ns / 1ps

module testbench();

    // DUT Signals
    reg         clk = 0;
    reg         rst_n;

    // Control & Operand Signals
    reg         start_i;
    reg  [2:0]  funct3_i;
    reg  [31:0] operand_a_i;
    reg  [31:0] operand_b_i;

    wire [31:0] result_o;
    wire        busy_o;
    wire        done_o;

    // Diagnostic Counters
    integer pass_count = 0;
    integer fail_count = 0;

    // Instantiate Design Under Test (DUT)
    top dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_i(start_i),
        .funct3_i(funct3_i),
        .operand_a_i(operand_a_i),
        .operand_b_i(operand_b_i),
        .result_o(result_o),
        .busy_o(busy_o),
        .done_o(done_o)
    );

    // Race-Free 100MHz Clock Generation
    always #5 clk = ~clk;
    
  // ChipInventor EDA Waveform Dump Block
    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);
    end

    // ------------------------------------------------------------------------
    // Verification Task
    // ------------------------------------------------------------------------
    task exec_mult(
        input [31:0]  a,
        input [31:0]  b,
        input [2:0]   f3,
        input [31:0]  exp_result,
        input [256:1] test_name
    );
        begin
            @(posedge clk);
            #1; // Delay past clock edge to avoid setup/hold race condition
            operand_a_i = a;
            operand_b_i = b;
            funct3_i    = f3;
            start_i     = 1'b1;

            @(posedge clk);
            #1;
            start_i     = 1'b0; // Deassert start pulse after 1 cycle

            // Wait for sequential shift-and-add calculation to complete
            wait (done_o === 1'b1);

            #1; // Settling time to sample output
            if (result_o === exp_result) begin
                $display("[PASS] %-30s | A: 0x%08h | B: 0x%08h | Out: 0x%08h", test_name, a, b, result_o);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %-30s | A: 0x%08h | B: 0x%08h | Exp: 0x%08h, Got: 0x%08h", test_name, a, b, exp_result, result_o);
                fail_count = fail_count + 1;
            end
            @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------------------
    // Main Stimulus
    // ------------------------------------------------------------------------
    initial begin
        $display("=======================================================================");
        $display("          STARTING SEQUENTIAL MULTIPLIER (Zmmul) TEST                  ");
        $display("=======================================================================");

        // Reset Pulse
        rst_n       = 1'b0;
        start_i     = 1'b0;
        funct3_i    = 3'b000;
        operand_a_i = 32'h0;
        operand_b_i = 32'h0;
        repeat (2) @(posedge clk);
        #1;
        rst_n       = 1'b1;
        @(posedge clk);

        // --- 1. MUL TESTS (Lower 32 bits) ---
        exec_mult(32'd10,          32'd5,           3'b000, 32'd50,         "MUL: Pos x Pos");
        exec_mult(-32'd10,         32'd5,           3'b000, -32'd50,        "MUL: Neg x Pos");
        exec_mult(-32'd15,         -32'd4,          3'b000, 32'd60,         "MUL: Neg x Neg");
        exec_mult(32'h1234_5678,   32'h0,           3'b000, 32'h0,          "MUL: Zero Operand");

        // --- 2. MULH TESTS (Upper 32 bits, Signed x Signed) ---
        exec_mult(32'h7FFF_FFFF,   32'd2,           3'b001, 32'h0,          "MULH: Max Pos x 2");
        exec_mult(32'h8000_0000,   32'd2,           3'b001, 32'hFFFF_FFFF,  "MULH: Min Neg x 2");
        exec_mult(-32'd1234567,    32'd8901234,     3'b001, 32'hFFFF_F601,  "MULH: Large Neg x Pos");

        // --- 3. MULHSU TESTS (Upper 32 bits, Signed x Unsigned) ---
        exec_mult(-32'd5,          32'd10,          3'b010, 32'hFFFF_FFFF,  "MULHSU: Neg x Unsigned Pos");
        exec_mult(32'h8000_0000,   32'h8000_0000,   3'b010, 32'hC000_0000,  "MULHSU: Min Neg x Large Unsigned");

        // --- 4. MULHU TESTS (Upper 32 bits, Unsigned x Unsigned) ---
        exec_mult(32'hFFFF_FFFF,   32'hFFFF_FFFF,   3'b011, 32'hFFFF_FFFE,  "MULHU: Max Unsigned x Max Unsigned");
        exec_mult(32'h8000_0000,   32'd4,           3'b011, 32'd2,          "MULHU: Large Unsigned x Small");

        $display("=======================================================================");
        $display(" SUMMARY: %0d Passed, %0d Failed", pass_count, fail_count);
        $display("=======================================================================");
        $finish;
    end

endmodule