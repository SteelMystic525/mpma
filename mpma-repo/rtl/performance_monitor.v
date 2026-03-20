module performance_monitor
#(
    parameter NUM_PORTS = 4,
    parameter DATA_W = 32
)
(
    input  clk,
    input  rst_n,
    
    // Control
    input  reset_counters,
    
    // From ports (requests)
    input  [NUM_PORTS-1:0] req_valid,
    input  [NUM_PORTS-1:0] req_accepted,
    
    // From scheduler
    input  [NUM_PORTS-1:0] resp_valid,
    input  [NUM_PORTS-1:0] conflict_flag,
    input  granted_valid,
    input  [1:0] selected_port,
    
    // Performance metrics outputs (32-bit registers)
    output reg [31:0] total_cycles,
    output reg [31:0] active_cycles,
    
    // Per-port metrics
    output reg [31:0] transaction_count_0,
    output reg [31:0] transaction_count_1,
    output reg [31:0] transaction_count_2,
    output reg [31:0] transaction_count_3,
    
    output reg [31:0] total_latency_0,
    output reg [31:0] total_latency_1,
    output reg [31:0] total_latency_2,
    output reg [31:0] total_latency_3,
    
    output reg [31:0] conflict_count_0,
    output reg [31:0] conflict_count_1,
    output reg [31:0] conflict_count_2,
    output reg [31:0] conflict_count_3,
    
    output reg [31:0] stall_cycles_0,
    output reg [31:0] stall_cycles_1,
    output reg [31:0] stall_cycles_2,
    output reg [31:0] stall_cycles_3,
    
    // Derived metrics
    output reg [31:0] memory_utilization_percent,
    output reg [31:0] avg_latency_0,
    output reg [31:0] avg_latency_1,
    output reg [31:0] avg_latency_2,
    output reg [31:0] avg_latency_3
);

    // Latency tracking: timestamp when request is made
    reg [31:0] request_timestamp_0, request_timestamp_1, request_timestamp_2, request_timestamp_3;
    reg request_pending_0, request_pending_1, request_pending_2, request_pending_3;
    
    // Cycle counter
    reg [31:0] cycle_count;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || reset_counters) begin
            total_cycles <= 32'b0;
            active_cycles <= 32'b0;
            cycle_count <= 32'b0;
            memory_utilization_percent <= 32'b0;
            
            transaction_count_0 <= 32'b0;
            transaction_count_1 <= 32'b0;
            transaction_count_2 <= 32'b0;
            transaction_count_3 <= 32'b0;
            
            total_latency_0 <= 32'b0;
            total_latency_1 <= 32'b0;
            total_latency_2 <= 32'b0;
            total_latency_3 <= 32'b0;
            
            conflict_count_0 <= 32'b0;
            conflict_count_1 <= 32'b0;
            conflict_count_2 <= 32'b0;
            conflict_count_3 <= 32'b0;
            
            stall_cycles_0 <= 32'b0;
            stall_cycles_1 <= 32'b0;
            stall_cycles_2 <= 32'b0;
            stall_cycles_3 <= 32'b0;
            
            avg_latency_0 <= 32'b0;
            avg_latency_1 <= 32'b0;
            avg_latency_2 <= 32'b0;
            avg_latency_3 <= 32'b0;
            
            request_timestamp_0 <= 32'b0;
            request_timestamp_1 <= 32'b0;
            request_timestamp_2 <= 32'b0;
            request_timestamp_3 <= 32'b0;
            
            request_pending_0 <= 1'b0;
            request_pending_1 <= 1'b0;
            request_pending_2 <= 1'b0;
            request_pending_3 <= 1'b0;
            
        end else begin
            // Increment cycle counters
            cycle_count <= cycle_count + 1;
            total_cycles <= total_cycles + 1;
            
            // Track active cycles
            if (granted_valid)
                active_cycles <= active_cycles + 1;
            
            // Port 0 tracking
            if (req_valid[0] && !request_pending_0) begin
                request_timestamp_0 <= cycle_count;
                request_pending_0 <= 1'b1;
            end
            if (resp_valid[0] && request_pending_0) begin
                transaction_count_0 <= transaction_count_0 + 1;
                total_latency_0 <= total_latency_0 + (cycle_count - request_timestamp_0);
                request_pending_0 <= 1'b0;
            end
            if (conflict_flag[0])
                conflict_count_0 <= conflict_count_0 + 1;
            if (req_valid[0] && !req_accepted[0])
                stall_cycles_0 <= stall_cycles_0 + 1;
            if (transaction_count_0 > 0)
                avg_latency_0 <= total_latency_0 / transaction_count_0;
            
            // Port 1 tracking
            if (req_valid[1] && !request_pending_1) begin
                request_timestamp_1 <= cycle_count;
                request_pending_1 <= 1'b1;
            end
            if (resp_valid[1] && request_pending_1) begin
                transaction_count_1 <= transaction_count_1 + 1;
                total_latency_1 <= total_latency_1 + (cycle_count - request_timestamp_1);
                request_pending_1 <= 1'b0;
            end
            if (conflict_flag[1])
                conflict_count_1 <= conflict_count_1 + 1;
            if (req_valid[1] && !req_accepted[1])
                stall_cycles_1 <= stall_cycles_1 + 1;
            if (transaction_count_1 > 0)
                avg_latency_1 <= total_latency_1 / transaction_count_1;
            
            // Port 2 tracking
            if (req_valid[2] && !request_pending_2) begin
                request_timestamp_2 <= cycle_count;
                request_pending_2 <= 1'b1;
            end
            if (resp_valid[2] && request_pending_2) begin
                transaction_count_2 <= transaction_count_2 + 1;
                total_latency_2 <= total_latency_2 + (cycle_count - request_timestamp_2);
                request_pending_2 <= 1'b0;
            end
            if (conflict_flag[2])
                conflict_count_2 <= conflict_count_2 + 1;
            if (req_valid[2] && !req_accepted[2])
                stall_cycles_2 <= stall_cycles_2 + 1;
            if (transaction_count_2 > 0)
                avg_latency_2 <= total_latency_2 / transaction_count_2;
            
            // Port 3 tracking
            if (req_valid[3] && !request_pending_3) begin
                request_timestamp_3 <= cycle_count;
                request_pending_3 <= 1'b1;
            end
            if (resp_valid[3] && request_pending_3) begin
                transaction_count_3 <= transaction_count_3 + 1;
                total_latency_3 <= total_latency_3 + (cycle_count - request_timestamp_3);
                request_pending_3 <= 1'b0;
            end
            if (conflict_flag[3])
                conflict_count_3 <= conflict_count_3 + 1;
            if (req_valid[3] && !req_accepted[3])
                stall_cycles_3 <= stall_cycles_3 + 1;
            if (transaction_count_3 > 0)
                avg_latency_3 <= total_latency_3 / transaction_count_3;
            
            // Calculate memory utilization percentage
            if (total_cycles > 0)
                memory_utilization_percent <= (active_cycles * 100) / total_cycles;
        end
    end

endmodule