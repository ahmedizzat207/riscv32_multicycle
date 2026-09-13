// PC: Program Counter
// Tracks instruction address. Reset vector is 32'h00400000 (IMEM base address).
// Supports unconditional update (pc_write_i) and conditional update (pcwrite_cond_i & branch_taken_i).
module PC (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire        pc_write_i,     // unconditional PC update
    input  wire        pcwrite_cond_i, // conditional update
    input  wire        branch_taken_i, // from branch comparator
    input  wire [31:0] pc_next_i,      // next PC value (PC+4, branch target, or jump target)
    output reg  [31:0] pc_o
);
    wire pc_en = pc_write_i | (pcwrite_cond_i & branch_taken_i);

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            pc_o <= 32'h00400000;   // reset vector = IMEM base
        else if (pc_en)
            pc_o <= pc_next_i;
    end
endmodule
