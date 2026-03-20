module port_if_enhanced
#(
    parameter ADDR_W = 10,
    parameter DATA_W = 32,
    parameter FIFO_DEPTH = 8,
    parameter PRIORITY_W = 2,
    parameter PTR_WIDTH = 4  // log2(FIFO_DEPTH) + 1
)
(
    input  clk,
    input  rst_n,
    
    // External port interface
    input  port_en,
    input  port_wr,
    input  [ADDR_W-1:0] port_addr,
    input  [DATA_W-1:0] port_wdata,
    input  [PRIORITY_W-1:0] port_priority,
    input  [3:0] port_burst_len,
    output reg [DATA_W-1:0] port_rdata,
    output reg port_ready,
    
    // To scheduler
    output reg req_valid,
    output reg req_wr,
    output reg [ADDR_W-1:0] req_addr,
    output reg [DATA_W-1:0] req_wdata,
    output reg [PRIORITY_W-1:0] req_priority,
    output reg [3:0] req_burst_len,
    
    // From scheduler
    input  resp_valid,
    input  [DATA_W-1:0] resp_rdata,
    input  req_ready
);

    // FIFO storage - use generate for arrays
    reg [ADDR_W-1:0] fifo_addr_0, fifo_addr_1, fifo_addr_2, fifo_addr_3;
    reg [ADDR_W-1:0] fifo_addr_4, fifo_addr_5, fifo_addr_6, fifo_addr_7;
    
    reg [DATA_W-1:0] fifo_wdata_0, fifo_wdata_1, fifo_wdata_2, fifo_wdata_3;
    reg [DATA_W-1:0] fifo_wdata_4, fifo_wdata_5, fifo_wdata_6, fifo_wdata_7;
    
    reg [PRIORITY_W-1:0] fifo_priority_0, fifo_priority_1, fifo_priority_2, fifo_priority_3;
    reg [PRIORITY_W-1:0] fifo_priority_4, fifo_priority_5, fifo_priority_6, fifo_priority_7;
    
    reg [3:0] fifo_burst_len_0, fifo_burst_len_1, fifo_burst_len_2, fifo_burst_len_3;
    reg [3:0] fifo_burst_len_4, fifo_burst_len_5, fifo_burst_len_6, fifo_burst_len_7;
    
    reg fifo_wr_0, fifo_wr_1, fifo_wr_2, fifo_wr_3;
    reg fifo_wr_4, fifo_wr_5, fifo_wr_6, fifo_wr_7;
    
    // FIFO pointers
    reg [PTR_WIDTH-1:0] wr_ptr;
    reg [PTR_WIDTH-1:0] rd_ptr;
    
    wire [2:0] wr_addr;
    wire [2:0] rd_addr;
    assign wr_addr = wr_ptr[2:0];
    assign rd_addr = rd_ptr[2:0];
    
    // FIFO status
    wire fifo_full;
    wire fifo_empty;
    assign fifo_full = (wr_ptr[PTR_WIDTH-1] != rd_ptr[PTR_WIDTH-1]) && (wr_addr == rd_addr);
    assign fifo_empty = (wr_ptr == rd_ptr);
    
    // Current FIFO head values (for reading)
    reg [ADDR_W-1:0] current_addr;
    reg [DATA_W-1:0] current_wdata;
    reg [PRIORITY_W-1:0] current_priority;
    reg [3:0] current_burst_len;
    reg current_wr;
    
    // Read FIFO head based on rd_addr
    always @(*) begin
        case (rd_addr)
            3'd0: begin
                current_addr = fifo_addr_0;
                current_wdata = fifo_wdata_0;
                current_priority = fifo_priority_0;
                current_burst_len = fifo_burst_len_0;
                current_wr = fifo_wr_0;
            end
            3'd1: begin
                current_addr = fifo_addr_1;
                current_wdata = fifo_wdata_1;
                current_priority = fifo_priority_1;
                current_burst_len = fifo_burst_len_1;
                current_wr = fifo_wr_1;
            end
            3'd2: begin
                current_addr = fifo_addr_2;
                current_wdata = fifo_wdata_2;
                current_priority = fifo_priority_2;
                current_burst_len = fifo_burst_len_2;
                current_wr = fifo_wr_2;
            end
            3'd3: begin
                current_addr = fifo_addr_3;
                current_wdata = fifo_wdata_3;
                current_priority = fifo_priority_3;
                current_burst_len = fifo_burst_len_3;
                current_wr = fifo_wr_3;
            end
            3'd4: begin
                current_addr = fifo_addr_4;
                current_wdata = fifo_wdata_4;
                current_priority = fifo_priority_4;
                current_burst_len = fifo_burst_len_4;
                current_wr = fifo_wr_4;
            end
            3'd5: begin
                current_addr = fifo_addr_5;
                current_wdata = fifo_wdata_5;
                current_priority = fifo_priority_5;
                current_burst_len = fifo_burst_len_5;
                current_wr = fifo_wr_5;
            end
            3'd6: begin
                current_addr = fifo_addr_6;
                current_wdata = fifo_wdata_6;
                current_priority = fifo_priority_6;
                current_burst_len = fifo_burst_len_6;
                current_wr = fifo_wr_6;
            end
            3'd7: begin
                current_addr = fifo_addr_7;
                current_wdata = fifo_wdata_7;
                current_priority = fifo_priority_7;
                current_burst_len = fifo_burst_len_7;
                current_wr = fifo_wr_7;
            end
        endcase
    end
    
    // FIFO write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            port_ready <= 1'b1;
        end else begin
            // Write to FIFO when port_en and space available
            if (port_en && !fifo_full) begin
                case (wr_addr)
                    3'd0: begin
                        fifo_addr_0 <= port_addr;
                        fifo_wdata_0 <= port_wdata;
                        fifo_priority_0 <= port_priority;
                        fifo_burst_len_0 <= port_burst_len;
                        fifo_wr_0 <= port_wr;
                    end
                    3'd1: begin
                        fifo_addr_1 <= port_addr;
                        fifo_wdata_1 <= port_wdata;
                        fifo_priority_1 <= port_priority;
                        fifo_burst_len_1 <= port_burst_len;
                        fifo_wr_1 <= port_wr;
                    end
                    3'd2: begin
                        fifo_addr_2 <= port_addr;
                        fifo_wdata_2 <= port_wdata;
                        fifo_priority_2 <= port_priority;
                        fifo_burst_len_2 <= port_burst_len;
                        fifo_wr_2 <= port_wr;
                    end
                    3'd3: begin
                        fifo_addr_3 <= port_addr;
                        fifo_wdata_3 <= port_wdata;
                        fifo_priority_3 <= port_priority;
                        fifo_burst_len_3 <= port_burst_len;
                        fifo_wr_3 <= port_wr;
                    end
                    3'd4: begin
                        fifo_addr_4 <= port_addr;
                        fifo_wdata_4 <= port_wdata;
                        fifo_priority_4 <= port_priority;
                        fifo_burst_len_4 <= port_burst_len;
                        fifo_wr_4 <= port_wr;
                    end
                    3'd5: begin
                        fifo_addr_5 <= port_addr;
                        fifo_wdata_5 <= port_wdata;
                        fifo_priority_5 <= port_priority;
                        fifo_burst_len_5 <= port_burst_len;
                        fifo_wr_5 <= port_wr;
                    end
                    3'd6: begin
                        fifo_addr_6 <= port_addr;
                        fifo_wdata_6 <= port_wdata;
                        fifo_priority_6 <= port_priority;
                        fifo_burst_len_6 <= port_burst_len;
                        fifo_wr_6 <= port_wr;
                    end
                    3'd7: begin
                        fifo_addr_7 <= port_addr;
                        fifo_wdata_7 <= port_wdata;
                        fifo_priority_7 <= port_priority;
                        fifo_burst_len_7 <= port_burst_len;
                        fifo_wr_7 <= port_wr;
                    end
                endcase
                wr_ptr <= wr_ptr + 1;
            end
            
            // Read from FIFO when scheduler is ready and FIFO not empty
            if (req_ready && !fifo_empty) begin
                rd_ptr <= rd_ptr + 1;
            end
            
            // Update ready signal
            port_ready <= !fifo_full;
        end
    end
    
    // Output request from FIFO head
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_valid <= 1'b0;
            req_wr <= 1'b0;
            req_addr <= {ADDR_W{1'b0}};
            req_wdata <= {DATA_W{1'b0}};
            req_priority <= {PRIORITY_W{1'b0}};
            req_burst_len <= 4'b0;
            port_rdata <= {DATA_W{1'b0}};
        end else begin
            // Present FIFO head to scheduler
            if (!fifo_empty) begin
                req_valid <= 1'b1;
                req_wr <= current_wr;
                req_addr <= current_addr;
                req_wdata <= current_wdata;
                req_priority <= current_priority;
                req_burst_len <= current_burst_len;
            end else begin
                req_valid <= 1'b0;
            end
            
            // Capture response
            if (resp_valid)
                port_rdata <= resp_rdata;
        end
    end

endmodule