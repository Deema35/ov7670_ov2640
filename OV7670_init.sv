module OV7670_init
#(
	parameter ov7670_ADDR = 7'b0100001,
	parameter ov2640_ADDR = 7'b0110000
)


(
	input wire clk,
	input wire rst,
	
	input wire sccb_ready,
	input wire Redy_Symbol,
	
	input wire [7:0] sccb_DATA_OUT,
	output wire [7:0] sccb_DATA_IN,
	output wire [7:0] sccb_REG,
	output wire [7:0] Write_Symbol,
	output reg [6:0] sccb_addr,
	
	output wire sccb_valid,
	output reg CAM_RESET,
	output wire Valid_Symbol,
	output wire [3:0] sccb_op_type,
	output wire DataSymbol,
	output reg InitReady = 0,
	output reg [7:0] Cam_ID
	
	
);





wire [7:0]Config_REG;
wire [7:0]Read_REG;
assign sccb_REG = (Config_valid) ? Config_REG : Read_REG;

wire [7:0]Config_Symbol;
wire [7:0]Read_Symbol;
assign Write_Symbol = (Config_valid) ? Config_Symbol : Read_Symbol;

reg Config_sccb_valid;
reg Read_sccb_valid;
assign sccb_valid = (Config_valid) ? Config_sccb_valid : Read_sccb_valid;

reg Config_Valid_Symbol;
reg Read_Valid_Symbol;
assign Valid_Symbol = (Config_valid) ? Config_Valid_Symbol : Read_Valid_Symbol;

reg [3:0] Config_sccb_op_type;
reg [3:0] Read_sccb_op_type;
assign sccb_op_type = (Config_valid) ? Config_sccb_op_type : Read_sccb_op_type;

assign DataSymbol = (Config_valid) ? Config_DataSymbol : Read_DataSymbol;



reg [3:0] byte_num;
reg [7:0] Reg_Read_Addr;
reg Read_valid = 1'b0;
wire Read_ready;

MSerialRead SerialRead
(
	.clk(clk),
	.rst(rst),
	
	.byte_num(byte_num),
	.Read_Addr(Reg_Read_Addr),
	
	.Read_valid(Read_valid),
	.Read_ready(Read_ready),
	
	.sccb_ready(sccb_ready),
	.sccb_DATA_OUT(sccb_DATA_OUT),
	.sccb_REG(Read_REG),
	.sccb_valid(Read_sccb_valid),
	.sccb_op_type(Read_sccb_op_type),
	
	
	.Redy_Symbol(Redy_Symbol),
	.Write_Symbol(Read_Symbol),
	.Valid_Symbol(Read_Valid_Symbol),
	.DataSymbol(Read_DataSymbol),
	.flag(flag)
	
);

reg Config_valid = 1'b0;
wire Config_ready;

Config_Write ConfigWrite
(
	.clk(clk),
	.rst(rst),
	
	.Config_valid(Config_valid),
	.Config_ready(Config_ready),
	
	.sccb_ready(sccb_ready),
	.Cam_ID(Cam_ID),
	.sccb_DATA_OUT(sccb_DATA_OUT),
	.sccb_DATA_IN(sccb_DATA_IN),
	.sccb_REG(Config_REG),
	.sccb_valid(Config_sccb_valid),
	.sccb_op_type(Config_sccb_op_type),
	
	.Redy_Symbol(Redy_Symbol),
	.Write_Symbol(Config_Symbol),
	.Valid_Symbol(Config_Valid_Symbol),
	.DataSymbol(Config_DataSymbol)
	
);


reg [24:0] cnt_wait;

reg [3:0] State_main = 4'd0;
reg IDget;

localparam 	S_BEGIN = 4'd0,
				S_CAM_RESET = 4'd1,
				S_GET_ID_ov7670 = 4'd2,
				S_READREADY_WAITE = 4'd3,
				S_GET_ID_ov2640 = 4'd4,
				S_READREADY_WAITE_2 = 4'd5,
				S_CONFIG = 4'd7,
				S_END = 4'd8;

always @(posedge clk) 
begin
	if(rst)
	begin
		State_main <= S_BEGIN;
		cnt_wait <= 'd0;
		InitReady <= 0;
	end
	else
	begin
		case (State_main)
		
		S_BEGIN:
		begin
			CAM_RESET <= 1'b0;
			IDget <= 'b0;
			if(cnt_wait != 16000000) cnt_wait <= cnt_wait + 1'b1; 
			
			else
			begin	
				cnt_wait <= 'd0;
				State_main <= S_CAM_RESET;
			end
		end
		
		S_CAM_RESET:
		begin
			
			CAM_RESET <= 1'b1;
			
			if(cnt_wait != 16000000) cnt_wait <= cnt_wait + 1'b1;
			
			else State_main <= S_GET_ID_ov7670;
		end
		
		S_GET_ID_ov7670:
		begin
			sccb_addr <= ov7670_ADDR;
			if(Read_ready)
			begin
				Read_valid <= 'b0;
				if (Cam_ID == 'h76) State_main <= S_CONFIG;
				else State_main <= S_READREADY_WAITE;
				
			end
			else
			begin
				if(Valid_Symbol & !IDget)
				begin
					Cam_ID <= Write_Symbol;
					IDget <= 1'b1;
				end
				
				Read_valid <= 'b1;
				byte_num <= 'd2;
				Reg_Read_Addr <= 'h0A;
			end
		end
		
		S_READREADY_WAITE:
		begin
			Cam_ID = 'h00;
			IDget <= 1'b0;
			if(!Read_ready) State_main <= S_GET_ID_ov2640;
		end
		
		S_GET_ID_ov2640:
		begin
			sccb_addr <= ov2640_ADDR;
			if(Read_ready)
			begin
				Read_valid <= 'b0;
				if (Cam_ID == 'h26) State_main <= S_CONFIG;
				else State_main <= S_READREADY_WAITE_2;
				
			end
			else
			begin
				if(Valid_Symbol & !IDget)
				begin
					Cam_ID <= Write_Symbol;
					IDget <= 1'b1;
				end
				
				Read_valid <= 'b1;
				byte_num <= 'd2;
				Reg_Read_Addr <= 'h0A;
			end
		end
		
		S_READREADY_WAITE_2:
		begin
			Cam_ID = 'h00;
			IDget <= 1'b0;
			if(!Read_ready) State_main <= S_END;
		end
		
		
				
		S_CONFIG:
		begin
			if (Config_ready)
			begin
				Config_valid <= 1'b0;
				State_main <= S_END;
			end
			else Config_valid <= 1'b1;
			
		end
		
		S_END:
		begin
			InitReady = 'b1;
		end
		endcase
	end
end

endmodule


module MSerialRead
(
	input wire clk,
	input wire rst,
	
	input wire [3:0] byte_num,
	input wire [7:0] Read_Addr,
	
	input wire Read_valid,
	output reg Read_ready,
	
	input wire sccb_ready,
	input wire Redy_Symbol,
	
	input wire [7:0] sccb_DATA_OUT,
	output reg [7:0] sccb_REG,
	output reg [7:0] Write_Symbol,
	
	output reg sccb_valid,
	output reg Valid_Symbol,
	output reg [3:0] sccb_op_type,
	output reg DataSymbol,
	output reg flag
	
	
);
reg [3:0] cnt_byte;



localparam  OP_W3 = 4'd0,
				OP_W2 = 4'd1,
				OP_R2 = 4'd2;
				
reg [3:0] State_main = 4'd0;
localparam 	S_BEGIN = 4'd0,
				S_SEND = 4'd2,
				S_GET = 4'd3,
				S_WAIT = 4'd4,
				S_PRINT_ON_SCREEN = 4'd5,
				S_NEXT_STRING_1 = 4'd6,
				S_NEXT_STRING_2 = 4'd7,
				S_END = 4'd8;
				
				


always @(posedge clk) 
begin
	if(rst)
	begin
		State_main <= S_BEGIN;
		
	end
	else
	begin
		case (State_main)
		S_BEGIN:
		begin
			Read_ready <= 'b0;
			Valid_Symbol <= 'd0;
			if (Read_valid)
			begin
				cnt_byte <= 'd0;
				State_main <= S_SEND;
			end
		end
		S_SEND:
		begin 
			if(!sccb_ready)
			begin
				sccb_op_type  <= OP_W2;
				sccb_REG <= Read_Addr + cnt_byte;
				sccb_valid <= 1'b1;
				State_main <= S_WAIT;
			end
		end
		
		S_GET:
		begin 
			
			if(!sccb_ready)
			begin
				sccb_op_type  <= OP_R2;
				sccb_valid <= 1'b1;
				cnt_byte <= cnt_byte + 'd1;
				State_main <= S_WAIT;
			end
		end
		
		S_WAIT:
		begin
			
			if (sccb_ready)
			begin
				sccb_valid <= 1'b0;
				if (sccb_op_type  == OP_W2) State_main <=  S_GET;
				else State_main <=  S_PRINT_ON_SCREEN;
			end
		end
		
		
		S_PRINT_ON_SCREEN:
		begin
			if(!Redy_Symbol)
			begin
				Write_Symbol <= sccb_DATA_OUT;
				Valid_Symbol <= 'b1;
				DataSymbol <=  'b1;
			end
			else
			begin
				
				Valid_Symbol <= 'b0;
				if (cnt_byte == byte_num) State_main <= S_NEXT_STRING_1;
				else State_main <= S_SEND;
				
			end
			
		end
		
		S_NEXT_STRING_1:
		begin
			if(!Redy_Symbol)
			begin
				Write_Symbol <= 8'd19;
				Valid_Symbol <= 'b1;
				DataSymbol <=  'b0;
				State_main <= S_NEXT_STRING_2;
			end
		end
		
		S_NEXT_STRING_2:
		begin
			if(Redy_Symbol)
			begin
				
				Valid_Symbol <= 'b0;
				State_main <= S_END;
				
			end
			
		end
			
		
		S_END:
		begin
			flag <= 'b0;
			Read_ready <= 'b1;
			if (!Read_valid)
			begin
				Read_ready <= 'b0;
				State_main <= S_BEGIN;
			end
		end
		endcase
	end
		
end

endmodule

module Config_Write
(
	input wire clk,
	input wire rst,
		
	input wire Config_valid,
	output reg Config_ready,
	
	input wire sccb_ready,
	input wire Redy_Symbol,
	input wire [7:0] Cam_ID,
	
	input wire [7:0] sccb_DATA_OUT,
	output reg [7:0] sccb_DATA_IN,
	output reg [7:0] sccb_REG,
	output reg [7:0] Write_Symbol,
	
	output reg sccb_valid,
	output reg Valid_Symbol,
	output reg [3:0] sccb_op_type,
	output reg DataSymbol
	
);

reg [15:0] Addr;
reg [15:0] Data;
reg [15:0] Data_OV7670;
reg [15:0] Data_OV2640;

M_OV7670_Config_ROM OV7670_Config_ROM
(
	.Addr(Addr),
	.Data(Data_OV7670)
);

M_OV2640_Config_ROM OV2640_Config_ROM
(	
	.Addr(Addr),
	.Data(Data_OV2640)
);



assign Data =  (Cam_ID == 'h76) ? Data_OV7670 :
					(Cam_ID == 'h26) ? Data_OV2640 : 16'hffff;


localparam  OP_W3 = 4'd0,
				OP_W2 = 4'd1,
				OP_R2 = 4'd2;
				
reg [3:0] State_main = 4'd0;

localparam 	S_BEGIN = 4'd0,
				S_SEND = 4'd2,
				S_GET = 4'd3,
				S_WAIT = 4'd4,
				S_PRINT_ON_SCREEN_REG_1 = 4'd5,
				S_PRINT_ON_SCREEN_REG_2 = 4'd6,
				S_PRINT_ON_SCREEN_X_1 = 4'd7,
				S_PRINT_ON_SCREEN_X_2 = 4'd8,
				S_PRINT_ON_SCREEN_DATA_1 = 4'd9,
				S_PRINT_ON_SCREEN_DATA_2 = 4'd10,
				S_PRINT_ON_SCREEN_SPACE_1 = 4'd11,
				S_PRINT_ON_SCREEN_SPACE_2 = 4'd12,
				S_END = 4'd13,
				S_PRINT_X_1 = 4'd14,
				S_PRINT_X_2 = 4'd15;
				
				
				

always @(posedge clk) 
begin
	if(rst)
	begin
		State_main <= S_BEGIN;
		
	end
	else
	begin
		case (State_main)
		S_BEGIN:
		begin
			Config_ready <= 'b0;
			Valid_Symbol <= 'b0;
			if (Config_valid)
			begin
				Addr <= 'd0;
				State_main <= S_SEND;
			end
		end
		S_SEND:
		begin 
			if (Data == 16'hffff) State_main <= S_END;
			if(!sccb_ready)
			begin
				
				sccb_op_type  <= OP_W3;
				sccb_REG <= Data[15:8];
				sccb_DATA_IN <= Data[7:0];
				Addr <= Addr + 'd1;
				sccb_valid <= 1'b1;
				State_main <= S_WAIT;
			end
		end
		S_GET:
		begin 
			
			if(!sccb_ready)
			begin
				sccb_op_type  <= OP_R2;
				sccb_valid <= 1'b1;
				State_main <= S_WAIT;
			end
		end
		S_WAIT:
		begin
			
			if (sccb_ready)
			begin
				
				sccb_valid <= 1'b0;
				if (sccb_op_type  == OP_W3) State_main <=  S_GET;
				else State_main <=  S_PRINT_ON_SCREEN_REG_1;
			end
		end
		
		S_PRINT_ON_SCREEN_REG_1:
		begin
			if(!Redy_Symbol)
			begin
				Write_Symbol <= sccb_REG;
				Valid_Symbol <= 'b1;
				DataSymbol <=  'b1;
				State_main <=  S_PRINT_ON_SCREEN_REG_2;
			end
			
		end
		
		
		S_PRINT_ON_SCREEN_REG_2:
		begin
			if(Redy_Symbol)
			begin
				Valid_Symbol <= 'b0;
				State_main <= S_PRINT_ON_SCREEN_X_1;				
			end
		end
		
		S_PRINT_ON_SCREEN_X_1:
		begin
			if(!Redy_Symbol)
			begin
				Write_Symbol <= 'd18;
				Valid_Symbol <= 'b1;
				DataSymbol <=  'b0;
				State_main <=  S_PRINT_ON_SCREEN_X_2;
			end
		end
		
		S_PRINT_ON_SCREEN_X_2:
		begin
			if(Redy_Symbol)
			begin
				Valid_Symbol <= 'b0;
				State_main <= S_PRINT_ON_SCREEN_DATA_1;				
			end
		end
		 
		S_PRINT_ON_SCREEN_DATA_1:
		begin
			if(!Redy_Symbol)
			begin
				Write_Symbol <= sccb_DATA_OUT;
				Valid_Symbol <= 'b1;
				DataSymbol <=  'b1;
				State_main <= S_PRINT_ON_SCREEN_DATA_2;
			end
		end
		
		
		
		S_PRINT_ON_SCREEN_DATA_2:
		begin
			if(Redy_Symbol)
			begin
				Valid_Symbol <= 'b0;
				State_main <= S_PRINT_ON_SCREEN_SPACE_1;
			end
		end
		
		S_PRINT_ON_SCREEN_SPACE_1:
		begin
			if(!Redy_Symbol)
			begin
				Write_Symbol <= 'd16;
				Valid_Symbol <= 'b1;
				DataSymbol <=  'b0;
				State_main <= S_PRINT_ON_SCREEN_SPACE_2;
			end
		end
		
		
		
		S_PRINT_ON_SCREEN_SPACE_2:
		begin
			if(Redy_Symbol)
			begin
				Valid_Symbol <= 'b0;
				
				
				
				State_main <= S_SEND;
			end
		end
			
		
		S_END:
		begin
			if (!Config_valid)
			begin
				State_main <= S_BEGIN;
			end
			else Config_ready <= 'b1;
			
		end
		endcase
	end
		
end

endmodule

