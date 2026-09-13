// LSU_UNIT: Load Store Unit
// Handles sub-word alignment and byte-write masking for Stores (SB, SH, SW)
// Handles sub-word extraction and sign/zero-extension for Loads (LB, LH, LW, LBU, LHU)
module LSU_UNIT (
    input  wire [31:0] core_data_o,     // store data from datapath (RD2)
    input  wire [31:0] core_address_o,  // address from datapath (ALU result)
    input  wire [2:0]  op_size_o,       // size/sign control from datapath (funct3)
    output reg  [31:0] core_data_i,     // load data returned to datapath

    // ---- Memory (DMEM) side ----
    output reg  [31:0] mem_data_i,      // aligned write data -> DMEM
    output wire [31:0] mem_address_i,   // address -> DMEM (passthrough)
    output reg  [3:0]  byte_write_i,    // byte-write mask -> DMEM
    input  wire [31:0] mem_data_o       // raw read data <- DMEM
);
    assign mem_address_i = core_address_o;

    wire [1:0] addr_low = core_address_o[1:0];

    // -----------------------------------------------------------
    // STORE PATH: align core_data_o into correct byte lane(s)
    // and generate 4-bit byte_write_i mask
    // -----------------------------------------------------------
    always @(*) begin
        mem_data_i   = 32'b0;
        byte_write_i = 4'b0000;

        case (op_size_o[1:0])
            // ---- Byte (SB) ----
            2'b00: begin
                case (addr_low)
                    2'b00: begin mem_data_i = {24'b0, core_data_o[7:0]};        byte_write_i = 4'b0001; end
                    2'b01: begin mem_data_i = {16'b0, core_data_o[7:0], 8'b0};  byte_write_i = 4'b0010; end
                    2'b10: begin mem_data_i = {8'b0,  core_data_o[7:0], 16'b0}; byte_write_i = 4'b0100; end
                    2'b11: begin mem_data_i = {core_data_o[7:0], 24'b0};        byte_write_i = 4'b1000; end
                endcase
            end

            // ---- Halfword (SH) ----
            2'b01: begin
                case (addr_low[1])
                    1'b0: begin mem_data_i = {16'b0, core_data_o[15:0]};  byte_write_i = 4'b0011; end
                    1'b1: begin mem_data_i = {core_data_o[15:0], 16'b0};  byte_write_i = 4'b1100; end
                endcase
            end

            // ---- Word (SW) ----
            2'b10: begin
                mem_data_i   = core_data_o;
                byte_write_i = 4'b1111;
            end

            default: begin
                mem_data_i   = 32'b0;
                byte_write_i = 4'b0000;
            end
        endcase
    end

    // -----------------------------------------------------------
    // LOAD PATH: extract byte/half/word from mem_data_o
    // and sign/zero-extend per op_size_o
    // -----------------------------------------------------------
    reg [7:0]  byte_sel;
    reg [15:0] half_sel;

    always @(*) begin
        case (addr_low)
            2'b00: byte_sel = mem_data_o[7:0];
            2'b01: byte_sel = mem_data_o[15:8];
            2'b10: byte_sel = mem_data_o[23:16];
            2'b11: byte_sel = mem_data_o[31:24];
        endcase

        case (addr_low[1])
            1'b0: half_sel = mem_data_o[15:0];
            1'b1: half_sel = mem_data_o[31:16];
        endcase

        case (op_size_o)
            3'b000:  core_data_i = {{24{byte_sel[7]}},  byte_sel}; // LB  (sign-extend)
            3'b100:  core_data_i = {24'b0,               byte_sel}; // LBU (zero-extend)
            3'b001:  core_data_i = {{16{half_sel[15]}},  half_sel}; // LH  (sign-extend)
            3'b101:  core_data_i = {16'b0,               half_sel}; // LHU (zero-extend)
            3'b010:  core_data_i = mem_data_o;                      // LW  (full word)
            default: core_data_i = 32'b0;
        endcase
    end

endmodule
