`timescale 1ns / 1ps

module HW5(clk,rst,button_R,button_L,button_speed,LED,O_red,O_green,O_blue,O_hs,O_vs);

input clk,rst,button_R,button_L,button_speed;
output [7:0] LED;
output [3:0] O_red,O_green,O_blue;
output O_hs,O_vs;

wire divclk1;
wire click_R,click_L;
wire LED_flag;
wire [1:0] LED_state,score_state;

divclk     div_clk  (divclk1,clk,rst,button_speed);
button     buttonR  (click_R,button_R,clk,rst);
button     buttonL  (click_L,button_L,clk,rst);
FSM        fsm      (divclk1,rst,click_R,click_L,LED_flag,LED_state,score_state);
LED        LED_move (divclk1,rst,LED_state,score_state,LED,LED_flag);
vga_driver VGA(clk,rst,LED,O_red,O_green,O_blue,O_hs,O_vs);

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
module FSM(clk,rst,button_R,button_L,LED_flag,LED_state,score_state);

input clk,rst,button_R,button_L,LED_flag;
output reg [1:0] LED_state,score_state;

reg [2:0] state;
/*
	LED_flag:						LED_state:		score_state:	       state:
		0 移動中/超過最後一格		    00 結束		 00 不計分	        3'b000 等發球
		1 已到最後一格			    01 左移		 01 右+1			3'b001 左移中
								    10 右移	         10 左+1			3'b010 右移中
															        3'b011 右win
																3'b100 左win
																3'b101 等右發球
																3'b110 等左發球
*/
always @(posedge clk or negedge rst)
	begin
		if(rst)
			begin
				state <= 3'b000;
			end
		else
			begin
				case(state)
					3'b000:								//等發球
						begin
							if(~button_R)
								state <= 3'b001;
							else if(~button_L)
								state <= 3'b010;
							else
								state <= 3'b000;
						end
					3'b001:								//左移中
						begin
							if(button_L == 0 && LED_flag == 1)
								state <= 3'b010;
							else if(button_L == 0 && LED_flag == 0)
								state <= 3'b011;
							else if(button_L == 1 && LED_flag == 1)
								state <= 3'b011;
							else
								state <= 3'b001;
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
					3'b011:								//右win
						begin
							if(~button_R)
								state <= 3'b001;
							else
								state <= 3'b0101;
						end
					3'b100:								//左win
						begin
							if(~button_L)
								state <= 3'b010;
							else
								state <= 3'b110;
						end
					3'b101:								//等右發球
						begin
							if(~button_R)
								state <= 3'b001;
							else
								state <= 3'b101;
						end
					3'b110:								//等左發球
						begin
							if(~button_L)
								state <= 3'b010;
							else
								state <= 3'b110;
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
					score_state <= 2'b01;
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
			3'b110:
				begin
					LED_state   <= 2'b00;
					score_state <= 2'b00;
				end
		endcase
	end

endmodule 

module vga_driver
(
    input                      I_clk , //系統100MHz時鐘
    input                      I_rst_n , //系統復位
	input            [ 7 : 0 ] LED_state,
    output    reg    [ 3 : 0 ] O_red , // VGA紅色分量
    output    reg    [ 3 : 0 ] O_green , // VGA綠色分量
    output    reg    [ 3 : 0 ] O_blue , // VGA藍色分量
    output                   O_hs , // VGA行同步信號
    output                   O_vs       // VGA場同步信號
);

//分辨率為640*480時行時序各個參數定義
parameter        C_H_SYNC_PULSE =    96   ,
                C_H_BACK_PORCH       =    48   ,
                C_H_ACTIVE_TIME      =    640 ,
                C_H_FRONT_PORCH      =    16   ,
                C_H_LINE_PERIOD      =    800 ;

//分辨率為640*480時場時序各個參數定義               
parameter        C_V_SYNC_PULSE =    2    ,
                C_V_BACK_PORCH       =    33   ,
                C_V_ACTIVE_TIME      =    480 ,
                C_V_FRONT_PORCH      =    10   ,
                C_V_FRAME_PERIOD     =    525 ;
                
parameter        C_COLOR_BAR_WIDTH = C_H_ACTIVE_TIME / 8   ;  

reg [ 11 : 0 ] R_h_cnt ; //行時序計數器
reg [ 11 : 0 ] R_v_cnt ; //列時序計數器
reg              R_clk_50M , R_clk_25M ;

wire             W_active_flag ; //激活標誌，當這個信號為1時RGB的數據可以顯示在屏幕上

//////////////////////////////////////////////////////////////////
 //功能： 產生25MHz的像素時鐘
//////////////////////////////////////////////////////////////////
 always @( posedge I_clk or  negedge I_rst_n)
 begin 
    if (I_rst_n)
        R_clk_50M    <=   1'b0 ; 
    else 
        R_clk_50M    <= ~ R_clk_50M ;     
 end 
 always @( posedge R_clk_50M or  negedge I_rst_n)
 begin 
    if (I_rst_n)
        R_clk_25M    <=   1'b0 ; 
    else 
        R_clk_25M    <= ~ R_clk_25M ;     
 end 
//////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////
 //功能：產生行時序
//////////////////////////////////////////////////////////////////
 always @( posedge R_clk_25M or  negedge I_rst_n)
 begin 
    if (I_rst_n)
        R_h_cnt <=   12'd0 ; 
    else  if (R_h_cnt == C_H_LINE_PERIOD - 1'b1) 
        R_h_cnt <=   12'd0 ; 
    else 
        R_h_cnt <= R_h_cnt + 1'b1 ;                 
end                

assign O_hs = (R_h_cnt < C_H_SYNC_PULSE) ? 1'b0 : 1'b1 ; 
 //////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////
 //功能：產生場時序
//////////////////////////////////////////////////////////////////
 always @( posedge R_clk_25M or  negedge I_rst_n)
 begin 
    if (I_rst_n)
        R_v_cnt <=   12'd0 ; 
    else  if (R_v_cnt == C_V_FRAME_PERIOD - 1'b1) 
        R_v_cnt <=   12'd0 ; 
    else  if (R_h_cnt == C_H_LINE_PERIOD - 1'b1) 
        R_v_cnt <= R_v_cnt + 1'b1 ; 
    else 
        R_v_cnt <=   R_v_cnt ;                        
 end                

assign O_vs = (R_v_cnt < C_V_SYNC_PULSE) ? 1'b0 : 1'b1 ; 
 //////////////////////////////////////////////////////////////////  

assign W_active_flag = (R_h_cnt >= (C_H_SYNC_PULSE + C_H_BACK_PORCH )) && 
                        (R_h_cnt <= (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_H_ACTIVE_TIME)) &&  
                        (R_v_cnt >= (C_V_SYNC_PULSE + C_V_BACK_PORCH )) && 
                        (R_v_cnt <= (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME)) ;                     

//////////////////////////////////////////////////////////////////
 //功能：把顯示器屏幕分成8個縱列，每個縱列的寬度是80 
//////////////////////////////////////////////////////////////////
 always @( posedge R_clk_25M or  negedge I_rst_n)   //顯示邊界當球
 begin 
    if (I_rst_n) 
         begin 
            O_red    <=   4'b0000 ; 
            O_green <=   4'b0000 ; 
            O_blue <=   4'b0000 ; 
        end 
    else  if (W_active_flag)     
         begin 
			if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH)) 
				begin 
					if(LED_state == 8'b1000_0000)
				        begin
							O_red    <=   4'b1111 ; 
							O_green <=   4'b0000 ; 
							O_blue <=   4'b0000 ; 
						end 
				end
			else if (R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH* 2 )) 
				begin 
				    if(LED_state == 8'b0100_0000)
				        begin
							O_red    <=   4'b1111 ; 
							O_green <=   4'b0000 ; 
							O_blue <=   4'b0000 ;
						end
				end
            else if (R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH* 3 ))
			     begin 
			         if(LED_state == 8'b0010_0000)
				        begin
							O_red    <=   4'b1111 ; 
							O_green <=   4'b0000 ; 
							O_blue <=   4'b0000 ;
						end
				end
            else if (R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*4 ))
			    begin
			         if(LED_state == 8'b0001_0000)
				        begin 
							O_red    <=   4'b1111 ; 
							O_green <=   4'b0000 ; 
							O_blue <=   4'b0000 ;
						end 
				end		
			else if (R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH* 5 )) 
			     begin
			         if(LED_state == 8'b0000_1000)
				        begin 
							O_red    <=   4'b1111 ; 
							O_green <=   4'b0000 ; 
							O_blue <=   4'b0000 ;
						end
				end		
            else if (R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH* 6 )) 
				begin 
				    if(LED_state == 8'b0000_0100)
				        begin
							O_red    <=   4'b1111 ; 
							O_green <=   4'b0000 ; 
							O_blue <=   4'b0000 ;
						end  
				end
			else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH* 7 ))
				begin
				    if(LED_state == 8'b0000_0010)
				        begin 
							O_red    <=   4'b1111 ; 
							O_green <=   4'b0000 ; 
							O_blue <=   4'b0000 ;
						end 
				end
            else 
                begin 
                    if (LED_state == 8'b0000_0001)
                        begin
                            O_red    <=   4'b1111 ; 
							O_green <=   4'b0000 ; 
							O_blue <=   4'b0000 ;
                        end
                 end                    
        end 
    else 
        begin 
            O_red    <=   4'b0000 ; 
            O_green <=   4'b0000 ; 
            O_blue <=   4'b0000 ; 
        end            
end 

endmodule
