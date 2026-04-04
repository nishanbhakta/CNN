`timescale 1ns/1ps

module divider_tb ();

    reg clk;
    reg rst;
    reg start;
    reg signed [31:0] dividend;
    reg signed [31:0] divisor;
    wire signed [31:0] quotient;
    wire signed [31:0] remainder;
    wire done;

    divider #(.WIDTH(32)) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .dividend(dividend),
        .divisor(divisor),
        .quotient(quotient),
        .remainder(remainder),
        .done(done)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("divider_tb.vcd");
        $dumpvars(0, divider_tb);
    end

    task run_division;
        input signed [31:0] dividend_value;
        input signed [31:0] divisor_value;
        input signed [31:0] expected_quotient;
        input signed [31:0] expected_remainder;
        input [127:0] label;
        begin
            @(negedge clk);
            dividend = dividend_value;
            divisor = divisor_value;
            start = 1;

            @(negedge clk);
            start = 0;

            @(posedge done);
            #1;

            $display("%0s: q = %0d (Expected: %0d), r = %0d (Expected: %0d)",
                     label, quotient, expected_quotient, remainder, expected_remainder);
        end
    endtask

    initial begin
        rst = 1;
        start = 0;
        dividend = 0;
        divisor = 0;

        @(negedge clk);
        rst = 0;

        run_division(32'sd100, 32'sd5, 32'sd20, 32'sd0, "Test 1");
        run_division(32'sd50, 32'sd3, 32'sd16, 32'sd2, "Test 2");
        run_division(-32'sd100, 32'sd4, -32'sd25, 32'sd0, "Test 3");

        $finish;
    end

endmodule
