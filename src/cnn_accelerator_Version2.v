/*
  CNN Hardware Accelerator - 3-stage parallel datapath
  Output = (sum(xi * hi)) / 9 / K

  Stage 1: launch all 3x3 products in parallel
  Stage 2: reduce the 9 products into 3 partial sums
  Stage 3: reduce the partial sums into one accumulator value
*/

module cnn_accelerator #(
    parameter WIDTH = 32,
    parameter ACC_WIDTH = 72,
    parameter NUM_INPUTS = 9,
    parameter PIPELINE_LANES = 3
) (
    input clk,
    input rst,
    input start,

    input signed [WIDTH-1:0] input_data [0:NUM_INPUTS-1],
    input signed [WIDTH-1:0] kernel [0:NUM_INPUTS-1],
    input signed [WIDTH-1:0] scale_factor,

    output signed [WIDTH-1:0] result,
    output done
);

    localparam integer GROUP_SIZE = (NUM_INPUTS + PIPELINE_LANES - 1) / PIPELINE_LANES;

    wire [NUM_INPUTS-1:0] mult_done_bus;
    wire signed [2*WIDTH-1:0] mult_product [0:NUM_INPUTS-1];
    wire signed [ACC_WIDTH-1:0] mult_product_ext [0:NUM_INPUTS-1];
    wire mult_start;
    wire stage2_en;
    wire stage3_en;
    wire div9_start;
    wire div_start;
    wire output_valid;
    wire [3:0] controller_state;
    wire all_mult_done = &mult_done_bus;

    reg signed [ACC_WIDTH-1:0] stage1_products [0:NUM_INPUTS-1];
    reg signed [ACC_WIDTH-1:0] stage2_partial [0:PIPELINE_LANES-1];
    reg signed [ACC_WIDTH-1:0] stage3_sum;
    reg signed [WIDTH-1:0] result_reg;

    reg signed [ACC_WIDTH-1:0] partial_sum_comb [0:PIPELINE_LANES-1];
    reg signed [ACC_WIDTH-1:0] total_sum_comb;

    wire signed [ACC_WIDTH-1:0] div9_result;
    wire div9_done;
    wire signed [WIDTH-1:0] final_result;
    wire div_done;

    integer group_idx;
    integer lane_idx;
    integer reg_idx;

    controller ctrl_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .mult_done(all_mult_done),
        .div9_done(div9_done),
        .div_done(div_done),
        .mult_start(mult_start),
        .stage2_en(stage2_en),
        .stage3_en(stage3_en),
        .div9_start(div9_start),
        .div_start(div_start),
        .output_valid(output_valid),
        .state(controller_state)
    );

    genvar mult_idx;
    generate
        for (mult_idx = 0; mult_idx < NUM_INPUTS; mult_idx = mult_idx + 1) begin : gen_parallel_mult
            multiplier #(.WIDTH(WIDTH)) mult_inst (
                .clk(clk),
                .rst(rst),
                .start(mult_start),
                .a(input_data[mult_idx]),
                .b(kernel[mult_idx]),
                .product(mult_product[mult_idx]),
                .done(mult_done_bus[mult_idx])
            );

            assign mult_product_ext[mult_idx] = {{
                (ACC_WIDTH - (2 * WIDTH)){mult_product[mult_idx][(2 * WIDTH) - 1]}
            }, mult_product[mult_idx]};
        end
    endgenerate

    divide_by_9 #(.WIDTH(ACC_WIDTH)) div9_inst (
        .clk(clk),
        .rst(rst),
        .start(div9_start),
        .dividend(stage3_sum),
        .quotient(div9_result),
        .done(div9_done)
    );

    divider #(.WIDTH(WIDTH)) div_inst (
        .clk(clk),
        .rst(rst),
        .start(div_start),
        .dividend(div9_result[WIDTH-1:0]),
        .divisor(scale_factor),
        .quotient(final_result),
        .remainder(),
        .done(div_done)
    );

    always @(*) begin
        for (group_idx = 0; group_idx < PIPELINE_LANES; group_idx = group_idx + 1) begin
            partial_sum_comb[group_idx] = {ACC_WIDTH{1'b0}};
            for (
                lane_idx = group_idx * GROUP_SIZE;
                (lane_idx < ((group_idx + 1) * GROUP_SIZE)) && (lane_idx < NUM_INPUTS);
                lane_idx = lane_idx + 1
            ) begin
                partial_sum_comb[group_idx] = partial_sum_comb[group_idx] + stage1_products[lane_idx];
            end
        end

        total_sum_comb = {ACC_WIDTH{1'b0}};
        for (group_idx = 0; group_idx < PIPELINE_LANES; group_idx = group_idx + 1) begin
            total_sum_comb = total_sum_comb + stage2_partial[group_idx];
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            result_reg <= {WIDTH{1'b0}};
            stage3_sum <= {ACC_WIDTH{1'b0}};

            for (reg_idx = 0; reg_idx < NUM_INPUTS; reg_idx = reg_idx + 1) begin
                stage1_products[reg_idx] <= {ACC_WIDTH{1'b0}};
            end

            for (reg_idx = 0; reg_idx < PIPELINE_LANES; reg_idx = reg_idx + 1) begin
                stage2_partial[reg_idx] <= {ACC_WIDTH{1'b0}};
            end
        end else begin
            if (all_mult_done) begin
                for (reg_idx = 0; reg_idx < NUM_INPUTS; reg_idx = reg_idx + 1) begin
                    stage1_products[reg_idx] <= mult_product_ext[reg_idx];
                end
            end

            if (stage2_en) begin
                for (reg_idx = 0; reg_idx < PIPELINE_LANES; reg_idx = reg_idx + 1) begin
                    stage2_partial[reg_idx] <= partial_sum_comb[reg_idx];
                end
            end

            if (stage3_en) begin
                stage3_sum <= total_sum_comb;
            end

            if (div_done) begin
                result_reg <= final_result;
            end
        end
    end

    assign result = result_reg;
    assign done = output_valid;

endmodule
