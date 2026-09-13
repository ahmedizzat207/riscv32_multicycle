// RISCV_ADDR_DECODER: Address Decoder for Unified Memory Subsystem
// Routes memory access signals according to the 32-bit address:
// - IMEM: base address 0x00400000 (o_Mem_Sel = 1)
// - DMEM: base address 0x10010000 (o_Mem_Sel = 0, Write Enable and Byte Write forwarded)
module RISCV_ADDR_DECODER (
    input  wire [31:0] i_Address,
    input  wire        i_Write_Enable,
    input  wire [3:0]  i_Byte_Write,
    input  wire [31:0] i_Data,    
    input  wire        i_OE,

    output wire [31:0] o_Address,     
    output wire        o_DMEM_Write_Enable,
    output wire [3:0]  o_DMEM_Byte_Write,
    output wire [31:0] o_Data,  
    output wire        o_Mem_Sel, // 1 = IMEM (select B in MUX2_32), 0 = DMEM (select A)
    output wire        o_OE
);
    assign o_Address = i_Address;
    assign o_Data    = i_Data;

    // DMEM ranges from 0x10010000; IMEM ranges from 0x00400000
    wire is_dmem = (i_Address[31:16] == 16'h1001);
    assign o_Mem_Sel = !is_dmem;

    assign o_DMEM_Write_Enable = is_dmem ? i_Write_Enable : 1'b0;
    assign o_DMEM_Byte_Write   = is_dmem ? i_Byte_Write   : 4'b0000;
    assign o_OE = i_OE;
endmodule
