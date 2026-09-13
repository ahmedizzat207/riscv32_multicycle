// STAGE2_BRANCH_COMPARATOR: ChipInventor Stage 2 Wrapper for Branch Comparator
module STAGE2_BRANCH_COMPARATOR (
    input  wire [31:0] a_i,
    input  wire [2:0]  funct3_i,
    input  wire [31:0] b_i,
    output wire        branch_taken_o
);
    branch_comparator blk3886_28 (
        .a_i            (a_i[31:0]),
        .funct3_i       (funct3_i[2:0]),
        .b_i            (b_i[31:0]),
        .branch_taken_o (branch_taken_o)
    );
endmodule
