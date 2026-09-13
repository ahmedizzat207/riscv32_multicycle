// mem_data_reg: Memory Data Register (MDR)
// Latches data read from Data Memory across the multi-cycle read access
module mem_data_reg (
    input  wire        i_Clk,
    input  wire        i_Rst,        
    input  wire        i_MDR_Write,  
    input  wire [31:0] i_Data,       
    output reg  [31:0] o_Data        
);
    always @(posedge i_Clk) begin
        if (i_Rst)
            o_Data <= 32'h00000000;
        else if (i_MDR_Write)
            o_Data <= i_Data;
    end
endmodule
