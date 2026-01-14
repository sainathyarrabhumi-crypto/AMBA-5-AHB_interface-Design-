module ahb5_slave_lite (
    // Global Signals
    input wire hclk,
    input wire hresetn,

    // Select & Control Signals
    input wire hsel,
    input wire [31:0] haddr,
    input wire [1:0]  htrans, 
    input wire hwrite,
    input wire [2:0]  hsize, 
    input wire [2:0]  hburst, 
    input wire hready_in,     
    input wire hnonsec,       

    // Data Signals
    input wire [31:0] hwdata,
    output reg [31:0] hrdata,

    // Response Signals
    output reg hreadyout,
    output reg hresp
);

    // --- EXPLODED MEMORY with PRESERVE ATTRIBUTE ---
    // The (* syn_preserve *) tells Design Compiler: 
    // "Keep these registers even if you think they are useless."
    reg [31:0] mem_0;// synopsys preserve
    reg [31:0] mem_1;// synopsys preserve
    reg [31:0] mem_2;// synopsys preserve
    reg [31:0] mem_3;// synopsys preserve

    // --- Pipeline Registers with PRESERVE ---
    // We also protect the control logic so writes are still enabled
     reg [31:0] addr_reg;// synopsys preserve
     reg        write_reg;// synopsys preserve
     reg        valid_trans_reg; // synopsys preserve
    reg        sec_violation_reg; // synopsys preserve

    // --- FSM States ---
    localparam S_OKAY       = 2'b00;
    localparam S_ERROR_WAIT = 2'b01; 
    localparam S_ERROR_DONE = 2'b10; 
    
    reg [1:0] state, next_state;

    // --- 1. ADDRESS PHASE ---
    wire trans_is_valid = hsel && hready_in && htrans[1];// synopsys preserve
    wire current_sec_violation = trans_is_valid && (hnonsec == 1'b1);// synopsys preserve

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

    // --- 2. DATA PHASE ---
    wire enable_write = valid_trans_reg && write_reg && !sec_violation_reg && (state == S_OKAY);
    
    // Wire to extract the 2-bit index from the stored address
    wire [1:0] mem_idx = addr_reg[3:2];

    // WRITE LOGIC
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

    // READ LOGIC
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

    // --- 3. RESPONSE FSM ---
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

   // --- 3. RESPONSE OUTPUT LOGIC ---
    always @(*) begin
        // Default values
        hresp     = 1'b0;
        hreadyout = 1'b1;

        case (state)
            S_OKAY: begin
                // *** THE FIX IS HERE ***
                // If we have a pending violation, we must drive ERROR immediately!
                // We also drive hreadyout=0 to STALL the master so it sees the error.
                if (sec_violation_reg) begin
                    hresp     = 1'b1; // Signal ERROR
                    hreadyout = 1'b0; // EXTEND the cycle (Stall)
                end
                else begin
                    hresp     = 1'b0; // OKAY
                    hreadyout = 1'b1; // Ready
                end
            end

            S_ERROR_WAIT: begin
                hresp     = 1'b1; // ERROR
                hreadyout = 1'b0; // NOT READY (Cycle 1 of Error response)
            end

            S_ERROR_DONE: begin
                hresp     = 1'b1; // ERROR
                hreadyout = 1'b1; // READY (Cycle 2 of Error response - Master captures error now)
            end
            
            default: begin
                hresp     = 1'b0;
                hreadyout = 1'b1;
            end
        endcase
    end

endmodule