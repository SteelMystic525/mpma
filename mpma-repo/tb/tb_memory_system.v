`timescale 1ns/1ps

module tb_memory_system;

    parameter ADDR_W = 10;
    parameter DATA_W = 32;
    parameter NUM_PORTS = 4;
    parameter PRIORITY_W = 2;
    parameter CLK_PERIOD = 10;
    parameter SIM_CYCLES = 50000;
    
    // Clock and reset
    reg clk;
    reg rst_n;
    
    // Port 0
    reg port0_en, port0_wr;
    reg [ADDR_W-1:0] port0_addr;
    reg [DATA_W-1:0] port0_wdata;
    reg [PRIORITY_W-1:0] port0_priority;
    reg [3:0] port0_burst_len;
    wire [DATA_W-1:0] port0_rdata;
    wire port0_ready;
    
    // Port 1
    reg port1_en, port1_wr;
    reg [ADDR_W-1:0] port1_addr;
    reg [DATA_W-1:0] port1_wdata;
    reg [PRIORITY_W-1:0] port1_priority;
    reg [3:0] port1_burst_len;
    wire [DATA_W-1:0] port1_rdata;
    wire port1_ready;
    
    // Port 2
    reg port2_en, port2_wr;
    reg [ADDR_W-1:0] port2_addr;
    reg [DATA_W-1:0] port2_wdata;
    reg [PRIORITY_W-1:0] port2_priority;
    reg [3:0] port2_burst_len;
    wire [DATA_W-1:0] port2_rdata;
    wire port2_ready;
    
    // Port 3
    reg port3_en, port3_wr;
    reg [ADDR_W-1:0] port3_addr;
    reg [DATA_W-1:0] port3_wdata;
    reg [PRIORITY_W-1:0] port3_priority;
    reg [3:0] port3_burst_len;
    wire [DATA_W-1:0] port3_rdata;
    wire port3_ready;
    
    // Config interface
    reg cfg_en, cfg_wr;
    reg [ADDR_W-1:0] cfg_addr;
    reg [DATA_W-1:0] cfg_wdata;
    wire [DATA_W-1:0] cfg_rdata;
    
    // Read result storage
    reg [DATA_W-1:0] cfg_read_data;
    
    // Per-port loop counters (declared at module scope)
    integer p0_i, p1_i, p2_i, p3_i;
    integer p0_seed, p1_seed, p2_seed, p3_seed;
    
    // DUT
    memory_system_top #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),
        .NUM_PORTS(NUM_PORTS),
        .PRIORITY_W(PRIORITY_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .port0_en(port0_en),
        .port0_wr(port0_wr),
        .port0_addr(port0_addr),
        .port0_wdata(port0_wdata),
        .port0_priority(port0_priority),
        .port0_burst_len(port0_burst_len),
        .port0_rdata(port0_rdata),
        .port0_ready(port0_ready),
        .port1_en(port1_en),
        .port1_wr(port1_wr),
        .port1_addr(port1_addr),
        .port1_wdata(port1_wdata),
        .port1_priority(port1_priority),
        .port1_burst_len(port1_burst_len),
        .port1_rdata(port1_rdata),
        .port1_ready(port1_ready),
        .port2_en(port2_en),
        .port2_wr(port2_wr),
        .port2_addr(port2_addr),
        .port2_wdata(port2_wdata),
        .port2_priority(port2_priority),
        .port2_burst_len(port2_burst_len),
        .port2_rdata(port2_rdata),
        .port2_ready(port2_ready),
        .port3_en(port3_en),
        .port3_wr(port3_wr),
        .port3_addr(port3_addr),
        .port3_wdata(port3_wdata),
        .port3_priority(port3_priority),
        .port3_burst_len(port3_burst_len),
        .port3_rdata(port3_rdata),
        .port3_ready(port3_ready),
        .cfg_en(cfg_en),
        .cfg_wr(cfg_wr),
        .cfg_addr(cfg_addr),
        .cfg_wdata(cfg_wdata),
        .cfg_rdata(cfg_rdata)
    );
    
    // Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Config write task
    task write_config;
        input [ADDR_W-1:0] addr;
        input [DATA_W-1:0] data;
        begin
            @(negedge clk);
            cfg_en   = 1'b1;
            cfg_wr   = 1'b1;
            cfg_addr = addr;
            cfg_wdata = data;
            @(negedge clk);
            cfg_en   = 1'b0;
            cfg_wr   = 1'b0;
        end
    endtask
    
    // Config read task
    task read_config;
        input [ADDR_W-1:0] addr;
        begin
            @(negedge clk);
            cfg_en   = 1'b1;
            cfg_wr   = 1'b0;
            cfg_addr = addr;
            @(negedge clk);
            cfg_read_data = cfg_rdata;
            cfg_en   = 1'b0;
        end
    endtask
    
    // Display metrics task
    task display_metrics;
        begin
            $display("\n========== PERFORMANCE METRICS ==========");
            
            read_config(10'h328);
            $display("Total Cycles:          %0d", cfg_read_data);
            read_config(10'h32C);
            $display("Active Cycles:         %0d", cfg_read_data);
            read_config(10'h330);
            $display("Memory Utilization:    %0d%%", cfg_read_data);
            
            $display("\n--- Port 0 Statistics ---");
            read_config(10'h340); $display("  Transactions:  %0d", cfg_read_data);
            read_config(10'h350); $display("  Avg Latency:   %0d cycles", cfg_read_data);
            read_config(10'h360); $display("  Conflicts:     %0d", cfg_read_data);
            read_config(10'h370); $display("  Stall Cycles:  %0d", cfg_read_data);
            
            $display("\n--- Port 1 Statistics ---");
            read_config(10'h344); $display("  Transactions:  %0d", cfg_read_data);
            read_config(10'h354); $display("  Avg Latency:   %0d cycles", cfg_read_data);
            read_config(10'h364); $display("  Conflicts:     %0d", cfg_read_data);
            read_config(10'h374); $display("  Stall Cycles:  %0d", cfg_read_data);
            
            $display("\n--- Port 2 Statistics ---");
            read_config(10'h348); $display("  Transactions:  %0d", cfg_read_data);
            read_config(10'h358); $display("  Avg Latency:   %0d cycles", cfg_read_data);
            read_config(10'h368); $display("  Conflicts:     %0d", cfg_read_data);
            read_config(10'h378); $display("  Stall Cycles:  %0d", cfg_read_data);
            
            $display("\n--- Port 3 Statistics ---");
            read_config(10'h34C); $display("  Transactions:  %0d", cfg_read_data);
            read_config(10'h35C); $display("  Avg Latency:   %0d cycles", cfg_read_data);
            read_config(10'h36C); $display("  Conflicts:     %0d", cfg_read_data);
            read_config(10'h37C); $display("  Stall Cycles:  %0d", cfg_read_data);
            
            $display("==========================================\n");
        end
    endtask
    
    // Direct internal dump (bypass config registers)
    task display_internal_dump;
        begin
            $display("\n========== DIRECT INTERNAL DUMP ==========");
            $display("perf_mon.total_cycles:          %0d", dut.perf_mon.total_cycles);
            $display("perf_mon.active_cycles:         %0d", dut.perf_mon.active_cycles);
            $display("perf_mon.mem_util:              %0d%%", dut.perf_mon.memory_utilization_percent);
            $display("perf_mon.transaction_count_0:   %0d", dut.perf_mon.transaction_count_0);
            $display("perf_mon.transaction_count_1:   %0d", dut.perf_mon.transaction_count_1);
            $display("perf_mon.transaction_count_2:   %0d", dut.perf_mon.transaction_count_2);
            $display("perf_mon.transaction_count_3:   %0d", dut.perf_mon.transaction_count_3);
            $display("perf_mon.avg_latency_0:         %0d", dut.perf_mon.avg_latency_0);
            $display("perf_mon.avg_latency_1:         %0d", dut.perf_mon.avg_latency_1);
            $display("perf_mon.avg_latency_2:         %0d", dut.perf_mon.avg_latency_2);
            $display("perf_mon.avg_latency_3:         %0d", dut.perf_mon.avg_latency_3);
            $display("perf_mon.conflict_count_0:      %0d", dut.perf_mon.conflict_count_0);
            $display("perf_mon.conflict_count_1:      %0d", dut.perf_mon.conflict_count_1);
            $display("perf_mon.conflict_count_2:      %0d", dut.perf_mon.conflict_count_2);
            $display("perf_mon.conflict_count_3:      %0d", dut.perf_mon.conflict_count_3);
            $display("perf_mon.stall_cycles_0:        %0d", dut.perf_mon.stall_cycles_0);
            $display("perf_mon.stall_cycles_1:        %0d", dut.perf_mon.stall_cycles_1);
            $display("perf_mon.stall_cycles_2:        %0d", dut.perf_mon.stall_cycles_2);
            $display("perf_mon.stall_cycles_3:        %0d", dut.perf_mon.stall_cycles_3);
            $display("==========================================\n");
        end
    endtask
    
    // =============================================
    // PORT TRAFFIC GENERATORS
    // Each port has its own always block - no fork,
    // no shared task, no race conditions.
    // Controlled by these signals:
    // =============================================
    reg  [1:0]  test_phase;       // 0=idle, 1=test1, 2=test2, 3=test3, 4=test4
    reg         start_traffic;    // Pulse to start current test
    reg         traffic_done_0, traffic_done_1, traffic_done_2, traffic_done_3;
    reg  [7:0]  num_trans;        // How many transactions per port this test
    reg  [1:0]  port0_pri_cfg, port1_pri_cfg, port2_pri_cfg, port3_pri_cfg;
    reg  [3:0]  burst_cfg;        // Burst length for this test
    reg  [3:0]  rate_cfg;         // Cycles between transactions
    
    // Port 0 traffic generator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            port0_en <= 1'b0;
            traffic_done_0 <= 1'b0;
            p0_i <= 0;
            p0_seed <= 1111;
        end else begin
            if (start_traffic) begin
                p0_i <= 0;
                traffic_done_0 <= 1'b0;
            end else if (!traffic_done_0 && test_phase != 2'd0) begin
                if (p0_i >= num_trans) begin
                    port0_en <= 1'b0;
                    traffic_done_0 <= 1'b1;
                end else begin
                    // Simple counter-based pacing
                    if (p0_i[1:0] == rate_cfg[1:0] || rate_cfg == 0) begin
                        port0_en      <= 1'b1;
                        port0_wr      <= p0_seed[0];
                        port0_addr    <= p0_seed[9:0] ^ p0_i[9:0];
                        port0_wdata   <= {p0_i[7:0], 8'hAA, 8'hBB, 8'hCC};
                        port0_priority <= port0_pri_cfg;
                        port0_burst_len <= burst_cfg;
                        p0_seed       <= p0_seed * 32'd1103515245 + 32'd12345;
                        p0_i          <= p0_i + 1;
                    end else begin
                        port0_en <= 1'b0;
                    end
                end
            end else begin
                port0_en <= 1'b0;
            end
        end
    end
    
    // Port 1 traffic generator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            port1_en <= 1'b0;
            traffic_done_1 <= 1'b0;
            p1_i <= 0;
            p1_seed <= 2222;
        end else begin
            if (start_traffic) begin
                p1_i <= 0;
                traffic_done_1 <= 1'b0;
            end else if (!traffic_done_1 && test_phase != 2'd0) begin
                if (p1_i >= num_trans) begin
                    port1_en <= 1'b0;
                    traffic_done_1 <= 1'b1;
                end else begin
                    if (p1_i[1:0] == rate_cfg[1:0] || rate_cfg == 0) begin
                        port1_en      <= 1'b1;
                        port1_wr      <= p1_seed[0];
                        port1_addr    <= p1_seed[9:0] ^ p1_i[9:0];
                        port1_wdata   <= {p1_i[7:0], 8'h11, 8'h22, 8'h33};
                        port1_priority <= port1_pri_cfg;
                        port1_burst_len <= burst_cfg;
                        p1_seed       <= p1_seed * 32'd1103515245 + 32'd12345;
                        p1_i          <= p1_i + 1;
                    end else begin
                        port1_en <= 1'b0;
                    end
                end
            end else begin
                port1_en <= 1'b0;
            end
        end
    end
    
    // Port 2 traffic generator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            port2_en <= 1'b0;
            traffic_done_2 <= 1'b0;
            p2_i <= 0;
            p2_seed <= 3333;
        end else begin
            if (start_traffic) begin
                p2_i <= 0;
                traffic_done_2 <= 1'b0;
            end else if (!traffic_done_2 && test_phase != 2'd0) begin
                if (p2_i >= num_trans) begin
                    port2_en <= 1'b0;
                    traffic_done_2 <= 1'b1;
                end else begin
                    if (p2_i[1:0] == rate_cfg[1:0] || rate_cfg == 0) begin
                        port2_en      <= 1'b1;
                        port2_wr      <= p2_seed[0];
                        port2_addr    <= p2_seed[9:0] ^ p2_i[9:0];
                        port2_wdata   <= {p2_i[7:0], 8'h44, 8'h55, 8'h66};
                        port2_priority <= port2_pri_cfg;
                        port2_burst_len <= burst_cfg;
                        p2_seed       <= p2_seed * 32'd1103515245 + 32'd12345;
                        p2_i          <= p2_i + 1;
                    end else begin
                        port2_en <= 1'b0;
                    end
                end
            end else begin
                port2_en <= 1'b0;
            end
        end
    end
    
    // Port 3 traffic generator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            port3_en <= 1'b0;
            traffic_done_3 <= 1'b0;
            p3_i <= 0;
            p3_seed <= 4444;
        end else begin
            if (start_traffic) begin
                p3_i <= 0;
                traffic_done_3 <= 1'b0;
            end else if (!traffic_done_3 && test_phase != 2'd0) begin
                if (p3_i >= num_trans) begin
                    port3_en <= 1'b0;
                    traffic_done_3 <= 1'b1;
                end else begin
                    if (p3_i[1:0] == rate_cfg[1:0] || rate_cfg == 0) begin
                        port3_en      <= 1'b1;
                        port3_wr      <= p3_seed[0];
                        port3_addr    <= p3_seed[9:0] ^ p3_i[9:0];
                        port3_wdata   <= {p3_i[7:0], 8'h77, 8'h88, 8'h99};
                        port3_priority <= port3_pri_cfg;
                        port3_burst_len <= burst_cfg;
                        p3_seed       <= p3_seed * 32'd1103515245 + 32'd12345;
                        p3_i          <= p3_i + 1;
                    end else begin
                        port3_en <= 1'b0;
                    end
                end
            end else begin
                port3_en <= 1'b0;
            end
        end
    end
    
    // Wait for all 4 ports to finish
    task wait_traffic_done;
        begin
            while (!(traffic_done_0 && traffic_done_1 && traffic_done_2 && traffic_done_3))
                @(posedge clk);
            // Extra settle time for pipeline to flush
            repeat(50) @(posedge clk);
            test_phase <= 2'd0;
        end
    endtask
    
    // Launch traffic: set config, pulse start, wait done
    task run_test;
        input [7:0] n_trans;
        input [3:0] burst;
        input [3:0] rate;
        input [1:0] p0_pri, p1_pri, p2_pri, p3_pri;
        begin
            num_trans       <= n_trans;
            burst_cfg       <= burst;
            rate_cfg        <= rate;
            port0_pri_cfg   <= p0_pri;
            port1_pri_cfg   <= p1_pri;
            port2_pri_cfg   <= p2_pri;
            port3_pri_cfg   <= p3_pri;
            @(negedge clk);
            test_phase      <= 2'd1;
            start_traffic   <= 1'b1;
            @(negedge clk);
            start_traffic   <= 1'b0;
            wait_traffic_done;
        end
    endtask
    
    // =============================================
    // MAIN TEST SEQUENCE
    // =============================================
    initial begin
        // Init
        rst_n = 0;
        cfg_en = 0; cfg_wr = 0;
        cfg_addr = 0; cfg_wdata = 0;
        test_phase = 0;
        start_traffic = 0;
        num_trans = 0;
        burst_cfg = 0;
        rate_cfg = 0;
        port0_pri_cfg = 0; port1_pri_cfg = 0;
        port2_pri_cfg = 0; port3_pri_cfg = 0;
        port0_wr = 0; port1_wr = 0; port2_wr = 0; port3_wr = 0;
        port0_addr = 0; port1_addr = 0; port2_addr = 0; port3_addr = 0;
        port0_wdata = 0; port1_wdata = 0; port2_wdata = 0; port3_wdata = 0;
        port0_priority = 0; port1_priority = 0; port2_priority = 0; port3_priority = 0;
        port0_burst_len = 0; port1_burst_len = 0; port2_burst_len = 0; port3_burst_len = 0;
        
        #(CLK_PERIOD * 10);
        rst_n = 1;
        #(CLK_PERIOD * 5);
        
        $display("========================================");
        $display("  QoS Memory System - Full Test Suite");
        $display("========================================\n");
        
        // --------------------------------------------------
        // TEST 1: Priority-Based Arbitration
        // --------------------------------------------------
        $display("TEST 1: Priority-Based Arbitration");
        $display("  Config: P0=0(lowest), P1=1, P2=2, P3=3(highest)");
        $display("  Expected: P3 gets most transactions\n");
        
        write_config(10'h300, 32'h00000000);  // arbiter_mode = priority
        write_config(10'h304, 32'h00000000);  // P0 pri = 0
        write_config(10'h308, 32'h00000001);  // P1 pri = 1
        write_config(10'h30C, 32'h00000002);  // P2 pri = 2
        write_config(10'h310, 32'h00000003);  // P3 pri = 3
        write_config(10'h324, 32'h00000001);  // Reset counters
        #(CLK_PERIOD * 5);
        
        // 200 transactions per port, no burst, rate=1 (every cycle)
        run_test(8'd200, 4'd0, 4'd0, 2'd0, 2'd1, 2'd2, 2'd3);
        
        $display("--- TEST 1 RESULTS (via config regs) ---");
        display_metrics();
        $display("--- TEST 1 RESULTS (direct dump) ---");
        display_internal_dump();
        
        // --------------------------------------------------
        // TEST 2: Round-Robin Arbitration
        // --------------------------------------------------
        $display("TEST 2: Round-Robin Arbitration");
        $display("  Config: All ports equal");
        $display("  Expected: ~equal transactions across all ports\n");
        
        write_config(10'h300, 32'h00000001);  // arbiter_mode = round-robin
        write_config(10'h324, 32'h00000001);  // Reset counters
        #(CLK_PERIOD * 5);
        
        run_test(8'd200, 4'd0, 4'd0, 2'd0, 2'd0, 2'd0, 2'd0);
        
        $display("--- TEST 2 RESULTS (via config regs) ---");
        display_metrics();
        $display("--- TEST 2 RESULTS (direct dump) ---");
        display_internal_dump();
        
        // --------------------------------------------------
        // TEST 3: Weighted Fair Queuing
        // --------------------------------------------------
        $display("TEST 3: Weighted Fair Queuing");
        $display("  Weights: P0=8, P1=4, P2=2, P3=1");
        $display("  Expected: ratio ~8:4:2:1\n");
        
        write_config(10'h300, 32'h00000002);  // arbiter_mode = weighted
        write_config(10'h314, 32'h00000008);  // P0 weight = 8
        write_config(10'h318, 32'h00000004);  // P1 weight = 4
        write_config(10'h31C, 32'h00000002);  // P2 weight = 2
        write_config(10'h320, 32'h00000001);  // P3 weight = 1
        write_config(10'h324, 32'h00000001);  // Reset counters
        #(CLK_PERIOD * 5);
        
        run_test(8'd200, 4'd0, 4'd0, 2'd0, 2'd0, 2'd0, 2'd0);
        
        $display("--- TEST 3 RESULTS (via config regs) ---");
        display_metrics();
        $display("--- TEST 3 RESULTS (direct dump) ---");
        display_internal_dump();
        
        // --------------------------------------------------
        // TEST 4: Burst Transactions
        // --------------------------------------------------
        $display("TEST 4: Burst Transactions");
        $display("  All ports send 8-beat bursts");
        $display("  Expected: high utilization\n");
        
        write_config(10'h300, 32'h00000001);  // round-robin for fairness
        write_config(10'h324, 32'h00000001);  // Reset counters
        #(CLK_PERIOD * 5);
        
        // burst_len = 7 means 8 beats
        run_test(8'd100, 4'd7, 4'd0, 2'd0, 2'd0, 2'd0, 2'd0);
        
        $display("--- TEST 4 RESULTS (via config regs) ---");
        display_metrics();
        $display("--- TEST 4 RESULTS (direct dump) ---");
        display_internal_dump();
        
        // --------------------------------------------------
        // DONE
        // --------------------------------------------------
        $display("========================================");
        $display("  All Tests Complete!");
        $display("========================================\n");
        
        #(CLK_PERIOD * 50);
        $finish;
    end
    
    // Timeout
    initial begin
        #(CLK_PERIOD * SIM_CYCLES);
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
    // Waveform dump
    initial begin
        $dumpfile("memory_system.vcd");
        $dumpvars(0, tb_memory_system);
    end

endmodule