module MCameraFrame
(
	input wire clk_120,
	input wire rst,
	
	input wire [7:0] Cam_ID,
	
	output reg [15:0] DATA,
	output wire [23:0]   DATA_addr,
	output reg DATA_valid,
	input wire	DATA_ready,
	output reg m_we,
	output reg	Serial_access = 'b0,
	
	output reg WriteFlag,
	
	input wire [10:0] V_Count,
	output reg [10:0] ReadAddr,
	input wire [15:0] Out_Data
);



reg[10:0] H_Copy_count = 0;
reg[10:0] V_Copy_count = 0;
wire [10:0] StringSize;

assign DATA_addr[10:0] = H_Copy_count[10:0];
assign DATA_addr[21:11] = V_Copy_count[10:0];
assign DATA_addr[23:22] = 0;

assign StringSize =  (Cam_ID == 'h26) ? 'd800 : 'd640;
							


reg [3:0] Copy_State = 'd0;

localparam  S_COPY_IDLE = 'd0,
				S_COPY = 'd1;
				
always@(posedge clk_120)
begin
	if (rst) 
	begin
		Copy_State <= S_COPY_IDLE;
		WriteFlag <= 1'b0;
		V_Copy_count <= 'd0;
	end
	else
	begin
		case (Copy_State)
		
		S_COPY_IDLE:
		begin
			WriteFlag <= 1'b0;
			H_Copy_count <= 'd0;
			m_we <= 1'b0;
			Serial_access <= 1'b0;
			if (V_Copy_count != V_Count)
			begin
				V_Copy_count <= V_Count;
				Copy_State <= S_COPY;
				
			end
		end
		
				
		S_COPY:
		begin
			if (H_Copy_count == StringSize)
			begin
				WriteFlag <= 1'b0;
				Copy_State <= S_COPY_IDLE;
			end
			
			else
			begin
				if (DATA_ready)
				begin
					H_Copy_count <= H_Copy_count + 1'b1;
					WriteFlag <= 1'b1;
					ReadAddr <= H_Copy_count;
					Serial_access <= 1'b1;
					DATA <= Out_Data;
					m_we <= 1'b1;
					DATA_valid <= 1'b0;
					
				end
				else
				begin
					DATA_valid <= 1'b1;
					
				end
			end
			
			
			
		end
		endcase
	end
end

endmodule





