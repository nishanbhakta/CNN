/*
  FSM Controller for CNN Hardware Accelerator
  States: IDLE -> LOAD -> MULTIPLY -> ACCUMULATE -> DIV9 -> DIVIDE -> OUTPUT
*/

module controller (
    input clk,
    input rst,
    input start,
    input mult_done,
    input div9_done,
    input div_done,
    
    output reg mult_start,
    output reg div9_start,
    output reg div_start,
    output reg mac_reset,
    output reg mac_enable,
    output reg output_valid,
    output reg reset_input_idx,
    output reg [2:0] state
);

    localparam IDLE = 3'd0;
    localparam LOAD = 3'd1;
    localparam MULTIPLY = 3'd2;
    localparam ACCUMULATE = 3'd3;
    localparam DIV9 = 3'd4;
    localparam WAIT_DIV9 = 3'd5;
    localparam DIVIDE = 3'd6;
    localparam OUTPUT = 3'd7;
    
    reg [3:0] input_count;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            mult_start <= 1'b0;
            div9_start <= 1'b0;
            div_start <= 1'b0;
            mac_reset <= 1'b0;
            mac_enable <= 1'b0;
            output_valid <= 1'b0;
            reset_input_idx <= 1'b0;
            input_count <= 4'b0;
        end
        else begin
            reset_input_idx <= 1'b0;  // Default: don't reset
            
            case (state)
                IDLE: begin
                    output_valid <= 1'b0;
                    mac_reset <= 1'b1;
                    mult_start <= 1'b0;
                    if (start) begin
                        input_count <= 4'b0;
                        reset_input_idx <= 1'b1;
                        state <= LOAD;
                    end
                end
                
                LOAD: begin
                    mac_reset <= 1'b0;
                    mult_start <= 1'b1;
                    state <= MULTIPLY;
                end
                
                MULTIPLY: begin
                    mult_start <= 1'b0;
                    if (mult_done) begin
                        mac_enable <= 1'b1;
                        state <= ACCUMULATE;
                    end
                end
                
                ACCUMULATE: begin
                    mac_enable <= 1'b0;
                    input_count <= input_count + 1'b1;
                    
                    if (input_count == 4'd8) begin
                        state <= DIV9;
                    end
                    else begin
                        mult_start <= 1'b1;
                        state <= MULTIPLY;
                    end
                end
                
                DIV9: begin
                    div9_start <= 1'b1;
                    state <= WAIT_DIV9;
                end
                
                WAIT_DIV9: begin
                    div9_start <= 1'b0;
                    if (div9_done) begin
                        div_start <= 1'b1;
                        state <= DIVIDE;
                    end
                end
                
                DIVIDE: begin
                    div_start <= 1'b0;
                    if (div_done) begin
                        output_valid <= 1'b1;
                        state <= OUTPUT;
                    end
                end
                
                OUTPUT: begin
                    if (output_valid) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule