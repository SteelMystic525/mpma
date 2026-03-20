module memory_system_top
#(
    parameter ADDR_W = 10,
    parameter DATA_W = 32,
    parameter NUM_PORTS = 4,
    parameter FIFO_DEPTH = 8,
    parameter PRIORITY_W = 2
)
(
    input  clk,
    input  rst_n,
    
    // Port 0 interface
    input  port0_en,
    input  port0_wr,
    input  [ADDR_W-1:0] port0_addr,
    input  [DATA_W-1:0] port0_wdata,
    input  [PRIORITY_W-1:0] port0_priority,
    input  [3:0] port0_burst_len,
    output [DATA_W-1:0] port0_rdata,
    output port0_ready,
    
    // Port 1 interface
    input  port1_en,
    input  port1_wr,
    input  [ADDR_W-1:0] port1_addr,
    input  [DATA_W-1:0] port1_wdata,
    input  [PRIORITY_W-1:0] port1_priority,
    input  [3:0] port1_burst_len,
    output [DATA_W-1:0] port1_rdata,
    output port1_ready,
    
    // Port 2 interface
    input  port2_en,
    input  port2_wr,
    input  [ADDR_W-1:0] port2_addr,
    input  [DATA_W-1:0] port2_wdata,
    input  [PRIORITY_W-1:0] port2_priority,
    input  [3:0] port2_burst_len,
    output [DATA_W-1:0] port2_rdata,
    output port2_ready,
    
    // Port 3 interface
    input  port3_en,
    input  port3_wr,
    input  [ADDR_W-1:0] port3_addr,
    input  [DATA_W-1:0] port3_wdata,
    input  [PRIORITY_W-1:0] port3_priority,
    input  [3:0] port3_burst_len,
    output [DATA_W-1:0] port3_rdata,
    output port3_ready,
    
    // Configuration interface
    input  cfg_en,
    input  cfg_wr,
    input  [ADDR_W-1:0] cfg_addr,
    input  [DATA_W-1:0] cfg_wdata,
    output [DATA_W-1:0] cfg_rdata
);

    // Internal signals
    wire [NUM_PORTS-1:0] req_valid;
    wire [NUM_PORTS-1:0] req_wr;
    wire [NUM_PORTS*ADDR_W-1:0] req_addr;
    wire [NUM_PORTS*DATA_W-1:0] req_wdata;
    wire [NUM_PORTS*PRIORITY_W-1:0] req_priority;
    wire [NUM_PORTS*4-1:0] req_burst_len;
    
    wire [NUM_PORTS-1:0] resp_valid;
    wire [NUM_PORTS*DATA_W-1:0] resp_rdata;
    wire [NUM_PORTS-1:0] req_ready;
    
    wire bram_en;
    wire bram_wr;
    wire [ADDR_W-1:0] bram_addr;
    wire [DATA_W-1:0] bram_wdata;
    wire [DATA_W-1:0] bram_rdata;
    
    // Configuration signals
    wire [1:0] arbiter_mode;
    wire [3:0] port_weight_0, port_weight_1, port_weight_2, port_weight_3;
    wire [1:0] port_priority_0, port_priority_1, port_priority_2, port_priority_3;
    wire reset_counters;
    
    // Performance monitoring signals
    wire [NUM_PORTS-1:0] conflict_flag;
    wire [1:0] selected_port;
    wire granted_valid;
    
    wire [31:0] total_cycles;
    wire [31:0] active_cycles;
    wire [31:0] transaction_count_0, transaction_count_1, transaction_count_2, transaction_count_3;
    wire [31:0] avg_latency_0, avg_latency_1, avg_latency_2, avg_latency_3;
    wire [31:0] conflict_count_0, conflict_count_1, conflict_count_2, conflict_count_3;
    wire [31:0] stall_cycles_0, stall_cycles_1, stall_cycles_2, stall_cycles_3;
    wire [31:0] memory_utilization_percent;
    
    // Port 0 Interface
    port_if_enhanced #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),
        .FIFO_DEPTH(FIFO_DEPTH),
        .PRIORITY_W(PRIORITY_W)
    ) port0_if (
        .clk(clk),
        .rst_n(rst_n),
        .port_en(port0_en),
        .port_wr(port0_wr),
        .port_addr(port0_addr),
        .port_wdata(port0_wdata),
        .port_priority(port0_priority),
        .port_burst_len(port0_burst_len),
        .port_rdata(port0_rdata),
        .port_ready(port0_ready),
        .req_valid(req_valid[0]),
        .req_wr(req_wr[0]),
        .req_addr(req_addr[0*ADDR_W +: ADDR_W]),
        .req_wdata(req_wdata[0*DATA_W +: DATA_W]),
        .req_priority(req_priority[0*PRIORITY_W +: PRIORITY_W]),
        .req_burst_len(req_burst_len[0*4 +: 4]),
        .resp_valid(resp_valid[0]),
        .resp_rdata(resp_rdata[0*DATA_W +: DATA_W]),
        .req_ready(req_ready[0])
    );
    
    // Port 1 Interface
    port_if_enhanced #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),
        .FIFO_DEPTH(FIFO_DEPTH),
        .PRIORITY_W(PRIORITY_W)
    ) port1_if (
        .clk(clk),
        .rst_n(rst_n),
        .port_en(port1_en),
        .port_wr(port1_wr),
        .port_addr(port1_addr),
        .port_wdata(port1_wdata),
        .port_priority(port1_priority),
        .port_burst_len(port1_burst_len),
        .port_rdata(port1_rdata),
        .port_ready(port1_ready),
        .req_valid(req_valid[1]),
        .req_wr(req_wr[1]),
        .req_addr(req_addr[1*ADDR_W +: ADDR_W]),
        .req_wdata(req_wdata[1*DATA_W +: DATA_W]),
        .req_priority(req_priority[1*PRIORITY_W +: PRIORITY_W]),
        .req_burst_len(req_burst_len[1*4 +: 4]),
        .resp_valid(resp_valid[1]),
        .resp_rdata(resp_rdata[1*DATA_W +: DATA_W]),
        .req_ready(req_ready[1])
    );
    
    // Port 2 Interface
    port_if_enhanced #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),
        .FIFO_DEPTH(FIFO_DEPTH),
        .PRIORITY_W(PRIORITY_W)
    ) port2_if (
        .clk(clk),
        .rst_n(rst_n),
        .port_en(port2_en),
        .port_wr(port2_wr),
        .port_addr(port2_addr),
        .port_wdata(port2_wdata),
        .port_priority(port2_priority),
        .port_burst_len(port2_burst_len),
        .port_rdata(port2_rdata),
        .port_ready(port2_ready),
        .req_valid(req_valid[2]),
        .req_wr(req_wr[2]),
        .req_addr(req_addr[2*ADDR_W +: ADDR_W]),
        .req_wdata(req_wdata[2*DATA_W +: DATA_W]),
        .req_priority(req_priority[2*PRIORITY_W +: PRIORITY_W]),
        .req_burst_len(req_burst_len[2*4 +: 4]),
        .resp_valid(resp_valid[2]),
        .resp_rdata(resp_rdata[2*DATA_W +: DATA_W]),
        .req_ready(req_ready[2])
    );
    
    // Port 3 Interface
    port_if_enhanced #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),
        .FIFO_DEPTH(FIFO_DEPTH),
        .PRIORITY_W(PRIORITY_W)
    ) port3_if (
        .clk(clk),
        .rst_n(rst_n),
        .port_en(port3_en),
        .port_wr(port3_wr),
        .port_addr(port3_addr),
        .port_wdata(port3_wdata),
        .port_priority(port3_priority),
        .port_burst_len(port3_burst_len),
        .port_rdata(port3_rdata),
        .port_ready(port3_ready),
        .req_valid(req_valid[3]),
        .req_wr(req_wr[3]),
        .req_addr(req_addr[3*ADDR_W +: ADDR_W]),
        .req_wdata(req_wdata[3*DATA_W +: DATA_W]),
        .req_priority(req_priority[3*PRIORITY_W +: PRIORITY_W]),
        .req_burst_len(req_burst_len[3*4 +: 4]),
        .resp_valid(resp_valid[3]),
        .resp_rdata(resp_rdata[3*DATA_W +: DATA_W]),
        .req_ready(req_ready[3])
    );
    
    // Scheduler with QoS
    scheduler_qos #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),
        .PRIORITY_W(PRIORITY_W),
        .NUM_PORTS(NUM_PORTS)
    ) scheduler (
        .clk(clk),
        .rst_n(rst_n),
        .arbiter_mode(arbiter_mode),
        .port_weight_0(port_weight_0),
        .port_weight_1(port_weight_1),
        .port_weight_2(port_weight_2),
        .port_weight_3(port_weight_3),
        .req_valid(req_valid),
        .req_wr(req_wr),
        .req_addr(req_addr),
        .req_wdata(req_wdata),
        .req_priority(req_priority),
        .req_burst_len(req_burst_len),
        .bram_en(bram_en),
        .bram_wr(bram_wr),
        .bram_addr(bram_addr),
        .bram_wdata(bram_wdata),
        .bram_rdata(bram_rdata),
        .resp_valid(resp_valid),
        .resp_rdata(resp_rdata),
        .req_ready(req_ready),
        .conflict_flag(conflict_flag),
        .selected_port(selected_port),
        .granted_valid(granted_valid)
    );
    
    // BRAM Controller
    bram_ctrl #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W)
    ) bram (
        .clk(clk),
        .en(bram_en),
        .wr(bram_wr),
        .addr(bram_addr),
        .wdata(bram_wdata),
        .rdata(bram_rdata)
    );
    
    // Performance Monitor
    performance_monitor #(
        .NUM_PORTS(NUM_PORTS),
        .DATA_W(DATA_W)
    ) perf_mon (
        .clk(clk),
        .rst_n(rst_n),
        .reset_counters(reset_counters),
        .req_valid(req_valid),
        .req_accepted(req_ready),
        .resp_valid(resp_valid),
        .conflict_flag(conflict_flag),
        .granted_valid(granted_valid),
        .selected_port(selected_port),
        .total_cycles(total_cycles),
        .active_cycles(active_cycles),
        .transaction_count_0(transaction_count_0),
        .transaction_count_1(transaction_count_1),
        .transaction_count_2(transaction_count_2),
        .transaction_count_3(transaction_count_3),
        .total_latency_0(),
        .total_latency_1(),
        .total_latency_2(),
        .total_latency_3(),
        .conflict_count_0(conflict_count_0),
        .conflict_count_1(conflict_count_1),
        .conflict_count_2(conflict_count_2),
        .conflict_count_3(conflict_count_3),
        .stall_cycles_0(stall_cycles_0),
        .stall_cycles_1(stall_cycles_1),
        .stall_cycles_2(stall_cycles_2),
        .stall_cycles_3(stall_cycles_3),
        .memory_utilization_percent(memory_utilization_percent),
        .avg_latency_0(avg_latency_0),
        .avg_latency_1(avg_latency_1),
        .avg_latency_2(avg_latency_2),
        .avg_latency_3(avg_latency_3)
    );
    
    // Configuration Registers
    config_registers #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),
        .NUM_PORTS(NUM_PORTS),
        .BASE_ADDR(10'h300)
    ) cfg_regs (
        .clk(clk),
        .rst_n(rst_n),
        .reg_en(cfg_en),
        .reg_wr(cfg_wr),
        .reg_addr(cfg_addr),
        .reg_wdata(cfg_wdata),
        .reg_rdata(cfg_rdata),
        .arbiter_mode(arbiter_mode),
        .port_weight_0(port_weight_0),
        .port_weight_1(port_weight_1),
        .port_weight_2(port_weight_2),
        .port_weight_3(port_weight_3),
        .port_priority_0(port_priority_0),
        .port_priority_1(port_priority_1),
        .port_priority_2(port_priority_2),
        .port_priority_3(port_priority_3),
        .total_cycles(total_cycles),
        .active_cycles(active_cycles),
        .transaction_count_0(transaction_count_0),
        .transaction_count_1(transaction_count_1),
        .transaction_count_2(transaction_count_2),
        .transaction_count_3(transaction_count_3),
        .avg_latency_0(avg_latency_0),
        .avg_latency_1(avg_latency_1),
        .avg_latency_2(avg_latency_2),
        .avg_latency_3(avg_latency_3),
        .conflict_count_0(conflict_count_0),
        .conflict_count_1(conflict_count_1),
        .conflict_count_2(conflict_count_2),
        .conflict_count_3(conflict_count_3),
        .stall_cycles_0(stall_cycles_0),
        .stall_cycles_1(stall_cycles_1),
        .stall_cycles_2(stall_cycles_2),
        .stall_cycles_3(stall_cycles_3),
        .memory_utilization_percent(memory_utilization_percent),
        .reset_counters(reset_counters)
    );

endmodule