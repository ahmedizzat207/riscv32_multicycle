// STAGE2_ALU: ChipInventor Stage 2 Wrapper for ALU
module STAGE2_ALU (
    input  wire [31:0] i_A,
    input  wire [31:0] i_B,
    input  wire [3:0]  i_Sel,
    output wire [31:0] o_Q
);
    ALU blk3085_2 (
        .i_A   (i_A[31:0]),
        .i_B   (i_B[31:0]),
        .i_Sel (i_Sel[3:0]),
        .o_Q   (o_Q[31:0])
    );
endmodule
