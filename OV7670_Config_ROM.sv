module M_OV7670_Config_ROM 
#(
	parameter ADDR_WIDTH = 'd7,
	parameter DATA_WIDTH = 'd16
	
)
(   
	input wire [ADDR_WIDTH - 1:0] Addr,
	output wire [DATA_WIDTH - 1:0] Data

);
 
assign Data = mem[Addr];

reg [DATA_WIDTH-1:0] mem[80:0];

initial
begin

	mem[0] = 16'h12_04; // COM7,   00-set yuv422, 01-RAW RGB565 04 - set RGB color output
	mem[1] = 16'h11_80; // CLKRC     internal PLL matches input clock
	mem[2] = 16'h0C_00; // COM3,     default settings
	mem[3] = 16'h3E_00; // COM14,    no scaling, normal pclock
	mem[4] = 16'h04_00; // COM1,     disable CCIR656*
	mem[5] = 16'h40_d0; //COM15,     RGB555, full output range, we need set fourth bit if we want enable RGB444
	mem[6] = 16'h8C_02; // Not RGB,Enable RGB444 02
	
	
	mem[7] = 16'h14_18; //COM9       MAX AGC value x4

	// Color Saturation 0
	mem[8] = 16'h4F_80; //MTX1       
	mem[9] = 16'h50_80; //MTX2
	mem[10] = 16'h51_00; //MTX3
	mem[11] = 16'h52_22; //MTX4
	mem[12] = 16'h53_71; //MTX5
	mem[13] = 16'h54_99; //MTX6
	mem[14] = 16'h58_9E; //MTXS

	mem[15] = 16'h3D_C0; //COM13      sets gamma enable, does not preserve reserved bits, may be wrong?
	mem[16] = 16'h17_14; //HSTART     start high 8 bits
	mem[17] = 16'h18_02; //HSTOP      stop high 8 bits //these kill the odd colored line
	mem[18] = 16'h32_80; //HREF       edge offset
	mem[19] = 16'h19_03; //VSTART     start high 8 bits
	mem[20] = 16'h1A_7B; //VSTOP      stop high 8 bits
	mem[21] = 16'h03_0A; //VREF       vsync edge offset
	mem[22] = 16'h0F_41; //COM6       reset timings
	mem[23] = 16'h1E_00; //MVFP       disable mirror / flip //might have magic value of 03
	mem[24] = 16'h33_0B; //CHLF       //magic value from the internet
	mem[25] = 16'h3C_78; //COM12      no HREF when VSYNC low
	mem[26] = 16'h69_00; //GFIX       fix gain control
	mem[27] = 16'h74_00; //REG74      Digital gain control
	mem[28] = 16'hB0_84; //RSVD       magic value from the internet *required* for good color
	mem[29] = 16'hB1_0c; //ABLC1
	mem[30] = 16'hB2_0e; //RSVD       more magic internet values
	mem[31] = 16'hB3_80; //THL_ST

	//begin mystery scaling numbers
	mem[32] = 16'h70_3a;
	mem[33] = 16'h71_35;
	mem[34] = 16'h72_11;
	mem[35] = 16'h73_f0;
	mem[36] = 16'ha2_02;

	//gamma curve values
	mem[37] = 16'h7a_20;
	mem[38] = 16'h7b_10;
	mem[39] = 16'h7c_1e;
	mem[40] = 16'h7d_35;
	mem[41] = 16'h7e_5a;
	mem[42] = 16'h7f_69;
	mem[43] = 16'h80_76;
	mem[44] = 16'h81_80;
	mem[45] = 16'h82_88;
	mem[46] = 16'h83_8f;
	mem[47] = 16'h84_96;
	mem[48] = 16'h85_a3;
	mem[49] = 16'h86_af;
	mem[50] = 16'h87_c4;
	mem[51] = 16'h88_d7;
	mem[52] = 16'h89_e8;

	 //AGC and AEC
	mem[53] = 16'h13_e7;//e0; //COM8, enable AGC / AEC
	mem[54] = 16'h00_00; //set gain reg to 0 for AGC
	mem[55] = 16'h10_00; //set ARCJ reg to 0
	mem[56] = 16'h0d_40; //magic reserved bit for COM4
	mem[57] = 16'h14_18; //COM9, 4x gain + magic bit
	mem[58] = 16'ha5_05; // BD50MAX
	mem[59] = 16'hab_07; //DB60MAX
	mem[60] = 16'h24_95; //AGC upper limit
	mem[61] = 16'h25_33; //AGC lower limit
	mem[62] = 16'h26_e3; //AGC/AEC fast mode op region
	mem[63] = 16'h9f_78; //HAECC1
	mem[64] = 16'ha0_68; //HAECC2
	mem[65] = 16'ha1_03; //magic
	mem[66] = 16'ha6_d8; //HAECC3
	mem[67] = 16'ha7_d8; //HAECC4
	mem[68] = 16'ha8_f0; //HAECC5
	mem[69] = 16'ha9_90; //HAECC6
	mem[70] = 16'haa_94; //HAECC7
	mem[71] = 16'h13_e5; //COM8, enable AGC / AEC
	
	mem[72] = 16'h01_d0; //Blue channel gain
	mem[73] = 16'h02_d0; //Red channel gain
	mem[74] = 16'h55_00; //Brightness 
	mem[75] = 16'h56_40; //Contrast +2
	//Not special effects
	mem[76] = 16'h3a_04; //TSLB       set correct output data sequence (magic)
	mem[77] = 16'h67_c0;
	mem[78] = 16'h68_80;
	
	mem[79] = 16'h6f_9f;  // Simple AWB
	
	mem[80] = 16'hff_ff; //END


end
  

endmodule 