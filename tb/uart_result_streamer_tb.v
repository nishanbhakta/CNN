`timescale 1ns/1ps

module uart_result_streamer_tb;

    localparam integer CLK_PERIOD = 10;
    localparam integer CLK_FREQ_HZ = 40;
    localparam integer BAUD_RATE = 10;
    localparam integer CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;
    localparam integer BIT_PERIOD = CLK_PERIOD * CLKS_PER_BIT;
    localparam integer NUM_BYTES = 10;

    reg clk;
    reg rst;
    reg start;
    reg [31:0] result;
    wire tx;
    wire busy;
    wire done;

    reg [7:0] expected_bytes [0:NUM_BYTES-1];
    reg [7:0] observed_byte;
    integer byte_idx;
    integer bit_idx;

    uart_result_streamer #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .result(result),
        .tx(tx),
        .busy(busy),
        .done(done)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("uart_result_streamer_tb.vcd");
        $dumpvars(0, uart_result_streamer_tb);
    end

    task automatic expect_uart_byte;
        input [7:0] expected;
        input integer index;
        begin
            observed_byte = 8'h00;

            wait (tx === 1'b0);
            #(BIT_PERIOD + (BIT_PERIOD / 2));

            for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                observed_byte[bit_idx] = tx;
                #(BIT_PERIOD);
            end

            if (tx !== 1'b1) begin
                $display("FAIL: stop bit missing for byte %0d", index);
                $finish;
            end

            if (observed_byte !== expected) begin
                $display(
                    "FAIL: byte %0d mismatch. Expected 0x%02h (%s), got 0x%02h (%s)",
                    index,
                    expected,
                    expected,
                    observed_byte,
                    observed_byte
                );
                $finish;
            end

            $display("Byte %0d OK: 0x%02h (%s)", index, observed_byte, observed_byte);
            #(BIT_PERIOD / 2);
        end
    endtask

    initial begin
        expected_bytes[0] = "8";
        expected_bytes[1] = "9";
        expected_bytes[2] = "A";
        expected_bytes[3] = "B";
        expected_bytes[4] = "C";
        expected_bytes[5] = "D";
        expected_bytes[6] = "E";
        expected_bytes[7] = "F";
        expected_bytes[8] = 8'h0D;
        expected_bytes[9] = 8'h0A;

        rst = 1'b1;
        start = 1'b0;
        result = 32'h89ABCDEF;

        #(CLK_PERIOD * 3);
        rst = 1'b0;

        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        if (!busy) begin
            @(posedge busy);
        end

        for (byte_idx = 0; byte_idx < NUM_BYTES; byte_idx = byte_idx + 1) begin
            expect_uart_byte(expected_bytes[byte_idx], byte_idx);
        end

        wait(done);
        @(posedge clk);

        if (busy) begin
            $display("FAIL: busy should be low after the last byte");
            $finish;
        end

        $display("PASS: UART result streamer transmitted the expected ASCII hex frame.");
        $finish;
    end

    initial begin
        #(BIT_PERIOD * NUM_BYTES * 16);
        $display("FAIL: UART streamer test timed out.");
        $finish;
    end

endmodule
