/*
  Divide-by-9 Module using Fixed-Point Reciprocal Multiplication
  - Avoids full division for efficiency
  - Uses: result = (input * RECIPROCAL_1_9) >> 28
  - RECIPROCAL_1_9 = 2^28 / 9 = 29,826,228 (Q28 format)
  - Single-cycle latency
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

    localparam signed [39:0] RECIPROCAL_1_9 = 40'sd29826228;
    // Q28 shift amount: right-shift by 28 to convert Q28 fixed-point product
    // back to an integer quotient (i.e., extracts the integer part of
    // dividend * (2^28/9) / 2^28 = dividend / 9).
    localparam SHIFT_AMOUNT = 28;
    
    always @(posedge clk) begin
        if (rst) begin
            done <= 1'b0;
            quotient <= {WIDTH{1'b0}};
        end else if (start) begin
            // Multiply by Q28 reciprocal and shift in a single registered
            // assignment so quotient and done are valid on the same cycle.
            quotient <= (dividend * RECIPROCAL_1_9) >>> SHIFT_AMOUNT;
            done <= 1'b1;
        end else begin
            done <= 1'b0;
        end
    end

endmodule