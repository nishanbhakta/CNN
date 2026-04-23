/*
    One-stage pipelined, DSP-friendly signed multiplier.
    - Latches a*b into an internal pipeline register when start is asserted.
    - Asserts done exactly one clock later (single-cycle operation latency).
    - Updates product only when the pipeline output is valid.
    - Preserves a simple start/done handshake expected by the controller.
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

    // Internal stage holding the multiplication result for one cycle.
    reg signed [2*WIDTH-1:0] product_pipe;
    // Valid bit aligned with product_pipe; drives done on the next cycle.
    reg valid_pipe;

    always @(posedge clk) begin
        if (rst) begin
            done <= 1'b0;
            product <= {2*WIDTH{1'b0}};
            product_pipe <= {2*WIDTH{1'b0}};
            valid_pipe <= 1'b0;
        end else begin
            // Present the stored product and matching completion pulse together.
            done <= valid_pipe;

            if (valid_pipe) begin
                product <= product_pipe;
            end

            if (start) begin
                // Map directly to a signed hardware multiply.
                product_pipe <= a * b;
            end

            valid_pipe <= start;
        end
    end

endmodule
