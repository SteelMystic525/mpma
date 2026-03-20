module bram_ctrl
#(
    parameter ADDR_W = 10,
    parameter DATA_W = 32
)
(
    input  clk,
    input  en,
    input  wr,
    input  [ADDR_W-1:0] addr,
    input  [DATA_W-1:0] wdata,
    output reg [DATA_W-1:0] rdata
);

    reg [DATA_W-1:0] mem [0:(1<<ADDR_W)-1];

    always @(posedge clk) begin
        if (en) begin
            if (wr)
                mem[addr] <= wdata;
            rdata <= mem[addr];
        end
    end
endmodule
