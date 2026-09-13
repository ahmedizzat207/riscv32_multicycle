// rs1_reg: Register File RS1 Pipeline Register
// Latches rs1 operand during Decode phase to hold stable for Execute
module rs1_reg (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire        en_i,        // load enable, asserted during Decode state
    input  wire [31:0] rs1_data_i,  // data straight from register file read port
    output reg  [31:0] rs1_data_o   // latched value, held for use in Execute
);
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            rs1_data_o <= 32'b0;
        else if (en_i)
            rs1_data_o <= rs1_data_i;
    end
endmodule
