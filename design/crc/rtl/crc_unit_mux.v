// crc_unit_mux: CRC Result Output Multiplexer
// 4'h0: CRC8 (CRCB), 4'h1: CRC16 (CRCH), 4'h2: CRC32 (CRCW)
module crc_unit_mux (
    input  wire [15:0] crc8_i,
    input  wire [15:0] crc16_i,
    input  wire [15:0] crc32_i,
    input  wire [3:0]  crc_op_i,
    output reg  [15:0] crc_data_o
);
    always @(*) begin
        case (crc_op_i)
            4'h0:    crc_data_o = crc8_i;
            4'h1:    crc_data_o = crc16_i;
            4'h2:    crc_data_o = crc32_i;
            default: crc_data_o = 16'hFFFF;
        endcase
    end
endmodule
