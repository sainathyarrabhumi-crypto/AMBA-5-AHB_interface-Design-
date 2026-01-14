module ahb_top (
    input wire hclk,
    input wire hresetn,

    // --- User/Client Interface ---
    input wire        cmd_start,
    input wire        cmd_write,
    input wire        cmd_burst, // The new burst signal
    input wire [31:0] cmd_addr,
    input wire [31:0] cmd_wdata,
    input wire        cmd_sec,
    
    output wire        cmd_done,
    output wire        cmd_error,
    output wire [31:0] cmd_rdata
);

    // =========================================================================
    // 1. Define the AHB Bus Wires (WITH CORRECT WIDTHS)
    // =========================================================================
    // Signals Master drives -> Slave
    wire [31:0] haddr;      // Fixed: Was 1-bit, now 32-bit
    wire [1:0]  htrans;     // Fixed: Was 1-bit, now 2-bit
    wire        hwrite;
    wire [31:0] hwdata;     // Fixed: Was 1-bit, now 32-bit
    wire [2:0]  hsize;      // Fixed: Was 1-bit, now 3-bit
    wire [2:0]  hburst;     // Fixed: Was 1-bit, now 3-bit
    wire        hnonsec;
    wire        hmastlock;

    // Signals Slave drives -> Master
    wire [31:0] hrdata;     // Fixed: Was 1-bit, now 32-bit
    wire        hresp;
    wire        hreadyout;  // Output from Slave

    // Interconnect Signals
    wire        hsel_slave; // Decoder output
    wire        hready_sys; // Global Ready Signal

    // =========================================================================
    // 2. The Interconnect Logic
    // =========================================================================
    
    // A. The Decoder
    // Map Slave to 0x0000_0000 -> 0x0000_FFFF (Top 16 bits are 0)
    assign hsel_slave = (haddr[31:16] == 16'h0000);

    // B. The HREADY Feedback Loop
    // In a system with 1 slave, System Ready is just the Slave's Ready.
    assign hready_sys = hreadyout;

    // =========================================================================
    // 3. Instantiate the Master
    // =========================================================================
    ahb5_master_lite u_master (
        .hclk       (hclk),
        .hresetn    (hresetn),

        // Bus Interface
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

        // Client Interface
        .cmd_start  (cmd_start),
        .cmd_write  (cmd_write),
        .cmd_burst  (cmd_burst), // Connected
        .cmd_addr   (cmd_addr),
        .cmd_wdata  (cmd_wdata),
        .cmd_sec    (cmd_sec),
        .cmd_done   (cmd_done),
        .cmd_error  (cmd_error),
        .cmd_rdata  (cmd_rdata)
    );

    // =========================================================================
    // 4. Instantiate the Slave
    // =========================================================================
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