module axi4_full_basic #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 4
) (
    // Global Signals  
    input wire clk,
    input wire rstn,

    // Write Address Channel
    output reg                         awready,
    input  wire                        awvalid,
    input  wire [ADDR_WIDTH-1:0]       awaddr,
    input  wire [ID_WIDTH-1:0]         awid,
    input  wire [7:0]                  awlen,
    input  wire [2:0]                  awsize,

    // Write Data Channel
    output reg                         wready,
    input  wire                        wvalid,
    input  wire [DATA_WIDTH-1:0]       wdata,
    input  wire [(DATA_WIDTH/8)-1:0]   wstrb,
    input  wire                        wlast,

    // Write Response Channel
    input  wire                        bready,
    output reg                         bvalid,
    output wire  [1:0]                  bresp,
    output reg  [ID_WIDTH-1:0]         bid,

    // Read Address Channel
    output reg                         arready,
    input  wire                        arvalid,
    input  wire [ADDR_WIDTH-1:0]       araddr,
    input  wire [ID_WIDTH-1:0]         arid,

    // Read Data Channel
    input  wire                        rready,
    output reg                         rvalid,
    output wire  [DATA_WIDTH-1:0]       rdata,
    output wire  [1:0]                  rresp,
    output reg                         rlast,
    output reg  [ID_WIDTH-1:0]         rid
);

    // Simple AXI4 FSM States
    localparam IDLE = 1'b0;
    localparam BUSY = 1'b1;

    reg write_state;
    reg read_state;

    // Write Address & Data Logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            awready <= 1'b0;
            wready  <= 1'b0;
            bvalid  <= 1'b0;
            write_state <= IDLE;
        end else begin
            case (write_state)
                IDLE: begin
                    awready <= 1'b1;
                    wready  <= 1'b1;
                    if (awvalid || wvalid) begin
                        write_state <= BUSY;
                        bid         <= awid;
                    end
                end
                BUSY: begin
                    awready <= 1'b0;
                    wready <= 1'b0;
                    bvalid <= 1'b1;
                    if (bvalid && bready) begin
                        write_state<= IDLE;
                        bvalid <=1'b0;
                    end
                end
            endcase
        end
    end

    // Read Address & Data Logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            arready <= 1'b0;
            rvalid  <= 1'b0;
            read_state <= IDLE;
        end else begin
            case (read_state)
                IDLE: begin
                    arready <= 1'b1;
                    rvalid  <= 1'b0;
                    if (arvalid) begin
                        read_state <= BUSY;
                        rid        <= arid;
                    end
                end
                BUSY: begin
                    arready <= 1'b0;
                    rvalid <= 1'b1;
                    rlast <= 1'b1;
                    if(rvalid && rready) begin
                        read_state <= IDLE;
                        rvalid <= 1'b0;
                        rlast <= 1'b0;
                    end
                end
            endcase
        end
    end

    // Default Read Data
    assign rdata= {DATA_WIDTH{1'b0}};
    assign rresp= 2'b00;
    assign bresp= 2'b00;

endmodule