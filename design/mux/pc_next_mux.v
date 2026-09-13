// PC_Next_MUX: Multiplexer for Next PC Value
// 0: ALU_Result (combinational), 1: ALU_Out (latched branch target)
module PC_Next_MUX (
    input  wire [31:0] ALU_Result, 
    input  wire [31:0] ALU_Out, 
    input  wire        PC_Sel, 
    output wire [31:0] PC_Next
);
    assign PC_Next = (PC_Sel) ? ALU_Out : ALU_Result;
endmodule
