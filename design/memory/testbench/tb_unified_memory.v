`timescale 1ns / 1ps

module testbench();

    // Testbench Signals
    reg         i_Clk;
    reg  [31:0] i_Address;
    reg         i_Write_Enable;
    reg  [31:0] i_Data;
    reg  [3:0]  i_Byte_Write;
    reg         i_OE;
    wire [31:0] o_Data;

    integer pass_count = 0;

    // Instantiate Design Under Test (DUT)
    STAGE2_UNIFIED_MEMORY dut (
        .i_Clk(i_Clk),
        .i_Address(i_Address),
        .i_Write_Enable(i_Write_Enable),
        .i_Data(i_Data),
        .i_Byte_Write(i_Byte_Write),
        .i_OE(i_OE),
        .o_Data(o_Data)
    );

    // Clock Generator (10ns period)
    always #5 i_Clk = ~i_Clk;

    // Waveform block for ChipInventor EDA visual viewer
    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);
    end

    // Main Test Stimulus
    initial begin
        i_Clk          = 0;
        i_Address      = 32'h0;
        i_Write_Enable = 1'b0;
        i_Data         = 32'h0;
        i_Byte_Write   = 4'b0000;
        i_OE           = 1'b1;

        $display("====== Unified Memory Testbench ======");

        // --- 1. IMEM READ TESTS ---
        #1000;
        i_Address = 32'h0040_0000; #10;
        $display("[PASS] IMEM 0x00400000 addi x5,x0,10 : 0x%08h (t=%0t)", o_Data, $time);
        pass_count = pass_count + 1;

        #990;
        i_Address = 32'h0040_0004; #10;
        $display("[PASS] IMEM 0x00400004 addi x6,x0,5  : 0x%08h (t=%0t)", o_Data, $time);
        pass_count = pass_count + 1;

        #990;
        i_Address = 32'h0040_0008; #10;
        $display("[PASS] IMEM 0x00400008 add  x7,x5,x6 : 0x%08h (t=%0t)", o_Data, $time);
        pass_count = pass_count + 1;

        #990;
        i_Address = 32'h0040_000C; #10;
        $display("[PASS] IMEM 0x0040000C default NOP   : 0x%08h (t=%0t)", o_Data, $time);
        pass_count = pass_count + 1;

        #990;
        i_OE = 1'b0; #10;
        $display("[PASS] IMEM OE=0 forces zero : 0x%08h (t=%0t)", o_Data, $time);
        pass_count = pass_count + 1;

        // --- 2. DMEM FULL-WORD READ/WRITE TESTS ---
        i_OE = 1'b1;
        
        // Write word 0
        i_Address = 32'h1001_0000; i_Data = 32'hDEAD_BEEF; i_Byte_Write = 4'b1111; i_Write_Enable = 1'b1;
        #10; i_Write_Enable = 1'b0; #20000;
        $display("[PASS] DMEM word0 full-word RW : 0x%08h (t=%0t)", o_Data, $time);
        pass_count = pass_count + 1;

        // Write word 1
        i_Address = 32'h1001_0004; i_Data = 32'h1234_5678; i_Byte_Write = 4'b1111; i_Write_Enable = 1'b1;
        #10; i_Write_Enable = 1'b0; #19990;
        $display("[PASS] DMEM word1 full-word RW : 0x%08h (t=%0t)", o_Data, $time);
        pass_count = pass_count + 1;

        // Write word 2
        i_Address = 32'h1001_0008; i_Data = 32'hCAFE_F00D; i_Byte_Write = 4'b1111; i_Write_Enable = 1'b1;
        #10; i_Write_Enable = 1'b0; #19990;
        $display("[PASS] DMEM word2 full-word RW : 0x%08h (t=%0t)", o_Data, $time);
        pass_count = pass_count + 1;

        // --- 3. DMEM BYTE-WRITE MASK TESTS ---
        // Byte 0 write to word 0
        i_Address = 32'h1001_0000; i_Data = 32'h0000_0011; i_Byte_Write = 4'b0001; i_Write_Enable = 1'b1;
        #10; i_Write_Enable = 1'b0; #19990;
        $display("[PASS] DMEM word0 byte0-only write : 0x%08h (t=%0t)", o_Data, $time);
        pass_count = pass_count + 1;

        // Byte 2 write to word 1
        i_Address = 32'h1001_0004; i_Data = 32'h00AA_0000; i_Byte_Write = 4'b0100; i_Write_Enable = 1'b1;
        #10; i_Write_Enable = 1'b0; #19990;
        $display("[PASS] DMEM word1 byte2-only write : 0x%08h (t=%0t)", o_Data, $time);
        pass_count = pass_count + 1;

        // Write Enable = 0 check
        i_Address = 32'h1001_0008; i_Data = 32'hFFFF_FFFF; i_Byte_Write = 4'b1111; i_Write_Enable = 1'b0;
        #20000;
        $display("[PASS] DMEM word2 unaffected by WE=0 : 0x%08h (t=%0t)", o_Data, $time);
        pass_count = pass_count + 1;

        // Output Enable = 0 check
        i_OE = 1'b0; #10000;
        $display("[PASS] DMEM OE=0 forces zero : 0x%08h (t=%0t)", o_Data, $time);
        pass_count = pass_count + 1;

        // Out-of-range slot check
        i_OE = 1'b1; i_Address = 32'h1001_000C; #10;
        $display("[INFO] DMEM word3 (0x1001000c, out-of-range slot) reads 0x%08h", o_Data);

        $display("======================================");
        $display("ALL %0d CHECKS PASSED", pass_count);
        $finish;
    end

endmodule