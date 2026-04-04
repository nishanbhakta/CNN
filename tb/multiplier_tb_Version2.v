`timescale 1ns/1ps

module multiplier_tb ();

    reg clk;
    reg rst;
    reg start;
    reg signed [31:0] a, b;
    wire signed [63:0] product;
    wire done;

    multiplier #(.WIDTH(32)) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .b(b),
        .product(product),
        .done(done)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("multiplier_tb.vcd");
        $dumpvars(0, multiplier_tb);
    end

    initial begin
        rst = 1;
        start = 0;
        a = 0;
        b = 0;
        #10 rst = 0;

        a = 32'sd5;
        b = 32'sd3;
        start = 1;
        #10 start = 0;
        wait(done);
        #10;
        $display("Test 1: 5 * 3 = %d (Expected: 15)", product);

        a = 32'sd100;
        b = 32'sd200;
        start = 1;
        #10 start = 0;
        wait(done);
        #10;
        $display("Test 2: 100 * 200 = %d (Expected: 20000)", product);

        a = -32'sd50;
        b = 32'sd4;
        start = 1;
        #10 start = 0;
        wait(done);
        #10;
        $display("Test 3: -50 * 4 = %d (Expected: -200)", product);

        $finish;
    end

endmodule
