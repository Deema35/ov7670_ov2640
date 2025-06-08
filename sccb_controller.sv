module sccb_controller 
(
	input wire clk, 
	input wire rst, 
	
	input wire m_valid,
	input wire [3:0]op_type,
	
	input wire [6:0]  ADDR,
	input wire [7:0]  REG,
	input wire [7:0]  DATA_IN,
	
	output reg [7:0] DATA_OUT,
	output reg m_ready,
	

	inout tri sda_io,
   inout tri scl_io
);

wire State_clk;
wire Sda_clk;

wire [7:0] ADDR_I2C;

reg scl_r = 'd1;
reg sda_r = 'd1;


	
assign scl_io = (scl_r) ? 1'bz : 1'b0;
assign sda_io = (sda_r) ? 1'bz : 1'b0;

assign ADDR_I2C[7:1] = ADDR[6:0];
assign ADDR_I2C[0] = (op_type == OP_R2) ? 1'b1 : 1'b0;

localparam  OP_W3 = 4'd0,
				OP_W2 = 4'd1,
				OP_R2 = 4'd2;

							
reg [4:0] cnt_bayte_get = 'd0;
reg [4:0] cnt_bayte_send = 'd0;
reg [3:0] NextState = 'd0;
reg [3:0] State_main = 'd0;
reg pre_start_flag = 'd0;

localparam 	S_IDLE = 4'd0,
				S_START = 4'd1,
				S_SEND_ADDR = 4'd3,
				S_SEND_REG  = 4'd4,
				S_SEND_DATA  = 4'd5,
				S_END_TRANSMIT = 4'd7,
				S_GET_ACK = 4'd8,
				S_GET_DATA = 4'd9,
				S_END_RESIVE = 4'd10,
				S_SEND_ACK = 4'd11,
				S_STOP = 4'd12;
				
				

always @(posedge State_clk) 
begin
	if (rst)
	begin
		
		State_main <= S_IDLE;
		
	end 
	else
	begin
	
		case(State_main)
		
		S_IDLE:
		begin
			
			m_ready <= 1'b0;
			cnt_bayte_get <= 'd0;
			cnt_bayte_send <= 'd0;
			
			if(m_valid) State_main <= S_START;
		end	
		
		
		S_START: if (!sda_r) State_main <= S_SEND_ADDR; 
		
		
		S_SEND_ADDR:
		begin
			if (TransmitReady) 
			begin
				if (op_type == OP_R2) NextState <= S_GET_DATA;
				else NextState <= S_SEND_REG;
				State_main <= S_END_TRANSMIT;
			end
		end
		
		
		S_SEND_REG: 
		begin
			if (TransmitReady) 
			begin
				if (op_type == OP_W3) NextState <= S_SEND_DATA;
				else NextState <= S_STOP;
				State_main <= S_END_TRANSMIT;
			end
		end
		
		
		S_SEND_DATA:
		begin
			if (TransmitReady) 
			begin 
				
				NextState <= S_STOP;
				
				State_main <= S_END_TRANSMIT;
			end
		end
		
		
		S_END_TRANSMIT: 
		begin
			if (!scl_r) 
			begin
				 State_main <= S_GET_ACK;
				
			end
		end
		
		S_GET_ACK: 
		begin
			if (ACKGeted & !scl_io) 
			begin
				
				State_main <= NextState;
				
			end
		end
		
		S_SEND_ACK:

		begin
			if (ACKGeted & !scl_io) 
			begin
				
				State_main <= NextState;
				cnt_bayte_get <= cnt_bayte_get + 1'b1;
			end
		end
		
		S_GET_DATA:
		begin
			if (TransmitReady) 
			begin 
				NextState <= S_STOP;
				
				State_main <= S_END_RESIVE;
			end
		end
		
		S_END_RESIVE: 
		begin
			if (!scl_r) 
			begin
				 State_main <= S_SEND_ACK;
				
			end
		end
		
		

		
		S_STOP:
		begin
			if (scl_io & sda_io)
			begin
				State_main <= S_IDLE;
				
				m_ready <= 1'b1;
			end
		end

		endcase
	end

end

wire [7:0] DATA_SEND;

assign DATA_SEND =   (State_main == S_SEND_ADDR) ? ADDR_I2C :
							(State_main == S_SEND_REG) ? REG:
							(State_main == S_SEND_DATA) ? DATA_IN : 8'd0;

reg ACKGeted = 'd0;
reg [3:0] cnt_bit = 'd0;
reg TransmitReady = 'd0;

always @(posedge Sda_clk) 
begin
if (rst)
begin
	sda_r <= 1'b1; 
end	
else
begin
	case(State_main)

	S_IDLE:
	begin
		ACKGeted <= 1'b0;
		sda_r <= 1'b1; 
		cnt_bit <= 'd0;
		TransmitReady <= 1'b0;
	end

	S_START: if (sda_r) sda_r <= 1'b0;

	S_SEND_ADDR, 
	S_SEND_REG, 
	S_SEND_DATA:
	begin
		ACKGeted <= 1'b0;
		if (!scl_r) 
		begin
			if (cnt_bit != 4'd7)
			begin
				sda_r <= DATA_SEND[4'd7 - cnt_bit];
				cnt_bit <= cnt_bit + 1;
			end
			else 
			begin
				sda_r <= DATA_SEND[0];
				cnt_bit <= 0;
				TransmitReady <= 1'b1;
			end
			
		end
	end	

	S_END_TRANSMIT,
	S_END_RESIVE:
	begin
		TransmitReady <= 1'b0;
		if (!scl_r) sda_r <= 1'b0;
	end

	S_GET_DATA:
	begin 
		sda_r <= 1'b1;
		ACKGeted <= 1'b0;
		if (scl_io) 
		begin
			if (cnt_bit != 4'd7)
			begin
				DATA_OUT[4'd7 - cnt_bit] <= sda_io;
				cnt_bit <= cnt_bit + 1;
			end
			else 
			begin
				DATA_OUT[0] <= sda_io;
				cnt_bit <= 0;
				TransmitReady <= 1'b1;
			end
		end
		
	end



	S_STOP: 
	begin
		if (scl_io) sda_r <= 1'b1;
		else sda_r <= 1'b0;
	end


	S_GET_ACK: 
		begin
			sda_r <= 1'b1;
			if (scl_io) 
			begin
				ACKGeted <= 1'b1;
			end
		end
		
	S_SEND_ACK:
		begin
			if (!scl_io) 
			begin
				sda_r <= 1'b1;
				ACKGeted <= 1'b1;
			end
		end
		



	default:
	begin
		
		sda_r <= 1'b1; 
		cnt_bit <= 0;
		TransmitReady <= 1'b0;
		
	end

	endcase
	
end
end	

always @(negedge Sda_clk) 
begin
if (rst)
begin
	scl_r <= 1'b1;
end
else
begin

	case(State_main)
	
	
	
	
	S_START: if (!sda_r) scl_r <= 1'b0;
	
	
	S_SEND_ADDR, 
	S_SEND_REG, 
	S_SEND_DATA,
	S_GET_DATA,
	S_SEND_ACK,
	S_GET_ACK:
	begin
	
		if (scl_r & scl_io) scl_r <= 1'b0;
			
		else scl_r <= 1'b1;
		
	end	
	
	S_END_TRANSMIT,
	S_END_RESIVE:
	begin
		if (scl_r & scl_io) scl_r <= 1'b0;
	end
	
	S_STOP: if (!scl_r) scl_r <= 1'b1;
	
	default: scl_r <= 1'b1;
	
	endcase
end
end

sccb_Clock_generator Gen
(
	.clk(clk),
	.rst(rst),
	.State_clk(State_clk),
	.Sda_clk(Sda_clk)
);

endmodule 

module sccb_Clock_generator
(
	input wire clk,
	input wire rst,
	output reg State_clk = 1'b0,
	output reg Sda_clk = 1'b0
);

reg [2:0] Counter  = 'd0;

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