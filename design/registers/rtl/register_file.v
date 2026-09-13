// REGISTER_FILE: 32-entry 32-bit General-Purpose Register File
// Synchronous write on positive clock edge, asynchronous read
// Register x0 is hardwired to 0.
// SP (x2) and GP (x3) are initialized with standard base pointers upon reset.
module REGISTER_FILE #(
    parameter p_DATA_MEM_SIZE = 2**10
)(
    input  wire [31:0] i_Data_Rd,
    input  wire [31:0] i_Instruction,
    input  wire        i_Write_Enable,
    input  wire        i_Clk,
    input  wire        i_Rst,
    output wire [31:0] o_Data_Rs_1,
    output wire [31:0] o_Data_Rs_2  
);
    /* Constants */
    localparam c_SP_INDEX = 2;
    localparam c_GP_INDEX = 3;
    localparam c_GP_INITIAL_VALUE = 32'h1001_0000;
    localparam c_SP_INITIAL_VALUE = c_GP_INITIAL_VALUE + p_DATA_MEM_SIZE - 4;

    /* Instruction fields */
    wire [4:0] w_Select_Rd   = i_Instruction[11:7];
    wire [4:0] w_Select_Rs_1 = i_Instruction[19:15];
    wire [4:0] w_Select_Rs_2 = i_Instruction[24:20];
  
    /* Registers Data */
    reg [31:0] r_Registers [0:31];
  
    integer i;
    always @(posedge i_Clk or posedge i_Rst) begin
        if (i_Rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                case (i)
                    c_SP_INDEX: r_Registers[i] = c_SP_INITIAL_VALUE;
                    c_GP_INDEX: r_Registers[i] = c_GP_INITIAL_VALUE;
                    default:    r_Registers[i] = 32'h0;
                endcase
            end
        end
        else begin 
            if (i_Write_Enable && w_Select_Rd != 5'h0) begin
                r_Registers[w_Select_Rd] = i_Data_Rd;
            end
        end
    end
    
    assign o_Data_Rs_1 = r_Registers[w_Select_Rs_1];
    assign o_Data_Rs_2 = r_Registers[w_Select_Rs_2];

endmodule
