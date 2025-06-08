module i2c_controller_Test;

reg clk = 1'b0; 
reg rst = 1'b0;

always #1 clk = ~clk;
	
reg m_valid;
reg m_we;
	
	
reg [6:0]  ADDR;
reg [7:0]  REG;
reg [7:0]  DATA_IN;
reg [4:0] DataNum = 0;
	
wire [7:0] DATA_OUT;
wire m_ready;
wire NACK;
	
wire sda_io;
wire scl_io;

pullup(sda_io);
pullup(scl_io);
/*
initial 
begin
#10 rst = 1;

#10 rst = 0;
end*/
reg [3:0] cnt_byte = 0;


reg [3:0] State_main = S_SEND;
localparam 	S_SEND = 4'd0,
				S_WAIT = 4'd1,
				S_GET = 4'd2,
				S_END = 4'd3, 
				S_GET_2 = 4'd4;

always @(posedge clk) 
begin
	if(rst)
	begin
		State_main <= S_SEND;
	end
	else
	begin
		case (State_main)
		S_SEND:
		begin
			ADDR <= 7'b0100001;
			REG <= 8'h0A;
			DATA_IN <= 8'b00111001;
			m_valid <= 1'b1;
			m_we <= 1'b0;
			State_main <= S_WAIT;
			DataNum <= 0;
		end
		S_WAIT:
		begin
			
			if (m_ready)
			begin
				m_valid <= 1'b0;
				State_main <= S_END;
			end
			
			
		end
		
		
		endcase
	end
		
end

initial  #850 $finish;


//создаем файл VCD для последующего анализа сигналов
initial
begin
  $dumpfile("out.vcd");
  $dumpvars(0,i2c_controller_inst);
  $dumpvars(0,i2c_slave_inst);
end

//наблюдаем на некоторыми сигналами системы
initial $monitor($stime,,, clk,, rst,,, m_valid,, m_ready,, NACK,,, sda_io,, scl_io);



i2c_controller  i2c_controller_inst
(

	.clk(clk), 
	.rst(rst), 
	
	.m_valid(m_valid),
	.m_we(m_we),
	.ADDR(ADDR),
	.REG(REG),
	.DATA_IN(DATA_IN),
	.DataNum(DataNum),
	
	.DATA_OUT(DATA_OUT),
	.m_ready(m_ready),
		
	.sda_io(sda_io),
	.scl_io(scl_io)
);


i2c_slave i2c_slave_inst
(
	.clk(clk), 
	.rst(rst),  
	.sda_io(sda_io), 
	.scl_io(scl_io)
);
	
endmodule
