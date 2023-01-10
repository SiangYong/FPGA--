`timescale 1ns / 1ps

module HW6_1(clk,rst,sw,Dinout,LED);

input clk,rst,sw;
inout  Dinout;
output reg LED;

wire Dout,Din;

assign Dout = 0 ;

assign Dinout = sw ?Dout :1'bz;
assign Din    = sw ?1'b1 :Dinout;

always @(*) begin
    if(rst) LED <= 0;
    else begin
        if(Din == 0)  LED <= 1;
        else     LED <= 0;
    end
end

endmodule
