// op_size_decoder: Instruction funct3 (op_size) Extractor
// Extracts bits [14:12] from the instruction word
module op_size_decoder (
    input  wire [31:0] inst_i,
    output wire [2:0]  op_size_o
);
    assign op_size_o = inst_i[14:12];
endmodule
