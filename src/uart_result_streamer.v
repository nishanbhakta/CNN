/*
  Streams the 32-bit CNN result as ASCII hex over UART:
  XXXXXXXX\r\n
*/

module uart_result_streamer #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer BAUD_RATE = 115_200
) (
    input clk,
    input rst,
    input start,
    input [31:0] result,
    output tx,
    output busy,
    output reg done
);

    localparam [1:0] IDLE = 2'd0;
    localparam [1:0] REQUEST = 2'd1;
    localparam [1:0] WAIT_BYTE = 2'd2;
    localparam [3:0] LAST_BYTE_INDEX = 4'd9;

    reg [1:0] state;
    reg [3:0] byte_index;
    reg [31:0] result_latched;
    reg uart_start;
    wire uart_busy;
    wire uart_done;
    wire [7:0] current_byte;

    function [7:0] hex_to_ascii;
        input [3:0] nibble;
        begin
            case (nibble)
                4'h0: hex_to_ascii = "0";
                4'h1: hex_to_ascii = "1";
                4'h2: hex_to_ascii = "2";
                4'h3: hex_to_ascii = "3";
                4'h4: hex_to_ascii = "4";
                4'h5: hex_to_ascii = "5";
                4'h6: hex_to_ascii = "6";
                4'h7: hex_to_ascii = "7";
                4'h8: hex_to_ascii = "8";
                4'h9: hex_to_ascii = "9";
                4'hA: hex_to_ascii = "A";
                4'hB: hex_to_ascii = "B";
                4'hC: hex_to_ascii = "C";
                4'hD: hex_to_ascii = "D";
                4'hE: hex_to_ascii = "E";
                default: hex_to_ascii = "F";
            endcase
        end
    endfunction

    function [7:0] result_byte;
        input [31:0] value;
        input [3:0] index;
        begin
            case (index)
                4'd0: result_byte = hex_to_ascii(value[31:28]);
                4'd1: result_byte = hex_to_ascii(value[27:24]);
                4'd2: result_byte = hex_to_ascii(value[23:20]);
                4'd3: result_byte = hex_to_ascii(value[19:16]);
                4'd4: result_byte = hex_to_ascii(value[15:12]);
                4'd5: result_byte = hex_to_ascii(value[11:8]);
                4'd6: result_byte = hex_to_ascii(value[7:4]);
                4'd7: result_byte = hex_to_ascii(value[3:0]);
                4'd8: result_byte = 8'h0D;
                default: result_byte = 8'h0A;
            endcase
        end
    endfunction

    assign current_byte = result_byte(result_latched, byte_index);
    assign busy = (state != IDLE) || uart_busy;

    uart_tx #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) tx_inst (
        .clk(clk),
        .rst(rst),
        .start(uart_start),
        .data(current_byte),
        .tx(tx),
        .busy(uart_busy),
        .done(uart_done)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            byte_index <= 4'd0;
            result_latched <= 32'd0;
            uart_start <= 1'b0;
            done <= 1'b0;
        end else begin
            uart_start <= 1'b0;
            done <= 1'b0;

            case (state)
                IDLE: begin
                    if (start) begin
                        result_latched <= result;
                        byte_index <= 4'd0;
                        state <= REQUEST;
                    end
                end

                REQUEST: begin
                    if (!uart_busy) begin
                        uart_start <= 1'b1;
                        state <= WAIT_BYTE;
                    end
                end

                WAIT_BYTE: begin
                    if (uart_done) begin
                        if (byte_index == LAST_BYTE_INDEX) begin
                            done <= 1'b1;
                            state <= IDLE;
                        end else begin
                            byte_index <= byte_index + 1'b1;
                            state <= REQUEST;
                        end
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
