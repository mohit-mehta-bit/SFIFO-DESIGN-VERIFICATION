interface fifo_if();

      logic clk;
      logic rst;
      logic wr;
      logic rd;
      logic [7:0] din;
      logic [7:0] dout;
      logic full;
      logic empty;
      
endinterface

class transaction;
    
    rand bit oper;
    rand bit [7:0] din;
    bit wr;
    bit rd;
    bit full;
    bit empty;
    bit [7:0] dout;
    
    constraint oper_c {  
                  oper dist {0 :/ 50 , 1:/50};
                             }
    constraint data_c { 
                       din inside {[1:20]};
                            }
    
endclass

class generator;
      
      transaction tr;
      mailbox #(transaction) mbx;
      event done;
      event next;
      int count;
      
      function new(mailbox #(transaction)mbx);
     
      this.mbx  =   mbx;
      
      endfunction
      
      task run();
        repeat(count)begin
            tr = new();
            assert(tr.randomize) else $error("randomization failed");
            mbx.put(tr);
            $display("[GEN]: operation: %0b,(1:wr,0:rd), data_in : %0b", tr.oper,tr.din);
            
            @next;
        end
        
        ->done;
      endtask
      
endclass

class driver;
        
        transaction tr;
        mailbox #(transaction) mbx;
        virtual fifo_if vif;
        
        function new(mailbox #(transaction) mbx,virtual fifo_if vif);
                
           this.mbx = mbx;
           this.vif = vif;
        
        endfunction
        
        task reset();
           vif.rst <= 1'b1;
           repeat(5) @(posedge vif.clk);
           vif.rst <=1'b0;
           @(posedge vif.clk);
           $display("----------------------------------------------------------");
        endtask
        
        task write();
        
           @(posedge vif.clk);
           vif.wr <= 1'b1;
           vif.rd <= 1'b0;
           
           vif.din <= tr.din;
           
           @(posedge vif.clk);
           vif.wr <= 1'b0;
           $display("[DRV]: data in: ", tr.din);
           
           
        endtask
        
        task read();
           
           @(posedge vif.clk);
           vif.rd <= 1'b1;
           vif.wr <= 1'b0;
           
           @(posedge vif.clk);
           vif.rd <=1'b0;
           
           $display("DATA READ");
        endtask
        
        task run();
           forever begin
            mbx.get(tr);
            
            if (tr.oper)begin
               write();
            end
            
            else begin
               read();
            end
           end
        
        endtask
        
endclass

class monitor;

       transaction tr;
       mailbox #(transaction) mbx;
       virtual fifo_if vif;
       
       function new(mailbox #(transaction) mbx,virtual fifo_if vif);
         
         this.mbx = mbx;
         this.vif = vif;
         
       endfunction
       
       task run();
       forever begin
       tr =new();
         @(posedge vif.clk);
         #1;
         if (vif.wr || vif.rd) begin
           tr = new();
         tr.wr = vif.wr;
         tr.rd = vif.rd;
         tr.din = vif.din;
         tr.full = vif.full;
         tr.empty = vif.empty;
         
         @(posedge vif.clk);
         #1;
         tr.dout = vif.dout;
         
         mbx.put(tr);
         
          $display("[MON] : WR=%0d | RD=%0d | DIN=%0d | DOUT=%0d | FULL=%0d | EMPTY=%0d",
                tr.wr,
                tr.rd,
                tr.din,
                tr.dout,
                tr.full,
                tr.empty);
          end
                
       end
       endtask
 
endclass

class scoreboard;
        
        transaction tr;
        mailbox #(transaction) mbx;
        event next;
        bit [7:0] reff[$];
        
        bit [7:0] temp;
        
        int err = 0;
        
        function new(mailbox #(transaction) mbx);
           this.mbx = mbx;
        endfunction
        
        task run();
           forever begin
               mbx.get(tr);
                $display("[SCO] : WR=%0d | RD=%0d | DIN=%0d | DOUT=%0d | FULL=%0d | EMPTY=%0d",
                tr.wr,
                tr.rd,
                tr.din,
                tr.dout,
                tr.full,
                tr.empty);
               
               if(tr.wr==1'b1)begin
                    if (tr.full==1'b0)begin
                      reff.push_front(tr.din);
                     
               $display("[SCO] : DATA STORED = %0d", tr.din);
               $display("WRITE OPERATION SUCCESSFUL");
                      
                    end
                    else begin 
                    $display("FIFO IS FULL");
                    end
                end
                
                else if (tr.rd==1'b1)begin
                
                  if(tr.empty==1'b0)begin
                      temp = reff.pop_back();
                      
                      if (temp==tr.dout)begin
                      $display("READ OPERATION SUCCESSFUL");
                      $display("[SCO] : DATA MATCH | Expected = %0d | Actual = %0d",
                      temp,
                      tr.dout);
                      end
                      else begin
                      err++;
                      $display("READ OPERATION FAILED, NO OF OPERATION FAILED = %0d",err);
                     end 
                  end
                  else begin
                     $display("FIFO IS EMPTY");
                  end
                end
                $display("----------------------------------------------------------");
                
             ->next;   
           end
        endtask
endclass

class environment;
      
      virtual fifo_if vif;
      mailbox #(transaction) gen2drv;
      mailbox #(transaction) mon2sco;
      
      generator gen;
      driver drv;
      monitor mon;
      scoreboard sco;
      
      event next;
      
      function new( virtual fifo_if vif);
         
          gen2drv = new();
          mon2sco = new();
          
          gen = new(gen2drv);
          drv = new(gen2drv,vif);
          mon = new(mon2sco,vif);
          sco = new(mon2sco);
          
          gen.next = next;
          sco.next = next;
          
      endfunction
      
      task pretest();
            
            drv.reset();
      endtask
      
      task test();
         fork
           gen.run();
           drv.run();
           mon.run();
           sco.run();
         join_any
      endtask
      
      task posttest();
        
        wait(gen.done.triggered);
        $finish;
         
      endtask
      
      task run();
          pretest();
          test();
          posttest();
      endtask
      
endclass

module tb( );
     
     fifo_if vif();
     fifo dut (  .clk   (vif.clk),
                 .rst   (vif.rst),
                 .wr    (vif.wr),
                 .rd    (vif.rd), 
                 .din   (vif.din),
                 .dout  (vif.dout),
                 .empty (vif.empty),
                 .full  (vif.full) );
     environment env;
     
     initial vif.clk = 1'b0;
     
     always #10 vif.clk = ~ vif.clk;
     
     initial begin
          env = new(vif);
          env.gen.count=10;
          env.run();
     end
     
  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars;
end
endmodule
