// DMEM_TO_REG_MUX: Register File Write-Back Source Multiplexer
// 0: DMEM (read from memory via MDR), 1: ALUOut_o (ALU / MULT / CRC execution result)
module DMEM_TO_REG_MUX (
    input  wire [31:0] DMEM, 
    input  wire [31:0] ALUOut_o, 
    input  wire        DMEM_REG_Sel, 
    output wire [31:0] Data_o
);
    assign Data_o = (DMEM_REG_Sel) ? ALUOut_o : DMEM;
endmodule
