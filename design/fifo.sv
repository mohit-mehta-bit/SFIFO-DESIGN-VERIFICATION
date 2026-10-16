`timescale 1ns / 1ps

module fifo( input clk,rst,wr,rd,
             input [7:0] din,
             output full, empty,
             output reg [7:0] dout
 );
    
   reg [3:0] wptr;
   reg [3:0] rptr;
   reg [4:0] cnt;
   reg [7:0] mem[16];
   
   always @(posedge clk)begin
    
    if (rst)begin
        wptr <=0;
        rptr <=0;
        cnt <=0;
        
    end
    
    else begin
         if (wr &&(full==1'b0))begin
               mem[cnt]<=din;
               wptr<=wptr+1;
               cnt++;
         end
         else if (rd && (empty == 1'b0))begin
               dout <= mem[rptr];
               rptr <= rptr +1;
               cnt <= cnt-1;
         
         end
    end
    
   end
   
   assign full = (cnt==16) ? 1'b1: 1'b0;
   assign empty = (cnt==0) ? 1'b1: 1'b0;
    
endmodule
