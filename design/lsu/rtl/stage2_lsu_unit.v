// STAGE2_LSU_UNIT: ChipInventor Stage 2 Wrapper for Load-Store Unit
module STAGE2_LSU_UNIT (
    output wire [31:0] mem_address_i,
    output wire [3:0]  byte_write_i,
    output wire [31:0] core_data_i,
    output wire [31:0] mem_data_i,
    input  wire [31:0] core_address_o,
    input  wire [2:0]  op_size_o,
    input  wire [31:0] core_data_o,
    input  wire [31:0] mem_data_o
);
    LSU_UNIT blk4110_21 (
        .mem_address_i  (mem_address_i[31:0]),
        .byte_write_i   (byte_write_i[3:0]),
        .core_data_i    (core_data_i[31:0]),
        .mem_data_i     (mem_data_i[31:0]),
        .core_address_o (core_address_o[31:0]),
        .op_size_o      (op_size_o[2:0]),
        .core_data_o    (core_data_o[31:0]),
        .mem_data_o     (mem_data_o[31:0])
    );
endmodule
