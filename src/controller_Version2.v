/*
  3-stage controller for the CNN hardware accelerator.
  Stage 1: launch all multipliers in parallel and wait for completion.
  Stage 2: register three partial sums.
  Stage 3: register the final accumulated sum, then normalize it.
*/

module controller (
    input clk,
    input rst,
    input start,
    input mult_done,
    input div9_done,
    input div_done,

    output reg mult_start,
    output reg stage2_en,
    output reg stage3_en,
    output reg div9_start,
    output reg div_start,
    output reg output_valid,
    output reg [3:0] state
);

    localparam IDLE = 4'd0;
    localparam WAIT_MULT = 4'd1;
    localparam REDUCE_L1 = 4'd2;
    localparam REDUCE_L2 = 4'd3;
    localparam START_DIV9 = 4'd4;
    localparam WAIT_DIV9 = 4'd5;
    localparam START_DIV = 4'd6;
    localparam WAIT_DIV = 4'd7;
    localparam OUTPUT = 4'd8;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            mult_start <= 1'b0;
            stage2_en <= 1'b0;
            stage3_en <= 1'b0;
            div9_start <= 1'b0;
            div_start <= 1'b0;
            output_valid <= 1'b0;
        end else begin
            mult_start <= 1'b0;
            stage2_en <= 1'b0;
            stage3_en <= 1'b0;
            div9_start <= 1'b0;
            div_start <= 1'b0;
            output_valid <= 1'b0;

            case (state)
                IDLE: begin
                    if (start) begin
                        mult_start <= 1'b1;
                        state <= WAIT_MULT;
                    end
                end

                WAIT_MULT: begin
                    if (mult_done) begin
                        state <= REDUCE_L1;
                    end
                end

                REDUCE_L1: begin
                    stage2_en <= 1'b1;
                    state <= REDUCE_L2;
                end

                REDUCE_L2: begin
                    stage3_en <= 1'b1;
                    state <= START_DIV9;
                end

                START_DIV9: begin
                    div9_start <= 1'b1;
                    state <= WAIT_DIV9;
                end

                WAIT_DIV9: begin
                    if (div9_done) begin
                        state <= START_DIV;
                    end
                end

                START_DIV: begin
                    div_start <= 1'b1;
                    state <= WAIT_DIV;
                end

                WAIT_DIV: begin
                    if (div_done) begin
                        output_valid <= 1'b1;
                        state <= OUTPUT;
                    end
                end

                OUTPUT: begin
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
