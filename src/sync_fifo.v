/*
    Simple synchronous FIFO with single-clock read/write ports.
    - Presents the current head entry on dout each cycle.
    - Supports simultaneous push and pop operations.
*/

module sync_fifo #(
    parameter WIDTH = 32,
    parameter DEPTH = 16
) (
    input clk,
    input rst,
    input wr_en,
    input rd_en,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout,
    output full,
    output empty
);

    localparam ADDR_WIDTH = (DEPTH <= 2) ? 1 : $clog2(DEPTH);
    localparam COUNT_WIDTH = $clog2(DEPTH + 1);

    // Storage plus head/tail pointers for the circular buffer.
    (* ram_style = "block" *) reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [COUNT_WIDTH-1:0] count;
    reg [WIDTH-1:0] dout_reg;

    wire do_write = wr_en && !full;
    wire do_read = rd_en && !empty;

    assign full = (count == DEPTH[COUNT_WIDTH-1:0]);
    assign empty = (count == {COUNT_WIDTH{1'b0}});
    assign dout = dout_reg;

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
            rd_ptr <= {ADDR_WIDTH{1'b0}};
            count <= {COUNT_WIDTH{1'b0}};
            dout_reg <= {WIDTH{1'b0}};
        end else begin
            // Present the current head entry every cycle.
            dout_reg <= mem[rd_ptr];

            if (do_write) begin
                mem[wr_ptr] <= din;
                if (wr_ptr == DEPTH - 1) begin
                    wr_ptr <= {ADDR_WIDTH{1'b0}};
                end else begin
                    wr_ptr <= wr_ptr + 1'b1;
                end
            end

            if (do_read) begin
                if (rd_ptr == DEPTH - 1) begin
                    rd_ptr <= {ADDR_WIDTH{1'b0}};
                end else begin
                    rd_ptr <= rd_ptr + 1'b1;
                end
            end

            // Update occupancy for write-only, read-only, or simultaneous access.
            case ({do_write, do_read})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule
