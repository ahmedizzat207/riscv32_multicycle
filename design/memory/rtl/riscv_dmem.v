// RISCV_DMEM: Data Memory (SRAM)
// 2048 words (8 KB) address space with byte-level write masking
// Synchronous read and synchronous write on positive clock edge
module RISCV_DMEM (
    input  wire        i_Clk,
    input  wire [31:0] i_Address,
    input  wire [31:0] i_Data,
    input  wire [3:0]  i_ByteWrite,    // 4-bit byte-write mask
    input  wire        i_WriteEnable,  // Write Enable
    input  wire        i_OE,           // Output Enable
    output reg  [31:0] o_Data
);
    reg [31:0] r_Mem [0:2047]; 
    wire [10:0] w_Index = i_Address[12:2];

    // Synchronous, per-byte write
    always @(posedge i_Clk) begin
        if (i_WriteEnable) begin
            if (i_ByteWrite[0]) r_Mem[w_Index][7:0]   <= i_Data[7:0];
            if (i_ByteWrite[1]) r_Mem[w_Index][15:8]  <= i_Data[15:8];
            if (i_ByteWrite[2]) r_Mem[w_Index][23:16] <= i_Data[23:16];
            if (i_ByteWrite[3]) r_Mem[w_Index][31:24] <= i_Data[31:24];
        end
    end

    // Synchronous read
    always @(posedge i_Clk) begin
        if (i_OE)
            o_Data <= r_Mem[w_Index];
        else
            o_Data <= 32'h0;
    end
endmodule
