module TextController
#(
	parameter ENDFRAME = 'd1055,
	parameter STRINGLENGTH = 'd800,
	parameter FONT_COLOR = 12'b000011111111,
	parameter BACKGROUND_COLOR = 12'b000000000000
)
(
	input wire clk,
	input wire rst,
	
	input wire DataSymbol,
	input wire Valid_Symbol,
	input wire [7:0] Write_Symbol,
	output reg Redy_Symbol,
	
	input wire Hblank,
	
	input wire [10:0] V_count,
	
	output reg StringRAM_we,
	output reg [15:0]StringRAM_write_addr,
	output reg [15:0] StringRAM_data,
	output reg flag
	
);





reg [15:0]Pix_H_Counter = 0;
reg [15:0]Pix_V_Counter = 0;

wire [15:0]Data_H_Counter;
wire [15:0]Data_V_Counter;


assign Data_H_Counter = Pix_H_Counter / 'd8;
assign Data_V_Counter = Pix_V_Counter / 'd10;




reg [7:0] FontAddr;
reg [7:0] FontOffset;

wire [7:0] Font_data;
	
FONT_ROM FontRom
(
	.FontAddr(FontAddr),
	.FontOffset(FontOffset),
	.Font_data(Font_data)
);

reg Screen_we = 'b0;
reg [15:0] Screen_addr_write;
reg [15:0] Screen_addr_read;
reg [7:0] Screen_data_write;
wire [7:0] Screen_data_read;
reg [8:0] Data_Count;

SCREEN_RAM ScreenRam
(
	.clk(clk),
	.rst(rst),
	
	.we(Screen_we),
	.write_addr(Screen_addr_write),
	.read_addr(Screen_addr_read),
	.data(Screen_data_write),
	.q(Screen_data_read)
	
);

reg [3:0] m_State;
parameter   S_BEGIN = 4'd0,
				S_GET_FONT_1 = 4'd1,
				S_GET_FONT_2 = 4'd2,
				S_GET_FONT_3 = 4'd3,
				S_FILLSTRING = 4'd4,
				S_PIX_COUNT_INCREAS = 4'd5,
				S_READY = 4'd6;
				
				
always @(posedge clk)
begin
	if (rst)
	begin
		Pix_V_Counter <= 0; //danger
		m_State <= S_BEGIN;
		
	end
	
	else 
	begin
	
	case(m_State)
		S_BEGIN:
		begin
			FontAddr <= 'd0;
			StringRAM_we <= 1'b0;
			Pix_H_Counter <= 'd0;
			m_State <= S_GET_FONT_1;
			
		end
		
		
		S_GET_FONT_1:
		begin
			Screen_addr_read <= Data_H_Counter + (Data_V_Counter * 'd100);
			m_State <= S_GET_FONT_3;
		end
		
		
		
		S_GET_FONT_3:
		begin
			FontAddr <= Screen_data_read;
			
			FontOffset <= Pix_V_Counter % 'd10;
			Data_Count <= 'd0;
			m_State <= S_FILLSTRING;
		end
		
		S_FILLSTRING:
		begin
			StringRAM_we <= 1'b1;
			
			StringRAM_data <= (Font_data[Data_Count]) ? FONT_COLOR : BACKGROUND_COLOR;
			StringRAM_write_addr <= Pix_H_Counter + Data_Count;

			
			if (Data_Count != 'd7) Data_Count <= Data_Count + 'b1;
			else m_State <= S_PIX_COUNT_INCREAS;
			
			
				
		end
		S_PIX_COUNT_INCREAS:
		begin
			StringRAM_we <= 1'b0;
			Pix_H_Counter <= Pix_H_Counter + 'd8;
			
			if (Pix_H_Counter == STRINGLENGTH) m_State <= S_READY;
			else m_State <= S_GET_FONT_1;
			
		end
		
		S_READY:
		begin
		
			if (Hblank)
			begin
				if (V_count < 'd599)
				begin 
					Pix_V_Counter <= V_count + 1'b1;
					m_State <= S_BEGIN;
				end

				else if (V_count == (ENDFRAME - 1'b1))
				begin
					Pix_V_Counter <= 0;
					m_State <= S_BEGIN;
				end
			end
		
		end
	endcase
		
	end
	
end

reg [15:0] Cursor_X;
reg [15:0] Cursor_Y;

reg [3:0]m_Enter_State = 'd0;
parameter	S_CUR_BEGIN = 4'd0,
				S_SET_CURSOR_ORIG = 4'd1,
				S_WAIT_SYMBOL = 4'd2,
				S_ENTER_NEXT_SYMBOL = 4'd3,
				S_MOVE_CURSOR = 4'd4, 
				S_SYMBOL_CONFIRM = 4'd5,
				S_NEXT_LINE = 4'd6,
				S_ERASE_CURSOR = 4'd7;
				

always @(posedge clk)
begin
if (rst)
begin
	m_Enter_State <= S_CUR_BEGIN;
	
end
else
begin
	case (m_Enter_State) 
	S_CUR_BEGIN:
	begin 
		Cursor_X <= 'd0;
		Cursor_Y <= 'd0;
		Redy_Symbol <= 'b0;
		Screen_we <= 1'b0;
		m_Enter_State <= S_SET_CURSOR_ORIG;
	end
	
	S_SET_CURSOR_ORIG:
	begin
		Screen_we <= 1'b1;
		Screen_addr_write <= 'd0;
		Screen_data_write <= 8'd17;
		m_Enter_State <= S_WAIT_SYMBOL;
	end
	
		
	S_WAIT_SYMBOL:
	begin
		Redy_Symbol <= 'b0;
		if (Valid_Symbol)
		begin
			
			if (DataSymbol)
			begin
				
				Screen_we <= 1'b1;
				Screen_addr_write <= Cursor_X  + (Cursor_Y * 'd100);
				Screen_data_write[3:0] <= Write_Symbol[7:4];
				Screen_data_write[7:4] <= 'd0;
				Cursor_X <= Cursor_X + 'd1;
				m_Enter_State <= S_ENTER_NEXT_SYMBOL;
			end
			else
			begin
				
				if (Write_Symbol == 8'd19) m_Enter_State <= S_ERASE_CURSOR;
				else
				begin
					Screen_we <= 1'b1;
					Screen_addr_write <= Cursor_X  + (Cursor_Y * 'd100);
					Screen_data_write <= Write_Symbol;
					Cursor_X <= Cursor_X + 'd1;
					m_Enter_State <= S_MOVE_CURSOR;
				end
			end
			
			
		end
		else 
		begin
			Screen_we <= 1'b0;
			
		end
	end
	
	S_ENTER_NEXT_SYMBOL:
	begin
		Screen_we <= 1'b1;
		Screen_addr_write <= Cursor_X  + (Cursor_Y * 'd100);
		Screen_data_write[3:0] <= Write_Symbol[3:0];
		Screen_data_write[7:4] <= 'd0;
		Cursor_X <= Cursor_X + 'd1;
		m_Enter_State <= S_MOVE_CURSOR;
	end
	
	S_ERASE_CURSOR:
	begin
		Screen_we <= 1'b1;
		Screen_addr_write <= Cursor_X + (Cursor_Y * 'd100);
		Screen_data_write <= 8'd16;
		m_Enter_State <= S_NEXT_LINE;
	end
	
	S_NEXT_LINE:
	begin
		
		Screen_we <= 1'b0;
		Cursor_Y <= Cursor_Y + 'd1;
		Cursor_X <= 'd0;
		m_Enter_State <= S_MOVE_CURSOR;
	end
	
	S_MOVE_CURSOR:
	begin
		Screen_we <= 1'b1;
		Screen_addr_write <= Cursor_X + (Cursor_Y * 'd100);
		Screen_data_write <= 8'd17;
		m_Enter_State <= S_SYMBOL_CONFIRM;
	end
	
	S_SYMBOL_CONFIRM:
	begin
		Redy_Symbol <= 1'b1;
		Screen_we <= 1'b0;
		if(!Valid_Symbol)
		begin
			m_Enter_State <= S_WAIT_SYMBOL;

		end
		
	end
	endcase 
end
end

endmodule



module SCREEN_RAM
#(
	parameter ADDR_WIDTH = 'd14,
	parameter DATA_WIDTH = 'd8, 
	parameter CELL_NUM = 'd6000
	
)
( 
	input wire clk,
	input wire rst,
	
	input wire we,
	input wire [DATA_WIDTH-1:0] data,
	input wire [ADDR_WIDTH-1:0] read_addr,
	input wire [ADDR_WIDTH-1:0] write_addr,
	
	output reg [DATA_WIDTH-1:0] q
	
);

reg [DATA_WIDTH - 1:0] ScreenData [CELL_NUM - 1:0];  //Text data


initial 
begin
ScreenData = '{CELL_NUM{8'd16}}; 
end

reg [ADDR_WIDTH-1:0]Cell_count = 'd0;

assign q = ScreenData[read_addr];

always @ (posedge clk)
begin
	if (rst)
	begin 
		if (Cell_count != CELL_NUM)
		begin
			ScreenData[Cell_count] <= 8'd16;
			
			Cell_count <= Cell_count + 'd1;
		end 
	end
	else
	begin
		
		Cell_count <= 'd0;
		if (we) ScreenData[write_addr] <= data;
		
	end
end


	
endmodule

module FONT_ROM 
#(
	parameter ADDR_WIDTH = 'd8,
	parameter DATA_WIDTH = 'd8
	
)
(   
	input wire [ADDR_WIDTH - 1:0] FontAddr,
	input wire [ADDR_WIDTH - 1:0] FontOffset,
	output wire [DATA_WIDTH - 1:0] Font_data

);
 
assign Font_data = Font_mem[(FontAddr * 'd10) + FontOffset];



 
reg [DATA_WIDTH-1:0] Font_mem[189:0];

initial 
begin
	Font_mem[0] = 8'b00000000;
	Font_mem[1] = 8'b00111100;
	Font_mem[2] = 8'b01100110;
	Font_mem[3] = 8'b01000010;
	Font_mem[4] = 8'b01000010;
	Font_mem[5] = 8'b01000010;
	Font_mem[6] = 8'b01000010;
	Font_mem[7] = 8'b01100110;
	Font_mem[8] = 8'b00111100;
	Font_mem[9] = 8'b00000000;

	Font_mem[10] = 8'b00000000;
	Font_mem[11] = 8'b00110000;
	Font_mem[12] = 8'b00111000;
	Font_mem[13] = 8'b00101100;
	Font_mem[14] = 8'b00100000;
	Font_mem[15] = 8'b00100000;
	Font_mem[16] = 8'b00100000;
	Font_mem[17] = 8'b00100000;
	Font_mem[18] = 8'b00100000;
	Font_mem[19] = 8'b00000000;

	Font_mem[20] = 8'b00000000;
	Font_mem[21] = 8'b00111100;
	Font_mem[22] = 8'b01100110;
	Font_mem[23] = 8'b01000010;
	Font_mem[24] = 8'b01100000;
	Font_mem[25] = 8'b00110000;
	Font_mem[26] = 8'b00011000;
	Font_mem[27] = 8'b00001100;
	Font_mem[28] = 8'b01111110;
	Font_mem[29] = 8'b00000000;

	Font_mem[30] = 8'b00000000;
	Font_mem[31] = 8'b00011100;
	Font_mem[32] = 8'b00100010;
	Font_mem[33] = 8'b01100000;
	Font_mem[34] = 8'b00110000;
	Font_mem[35] = 8'b00011000;
	Font_mem[36] = 8'b00110000;
	Font_mem[37] = 8'b01100010;
	Font_mem[38] = 8'b00111110;
	Font_mem[39] = 8'b00000000;

	Font_mem[40] = 8'b00000000;
	Font_mem[41] = 8'b00110000;
	Font_mem[42] = 8'b00111000;
	Font_mem[43] = 8'b00101100;
	Font_mem[44] = 8'b00100100;
	Font_mem[45] = 8'b00100110;
	Font_mem[46] = 8'b00100010;
	Font_mem[47] = 8'b01111110;
	Font_mem[48] = 8'b00100000;
	Font_mem[49] = 8'b00000000;

	Font_mem[50] = 8'b00000000;
	Font_mem[51] = 8'b01111100;
	Font_mem[52] = 8'b00000100;
	Font_mem[53] = 8'b00000100;
	Font_mem[54] = 8'b00111100;
	Font_mem[55] = 8'b01100000;
	Font_mem[56] = 8'b01000000;
	Font_mem[57] = 8'b01000100;
	Font_mem[58] = 8'b01111100;
	Font_mem[59] = 8'b00000000;

	Font_mem[60] = 8'b00000000;
	Font_mem[61] = 8'b00111100;
	Font_mem[62] = 8'b01100110;
	Font_mem[63] = 8'b00000010;
	Font_mem[64] = 8'b00111110;
	Font_mem[65] = 8'b01100110;
	Font_mem[66] = 8'b01000010;
	Font_mem[67] = 8'b01000010;
	Font_mem[68] = 8'b01111110;
	Font_mem[69] = 8'b00000000;

	Font_mem[70] = 8'b00000000;
	Font_mem[71] = 8'b01111110;
	Font_mem[72] = 8'b01100000;
	Font_mem[73] = 8'b00100000;
	Font_mem[74] = 8'b00110000;
	Font_mem[75] = 8'b00011000;
	Font_mem[76] = 8'b00001000;
	Font_mem[77] = 8'b00001100;
	Font_mem[78] = 8'b00001100;
	Font_mem[79] = 8'b00000000;

	Font_mem[80] = 8'b00000000;
	Font_mem[81] = 8'b00111100;
	Font_mem[82] = 8'b01100110;
	Font_mem[83] = 8'b01000010;
	Font_mem[84] = 8'b01100110;
	Font_mem[85] = 8'b00111100;
	Font_mem[86] = 8'b01100110;
	Font_mem[87] = 8'b01000010;
	Font_mem[88] = 8'b01111110;
	Font_mem[89] = 8'b00000000;

	Font_mem[90] = 8'b00000000;
	Font_mem[91] = 8'b00111100;
	Font_mem[92] = 8'b01100110;
	Font_mem[93] = 8'b01000010;
	Font_mem[94] = 8'b01100010;
	Font_mem[95] = 8'b01011100;
	Font_mem[96] = 8'b01000000;
	Font_mem[97] = 8'b01000010;
	Font_mem[98] = 8'b01111110;
	Font_mem[99] = 8'b00000000;

	Font_mem[100] = 8'b00000000;
	Font_mem[101] = 8'b00011000;
	Font_mem[102] = 8'b00111100;
	Font_mem[103] = 8'b00100100;
	Font_mem[104] = 8'b00100100;
	Font_mem[105] = 8'b01100110;
	Font_mem[106] = 8'b01111110;
	Font_mem[107] = 8'b01000010;
	Font_mem[108] = 8'b01000010;
	Font_mem[109] = 8'b00000000;

	Font_mem[110] = 8'b00000000;
	Font_mem[111] = 8'b00011110;
	Font_mem[112] = 8'b01100010;
	Font_mem[113] = 8'b01000010;
	Font_mem[114] = 8'b00100010;
	Font_mem[115] = 8'b00111110;
	Font_mem[116] = 8'b01000010;
	Font_mem[117] = 8'b01100010;
	Font_mem[118] = 8'b00111110;
	Font_mem[119] = 8'b00000000;

	Font_mem[120] = 8'b00000000;
	Font_mem[121] = 8'b00111100;
	Font_mem[122] = 8'b01100110;
	Font_mem[123] = 8'b01000010;
	Font_mem[124] = 8'b00000010;
	Font_mem[125] = 8'b00000010;
	Font_mem[126] = 8'b01000010;
	Font_mem[127] = 8'b01100110;
	Font_mem[128] = 8'b00111100;
	Font_mem[129] = 8'b00000000;

	Font_mem[130] = 8'b00000000;
	Font_mem[131] = 8'b00111110;
	Font_mem[132] = 8'b01100010;
	Font_mem[133] = 8'b01000010;
	Font_mem[134] = 8'b01000010;
	Font_mem[135] = 8'b01000010;
	Font_mem[136] = 8'b01000010;
	Font_mem[137] = 8'b01100010;
	Font_mem[138] = 8'b00111110;
	Font_mem[139] = 8'b00000000;

	Font_mem[140] = 8'b00000000;
	Font_mem[141] = 8'b01111110;
	Font_mem[142] = 8'b00000010;
	Font_mem[143] = 8'b00000010;
	Font_mem[144] = 8'b00000010;
	Font_mem[145] = 8'b00111110;
	Font_mem[146] = 8'b00000010;
	Font_mem[147] = 8'b00000010;
	Font_mem[148] = 8'b01111110;
	Font_mem[149] = 8'b00000000;

	Font_mem[150] = 8'b00000000;
	Font_mem[151] = 8'b01111110;
	Font_mem[152] = 8'b00000010;
	Font_mem[153] = 8'b00000010;
	Font_mem[154] = 8'b00000010;
	Font_mem[155] = 8'b00011110;
	Font_mem[156] = 8'b00000010;
	Font_mem[157] = 8'b00000010;
	Font_mem[158] = 8'b00000010;
	Font_mem[159] = 8'b00000000;

	Font_mem[160] = 8'b00000000;
	Font_mem[161] = 8'b00000000;
	Font_mem[162] = 8'b00000000;
	Font_mem[163] = 8'b00000000;
	Font_mem[164] = 8'b00000000;
	Font_mem[165] = 8'b00000000;
	Font_mem[166] = 8'b00000000;
	Font_mem[167] = 8'b00000000;
	Font_mem[168] = 8'b00000000;
	Font_mem[169] = 8'b00000000;

	Font_mem[170] = 8'b11111111;
	Font_mem[171] = 8'b11111111;
	Font_mem[172] = 8'b11111111;
	Font_mem[173] = 8'b11111111;
	Font_mem[174] = 8'b11111111;
	Font_mem[175] = 8'b11111111;
	Font_mem[176] = 8'b11111111;
	Font_mem[177] = 8'b11111111;
	Font_mem[178] = 8'b11111111;
	Font_mem[179] = 8'b11111111;

	Font_mem[180] = 8'b00000000;
	Font_mem[181] = 8'b01000010;
	Font_mem[182] = 8'b01100110;
	Font_mem[183] = 8'b00111100;
	Font_mem[184] = 8'b00011000;
	Font_mem[185] = 8'b00011000;
	Font_mem[186] = 8'b00111100;
	Font_mem[187] = 8'b01100110;
	Font_mem[188] = 8'b01000010;
	Font_mem[189] = 8'b00000000;

end
  

endmodule 
