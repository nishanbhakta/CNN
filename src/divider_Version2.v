/*
  32-bit Restoring Divider - Sequential Implementation
  - Takes 32 cycles to complete
  - Supports signed integers
  - Outputs quotient and remainder
  - Uses explicit next-state signals so the final outputs come from the
    current division step instead of stale register contents.
 */

module divider #(
    parameter WIDTH = 32
) (
    input clk,
    input rst,
    input start,
    input signed [WIDTH-1:0] dividend,
    input signed [WIDTH-1:0] divisor,
    output reg signed [WIDTH-1:0] quotient,
    output reg signed [WIDTH-1:0] remainder,
    output reg done
);

    localparam IDLE = 1'b0;
    localparam DIVIDE = 1'b1;
    localparam COUNTER_WIDTH = $clog2(WIDTH + 1);
    localparam [COUNTER_WIDTH-1:0] ITERATIONS = WIDTH;

    reg state;
    reg [WIDTH-1:0] divisor_reg;
    reg [WIDTH-1:0] quotient_reg;
    reg [WIDTH:0] remainder_reg;
    reg [COUNTER_WIDTH-1:0] counter;
    reg result_sign;
    reg remainder_sign;

    wire dividend_sign = dividend[WIDTH-1];
    wire divisor_sign = divisor[WIDTH-1];
    wire [WIDTH-1:0] dividend_abs = dividend_sign ? -dividend : dividend;
    wire [WIDTH-1:0] divisor_abs = divisor_sign ? -divisor : divisor;

    wire [WIDTH:0] shifted_remainder = {remainder_reg[WIDTH-1:0], quotient_reg[WIDTH-1]};
    wire subtract_ok = shifted_remainder >= {1'b0, divisor_reg};
    wire [WIDTH:0] remainder_next = subtract_ok
        ? (shifted_remainder - {1'b0, divisor_reg})
        : shifted_remainder;
    wire [WIDTH-1:0] quotient_next = {quotient_reg[WIDTH-2:0], subtract_ok};

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            done <= 1'b0;
            quotient <= {WIDTH{1'b0}};
            remainder <= {WIDTH{1'b0}};
            divisor_reg <= {WIDTH{1'b0}};
            quotient_reg <= {WIDTH{1'b0}};
            remainder_reg <= {(WIDTH+1){1'b0}};
            counter <= {COUNTER_WIDTH{1'b0}};
            result_sign <= 1'b0;
            remainder_sign <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)
                IDLE: begin
                    if (start) begin
                        if (divisor == 0) begin
                            quotient <= {WIDTH{1'b0}};
                            remainder <= dividend;
                            done <= 1'b1;
                        end else begin
                            divisor_reg <= divisor_abs;
                            quotient_reg <= dividend_abs;
                            remainder_reg <= {(WIDTH+1){1'b0}};
                            result_sign <= dividend_sign ^ divisor_sign;
                            remainder_sign <= dividend_sign;
                            counter <= ITERATIONS;
                            state <= DIVIDE;
                        end
                    end
                end

                DIVIDE: begin
                    quotient_reg <= quotient_next;
                    remainder_reg <= remainder_next;
                    counter <= counter - 1'b1;

                    if (counter == {{(COUNTER_WIDTH-1){1'b0}}, 1'b1}) begin
                        quotient <= result_sign
                            ? -$signed(quotient_next)
                            : $signed(quotient_next);
                        remainder <= remainder_sign
                            ? -$signed(remainder_next[WIDTH-1:0])
                            : $signed(remainder_next[WIDTH-1:0]);
                        done <= 1'b1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
