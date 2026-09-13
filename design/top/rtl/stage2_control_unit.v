// ============================================================================
// CONTROL_UNIT_3: Multicycle Finite State Machine Controller
// ============================================================================
// Controls instruction execution through:
// - Fetch (S_FETCH)
// - Decode (S_DECODE)
// - Execute (S_EXEC_RTYPE, S_EXEC_ITYPE, S_EXEC_LUI, S_EXEC_AUIPC, S_EXEC_CRC,
//            S_EXEC_ADDR_LOAD, S_EXEC_ADDR_STORE, S_BR_TARGET, S_JAL_LINK, S_JALR_LINK, S_MUL_START)
// - Memory Access (S_MEM_READ1, S_MEM_READ2, S_MEM_WRITE)
// - Write Back (S_WB_ALU, S_WB_MEM)
// - Multi-cycle Multiplication wait states (S_MUL_WAIT, S_MUL_LATCH)
// ============================================================================

module CONTROL_UNIT_3 (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire [31:0] instr_i,
    input  wire        branch_taken_i,
    input  wire        mult_busy_i,
    input  wire        mult_done_i,

    output reg  [2:0]  o_Branch_Sel,
    output reg  [3:0]  o_Alu_Sel,
    output reg  [2:0]  o_Mult_Sel,
    output reg  [3:0]  o_Crc_sel,
    output reg  [1:0]  o_Src_B_Sel,
    output reg  [1:0]  o_Src_A_Sel,
    output reg         o_IR_Write,
    output reg         o_MDR_Write,
    output reg         o_lorD,
    output reg         o_PC_Sel,
    output reg         o_DMEM_REG_Sel,
    output reg  [1:0]  o_Write_Back_Sel,
    output reg         o_mult_start,
    output reg         o_oe,
    output reg         o_Reg_Write,
    output reg         o_Rs_Write,
    output reg         o_Mem_Write,
    output reg         o_PC_Write,
    output reg         o_PC_Write_Cond
);

    // ---- ALU opcodes (must match the ALU module exactly) ----
    localparam ALU_PASS_B = 4'h0;
    localparam ALU_ADD    = 4'h1;
    localparam ALU_SUB    = 4'h2;
    localparam ALU_AND    = 4'h3;
    localparam ALU_OR     = 4'h4;
    localparam ALU_XOR    = 4'h5;
    localparam ALU_SLL    = 4'h6;
    localparam ALU_SRL    = 4'h7;
    localparam ALU_SRA    = 4'h8;
    localparam ALU_SLT    = 4'h9;
    localparam ALU_SLTU   = 4'hA;

    // ---- opcodes ----
    localparam OP_RTYPE  = 7'b0110011;
    localparam OP_ITYPE  = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;

    // ---- funct7 subgroups (opcode == OP_RTYPE) ----
    localparam F7_MUL = 7'b0000001;
    localparam F7_CRC = 7'b1000000;   // 0x40, per Block Guide

    // ---- instruction field extraction ----
    wire [6:0] opcode = instr_i[6:0];
    wire [2:0] funct3 = instr_i[14:12];
    wire [6:0] funct7 = instr_i[31:25];
    wire       bit30  = instr_i[30];

    function [3:0] calc_alu_sel;
        input is_rtype;
        input [2:0] f3;
        input       b30;
        begin
            case (f3)
                3'b000:  calc_alu_sel = (is_rtype && b30) ? ALU_SUB : ALU_ADD;
                3'b001:  calc_alu_sel = ALU_SLL;
                3'b010:  calc_alu_sel = ALU_SLT;
                3'b011:  calc_alu_sel = ALU_SLTU;
                3'b100:  calc_alu_sel = ALU_XOR;
                3'b101:  calc_alu_sel = b30 ? ALU_SRA : ALU_SRL;
                3'b110:  calc_alu_sel = ALU_OR;
                3'b111:  calc_alu_sel = ALU_AND;
                default: calc_alu_sel = ALU_ADD;
            endcase
        end
    endfunction

    // ---- states ----
    localparam S_FETCH           = 5'd0;
    localparam S_DECODE          = 5'd1;
    localparam S_EXEC_RTYPE      = 5'd2;
    localparam S_EXEC_ITYPE      = 5'd3;
    localparam S_EXEC_LUI        = 5'd4;
    localparam S_EXEC_AUIPC      = 5'd5;
    localparam S_WB_ALU          = 5'd6;
    localparam S_EXEC_ADDR_LOAD  = 5'd7;
    localparam S_MEM_READ1       = 5'd8;
    localparam S_MEM_READ2       = 5'd9;
    localparam S_WB_MEM          = 5'd10;
    localparam S_EXEC_ADDR_STORE = 5'd11;
    localparam S_MEM_WRITE       = 5'd12;
    localparam S_PC_UPDATE       = 5'd13;
    localparam S_BR_TARGET       = 5'd14;
    localparam S_BR_COMPARE      = 5'd15;
    localparam S_JAL_LINK        = 5'd16;
    localparam S_JAL_TARGET      = 5'd17;
    localparam S_MUL_START       = 5'd18;
    localparam S_MUL_WAIT        = 5'd19;
    localparam S_MUL_LATCH       = 5'd20;
    localparam S_EXEC_CRC        = 5'd21;
    localparam S_JALR_LINK       = 5'd22;
    localparam S_JALR_TARGET     = 5'd23;
    localparam S_JALR_MASK       = 5'd24;

    reg [4:0] state, next_state;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) state <= S_FETCH;
        else       state <= next_state;
    end

    always @(*) begin
        // ---- safe defaults every cycle; each state overrides only what it needs ----
        o_Branch_Sel     = 3'b000;
        o_Alu_Sel        = ALU_ADD;
        o_Mult_Sel       = 3'b000;
        o_Crc_sel        = 4'h0;
        o_Src_B_Sel      = 2'b00;
        o_Src_A_Sel      = 2'b00;
        o_IR_Write       = 1'b0;
        o_MDR_Write      = 1'b0;
        o_lorD           = 1'b0;
        o_PC_Sel         = 1'b0;
        o_DMEM_REG_Sel   = 1'b0;
        o_Write_Back_Sel = 2'b00;
        o_mult_start     = 1'b0;
        o_oe             = 1'b0;
        o_Reg_Write      = 1'b0;
        o_Rs_Write       = 1'b0;
        o_Mem_Write      = 1'b0;
        o_PC_Write       = 1'b0;
        o_PC_Write_Cond  = 1'b0;

        next_state = S_FETCH;

        case (state)

            // ---------------------------------------------------------
            S_FETCH: begin
                o_lorD     = 1'b0;   // address = PC
                o_oe       = 1'b1;
                o_IR_Write = 1'b1;
                next_state = S_DECODE;
            end

            // ---------------------------------------------------------
            S_DECODE: begin
                o_Rs_Write = 1'b1;
                case (opcode)
                    OP_RTYPE: begin
                        if (funct7 == F7_MUL)      next_state = S_MUL_START;
                        else if (funct7 == F7_CRC) next_state = S_EXEC_CRC;
                        else                       next_state = S_EXEC_RTYPE;
                    end
                    OP_ITYPE:  next_state = S_EXEC_ITYPE;
                    OP_LOAD:   next_state = S_EXEC_ADDR_LOAD;
                    OP_STORE:  next_state = S_EXEC_ADDR_STORE;
                    OP_BRANCH: next_state = S_BR_TARGET;
                    OP_JAL:    next_state = S_JAL_LINK;
                    OP_JALR:   next_state = S_JALR_LINK;
                    OP_LUI:    next_state = S_EXEC_LUI;
                    OP_AUIPC:  next_state = S_EXEC_AUIPC;
                    default:   next_state = S_PC_UPDATE;
                endcase
            end

            // ---------------------------------------------------------
            S_EXEC_RTYPE: begin
                o_Src_A_Sel = 2'b00;                        // rs1
                o_Src_B_Sel = 2'b00;                        // rs2
                o_Alu_Sel   = calc_alu_sel(1'b1, funct3, bit30);
                o_Write_Back_Sel = 2'b00;                   // ALU
                next_state  = S_WB_ALU;
            end

            S_EXEC_ITYPE: begin
                o_Src_A_Sel = 2'b00;                         // rs1
                o_Src_B_Sel = 2'b10;                         // immediate
                o_Alu_Sel   = calc_alu_sel(1'b0, funct3, bit30);
                o_Write_Back_Sel = 2'b00;
                next_state  = S_WB_ALU;
            end

            S_EXEC_LUI: begin
                o_Src_B_Sel = 2'b10;                         // immediate (already shifted by imm_generator)
                o_Alu_Sel   = ALU_PASS_B;
                o_Write_Back_Sel = 2'b00;
                next_state  = S_WB_ALU;
            end

            S_EXEC_AUIPC: begin
                o_Src_A_Sel = 2'b01;                         // PC (still original -- Fetch never wrote it)
                o_Src_B_Sel = 2'b10;                         // immediate
                o_Alu_Sel   = ALU_ADD;
                o_Write_Back_Sel = 2'b00;
                next_state  = S_WB_ALU;
            end

            S_EXEC_CRC: begin
                o_Src_A_Sel = 2'b00;                         // rs1
                o_Src_B_Sel = 2'b00;                         // rs2
                o_Crc_sel   = {1'b0, funct3};               // funct3 selects CRC8/16/32
                o_Write_Back_Sel = 2'b10;                    // CRC
                next_state  = S_WB_ALU;
            end

            // ---------------------------------------------------------
            // Writeback for any ALU/MULT/CRC result, combined with the
            // PC+4 commit in the same cycle.
            S_WB_ALU: begin
                o_Reg_Write    = 1'b1;
                o_DMEM_REG_Sel = 1'b1;    // ALUOut register (still valid pre-edge)
                o_Src_A_Sel = 2'b01;       // PC
                o_Src_B_Sel = 2'b01;      // constant 4
                o_Alu_Sel   = ALU_ADD;
                o_Write_Back_Sel = 2'b00;
                o_PC_Write  = 1'b1;
                o_PC_Sel    = 1'b0;       // PC_Next = live ALU result (PC+4)
                next_state  = S_FETCH;
            end

            // ---------------------------------------------------------
            S_EXEC_ADDR_LOAD: begin
                o_Src_A_Sel = 2'b00;       // rs1
                o_Src_B_Sel = 2'b10;      // immediate
                o_Alu_Sel   = ALU_ADD;
                o_Write_Back_Sel = 2'b00;
                next_state  = S_MEM_READ1;
            end

            S_MEM_READ1: begin
                o_Src_A_Sel = 2'b00;
                o_Src_B_Sel = 2'b10;
                o_Alu_Sel   = ALU_ADD;
                o_lorD = 1'b1;
                o_oe   = 1'b1;
                next_state = S_MEM_READ2;
            end
            S_MEM_READ2: begin
                o_Src_A_Sel = 2'b00;
                o_Src_B_Sel = 2'b10;
                o_Alu_Sel   = ALU_ADD;
                o_lorD = 1'b1;
                o_oe   = 1'b1;
                o_MDR_Write = 1'b1;
                next_state = S_WB_MEM;
            end

            S_WB_MEM: begin
                o_Reg_Write    = 1'b1;
                o_DMEM_REG_Sel = 1'b0;    // MDR value
                o_Src_A_Sel = 2'b01;       // PC
                o_Src_B_Sel = 2'b01;      // constant 4
                o_Alu_Sel   = ALU_ADD;
                o_Write_Back_Sel = 2'b00;
                o_PC_Write  = 1'b1;
                o_PC_Sel    = 1'b0;
                next_state  = S_FETCH;
            end

            // ---------------------------------------------------------
            S_EXEC_ADDR_STORE: begin
                o_Src_A_Sel = 2'b00;       // rs1
                o_Src_B_Sel = 2'b10;      // immediate
                o_Alu_Sel   = ALU_ADD;
                o_Write_Back_Sel = 2'b00;
                next_state  = S_MEM_WRITE;
            end

            S_MEM_WRITE: begin
                o_lorD      = 1'b1;
                o_Mem_Write = 1'b1;
                next_state  = S_PC_UPDATE;
            end

            // stores get no free writeback cycle to piggyback the PC+4 commit on
            S_PC_UPDATE: begin
                o_Src_A_Sel = 2'b01;       // PC
                o_Src_B_Sel = 2'b01;      // constant 4
                o_Alu_Sel   = ALU_ADD;
                o_Write_Back_Sel = 2'b00;
                o_PC_Write  = 1'b1;
                o_PC_Sel    = 1'b0;
                next_state  = S_FETCH;
            end

            S_BR_TARGET: begin
                o_Src_A_Sel = 2'b01;       // PC (still original)
                o_Src_B_Sel = 2'b10;      // immediate
                o_Alu_Sel   = ALU_ADD;
                o_Write_Back_Sel = 2'b00;
                next_state  = S_BR_COMPARE;
            end

            // Branch resolution handles both outcomes:
            // Taken: write PC this cycle from ALU_Out (target latched in S_BR_TARGET).
            // Not taken: fall through to S_PC_UPDATE to commit PC+4.
            S_BR_COMPARE: begin
                o_Src_A_Sel  = 2'b00;      // rs1
                o_Src_B_Sel  = 2'b00;      // rs2
                o_Branch_Sel = funct3;
                if (branch_taken_i) begin
                    o_PC_Write = 1'b1;
                    o_PC_Sel   = 1'b1;     // PC_Next = latched branch target
                    next_state = S_FETCH;
                end else begin
                    next_state = S_PC_UPDATE;  // PC_Next = PC+4
                end
            end

            S_JAL_LINK: begin
                o_Src_A_Sel = 2'b01;       // PC
                o_Src_B_Sel = 2'b01;      // constant 4
                o_Alu_Sel   = ALU_ADD;
                o_Write_Back_Sel = 2'b00;
                next_state  = S_JAL_TARGET;
            end

            S_JAL_TARGET: begin
                o_Reg_Write    = 1'b1;
                o_DMEM_REG_Sel = 1'b1;    // link value
                o_Src_A_Sel = 2'b01;       // PC
                o_Src_B_Sel = 2'b10;      // immediate
                o_Alu_Sel   = ALU_ADD;
                o_PC_Write  = 1'b1;
                o_PC_Sel    = 1'b0;       // PC_Next = live ALU result (target)
                next_state  = S_FETCH;
            end

            S_JALR_LINK: begin
                o_Src_A_Sel = 2'b01;       // PC
                o_Src_B_Sel = 2'b01;      // constant 4
                o_Alu_Sel   = ALU_ADD;
                o_Write_Back_Sel = 2'b00;
                next_state  = S_JALR_TARGET;
            end

            S_JALR_TARGET: begin
                o_Reg_Write    = 1'b1;
                o_DMEM_REG_Sel = 1'b1;    // link value
                o_Src_A_Sel = 2'b00;       // rs1
                o_Src_B_Sel = 2'b10;      // immediate
                o_Alu_Sel   = ALU_ADD;
                o_Write_Back_Sel = 2'b00;
                next_state  = S_JALR_MASK;
            end

            S_JALR_MASK: begin
                o_Src_A_Sel = 2'b10;      // ALUOut feedback
                o_Src_B_Sel = 2'b11;      // mask constant (0xFFFFFFFE)
                o_Alu_Sel   = ALU_AND;
                o_PC_Write  = 1'b1;
                o_PC_Sel    = 1'b0;
                next_state  = S_FETCH;
            end

            S_MUL_START: begin
                o_Src_A_Sel  = 2'b00;      // rs1
                o_Src_B_Sel  = 2'b00;      // rs2
                o_Mult_Sel   = funct3;
                o_mult_start = 1'b1;
                next_state   = S_MUL_WAIT;
            end

            S_MUL_WAIT: begin
                o_Mult_Sel = funct3;
                next_state = mult_done_i ? S_MUL_LATCH : S_MUL_WAIT;
            end

            S_MUL_LATCH: begin
                o_Write_Back_Sel = 2'b01;  // MULT result
                next_state       = S_WB_ALU;
            end

            default: next_state = S_FETCH;

        endcase
    end

endmodule

// ============================================================================
// STAGE2_CONTROL_UNIT: ChipInventor Stage 2 Wrapper for Control Unit
// ============================================================================
module STAGE2_CONTROL_UNIT (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire        branch_taken_i,
    input  wire [31:0] inst_i,
    output wire [2:0]  o_Branch_Sel,
    output wire [3:0]  o_Alu_Sel,
    output wire [2:0]  o_Mult_Sel,
    output wire [3:0]  o_Crc_Sel,
    output wire [1:0]  o_Src_B_Sel,
    output wire [1:0]  o_Src_A_Sel,
    output wire        o_IR_Write,
    output wire        o_MDR_Write,
    output wire        o_lorD,
    output wire        o_PC_Sel,
    output wire        o_DMEM_REG_Sel,
    output wire [1:0]  o_Write_Back_Sel,
    input  wire        mult_busy_i,
    input  wire        mult_done_i,
    output wire        o_mult_start,
    output wire        o_oe,
    output wire        o_Rs_Write,
    output wire        o_Reg_Write,
    output wire        o_Mem_Write,
    output wire        o_PC_Write,
    output wire        o_PC_Write_Cond
);

    CONTROL_UNIT_3 blk4197_44 (
        .clk_i            (clk_i),
        .rst_i            (rst_i),
        .branch_taken_i   (branch_taken_i),
        .instr_i          (inst_i[31:0]),
        .o_Branch_Sel     (o_Branch_Sel[2:0]),
        .o_Alu_Sel        (o_Alu_Sel[3:0]),
        .o_Mult_Sel       (o_Mult_Sel[2:0]),
        .o_Crc_sel        (o_Crc_Sel[3:0]),
        .o_Src_B_Sel      (o_Src_B_Sel[1:0]),
        .o_Src_A_Sel      (o_Src_A_Sel[1:0]),
        .o_IR_Write       (o_IR_Write),
        .o_MDR_Write      (o_MDR_Write),
        .o_lorD           (o_lorD),
        .o_PC_Sel         (o_PC_Sel),
        .o_DMEM_REG_Sel   (o_DMEM_REG_Sel),
        .o_Write_Back_Sel (o_Write_Back_Sel[1:0]),
        .mult_busy_i      (mult_busy_i),
        .mult_done_i      (mult_done_i),
        .o_mult_start     (o_mult_start),
        .o_oe             (o_oe),
        .o_Rs_Write       (o_Rs_Write),
        .o_Reg_Write      (o_Reg_Write),
        .o_Mem_Write      (o_Mem_Write),
        .o_PC_Write       (o_PC_Write),
        .o_PC_Write_Cond  (o_PC_Write_Cond)
    );

endmodule
