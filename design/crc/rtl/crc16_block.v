// crc16_block: Custom Xicrc Extension CRC16 Evaluation Block
// Polynomial: 16'h1021. Operates on 16 bits (2 bytes) of rs1 with seed from rs2[15:0]
module crc16_block (
    input  wire [31:0] rs1_i,
    input  wire [31:0] rs2_i,
    output reg  [15:0] crc16_o
);
    localparam [15:0] POLY = 16'h1021;

    reg [15:0] crc;
    integer i;

    always @(*) begin
        crc = rs2_i[15:0];                 

        // Byte 0
        crc = crc ^ {rs1_i[15:8], 8'h00};    
        for (i = 0; i < 8; i = i + 1) begin
            if (crc[15])
                crc = (crc << 1) ^ POLY;
            else
                crc = crc << 1;
        end

        // Byte 1
        crc = crc ^ {rs1_i[7:0], 8'h00};       
        for (i = 0; i < 8; i = i + 1) begin
            if (crc[15])
                crc = (crc << 1) ^ POLY;
            else
                crc = crc << 1;
        end

        crc16_o = crc;
    end
endmodule
