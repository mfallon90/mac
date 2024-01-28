`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
// Author: Michael Fallon
//
// Design Name: rgmii_rx
//
//////////////////////////////////////////////////////////////////////////////////

module rgmii_rx #(
    parameter int   DATA_WIDTH = 8,
    parameter int   SIM = 0
    )(
    input  wire                     mac_clk,
    input  wire                     mac_rst_n,
    output logic                    mac_startofpacket,
    output logic                    mac_endofpacket,
    output logic                    mac_valid,
    output logic [DATA_WIDTH-1:0]   mac_data,
    output logic                    mac_error,

    input  wire                     rgmii_rx_clk,
    input  wire  [3:0]              rgmii_rx_data,
    input  wire                     rgmii_rx_ctl
    );

    localparam logic [7:0]  SFD = 8'hD5;

    typedef struct packed {
        logic                   startofpacket;
        logic                   endofpacket;
        logic                   valid;
        logic                   error;
        logic [DATA_WIDTH-1:0]  data;
    } fifo_t;

    typedef enum {
        S_IDLE,
        S_IN_PACKET
    } state_t;

    logic           rx_clk;
    state_t         state;
    fifo_t          wr_data;
    fifo_t          rd_data;
    logic           rx_valid;
    logic           rx_valid_comb;
    logic           rx_error;
    logic [7:0]     rx_data;
    logic           startofpacket;
    logic           endofpacket;
    logic           wr_rst_n;

    rgmii_ddr #(
        .SIM    (SIM)
    ) i_rgmii_ddr (
        .ddr_clk_in     (rgmii_rx_clk),
        .ddr_data_in    (rgmii_rx_data),
        .ddr_ctl_in     (rgmii_rx_ctl),
        .ddr_clk_out    (rx_clk),
        .ddr_data_out   (rx_data),
        .ddr_valid      (rx_valid),
        .ddr_valid_comb (rx_valid_comb),
        .ddr_error      (rx_error)
    );


    always_ff @(posedge rx_clk) begin
        if (wr_rst_n == 0) begin
            state         <= S_IDLE;
            startofpacket <= 'x;
            endofpacket   <= 'x;
            wr_data       <= 'x;
            wr_data.valid <= '0;
        end
        startofpacket         <= 1'b0;
        endofpacket           <= 1'b0;
        wr_data.startofpacket <= startofpacket;
        wr_data.endofpacket   <= endofpacket;
        wr_data.data          <= rx_data;
        wr_data.error         <= rx_error;

        case (state)
            S_IDLE: begin
                wr_data.valid   <= 1'b0;
                if (rx_valid == 1 && rx_data == SFD) begin
                    startofpacket <= 1'b1;
                    state         <= S_IN_PACKET;
                end
            end
            S_IN_PACKET: begin
                wr_data.valid   <= rx_valid;
                if (rx_valid != rx_valid_comb) begin
                    wr_data.endofpacket <= 1'b1;
                    state               <= S_IDLE;
                end
            end
        endcase
    end

    generate
        if (1) begin
            logic rgmii_ila_clk;

            clk_wiz_1 i_clk_wiz (
                .clk_in1  (rx_clk),
                .clk_out1 (rgmii_ila_clk)
            );

            ila_0 i_ila (
                .clk    (rgmii_ila_clk),
                .probe0 (rx_clk),
                .probe1 (rgmii_rx_data),
                .probe2 (rgmii_rx_ctl),
                .probe3 (rx_valid),
                .probe4 (rx_error),
                .probe5 (rx_data),
                .probe6 (wr_data.startofpacket),
                .probe7 (wr_data.endofpacket),
                .probe8 (wr_data.valid),
                .probe9 (wr_data.data),
                .probe10(wr_data.error)
            );
        end
    endgenerate

    async_fifo #(
        .P_DEPTH    (64),
        .P_WIDTH    ($bits(fifo_t))
    ) i_async_fifo (
        .wr_clk     (rx_clk),
        .wr_rst_n   (wr_rst_n),
        .wr_data    (wr_data),
        .wr_vld     (1'b1),
        .wr_rdy     (), // NC
        .rd_clk     (mac_clk),
        .rd_rst_n   (mac_rst_n),
        .rd_data    (rd_data),
        .rd_vld     (), // NC
        .rd_rdy     (1'b1)
    );

    assign mac_startofpacket = wr_data.startofpacket;
    assign mac_endofpacket   = wr_data.endofpacket;
    assign mac_valid         = wr_data.valid;
    assign mac_data          = wr_data.data;
    assign mac_error         = wr_data.error;

    initial begin
        $dumpfile("rgmii_rx.vcd");
        $dumpvars();
    end

endmodule
