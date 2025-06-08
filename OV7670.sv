module OV7670
#(
	parameter ENDSTRING = 9'd263,
	parameter ENDFRAME = 11'd627,
	parameter ADDR_WIDTH = 14,
	parameter DATA_WIDTH = 6
	
)

(
	input wire clk_50,
	input reg RESET_N,
	input reg KEY_N,
	
	//Video interfase
	output wire Hsync,
	output wire Vsync,
	output wire LEDR,
	output wire [3:0]  Red,
	output wire [3:0]  Green,
	output wire [3:0]  Blue,
	
	//SCI Bas
	input wire [7:0] CAM_DATA, 
	input wire CAM_PCLK,
	input wire CAM_HREF,
	input wire CAM_VSYNC,
	output reg CAM_RESET,
	output wire CAM_XCLK,
	
	//I2C Bas
	inout wire CAM_sda_io,
   inout wire CAM_scl_io,

	
	//SDRAM
	output wire   [12:0]	DRAM_ADDR, //SDRAM address
   output wire   [1:0] 	DRAM_BA, //SDRAM bank address
   output wire        DRAM_CKE, //SDRAM clock enable
   output wire           DRAM_CLK,	//SDRAM clock
   output wire    		DRAM_CS_N,//SDRAM Chip Selects
   inout  tri   [15:0]	DRAM_DQ,  //SDRAM data bus
	output wire           DRAM_UDQM, //SDRAM data mask lines
   output wire           DRAM_LDQM, //SDRAM data mask lines
   output wire        DRAM_RAS_N, //SDRAM Row address Strobe
	output wire        DRAM_CAS_N,  //SDRAM Column address Strobe
   output wire        DRAM_WE_N, //SDRAM write enable
	
	output wire Analiz_scl,
	output wire Analiz_sda
	
);

assign Analiz_scl = CAM_scl_io;
assign Analiz_sda = CAM_sda_io;

wire flag;


assign LEDR = (flag) ? 1'b0 : 1'b1;

parameter 	M_TextMode = 'd0,
				M_PictureMode = 'd1;

reg DisplayMode = 0; //After start we see text

Debouncer Deb
(
	.clk(clk_50),
	.Button(!KEY_N),
	.Out(DisplayMode)
);





wire clk_400K;
wire clk_120;
wire clk_40;

PLL Pll
(
	.inclk0(clk_50),
	.c0(clk_40),
	.c1(clk_120),
	.c2(CAM_XCLK),
	.c3(clk_400K)
);




wire [11:0]  Pix_color;
wire Hblank;
wire Vblank;	
wire [10:0] H_count;
wire [10:0] V_count;


				
VideoAdapter_M VideoAdapter
(
	.clk(clk_40),
	.rst(!RESET_N),
	.Pix_color(Pix_color),
	
	.Hsync(Hsync),
	.Vsync(Vsync),
	
	.Red(Red),
	.Green(Green),
	.Blue(Blue),
	
	
	.Hblank(Hblank),
	.Vblank(Vblank),
	
	.H_count(H_count),
	.V_count(V_count)
	
);


wire Valid_Symbol;
reg [7:0] Write_Symbol = 'b0;
wire Redy_Symbol;

wire StringRAM_we = (DisplayMode) ? StringRAM_we_Picture : StringRAM_we_Text;
wire StringRAM_we_Text;
wire StringRAM_we_Picture;

wire [10:0]StringRAM_write_addr = (DisplayMode) ? StringRAM_write_addr_Picture : StringRAM_write_addr_Text;
wire [10:0]StringRAM_write_addr_Text;
wire [10:0]StringRAM_write_addr_Picture;

wire [11:0]StringRAM_data = (DisplayMode) ? StringRAM_data_Picture : StringRAM_data_Text;
wire [11:0]StringRAM_data_Text;
wire [11:0]StringRAM_data_Picture;

wire DataSymbol;


TextController TxtCont
(
	.clk(clk_120),
	.rst(!RESET_N),
	
	.DataSymbol(DataSymbol),
	.Valid_Symbol(Valid_Symbol),
	.Write_Symbol(Write_Symbol),
	.Redy_Symbol(Redy_Symbol),
	
	.Hblank(Hblank),
	.V_count(V_count),
	
	.StringRAM_we(StringRAM_we_Text),
	.StringRAM_write_addr(StringRAM_write_addr_Text),
	.StringRAM_data(StringRAM_data_Text),
	.flag(flag)
);

wire WriteFlag;
wire [15:0] m_in_data;

wire [23:0] m_addr = (WriteFlag) ? m_addr_Frame : m_addr_Pic;
wire [23:0] m_addr_Frame;
wire [23:0] m_addr_Pic;

wire m_valid = (WriteFlag) ? m_valid_Frame : m_valid_Pic;
wire m_valid_Frame;
wire m_valid_Pic;

wire Serial_access = (WriteFlag) ? Serial_access_Frame : Serial_access_Pic;
wire Serial_access_Frame;
wire Serial_access_Pic;

wire m_we;
wire m_ready;
wire [15:0] m_out_data;


Picture_Controller PictureController
(
	.clk(clk_120),
	.rst(!RESET_N),
	
	.DATA(m_out_data),
	.DATA_valid(m_valid_Pic),
	
	.Hblank(Hblank),
	.V_count(V_count),
	.DATA_addr(m_addr_Pic),
	.WriteFlag(WriteFlag),
	.DATA_in_ready(m_ready),
	.Serial_access(Serial_access_Pic),
	
	.StringRAM_we(StringRAM_we_Picture),
	.StringRAM_write_addr(StringRAM_write_addr_Picture),
	.StringRAM_data(StringRAM_data_Picture),
	
	
);

wire [7:0] Cam_ID;

wire CamString_we = (Cam_ID == 'h26) ? CamString_we_ov2640 : CamString_we_OV7670;
wire CamString_we_OV7670;
wire CamString_we_ov2640;

wire [10:0]  WriteAddr = (Cam_ID == 'h26) ?  WriteAddr_ov2640 : WriteAddr_OV7670;
wire [10:0] WriteAddr_OV7670;
wire [10:0] WriteAddr_ov2640;

wire [15:0] Pix_Data  = (Cam_ID == 'h26) ?  Pix_Data_ov2640 : Pix_Data_OV7670;
wire [15:0] Pix_Data_OV7670;
wire [15:0] Pix_Data_ov2640;

wire [10:0] V_Count = (Cam_ID == 'h26) ?   V_Count_ov2640 : V_Count_OV7670;
wire [10:0] V_Count_OV7670;
wire [10:0] V_Count_ov2640;

wire [10:0] ReadAddr;
wire [15:0] Out_Data;

MCameraFrame CameraFrame
(
	.clk_120(clk_120),
	.rst(rst),
	.Cam_ID (Cam_ID),
	
	.DATA(m_in_data),
	.DATA_addr(m_addr_Frame),
	.DATA_valid(m_valid_Frame),
	.DATA_ready(m_ready),
	.m_we(m_we),
	.Serial_access(Serial_access_Frame),
	
	.WriteFlag(WriteFlag),
	
	.V_Count(V_Count),
	.ReadAddr(ReadAddr),
	.Out_Data(Out_Data)
);



M_OV7670_BufferFiller OV7670_BufferFiller
(
	.PCLK(CAM_PCLK),
	.rst(rst),
	
	.VSYNC(CAM_VSYNC),
	.HREF(CAM_HREF),
	.CAM_DATA(CAM_DATA),
	
	.Pix_Data(Pix_Data_OV7670),
	.WriteAddr(WriteAddr_OV7670),
	.V_Count(V_Count_OV7670),
	.CamString_we(CamString_we_OV7670)
);

wire Blue_Buffer_we;
wire [10:0] Blue_Buffer_ReadAddr;
wire [10:0] Blue_Buffer_WriteAddr;
wire [3:0] Blue_Buffer_Read_Data;
wire [3:0] Blue_Buffer_Write_Data;

M_OV2640_BufferFiller OV2640_BufferFiller
(
	.PCLK(CAM_PCLK),
	.rst(rst),
	
	.VSYNC(CAM_VSYNC),
	.HREF(CAM_HREF),
	.CAM_DATA(CAM_DATA),
	
	.Pix_Data(Pix_Data_ov2640),
	.WriteAddr(WriteAddr_ov2640),
	.V_Count(V_Count_ov2640),
	.CamString_we(CamString_we_ov2640),
	
	.Blue_Buffer_we(Blue_Buffer_we),
	.Blue_Buffer_ReadAddr(Blue_Buffer_ReadAddr),
	.Blue_Buffer_WriteAddr(Blue_Buffer_WriteAddr),
	.Blue_Buffer_Read_Data(Blue_Buffer_Read_Data),
	.Blue_Buffer_Write_Data(Blue_Buffer_Write_Data)
);

M_STRING_BUF
#(
	.DATA_WIDTH('d4)
)
 Blue_Buffer
(
	.clk(CAM_PCLK),
	.we(Blue_Buffer_we),
	.read_addr(Blue_Buffer_ReadAddr),
	.write_addr(Blue_Buffer_WriteAddr),
	.data(Blue_Buffer_Write_Data),
	.q(Blue_Buffer_Read_Data)
);



sdram_controller  
SDRAMController
(
	.clk_ref(clk_120),
	.rst(!RESET_N),
	.in_data(m_in_data),
	.m_addr(m_addr),
	.m_we(m_we),
	.m_valid(m_valid),
	.Serial_access(Serial_access),
	
	.m_ready(m_ready),
	.out_data(m_out_data),
	
	.sd_cke(DRAM_CKE),
	.sd_clk(DRAM_CLK),
	.sd_dqml(DRAM_LDQM),
	.sd_dqmh(DRAM_UDQM),
	.sd_cas_n(DRAM_CAS_N),
	.sd_ras_n(DRAM_RAS_N),
	.sd_we_n(DRAM_WE_N),
	.sd_cs_n(DRAM_CS_N),
	.sd_addr({DRAM_BA, DRAM_ADDR}),
	.sd_data(DRAM_DQ)
	
);

M_STRING_BUF
#(
	.DATA_WIDTH('d16)
)
 CamStringBuf
(
	.clk(CAM_PCLK),
	.we(CamString_we),
	.read_addr(ReadAddr),
	.write_addr(WriteAddr),
	.data(Pix_Data),
	.q(Out_Data)
);

M_STRING_BUF StringRAM
(
	.clk(clk_120),
	.we(StringRAM_we),
	.read_addr(H_count),
	.write_addr(StringRAM_write_addr),
	.data(StringRAM_data),
	.q(Pix_color)
);

wire [3:0] sccb_op_type;
wire sccb_valid;
wire sccb_ready;
wire [6:0] sccb_addr;

wire [7:0] sccb_REG;
wire [7:0] sccb_DATA_IN;
wire [7:0] sccb_DATA_OUT;



OV7670_init OV7670init
(
	.clk(clk_120),
	.rst(!RESET_N),
	
	.sccb_ready(sccb_ready),
	.Redy_Symbol(Redy_Symbol),
	.sccb_DATA_OUT(sccb_DATA_OUT),
	.sccb_DATA_IN(sccb_DATA_IN),
	.sccb_REG(sccb_REG),
	.sccb_addr(sccb_addr),
	.Write_Symbol(Write_Symbol),
	
	.sccb_valid(sccb_valid),
	.CAM_RESET(CAM_RESET),
	.Valid_Symbol(Valid_Symbol),
	.sccb_op_type(sccb_op_type),
	.DataSymbol(DataSymbol),
	.Cam_ID(Cam_ID)
	
	
);



sccb_controller  SccbController
(

	.clk(clk_400K), 
	.rst(!RESET_N), 
	
	.m_valid(sccb_valid),
	.op_type(sccb_op_type),
	.ADDR(sccb_addr),
	.REG(sccb_REG),
	.DATA_IN(sccb_DATA_IN),
	
	.DATA_OUT(sccb_DATA_OUT),
	.m_ready(sccb_ready),
		
	.sda_io(CAM_sda_io),
	.scl_io(CAM_scl_io)
);



endmodule 



module M_STRING_BUF
#(
	parameter ADDR_WIDTH = 'd11,
	parameter DATA_WIDTH = 'd12,
	parameter STRINGLENGTH = 'd800
	
)
( 
	input wire clk,
	input wire we,
	
	input wire [ADDR_WIDTH - 1:0] read_addr,
	input wire [ADDR_WIDTH - 1:0] write_addr,
	input wire [DATA_WIDTH - 1:0] data,
	
	output wire [DATA_WIDTH - 1:0]  q
);


reg [DATA_WIDTH - 1:0]   string_buf [STRINGLENGTH - 1:0]; 

assign q = string_buf[read_addr];

always @ (posedge clk) if (we) string_buf[write_addr] <= data;


endmodule

