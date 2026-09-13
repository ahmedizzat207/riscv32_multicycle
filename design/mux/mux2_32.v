// MUX2_32: 2-to-1 32-bit Multiplexer
// Selects between input A (when S=0) and input B (when S=1)
module MUX2_32 (
    input  wire [31:0] A, 
    input  wire [31:0] B, 
    input  wire        S, 
    output wire [31:0] Z
);
    assign Z = (S) ? B : A;
endmodule
