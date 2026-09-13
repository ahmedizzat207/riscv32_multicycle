// ALU: 11-operation 32-bit Arithmetic and Logic Unit
// Supports: PASS_B, ADD, SUB, AND, OR, XOR, SLL, SRL, SRA (MRS), SLT, SLTU
module ALU (
    input  wire signed [31:0] i_A,
    input  wire signed [31:0] i_B,
    input  wire [3:0]         i_Sel,
    output reg  signed [31:0] o_Q
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
  
    always @(*) begin
        case (i_Sel)
            c_ALU_OP_PASS_B: o_Q = i_B;
            c_ALU_OP_ADD:    o_Q = i_A + i_B;
            c_ALU_OP_SUB:    o_Q = i_A - i_B;
            c_ALU_OP_AND:    o_Q = i_A & i_B;
            c_ALU_OP_OR:     o_Q = i_A | i_B;
            c_ALU_OP_XOR:    o_Q = i_A ^ i_B;
            c_ALU_OP_SLL:    o_Q = i_A << i_B[4:0];
            c_ALU_OP_SRL:    o_Q = i_A >> i_B[4:0];    // logical right shift (zero filled)
            c_ALU_OP_MRS:    o_Q = i_A >>> i_B[4:0];   // arithmetic right shift (sign extended)
            c_ALU_OP_SLT:    o_Q = (i_A < i_B) ? 32'h1 : 32'h0;                       // signed comparison
            c_ALU_OP_SLTU:   o_Q = ($unsigned(i_A) < $unsigned(i_B)) ? 32'h1 : 32'h0; // unsigned comparison
            default:         o_Q = 32'h0;
        endcase
    end
endmodule
