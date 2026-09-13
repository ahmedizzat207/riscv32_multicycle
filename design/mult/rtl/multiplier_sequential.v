// multiplier_sequential: Sequential 32-Cycle Shift-and-Add Hardware Multiplier
// Implements Zmmul Extension: MUL, MULH, MULHSU, MULHU
// 64-bit internal product with sign handling and handshake protocol (start_i, busy_o, done_o)
module multiplier_sequential (
    input  wire        clk_i,
    input  wire        rst_i,

    // Control Interface
    input  wire        start_i,        // Start signal (mult_start from Control Unit)
    input  wire [2:0]  funct3_i,       // Instruction funct3 (000=MUL, 001=MULH, 010=MULHSU, 011=MULHU)
    input  wire [31:0] operand_a_i,    // rs1 data
    input  wire [31:0] operand_b_i,    // rs2 data
    output reg  [31:0] result_o,       // 32-bit result routed to Writeback MUX
    output reg         busy_o,         // High while calculating
    output reg         done_o          // Handshake completion pulse (mult_done)
);

    // ------------------------------------------------------------------------
    // FSM States & Registers
    // ------------------------------------------------------------------------
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam FINI = 2'b10;

    reg [1:0]  state;
    reg [5:0]  count;
    reg [2:0]  funct3_r;
    reg        sign_result_r;

    reg [63:0] multiplicand;
    reg [31:0] multiplier;
    reg [63:0] accum;

    // ------------------------------------------------------------------------
    // Sign Extraction Logic
    // ------------------------------------------------------------------------
    wire a_is_signed = (funct3_i == 3'b001 || funct3_i == 3'b010) && operand_a_i[31]; // MULH, MULHSU
    wire b_is_signed = (funct3_i == 3'b001) && operand_b_i[31];                       // MULH

    // Absolute magnitudes for signed operands
    wire [31:0] abs_a = a_is_signed ? (~operand_a_i + 1'b1) : operand_a_i;
    wire [31:0] abs_b = b_is_signed ? (~operand_b_i + 1'b1) : operand_b_i;

    // ------------------------------------------------------------------------
    // Sequential State Machine & Iterative Kernel
    // ------------------------------------------------------------------------
    reg [63:0] final_product;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state         <= IDLE;
            count         <= 6'd0;
            funct3_r      <= 3'd0;
            sign_result_r <= 1'b0;
            multiplicand  <= 64'd0;
            multiplier    <= 32'd0;
            accum         <= 64'd0;
            result_o      <= 32'd0;
            busy_o        <= 1'b0;
            done_o        <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done_o <= 1'b0;
                    if (start_i) begin
                        funct3_r      <= funct3_i;
                        sign_result_r <= a_is_signed ^ b_is_signed; // Result is negative if signs differ
                        multiplicand  <= {32'd0, abs_a};
                        multiplier    <= abs_b;
                        accum         <= 64'd0;
                        count         <= 6'd0;
                        busy_o        <= 1'b1;
                        state         <= CALC;
                    end
                end

                CALC: begin
                    // Shift-and-Add Algorithm Step
                    if (multiplier[0]) begin
                        accum <= accum + multiplicand;
                    end
                    multiplicand <= multiplicand << 1;
                    multiplier   <= multiplier >> 1;
                    count        <= count + 1'b1;

                    if (count == 6'd31) begin
                        state <= FINI;
                    end
                end

                FINI: begin
                    busy_o <= 1'b0;
                    done_o <= 1'b1;

                    // Apply sign adjustment if negative
                    final_product = sign_result_r ? (~accum + 1'b1) : accum;

                    // Select output word based on instruction funct3
                    case (funct3_r)
                        3'b000:  result_o <= final_product[31:0];  // MUL (Lower 32 bits)
                        3'b001,                                    // MULH (Upper 32 bits, Signed x Signed)
                        3'b010,                                    // MULHSU (Upper 32 bits, Signed x Unsigned)
                        3'b011:  result_o <= final_product[63:32]; // MULHU (Upper 32 bits, Unsigned x Unsigned)
                        default: result_o <= final_product[31:0];
                    endcase

                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
