// Verilog code for mac.v
module mac(output reg [31:0] result, input [31:0] a, b, c);
  always @(*) begin
    result = (a * b) + c;
  end
endmodule
