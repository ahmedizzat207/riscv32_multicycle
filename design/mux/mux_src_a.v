// MUX_SRC_A: Multiplexer for ALU Operand A
// 00: Rs_1, 01: PC, 10: ALUOut (feedback for JALR bit0 masking)
module MUX_SRC_A (
    input  wire [31:0] Rs_1,
    input  wire [31:0] PC,
    input  wire [31:0] ALUOut,
    input  wire [1:0]  Src_A_Sel,
    output reg  [31:0] Src_A
);
    always @(*) begin
        case (Src_A_Sel)
            2'b00:   Src_A = Rs_1;
            2'b01:   Src_A = PC;
            2'b10:   Src_A = ALUOut;
            default: Src_A = Rs_1;
        endcase
    end
endmodule
