/*
  32-bit Signed Multiplier - Single-cycle registered implementation
  - Accepts signed inputs a and b (WIDTH bits each)
  - Outputs signed product (2*WIDTH bits)
  - done is asserted one cycle after start
*/

module multiplier #(
    parameter WIDTH = 32
) (
    input clk,
    input rst,
    input start,
    input signed [WIDTH-1:0] a,
    input signed [WIDTH-1:0] b,
    output reg signed [2*WIDTH-1:0] product,
    output reg done
);
    always @(posedge clk) begin
        if (rst) begin
            product <= {2*WIDTH{1'b0}};
            done    <= 1'b0;
        end else if (start) begin
            product <= a * b;
            done    <= 1'b1;
        end else begin
            done <= 1'b0;
        end
    end
endmodule
