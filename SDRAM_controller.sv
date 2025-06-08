module sdram_controller
#(
	parameter CL = 3,
	parameter	INIT_PER	=	12000
)
(
    input clk_ref,
	 input rst,
	 //user interface)
	 input [15:0] in_data, // valid if m_we==1 Data write
	 input [23:0] m_addr, //2bit BANK, 13bit ROW, 9bit COLUMM
	 input		 m_we	  , // 0 - read, 1 - write)
	 input		 m_valid, //req
	 
	 input wire Serial_access,
	 
	 output      m_ready,
	 output reg[15:0] out_data,  //Data read

	 	 
	 //SDRAM interface
	 output reg sd_cke,
	 output sd_clk,
	 output sd_dqml,
	 output sd_dqmh,
	 output reg  sd_cas_n,
	 output reg sd_ras_n,
	 output reg sd_we_n,
	 output reg sd_cs_n,
	 output reg [14:0] sd_addr,
	 inout  tri [15:0] sd_data
);


reg [3:0] state_main = S_WAIT;
reg [23:0] m_addr_set;
reg flg_first_cmd = 1'b1;
reg [15:0] cnt_wait = 'd0;
reg [10:0] cnt_refresh_sdram = 'd0;

assign sd_clk = clk_ref;

    parameter  S_WAIT = 4'd0,    
					S_NOP = 4'd1,    
					S_PRECHARGE_ALL = 4'd2,   
					S_AUTO_REFRESH = 4'd3,
					S_LOAD_MODE = 4'd4,
					S_IDLE = 4'd5,
					S_NOT_PRECHARGE_IDLE = 4'd6,
					S_ACTIVATE_ROW = 4'd7,
					S_WRITE = 4'd8,
					S_PRECHARGE_AFTER = 4'd9,
					S_READ = 4'd10,
					S_READING_DATA = 4'd11;

					 
always@(posedge clk_ref)
begin
	if(rst) begin
		state_main <= S_WAIT;
		
		flg_first_cmd <= 1'b1;
		cnt_wait <= 1'b0;
		m_ready <= 1'b0;
		
	end
	else
	begin
		case(state_main)
		
			S_WAIT: 
			
			begin 
			
				if(cnt_wait != INIT_PER) cnt_wait <= cnt_wait + 1'b1; 
				
				else 
				begin
					state_main<= S_NOP;
					cnt_wait <= 0;
				end 
				
			end
			
			S_NOP: 
			
			begin 
			
				if(cnt_wait != 2000) cnt_wait <= cnt_wait + 1'b1;
				
				else
				begin 
					state_main<= S_PRECHARGE_ALL;
					cnt_wait <= 0;
				end 
				
			end
			
			S_PRECHARGE_ALL: 
			
			begin 
				if(cnt_wait != 1) cnt_wait <= cnt_wait + 1'b1;
				
				else 
				begin 
					cnt_wait <= 0;
					state_main <= S_AUTO_REFRESH;
				end 
				
			end
			
			S_AUTO_REFRESH: 
			
			begin 
				if(cnt_wait[14:0] != 6) cnt_wait <= cnt_wait + 1'b1;
				
				else 
				begin 
					cnt_wait[14:0] <= 0;
					
					if(cnt_wait[15]) 
					begin
					state_main <= S_LOAD_MODE;
					cnt_wait[15] <= 0;
					end 
					
					else cnt_wait[15] <= 1;
				end 
				
				
			end
			
			S_LOAD_MODE: 
			
			begin 
				if(cnt_wait != 1) cnt_wait <= cnt_wait + 1'b1;
				
				else
				begin 
					cnt_wait <= 0;
					state_main <= S_IDLE;
				end 
				 
			end
			
			S_IDLE:  
			
			begin 
				if(!m_valid) 
				begin
					if(&cnt_refresh_sdram) 
					begin
						state_main <= S_PRECHARGE_AFTER;
						cnt_refresh_sdram <= 0;
					end 
					else cnt_refresh_sdram <= cnt_refresh_sdram + 1'b1;
				end
				
				else
				
				begin
					cnt_refresh_sdram <= 0;
					m_addr_set <= m_addr;
					state_main <= S_ACTIVATE_ROW;
					
				end 
				
			end
			
			S_NOT_PRECHARGE_IDLE:
			begin
				if (!Serial_access) state_main <= S_PRECHARGE_AFTER;
				else
				begin
				
					if (m_valid)
					begin
						if (m_addr_set[21:9] == m_addr[21:9])
						begin
							m_addr_set <= m_addr;
							flg_first_cmd <= 1;
							
							if(m_we) state_main <= S_WRITE;
							else state_main <= S_READ;
						end
						else  state_main <= S_PRECHARGE_AFTER;
						
					end
				end
			
			end
			
			S_ACTIVATE_ROW:
			
			begin 
				if(cnt_wait != CL) cnt_wait <= cnt_wait + 1'b1;
				
				else
				
				begin 
					cnt_wait <= 0;
					
					if(m_we) state_main <= S_WRITE;
					else state_main <= S_READ;
					
					flg_first_cmd <= 1;
				end 
			end
			S_WRITE: 
			
			begin
			
				m_ready<= 1'b1;
				
				if(flg_first_cmd) flg_first_cmd <= 0;
				
				else 
				begin 
				
					if(!m_valid) 
					begin
						m_ready<= 1'b0;
						
						if (Serial_access) state_main <= S_NOT_PRECHARGE_IDLE;
						else  state_main <= S_PRECHARGE_AFTER;
						
					end
					
				end
			end
						
			S_PRECHARGE_AFTER: 
			
			begin 
				
			begin
				if(cnt_wait != 3) cnt_wait <= cnt_wait + 1'b1;
				
				else 
				begin 
					cnt_wait <= 0;
					state_main <= S_IDLE;
				end
			end
				
			end
			
			S_READ:
			
			begin 
			
				if(flg_first_cmd) flg_first_cmd <= 0;
				
				else 
				begin
					if (cnt_wait > CL) m_ready<= 1'b1;
					
					
					if(!m_valid) 
					begin
					
						m_ready<= 1'b0;
					
						cnt_wait <= 0;
						
						if (Serial_access) state_main <= S_NOT_PRECHARGE_IDLE;
						else  state_main <= S_PRECHARGE_AFTER;
						

					end
					
					else cnt_wait <= cnt_wait + 1'b1;
				end
				
				
			end
			
			
		endcase
	end
end


					  
assign sd_dqml	= 0;
assign sd_dqmh	= 0;

always@(posedge clk_ref)
begin

	out_data <= sd_data;

	sd_cke <= (state_main == S_WAIT) ?  0:1;

	sd_cs_n <= (rst == 1) ? 1:0;

	sd_addr[14:13] <= m_addr_set[23:22]; //Set bunk number
	
	case(state_main)

		
		S_PRECHARGE_ALL, S_PRECHARGE_AFTER:  //precharge then NOP
		begin
			sd_cas_n <=	1;
			sd_ras_n <= (cnt_wait==0) ? 0:1;
			sd_we_n <= (cnt_wait==0) ? 0:1;
			sd_addr[12:0] <= (cnt_wait==0) ? {4'b0,1'b1,10'b0} : 0;
			
		end
		
		S_AUTO_REFRESH: //autorefresh  then NOP
		begin
			sd_cas_n <= (cnt_wait[14:0]==0) ? 0:1;
			sd_ras_n <= (cnt_wait[14:0]==0) ? 0:1;
			sd_we_n	<= 1;
			sd_addr[12:0] <= 0;
		end
		
		S_LOAD_MODE: //load mode then NOP
		begin
			sd_cas_n <= (cnt_wait==0) ? 0:1;
			sd_ras_n <= (cnt_wait==0) ? 0:1;
			sd_we_n <= (cnt_wait==0) ? 0:1;
			sd_addr[12:0] <= (cnt_wait==0)  ? {2'b00,3'b000,1'b1,2'b00,CL[2:0],1'b0,3'b000} : 0; 
			//BA[1:0]==0,A[12:10]==0,WRITE_BURST_MODE = 0,OP_MODE = 'd0, CL = 2, TYPE_BURST = 0, BURST_LENGTH = 1
		end
		
		S_ACTIVATE_ROW: //activate then NOP
		begin
			sd_cas_n <= 1;
			sd_ras_n <= (cnt_wait==0) ? 0:1;
			sd_we_n <= 1;
			sd_addr[12:0] <= (cnt_wait==0)  ? m_addr_set[21:9] : 0;
		end
		
		S_WRITE: //WRITE or NOP
		begin
			sd_cas_n <= (m_valid == 1 && m_ready == 1) ? 0:1;
			sd_ras_n <= 1;
			sd_we_n <= (m_valid == 1 && m_ready == 1) ? 0:1;
			sd_addr[12:0] <= {7'd0,m_addr_set[8:0]};
		end
		
		S_READ: //Read then NOP
		begin
			sd_cas_n <= (cnt_wait==0) ? 0:1;
			sd_ras_n <=  1;
			sd_we_n <=  1;
			sd_addr[12:0] <= {7'd0,m_addr_set[8:0]};
		end
		
		
		default: //NOP
		begin
			sd_cas_n <=	1; 
			sd_ras_n<= 1;
			sd_we_n	<= 1;
			sd_addr[12:0] <= 0;
		
		end
	endcase

end



assign  sd_data = (state_main == S_WRITE) ? in_data : 16'hzzzz;



endmodule 