module testbench;
  top_module dut();

  initial begin
      $dumpfile("top_module.vcd");
      $dumpvars(0, dut);
  end
endmodule

