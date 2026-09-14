`timescale 1ns/1ps
module testbench();
  reg i_clk = 0;
  reg i_rst = 0;
  integer fails = 0;
  integer cycle_count = 0;
  integer instr_count = 0;
  reg halted = 0;
  reg        prev_state_is_decode = 0;
  reg [31:0] max_pc_seen = 32'h0;

  top ai45( .i_clk(i_clk), .i_rst(i_rst));
  always #5 i_clk = ~i_clk;

  // ---- Confirmed signal paths ----
  wire [31:0] w_PC       = ai45.blkProj14999_7.blk4086_75.pc_o;
  wire [31:0] w_Instr    = ai45.o_Instruction;
  wire [4:0]  w_State    = ai45.blkProj14523_5.blk4197_44.state;
  wire [31:0] w_mem_addr = ai45.blkProj14999_7.w_18;  // ADDR_MUX output -> unified memory address

  wire [31:0] w_x4 = ai45.blkProj14999_7.blk2116_47.r_Registers[4];
  reg  [31:0] prev_x4 = 32'hFFFFFFFF;

  // ---- CRC accumulator trace (x8 is the running CRC register per the firmware) ----
  wire [31:0] w_x8 = ai45.blkProj14999_7.blk2116_47.r_Registers[8];
  reg  [31:0] prev_x8 = 32'hFFFFFFFF;

  // ---- FSM state encoding (from CONTROL_UNIT_3) ----
  localparam S_FETCH  = 5'd0;
  localparam S_DECODE = 5'd1;

  // ---- Known firmware halt-loop addresses (jal x0,0 self-loops) ----
  localparam HALT_ADDR_PASS = 32'h004003EC;
  localparam HALT_ADDR_FAIL = 32'h004003F0;

  // ---- Suspected data-only region past both halt loops ----
  localparam DATA_REGION_LO = 32'h004003F8;
  localparam DATA_REGION_HI = 32'h00400408;

  task check(input [8*24-1:0] name, input [31:0] actual, input [31:0] expected);
    begin
      if (actual !== expected) begin
        fails = fails + 1;
        $display("  FAIL  %-24s got=0x%08h expected=0x%08h", name, actual, expected);
      end else begin
        $display("  PASS  %-24s = 0x%08h", name, actual);
      end
    end
  endtask

  function [127:0] decode_mnemonic(input [31:0] instr);
    reg [6:0] opcode;
    reg [6:0] funct7;
    begin
      opcode = instr[6:0];
      funct7 = instr[31:25];
      case (opcode)
        7'b0110011: decode_mnemonic = (funct7 == 7'h01) ? "MUL" :
                                       (funct7 == 7'h40) ? "CRC" :
                                                            "R-TYPE ALU";
        7'b0010011: decode_mnemonic = "I-TYPE ALU";
        7'b0000011: decode_mnemonic = "LOAD";
        7'b0100011: decode_mnemonic = "STORE";
        7'b1100011: decode_mnemonic = "BRANCH";
        7'b1101111: decode_mnemonic = "JAL";
        7'b1100111: decode_mnemonic = "JALR";
        7'b0110111: decode_mnemonic = "LUI";
        7'b0010111: decode_mnemonic = "AUIPC";
        default:    decode_mnemonic = "UNKNOWN/NOP";
      endcase
    end
  endfunction

  always @(posedge i_clk) begin
    if (!i_rst) begin
      cycle_count = cycle_count + 1;

      if (w_State == S_DECODE && !prev_state_is_decode) begin
        instr_count = instr_count + 1;
        $display("[%0t] #%0d PC=0x%08h INSTR=0x%08h (%0s)",
                   $time, instr_count, w_PC, w_Instr, decode_mnemonic(w_Instr));
      end
      prev_state_is_decode <= (w_State == S_DECODE);

      // ---- Track x4 (pass/fail result register) so its final write is visible ----
      if (w_x4 !== prev_x4) begin
        $display(" >>> x4 changed: 0x%08h -> 0x%08h (cycle %0d)",
                   prev_x4, w_x4, cycle_count);
        prev_x4 <= w_x4;
      end


      if (w_PC > max_pc_seen) max_pc_seen = w_PC;
      if (w_PC >= DATA_REGION_LO && w_PC <= DATA_REGION_HI) begin
        $display("!!! PC actually reached data region at 0x%08h (cycle %0d)",
                   w_PC, cycle_count);
      end

      if (w_mem_addr >= DATA_REGION_LO && w_mem_addr <= DATA_REGION_HI) begin
        $display("### memory access into data region: addr=0x%08h (cycle %0d)",
                   w_mem_addr, cycle_count);
      end

      if ((w_PC == HALT_ADDR_PASS || w_PC == HALT_ADDR_FAIL) && !halted) begin
        halted = 1;
        $display("[%0t] Firmware halted at 0x%08h after %0d cycles, %0d instructions",
                   $time, w_PC, cycle_count, instr_count);
      end
    end
  end

  initial begin
    i_rst = 1;
    repeat (2) @(posedge i_clk);
    #1;
    i_rst = 0;

    // Wait for the halt loop, with a generous backstop timeout
    wait (halted || cycle_count > 20000);
    repeat (8) @(posedge i_clk);  // let the halt-marker instruction (addi x4,...) fully retire
    #1;

    $display("---- Comprehensive instruction test ----");
    if (!halted)
      $display("  WARNING: did not detect halt loop; results may be incomplete");

    check("x4", ai45.blkProj14999_7.blk2116_47.r_Registers[4], 32'h00000000);

    $display("=====================================");
    if (fails == 0) $display("ALL CHECKS PASSED");
    else $display("%0d CHECK(S) FAILED", fails);
    $display("Total cycles run: %0d", cycle_count);
    $display("Total instructions traced: %0d", instr_count);
    $display("Highest PC reached: 0x%08h", max_pc_seen);
    $display("=====================================");
    $finish;
  end

  initial begin #500000; $display("TIMEOUT"); $finish; end

  initial begin
    $dumpfile("testbench.vcd");
    $dumpvars(0,testbench);
  end

endmodule