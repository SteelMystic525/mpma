module scheduler_qos
#(
    parameter ADDR_W = 10,
    parameter DATA_W = 32,
    parameter PRIORITY_W = 2,
    parameter NUM_PORTS = 4,
    parameter STARVATION_THRESHOLD = 30
)
(
    input  clk,
    input  rst_n,
    
    // Configuration
    input  [1:0] arbiter_mode,
    input  [3:0] port_weight_0,
    input  [3:0] port_weight_1,
    input  [3:0] port_weight_2,
    input  [3:0] port_weight_3,
    
    // From ports
    input  [NUM_PORTS-1:0] req_valid,
    input  [NUM_PORTS-1:0] req_wr,
    input  [NUM_PORTS*ADDR_W-1:0] req_addr,
    input  [NUM_PORTS*DATA_W-1:0] req_wdata,
    input  [NUM_PORTS*PRIORITY_W-1:0] req_priority,
    input  [NUM_PORTS*4-1:0] req_burst_len,
    
    // To BRAM
    output reg bram_en,
    output reg bram_wr,
    output reg [ADDR_W-1:0] bram_addr,
    output reg [DATA_W-1:0] bram_wdata,
    
    // From BRAM
    input  [DATA_W-1:0] bram_rdata,
    
    // Back to ports
    output reg [NUM_PORTS-1:0] resp_valid,
    output reg [NUM_PORTS*DATA_W-1:0] resp_rdata,
    output reg [NUM_PORTS-1:0] req_ready,
    
    // Performance monitoring outputs
    output reg [NUM_PORTS-1:0] conflict_flag,
    output reg [1:0] selected_port,
    output reg granted_valid
);

    // Starvation prevention counters
    reg [15:0] wait_cycles_0, wait_cycles_1, wait_cycles_2, wait_cycles_3;
    reg [PRIORITY_W-1:0] boosted_priority_0, boosted_priority_1, boosted_priority_2, boosted_priority_3;
    
    // Round-robin state
    reg [1:0] rr_last_grant;
    
    // Weighted arbitration state
    reg [7:0] weight_credits_0, weight_credits_1, weight_credits_2, weight_credits_3;
    
    // Burst handling
    reg in_burst;
    reg [3:0] burst_count;
    reg [1:0] burst_master;
    reg [ADDR_W-1:0] burst_addr;
    
    // Selected port
    reg [1:0] sel;
    reg sel_valid;
    
    // Extract individual port signals
    wire [ADDR_W-1:0] req_addr_0 = req_addr[0*ADDR_W +: ADDR_W];
    wire [ADDR_W-1:0] req_addr_1 = req_addr[1*ADDR_W +: ADDR_W];
    wire [ADDR_W-1:0] req_addr_2 = req_addr[2*ADDR_W +: ADDR_W];
    wire [ADDR_W-1:0] req_addr_3 = req_addr[3*ADDR_W +: ADDR_W];
    
    wire [DATA_W-1:0] req_wdata_0 = req_wdata[0*DATA_W +: DATA_W];
    wire [DATA_W-1:0] req_wdata_1 = req_wdata[1*DATA_W +: DATA_W];
    wire [DATA_W-1:0] req_wdata_2 = req_wdata[2*DATA_W +: DATA_W];
    wire [DATA_W-1:0] req_wdata_3 = req_wdata[3*DATA_W +: DATA_W];
    
    wire [PRIORITY_W-1:0] req_priority_0 = req_priority[0*PRIORITY_W +: PRIORITY_W];
    wire [PRIORITY_W-1:0] req_priority_1 = req_priority[1*PRIORITY_W +: PRIORITY_W];
    wire [PRIORITY_W-1:0] req_priority_2 = req_priority[2*PRIORITY_W +: PRIORITY_W];
    wire [PRIORITY_W-1:0] req_priority_3 = req_priority[3*PRIORITY_W +: PRIORITY_W];
    
    wire [3:0] req_burst_len_0 = req_burst_len[0*4 +: 4];
    wire [3:0] req_burst_len_1 = req_burst_len[1*4 +: 4];
    wire [3:0] req_burst_len_2 = req_burst_len[2*4 +: 4];
    wire [3:0] req_burst_len_3 = req_burst_len[3*4 +: 4];
    
    // Count number of valid requests (for conflict detection)
    wire [2:0] num_requests = req_valid[0] + req_valid[1] + req_valid[2] + req_valid[3];
    
    // Priority arbitration logic
    reg [1:0] priority_sel;
    always @(*) begin
        if (req_valid[0] && (!req_valid[1] || boosted_priority_0 > boosted_priority_1) &&
                           (!req_valid[2] || boosted_priority_0 > boosted_priority_2) &&
                           (!req_valid[3] || boosted_priority_0 > boosted_priority_3))
            priority_sel = 2'd0;
        else if (req_valid[1] && (!req_valid[2] || boosted_priority_1 > boosted_priority_2) &&
                                (!req_valid[3] || boosted_priority_1 > boosted_priority_3))
            priority_sel = 2'd1;
        else if (req_valid[2] && (!req_valid[3] || boosted_priority_2 > boosted_priority_3))
            priority_sel = 2'd2;
        else
            priority_sel = 2'd3;
    end
    
    // Round-robin arbitration
    reg [1:0] rr_sel;
    always @(*) begin
        case (rr_last_grant)
            2'd0: begin
                if (req_valid[1])      rr_sel = 2'd1;
                else if (req_valid[2]) rr_sel = 2'd2;
                else if (req_valid[3]) rr_sel = 2'd3;
                else                   rr_sel = 2'd0;
            end
            2'd1: begin
                if (req_valid[2])      rr_sel = 2'd2;
                else if (req_valid[3]) rr_sel = 2'd3;
                else if (req_valid[0]) rr_sel = 2'd0;
                else                   rr_sel = 2'd1;
            end
            2'd2: begin
                if (req_valid[3])      rr_sel = 2'd3;
                else if (req_valid[0]) rr_sel = 2'd0;
                else if (req_valid[1]) rr_sel = 2'd1;
                else                   rr_sel = 2'd2;
            end
            2'd3: begin
                if (req_valid[0])      rr_sel = 2'd0;
                else if (req_valid[1]) rr_sel = 2'd1;
                else if (req_valid[2]) rr_sel = 2'd2;
                else                   rr_sel = 2'd3;
            end
        endcase
    end
    
    // Weighted arbitration - pick highest credits among valid
    reg [1:0] weighted_sel;
    always @(*) begin
        weighted_sel = 2'd0;
        if      (req_valid[0] && (!req_valid[1] || weight_credits_0 >= weight_credits_1) &&
                                  (!req_valid[2] || weight_credits_0 >= weight_credits_2) &&
                                  (!req_valid[3] || weight_credits_0 >= weight_credits_3))
            weighted_sel = 2'd0;
        else if (req_valid[1] && (!req_valid[2] || weight_credits_1 >= weight_credits_2) &&
                                  (!req_valid[3] || weight_credits_1 >= weight_credits_3))
            weighted_sel = 2'd1;
        else if (req_valid[2] && (!req_valid[3] || weight_credits_2 >= weight_credits_3))
            weighted_sel = 2'd2;
        else if (req_valid[3])
            weighted_sel = 2'd3;
    end
    
    // Main arbitration logic
    always @(*) begin
        // Detect conflicts
        conflict_flag = (num_requests > 1) ? req_valid : 4'b0000;
        
        // If in burst, continue with same master
        if (in_burst) begin
            sel = burst_master;
            sel_valid = 1'b1;
        end else if (|req_valid) begin
            // Select based on arbitration mode
            case (arbiter_mode)
                2'b00: sel = priority_sel;
                2'b01: sel = rr_sel;
                2'b10: sel = weighted_sel;
                default: sel = 2'b00;
            endcase
            sel_valid = 1'b1;
        end else begin
            sel = 2'b00;
            sel_valid = 1'b0;
        end
    end
    
    // Get selected address and data
    reg [ADDR_W-1:0] selected_addr;
    reg [DATA_W-1:0] selected_wdata;
    reg selected_wr;
    reg [3:0] selected_burst_len;
    
    always @(*) begin
        case (sel)
            2'd0: begin
                selected_addr = req_addr_0;
                selected_wdata = req_wdata_0;
                selected_wr = req_wr[0];
                selected_burst_len = req_burst_len_0;
            end
            2'd1: begin
                selected_addr = req_addr_1;
                selected_wdata = req_wdata_1;
                selected_wr = req_wr[1];
                selected_burst_len = req_burst_len_1;
            end
            2'd2: begin
                selected_addr = req_addr_2;
                selected_wdata = req_wdata_2;
                selected_wr = req_wr[2];
                selected_burst_len = req_burst_len_2;
            end
            2'd3: begin
                selected_addr = req_addr_3;
                selected_wdata = req_wdata_3;
                selected_wr = req_wr[3];
                selected_burst_len = req_burst_len_3;
            end
        endcase
    end
    
    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bram_en <= 1'b0;
            resp_valid <= 4'b0000;
            req_ready <= 4'b0000;
            rr_last_grant <= 2'b00;
            in_burst <= 1'b0;
            burst_count <= 4'b0;
            granted_valid <= 1'b0;
            selected_port <= 2'b00;
            
            wait_cycles_0 <= 16'b0;
            wait_cycles_1 <= 16'b0;
            wait_cycles_2 <= 16'b0;
            wait_cycles_3 <= 16'b0;
            
            boosted_priority_0 <= 2'b00;
            boosted_priority_1 <= 2'b00;
            boosted_priority_2 <= 2'b00;
            boosted_priority_3 <= 2'b00;
            
            weight_credits_0 <= 8'b0;
            weight_credits_1 <= 8'b0;
            weight_credits_2 <= 8'b0;
            weight_credits_3 <= 8'b0;
            
        end else begin
            // Update starvation counters
            if (req_valid[0] && sel != 2'd0) begin
                wait_cycles_0 <= wait_cycles_0 + 1;
                if (wait_cycles_0 > STARVATION_THRESHOLD)
                    boosted_priority_0 <= 2'b11;
                else
                    boosted_priority_0 <= req_priority_0;
            end else begin
                wait_cycles_0 <= 16'b0;
                boosted_priority_0 <= req_priority_0;
            end
            
            if (req_valid[1] && sel != 2'd1) begin
                wait_cycles_1 <= wait_cycles_1 + 1;
                if (wait_cycles_1 > STARVATION_THRESHOLD)
                    boosted_priority_1 <= 2'b11;
                else
                    boosted_priority_1 <= req_priority_1;
            end else begin
                wait_cycles_1 <= 16'b0;
                boosted_priority_1 <= req_priority_1;
            end
            
            if (req_valid[2] && sel != 2'd2) begin
                wait_cycles_2 <= wait_cycles_2 + 1;
                if (wait_cycles_2 > STARVATION_THRESHOLD)
                    boosted_priority_2 <= 2'b11;
                else
                    boosted_priority_2 <= req_priority_2;
            end else begin
                wait_cycles_2 <= 16'b0;
                boosted_priority_2 <= req_priority_2;
            end
            
            if (req_valid[3] && sel != 2'd3) begin
                wait_cycles_3 <= wait_cycles_3 + 1;
                if (wait_cycles_3 > STARVATION_THRESHOLD)
                    boosted_priority_3 <= 2'b11;
                else
                    boosted_priority_3 <= req_priority_3;
            end else begin
                wait_cycles_3 <= 16'b0;
                boosted_priority_3 <= req_priority_3;
            end
            
            // Update weight credits
            // Every cycle: all ports gain credits equal to their weight
            // When selected: that port pays a fixed cost (16)
            // This naturally produces bandwidth ratio equal to weight ratio
            if (arbiter_mode == 2'b10) begin
                if (sel_valid && sel == 2'd0)
                    weight_credits_0 <= weight_credits_0 + port_weight_0 - 8'd16;
                else
                    weight_credits_0 <= weight_credits_0 + port_weight_0;
                    
                if (sel_valid && sel == 2'd1)
                    weight_credits_1 <= weight_credits_1 + port_weight_1 - 8'd16;
                else
                    weight_credits_1 <= weight_credits_1 + port_weight_1;
                    
                if (sel_valid && sel == 2'd2)
                    weight_credits_2 <= weight_credits_2 + port_weight_2 - 8'd16;
                else
                    weight_credits_2 <= weight_credits_2 + port_weight_2;
                    
                if (sel_valid && sel == 2'd3)
                    weight_credits_3 <= weight_credits_3 + port_weight_3 - 8'd16;
                else
                    weight_credits_3 <= weight_credits_3 + port_weight_3;
            end
            
            // Handle burst transactions
            if (in_burst) begin
                burst_count <= burst_count - 1;
                burst_addr <= burst_addr + 1;
                if (burst_count == 1)
                    in_burst <= 1'b0;
            end else if (sel_valid && selected_burst_len > 0) begin
                in_burst <= 1'b1;
                burst_count <= selected_burst_len;
                burst_master <= sel;
                burst_addr <= selected_addr + 1;
            end
            
            // Generate BRAM control signals
            bram_en <= sel_valid;
            if (sel_valid) begin
                bram_wr <= selected_wr;
                if (in_burst)
                    bram_addr <= burst_addr;
                else
                    bram_addr <= selected_addr;
                bram_wdata <= selected_wdata;
            end
            
            // Generate response (1 cycle delay for BRAM read)
            resp_valid <= bram_en ? (4'b0001 << sel) : 4'b0000;
            resp_rdata <= {bram_rdata, bram_rdata, bram_rdata, bram_rdata};
            
            // Credit return (ready signal)
            req_ready <= bram_en ? (4'b0001 << sel) : 4'b0000;
            
            // Update round-robin state
            if (sel_valid && arbiter_mode == 2'b01)
                rr_last_grant <= sel;
            
            // Monitoring outputs
            granted_valid <= sel_valid;
            selected_port <= sel;
        end
    end

endmodule