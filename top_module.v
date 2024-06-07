module top_module();
    reg clk=0;
    reg reset=1;

    always #1 clk = ~clk;

    initial begin
        #1 reset = 0;
        #46 $stop;
    end

    control_unit cu( .clk(clk), .reset(reset) ); 
endmodule