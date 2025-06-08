module i2c_slave
#(
	SEND_ACK = 1,
	SLOW = 0
)
(
	input wire clk, 
	input wire rst, 
	
	inout tri sda_io,
   inout tri scl_io
); 

wire State_clk;
wire Sda_clk;

reg [7:0] DATA_READ;
reg [7:0] DATA_WRITE = 8'b11111111;

reg scl_r = 1;
reg sda_r = 1;

assign scl_io = (scl_r) ? 1'bz : 1'b0;
assign sda_io = (sda_r) ? 1'bz : 1'b0;	


reg [3:0]m_State_slave = S_IDLE;

localparam 	S_IDLE = 4'd0,
				S_GET_DATA = 4'd1,
				S_SEND_ACK = 4'd2,
				S_SLOW = 4'd3,
				S_SEND_DATA = 4'd4,
				S_GET_ACK = 4'd5;
				
reg [3:0] cnt_bit_slave = 0;
reg [3:0] cnt_slow_slave = 0;

reg ReadData = 1'b0;
reg StartResive = 1'b0;
reg StopResive = 1'b0;
reg DataSend = 1'b0;

always @(negedge sda_io)
begin
	
	if(scl_io) StartResive <= 1'b1;
	
end

always @(posedge sda_io)
begin
	if(scl_io) StopResive <= 1'b1;
end

			
				
always @(posedge State_clk)
begin
	if (rst)
	begin
		m_State_slave <= S_IDLE;
		
	end 
	else
	begin
	
		case(m_State_slave)
		
		S_IDLE: 
		begin
			StopResive <= 1'b0;
			
			if(StartResive)
			begin
				m_State_slave <= S_GET_DATA;
				StartResive <= 1'b0;
			end
		end
		
		S_GET_DATA:
		begin
			if (StopResive) m_State_slave <= S_IDLE;
			if (StartResive)
			begin
				m_State_slave <= S_GET_DATA;
				cnt_bit_slave <= 1'b0;
				StartResive <= 1'b0;
				ReadData <= 1'b1;
			end
			if(!scl_io) 
			begin
				if(cnt_bit_slave == 4'd8) m_State_slave <= S_SEND_ACK;
			end
			
		end
		S_SEND_ACK:
		begin
			StartResive <= 1'b0;
			
		end
		
		S_SLOW: 
		if(cnt_slow_slave == SLOW)
		begin
			m_State_slave <= S_GET_DATA;
			scl_r <= 1'd1;
		end
		else
		begin
			cnt_slow_slave <= cnt_slow_slave + 1'd1;
			scl_r <= 1'd0;
		end
		
		S_SEND_DATA:
		begin
			if (StopResive) m_State_slave <= S_IDLE;
			if (StartResive)
			begin
				m_State_slave <= S_SEND_DATA;
				cnt_bit_slave <= 1'b0;
				StartResive <= 1'b0;
				DataSend <= 1'b1;
			end
			if(!scl_io) 
			begin
				if(cnt_bit_slave == 4'd8) m_State_slave <= S_GET_ACK;
			end
		end
		
		S_GET_ACK:
		begin
			if (scl_io)
			begin
				cnt_bit_slave <= 0;
				if (sda_io) m_State_slave <= S_IDLE;
				else 
				begin
					m_State_slave <= S_SEND_DATA;
					DataSend <= 1'b1;
				end
			end
		end
		
		endcase
		
	end
	
end

always @(posedge scl_io)
begin
	case(m_State_slave)
		S_GET_DATA:
		begin
			
			DATA_READ[4'd7 - cnt_bit_slave] <= sda_io;
			cnt_bit_slave <= cnt_bit_slave + 1'd1;
		
		end
		
		S_SEND_DATA:
		begin
			DataSend <= 1'b1;
		end
		
		
	endcase
end

always @(posedge Sda_clk)
begin
	case(m_State_slave)
	
		
	S_SEND_DATA:
	
	begin
	if (!scl_io & DataSend)
		begin
			DataSend <= 1'b0;
			sda_r <= DATA_WRITE[4'd7 - cnt_bit_slave];
			cnt_bit_slave <= cnt_bit_slave + 1'd1;
		end
	end
	
	S_SEND_ACK:
	
	begin
	if (!scl_io)
		begin
			if (sda_r == 1)
			begin
				cnt_bit_slave <= 0;
				if (SEND_ACK) sda_r <= 1'd0;
				else m_State_slave <= S_IDLE;
				
			end
			else
			begin
				sda_r <= 1'd1;
				
				
				cnt_slow_slave <= 0;
				
				if (SLOW) m_State_slave <= S_SLOW;
				
				else if (ReadData) 
				begin
					ReadData <= 0;
					m_State_slave <= S_SEND_DATA;
				end
				
				else m_State_slave <= S_GET_DATA;
			end
		end
			
	end
	
	endcase

end





Clock_generator_slave Slave_Gen
(
	.clk(clk),
	.rst(rst),
	.State_clk(State_clk),
	.Sda_clk(Sda_clk)
);

endmodule

module Clock_generator_slave
(
	input wire clk,
	input wire rst,
	output reg State_clk = 1'b0,
	output reg Sda_clk = 1'b0
);

reg [2:0] Counter = 0;

always @(negedge clk) 
begin
	if (rst) Counter = 0;
	else
	begin
		
		case(Counter)
			0:  
			begin
				State_clk <= 1'b1;
				Counter <= Counter + 1'b1;
			end
			1:  
			begin
				Sda_clk <= 1'b1;
				Counter <= Counter + 1'b1;
			end
			2:  
			begin
				State_clk <= 1'b0;
				Counter <= Counter + 1'b1;
			end
			3:  
			begin
				Sda_clk <= 1'b0;
				Counter <= 1'b0;
			end
			
				
		endcase
	end
end

endmodule 