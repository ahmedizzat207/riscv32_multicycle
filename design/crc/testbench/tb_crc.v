`timescale 1ns / 1ps
// ============================================================================
// Testbench: tb_crc
// Module Under Test: STAGE2_CRC / crc8_block, crc16_block, crc32_block
// Project: ChampionCHIP eXperience (Phase 2 Challenge) - Equipe 15
// ============================================================================

module tb_crc;

    // Stimulus Signals
    reg  [31:0] rs1_i;
    reg  [31:0] rs2_i;
    reg  [3:0]  crc_op_i;
    wire [15:0] crc_data_o;

    // Instantiate DUT
    STAGE2_CRC dut (
        .rs1_i      (rs1_i),
        .rs2_i      (rs2_i),
        .crc_op_i   (crc_op_i),
        .crc_data_o (crc_data_o)
    );

    initial begin
        $dumpfile("crc_tb.vcd");
        $dumpvars(0, tb_crc);

        $display("=========================================================");
        $display(" Starting CRC Testbench (tb_crc)");
        $display("=========================================================");

        // Reference inputs from Phase 2 Team Report
        rs1_i = 32'h12345678;
        rs2_i = 32'h90ABCDEF;

        // Test CRCB (crc_op = 0) -> Expected: 0xD383
        crc_op_i = 4'h0; #10;
        $display("CRCB = %04h (Expected: d383)", crc_data_o);

        // Test CRCH (crc_op = 1) -> Expected: 0x0EC9
        crc_op_i = 4'h1; #10;
        $display("CRCH = %04h (Expected: 0ec9)", crc_data_o);

        // Test CRCW (crc_op = 2) -> Expected: 0x1E82
        crc_op_i = 4'h2; #10;
        $display("CRCW = %04h (Expected: 1e82)", crc_data_o);

        // --------------------------------------------------------------------
        // TODO: Fill in additional custom CRC stimulus or data streams here
        // --------------------------------------------------------------------

        if (crc_data_o == 16'h1E82) begin
            $display("PASS");
        end else begin
            $display("FAIL");
        end

        $display("=========================================================");
        $display(" CRC Testbench Finished");
        $display("=========================================================");
        $finish;
    end

endmodule
