// ADDR_MUX: Memory Address Multiplexer
// Selects between PC_o (Instruction Fetch, lorD=0) and ALUOut_o (Data Memory Access, lorD=1)
module ADDR_MUX (
    input  wire [31:0] PC_o, 
    input  wire [31:0] ALUOut_o, 
    input  wire        lorD, 
    output wire [31:0] Addr
);
    assign Addr = (lorD) ? ALUOut_o : PC_o;
endmodule
