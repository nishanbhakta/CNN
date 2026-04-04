`timescale 1ns/1ps

module mac_tb ();

    reg clk;
    reg rst;
    reg enable;
    reg reset_acc;
    reg signed [63:0] product_in;
    wire signed [71:0] result;

    mac #(.WIDTH(32), .ACC_WIDTH(72)) uut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .reset_acc(reset_acc),
        .product_in(product_in),
        .result(result)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("mac_tb.vcd");
        $dumpvars(0, mac_tb);
    end

    initial begin
        rst = 1;
        enable = 0;
        reset_acc = 0;
        product_in = 0;
        #10 rst = 0;

        reset_acc = 1;
        #10;
        reset_acc = 0;

        product_in = 64'sd50;
        enable = 1;
        #10;
        $display("After 1st MAC: result = %d (Expected: 50)", result);

        product_in = 64'sd60;
        #10;
        $display("After 2nd MAC: result = %d (Expected: 110)", result);

        product_in = 64'sd60;
        #10;
        $display("After 3rd MAC: result = %d (Expected: 170)", result);

        enable = 0;
        $finish;
    end

endmodule
