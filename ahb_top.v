module ahb_top (
    input wire hclk,
    input wire hresetn,

   
    input wire        cmd_start,
    input wire        cmd_write,
    input wire        cmd_burst, 
    input wire [31:0] cmd_addr,
    input wire [31:0] cmd_wdata,
    input wire        cmd_sec,
    
    output wire        cmd_done,
    output wire        cmd_error,
    output wire [31:0] cmd_rdata
);

 
    
    wire [31:0] haddr;      
    wire [1:0]  htrans;     
    wire        hwrite;
    wire [31:0] hwdata;     
    wire [2:0]  hsize;      
    wire [2:0]  hburst;     
    wire        hnonsec;
    wire        hmastlock;

    
    wire [31:0] hrdata;     
    wire        hresp;
    wire        hreadyout; 

   
    wire        hsel_slave;
    wire        hready_sys; 

  
    
    
    assign hsel_slave = (haddr[31:16] == 16'h0000);

    
    assign hready_sys = hreadyout;

   
    ahb5_master_lite u_master (
        .hclk       (hclk),
        .hresetn    (hresetn),

     
        .haddr      (haddr),
        .htrans     (htrans),
        .hwrite     (hwrite),
        .hwdata     (hwdata),
        .hsize      (hsize),
        .hburst     (hburst), 
        .hnonsec    (hnonsec),
        .hmastlock  (hmastlock),
        .hrdata     (hrdata),
        .hready     (hready_sys), 
        .hresp      (hresp),

        
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

   
    ahb5_slave_lite u_slave (
        .hclk       (hclk),
        .hresetn    (hresetn),

        .hsel       (hsel_slave),
        .haddr      (haddr),
        .htrans     (htrans),
        .hwrite     (hwrite),
        .hsize      (hsize),
        .hburst     (hburst),
        .hready_in  (hready_sys), 
        .hnonsec    (hnonsec),

        .hwdata     (hwdata),
        .hrdata     (hrdata),
        .hreadyout  (hreadyout),
        .hresp      (hresp)
    );


endmodule
