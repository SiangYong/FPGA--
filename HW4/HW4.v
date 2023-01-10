module vga_driver
(
    input                    I_clk , //系統50MHz時鐘
    input                    I_rst_n , //系統復位
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
 always @( posedge R_clk_25M or  negedge I_rst_n)
 begin 
    if (I_rst_n) 
         begin 
            O_red    <=   4'b0000 ; 
            O_green <=   4'b0000 ; 
            O_blue <=   4'b40000 ; 
        end 
    else  if (W_active_flag)     
         begin 
            if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH)) //紅色彩條
                begin 
                    O_red    <=   4'b1111 ; // 紅色彩條把紅色分量全部給1，綠色和藍色給0 
                    O_green <=   4'b0000 ; 
                    O_blue <=   4'b0000 ; 
                end 
            else  if (R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH* 2 )) //綠色彩條
                begin 
                    O_red    <=   4'b0000 ; 
                    O_green <=   4'b1111 ; // 綠色彩條把綠色分量全部給1，紅色和藍色分量給0 
                    O_blue <=   4'b0000 ; 
                end  
            else  if (R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH* 3 )) //藍色彩條
                begin 
                    O_red    <=   4'b0000 ; 
                    O_green <=   4'b0000 ; 
                    O_blue <=   4'b1111 ; // 藍色彩條把藍色分量全部給1，紅色和綠分量給0
                 end  
            else  if (R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*4 )) //白色彩條
                begin 
                    O_red    <=   4'b1111 ; // 白色彩條是有紅綠藍三基色混合而成
                    O_green <=   4'b1111 ; // 所以白色彩條要把紅綠藍三個分量全部給1 
                    O_blue <=   4'b1111 ; 
                end  
            else  if (R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH* 5 )) //黑色彩條
                begin 
                    O_red    <=   4'b0000 ; // 黑色彩條就是把紅綠藍所有分量全部給0 
                    O_green <=  4'b0000 ; 
                    O_blue <=   4'b0000 ; 
                end  
            else  if (R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH* 6 )) //黃色彩條
                begin 
                    O_red    <=   4'b1111 ; // 黃色彩條是有紅綠兩種顏色混合而成
                    O_green <=   4'b1111 ; // 所以黃色彩條要把紅綠兩個分量給1 
                    O_blue <=   4'b0000 ; // 藍色分量給0
                 end  
            else  if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH* 7 )) //紫色彩條
                begin 
                    O_red    <=   4'b1111 ; // 紫色彩條是有紅藍兩種顏色混合而成
                    O_green <=   4'b0000 ; // 所以紫色彩條要把紅藍兩個分量給1 
                    O_blue <=   4'b1111 ; // 綠色分量給0
                 end  
            else                               //青色彩條
                begin 
                    O_red    <=   4'b0000 ; // 青色彩條是由藍綠兩種顏色混合而成
                    O_green <=   4'b1111 ; // 所以青色彩條要把藍綠兩個分量給1 
                    O_blue <=   4'b1111 ; // 紅色分量給0
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
