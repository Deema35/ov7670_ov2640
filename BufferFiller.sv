module M_OV7670_BufferFiller
(
	input wire PCLK,
	input wire rst,
	
	input wire VSYNC,
	input wire HREF,
	input wire [7:0] CAM_DATA,
	
	output reg [15:0] Pix_Data,
	output reg [10:0] WriteAddr,
	output reg [10:0] V_Count,
	output reg CamString_we
);

reg[10:0] H_Count;


reg [3:0] Main_State = 0;

localparam  S_IDLE = 'd0,
				S_GET_FIST_BYTE = 'd2,
				S_GET_SECOND_BYTE = 'd3;

always@(posedge PCLK)
begin
	if (rst) 
	begin
		Main_State <= S_IDLE;
		V_Count <= 'd0;
	end
	else
	begin
		case (Main_State)
		
		S_IDLE: 
		begin
			if (VSYNC) V_Count <= 'd0;
			
			H_Count <= 'd0; 
			CamString_we <= 1'b0;
			
			if (HREF)
			begin
				
				Pix_Data[15:8] <= CAM_DATA;
			
				Main_State <= S_GET_SECOND_BYTE;
				
			end
			
		end
		
		S_GET_FIST_BYTE:
		begin
			
			if (HREF)
			begin
				
				Pix_Data[15:8] <= CAM_DATA;
				CamString_we <= 1'b0;
				Main_State <= S_GET_SECOND_BYTE;
				
			end
			else
			begin
				Main_State <= S_IDLE;
				V_Count <= V_Count + 1'b1;
				
			end
			
		end
		
		S_GET_SECOND_BYTE:
		begin
			if (HREF)
			begin
				Pix_Data[7:0] <= CAM_DATA;
				CamString_we <= 1'b1;
				WriteAddr <= H_Count;
				Main_State <= S_GET_FIST_BYTE;
				H_Count <= H_Count + 1'b1;
			end
			else
			begin
				Main_State <= S_IDLE;
				V_Count <= V_Count + 1'b1;
				
			end
			
		end
		
		endcase
	end
end

endmodule

module M_OV2640_BufferFiller
(
	input wire PCLK,
	input wire rst,
	
	input wire VSYNC,
	input wire HREF,
	input wire [7:0] CAM_DATA,
	
	output reg [15:0] Pix_Data,
	output reg [10:0] WriteAddr,
	output wire [10:0] V_Count,
	output reg CamString_we,
	
	output reg Blue_Buffer_we,
	output reg [10:0] Blue_Buffer_ReadAddr,
	output reg [10:0] Blue_Buffer_WriteAddr,
	input wire [3:0] Blue_Buffer_Read_Data,
	output reg [3:0] Blue_Buffer_Write_Data
);

reg[10:0] H_Count;
reg [10:0] V_Count_real;
assign V_Count = V_Count_real/2;


reg [3:0] Main_State = 0;

localparam  S_IDLE = 'd0,
				S_GET_FIST_BYTE = 'd2,
				S_GET_SECOND_BYTE = 'd3;

always@(posedge PCLK)
begin
	if (rst) 
	begin
		Main_State <= S_IDLE;
		V_Count_real <= 'd0;
	end
	else
	begin
		case (Main_State)
		
		S_IDLE: 
		begin
			if (VSYNC) V_Count_real <= 'd0;
			
			H_Count <= 'd0; 
			CamString_we <= 1'b0;
			
			if (HREF)
			begin
				if (V_Count_real[0])
				begin
					Pix_Data[7] <= CAM_DATA[7];
					Pix_Data[6] <= CAM_DATA[5];
					Pix_Data[5] <= CAM_DATA[0];
					Pix_Data[4] <= CAM_DATA[3];
				end
				
				else
				begin
					Blue_Buffer_WriteAddr <= 'd0;
					Blue_Buffer_we <= 1'b1;
					
					Blue_Buffer_Write_Data[3] <= CAM_DATA[7];
					Blue_Buffer_Write_Data[2] <= CAM_DATA[5];
					Blue_Buffer_Write_Data[1] <= CAM_DATA[0];
					Blue_Buffer_Write_Data[0] <= CAM_DATA[3];
					
				end
				
				Main_State <= S_GET_SECOND_BYTE;
			end
			
		end
		
		S_GET_FIST_BYTE:
		begin
			
			if (HREF)
			begin
				
				if (V_Count_real[0])
				begin
					Pix_Data[7] <= CAM_DATA[7]; //Green data
					Pix_Data[6] <= CAM_DATA[5];
					Pix_Data[5] <= CAM_DATA[0];
					Pix_Data[4] <= CAM_DATA[3];
					
					
					Pix_Data[3:0] <= Blue_Buffer_Read_Data[3:0];
					CamString_we <= 1'b0;
				end
				else
				begin
					Blue_Buffer_WriteAddr <= H_Count;
					Blue_Buffer_we <= 1'b1;
				
					Blue_Buffer_Write_Data[3] <= CAM_DATA[7];
					Blue_Buffer_Write_Data[2] <= CAM_DATA[5];
					Blue_Buffer_Write_Data[1] <= CAM_DATA[0];
					Blue_Buffer_Write_Data[0] <= CAM_DATA[3];
					
				end
				
				Main_State <= S_GET_SECOND_BYTE;
			end
			else
			begin
				Main_State <= S_IDLE;
				V_Count_real <= V_Count_real + 1'b1;
				
			end
			
		end
		
		S_GET_SECOND_BYTE:
		begin
			if (HREF)
			begin
				if (V_Count_real[0])
				begin
					Pix_Data[11] <= CAM_DATA[7]; //Red data
					Pix_Data[10] <= CAM_DATA[5];
					Pix_Data[9] <= CAM_DATA[3];
					Pix_Data[8] <= CAM_DATA[0];
					
					
					CamString_we <= 1'b1;
					WriteAddr <= H_Count;
				end
				H_Count <= H_Count + 1'b1;
					
			
				
				Main_State <= S_GET_FIST_BYTE;
				
			end
			else
			begin
				Main_State <= S_IDLE;
				V_Count_real <= V_Count_real + 1'b1;
				
			end
			Blue_Buffer_we <= 1'b0;
			Blue_Buffer_ReadAddr <= H_Count;
		end
		
		endcase
	end
end

endmodule

