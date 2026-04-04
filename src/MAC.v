// MAC Module for CNN Hardware Accelerator
module MAC(
    input wire [15:0] a,
    input wire [15:0] b,
    output reg [31:0] y
);
    always @(*) begin
        y = a * b;
    end
endmodule
