`timescale 1ns / 1ps

module rgmii #(
    parameter int DATA_WIDTH = 8,
    parameter int SIM = 0
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

    typedef struct packed {
        logic                   startofpacket;
        logic                   endofpacket;
        logic                   valid;
        logic [DATA_WIDTH-1:0]  data;
        logic                   error;
    } stream_t;

    stream_t stream0;
    stream_t stream1;

    rgmii_rx #(
        .DATA_WIDTH (DATA_WIDTH),
        .SIM        (SIM)
    ) i_rgmii_rx (
        .mac_clk           (mac_clk),
        .mac_rst_n         (mac_rst_n),
        .mac_startofpacket (stream0.startofpacket),
        .mac_endofpacket   (stream0.endofpacket),
        .mac_valid         (stream0.valid),
        .mac_data          (stream0.data),
        .mac_error         (stream0.error),
        .rgmii_rx_clk      (rgmii_rx_clk),
        .rgmii_rx_data     (rgmii_rx_data),
        .rgmii_rx_ctl      (rgmii_rx_ctl)
    );

    crc32 i_crc32 (
        .clk                      (mac_clk),
        .rst_n                    (mac_rst_n),
        .stream_in_startofpacket  (stream0.startofpacket),
        .stream_in_endofpacket    (stream0.endofpacket),
        .stream_in_valid          (stream0.valid),
        .stream_in_data           (stream0.data),
        .stream_in_error          (stream0.error),
        .stream_out_startofpacket (stream1.startofpacket),
        .stream_out_endofpacket   (stream1.endofpacket),
        .stream_out_valid         (stream1.valid),
        .stream_out_data          (stream1.data),
        .stream_out_error         (stream1.error)
    );

    assign mac_startofpacket = stream1.startofpacket;
    assign mac_endofpacket   = stream1.endofpacket;
    assign mac_valid         = stream1.valid;
    assign mac_data          = stream1.data;
    assign mac_error         = stream1.error;
    
    // initial begin
    //     $dumpfile("rgmii.vcd");
    //     $dumpvars();
    // end


endmodule
