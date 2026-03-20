module config_registers
#(
    parameter ADDR_W = 10,
    parameter DATA_W = 32,
    parameter NUM_PORTS = 4,
    parameter BASE_ADDR = 10'h300
)
(
    input  clk,
    input  rst_n,
    
    // Register access interface
    input  reg_en,
    input  reg_wr,
    input  [ADDR_W-1:0] reg_addr,
    input  [DATA_W-1:0] reg_wdata,
    output reg [DATA_W-1:0] reg_rdata,
    
    // Configuration outputs to scheduler
    output reg [1:0] arbiter_mode,
    output reg [3:0] port_weight_0,
    output reg [3:0] port_weight_1,
    output reg [3:0] port_weight_2,
    output reg [3:0] port_weight_3,
    output reg [1:0] port_priority_0,
    output reg [1:0] port_priority_1,
    output reg [1:0] port_priority_2,
    output reg [1:0] port_priority_3,
    
    // Performance counter inputs
    input  [31:0] total_cycles,
    input  [31:0] active_cycles,
    input  [31:0] transaction_count_0,
    input  [31:0] transaction_count_1,
    input  [31:0] transaction_count_2,
    input  [31:0] transaction_count_3,
    input  [31:0] avg_latency_0,
    input  [31:0] avg_latency_1,
    input  [31:0] avg_latency_2,
    input  [31:0] avg_latency_3,
    input  [31:0] conflict_count_0,
    input  [31:0] conflict_count_1,
    input  [31:0] conflict_count_2,
    input  [31:0] conflict_count_3,
    input  [31:0] stall_cycles_0,
    input  [31:0] stall_cycles_1,
    input  [31:0] stall_cycles_2,
    input  [31:0] stall_cycles_3,
    input  [31:0] memory_utilization_percent,
    
    // Control outputs
    output reg reset_counters
);

    wire [ADDR_W-1:0] offset;
    wire is_config_access;
    
    assign offset = reg_addr - BASE_ADDR;
    assign is_config_access = reg_en && (reg_addr >= BASE_ADDR) && (reg_addr < BASE_ADDR + 10'h80);
    
    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arbiter_mode <= 2'b00;
            reset_counters <= 1'b0;
            port_weight_0 <= 4'b0001;
            port_weight_1 <= 4'b0001;
            port_weight_2 <= 4'b0001;
            port_weight_3 <= 4'b0001;
            port_priority_0 <= 2'b00;
            port_priority_1 <= 2'b01;
            port_priority_2 <= 2'b10;
            port_priority_3 <= 2'b11;
        end else begin
            reset_counters <= 1'b0;
            
            if (is_config_access && reg_wr) begin
                case (offset)
                    10'h00: arbiter_mode <= reg_wdata[1:0];
                    10'h04: port_priority_0 <= reg_wdata[1:0];
                    10'h08: port_priority_1 <= reg_wdata[1:0];
                    10'h0C: port_priority_2 <= reg_wdata[1:0];
                    10'h10: port_priority_3 <= reg_wdata[1:0];
                    10'h14: port_weight_0 <= reg_wdata[3:0];
                    10'h18: port_weight_1 <= reg_wdata[3:0];
                    10'h1C: port_weight_2 <= reg_wdata[3:0];
                    10'h20: port_weight_3 <= reg_wdata[3:0];
                    10'h24: reset_counters <= reg_wdata[0];
                    default: ;
                endcase
            end
        end
    end
    
    // Read logic
    always @(*) begin
        reg_rdata = 32'h00000000;
        
        if (is_config_access && !reg_wr) begin
            case (offset)
                10'h00: reg_rdata = {30'b0, arbiter_mode};
                10'h04: reg_rdata = {30'b0, port_priority_0};
                10'h08: reg_rdata = {30'b0, port_priority_1};
                10'h0C: reg_rdata = {30'b0, port_priority_2};
                10'h10: reg_rdata = {30'b0, port_priority_3};
                10'h14: reg_rdata = {28'b0, port_weight_0};
                10'h18: reg_rdata = {28'b0, port_weight_1};
                10'h1C: reg_rdata = {28'b0, port_weight_2};
                10'h20: reg_rdata = {28'b0, port_weight_3};
                10'h24: reg_rdata = 32'h00000000;
                
                10'h28: reg_rdata = total_cycles;
                10'h2C: reg_rdata = active_cycles;
                10'h30: reg_rdata = memory_utilization_percent;
                
                10'h40: reg_rdata = transaction_count_0;
                10'h44: reg_rdata = transaction_count_1;
                10'h48: reg_rdata = transaction_count_2;
                10'h4C: reg_rdata = transaction_count_3;
                
                10'h50: reg_rdata = avg_latency_0;
                10'h54: reg_rdata = avg_latency_1;
                10'h58: reg_rdata = avg_latency_2;
                10'h5C: reg_rdata = avg_latency_3;
                
                10'h60: reg_rdata = conflict_count_0;
                10'h64: reg_rdata = conflict_count_1;
                10'h68: reg_rdata = conflict_count_2;
                10'h6C: reg_rdata = conflict_count_3;
                
                10'h70: reg_rdata = stall_cycles_0;
                10'h74: reg_rdata = stall_cycles_1;
                10'h78: reg_rdata = stall_cycles_2;
                10'h7C: reg_rdata = stall_cycles_3;
                
                default: reg_rdata = 32'hDEADBEEF;
            endcase
        end
    end

endmodule