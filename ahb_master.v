module ahb5_master_lite (
  
    input wire hclk,
    input wire hresetn,
    output reg  [31:0] haddr,
    output reg  [1:0]  htrans, 
    output reg         hwrite, 
    output reg  [31:0] hwdata,
    output reg  [2:0]  hsize,  
    output reg  [2:0]  hburst, 
    output reg         hnonsec,
    output wire        hmastlock,

    
    input wire [31:0] hrdata,
    input wire        hready,  
    input wire        hresp,   

   
    input wire        cmd_start, 
    input wire        cmd_write, 
    input wire        cmd_burst,
    input wire [31:0] cmd_addr,  
    input wire [31:0] cmd_wdata, 
    input wire        cmd_sec,   
    
    output reg        cmd_done,  
    output reg        cmd_error, 
    output reg [31:0] cmd_rdata  
);

    assign hmastlock = 1'b0;

    
    localparam S_IDLE        = 2'b00;
    localparam S_ADDR_PHASE  = 2'b01;
    localparam S_BURST_PHASE = 2'b10; 
    localparam S_DATA_PHASE  = 2'b11;

    reg [1:0] state, next_state;

    
    reg [31:0] wdata_reg; 
    reg [31:0] addr_reg;  
    reg        write_reg; 
    
   
    reg [1:0]  beat_cnt;  
    reg        is_burst;  

  
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (cmd_start) 
                    next_state = S_ADDR_PHASE;
            end

            S_ADDR_PHASE: begin
                if (hready) begin
                   
                    if (is_burst) 
                        next_state = S_BURST_PHASE;
                    else
                        next_state = S_DATA_PHASE; 
                end
            end

            S_BURST_PHASE: begin
                if (hready) begin
                    
                    if (beat_cnt > 0)
                        next_state = S_BURST_PHASE;
                    else
                        next_state = S_DATA_PHASE;
                end
            end

            S_DATA_PHASE: begin
                if (hready) 
                    next_state = S_IDLE;
            end
        endcase
    end

 
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            state      <= S_IDLE;
            wdata_reg  <= 0;
            addr_reg   <= 0;
            write_reg  <= 0;
            is_burst   <= 0;
            beat_cnt   <= 0;
            cmd_done   <= 0;
            cmd_error  <= 0;
            cmd_rdata  <= 0;
        end
        else begin
            cmd_done <= 0;
            
            if (hready || state == S_IDLE) 
                state <= next_state;

            
            if (state == S_IDLE && cmd_start) begin
                wdata_reg <= cmd_wdata;
                addr_reg  <= cmd_addr;
                write_reg <= cmd_write;
                is_burst  <= cmd_burst;
                beat_cnt  <= (cmd_burst) ? 2'd2 : 2'd0; 
                cmd_error <= 0; 
            end
            else if (hready && state == S_BURST_PHASE) begin
               
                wdata_reg <= wdata_reg + 1;
                addr_reg  <= addr_reg + 4;
                if (beat_cnt > 0) beat_cnt <= beat_cnt - 1;
            end
            
       
            if (hready && (state == S_DATA_PHASE || state == S_BURST_PHASE)) begin
                if (hresp) cmd_error <= 1;
                if (!write_reg) cmd_rdata <= hrdata;
                
              
                if (state == S_DATA_PHASE) cmd_done <= 1; 
            end
        end
    end


    always @(*) begin
    
        haddr   = 32'b0;
        htrans  = 2'b00; 
        hwrite  = 1'b0;
        hnonsec = 1'b0;
        hwdata  = 32'b0;
        hburst  = 3'b000;
        hsize   = 3'b010;

        case (state)
            S_IDLE: begin
                htrans = 2'b00; 
            end

            S_ADDR_PHASE: begin

                haddr   = addr_reg;   
                htrans  = 2'b10; 
                hwrite  = write_reg;
                hnonsec = cmd_sec;    
                hburst  = (is_burst) ? 3'b011 : 3'b000;
            end

            S_BURST_PHASE: begin
              
                
                if (write_reg) hwdata = wdata_reg;

               
                haddr   = addr_reg + 4; 
                htrans  = 2'b11; 
                hwrite  = write_reg;
                hnonsec = cmd_sec;
                hburst  = 3'b011;
            end

            S_DATA_PHASE: begin
                htrans = 2'b00; 
                
             
                if (write_reg) hwdata = wdata_reg;
            end
        endcase
    end

endmodule
