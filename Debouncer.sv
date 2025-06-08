module Debouncer
(
	input wire clk,
	input wire Button,
	output wire Out
);
reg [19:0] delay;
reg [2:0] shift;

always @(posedge clk)
begin
    delay = delay + 1;
    if (delay == 'd1000000) delay = 'd0;
end

wire ten_ms;
assign ten_ms = (delay == 0);

always @(posedge ten_ms)
begin
    shift[2:0] = {Button, shift[2:1]};
end

assign level = &shift;

always @(posedge level)
begin
    Out <= !Out;
end

endmodule