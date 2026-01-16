`timescale 1ns / 1ps

module ahb_top_tb;

   
    reg hclk;
    reg hresetn;

    
    reg         cmd_start;
    reg         cmd_write;
    reg         cmd_burst; 
    reg [31:0]  cmd_addr;
    reg [31:0]  cmd_wdata;
    reg         cmd_sec;
    
    wire        cmd_done;
    wire        cmd_error;
    wire [31:0] cmd_rdata;

   
    ahb_top u_dut (
        .hclk       (hclk),
        .hresetn    (hresetn),
        .cmd_start  (cmd_start),
        .cmd_write  (cmd_write),
        .cmd_burst  (cmd_burst), 
        .cmd_addr   (cmd_addr),
        .cmd_wdata  (cmd_wdata),
        .cmd_sec    (cmd_sec),
        .cmd_done   (cmd_done),
        .cmd_error  (cmd_error),
        .cmd_rdata  (cmd_rdata)
    );

    initial hclk = 0;
    always #5 hclk = ~hclk;

    initial begin
       
        hresetn = 0;
        cmd_start = 0;
        cmd_write = 0;
        cmd_burst = 0; 
        cmd_addr = 0;
        cmd_wdata = 0;
        cmd_sec = 0; 

        repeat (5) @(posedge hclk);
        hresetn = 1;
        repeat (2) @(posedge hclk);

        $display("\n--- Simulation Start ---");

      
        $display("[T= %0t] TEST 1: Single Write 0xCAFEBABE to 0x00...", $time);
        
        drive_trans(1'b1, 32'h0000_0000, 32'hCAFEBABE, 1'b0, 1'b0); 

      
        $display("[T= %0t] TEST 2: Reading from Address 0x00...", $time);
        drive_trans(1'b0, 32'h0000_0000, 32'h0, 1'b0, 1'b0); 

        if (cmd_rdata === 32'hCAFEBABE) 
            $display("PASS: Read Data matches expected (0xCAFEBABE)");
        else 
            $display("FAIL: Read Data 0x%h != Expected 0xCAFEBABE", cmd_rdata);

        $display("[T= %0t] TEST 3: Attempting Non-Secure Write...", $time);
        drive_trans(1'b1, 32'h0000_0004, 32'hDEADBEEF, 1'b1, 1'b0); 
        
        if (cmd_error == 1)
            $display("PASS: Security Error detected correctly.");
        else
            $display("FAIL: Security violation was missed!");

     
        $display("\n[T= %0t] TEST 4: Starting INCR4 Burst Write at 0x00...", $time);
        drive_trans(1'b1, 32'h0000_0000, 32'h0000_0010, 1'b0, 1'b1); 

        $display("[T= %0t] TEST 5: Verifying Burst Data...", $time);
        

        drive_trans(1'b0, 32'h0, 32'h0, 1'b0, 1'b0);
        if(cmd_rdata === 32'h10) $display("PASS: Burst Word 0 Correct (0x10)");
        else $display("FAIL: Burst Word 0 Wrong (Got 0x%h)", cmd_rdata);

        
        drive_trans(1'b0, 32'h4, 32'h0, 1'b0, 1'b0);
        if(cmd_rdata === 32'h11) $display("PASS: Burst Word 1 Correct (0x11)");
        else $display("FAIL: Burst Word 1 Wrong (Got 0x%h)", cmd_rdata);

       
        drive_trans(1'b0, 32'h8, 32'h0, 1'b0, 1'b0);
        if(cmd_rdata === 32'h12) $display("PASS: Burst Word 2 Correct (0x12)");
        else $display("FAIL: Burst Word 2 Wrong (Got 0x%h)", cmd_rdata);

        
        drive_trans(1'b0, 32'hC, 32'h0, 1'b0, 1'b0);
        if(cmd_rdata === 32'h13) $display("PASS: Burst Word 3 Correct (0x13)");
        else $display("FAIL: Burst Word 3 Wrong (Got 0x%h)", cmd_rdata);

        $display("--- Simulation Done ---\n");
        $finish;
    end

    task drive_trans;
        input is_write;
        input [31:0] addr;
        input [31:0] wdata;
        input is_nonsec;
        input is_burst_mode;
    begin
        
        @(posedge hclk);
        cmd_start <= 1;
        cmd_write <= is_write;
        cmd_addr  <= addr;
        cmd_wdata <= wdata;
        cmd_sec   <= is_nonsec;
        cmd_burst <= is_burst_mode;

        @(posedge hclk);
        cmd_start <= 0;
        cmd_burst <= 0; 

        wait(cmd_done);
        @(posedge hclk); 
    end
    endtask


endmodule
