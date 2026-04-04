`timescale 1ns/1ps

module divide_by_9_tb ();

    reg clk;
    reg rst;
    reg start;
    reg signed [71:0] dividend;
    wire signed [71:0] quotient;
    wire done;

    divide_by_9 #(.WIDTH(72)) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .dividend(dividend),
        .quotient(quotient),
        .done(done)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("divide_by_9_tb.vcd");
        $dumpvars(0, divide_by_9_tb);
    end

    initial begin
        rst = 1;
        start = 0;
        dividend = 0;
        #10 rst = 0;

        dividend = 72'sd81;
        start = 1;
        #10 start = 0;
        wait(done);
        #10;
        $display("Test 1: 81 / 9 = %d (Expected: 9)", quotient);

        dividend = -72'sd10;
        start = 1;
        #10 start = 0;
        wait(done);
        #10;
        $display("Test 2: -10 / 9 = %d (Expected: -1)", quotient);

        dividend = 72'sd0;
        start = 1;
        #10 start = 0;
        wait(done);
        #10;
        $display("Test 3: 0 / 9 = %d (Expected: 0)", quotient);

        $finish;
    end

endmodule
