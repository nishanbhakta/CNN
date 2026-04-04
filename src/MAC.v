// MAC Module for CNN Hardware Accelerator
// Sequential accumulator: result += product_in when enable is asserted.
// Clears accumulator when rst or reset_acc is asserted.
module mac #(
    parameter WIDTH = 32,
    parameter ACC_WIDTH = 72
) (
    input clk,
    input rst,
    input enable,
    input reset_acc,
    input signed [2*WIDTH-1:0] product_in,
    output reg signed [ACC_WIDTH-1:0] result
);
    always @(posedge clk) begin
        if (rst || reset_acc) begin
            result <= {ACC_WIDTH{1'b0}};
        end else if (enable) begin
            // Sign-extend product_in to ACC_WIDTH before accumulating
            result <= result + {{(ACC_WIDTH-2*WIDTH){product_in[2*WIDTH-1]}}, product_in};
        end
    end
endmodule
