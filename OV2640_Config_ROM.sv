module M_OV2640_Config_ROM 
#(
	parameter ADDR_WIDTH = 'd8,
	parameter DATA_WIDTH = 'd16
	
)
(   
	input wire [ADDR_WIDTH - 1:0] Addr,
	output wire [DATA_WIDTH - 1:0] Data

);
 
assign Data = mem[Addr];

reg [DATA_WIDTH-1:0] mem[180:0];
initial
begin
	mem[0] = 16'hff_00; //Set memory bank DSP
	mem[1] = 16'h2c_ff;
	mem[2] = 16'h2e_df;
	
	mem[3] = 16'hff_01; //Set memory bank sensor
	mem[4] = 16'h3c_32;
	mem[5] = 16'h11_00;
	mem[6] = 16'h09_02;
	mem[7] = 16'h04_28;
	mem[8] = 16'h13_e5;
	mem[9] = 16'h14_48;
	mem[10] = 16'h2c_0c;
	mem[11] = 16'h33_78;
	mem[12] = 16'h3a_33;
	mem[13] = 16'h3b_fb;
	mem[14] = 16'h3e_00;
	mem[15] = 16'h43_11;
	mem[16] = 16'h16_10;
	mem[17] = 16'h39_92;
	mem[18] = 16'h35_88; // UXGA=0x88 SVGA = 0xda
	mem[19] = 16'h22_0a; // UXGA=0x0a SVGA = 0x1a
	mem[20] = 16'h37_40; // UXGA=0x40 SVGA = 0xc3
	mem[21] = 16'h23_00;
	mem[22] = 16'h34_a0; // UXGA=0xa0 SVGA = 0xc0
	mem[23] = 16'h36_1a;
	mem[24] = 16'h06_02; // UXGA=0x02 SVGA = 0x88
	mem[25] = 16'h07_c0;
	mem[26] = 16'h0d_b7; // UXGA=0xb7 SVGA = 0x87
	mem[27] = 16'h0e_01; // UXGA=0x01 SVGA = 0x41
	mem[28] = 16'h4c_00;
	mem[29] = 16'h48_00;
	mem[30] = 16'h5b_00;
	mem[31] = 16'h42_83; // UXGA=0x83 SVGA = 0x03
	mem[32] = 16'h4a_81;
	mem[33] = 16'h21_99;
	mem[34] = 16'h24_40;
	mem[35] = 16'h25_38;
	mem[36] = 16'h26_82;
	mem[37] = 16'h5c_00;
	mem[38] = 16'h63_00;
	mem[39] = 16'h46_22;
	mem[40] = 16'h63_00;
	mem[41] = 16'h0c_3c;
	mem[42] = 16'h61_70;
	mem[43] = 16'h62_80;
	mem[44] = 16'h7c_05;
	mem[45] = 16'h20_80;
	mem[46] = 16'h28_30;
	mem[47] = 16'h6c_00;
	mem[48] = 16'h6d_80;
	mem[49] = 16'h6e_00;
	mem[50] = 16'h70_02;
	mem[51] = 16'h71_94;
	mem[52] = 16'h73_c1;
	mem[53] = 16'h12_01; // UXGA=0x01 SVGA = 0x40 (UXGA=0x03 SVGA = 0x42 with color bar)
	mem[54] = 16'h17_11; //UXGA=0x11, SVGA/CIF=0x11 
	mem[55] = 16'h18_75; // UXGA=0x75, SVGA/CIF=0x43 
	mem[56] = 16'h19_01; //UXGA=0x01, SVGA/CIF=0x00
	mem[57] = 16'h1a_97; //UXGA=0x97, SVGA/CIF=0x4b
	mem[58] = 16'h32_36; // UXGA=0x36, SVGA/CIF=0x09
	mem[59] = 16'h37_c0;
	mem[60] = 16'h4f_ca;
	mem[61] = 16'h50_a8;
	mem[62] = 16'h6d_00;
	mem[63] = 16'h3d_38; //UXGA=0x34, SVGA/CIF=0x38


	mem[64] = 16'hff_00; //Set memory bank DSP
	mem[65] = 16'he5_7f;
	mem[66] = 16'hf9_c0;
	mem[67] = 16'h41_24;
	mem[68] = 16'h0e_14;
	mem[69] = 16'h76_ff;
	mem[70] = 16'h33_a0;
	mem[71] = 16'h42_20;
	mem[72] = 16'h43_18;
	mem[73] = 16'h4c_00;
	mem[74] = 16'h87_d5;
	mem[75] = 16'h88_3f;
	mem[76] = 16'hd7_03;
	mem[77] = 16'hd9_10;
	mem[78] = 16'hd3_82;
	mem[79] = 16'hc8_08;
	mem[80] = 16'hc9_80;
	
	
	mem[81] = 16'h7c_00;
	mem[82] = 16'h7d_02;
	mem[83] = 16'h7c_03;
	mem[84] = 16'h7d_48;
	mem[85] = 16'h7d_48;
	mem[86] = 16'h7c_08;
	mem[87] = 16'h7d_20;
	mem[88] = 16'h7d_10;
	mem[89] = 16'h7d_0e;
	
	mem[90] = 16'h90_00;
	mem[91] = 16'h91_0e;
	mem[92] = 16'h91_1a;
	mem[93] = 16'h91_31;
	mem[94] = 16'h91_5a; 
	mem[95] = 16'h91_69;
	mem[96] = 16'h91_75;
	mem[97] = 16'h91_7e;
	mem[98] = 16'h91_88;
	mem[99] = 16'h91_8f;
	mem[100] = 16'h91_96;
	mem[101] = 16'h91_a3;
	mem[102] = 16'h91_af;
	mem[103] = 16'h91_c4;
	mem[104] = 16'h91_d7;
	mem[105] = 16'h91_e8;
	mem[106] = 16'h91_20;
	
	
	
	mem[107] = 16'h92_00;
	mem[108] = 16'h93_06;
	mem[109] = 16'h93_e3;
	mem[110] = 16'h93_05;
	mem[111] = 16'h93_05;
	mem[112] = 16'h93_00;
	mem[112] = 16'h93_04;
	mem[113] = 16'h93_00;
	mem[114] = 16'h93_00;
	mem[115] = 16'h93_00;
	mem[116] = 16'h93_00;
	mem[117] = 16'h93_00;
	mem[118] = 16'h93_00;
	mem[119] = 16'h93_00;
	
	mem[120] = 16'h96_00;
	mem[121] = 16'h97_08;
	mem[122] = 16'h97_19;
	mem[123] = 16'h97_02;
	mem[124] = 16'h97_0c;
	mem[125] = 16'h97_24;
	mem[126] = 16'h97_30;
	mem[127] = 16'h97_28;
	mem[128] = 16'h97_26;
	mem[129] = 16'h97_02;
	mem[130] = 16'h97_98;
	mem[131] = 16'h97_80;
	mem[132] = 16'h97_00;
	mem[133] = 16'h97_00;
	
	mem[134] = 16'hc3_ed;
	mem[135] = 16'ha4_00;
	mem[136] = 16'ha8_00;
	mem[137] = 16'hc5_11;
	mem[138] = 16'hc6_51;
	mem[139] = 16'hbf_80;
	mem[140] = 16'hc7_10;
	mem[141] = 16'hb6_66;
	mem[142] = 16'hb8_a5;
	mem[143] = 16'hb7_64;
	mem[144] = 16'hb9_7c;
	mem[145] = 16'hb3_af;
	mem[146] = 16'hb4_97;
	mem[147] = 16'hb5_ff;
	mem[148] = 16'hb0_c5;
	mem[149] = 16'hb1_94;
	mem[150] = 16'hb2_0f;
	mem[151] = 16'hc4_5c;
	mem[152] = 16'hc0_c8; //UXGA=0xc8, SVGA=0x64
	mem[153] = 16'hc1_96; //UXGA=0x96, SVGA=0x4b
	mem[154] = 16'h8c_00; 
	
	

	mem[155] = 16'h86_1d; //UXGA=0x1d, SVGA=0x3d
	mem[156] = 16'h50_00; 
	mem[157] = 16'h51_90; //UXGA=0x90, SVGA=0xc8
	mem[158] = 16'h52_2c; //UXGA=0x2c, SVGA=0x96
	mem[159] = 16'h53_00;
	mem[160] = 16'h54_00;
	mem[161] = 16'h55_88; //UXGA=0x88, SVGA=0x00
	mem[162] = 16'h5a_c8;
	mem[163] = 16'h5b_96;
	mem[164] = 16'h5c_00;
	mem[165] = 16'hd3_82;
	mem[166] = 16'hc3_ed;
	mem[167] = 16'h7f_00;
	mem[168] = 16'hda_08;
	mem[169] = 16'he5_1f;
	mem[170] = 16'he1_67;
	mem[171] = 16'he0_00;
	mem[172] = 16'hdd_7f;
	mem[173] = 16'h03_0f; //UXGA=0x0F, SVGA=0x0A, CIF=0x06
	mem[173] = 16'h03_0f;
	mem[174] = 16'hc2_02; //Enable 01-RAW 02-RGB 04-YUV


	mem[175] = 16'hff_ff; //END
	
	
	
	
end

endmodule