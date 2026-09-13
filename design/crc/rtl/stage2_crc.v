// STAGE2_CRC: ChipInventor Stage 2 Wrapper for CRC Computation
module STAGE2_CRC (
    input  wire [31:0] rs1_i,
    input  wire [31:0] rs2_i,
    input  wire [3:0]  crc_op_i,
    output wire [15:0] crc_data_o
);
    // Internal Wires
    wire [15:0] w_1; // CRC8
    wire [15:0] w_2; // CRC32
    wire [15:0] w_3; // CRC16

    // Instances of Modules
    crc8_block blk3875_1 (
        .rs1_i  (rs1_i[31:0]),
        .rs2_i  (rs2_i[31:0]),
        .crc8_o (w_1)
    );

    crc32_block blk3877_3 (
        .rs1_i   (rs1_i[31:0]),
        .rs2_i   (rs2_i[31:0]),
        .crc32_o (w_2)
    );

    crc_unit_mux blk3878_4 (
        .crc_op_i   (crc_op_i[3:0]),
        .crc_data_o  (crc_data_o[15:0]),
        .crc8_i     (w_1),
        .crc32_i    (w_2),
        .crc16_i    (w_3)
    );

    crc16_block blk3876_9 (
        .rs1_i   (rs1_i[31:0]),
        .rs2_i   (rs2_i[31:0]),
        .crc16_o (w_3)
    );

endmodule
