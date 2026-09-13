// MUX_SRC_B: Multiplexer for ALU Operand B
// 00: Rs_2, 01: 4 (for PC+4), 10: Imm (Immediate), 11: 32'hFFFFFFFE (mask for JALR)
module MUX_SRC_B (
    input  wire [31:0] Rs_2, 
    input  wire [31:0] Imm, 
    input  wire [1:0]  Src_B_Sel, 
    output reg  [31:0] Src_B
);
    always @(*) begin
        case (Src_B_Sel)
            2'b00:   Src_B = Rs_2;
            2'b01:   Src_B = 32'd4;
            2'b10:   Src_B = Imm;
            2'b11:   Src_B = 32'hFFFFFFFE;
            default: Src_B = Rs_2;
        endcase
    end
endmodule
