module Picture_Controller
#(
	
	//Video Adapter
	parameter ENDFRAME = 11'd627
)
(
	input wire clk,
	input wire rst,
	
	input wire [15:0] DATA,
	output reg DATA_valid,
	input wire [10:0] V_count,
	input wire Hblank,
	
	output wire [23:0]   DATA_addr,
	input wire WriteFlag,
	input wire	DATA_in_ready,
	output reg	Serial_access = 'b0,
	
	output reg StringRAM_we,
	output reg [10:0]StringRAM_write_addr,
	output reg [11:0] StringRAM_data
	
);


reg [10:0]DATA_Counter = 0;
reg [10:0]DATA_String_Counter = 0;

reg [7:0] Cb;
reg [7:0] Cr;

assign DATA_addr[10:0] = DATA_Counter[10:0];
assign DATA_addr[21:11] = DATA_String_Counter[10:0];
assign DATA_addr[23:22] = 0;


reg [3:0] BufferState;


parameter   S_READBEGIN = 4'd0,
				S_READSTRING = 4'd1,
				S_READREADY = 4'd2,
				S_WAITE = 4'd3;



always @(posedge clk)
begin
	if (rst)
	begin
	DATA_Counter <= 0;
	DATA_String_Counter <= 0;
	BufferState <= S_READBEGIN;
	
	end
	
	else 
	begin
	
		case(BufferState)
			S_READBEGIN:
			begin
				if (WriteFlag) BufferState <= S_WAITE;
				else BufferState <= S_READSTRING;
				DATA_Counter <= 'd0;
				Serial_access <= 'b1;
				StringRAM_we <= 'b0;
			end  
			
			S_READSTRING:
			begin
				if (DATA_Counter == 'd800) BufferState <= S_READREADY;
			
				if (WriteFlag) BufferState <= S_WAITE;
				
				if (DATA_in_ready)
				begin
					
					
					StringRAM_write_addr <= DATA_Counter;
					
					StringRAM_data[11:8] <= DATA[3:0];//Swap Red and blue
					StringRAM_data[7:4] <= DATA[7:4];
					StringRAM_data[3:0] <= DATA[11:8];
					
					DATA_Counter <= DATA_Counter + 1;
					DATA_valid <= 1'b0;
					StringRAM_we <= 'b1;
					
				end
				
				else DATA_valid <= 1'b1;
				
				
					
			end
			
			S_READREADY:
			begin
				StringRAM_we <= 'b0;
				Serial_access <= 'b0;
				if (Hblank)
				begin
					
					
					if (V_count < 'd599)
					begin 
						DATA_String_Counter <= V_count + 1'b1;
						BufferState <= S_READBEGIN;
					end

					else if (V_count == (ENDFRAME - 1'b1))
					begin
						DATA_String_Counter <= 0;
						BufferState <= S_READBEGIN;
					end
					
				end
			
			end
			
			S_WAITE:
			begin
				if (!WriteFlag) BufferState <= S_READSTRING;
				
			end
		endcase
		
	end
	
end


endmodule
