`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
// Author: Michael Fallon
//
// Design Name: rgmii_rx
//
//////////////////////////////////////////////////////////////////////////////////

module rgmii_rx #(
    parameter int   DATA_WIDTH = 8
    )(
    input  wire                     mac_clk,
    input  wire                     mac_rst_n,
    output logic                    mac_startofpacket,
    output logic                    mac_endofpacket,
    output logic                    mac_valid,
    output logic [DATA_WIDTH-1:0]   mac_data,
    output logic                    mac_error,

    input  wire                     rx_rgmii_clk,
    input  wire  [3:0]              rx_rgmii_data,
    input  wire                     rx_rgmii_ctl
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

    state_t         state;
    fifo_t          wr_data;
    fifo_t          rd_data;
    logic           data_valid;
    logic           data_error;
    logic [7:0]     data;
    logic           startofpacket;
    logic           endofpacket;
    (* keep = "true" *) logic           wr_rst_n;
    (* keep = "true" *) logic           wr_rst_n_d;
    (* keep = "true" *) logic [3:0]     lower_nibble;
    (* keep = "true" *) logic [3:0]     upper_nibble;
    (* keep = "true" *) logic           rx_rgmii_dv;
    (* keep = "true" *) logic           rx_rgmii_err;

    always_ff @(posedge rx_rgmii_clk) begin
        wr_rst_n_d <= mac_rst_n;
        wr_rst_n   <= wr_rst_n_d;
    end

    always_ff @(posedge rx_rgmii_clk) begin
        lower_nibble    <= rx_rgmii_data;
        rx_rgmii_dv     <= rx_rgmii_ctl;
    end

    always_ff @(negedge rx_rgmii_clk) begin
        upper_nibble    <= rx_rgmii_data;
        rx_rgmii_err    <= rx_rgmii_ctl;
    end

    always_ff @(posedge rx_rgmii_clk) begin
        data_valid <= rx_rgmii_dv;
        data_error <= rx_rgmii_err ^ rx_rgmii_dv;
        data       <= {upper_nibble, lower_nibble};
    end

    always_ff @(posedge rx_rgmii_clk) begin
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
        wr_data.data          <= data;
        wr_data.error         <= data_error;

        case (state)
            S_IDLE: begin
                wr_data.valid   <= 1'b0;
                if (data_valid == 1 && data == SFD) begin
                    startofpacket <= 1'b1;
                    state         <= S_IN_PACKET;
                end
            end
            S_IN_PACKET: begin
                wr_data.valid   <= data_valid;
                if (data_valid != rx_rgmii_dv) begin
                    wr_data.endofpacket <= 1'b1;
                    state               <= S_IDLE;
                end
            end
        endcase
    end

    generate
        if (0) begin
            logic rgmii_ila_clk;

            clk_wiz_1 i_clk_wiz (
                .clk_in1  (rx_rgmii_clk),
                .clk_out1 (rgmii_ila_clk)
            );

            ila_0 i_ila (
                .clk    (rgmii_ila_clk),
                .probe0 (rx_rgmii_clk),
                .probe1 (rx_rgmii_data),
                .probe2 (rx_rgmii_ctl),
                .probe3 (data_valid),
                .probe4 (data_error),
                .probe5 (data),
                .probe6 (wr_data.startofpacket),
                .probe7 (wr_data.endofpacket),
                .probe8 (wr_data.valid),
                .probe9 (wr_data.data),
                .probe10(wr_data.error)
            );
        end
    endgenerate

    async_fifo #(
        .P_DEPTH    (256),
        .P_WIDTH    ($bits(fifo_t))
    ) i_async_fifo (
        .wr_clk     (rx_rgmii_clk),
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

    assign mac_startofpacket = rd_data.startofpacket;
    assign mac_endofpacket   = rd_data.endofpacket;
    assign mac_valid         = rd_data.valid;
    assign mac_data          = rd_data.data;
    assign mac_error         = rd_data.error;

    initial begin
        $dumpfile("rgmii_rx.vcd");
        $dumpvars();
    end

endmodule
