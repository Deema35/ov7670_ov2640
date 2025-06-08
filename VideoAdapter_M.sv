module VideoAdapter_M
#(
	parameter ENDSTRING = 11'd1055,
	parameter ENDFRAME = 11'd627
	
)

(
	input wire clk,
	input wire rst,
	input wire [11:0]  Pix_color,
	
	output reg Hsync,
	output reg Vsync,
	
	output wire [3:0]  Red,
	output wire [3:0]  Green,
	output wire [3:0]  Blue,
	
	
	output reg Hblank,
	output reg Vblank,
	
	output reg [10:0] H_count,
	output reg [10:0] V_count
	
);


wire blank;

assign blank = Hblank | Vblank;

assign Red[3:0] = blank ? 4'b0000 : Pix_color[3:0];

assign Green[3:0] = blank ? 4'b0000 : Pix_color[7:4];

assign Blue[3:0] = blank ? 4'b0000 : Pix_color[11:8];


HorizontalCounter 
#(
	.ENDSTRING(ENDSTRING)
)
H_Counter
(
	.clk(clk),
	.rst(rst),
	.DATA(H_count)
);



VerticalCounter
#(
	.ENDSTRING(ENDSTRING),
	.ENDFRAME(ENDFRAME)
)
 V_Counter
(
	.clk(clk),
	.rst(rst),
	.Hor_count(H_count),
	.DATA(V_count),
);

always @(posedge clk ) 
begin 
	
	if (rst)
	begin
	
		Hblank <= 1'b0;
		Hsync <= 1'b0;
		
	end
	else
	begin
		
		case (H_count)
		
			799: Hblank <= 1'b1;
			
			839: Hsync <= 1'b1;
			
			967: Hsync <= 1'b0;
			
			ENDSTRING: Hblank <= 1'b0;
			
		endcase
		
		case (V_count)
		
			599: Vblank <= 1'b1;
			
			600: Vsync <= 1'b1;
			
			604: Vsync <= 1'b0;
			
			ENDFRAME: Vblank <= 1'b0;
			
		endcase
	end
		

end
endmodule



module HorizontalCounter
#(
	parameter ENDSTRING = 0
)
( 
	input wire clk,
	input wire rst,
	output reg [10:0]DATA
);


always @(posedge clk ) 
begin 

	if (rst) DATA <= 11'd0;
		
	else
	begin
	
	  if(DATA == ENDSTRING) DATA <= 11'd0;
		 
	  else DATA <= DATA + 1'd1; 
	  
	end
		 
end

endmodule 

module VerticalCounter
#(
	parameter ENDFRAME = 0,
	parameter ENDSTRING = 0
)
( 
	input wire clk, 
	input wire rst,
	input wire [10:0]Hor_count,
	output reg [10:0]DATA
);


always @(posedge clk ) 
begin 
	if (rst) DATA <= 11'd0;
	
	else
	begin
	
	  if(DATA == ENDFRAME) DATA <= 11'd0;
		 
	  else if (Hor_count == ENDSTRING)  DATA <= DATA + 1'd1; 
	  
	end
		 
end
		 

endmodule 
