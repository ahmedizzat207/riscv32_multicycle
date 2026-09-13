// inst_reg: Instruction Register (IR)
// Latches incoming instruction word from memory during Fetch phase
// Synchronous reset defaults to NOP (addi x0, x0, 0: 32'h00000013)
module inst_reg (
    input  wire        i_Clk,
    input  wire        i_Rst,          // synchronous, active-high
    input  wire        i_IR_Write,     // asserted by Control FSM during Fetch
    input  wire [31:0] i_Instruction,  // shared memory bus
    output reg  [31:0] o_Instruction   // latched instruction seen by Decode
);
    always @(posedge i_Clk) begin
        if (i_Rst)
            o_Instruction <= 32'h00000013; // NOP (addi x0, x0, 0)
        else if (i_IR_Write)
            o_Instruction <= i_Instruction;
    end
endmodule
