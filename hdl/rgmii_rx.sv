`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
// Author: Michael Fallon
//
// Design Name: rgmii_rx
//
//////////////////////////////////////////////////////////////////////////////////

module rgmii_rx
    (
    input  wire            sys_clk,
    input  wire            sys_rst_n,
    output logic           rx_data_valid,
    output logic           rx_data_error,
    output logic [7:0]     rx_data,

    input  wire            rx_rgmii_clk,
    input  wire  [3:0]     rx_rgmii_data,
    input  wire            rx_rgmii_ctl
    );

    typedef struct packed {
        logic [7:0] data;
        logic       error;
    } fifo_t;
    
    fifo_t wr_data;
    fifo_t rd_data;
    logic               wr_data_valid;
    logic               rd_data_valid;
    logic               wr_rst_n;
    logic               wr_rst_n_d;

    logic [3:0]         lower_nibble;
    logic [3:0]         upper_nibble;
    logic               rx_rgmii_dv;
    logic               rx_rgmii_err;

    always_ff @(posedge rx_rgmii_clk) begin
        wr_rst_n_d <= sys_rst_n;
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
        wr_data_valid   <= rx_rgmii_dv;
        wr_data.error   <= rx_rgmii_err;
        wr_data.data    <= {upper_nibble, lower_nibble};
    end

    async_fifo #(
        .P_DEPTH    (16),
        .P_WIDTH    ($bits(fifo_t))
    ) i_async_fifo (
        .wr_clk     (rx_rgmii_clk),
        .wr_rst_n   (wr_rst_n),
        .wr_data    (wr_data),
        .wr_vld     (wr_data_valid),
        .wr_rdy     (), // NC
        .rd_clk     (sys_clk),
        .rd_rst_n   (sys_rst_n),
        .rd_data    (rd_data),
        .rd_vld     (rd_data_valid),
        .rd_rdy     (1'b1)
    );

    assign rx_data       = rd_data.data;
    assign rx_data_error = rd_data.error;
    assign rx_data_valid = rd_data_valid;

    initial begin
        $dumpfile("rgmii_rx.vcd");
        $dumpvars();
    end

endmodule
