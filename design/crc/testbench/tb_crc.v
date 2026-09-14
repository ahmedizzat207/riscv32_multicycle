`timescale 1ns/1ps
module testbench;
   reg  [31:0] rs1_i;
   reg  [31:0] rs2_i;
   reg  [3:0]  crc_op_i;
   wire [15:0] crc_data_o;
   top DUT (
       .rs1_i      (rs1_i),
       .rs2_i      (rs2_i),
       .crc_op_i   (crc_op_i),
       .crc_data_o (crc_data_o)
   );
   initial begin
       // Test data
       rs1_i = 32'h12345678;
       rs2_i = 32'h90ABCDEF;
       // =====================================================
       // CRCB
       // =====================================================
       crc_op_i = 4'h0;
       #10;
       $display("CRCB = %h", crc_data_o);
       // =====================================================
       // CRCH
       // =====================================================
       crc_op_i = 4'h1;
       #10;
       $display("CRCH = %h", crc_data_o);
       // =====================================================
       // CRCW
       // =====================================================
       crc_op_i = 4'h2;
       #10;
       $display("CRCW = %h", crc_data_o);
       // =====================================================
       // Expected CRCW
       // =====================================================
       if (crc_data_o == 32'h00001E82)
           $display("PASS");
       else
           $display("FAIL: Expected 00001E82, Got %h",
                    crc_data_o);
       #10;
       $finish;
   end
endmodule
