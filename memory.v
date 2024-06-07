module memory(input [5:0] addr, input WRITE, input READ, inout wire [7:0] data);
  initial $readmemh("hex_mem.txt", mem);
  reg [7:0] mem[0:63];
  reg [7:0] data_out;

    always @(posedge WRITE)
        mem[addr] <= data;

    always @(posedge READ)
        data_out <= mem[addr];

  assign data = (READ) ? data_out : 8'bz;
endmodule