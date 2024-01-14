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
    input  wire            rx_rgmii_clk,
    input  wire  [3:0]     rx_rgmii_data,
    input  wire            rx_rgmii_ctl,

    output logic           rx_data_valid,
    output logic           rx_data_error,
    output logic [7:0]     rx_data_out
    );

    logic [3:0]         lower_nibble;
    logic [3:0]         upper_nibble;
    logic               rx_rgmii_dv;
    logic               rx_rgmii_err;

    always_ff @(posedge rx_rgmii_clk) begin
        lower_nibble    <= rx_rgmii_data;
        rx_rgmii_dv     <= rx_rgmii_ctl;
    end

    always_ff @(negedge rx_rgmii_clk) begin
        upper_nibble    <= rx_rgmii_data;
        rx_rgmii_err    <= rx_rgmii_ctl;
    end

    always_ff @(posedge rx_rgmii_clk) begin
        rx_data_valid   <= rx_rgmii_dv;
        rx_data_error   <= rx_rgmii_err;
        rx_data_out     <= {upper_nibble, lower_nibble};
    end

    initial begin
        $dumpfile("rgmii_rx.vcd");
        $dumpvars();
    end

endmodule
