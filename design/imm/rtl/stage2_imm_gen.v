// STAGE2_IMM_GEN: ChipInventor Stage 2 Wrapper for Immediate Generator
module STAGE2_IMM_GEN (
    output wire [31:0] imm_out_o,
    input  wire [31:0] inst_i
);
    imm_generator blk3885_16 (
        .imm_out_o (imm_out_o[31:0]),
        .inst_i    (inst_i[31:0])
    );
endmodule
