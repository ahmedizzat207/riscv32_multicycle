`timescale 1ns / 1ps

module testbench();

    // Inputs
    reg         clk_i;
    reg         rst_i;
    reg         branch_taken_i;
    reg  [31:0] inst_i;
    reg         mult_busy_i;
    reg         mult_done_i;

    // Outputs
    wire [2:0]  o_Branch_Sel;
    wire [3:0]  o_Alu_Sel;
    wire [2:0]  o_Mult_Sel;
    wire [3:0]  o_Crc_Sel;
    wire [1:0]  o_Src_B_Sel;
    wire [1:0]  o_Src_A_Sel;
    wire        o_IR_Write;
    wire        o_MDR_Write;
    wire        o_lorD;
    wire        o_PC_Sel;
    wire        o_DMEM_REG_Sel;
    wire [1:0]  o_Write_Back_Sel;
    wire        o_mult_start;
    wire        o_oe;
    wire        o_Rs_Write;
    wire        o_Reg_Write;
    wire        o_Mem_Write;
    wire        o_PC_Write;
    wire        o_PC_Write_Cond;

    integer pass_count = 0;
    integer fail_count = 0;

    // Instantiate DUT
    STAGE2_CONTROL_UNIT dut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .branch_taken_i(branch_taken_i),
        .inst_i(inst_i),
        .o_Branch_Sel(o_Branch_Sel),
        .o_Alu_Sel(o_Alu_Sel),
        .o_Mult_Sel(o_Mult_Sel),
        .o_Crc_Sel(o_Crc_Sel),
        .o_Src_B_Sel(o_Src_B_Sel),
        .o_Src_A_Sel(o_Src_A_Sel),
        .o_IR_Write(o_IR_Write),
        .o_MDR_Write(o_MDR_Write),
        .o_lorD(o_lorD),
        .o_PC_Sel(o_PC_Sel),
        .o_DMEM_REG_Sel(o_DMEM_REG_Sel),
        .o_Write_Back_Sel(o_Write_Back_Sel),
        .mult_busy_i(mult_busy_i),
        .mult_done_i(mult_done_i),
        .o_mult_start(o_mult_start),
        .o_oe(o_oe),
        .o_Rs_Write(o_Rs_Write),
        .o_Reg_Write(o_Reg_Write),
        .o_Mem_Write(o_Mem_Write),
        .o_PC_Write(o_PC_Write),
        .o_PC_Write_Cond(o_PC_Write_Cond)
    );

    // Clock Generator (10ns period)
    always #5 clk_i = ~clk_i;

    // Waveform dump for ChipInventor EDA visual viewer
    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);
    end

    // Verification Task
    task check_sig(
        input [256:1] test_label,
        input [256:1] sig_name,
        input [31:0]  act_val,
        input [31:0]  exp_val
    );
        begin
            if (act_val === exp_val) begin
                $display("[PASSED] %-20s | %-12s | Actual: 0x%0h (Expected: 0x%0h) @ time %0t", 
                         test_label, sig_name, act_val, exp_val, $time);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAILED] %-20s | %-12s | Actual: 0x%0h (Expected: 0x%0h) @ time %0t", 
                         test_label, sig_name, act_val, exp_val, $time);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Main Test Stimulus
    initial begin
        clk_i          = 0;
        rst_i          = 1;
        branch_taken_i = 0;
        inst_i         = 32'h0;
        mult_busy_i    = 0;
        mult_done_i    = 0;

        #10;
        rst_i = 0;

        // --- 1. ADD Instruction Sequence ---
        inst_i = 32'h006283b3; // add x7, x5, x6
        #1;
        check_sig("ADD@FETCH", "ir_write", o_IR_Write, 1'b1);
        check_sig("ADD@FETCH", "oe",       o_oe,       1'b1);

        #10; // State: DECODE
        check_sig("ADD@DECODE", "rs_write", o_Rs_Write, 1'b1);

        #10; // State: EXEC_RTYPE
        check_sig("ADD@EXEC_RTYPE", "src_a", o_Src_A_Sel, 2'b00);
        check_sig("ADD@EXEC_RTYPE", "src_b", o_Src_B_Sel, 2'b00);
        check_sig("ADD@EXEC_RTYPE", "alu",   o_Alu_Sel,   4'h1);

        #10; // State: WB_ALU
        check_sig("ADD@WB_ALU", "reg_we",   o_Reg_Write, 1'b1);
        check_sig("ADD@WB_ALU", "wb_sel",   o_Write_Back_Sel, 2'b00);
        check_sig("ADD@WB_ALU", "pc_write", o_PC_Write,  1'b1);

        // --- 2. ADDI Instruction Sequence ---
        #10; // State: FETCH
        inst_i = 32'h00a00293; // addi x5, x0, 10
        #20; // Skip to EXEC_ITYPE
        check_sig("ADDI@EXEC_ITYPE", "src_a", o_Src_A_Sel, 2'b00);
        check_sig("ADDI@EXEC_ITYPE", "src_b", o_Src_B_Sel, 2'b10);

        #10; // State: WB_ALU
        check_sig("ADDI@WB_ALU", "reg_we", o_Reg_Write, 1'b1);

        // --- 3. LUI Instruction Sequence ---
        #10; // State: FETCH
        inst_i = 32'h123452b7; // lui x5, 0x12345
        #20; // State: EXEC_LUI
        check_sig("LUI@EXEC_LUI", "src_b", o_Src_B_Sel, 2'b10);
        check_sig("LUI@EXEC_LUI", "alu",   o_Alu_Sel,   4'h0); // PASS_B

        #10; // State: WB_ALU
        check_sig("LUI@WB_ALU", "reg_we", o_Reg_Write, 1'b1);

        // --- 4. AUIPC Instruction Sequence ---
        #10; // State: FETCH
        inst_i = 32'h00001297; // auipc x5, 0
        #20; // State: EXEC_AUIPC
        check_sig("AUIPC@EXEC_AUIPC", "src_a", o_Src_A_Sel, 2'b01);
        check_sig("AUIPC@EXEC_AUIPC", "src_b", o_Src_B_Sel, 2'b10);

        #10; // State: WB_ALU
        check_sig("AUIPC@WB_ALU", "reg_we", o_Reg_Write, 1'b1);

        // --- 5. SW (Store Word) Sequence ---
        #10; // State: FETCH
        inst_i = 32'h00642023; // sw x6, 0(x8)
        #20; // State: EXEC_ADDR_STORE
        check_sig("SW@EXEC_ADDR_STORE", "alu", o_Alu_Sel, 4'h1);

        #10; // State: MEM_WRITE
        check_sig("SW@MEM_WRITE", "mem_we", o_Mem_Write, 1'b1);

        #10; // State: PC_UPDATE
        check_sig("SW@PC_UPDATE", "pc_write", o_PC_Write, 1'b1);

        // --- 6. LW (Load Word) Sequence ---
        #10; // State: FETCH
        inst_i = 32'h00042e83; // lw x29, 0(x8)
        #30; // State: MEM_READ2
        check_sig("LW@MEM_READ2", "mdr_write", o_MDR_Write, 1'b1);

        #10; // State: WB_MEM
        check_sig("LW@WB_MEM", "reg_we", o_Reg_Write, 1'b1);

        // --- 7. BEQ Branch Sequence ---
        #10; // State: FETCH
        inst_i = 32'h00628063; // beq x5, x6, offset
        #20; // State: BR_COMPARE
        branch_taken_i = 1'b1;
        #1;
        check_sig("BEQ@BR_COMPARE", "branch_sel", o_Branch_Sel, 3'b000);
        check_sig("BEQ@BR_COMPARE", "pc_write",  o_PC_Write,   1'b1);

        // --- 8. JAL Jump Sequence ---
        #9;  // State: FETCH
        inst_i = 32'h00800f6f; // jal x30, target
        #20; // State: JAL_TARGET
        check_sig("JAL@JAL_TARGET", "reg_we",   o_Reg_Write, 1'b1);
        check_sig("JAL@JAL_TARGET", "pc_write", o_PC_Write,  1'b1);

        // --- 9. MUL Multiplication Sequence ---
        #10; // State: FETCH
        inst_i = 32'h02c58533; // mul x10, x11, x12
        #20; // State: MUL_START
        check_sig("MUL@MUL_START", "mult_start", o_mult_start, 1'b1);

        #10; // State: MUL_WAIT
        mult_done_i = 1'b1;

        #10; // State: MUL_LATCH
        check_sig("MUL@MUL_LATCH", "wb_sel", o_Write_Back_Sel, 2'b01);

        #10; // State: WB_ALU
        check_sig("MUL@WB_ALU", "reg_we", o_Reg_Write, 1'b1);

        // --- 10. CRC Sequence ---
        #10; // State: FETCH
        inst_i = 32'h80848433; // crcb x8, x9, x8
        #20; // State: EXEC_CRC
        check_sig("CRC@EXEC_CRC", "crc_sel", o_Crc_Sel, 4'h0);

        #10; // State: WB_ALU
        check_sig("CRC@WB_ALU", "reg_we", o_Reg_Write, 1'b1);

        // --- 11. System Instructions (FENCE, ECALL, EBREAK) ---
        #10; // State: FETCH
        inst_i = 32'h0000000f; // FENCE
        #20;
        check_sig("FENCE", "reg_we_stays", o_Reg_Write, 1'b0);
        check_sig("FENCE", "mem_we_stays", o_Mem_Write, 1'b0);

        #20; // Fetch next
        inst_i = 32'h00000073; // ECALL
        #20;
        check_sig("ECALL", "reg_we_stays", o_Reg_Write, 1'b0);
        check_sig("ECALL", "mem_we_stays", o_Mem_Write, 1'b0);

        #20; // Fetch next
        inst_i = 32'h00100073; // EBREAK
        #20;
        check_sig("EBREAK", "reg_we_stays", o_Reg_Write, 1 me_Write, 1'b0);

        #10;
        $display("=======================================================================");
        $display(" SUMMARY: %0d Passed, %0d Failed", pass_count, fail_count);
        $display("=======================================================================");
        $finish;
    end

endmodule