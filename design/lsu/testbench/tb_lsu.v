`timescale 1ns / 1ps
// ============================================================================
// Testbench: tb_lsu
// Module Under Test: LSU_UNIT / STAGE2_LSU_UNIT
// Project: ChampionCHIP eXperience (Phase 2 Challenge) - Equipe 15
// ============================================================================

module tb_lsu;

    // Core Side Signals
    reg  [31:0] core_data_o;
    reg  [31:0] core_address_o;
    reg  [2:0]  op_size_o;
    wire [31:0] core_data_i;

    // Memory (DMEM) Side Signals
    wire [31:0] mem_data_i;
    wire [31:0] mem_address_i;
    wire [3:0]  byte_write_i;
    reg  [31:0] mem_data_o;

    // Instantiate DUT
    LSU_UNIT dut (
        .core_data_o    (core_data_o),
        .core_address_o (core_address_o),
        .op_size_o      (op_size_o),
        .core_data_i    (core_data_i),
        .mem_data_i     (mem_data_i),
        .mem_address_i  (mem_address_i),
        .byte_write_i   (byte_write_i),
        .mem_data_o     (mem_data_o)
    );

    initial begin
        $dumpfile("lsu_tb.vcd");
        $dumpvars(0, tb_lsu);

        $display("=========================================================");
        $display(" Starting Load/Store Unit Testbench (tb_lsu)");
        $display("=========================================================");

        // --- STORE TESTS ---
        $display("--- STORE TESTS (op_size: 00=byte, 01=half, 10=word) ---");
        core_data_o = 32'h000000AB;
        
        // SB at offset 0
        core_address_o = 32'h10010000; op_size_o = 3'b000; #10;
        $display("[STORE SB @0] addr: 0x%08h | bw: %04b | mem_data_i: 0x%08h", core_address_o, byte_write_i, mem_data_i);

        // SB at offset 1
        core_address_o = 32'h10010001; op_size_o = 3'b000; #10;
        $display("[STORE SB @1] addr: 0x%08h | bw: %04b | mem_data_i: 0x%08h", core_address_o, byte_write_i, mem_data_i);

        // SB at offset 2
        core_address_o = 32'h10010002; op_size_o = 3'b000; #10;
        $display("[STORE SB @2] addr: 0x%08h | bw: %04b | mem_data_i: 0x%08h", core_address_o, byte_write_i, mem_data_i);

        // SB at offset 3
        core_address_o = 32'h10010003; op_size_o = 3'b000; #10;
        $display("[STORE SB @3] addr: 0x%08h | bw: %04b | mem_data_i: 0x%08h", core_address_o, byte_write_i, mem_data_i);

        // SH at offset 0
        core_data_o = 32'h0000BEEF;
        core_address_o = 32'h10010000; op_size_o = 3'b001; #10;
        $display("[STORE SH @0] addr: 0x%08h | bw: %04b | mem_data_i: 0x%08h", core_address_o, byte_write_i, mem_data_i);

        // SW
        core_data_o = 32'h12345678;
        core_address_o = 32'h10010000; op_size_o = 3'b010; #10;
        $display("[STORE SW   ] addr: 0x%08h | bw: %04b | mem_data_i: 0x%08h", core_address_o, byte_write_i, mem_data_i);

        // --- LOAD TESTS ---
        $display("--- LOAD TESTS (sign/zero extension per op_size) ---");
        mem_data_o = 32'h812345C6; // C6=-58 (MSB=1), 45=69 (MSB=0), 23=35 (MSB=0), 81=-127 (MSB=1)

        // LB @0 (signed byte)
        core_address_o = 32'h10010000; op_size_o = 3'b000; #10;
        $display("[LOAD LB  @0] read: 0x%08h -> core_data_i: 0x%08h", mem_data_o, core_data_i);

        // LBU @0 (unsigned byte)
        core_address_o = 32'h10010000; op_size_o = 3'b100; #10;
        $display("[LOAD LBU @0] read: 0x%08h -> core_data_i: 0x%08h", mem_data_o, core_data_i);

        // LW (word)
        core_address_o = 32'h10010000; op_size_o = 3'b010; #10;
        $display("[LOAD LW    ] read: 0x%08h -> core_data_i: 0x%08h", mem_data_o, core_data_i);

        // --------------------------------------------------------------------
        // TODO: Fill in additional directed load/store test cases here
        // --------------------------------------------------------------------

        $display("=========================================================");
        $display(" LSU Testbench Finished");
        $display("=========================================================");
        $finish;
    end

endmodule
