// crc8_block: Custom Xicrc Extension CRC8 Evaluation Block
// Polynomial: 16'h1021. Operates on lowest 8 bits of rs1 with seed from rs2[15:0]
module crc8_block (
    input  wire [31:0] rs1_i,
    input  wire [31:0] rs2_i,
    output reg  [15:0] crc8_o
);
    localparam [15:0] POLY = 16'h1021;

    reg [15:0] crc;
    integer i;

    always @(*) begin
        crc = rs2_i[15:0];           
        crc = crc ^ {rs1_i[7:0], 8'h00}; 

        for (i = 0; i < 8; i = i + 1) begin
            if (crc[15])
                crc = (crc << 1) ^ POLY;
            else
                crc = crc << 1;
        end

        crc8_o = crc;
    end
endmodule
