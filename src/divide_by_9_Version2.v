/*
  Divide-by-9 Module
  - Single-cycle registered implementation
  - Uses exact signed division so negative values truncate toward zero.
 */

module divide_by_9 #(
    parameter WIDTH = 72
) (
    input clk,
    input rst,
    input start,
    input signed [WIDTH-1:0] dividend,
    output reg signed [WIDTH-1:0] quotient,
    output reg done
);

    always @(posedge clk) begin
        if (rst) begin
            done <= 1'b0;
            quotient <= {WIDTH{1'b0}};
        end else if (start) begin
            quotient <= dividend / 9;
            done <= 1'b1;
        end else begin
            done <= 1'b0;
        end
    end

endmodule
