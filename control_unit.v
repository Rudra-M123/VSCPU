module control_unit(input clk, input reset);
    //registers 
    reg [1:0] IR;
    reg [7:0] ALU;
    reg [7:0] AC;
    reg [7:0] DR;
    reg [5:0] PC;
    reg [5:0] AR;

    reg [3:0] state;
    parameter FETCH1 = 4'd0, FETCH2 = 4'd1, FETCH3 = 4'd2, CLEAR1 = 4'd8, FLIP1 = 4'd10, NAND1 = 4'd12, NAND2 = 4'd13, STORE1 = 4'd14, STORE2 = 4'd15;
    
    reg [12:0] microcoded_memory [0:15];
    reg [12:0] microcode;
    
    initial begin 
        $readmemh("microcoded_memory.txt", microcoded_memory);
        state <= 4'h0;
        microcode <= microcoded_memory[0];
        AR <= 6'hz;
    end

    wire [2:0] M1; 
    wire [1:0] M2;    
    wire SEL;
    wire [3:0] ADDR;

    assign SEL = microcode[12];
    assign M1 = microcode[8:6];    
    assign M2 = microcode[5:4];
    assign ADDR = microcode[3:0];

    //microsequencer
    always @(posedge clk) //begin
        state <= SEL? {1'b1, IR, 1'b0} : ADDR;
    
    always @(*)
        microcode <= microcoded_memory[state];

    //reset circuitry
    always @(reset) begin
        PC <= 6'h00; // boot address
        ALU <= 8'h00;
        AC <= 8'h00;
        DR <= 8'h00;
        AR <= 6'hz;
        IR <= 2'b00;
        state <= FETCH1;
    end    

    wire [13:0] control_signals;
    wire [7:0] bus, mem_bus;

    assign control_signals[0] = control_signals[7] || M1==3'd3; //ARLOAD
    assign control_signals[1] = M1==3'd2; //PCINC
    assign control_signals[2] = control_signals[10] || control_signals[9]; //DRLOAD   
    assign control_signals[3] = M1==3'd4 || control_signals[6] || control_signals[5]; //ACLOAD
    assign control_signals[4] = M2==2'd2; //IRLOAD
    assign control_signals[5] = M1==3'd6; //ALUS1
    assign control_signals[6] = M1==3'd5; //ALUS2
    assign control_signals[7] = M1==3'd1; //PCBUS
    assign control_signals[8] = control_signals[4] || M1==3'd3 || control_signals[11] || control_signals[5]; //DRBUS
    assign control_signals[9] = M2==2'd3; //ACBUS
    assign control_signals[10] = M2==2'd1; //MEMBUS
    assign control_signals[11] = M1==3'd7; //BUSMEM
    assign control_signals[12] = control_signals[11]; //WRITE
    assign control_signals[13] = control_signals[10]; //READ

    always @(negedge clk) begin
        IR <= control_signals[4]? bus[7:6] : IR;
        AC <= control_signals[3]? ALU : AC;
        DR <= control_signals[2]? bus : DR;
        PC <= control_signals[1]? PC + 1 : PC;
        AR <= control_signals[0]? bus[5:0] : AR;
    end


    always @(*) ALU <= control_signals[6]? ~AC : control_signals[5]? ~(bus & AC) : 8'h00;

    assign bus = control_signals[7]? {2'b00, PC} : (control_signals[8]? DR : (control_signals[9]? AC : ((control_signals[10] | control_signals[11])? mem_bus : 8'bz)));
     
    memory mem0 ( .addr(AR), .WRITE(control_signals[12]), .READ(control_signals[13]), .data(mem_bus) );
endmodule