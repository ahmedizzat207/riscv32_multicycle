// MUX3_32: 3-to-1 32-bit Multiplexer
// Selects execution result among ALU (00), MULT (01), and CRC (10, zero-extended)
module MUX3_32 (
    input  wire [31:0] ALU, 
    input  wire [31:0] MULT, 
    input  wire [15:0] CRC, 
    input  wire [1:0]  Sel, 
    output reg  [31:0] Result
);
    always @(*) begin
        case (Sel)
            2'b00: Result = ALU;
            2'b01: Result = MULT;
            2'b10: Result = {16'b0, CRC};
            default: Result = ALU;
        endcase
    end
endmodule
