// ============================================================================
// ChipInventor RVBL-2 Core - Consolidated Design Module
// ChampionCHIP eXperience (Phase 2 Challenge) - Equipe 15
// 
// Team Members:
// - Ahmed Izzat Sidahmed Ali Tahir
// - Ng Kah Lok
// - Gan Shao Hng
// - Jolin Tan
// - Fatin Nuralya Binti Mohamad
// ============================================================================

`default_nettype wire

//  ---------- INLCUDED BLOCK: MUX2_32  ---------- 
module MUX2_32 (
  input [31:0] A, 
  input [31:0] B, 
  input S, 
  output [31:0] Z
);
  assign Z = (S) ? B : A;
endmodule



//  ---------- INLCUDED BLOCK: REGISTER_FILE  ---------- 
module REGISTER_FILE # (
    parameter p_DATA_MEM_SIZE = 2**10
)(
    input [31:0] i_Data_Rd,
    input [31:0] i_Instruction,
    input i_Write_Enable,
    input i_Clk,
    input i_Rst,
    output [31:0] o_Data_Rs_1,
    output [31:0] o_Data_Rs_2  
);
    /* Constants */
    localparam c_SP_INDEX = 2;
    localparam c_GP_INDEX = 3;
    localparam c_GP_INITIAL_VALUE = 32'h1001_0000;
    localparam c_SP_INITIAL_VALUE = c_GP_INITIAL_VALUE + p_DATA_MEM_SIZE - 4;

    /* Instruction fields */
    wire [4:0] w_Select_Rd = i_Instruction[11:7];
    wire [4:0] w_Select_Rs_1 = i_Instruction[19:15];
    wire [4:0] w_Select_Rs_2 = i_Instruction[24:20];
  
    /* Registers Data */
    reg [31:0] r_Registers [0:31];
  
    integer i;
    always @(posedge i_Clk or posedge i_Rst) begin
        if(i_Rst) begin
            for(i = 0; i < 32; i = i + 1) begin
                case (i)
                    c_SP_INDEX: r_Registers[i] = c_SP_INITIAL_VALUE;
                    c_GP_INDEX: r_Registers[i] = c_GP_INITIAL_VALUE;
                    default:    r_Registers[i] = 32'h0;
                endcase
            end
        end
        else begin 
            if(i_Write_Enable && w_Select_Rd != 5'h0) begin
                r_Registers[w_Select_Rd] = i_Data_Rd;
            end
        end
    end
    
    assign o_Data_Rs_1 = r_Registers[w_Select_Rs_1];

    assign o_Data_Rs_2 = r_Registers[w_Select_Rs_2];

endmodule



//  ---------- INLCUDED BLOCK: ALU  ---------- 
module ALU (
    input signed [31:0] i_A,
    input signed [31:0] i_B,
  	input [3:0] i_Sel,
    output reg signed [31:0] o_Q
);
    localparam c_ALU_OP_PASS_B = 4'h0;
    localparam c_ALU_OP_ADD    = 4'h1;
    localparam c_ALU_OP_SUB    = 4'h2;
    localparam c_ALU_OP_AND    = 4'h3;
    localparam c_ALU_OP_OR     = 4'h4;
    localparam c_ALU_OP_XOR    = 4'h5;
    localparam c_ALU_OP_SLL    = 4'h6;
    localparam c_ALU_OP_SRL    = 4'h7;
    localparam c_ALU_OP_MRS    = 4'h8;   // SRA (arithmetic right shift)
    localparam c_ALU_OP_SLT    = 4'h9;
    localparam c_ALU_OP_SLTU   = 4'hA;
  
    always @ (*) begin
        case (i_Sel)
            c_ALU_OP_PASS_B: o_Q = i_B;
            c_ALU_OP_ADD:    o_Q = i_A + i_B;
            c_ALU_OP_SUB:    o_Q = i_A - i_B;
            c_ALU_OP_AND:    o_Q = i_A & i_B;
            c_ALU_OP_OR:     o_Q = i_A | i_B;
            c_ALU_OP_XOR:    o_Q = i_A ^ i_B;
            c_ALU_OP_SLL:    o_Q = i_A << i_B[4:0];
            c_ALU_OP_SRL:    o_Q = i_A >> i_B[4:0];    // logical: >> always zero-fills
            c_ALU_OP_MRS:    o_Q = i_A >>> i_B[4:0];   // arithmetic: >>> sign-extends on signed operands
            c_ALU_OP_SLT:    o_Q = (i_A < i_B) ? 32'h1 : 32'h0;                        // signed compare
            c_ALU_OP_SLTU:   o_Q = ($unsigned(i_A) < $unsigned(i_B)) ? 32'h1 : 32'h0;  // forced unsigned compare
            default:         o_Q = 32'h0;
        endcase
    end
endmodule



//  ---------- INLCUDED BLOCK: crc8_block  ---------- 
module crc8_block (
    input  wire [31:0] rs1_i,
    input  wire [31:0] rs2_i,
    output reg  [15:0] crc8_o
);

    localparam [15:0] POLY = 16'h1021;

    reg [15:0] crc;
    integer i;

    always @(*) begin

        crc = rs2_i[15:0];           

        crc = crc ^ {rs1_i[7:0], 8'h00}; 

        for (i = 0; i < 8; i = i + 1) begin
            if (crc[15])
                crc = (crc << 1) ^ POLY;
            else
                crc = crc << 1;
        end

        crc8_o = crc;

    end

endmodule



//  ---------- INLCUDED BLOCK: crc16_block  ---------- 
module crc16_block (
    input  wire [31:0] rs1_i,
    input  wire [31:0] rs2_i,
    output reg  [15:0] crc16_o
);

    localparam [15:0] POLY = 16'h1021;

    reg [15:0] crc;
    integer i;

    always @(*) begin

        crc = rs2_i[15:0];                 

        // Byte 0
        crc = crc ^ {rs1_i[15:8], 8'h00};    

        for (i = 0; i < 8; i = i + 1) begin
            if (crc[15])
                crc = (crc << 1) ^ POLY;
            else
                crc = crc << 1;
        end

        // Byte 1
        crc = crc ^ {rs1_i[7:0], 8'h00};       

        for (i = 0; i < 8; i = i + 1) begin
            if (crc[15])
                crc = (crc << 1) ^ POLY;
            else
                crc = crc << 1;
        end

        crc16_o = crc;

    end

endmodule



//  ---------- INLCUDED BLOCK: crc32_block  ---------- 
module crc32_block (
    input  wire [31:0] rs1_i,
    input  wire [31:0] rs2_i,
    output reg  [15:0] crc32_o
);

    localparam [15:0] POLY = 16'h1021;

    reg [15:0] crc;
    integer i;

    always @(*) begin

        crc = rs2_i[15:0]; 

        // Byte 0 of rs1
        crc = crc ^ {rs1_i[31:24], 8'h00};
        for (i = 0; i < 8; i = i + 1) begin
            if (crc[15]) crc = (crc << 1) ^ POLY;
            else         crc = crc << 1;
        end

        // Byte 1 of rs1
        crc = crc ^ {rs1_i[23:16], 8'h00};
        for (i = 0; i < 8; i = i + 1) begin
            if (crc[15]) crc = (crc << 1) ^ POLY;
            else         crc = crc << 1;
        end

        // Byte 2 of rs1
        crc = crc ^ {rs1_i[15:8], 8'h00};
        for (i = 0; i < 8; i = i + 1) begin
            if (crc[15]) crc = (crc << 1) ^ POLY;
            else         crc = crc << 1;
        end

        // Byte 3 of rs1
        crc = crc ^ {rs1_i[7:0], 8'h00};
        for (i = 0; i < 8; i = i + 1) begin
            if (crc[15]) crc = (crc << 1) ^ POLY;
            else         crc = crc << 1;
        end

        crc32_o = crc;

    end

endmodule



//  ---------- INLCUDED BLOCK: crc_unit_mux  ---------- 
module crc_unit_mux (
    input  wire [15:0] crc8_i,
    input  wire [15:0] crc16_i,
    input  wire [15:0] crc32_i,
    input  wire [3:0]  crc_op_i,
    output reg  [15:0] crc_data_o
);

    always @(*) begin
        case (crc_op_i)

            4'h0: crc_data_o = crc8_i;
            4'h1: crc_data_o = crc16_i;
            4'h2: crc_data_o = crc32_i;

            default:
                crc_data_o = 16'hFFFF;

        endcase
    end

endmodule



//  ---------- INLCUDED BLOCK: imm_generator  ---------- 
module imm_generator (
    input  wire [31:0] inst_i,      // 32-bit Instruction (from IR)
    output reg  [31:0] imm_out_o    // Formatted 32-bit Immediate
);

    wire [6:0] opcode = inst_i[6:0];

    always @(*) begin
        case (opcode)
            // I-Type Instructions (ADDI, SLTI, LW, JALR, SYSTEM [ECALL/EBREAK], MISC-MEM [FENCE])
            7'b0010011, 7'b0000011, 7'b1100111, 7'b1110011, 7'b0001111: begin
                imm_out_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end
            
            // S-Type Instructions (SW, SH, SB)
            7'b0100011: begin
                imm_out_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
            end
            
            // B-Type Instructions (BEQ, BNE, BLT, BGE, BLTU, BGEU)
            7'b1100011: begin
                imm_out_o = {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
            end
            
            // U-Type Instructions (LUI, AUIPC)
            7'b0110111, 7'b0010111: begin
                imm_out_o = {inst_i[31:12], 12'b0};
            end
            
            // J-Type Instructions (JAL)
            7'b1101111: begin
                imm_out_o = {{11{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
            end
            
            default: imm_out_o = 32'h00000000;
        endcase
    end

endmodule



//  ---------- INLCUDED BLOCK: branch_comparator  ---------- 
module branch_comparator (
    input  wire [31:0] a_i,           // Operand A (from rs1 / A_reg)
    input  wire [31:0] b_i,           // Operand B (from rs2 / B_reg)
    input  wire [2:0]  funct3_i,      // Instruction funct3 field
    output reg branch_taken_o // 1 if condition met, 0 otherwise
);
  
    always @(*) begin
        case (funct3_i)
            3'b000: branch_taken_o = (a_i == b_i);                     // BEQ
            3'b001: branch_taken_o = (a_i != b_i);                     // BNE
            3'b100: branch_taken_o = ($signed(a_i) < $signed(b_i));   // BLT
            3'b101: branch_taken_o = ($signed(a_i) >= $signed(b_i));  // BGE
            3'b110: branch_taken_o = (a_i < b_i);                     // BLTU
            3'b111: branch_taken_o = (a_i >= b_i);                    // BGEU
            default: branch_taken_o = 1'b0;
        endcase
    end

endmodule



//  ---------- INLCUDED BLOCK: RISCV_ADDR_DECODER  ---------- 
module RISCV_ADDR_DECODER (
    input  [31:0] i_Address,
    input         i_Write_Enable,
    input  [3:0]  i_Byte_Write,
    input  [31:0] i_Data,    
  	input i_OE,

    output [31:0] o_Address,     
    output        o_DMEM_Write_Enable,
    output [3:0]  o_DMEM_Byte_Write,
    output [31:0] o_Data,  
  	output o_Mem_Sel, // "1" = DMEM, "0" = IMEM
  	output o_OE
);

    assign o_Address = i_Address;
    assign o_Data     = i_Data;

    // DMEM ranges from 0x10010000; IMEM ranges from 0x00400000
    wire is_dmem = (i_Address[31:16] == 16'h1001);
  	assign o_Mem_Sel = !is_dmem;

    assign o_DMEM_Write_Enable = is_dmem ? i_Write_Enable : 1'b0;
    assign o_DMEM_Byte_Write   = is_dmem ? i_Byte_Write   : 4'b0000;
  assign o_OE = i_OE;

endmodule



//  ---------- INLCUDED BLOCK: RISCV_IMEM  ---------- 
module RISCV_IMEM (
  input  wire [31:0] i_Address,
  input  wire i_OE,
  output reg [31:0] o_Instruction
);

    always @(*) begin
        if (!i_OE) begin
            o_Instruction = 32'h0;
        end else begin
            case (i_Address)
              	32'h00400000: o_Instruction = 32'h123452B7;
                32'h00400004: o_Instruction = 32'h12345337;
                32'h00400008: o_Instruction = 32'h3E629463;
                32'h0040000C: o_Instruction = 32'h00001297;
                32'h00400010: o_Instruction = 32'h3E028063;
                32'h00400014: o_Instruction = 32'h00A00293;
                32'h00400018: o_Instruction = 32'hFFD28313;
                32'h0040001C: o_Instruction = 32'h00700393;
                32'h00400020: o_Instruction = 32'h3C731863;
                32'h00400024: o_Instruction = 32'h006283B3;
                32'h00400028: o_Instruction = 32'h01100E13;
                32'h0040002C: o_Instruction = 32'h3DC39263;
                32'h00400030: o_Instruction = 32'h405E03B3;
                32'h00400034: o_Instruction = 32'h3A639E63;
                32'h00400038: o_Instruction = 32'h0FF00293;
                32'h0040003C: o_Instruction = 32'h0F02C313;
                32'h00400040: o_Instruction = 32'h00F00393;
                32'h00400044: o_Instruction = 32'h3A731663;
                32'h00400048: o_Instruction = 32'h7002E313;
                32'h0040004C: o_Instruction = 32'h7FF00393;
                32'h00400050: o_Instruction = 32'h3A731063;
                32'h00400054: o_Instruction = 32'h0F02F313;
                32'h00400058: o_Instruction = 32'h0F000393;
                32'h0040005C: o_Instruction = 32'h38731A63;
                32'h00400060: o_Instruction = 32'h0AA00293;
                32'h00400064: o_Instruction = 32'h05500313;
                32'h00400068: o_Instruction = 32'h0062C3B3;
                32'h0040006C: o_Instruction = 32'h0FF00E13;
                32'h00400070: o_Instruction = 32'h39C39063;
                32'h00400074: o_Instruction = 32'h0062E3B3;
                32'h00400078: o_Instruction = 32'h37C39C63;
                32'h0040007C: o_Instruction = 32'h0062F3B3;
                32'h00400080: o_Instruction = 32'h36039863;
                32'h00400084: o_Instruction = 32'h00100293;
                32'h00400088: o_Instruction = 32'h00429313;
                32'h0040008C: o_Instruction = 32'h01000393;
                32'h00400090: o_Instruction = 32'h36731063;
                32'h00400094: o_Instruction = 32'h0023D313;
                32'h00400098: o_Instruction = 32'h00400E13;
                32'h0040009C: o_Instruction = 32'h35C31A63;
                32'h004000A0: o_Instruction = 32'hFF000293;
                32'h004000A4: o_Instruction = 32'h4022D313;
                32'h004000A8: o_Instruction = 32'hFFC00393;
                32'h004000AC: o_Instruction = 32'h34731263;
                32'h004000B0: o_Instruction = 32'h00100293;
                32'h004000B4: o_Instruction = 32'h00400313;
                32'h004000B8: o_Instruction = 32'h006293B3;
                32'h004000BC: o_Instruction = 32'h01000E13;
                32'h004000C0: o_Instruction = 32'h33C39863;
                32'h004000C4: o_Instruction = 32'h00200313;
                32'h004000C8: o_Instruction = 32'h006E53B3;
                32'h004000CC: o_Instruction = 32'h00400E93;
                32'h004000D0: o_Instruction = 32'h33D39063;
                32'h004000D4: o_Instruction = 32'hFF000293;
                32'h004000D8: o_Instruction = 32'h4062D3B3;
                32'h004000DC: o_Instruction = 32'hFFC00E93;
                32'h004000E0: o_Instruction = 32'h31D39863;
                32'h004000E4: o_Instruction = 32'h00A00293;
                32'h004000E8: o_Instruction = 32'h0142A313;
                32'h004000EC: o_Instruction = 32'h00100393;
                32'h004000F0: o_Instruction = 32'h30731063;
                32'h004000F4: o_Instruction = 32'hFF600293;
                32'h004000F8: o_Instruction = 32'h0142B313;
                32'h004000FC: o_Instruction = 32'h2E031A63;
                32'h00400100: o_Instruction = 32'h00A00293;
                32'h00400104: o_Instruction = 32'h01400313;
                32'h00400108: o_Instruction = 32'h0062A3B3;
                32'h0040010C: o_Instruction = 32'h00100E13;
                32'h00400110: o_Instruction = 32'h2FC39063;
                32'h00400114: o_Instruction = 32'h005333B3;
                32'h00400118: o_Instruction = 32'h2C039C63;
                32'h0040011C: o_Instruction = 32'h0FC10417;
                32'h00400120: o_Instruction = 32'hEE440413;
                32'h00400124: o_Instruction = 32'h12345337;
                32'h00400128: o_Instruction = 32'h67830313;
                32'h0040012C: o_Instruction = 32'h00642023;
                32'h00400130: o_Instruction = 32'h0000B3B7;
                32'h00400134: o_Instruction = 32'hABB38393;
                32'h00400138: o_Instruction = 32'h00741223;
                32'h0040013C: o_Instruction = 32'h0CC00E13;
                32'h00400140: o_Instruction = 32'h01C40423;
                32'h00400144: o_Instruction = 32'h00042E83;
                32'h00400148: o_Instruction = 32'h2A6E9463;
                32'h0040014C: o_Instruction = 32'h00441F03;
                32'h00400150: o_Instruction = 32'hFFFFBFB7;
                32'h00400154: o_Instruction = 32'hABBF8F93;
                32'h00400158: o_Instruction = 32'h29FF1C63;
                32'h0040015C: o_Instruction = 32'h00445F03;
                32'h00400160: o_Instruction = 32'h0000BFB7;
                32'h00400164: o_Instruction = 32'hABBF8F93;
                32'h00400168: o_Instruction = 32'h29FF1463;
                32'h0040016C: o_Instruction = 32'h00840F03;
                32'h00400170: o_Instruction = 32'hFCC00F93;
                32'h00400174: o_Instruction = 32'h27FF1E63;
                32'h00400178: o_Instruction = 32'h00844F03;
                32'h0040017C: o_Instruction = 32'h0CC00F93;
                32'h00400180: o_Instruction = 32'h27FF1863;
                32'h00400184: o_Instruction = 32'h00500293;
                32'h00400188: o_Instruction = 32'h00A00313;
                32'h0040018C: o_Instruction = 32'h00500393;
                32'h00400190: o_Instruction = 32'hFF600E13;
                32'h00400194: o_Instruction = 32'hFF600E93;
                32'h00400198: o_Instruction = 32'h00728463;
                32'h0040019C: o_Instruction = 32'h2540006F;
                32'h004001A0: o_Instruction = 32'h01DE0463;
                32'h004001A4: o_Instruction = 32'h24C0006F;
                32'h004001A8: o_Instruction = 32'h00629463;
                32'h004001AC: o_Instruction = 32'h2440006F;
                32'h004001B0: o_Instruction = 32'h01C29463;
                32'h004001B4: o_Instruction = 32'h23C0006F;
                32'h004001B8: o_Instruction = 32'h0062C463;
                32'h004001BC: o_Instruction = 32'h2340006F;
                32'h004001C0: o_Instruction = 32'h005E4463;
                32'h004001C4: o_Instruction = 32'h22C0006F;
                32'h004001C8: o_Instruction = 32'h00535463;
                32'h004001CC: o_Instruction = 32'h2240006F;
                32'h004001D0: o_Instruction = 32'h01C2D463;
                32'h004001D4: o_Instruction = 32'h21C0006F;
                32'h004001D8: o_Instruction = 32'h0062E463;
                32'h004001DC: o_Instruction = 32'h2140006F;
                32'h004001E0: o_Instruction = 32'h01C2E463;
                32'h004001E4: o_Instruction = 32'h20C0006F;
                32'h004001E8: o_Instruction = 32'h00537463;
                32'h004001EC: o_Instruction = 32'h2040006F;
                32'h004001F0: o_Instruction = 32'h005E7463;
                32'h004001F4: o_Instruction = 32'h1FC0006F;
                32'h004001F8: o_Instruction = 32'h00800F6F;
                32'h004001FC: o_Instruction = 32'h1F40006F;
                32'h00400200: o_Instruction = 32'h00000F97;
                32'h00400204: o_Instruction = 32'h010F8F93;
                32'h00400208: o_Instruction = 32'h000F8067;
                32'h0040020C: o_Instruction = 32'h1E40006F;
                32'h00400210: o_Instruction = 32'h00100013;
                32'h00400214: o_Instruction = 32'h1C001E63;
                32'h00400218: o_Instruction = 32'hDEADC2B7;
                32'h0040021C: o_Instruction = 32'hEEF28293;
                32'h00400220: o_Instruction = 32'h00028313;
                32'h00400224: o_Instruction = 32'h00030393;
                32'h00400228: o_Instruction = 32'h00038F93;
                32'h0040022C: o_Instruction = 32'hDEADC2B7;
                32'h00400230: o_Instruction = 32'hEEF28293;
                32'h00400234: o_Instruction = 32'h1A5F9E63;
                32'h00400238: o_Instruction = 32'h000185B7;
                32'h0040023C: o_Instruction = 32'h6A058593;
                32'h00400240: o_Instruction = 32'h00200613;
                32'h00400244: o_Instruction = 32'hEE6B36B7;
                32'h00400248: o_Instruction = 32'h80068693;
                32'h0040024C: o_Instruction = 32'h000312B7;
                32'h00400250: o_Instruction = 32'hD4028293;
                32'h00400254: o_Instruction = 32'hDCD65337;
                32'h00400258: o_Instruction = 32'hFFF00393;
                32'h0040025C: o_Instruction = 32'h00100E13;
                32'h00400260: o_Instruction = 32'h02C58533;
                32'h00400264: o_Instruction = 32'h18551663;
                32'h00400268: o_Instruction = 32'h02C68533;
                32'h0040026C: o_Instruction = 32'h18651263;
                32'h00400270: o_Instruction = 32'h02C59533;
                32'h00400274: o_Instruction = 32'h16051E63;
                32'h00400278: o_Instruction = 32'h02C69533;
                32'h0040027C: o_Instruction = 32'h16751A63;
                32'h00400280: o_Instruction = 32'h02C6B533;
                32'h00400284: o_Instruction = 32'h17C51663;
                32'h00400288: o_Instruction = 32'h02C6A533;
                32'h0040028C: o_Instruction = 32'h16751263;
                32'h00400290: o_Instruction = 32'h02D62533;
                32'h00400294: o_Instruction = 32'h15C51E63;
                32'h00400298: o_Instruction = 32'h000028B7;
                32'h0040029C: o_Instruction = 32'hE8288893;
                32'h004002A0: o_Instruction = 32'h00010437;
                32'h004002A4: o_Instruction = 32'hFFF40413;
                32'h004002A8: o_Instruction = 32'h01200493;
                32'h004002AC: o_Instruction = 32'h03400913;
                32'h004002B0: o_Instruction = 32'h05600993;
                32'h004002B4: o_Instruction = 32'h07800A13;
                32'h004002B8: o_Instruction = 32'h09000A93;
                32'h004002BC: o_Instruction = 32'h0AB00B13;
                32'h004002C0: o_Instruction = 32'h0CD00B93;
                32'h004002C4: o_Instruction = 32'h0EF00C13;
                32'h004002C8: o_Instruction = 32'h80848433;
                32'h004002CC: o_Instruction = 32'h80890433;
                32'h004002D0: o_Instruction = 32'h80898433;
                32'h004002D4: o_Instruction = 32'h808A0433;
                32'h004002D8: o_Instruction = 32'h808A8433;
                32'h004002DC: o_Instruction = 32'h808B0433;
                32'h004002E0: o_Instruction = 32'h808B8433;
                32'h004002E4: o_Instruction = 32'h808C0433;
                32'h004002E8: o_Instruction = 32'h11141463;
                32'h004002EC: o_Instruction = 32'h000102B7;
                32'h004002F0: o_Instruction = 32'hFFF28293;
                32'h004002F4: o_Instruction = 32'h00001337;
                32'h004002F8: o_Instruction = 32'h23430313;
                32'h004002FC: o_Instruction = 32'h000053B7;
                32'h00400300: o_Instruction = 32'h67838393;
                32'h00400304: o_Instruction = 32'h00009E37;
                32'h00400308: o_Instruction = 32'h0ABE0E13;
                32'h0040030C: o_Instruction = 32'h0000DEB7;
                32'h00400310: o_Instruction = 32'hDEFE8E93;
                32'h00400314: o_Instruction = 32'h805312B3;
                32'h00400318: o_Instruction = 32'h805392B3;
                32'h0040031C: o_Instruction = 32'h805E12B3;
                32'h00400320: o_Instruction = 32'h805E92B3;
                32'h00400324: o_Instruction = 32'h0D129663;
                32'h00400328: o_Instruction = 32'h00010537;
                32'h0040032C: o_Instruction = 32'hFFF50513;
                32'h00400330: o_Instruction = 32'h123455B7;
                32'h00400334: o_Instruction = 32'h67858593;
                32'h00400338: o_Instruction = 32'h90ABD637;
                32'h0040033C: o_Instruction = 32'hDEF60613;
                32'h00400340: o_Instruction = 32'h80A5A533;
                32'h00400344: o_Instruction = 32'h80A62533;
                32'h00400348: o_Instruction = 32'h0B151463;
                32'h0040034C: o_Instruction = 32'h00000297;
                32'h00400350: o_Instruction = 32'h0AC28293;
                32'h00400354: o_Instruction = 32'h0002A303;
                32'h00400358: o_Instruction = 32'h0042A383;
                32'h0040035C: o_Instruction = 32'h00010537;
                32'h00400360: o_Instruction = 32'hFFF50513;
                32'h00400364: o_Instruction = 32'h80A32533;
                32'h00400368: o_Instruction = 32'h80A3A533;
                32'h0040036C: o_Instruction = 32'h000028B7;
                32'h00400370: o_Instruction = 32'hE8288893;
                32'h00400374: o_Instruction = 32'h07151E63;
                32'h00400378: o_Instruction = 32'h01400293;
                32'h0040037C: o_Instruction = 32'h00A00313;
                32'h00400380: o_Instruction = 32'h006283B3;
                32'h00400384: o_Instruction = 32'h40628E33;
                32'h00400388: o_Instruction = 32'h03C38EB3;
                32'h0040038C: o_Instruction = 32'h12C00F13;
                32'h00400390: o_Instruction = 32'h07EE9063;
                32'h00400394: o_Instruction = 32'h00000297;
                32'h00400398: o_Instruction = 32'h06C28293;
                32'h0040039C: o_Instruction = 32'h0FC10317;
                32'h004003A0: o_Instruction = 32'hC7430313;
                32'h004003A4: o_Instruction = 32'h00300393;
                32'h004003A8: o_Instruction = 32'h0002AE03;
                32'h004003AC: o_Instruction = 32'h01C32023;
                32'h004003B0: o_Instruction = 32'h00428293;
                32'h004003B4: o_Instruction = 32'h00430313;
                32'h004003B8: o_Instruction = 32'hFFF38393;
                32'h004003BC: o_Instruction = 32'hFE0396E3;
                32'h004003C0: o_Instruction = 32'h0FC10317;
                32'h004003C4: o_Instruction = 32'hC5030313;
                32'h004003C8: o_Instruction = 32'h00032E03;
                32'h004003CC: o_Instruction = 32'h11111EB7;
                32'h004003D0: o_Instruction = 32'h111E8E93;
                32'h004003D4: o_Instruction = 32'h01DE1E63;
                32'h004003D8: o_Instruction = 32'h00832E03;
                32'h004003DC: o_Instruction = 32'h33333EB7;
                32'h004003E0: o_Instruction = 32'h333E8E93;
                32'h004003E4: o_Instruction = 32'h01DE1663;
                32'h004003E8: o_Instruction = 32'h00000213;
                32'h004003EC: o_Instruction = 32'h0000006F;
                32'h004003F0: o_Instruction = 32'hFFF00213;
                32'h004003F4: o_Instruction = 32'h0000006F;
                32'h004003F8: o_Instruction = 32'h12345678;
                32'h004003FC: o_Instruction = 32'h90ABCDEF;
                32'h00400400: o_Instruction = 32'h11111111;
                32'h00400404: o_Instruction = 32'h22222222;
                32'h00400408: o_Instruction = 32'h33333333;


        		default:
            		o_Instruction = 32'h00000013; // NOP
            endcase
        end
    end

endmodule



//  ---------- INLCUDED BLOCK: RISCV_DMEM  ---------- 
module RISCV_DMEM (
    input  wire i_Clk,
  input  wire [31:0] i_Address,
    input  wire [31:0]           i_Data,
    input  wire [3:0]            i_ByteWrite,    // bw_o
    input  wire                  i_WriteEnable,  // dmem_we_o
    input  wire                  i_OE,           // oe_o
    output reg  [31:0]           o_Data
);
  reg [31:0] r_Mem [0:2047]; // 2048 words = 8 KB
 
  wire [10:0] w_Index = i_Address[12:2];

    // Synchronous, per-byte write
    always @(posedge i_Clk) begin
        if (i_WriteEnable) begin
            if (i_ByteWrite[0]) r_Mem[w_Index][7:0]   <= i_Data[7:0];
            if (i_ByteWrite[1]) r_Mem[w_Index][15:8]  <= i_Data[15:8];
            if (i_ByteWrite[2]) r_Mem[w_Index][23:16] <= i_Data[23:16];
            if (i_ByteWrite[3]) r_Mem[w_Index][31:24] <= i_Data[31:24];
        end
    end

    always @(posedge i_Clk) begin
        if (i_OE)
            o_Data <= r_Mem[w_Index];
        else
            o_Data <= 32'h0;
    end

endmodule



//  ---------- INLCUDED BLOCK: multiplier_sequential  ---------- 
module multiplier_sequential (
    input  wire        clk_i,
    input  wire        rst_i,

    // Control Interface
    input  wire        start_i,        // Start signal (mult_start_o from Control Unit)
    input  wire [2:0]  funct3_i,       // Instruction funct3 (000=MUL, 001=MULH, 010=MULHSU, 011=MULHU)
    input  wire [31:0] operand_a_i,    // rs1 data
    input  wire [31:0] operand_b_i,    // rs2 data
    output reg  [31:0] result_o,       // 32-bit result routed to Writeback MUX
    output reg         busy_o,         // High while calculating
    output reg         done_o          // Handshake completion pulse (mult_done_i)
);

    // ------------------------------------------------------------------------
    // FSM States & Registers
    // ------------------------------------------------------------------------
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam FINI = 2'b10;

    reg [1:0]  state;
    reg [5:0]  count;
    reg [2:0]  funct3_r;
    reg        sign_result_r;

    reg [63:0] multiplicand;
    reg [31:0] multiplier;
    reg [63:0] accum;

    // ------------------------------------------------------------------------
    // Sign Extraction Logic
    // ------------------------------------------------------------------------
    wire a_is_signed = (funct3_i == 3'b001 || funct3_i == 3'b010) && operand_a_i[31]; // MULH, MULHSU
    wire b_is_signed = (funct3_i == 3'b001) && operand_b_i[31];                       // MULH

    // Absolute magnitudes for signed operands
    wire [31:0] abs_a = a_is_signed ? (~operand_a_i + 1'b1) : operand_a_i;
    wire [31:0] abs_b = b_is_signed ? (~operand_b_i + 1'b1) : operand_b_i;

    // ------------------------------------------------------------------------
    // Sequential State Machine & Iterative Kernel
    // ------------------------------------------------------------------------
    reg [63:0] final_product;

  always @(posedge clk_i or posedge rst_i) begin
      if (rst_i) begin
            state         <= IDLE;
            count         <= 6'd0;
            funct3_r      <= 3'd0;
            sign_result_r <= 1'b0;
            multiplicand  <= 64'd0;
            multiplier    <= 32'd0;
            accum         <= 64'd0;
            result_o      <= 32'd0;
            busy_o        <= 1'b0;
            done_o        <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done_o <= 1'b0;
                    if (start_i) begin
                        funct3_r      <= funct3_i;
                        sign_result_r <= a_is_signed ^ b_is_signed; // Result is negative if signs differ
                        multiplicand  <= {32'd0, abs_a};
                        multiplier    <= abs_b;
                        accum         <= 64'd0;
                        count         <= 6'd0;
                        busy_o        <= 1'b1;
                        state         <= CALC;
                    end
                end

                CALC: begin
                    // Shift-and-Add Algorithm Step
                    if (multiplier[0]) begin
                        accum <= accum + multiplicand;
                    end
                    multiplicand <= multiplicand << 1;
                    multiplier   <= multiplier >> 1;
                    count        <= count + 1'b1;

                    if (count == 6'd31) begin
                        state <= FINI;
                    end
                end

                FINI: begin
                    busy_o <= 1'b0;
                    done_o <= 1'b1;

                    // Apply sign adjustment if negative
                    final_product = sign_result_r ? (~accum + 1'b1) : accum;

                    // Select output word based on instruction funct3
                    case (funct3_r)
                        3'b000:  result_o <= final_product[31:0];  // MUL (Lower 32 bits)
                        3'b001,                                    // MULH (Upper 32 bits, Signed x Signed)
                        3'b010,                                    // MULHSU (Upper 32 bits, Signed x Unsigned)
                        3'b011:  result_o <= final_product[63:32]; // MULHU (Upper 32 bits, Unsigned x Unsigned)
                        default: result_o <= final_product[31:0];
                    endcase

                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule



//  ---------- INLCUDED BLOCK: MUX3_32  ---------- 
module MUX3_32 (
  input [31:0] ALU, 
  input [31:0] MULT, 
  input [15:0] CRC, 
  input [1:0]Sel, 
  output reg [31:0] Result
);
  
  always @ (*) begin
        case (Sel)
            2'b00: Result = ALU;
            2'b01: Result = MULT;
          2'b10: Result = {16'b0, CRC};
           
            default: Result = ALU;
        endcase
    end
endmodule



//  ---------- INLCUDED BLOCK: rs1_reg  ---------- 
module rs1_reg (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire        en_i,        // load enable, e.g. asserted during Decode state
    input  wire [31:0] rs1_data_i,  // data straight from register file read port
    output reg  [31:0] rs1_data_o   // latched value, held for use in Execute
);

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            rs1_data_o <= 32'b0;
        else if (en_i)
            rs1_data_o <= rs1_data_i;
    end

endmodule



//  ---------- INLCUDED BLOCK: rs2_reg  ---------- 
module rs2_reg (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire        en_i,        // load enable, e.g. asserted during Decode state
  input  wire [31:0] rs2_data_i,  // data straight from register file read port
  output reg  [31:0] rs2_data_o   // latched value, held for use in Execute
);

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            rs2_data_o <= 32'b0;
        else if (en_i)
            rs2_data_o <= rs2_data_i;
    end

endmodule



//  ---------- INLCUDED BLOCK: MUX_SRC_A  ---------- 
module MUX_SRC_A (
  input [31:0] Rs_1,
  input [31:0] PC,
  input [31:0] ALUOut,
  input [1:0] Src_A_Sel,
  output reg [31:0] Src_A
);
  always @ (*) begin
    case (Src_A_Sel)
      2'b00: Src_A = Rs_1;
      2'b01: Src_A = PC;
      2'b10: Src_A = ALUOut;   // feedback of latched result, for JALR masking
      default: Src_A = Rs_1;
    endcase
  end
endmodule



//  ---------- INLCUDED BLOCK: MUX_SRC_B  ---------- 
module MUX_SRC_B (
  input [31:0] Rs_2, 
  input [31:0] Imm, 
  input [1:0] Src_B_Sel, 
  output reg [31:0] Src_B
);
  always @ (*) begin
        case (Src_B_Sel)
            2'b00: Src_B = Rs_2;
            2'b01: Src_B = 32'd4;
          	2'b10: Src_B = Imm;
           	2'b11: Src_B = 32'hFFFFFFFE;  // bit0-clear mask, for JALR
            default: Src_B = Rs_2;
        endcase
    end
endmodule



//  ---------- INLCUDED BLOCK: inst_reg  ---------- 
module inst_reg (
    input  wire        i_Clk,
    input  wire        i_Rst,          // synchronous, active-high
    input  wire        i_IR_Write,     // asserted by Control FSM during Fetch
    input  wire [31:0] i_Instruction,  // shared memory bus (o_Data / o_Read_Data)
    output reg  [31:0] o_Instruction   // latched instruction seen by Decode
);

    always @(posedge i_Clk) begin
        if (i_Rst)
            o_Instruction <= 32'h00000013; // NOP (addi x0, x0, 0) -- safe default
                                            // so a reset doesn't leave Decode
                                            // looking at garbage/X before the
                                            // first real Fetch completes
        else if (i_IR_Write)
            o_Instruction <= i_Instruction;
        // else: hold current value (no assignment)
    end

endmodule



//  ---------- INLCUDED BLOCK: mem_data_reg  ---------- 
module mem_data_reg (
    input  wire        i_Clk,
    input  wire        i_Rst,        
    input  wire        i_MDR_Write,  
    input  wire [31:0] i_Data,       
    output reg  [31:0] o_Data        
);

    always @(posedge i_Clk) begin
        if (i_Rst)
            o_Data <= 32'h00000000;
        else if (i_MDR_Write)
            o_Data <= i_Data;
       
    end

endmodule



//  ---------- INLCUDED BLOCK: PC  ---------- 
module PC (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire        pc_write_i,   // unconditional PC update (e.g. after Fetch)
    input  wire        pcwrite_cond_i, // conditional update (branch taken)
    input  wire         branch_taken_i, // from branch comparator, qualifies pcwrite_cond
    input  wire [31:0] pc_next_i,    // output of PCSrc mux (PC+4 or branch/jump target)
    output reg  [31:0] pc_o
);

    wire pc_en = pc_write_i | (pcwrite_cond_i & branch_taken_i);

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            pc_o <= 32'h00400000;   // reset vector = IMEM base, per your memory map
        else if (pc_en)
            pc_o <= pc_next_i;
    end

endmodule



//  ---------- INLCUDED BLOCK: ADDR_MUX  ---------- 
module ADDR_MUX (
  input [31:0] PC_o, 
  input [31:0] ALUOut_o, 
  input lorD, 
  output [31:0] Addr
);
  assign Addr = (lorD) ? ALUOut_o : PC_o;
endmodule



//  ---------- INLCUDED BLOCK: EXECUTE_RESULT_REG  ---------- 
module EXECUTE_RESULT_REG (
    input  wire        clk_i,
    input  wire        rst_i,
  input  wire [31:0] exe_result_i,  
  output reg  [31:0] exeout_o
);

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            exeout_o <= 32'h0;
        else
            exeout_o <= exe_result_i;   // always latches, every cycle
    end

endmodule



//  ---------- INLCUDED BLOCK: PC_Next_MUX  ---------- 
module PC_Next_MUX (
  input [31:0] ALU_Result, 
  input [31:0] ALU_Out, 
  input PC_Sel, 
  output [31:0] PC_Next
);
  assign PC_Next = (PC_Sel) ? ALU_Out : ALU_Result;
endmodule



//  ---------- INLCUDED BLOCK: DMEM_TO_REG_MUX  ---------- 
module DMEM_TO_REG_MUX (
  input [31:0] DMEM, 
  input [31:0] ALUOut_o, 
  input DMEM_REG_Sel, 
  output [31:0] Data_o
);
  assign Data_o = (DMEM_REG_Sel) ? ALUOut_o : DMEM;
endmodule



//  ---------- INLCUDED BLOCK: LSU_UNIT  ---------- 
module LSU_UNIT (
    input  wire [31:0] core_data_o,     // store data from datapath (RD2)
    input  wire [31:0] core_address_o,  // address from datapath (ALU result)
    input  wire [2:0]  op_size_o,       // size/sign control from datapath
    output reg  [31:0] core_data_i,     // load data returned to datapath

    // ---- Memory (DMEM) side ----
    output reg  [31:0] mem_data_i,      // aligned write data -> DMEM
    output wire [31:0] mem_address_i,   // address -> DMEM (passthrough)
    output reg  [3:0]  byte_write_i,    // byte-write mask -> DMEM
    input  wire [31:0] mem_data_o       // raw read data <- DMEM
);

    assign mem_address_i = core_address_o;

    wire [1:0] addr_low = core_address_o[1:0];

    // -----------------------------------------------------------
    // STORE PATH: align core_data_o into the correct byte lane(s)
    // and generate the byte-write mask
    // -----------------------------------------------------------
    always @(*) begin
        mem_data_i   = 32'b0;
        byte_write_i = 4'b0000;

        case (op_size_o[1:0])
            // ---- byte ----
            2'b00: begin
                case (addr_low)
                    2'b00: begin mem_data_i = {24'b0, core_data_o[7:0]};        byte_write_i = 4'b0001; end
                    2'b01: begin mem_data_i = {16'b0, core_data_o[7:0], 8'b0};  byte_write_i = 4'b0010; end
                    2'b10: begin mem_data_i = {8'b0,  core_data_o[7:0], 16'b0}; byte_write_i = 4'b0100; end
                    2'b11: begin mem_data_i = {core_data_o[7:0], 24'b0};        byte_write_i = 4'b1000; end
                endcase
            end

            // ---- halfword ----
            2'b01: begin
                case (addr_low[1])
                    1'b0: begin mem_data_i = {16'b0, core_data_o[15:0]};  byte_write_i = 4'b0011; end
                    1'b1: begin mem_data_i = {core_data_o[15:0], 16'b0};  byte_write_i = 4'b1100; end
                endcase
            end

            // ---- word ----
            2'b10: begin
                mem_data_i   = core_data_o;
                byte_write_i = 4'b1111;
            end

            default: begin
                mem_data_i   = 32'b0;
                byte_write_i = 4'b0000;
            end
        endcase
    end

    // -----------------------------------------------------------
    // LOAD PATH: extract addressed byte/half/word from mem_data_o
    // and sign/zero-extend per op_size_o
    // -----------------------------------------------------------
    reg [7:0]  byte_sel;
    reg [15:0] half_sel;

    always @(*) begin
        case (addr_low)
            2'b00: byte_sel = mem_data_o[7:0];
            2'b01: byte_sel = mem_data_o[15:8];
            2'b10: byte_sel = mem_data_o[23:16];
            2'b11: byte_sel = mem_data_o[31:24];
        endcase

        case (addr_low[1])
            1'b0: half_sel = mem_data_o[15:0];
            1'b1: half_sel = mem_data_o[31:16];
        endcase

        case (op_size_o)
            3'b000:  core_data_i = {{24{byte_sel[7]}},  byte_sel}; // LB  (sign-extend)
            3'b100:  core_data_i = {24'b0,               byte_sel}; // LBU (zero-extend)
            3'b001:  core_data_i = {{16{half_sel[15]}},  half_sel}; // LH  (sign-extend)
            3'b101:  core_data_i = {16'b0,               half_sel}; // LHU (zero-extend)
            3'b010:  core_data_i = mem_data_o;                      // LW  (full word)
            default: core_data_i = 32'b0;
        endcase
    end

endmodule



//  ---------- INLCUDED BLOCK: op_size_decoder  ---------- 
module op_size_decoder (
    input  wire [31:0] inst_i,
    output wire [2:0]  op_size_o
);
    assign op_size_o = inst_i[14:12];
endmodule



//  ---------- INLCUDED BLOCK: CONTROL_UNIT_3  ---------- 
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
            // PC+4 commit in the same cycle (Option 2).
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

            // ---------------------------------------------------------
            // Branch resolution handles both outcomes:
            // Taken:     write PC this cycle from ALU_Out (target latched
            //            last cycle in S_BR_TARGET, still valid here).
            // Not taken: fall through to S_PC_UPDATE, which computes and
            //            commits PC+4 next cycle (same state stores use).
            S_BR_COMPARE: begin
                o_Src_A_Sel  = 2'b00;      // rs1 (needed so branch_taken_i is valid)
                o_Src_B_Sel  = 2'b00;      // rs2
                o_Branch_Sel = funct3;
                if (branch_taken_i) begin
                    o_PC_Write = 1'b1;
                    o_PC_Sel   = 1'b1;     // PC_Next = latched branch target
                    next_state = S_FETCH;
                end else begin
                    next_state = S_PC_UPDATE;  // PC_Next = PC+4, computed next cycle
                end
            end

            S_JAL_LINK: begin
                o_Src_A_Sel = 2'b01;       // PC (original)
                o_Src_B_Sel = 2'b01;      // constant 4
                o_Alu_Sel   = ALU_ADD;
                o_Write_Back_Sel = 2'b00;
                next_state  = S_JAL_TARGET;
            end

            S_JAL_TARGET: begin
                o_Reg_Write    = 1'b1;
                o_DMEM_REG_Sel = 1'b1;    // link value (latched last cycle, still valid)
                o_Src_A_Sel = 2'b01;       // PC (still original)
                o_Src_B_Sel = 2'b10;      // immediate
                o_Alu_Sel   = ALU_ADD;
                o_PC_Write  = 1'b1;
                o_PC_Sel    = 1'b0;       // PC_Next = live ALU result (target)
                next_state  = S_FETCH;
            end

            S_JALR_LINK: begin
                o_Src_A_Sel = 2'b01;       // PC (original)
                o_Src_B_Sel = 2'b01;      // constant 4
                o_Alu_Sel   = ALU_ADD;
                o_Write_Back_Sel = 2'b00;
                next_state  = S_JALR_TARGET;
            end

            S_JALR_TARGET: begin
                o_Reg_Write    = 1'b1;
                o_DMEM_REG_Sel = 1'b1;    // link value (latched last cycle, still valid)
                o_Src_A_Sel = 2'b00;       // rs1 (NOT PC -- this is the difference from JAL)
                o_Src_B_Sel = 2'b10;      // immediate
                o_Alu_Sel   = ALU_ADD;
                o_Write_Back_Sel = 2'b00;
                next_state  = S_JALR_MASK;
            end

            S_JALR_MASK: begin
                o_Src_A_Sel = 2'b10;      // "ALUOut" feedback, as wired in the pasted design
                o_Src_B_Sel = 2'b11;      // mask constant (0xFFFFFFFE)
                o_Alu_Sel   = ALU_AND;
                o_PC_Write  = 1'b1;
                o_PC_Sel    = 1'b0;
                next_state  = S_FETCH;
            end

            S_MUL_START: begin
                o_Src_A_Sel  = 2'b00;      // rs1
                o_Src_B_Sel  = 2'b00;     // rs2
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



// ---------- INCLUDED IP: STAGE2_ALU ---------- 
module STAGE2_ALU (
  input wire [31:0] i_A,
  input wire [31:0] i_B,
  input wire [3:0] i_Sel,
  output wire [31:0] o_Q
);
  ALU blk3085_2 (
         .i_A (i_A[31:0]),
         .i_B (i_B[31:0]),
         .i_Sel (i_Sel[3:0]),
         .o_Q (o_Q[31:0])
     );
endmodule



// ---------- INCLUDED IP: STAGE2_CONTROL_UNIT ---------- 
module STAGE2_CONTROL_UNIT (
  input wire clk_i,
  input wire rst_i,
  input wire branch_taken_i,
  input wire [31:0] inst_i,
  output wire [2:0] o_Branch_Sel,
  output wire [3:0] o_Alu_Sel,
  output wire [2:0] o_Mult_Sel,
  output wire [3:0] o_Crc_Sel,
  output wire [1:0] o_Src_B_Sel,
  output wire [1:0] o_Src_A_Sel,
  output wire o_IR_Write,
  output wire o_MDR_Write,
  output wire o_lorD,
  output wire o_PC_Sel,
  output wire o_DMEM_REG_Sel,
  output wire [1:0] o_Write_Back_Sel,
  input wire mult_busy_i,
  input wire mult_done_i,
  output wire o_mult_start,
  output wire o_oe,
  output wire o_Rs_Write,
  output wire o_Reg_Write,
  output wire o_Mem_Write,
  output wire o_PC_Write,
  output wire o_PC_Write_Cond
);

CONTROL_UNIT_3 blk4197_44 (
         .clk_i (clk_i),
         .rst_i (rst_i),
         .branch_taken_i (branch_taken_i),
         .instr_i (inst_i[31:0]),
         .o_Branch_Sel (o_Branch_Sel[2:0]),
         .o_Alu_Sel (o_Alu_Sel[3:0]),
         .o_Mult_Sel (o_Mult_Sel[2:0]),
         .o_Crc_sel (o_Crc_Sel[3:0]),
         .o_Src_B_Sel (o_Src_B_Sel[1:0]),
         .o_Src_A_Sel (o_Src_A_Sel[1:0]),
         .o_IR_Write (o_IR_Write),
         .o_MDR_Write (o_MDR_Write),
         .o_lorD (o_lorD),
         .o_PC_Sel (o_PC_Sel),
         .o_DMEM_REG_Sel (o_DMEM_REG_Sel),
         .o_Write_Back_Sel (o_Write_Back_Sel[1:0]),
         .mult_busy_i (mult_busy_i),
         .mult_done_i (mult_done_i),
         .o_mult_start (o_mult_start),
         .o_oe (o_oe),
         .o_Rs_Write (o_Rs_Write),
         .o_Reg_Write (o_Reg_Write),
         .o_Mem_Write (o_Mem_Write),
         .o_PC_Write (o_PC_Write),
         .o_PC_Write_Cond (o_PC_Write_Cond)
     );

endmodule



// ---------- INCLUDED IP: STAGE2_CRC ---------- 
module STAGE2_CRC (
  input wire [31:0] rs1_i,
  input wire [31:0] rs2_i,
  input wire [3:0] crc_op_i,
  output wire [15:0] crc_data_o
);

 wire [15:0] w_1;
 wire [15:0] w_2;
 wire [15:0] w_3;

crc8_block blk3875_1 (
         .rs1_i (rs1_i[31:0]),
         .rs2_i (rs2_i[31:0]),
         .crc8_o (w_1)
     );

crc32_block blk3877_3 (
         .rs1_i (rs1_i[31:0]),
         .rs2_i (rs2_i[31:0]),
         .crc32_o (w_2)
     );

crc_unit_mux blk3878_4 (
         .crc_op_i (crc_op_i[3:0]),
         .crc_data_o (crc_data_o[15:0]),
         .crc8_i (w_1),
         .crc32_i (w_2),
         .crc16_i (w_3)
     );

crc16_block blk3876_9 (
         .rs1_i (rs1_i[31:0]),
         .rs2_i (rs2_i[31:0]),
         .crc16_o (w_3)
     );

endmodule



// ---------- INCLUDED IP: STAGE2_IMM_GEN ---------- 
module STAGE2_IMM_GEN (
  output wire [31:0] imm_out_o,
  input wire [31:0] inst_i
);
imm_generator blk3885_16 (
         .imm_out_o (imm_out_o[31:0]),
         .inst_i (inst_i[31:0])
     );
endmodule



// ---------- INCLUDED IP: STAGE2_BRANCH_COMPARATOR ---------- 
module STAGE2_BRANCH_COMPARATOR (
  input wire [31:0] a_i,
  input wire [2:0] funct3_i,
  input wire [31:0] b_i,
  output wire branch_taken_o
);
branch_comparator blk3886_28 (
         .a_i (a_i[31:0]),
         .funct3_i (funct3_i[2:0]),
         .b_i (b_i[31:0]),
         .branch_taken_o (branch_taken_o)
     );
endmodule



// ---------- INCLUDED IP: STAGE2_UNIFIED_MEMORY ---------- 
module STAGE2_UNIFIED_MEMORY (
  output wire [31:0] o_Data,
  input wire [31:0] i_Address,
  input wire i_Write_Enable,
  input wire [31:0] i_Data,
  input wire [3:0] i_Byte_Write,
  input wire i_OE,
  input wire i_Clk
);

 wire [31:0] w_1;
 wire [31:0] w_2;
 wire w_3;
 wire [31:0] w_4;
 wire w_6;
 wire [3:0] w_7;
 wire [31:0] w_8;
 wire w_9;

MUX2_32 blk1779_46 (
         .Z (o_Data[31:0]),
         .A (w_1),
         .B (w_2),
         .S (w_3)
     );

RISCV_ADDR_DECODER blk3900_57 (
         .i_Address (i_Address[31:0]),
         .i_Write_Enable (i_Write_Enable),
         .i_Data (i_Data[31:0]),
         .i_Byte_Write (i_Byte_Write[3:0]),
         .i_OE (i_OE),
         .o_Mem_Sel (w_3),
         .o_Address (w_4),
         .o_DMEM_Write_Enable (w_6),
         .o_DMEM_Byte_Write (w_7),
         .o_Data (w_8),
         .o_OE (w_9)
     );

RISCV_IMEM blk3901_68 (
         .o_Instruction (w_2),
         .i_Address (w_4),
         .i_OE (w_9)
     );

RISCV_DMEM blk3902_69 (
         .i_Clk (i_Clk),
         .o_Data (w_1),
         .i_Address (w_4),
         .i_WriteEnable (w_6),
         .i_ByteWrite (w_7),
         .i_Data (w_8),
         .i_OE (w_9)
     );

endmodule



// ---------- INCLUDED IP: STAGE2_MULT ---------- 
module STAGE2_MULT (
  input wire clk_i,
  input wire rst_i,
  input wire start_i,
  input wire [2:0] funct3_i,
  input wire [31:0] operand_a_i,
  input wire [31:0] operand_b_i,
  output wire [31:0] result_o,
  output wire busy_o,
  output wire done_o
);
multiplier_sequential blk3979_4 (
         .clk_i (clk_i),
         .rst_i (rst_i),
         .start_i (start_i),
         .funct3_i (funct3_i[2:0]),
         .operand_a_i (operand_a_i[31:0]),
         .operand_b_i (operand_b_i[31:0]),
         .result_o (result_o[31:0]),
         .busy_o (busy_o),
         .done_o (done_o)
     );
endmodule



// ---------- INCLUDED IP: STAGE2_LSU_UNIT ---------- 
module STAGE2_LSU_UNIT (
  output wire [31:0] mem_address_i,
  output wire [3:0] byte_write_i,
  output wire [31:0] core_data_i,
  output wire [31:0] mem_data_i,
  input wire [31:0] core_address_o,
  input wire [2:0] op_size_o,
  input wire [31:0] core_data_o,
  input wire [31:0] mem_data_o
);
LSU_UNIT blk4110_21 (
         .mem_address_i (mem_address_i[31:0]),
         .byte_write_i (byte_write_i[3:0]),
         .core_data_i (core_data_i[31:0]),
         .mem_data_i (mem_data_i[31:0]),
         .core_address_o (core_address_o[31:0]),
         .op_size_o (op_size_o[2:0]),
         .core_data_o (core_data_o[31:0]),
         .mem_data_o (mem_data_o[31:0])
     );
endmodule



// ---------- INCLUDED IP: STAGE2_DATAPATH ---------- 
module STAGE2_DATAPATH (
  input wire [2:0] i_Branch_Sel,
  input wire [3:0] i_Alu_Sel,
  input wire [2:0] i_Mult_Sel,
  input wire [3:0] i_Crc_sel,
  input wire [1:0] i_Src_B_Sel,
  input wire [1:0] i_Src_A_Sel,
  input wire i_Clk,
  input wire i_Rst,
  input wire i_IR_Write,
  input wire i_MDR_Write,
  input wire i_lorD,
  input wire i_PC_Sel,
  input wire i_DMEM_REG_Sel,
  output wire o_branch_taken,
  output wire o_mult_done,
  output wire o_mult_busy,
  input wire [1:0] i_Write_Back_Sel,
  input wire i_mult_start,
  input wire i_oe,
  input wire i_Reg_Write,
  input wire i_Rs_Write,
  input wire i_Mem_Write,
  input wire i_PC_Write,
  input wire i_PC_Write_Cond,
  output wire [31:0] o_Instruction,
  output wire [31:0] exeout_o
);

 wire [31:0] w_1;
 wire [31:0] w_2;
 wire [15:0] w_3;
 wire [31:0] w_6;
 wire [31:0] w_7;
 wire [31:0] w_8;
 wire [31:0] w_9;
 wire [31:0] w_10;
 wire [31:0] w_11;
 wire [31:0] w_12;
 wire [31:0] w_16;
 wire [31:0] w_18;
 wire [31:0] w_19;
 wire [3:0] w_20;
 wire [31:0] w_21;
 wire [31:0] w_24;
 wire [31:0] w_25;
 wire [31:0] w_26;
 wire [31:0] w_31;
 wire [31:0] w_32;
 wire [31:0] w_34;
 wire [31:0] w_37;
 wire [2:0] w_45;

assign o_Instruction[31:0] = w_8;
assign exeout_o[31:0] = w_34;

STAGE2_CRC blkProj14952_41 (
         .crc_op_i (i_Crc_sel[3:0]),
         .rs1_i (w_1),
         .rs2_i (w_2),
         .crc_data_o (w_3)
     );

STAGE2_MULT blkProj14991_42 (
         .funct3_i (i_Mult_Sel[2:0]),
         .clk_i (i_Clk),
         .rst_i (i_Rst),
         .done_o (o_mult_done),
         .busy_o (o_mult_busy),
         .start_i (i_mult_start),
         .operand_a_i (w_1),
         .operand_b_i (w_2),
         .result_o (w_6)
     );

REGISTER_FILE #(.p_DATA_MEM_SIZE(2**10)) blk2116_47 (
         .i_Clk (i_Clk),
         .i_Rst (i_Rst),
         .i_Write_Enable (i_Reg_Write),
         .i_Data_Rd (w_7),
         .i_Instruction (w_8),
         .o_Data_Rs_1 (w_9),
         .o_Data_Rs_2 (w_10)
     );

rs1_reg blk3994_49 (
         .clk_i (i_Clk),
         .rst_i (i_Rst),
         .en_i (i_Rs_Write),
         .rs1_data_i (w_9),
         .rs1_data_o (w_11)
     );

rs2_reg blk3995_50 (
         .clk_i (i_Clk),
         .rst_i (i_Rst),
         .en_i (i_Rs_Write),
         .rs2_data_i (w_10),
         .rs2_data_o (w_12)
     );

STAGE2_ALU blkProj14268_54 (
         .i_Sel (i_Alu_Sel[3:0]),
         .i_A (w_1),
         .i_B (w_2),
         .o_Q (w_16)
     );

STAGE2_UNIFIED_MEMORY blkProj14963_55 (
         .i_Clk (i_Clk),
         .i_OE (i_oe),
         .i_Write_Enable (i_Mem_Write),
         .i_Address (w_18),
         .i_Data (w_19),
         .i_Byte_Write (w_20),
         .o_Data (w_21)
     );

STAGE2_IMM_GEN blkProj14957_56 (
         .inst_i (w_8),
         .imm_out_o (w_24)
     );

mem_data_reg blk4000_70 (
         .i_Clk (i_Clk),
         .i_Rst (i_Rst),
         .i_MDR_Write (i_MDR_Write),
         .i_Data (w_25),
         .o_Data (w_26)
     );

inst_reg blk3999_71 (
         .i_Clk (i_Clk),
         .i_Rst (i_Rst),
         .i_IR_Write (i_IR_Write),
         .o_Instruction (w_8),
         .i_Instruction (w_21)
     );

PC blk4086_75 (
         .clk_i (i_Clk),
         .rst_i (i_Rst),
         .pc_write_i (i_PC_Write),
         .pcwrite_cond_i (i_PC_Write_Cond),
         .pc_next_i (w_31),
         .pc_o (w_32)
     );

PC_Next_MUX blk4089_79 (
         .PC_Sel (i_PC_Sel),
         .ALU_Result (w_16),
         .PC_Next (w_31),
         .ALU_Out (w_34)
     );

ADDR_MUX blk4087_84 (
         .lorD (i_lorD),
         .Addr (w_18),
         .PC_o (w_32),
         .ALUOut_o (w_34)
     );

DMEM_TO_REG_MUX blk4091_85 (
         .DMEM_REG_Sel (i_DMEM_REG_Sel),
         .Data_o (w_7),
         .DMEM (w_26),
         .ALUOut_o (w_34)
     );

EXECUTE_RESULT_REG blk4088_100 (
         .clk_i (i_Clk),
         .rst_i (i_Rst),
         .exeout_o (w_34),
         .exe_result_i (w_37)
     );

STAGE2_LSU_UNIT blkProj15103_101 (
         .core_data_o (w_12),
         .mem_data_i (w_19),
         .byte_write_i (w_20),
         .mem_data_o (w_21),
         .core_data_i (w_25),
         .core_address_o (w_34),
         .op_size_o (w_45)
     );

op_size_decoder blk4137_103 (
         .inst_i (w_8),
         .op_size_o (w_45)
     );

MUX3_32 blk3989_105 (
         .Sel (i_Write_Back_Sel[1:0]),
         .CRC (w_3),
         .MULT (w_6),
         .ALU (w_16),
         .Result (w_37)
     );

MUX_SRC_A blk3997_110 (
         .Src_A_Sel (i_Src_A_Sel[1:0]),
         .Src_A (w_1),
         .Rs_1 (w_11),
         .PC (w_32),
         .ALUOut (w_34)
     );

MUX_SRC_B blk3998_111 (
         .Src_B_Sel (i_Src_B_Sel[1:0]),
         .Src_B (w_2),
         .Rs_2 (w_12),
         .Imm (w_24)
     );

STAGE2_BRANCH_COMPARATOR blkProj14958_112 (
         .funct3_i (i_Branch_Sel[2:0]),
         .branch_taken_o (o_branch_taken),
         .a_i (w_1),
         .b_i (w_2)
     );

endmodule



// ---------- TOP LEVEL PROCESSOR MODULE ---------- 
module top (
  input wire i_clk,
  input wire i_rst,
  output wire [31:0] o_Instruction,
  output wire [31:0] o_exeout
);

 wire w_1;
 wire [31:0] w_2;
 wire w_3;
 wire w_4;
 wire [2:0] w_5;
 wire [3:0] w_6;
 wire [2:0] w_7;
 wire [3:0] w_8;
 wire [1:0] w_9;
 wire [1:0] w_10;
 wire w_11;
 wire w_12;
 wire w_13;
 wire w_14;
 wire w_15;
 wire [1:0] w_16;
 wire w_17;
 wire w_18;
 wire w_19;
 wire w_20;
 wire w_21;
 wire w_22;
 wire w_23;

assign o_Instruction[31:0] = w_2;

STAGE2_CONTROL_UNIT blkProj14523_5 (
         .clk_i (i_clk),
         .rst_i (i_rst),
         .branch_taken_i (w_1),
         .inst_i (w_2),
         .mult_busy_i (w_3),
         .mult_done_i (w_4),
         .o_Branch_Sel (w_5),
         .o_Alu_Sel (w_6),
         .o_Mult_Sel (w_7),
         .o_Crc_Sel (w_8),
         .o_Src_B_Sel (w_9),
         .o_Src_A_Sel (w_10),
         .o_IR_Write (w_11),
         .o_MDR_Write (w_12),
         .o_lorD (w_13),
         .o_PC_Sel (w_14),
         .o_DMEM_REG_Sel (w_15),
         .o_Write_Back_Sel (w_16),
         .o_mult_start (w_17),
         .o_oe (w_18),
         .o_Rs_Write (w_19),
         .o_Reg_Write (w_20),
         .o_Mem_Write (w_21),
         .o_PC_Write (w_22),
         .o_PC_Write_Cond (w_23)
     );

STAGE2_DATAPATH blkProj14999_7 (
         .i_Clk (i_clk),
         .i_Rst (i_rst),
         .o_Instruction (w_2),
         .exeout_o (o_exeout[31:0]),
         .o_branch_taken (w_1),
         .o_mult_busy (w_3),
         .o_mult_done (w_4),
         .i_Branch_Sel (w_5),
         .i_Alu_Sel (w_6),
         .i_Mult_Sel (w_7),
         .i_Crc_sel (w_8),
         .i_Src_B_Sel (w_9),
         .i_Src_A_Sel (w_10),
         .i_IR_Write (w_11),
         .i_MDR_Write (w_12),
         .i_lorD (w_13),
         .i_PC_Sel (w_14),
         .i_DMEM_REG_Sel (w_15),
         .i_Write_Back_Sel (w_16),
         .i_mult_start (w_17),
         .i_oe (w_18),
         .i_Rs_Write (w_19),
         .i_Reg_Write (w_20),
         .i_Mem_Write (w_21),
         .i_PC_Write (w_22),
         .i_PC_Write_Cond (w_23)
     );

endmodule
