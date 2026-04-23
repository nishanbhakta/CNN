/*
  Low-I/O implementation wrapper for generated image datasets.
  - Includes generated windows internally instead of exposing them as top-level ports
  - Replays each generated 3x3 patch through cnn_accelerator
  - Stores each 16-bit result so the board wrapper can browse outputs later
*/

module cnn_generated_image_runner #(
    parameter WIDTH = 32,
    parameter ACC_WIDTH = 72,
    parameter NUM_INPUTS = 9,
    parameter COUNT_WIDTH = 16
) (
    input clk,
    input rst,
    input start,
    input [COUNT_WIDTH-1:0] display_index,
    output busy,
    output done,
    output all_match,
    output mismatch_seen,
    output [COUNT_WIDTH-1:0] completed_windows,
    output [COUNT_WIDTH-1:0] mismatch_count,
    output [COUNT_WIDTH-1:0] total_windows,
    output signed [15:0] display_value,
    output display_value_valid
);

    // Simple sequencer: load one generated window, run the accelerator, store the result.
    localparam [2:0] STATE_IDLE = 3'd0;
    localparam [2:0] STATE_LOAD = 3'd1;
    localparam [2:0] STATE_START = 3'd2;
    localparam [2:0] STATE_WAIT = 3'd3;
    localparam [2:0] STATE_DONE = 3'd4;
    localparam [COUNT_WIDTH-1:0] TOTAL_WINDOW_COUNT = GENERATED_NUM_WINDOWS;

`include "generated_windows.vh"

    // Local copies of the active patch and kernel presented to the accelerator.
    reg signed [WIDTH-1:0] input_data [0:NUM_INPUTS-1];
    reg signed [WIDTH-1:0] kernel [0:NUM_INPUTS-1];
    // Result RAM lets the board wrapper revisit previously computed outputs.
    (* ram_style = "block" *) reg signed [15:0] stored_outputs [0:GENERATED_NUM_WINDOWS-1];
    reg signed [WIDTH-1:0] scale_factor;
    reg accelerator_start;
    reg busy_reg;
    reg done_reg;
    reg [2:0] state;
    reg [COUNT_WIDTH-1:0] window_index_reg;
    reg [COUNT_WIDTH-1:0] completed_windows_reg;
    reg [COUNT_WIDTH-1:0] mismatch_count_reg;
    reg [31:0] current_row_reg;
    reg [31:0] current_col_reg;
    reg signed [WIDTH-1:0] last_result_reg;
    reg signed [WIDTH-1:0] last_expected_reg;

    wire signed [WIDTH-1:0] accelerator_result;
    wire accelerator_done;
    reg signed [15:0] display_value_reg;

    integer patch_index;

    cnn_accelerator #(
        .WIDTH(WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .NUM_INPUTS(NUM_INPUTS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(accelerator_start),
        .input_data(input_data),
        .kernel(kernel),
        .scale_factor(scale_factor),
        .result(accelerator_result),
        .done(accelerator_done)
    );

    always @(posedge clk) begin
        if (rst) begin
            accelerator_start <= 1'b0;
            busy_reg <= 1'b0;
            done_reg <= 1'b0;
            state <= STATE_IDLE;
            window_index_reg <= {COUNT_WIDTH{1'b0}};
            completed_windows_reg <= {COUNT_WIDTH{1'b0}};
            mismatch_count_reg <= {COUNT_WIDTH{1'b0}};
            current_row_reg <= 32'd0;
            current_col_reg <= 32'd0;
            last_result_reg <= {WIDTH{1'b0}};
            last_expected_reg <= {WIDTH{1'b0}};
            scale_factor <= {WIDTH{1'b0}};

            for (patch_index = 0; patch_index < NUM_INPUTS; patch_index = patch_index + 1) begin
                input_data[patch_index] <= {WIDTH{1'b0}};
                kernel[patch_index] <= {WIDTH{1'b0}};
            end
        end else begin
            accelerator_start <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    done_reg <= 1'b0;
                    if (start) begin
                        // Reset counters and begin replaying the generated windows from index 0.
                        window_index_reg <= {COUNT_WIDTH{1'b0}};
                        completed_windows_reg <= {COUNT_WIDTH{1'b0}};
                        mismatch_count_reg <= {COUNT_WIDTH{1'b0}};
                        current_row_reg <= 32'd0;
                        current_col_reg <= 32'd0;
                        last_result_reg <= {WIDTH{1'b0}};
                        last_expected_reg <= {WIDTH{1'b0}};
                        busy_reg <= 1'b1;

                        if (GENERATED_NUM_WINDOWS == 0) begin
                            done_reg <= 1'b1;
                            busy_reg <= 1'b0;
                            state <= STATE_DONE;
                        end else begin
                            state <= STATE_LOAD;
                        end
                    end
                end

                STATE_LOAD: begin
                    // Load the next generated window and expected reference result.
                    scale_factor <= GENERATED_SCALE_FACTOR;
                    current_row_reg <= generated_window_rows[window_index_reg];
                    current_col_reg <= generated_window_cols[window_index_reg];
                    last_expected_reg <= generated_expected_results[window_index_reg];

                    for (patch_index = 0; patch_index < NUM_INPUTS; patch_index = patch_index + 1) begin
                        input_data[patch_index] <= generated_image_windows[window_index_reg][patch_index];
                        kernel[patch_index] <= generated_kernel[patch_index];
                    end

                    state <= STATE_START;
                end

                STATE_START: begin
                    // Pulse the accelerator start for exactly one cycle.
                    accelerator_start <= 1'b1;
                    state <= STATE_WAIT;
                end

                STATE_WAIT: begin
                    if (accelerator_done) begin
                        // Save the computed result and update completion/mismatch counters.
                        last_result_reg <= accelerator_result;
                        stored_outputs[window_index_reg] <= accelerator_result[15:0];
                        completed_windows_reg <= window_index_reg + 1'b1;

                        if (accelerator_result != generated_expected_results[window_index_reg]) begin
                            mismatch_count_reg <= mismatch_count_reg + 1'b1;
                        end

                        if ((window_index_reg + 1'b1) >= TOTAL_WINDOW_COUNT) begin
                            busy_reg <= 1'b0;
                            done_reg <= 1'b1;
                            state <= STATE_DONE;
                        end else begin
                            window_index_reg <= window_index_reg + 1'b1;
                            state <= STATE_LOAD;
                        end
                    end
                end

                STATE_DONE: begin
                    if (start) begin
                        // Allow a fresh replay without requiring a global reset.
                        done_reg <= 1'b0;
                        window_index_reg <= {COUNT_WIDTH{1'b0}};
                        completed_windows_reg <= {COUNT_WIDTH{1'b0}};
                        mismatch_count_reg <= {COUNT_WIDTH{1'b0}};
                        current_row_reg <= 32'd0;
                        current_col_reg <= 32'd0;
                        last_result_reg <= {WIDTH{1'b0}};
                        last_expected_reg <= {WIDTH{1'b0}};
                        busy_reg <= 1'b1;

                        if (GENERATED_NUM_WINDOWS == 0) begin
                            done_reg <= 1'b1;
                            busy_reg <= 1'b0;
                        end else begin
                            state <= STATE_LOAD;
                        end
                    end
                end

                default: begin
                    state <= STATE_IDLE;
                    busy_reg <= 1'b0;
                    done_reg <= 1'b0;
                end
            endcase
        end
    end

    always @(*) begin
        // Expose a stored result only after the full run has completed.
        display_value_reg = 16'sd0;
        if ((display_index < TOTAL_WINDOW_COUNT) && done_reg) begin
            display_value_reg = stored_outputs[display_index];
        end
    end

    assign busy = busy_reg;
    assign done = done_reg;
    assign all_match = done_reg && (mismatch_count_reg == {COUNT_WIDTH{1'b0}});
    assign mismatch_seen = (mismatch_count_reg != {COUNT_WIDTH{1'b0}});
    assign completed_windows = completed_windows_reg;
    assign mismatch_count = mismatch_count_reg;
    assign total_windows = TOTAL_WINDOW_COUNT;
    assign display_value = display_value_reg;
    assign display_value_valid = done_reg && (display_index < TOTAL_WINDOW_COUNT);

endmodule
