// EXECUTE_RESULT_REG: ALUOut Register
// Latches execution result (ALU, Multiplier, or CRC) on every clock cycle
module EXECUTE_RESULT_REG (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire [31:0] exe_result_i,  
    output reg  [31:0] exeout_o
);
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            exeout_o <= 32'h0;
        else
            exeout_o <= exe_result_i;
    end
endmodule
