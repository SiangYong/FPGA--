`timescale 1ns / 1ps

module HW6_2(clk,rst,button_R,Dinout,button_speed,LED);

input clk,rst,button_R,button_speed;
inout Dinout;
output [7:0] LED;

wire divclk1;
wire click_R;
wire LED_flag;
wire [1:0] LED_state,score_state;

divclk   div_clk  (divclk1,clk,rst,button_speed);
button   buttonR  (click_R,button_R,clk,rst);
FSM      fsm      (divclk1,rst,click_R,Dinout,LED_flag,LED_state,score_state);
LED      LED_move (divclk1,rst,LED_state,score_state,LED,LED_flag);

endmodule

//除頻
module divclk(divclk1,clk,rst,speed_ctr);

output divclk1;
input clk,rst,speed_ctr;
reg [25:0] divclkcnt,speed;

assign divclk1 = divclkcnt[speed];   //給LED

always @(posedge clk or negedge rst)
	begin
		if(rst)
			divclkcnt <= 25'b0;
		else
		  begin
		    divclkcnt <= divclkcnt+1;
		    
			if(~speed_ctr)
			 speed <= 22 + {$random} % (25 - 22 + 1);
			else
			 speed <= 24;
		  end
	end
endmodule 

//解彈跳
module button(click,in,clk,rst);

output reg click;
input in,clk,rst;

reg [23:0]decnt;
parameter bound = 24'hffffff;

always @ (posedge clk or negedge rst)begin
	if(rst)begin
		decnt <= 0;
		click <= 0;
	end
	else begin
		if(~in)begin
			if(decnt < bound)begin
				decnt <= decnt + 1;
				click <= 0;
			end
			else begin
			   decnt <= decnt;
				click <= 1;
			end
		end
		else begin
			decnt <= 0;
			click <= 0;
		end
	end
end
endmodule

//LED 移動
module LED(clk,rst,LED_state,score_state,LED,LED_flag);

input clk,rst;
input [1:0] LED_state,score_state;
output reg [7:0] LED;
output reg LED_flag;

reg score_flag;
reg [3:0] score_R,score_L;

always @(posedge clk or negedge rst)
	begin
		if(rst)
			begin
				LED <= 8'b0000_0000;
				score_flag <= 0;
				score_R <= 0;
				score_L <= 0;
			end
		else
			begin
				case(LED_state)
					2'b00:
						begin
							score_flag <= 1;
							
							case(score_state)
							     2'b00:
							         begin
							             score_R <= score_R;
							             score_L <= score_L;
							             LED[3:0] <= score_R;
							             LED[7:4] <= score_L;
							         end
							    2'b01:
							         begin
							             score_R <= score_R + 1;
							             score_L <= score_L;
							             LED[3:0] <= score_R;
							             LED[7:4] <= score_L;
							         end
							    2'b10:
							         begin
							             score_R <= score_R;
							             score_L <= score_L + 1;
							             LED[3:0] <= score_R;
							             LED[7:4] <= score_L;
							         end
							endcase							
						end
					2'b01:
						begin
						  if(score_flag == 1)
						      begin
						          LED <= 8'b0000_0001;
                              score_flag <= 0;
                              end
						  else
						      begin   
						          if(LED_flag == 0)						 
							         begin
						                  if(LED == 8'b0000_0000)
						                      LED <= 8'b0000_0001;
						                  else
							                  LED <= {LED[6:0],LED[7]};
							         end
						          else
						            LED <= 8'b0000_0000;
						      end
						end
					2'b10:
						begin
						  if(score_flag == 1)
						      begin
						          LED <= 8'b1000_0000;
						          score_flag <= 0;
						      end
						  else
						      begin
						          if(LED_flag == 0)						 
							         begin
						                  if(LED == 8'b0000_0000)
						                      LED <= 8'b1000_0000;
						                  else
							                  LED <= {LED[0],LED[7:1]};
							         end
						          else
						             LED <= 8'b0000_0000;
						     end
						end
				endcase
			end
	end

always @(LED)
	begin
		if(LED == 8'b1000_0000 && LED_state == 2'b01)
			LED_flag <= 1;
	    else if(LED == 8'b0000_0001 && LED_state == 2'b10)
	        LED_flag <= 1;
		else
			LED_flag <= 0;
	end

endmodule

//FSM
module FSM(clk,rst,button_R,Dinout,LED_flag,LED_state,score_state);

input clk,rst,button_R;
input [1:0] LED_flag;
inout Dinout;
output reg [1:0] LED_state,score_state;

wire Din,Dout;
assign Dout = 0;
/*  en = 0    Dinout一直接收狀態
    en=1       Dinout切到輸出狀態 */
assign Dinout = en ?Dout :1'bz;    //只有在LED=8'b1000_0000時，en才跳成1，其餘時間一直是0
assign Din    = en ?1'b1 :Dinout;
 
reg en;
reg [2:0] state;
/*
	LED_flag:						LED_state:		score_state:	       state:
		0 移動中/超過最後一格		    00 結束		 00 不計分	        3'b000 等發球
		1 已到最後一格			           01 左移		 01 右+1			3'b001 左移中
								           10 右移	         10 左+1			3'b010 右移中
															               3 'b011 等另一台
																       3'b100 左win
																       3'b101 等右發球
*/
always @(posedge clk or negedge rst)
	begin
		if(rst)
			begin
				state <= 3'b000;
				en    <= 0;
			end
		else
			begin
				case(state)
					3'b000:								//等發球
						begin
							if(~button_R)
								state <= 3'b001;
							else if(~Din)
								state <= 3'b010;
							else
							    state <= 3'b000;
						end
					3'b001:								//左移中
						begin
							if(LED_flag == 1)
							 begin
							    en <= 1;
								state <= 3'b011;
							 end
							else
							 begin
							    en <= 0;
								state <= 3'b001;
							 end
						end
					3'b010:								//右移中
						begin
							if(button_R == 0 && LED_flag == 1)
								state <= 3'b001;
							else if(button_R == 0 && LED_flag == 0)
								state <= 3'b100;
							else if(button_R == 1 && LED_flag == 1)
								state <= 3'b100;
							else
								state <= 3'b010;
						end
					3'b011:								//等另一台
						begin
						    en <= 0;
						    
							if(Din == 0)
								state <= 3'b010;
							else
								state <= 3'b011;
						end
					3'b100:								//左win
						begin
							if(~button_R)
								state <= 3'b010;
							else
								state <= 3'b101;
						end
					3'b101:								//等左發球
						begin
							if(~button_R)
								state <= 3'b010;
							else
								state <= 3'b101;
						end
				endcase
			end
	end
	
always @(state)
	begin
		case(state)
			3'b000:
				begin
					LED_state   <= 2'b00;
					score_state <= 2'b00;
				end
			3'b001:
				begin
					LED_state   <= 2'b01;
					score_state <= 2'b00;
				end
			3'b010:
				begin
					LED_state   <= 2'b10;
					score_state <= 2'b00;
				end
			3'b011:
				begin
					LED_state   <= 2'b00;
					score_state <= 2'b00;
 
				end
			3'b100:
				begin
					LED_state   <= 2'b00;
					score_state <= 2'b10;
				end
			3'b101:
				begin
					LED_state   <= 2'b00;
					score_state <= 2'b00;
				end
		endcase
	end

endmodule 
