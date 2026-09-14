`timescale 1ns / 1ps

module testbench();

    // Testbench Signals
    reg         we_i;
    reg  [31:0] core_address_i;
    reg  [31:0] core_data_i;
    reg  [2:0]  funct3_i;
    reg  [31:0] mem_data_i;

    wire [31:0] core_data_o;
    wire [31:0] mem_address_o;
    wire [31:0] mem_data_o;
    wire [3:0]  byte_write_o;

    integer pass_count = 0;
    integer fail_count = 0;

    // Instantiate Design Under Test (DUT)
    lsu_combinational dut (
        .we_i(we_i),
        .core_address_i(core_address_i),
        .core_data_i(core_data_i),
        .funct3_i(funct3_i),
        .core_data_o(core_data_o),
        .mem_address_o(mem_address_o),
        .mem_data_o(mem_data_o),
        .mem_data_i(mem_data_i),
        .byte_write_o(byte_write_o)
    );

    // Waveform block for ChipInventor EDA visual viewer
    initial begin
        $dumpfile("testbench.vcd");
      $dumpvars(0, testbench);
    end

    // Verification task for LOAD operations (we_i = 0)
    task check_load(
        input [31:0] addr,
        input [31:0] mem_in,
        input [2:0]  f3,
        input [31:0] exp_core_out,
        input [256:1] test_name
    );
        begin
            we_i           = 1'b0; // Force write disable
            core_address_i = addr;
            mem_data_i     = mem_in;
            funct3_i       = f3;
            core_data_i    = 32'h0;
            #10; // Wait for combinational propagation

            // Verify load data AND ensure byte_write_o is suppressed to 4'b0000
            if (core_data_o === exp_core_out && mem_address_o === addr && byte_write_o === 4'b0000) begin
                $display("[PASS] %-22s | Addr: 0x%08h | Out: 0x%08h", test_name, addr, core_data_o);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %-22s | Addr: 0x%08h | Exp: 0x%08h, Got: 0x%08h | Mask: 4'b%04b", 
                         test_name, addr, exp_core_out, core_data_o, byte_write_o);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Verification task for STORE operations (we_i = 1)
    task check_store(
        input [31:0] addr,
        input [31:0] core_in,
        input [2:0]  f3,
        input [31:0] exp_mem_out,
        input [3:0]  exp_mask,
        input [256:1] test_name
    );
        begin
            we_i           = 1'b1; // Assert write enable
            core_address_i = addr;
            core_data_i    = core_in;
            funct3_i       = f3;
            mem_data_i     = 32'h0;
            #10; // Wait for combinational propagation

            if (mem_data_o === exp_mem_out && byte_write_o === exp_mask && mem_address_o === addr) begin
                $display("[PASS] %-22s | Addr: 0x%08h | MemOut: 0x%08h | Mask: 4'b%04b", test_name, addr, mem_data_o, byte_write_o);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %-22s | Addr: 0x%08h | ExpMem: 0x%08h, GotMem: 0x%08h | ExpMask: 4'b%04b, GotMask: 4'b%04b", 
                         test_name, addr, exp_mem_out, mem_data_o, exp_mask, byte_write_o);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Main Test Stimulus
    initial begin
        $display("=======================================================================");
        $display("                 STARTING LOAD/STORE UNIT (LSU) TEST                   ");
        $display("=======================================================================");

        // --- 1. LOAD TESTS (we_i = 0) ---
        check_load(32'h1000_0000, 32'h1234_5680, 3'b000, 32'hFFFF_FF80, "LB: Offset 0 (Neg)");
        check_load(32'h1000_0001, 32'h1234_7F00, 3'b000, 32'h0000_007F, "LB: Offset 1 (Pos)");
        check_load(32'h1000_0002, 32'h12FE_3456, 3'b000, 32'hFFFF_FFFE, "LB: Offset 2 (Neg)");
        check_load(32'h1000_0003, 32'hA512_3456, 3'b000, 32'hFFFF_FFA5, "LB: Offset 3 (Neg)");

        check_load(32'h1000_0000, 32'h1234_5680, 3'b100, 32'h0000_0080, "LBU: Offset 0");
        check_load(32'h1000_0003, 32'hA512_3456, 3'b100, 32'h0000_00A5, "LBU: Offset 3");

        check_load(32'h1000_0000, 32'h1234_8005, 3'b001, 32'hFFFF_8005, "LH: Offset 0 (Neg)");
        check_load(32'h1000_0002, 32'h7FFF_1234, 3'b001, 32'h0000_7FFF, "LH: Offset 2 (Pos)");

        check_load(32'h1000_0000, 32'h1234_8005, 3'b101, 32'h0000_8005, "LHU: Offset 0");
        check_load(32'h1000_0002, 32'h8000_1234, 3'b101, 32'h0000_8000, "LHU: Offset 2");

        check_load(32'h1000_0000, 32'hDEAD_BEEF, 3'b010, 32'hDEAD_BEEF, "LW: Full Word");

        // --- 2. STORE TESTS (we_i = 1) ---
        check_store(32'h2000_0000, 32'hAAAA_BBCC, 3'b000, 32'h0000_00CC, 4'b0001, "SB: Offset 0");
        check_store(32'h2000_0001, 32'hAAAA_BBCC, 3'b000, 32'h0000_CC00, 4'b0010, "SB: Offset 1");
        check_store(32'h2000_0002, 32'hAAAA_BBCC, 3'b000, 32'h00CC_0000, 4'b0100, "SB: Offset 2");
        check_store(32'h2000_0003, 32'hAAAA_BBCC, 3'b000, 32'hCC00_0000, 4'b1000, "SB: Offset 3");

        check_store(32'h2000_0000, 32'h1234_5678, 3'b001, 32'h0000_5678, 4'b0011, "SH: Offset 0");
        check_store(32'h2000_0002, 32'h1234_5678, 3'b001, 32'h5678_0000, 4'b1100, "SH: Offset 2");

        check_store(32'h2000_0000, 32'hCAFE_BABE, 3'b010, 32'hCAFE_BABE, 4'b1111, "SW: Full Word");

        $display("=======================================================================");
        $display(" SUMMARY: %0d Passed, %0d Failed", pass_count, fail_count);
        $display("=======================================================================");
        $finish;
    end

endmodule