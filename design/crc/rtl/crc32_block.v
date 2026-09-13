// crc32_block: Custom Xicrc Extension CRC32 (CRCW) Evaluation Block
// Polynomial: 16'h1021. Operates on full 32 bits (4 bytes) of rs1 with seed from rs2[15:0]
module crc32_block (
    input  wire [31:0] rs1_i,
    input  wire [31:0] rs2_i,
    output reg  [15:0] crc32_o
);
    localparam [15:0] POLY = 16'h1021;

    reg [15:0] crc;
    integer i;

    always @(*) begin
        crc = rs2_i[15:0]; 

        // Byte 0 of rs1
        crc = crc ^ {rs1_i[31:24], 8'h00};
        for (i = 0; i < 8; i = i + 1) begin
            if (crc[15]) crc = (crc << 1) ^ POLY;
            else         crc = crc << 1;
        end

        // Byte 1 of rs1
        crc = crc ^ {rs1_i[23:16], 8'h00};
        for (i = 0; i < 8; i = i + 1) begin
            if (crc[15]) crc = (crc << 1) ^ POLY;
            else         crc = crc << 1;
        end

        // Byte 2 of rs1
        crc = crc ^ {rs1_i[15:8], 8'h00};
        for (i = 0; i < 8; i = i + 1) begin
            if (crc[15]) crc = (crc << 1) ^ POLY;
            else         crc = crc << 1;
        end

        // Byte 3 of rs1
        crc = crc ^ {rs1_i[7:0], 8'h00};
        for (i = 0; i < 8; i = i + 1) begin
            if (crc[15]) crc = (crc << 1) ^ POLY;
            else         crc = crc << 1;
        end

        crc32_o = crc;
    end
endmodule
