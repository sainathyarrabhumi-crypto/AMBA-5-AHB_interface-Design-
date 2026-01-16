module ahb5_slave_lite (
   
    input wire hclk,
    input wire hresetn,


    input wire hsel,
    input wire [31:0] haddr,
    input wire [1:0]  htrans, 
    input wire hwrite,
    input wire [2:0]  hsize, 
    input wire [2:0]  hburst, 
    input wire hready_in,     
    input wire hnonsec,       

  
    input wire [31:0] hwdata,
    output reg [31:0] hrdata,

  
    output reg hreadyout,
    output reg hresp
);

   
    reg [31:0] mem_0;
    reg [31:0] mem_1;
    reg [31:0] mem_2;
    reg [31:0] mem_3;

   
     reg [31:0] addr_reg;
     reg        write_reg;
     reg        valid_trans_reg; 
    reg        sec_violation_reg; 

    
    localparam S_OKAY       = 2'b00;
    localparam S_ERROR_WAIT = 2'b01; 
    localparam S_ERROR_DONE = 2'b10; 
    
    reg [1:0] state, next_state;

 
    wire trans_is_valid = hsel && hready_in && htrans[1];
    wire current_sec_violation = trans_is_valid && (hnonsec == 1'b1);

    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            addr_reg          <= 32'b0;
            write_reg         <= 1'b0;
            valid_trans_reg   <= 1'b0;
            sec_violation_reg <= 1'b0;
        end
        else if (hready_in) begin
            addr_reg          <= haddr;
            write_reg         <= hwrite;
            valid_trans_reg   <= trans_is_valid;
            sec_violation_reg <= current_sec_violation;
        end
    end

    
    wire enable_write = valid_trans_reg && write_reg && !sec_violation_reg && (state == S_OKAY);
    
    wire [1:0] mem_idx = addr_reg[3:2];

   
    always @(posedge hclk) begin
        if (enable_write) begin
            case (mem_idx)
                2'b00: mem_0 <= hwdata;
                2'b01: mem_1 <= hwdata;
                2'b10: mem_2 <= hwdata;
                2'b11: mem_3 <= hwdata;
            endcase
        end
    end

    
    always @(*) begin
        if (valid_trans_reg && !write_reg && !sec_violation_reg) begin
            case (mem_idx)
                2'b00: hrdata = mem_0;
                2'b01: hrdata = mem_1;
                2'b10: hrdata = mem_2;
                2'b11: hrdata = mem_3;
                default: hrdata = 32'b0;
            endcase
        end else begin
            hrdata = 32'b0; 
        end
    end

    
    always @(*) begin
        next_state = state;
        case (state)
            S_OKAY:       if (sec_violation_reg) next_state = S_ERROR_WAIT;
            S_ERROR_WAIT: next_state = S_ERROR_DONE;
            S_ERROR_DONE: next_state = S_OKAY;
        endcase
    end

    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) state <= S_OKAY;
        else          state <= next_state;
    end

  
    always @(*) begin
      
        hresp     = 1'b0;
        hreadyout = 1'b1;

        case (state)
            S_OKAY: begin
               
                if (sec_violation_reg) begin
                    hresp     = 1'b1; 
                    hreadyout = 1'b0; 
                end
                else begin
                    hresp     = 1'b0;
                    hreadyout = 1'b1; 
                end
            end

            S_ERROR_WAIT: begin
                hresp     = 1'b1; 
                hreadyout = 1'b0; 
            end

            S_ERROR_DONE: begin
                hresp     = 1'b1; 
                hreadyout = 1'b1; 
            end
            
            default: begin
                hresp     = 1'b0;
                hreadyout = 1'b1;
            end
        endcase
    end

endmodule
