`timescale 1ns / 1ps
// ============================================================================
// Testbench: tb_unified_memory
// Module Under Test: STAGE2_UNIFIED_MEMORY
// Project: ChampionCHIP eXperience (Phase 2 Challenge) - Equipe 15
// ============================================================================

module tb_unified_memory;

    // Clock and Control Signals
    reg         i_Clk;
    reg  [31:0] i_Address;
    reg         i_Write_Enable;
    reg  [31:0] i_Data;
    reg  [3:0]  i_Byte_Write;
    reg         i_OE;
    wire [31:0] o_Data;

    // Instantiate DUT
    STAGE2_UNIFIED_MEMORY dut (
        .i_Clk          (i_Clk),
        .i_Address      (i_Address),
        .i_Write_Enable (i_Write_Enable),
        .i_Data         (i_Data),
        .i_Byte_Write   (i_Byte_Write),
        .i_OE           (i_OE),
        .o_Data         (o_Data)
    );

    // Clock Generation (10ns period -> 100MHz)
    always #5 i_Clk = ~i_Clk;

    initial begin
        $dumpfile("unified_memory_tb.vcd");
        $dumpvars(0, tb_unified_memory);

        // Initialize signals
        i_Clk          = 1'b0;
        i_Address      = 32'h0;
        i_Write_Enable = 1'b0;
        i_Data         = 32'h0;
        i_Byte_Write   = 4'b0;
        i_OE           = 1'b1;

        $display("=========================================================");
        $display(" Starting Unified Memory Testbench (tb_unified_memory)");
        $display("=========================================================");

        // --- IMEM READ TESTS ---
        $display("--- IMEM TESTS ---");
        i_Address = 32'h00400000; i_OE = 1'b1; #10;
        $display("[IMEM 0x00400000] Instruction = 0x%08h", o_Data);

        i_Address = 32'h00400004; #10;
        $display("[IMEM 0x00400004] Instruction = 0x%08h", o_Data);

        i_Address = 32'h00400008; #10;
        $display("[IMEM 0x00400008] Instruction = 0x%08h", o_Data);

        // De-assert OE (should force output to zero)
        i_OE = 1'b0; #10;
        $display("[IMEM OE=0      ] Output = 0x%08h (Expected: 00000000)", o_Data);
        i_OE = 1'b1;

        // --- DMEM WRITE AND READ TESTS ---
        $display("--- DMEM TESTS ---");
        // Write word 0xDEADBEEF to 0x10010000
        @(posedge i_Clk);
        i_Address      = 32'h10010000;
        i_Data         = 32'hDEADBEEF;
        i_Byte_Write   = 4'b1111;
        i_Write_Enable = 1'b1;
        @(posedge i_Clk);
        i_Write_Enable = 1'b0;

        // Read back from 0x10010000
        @(posedge i_Clk);
        #1;
        $display("[DMEM Read 0x10010000] Data = 0x%08h (Expected: deadbeef)", o_Data);

        // --------------------------------------------------------------------
        // TODO: Fill in additional sub-word writes and boundary test cases
        // --------------------------------------------------------------------

        #50;
        $display("=========================================================");
        $display(" Unified Memory Testbench Finished");
        $display("=========================================================");
        $finish;
    end

endmodule
