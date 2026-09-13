`timescale 1ns / 1ps
// ============================================================================
// Testbench: tb_top
// Module Under Test: top (RVBL-2 Multicycle RISC-V Core)
// Project: ChampionCHIP eXperience (Phase 2 Challenge) - Equipe 15
// ============================================================================

module tb_top;

    // Clock and Reset Signals
    reg         i_clk;
    reg         i_rst;

    // Output Monitor Signals
    wire [31:0] o_Instruction;
    wire [31:0] o_exeout;

    // Cycle & Instruction Counters
    integer cycle_count;
    integer instr_count;

    // Instantiate the Device Under Test (DUT)
    top dut (
        .i_clk         (i_clk),
        .i_rst         (i_rst),
        .o_Instruction (o_Instruction),
        .o_exeout      (o_exeout)
    );

    // Clock Generation (50 MHz -> 20ns period)
    always #10 i_clk = ~i_clk;

    // Cycle Counter
    always @(posedge i_clk) begin
        if (!i_rst) begin
            cycle_count <= cycle_count + 1;
        end
    end

    // Simulation Stimulus & Execution
    initial begin
        // VCD Dump for waveform inspection
        $dumpfile("top_tb.vcd");
        $dumpvars(0, tb_top);

        // Initialize signals
        i_clk       = 1'b0;
        i_rst       = 1'b1;
        cycle_count = 0;
        instr_count = 0;

        $display("=========================================================");
        $display(" Starting Simulation: RVBL-2 Multicycle Core (tb_top)");
        $display(" ChampionCHIP eXperience - Equipe 15");
        $display("=========================================================");

        // Apply Reset (hold for 5 clock cycles)
        #50;
        @(posedge i_clk);
        i_rst = 1'b0;
        $display("[%0t] Core reset released. Starting firmware execution...", $time);

        // --------------------------------------------------------------------
        // TODO: Add custom firmware execution monitors, breakpoints, or checks
        // --------------------------------------------------------------------

        // Run simulation for demo duration (adjust as necessary for firmware demo)
        #500000;

        $display("=========================================================");
        $display(" Simulation finished at time %0t ps", $time);
        $display(" Total cycles: %0d", cycle_count);
        $display("=========================================================");
        $finish;
    end

    // Monitor instruction fetch and writeback execution
    always @(posedge i_clk) begin
        if (!i_rst) begin
            // You can add trace log statements here
        end
    end

endmodule
