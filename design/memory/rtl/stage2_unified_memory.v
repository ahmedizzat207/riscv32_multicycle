// STAGE2_UNIFIED_MEMORY: ChipInventor Stage 2 Unified Memory Subsystem
// Combines Instruction ROM (IMEM) and Data RAM (DMEM) behind an Address Decoder
module STAGE2_UNIFIED_MEMORY (
    output wire [31:0] o_Data,
    input  wire [31:0] i_Address,
    input  wire        i_Write_Enable,
    input  wire [31:0] i_Data,
    input  wire [3:0]  i_Byte_Write,
    input  wire        i_OE,
    input  wire        i_Clk
);
    // Internal Wires
    wire [31:0] w_1; // DMEM output
    wire [31:0] w_2; // IMEM output
    wire        w_3; // o_Mem_Sel (1: IMEM, 0: DMEM)
    wire [31:0] w_4; // decoded address
    wire        w_6; // DMEM write enable
    wire [3:0]  w_7; // DMEM byte write mask
    wire [31:0] w_8; // forwarded write data
    wire        w_9; // forwarded OE

    // Instances of Modules
    MUX2_32 blk1779_46 (
        .Z (o_Data[31:0]),
        .A (w_1),
        .B (w_2),
        .S (w_3)
    );

    RISCV_ADDR_DECODER blk3900_57 (
        .i_Address           (i_Address[31:0]),
        .i_Write_Enable      (i_Write_Enable),
        .i_Data              (i_Data[31:0]),
        .i_Byte_Write        (i_Byte_Write[3:0]),
        .i_OE                (i_OE),
        .o_Mem_Sel           (w_3),
        .o_Address           (w_4),
        .o_DMEM_Write_Enable (w_6),
        .o_DMEM_Byte_Write   (w_7),
        .o_Data              (w_8),
        .o_OE                (w_9)
    );

    RISCV_IMEM blk3901_68 (
        .o_Instruction (w_2),
        .i_Address     (w_4),
        .i_OE          (w_9)
    );

    RISCV_DMEM blk3902_69 (
        .i_Clk         (i_Clk),
        .o_Data        (w_1),
        .i_Address     (w_4),
        .i_WriteEnable (w_6),
        .i_ByteWrite   (w_7),
        .i_Data        (w_8),
        .i_OE          (w_9)
    );

endmodule
