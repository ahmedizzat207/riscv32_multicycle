// imm_generator: Immediate Generator for RISC-V RV32I
// Extracts, bit-reorders, and sign/zero-extends immediate fields for:
// - I-Type (ADDI, SLTI, LW, JALR, SYSTEM, FENCE)
// - S-Type (SW, SH, SB)
// - B-Type (BEQ, BNE, BLT, BGE, BLTU, BGEU)
// - U-Type (LUI, AUIPC)
// - J-Type (JAL)
module imm_generator (
    input  wire [31:0] inst_i,      // 32-bit Instruction (from IR)
    output reg  [31:0] imm_out_o    // Formatted 32-bit Immediate
);
    wire [6:0] opcode = inst_i[6:0];

    always @(*) begin
        case (opcode)
            // I-Type Instructions
            7'b0010011, 7'b0000011, 7'b1100111, 7'b1110011, 7'b0001111: begin
                imm_out_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end
            
            // S-Type Instructions
            7'b0100011: begin
                imm_out_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
            end
            
            // B-Type Instructions
            7'b1100011: begin
                imm_out_o = {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
            end
            
            // U-Type Instructions
            7'b0110111, 7'b0010111: begin
                imm_out_o = {inst_i[31:12], 12'b0};
            end
            
            // J-Type Instructions
            7'b1101111: begin
                imm_out_o = {{11{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
            end
            
            default: imm_out_o = 32'h00000000;
        endcase
    end
endmodule
