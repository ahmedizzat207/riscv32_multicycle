// branch_comparator: Branch Comparator Unit
// Evaluates branch conditions according to funct3_i:
// 3'b000: BEQ, 3'b001: BNE, 3'b100: BLT, 3'b101: BGE, 3'b110: BLTU, 3'b111: BGEU
module branch_comparator (
    input  wire [31:0] a_i,            // Operand A (from rs1)
    input  wire [31:0] b_i,            // Operand B (from rs2)
    input  wire [2:0]  funct3_i,       // Branch condition sub-opcode
    output reg         branch_taken_o  // Asserted if branch condition met
);
    always @(*) begin
        case (funct3_i)
            3'b000:  branch_taken_o = (a_i == b_i);                    // BEQ
            3'b001:  branch_taken_o = (a_i != b_i);                    // BNE
            3'b100:  branch_taken_o = ($signed(a_i) < $signed(b_i));  // BLT
            3'b101:  branch_taken_o = ($signed(a_i) >= $signed(b_i)); // BGE
            3'b110:  branch_taken_o = (a_i < b_i);                    // BLTU
            3'b111:  branch_taken_o = (a_i >= b_i);                   // BGEU
            default: branch_taken_o = 1'b0;
        endcase
    end
endmodule
