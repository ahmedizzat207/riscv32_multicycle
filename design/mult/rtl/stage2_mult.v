// STAGE2_MULT: ChipInventor Stage 2 Wrapper for Sequential Multiplier
module STAGE2_MULT (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire        start_i,
    input  wire [2:0]  funct3_i,
    input  wire [31:0] operand_a_i,
    input  wire [31:0] operand_b_i,
    output wire [31:0] result_o,
    output wire        busy_o,
    output wire        done_o
);
    multiplier_sequential blk3979_4 (
        .clk_i       (clk_i),
        .rst_i       (rst_i),
        .start_i     (start_i),
        .funct3_i    (funct3_i[2:0]),
        .operand_a_i (operand_a_i[31:0]),
        .operand_b_i (operand_b_i[31:0]),
        .result_o    (result_o[31:0]),
        .busy_o      (busy_o),
        .done_o      (done_o)
    );
endmodule
