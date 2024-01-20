`timescale 1ns / 1ps

module mimas_a7_top #(
    parameter [31:0]    P_RESIDUE = 32'hC704DD7B
    )(
    input   wire            sys_clk,
    input   wire            sys_rst,

    output logic [7:0] led,

    input  wire  [3:0] push_button,

    input  wire  [7:0] dip_switch,

    output logic [3:0]  seven_seg_en,

    output logic [7:0]  seven_seg_led,

    output logic        mdc,
    inout  logic        mdio,
    output logic        phy_rst_n,
    input  wire  [3:0]  rgmii_rx_data,
    input  wire         rgmii_rx_ctl,
    input  wire         rgmii_rx_clk,
    output logic  [3:0] rgmii_tx_data,
    output logic        rgmii_tx_ctl,
    input  wire         rgmii_tx_clk
    );

    logic   mac_clk;

    clk_wiz_0 i_clk_wiz (
        .reset      (sys_rst),
        .clk_in1    (sys_clk),
        .clk_out1   (mac_clk)
    );

    typedef struct packed {
        logic        startofpacket;
        logic        endofpacket;
        logic        valid;
        logic [7:0]  data;
        logic        error;
    } stream_t;
    
    stream_t stream;
    logic rst, rst_d;
    logic rst_n, rst_n_d;
    always_ff @(posedge sys_clk) begin
        rst_d   <= sys_rst;
        rst_n_d <= ~sys_rst;
        rst     <= rst_d;
        rst_n   <= rst_n_d;
    end

    rgmii i_rgmii (
        .mac_clk           (mac_clk),
        .mac_rst_n         (rst_n),
        .mac_startofpacket (stream.startofpacket),
        .mac_endofpacket   (stream.endofpacket),
        .mac_valid         (stream.valid),
        .mac_data          (stream.data),
        .mac_error         (stream.error),
        .rx_rgmii_clk      (rgmii_rx_clk),
        .rx_rgmii_data     (rgmii_rx_data),
        .rx_rgmii_ctl      (rgmii_rx_ctl)
    );

    ila_wrapper i_ila_wrapper (
        .mac_clk       (mac_clk),
        .startofpacket (stream.startofpacket),
        .endofpacket   (stream.endofpacket),
        .valid         (stream.valid),
        .data          (stream.data),
        .error         (stream.error)
    );

    assign led           = '0;
    assign mdc           = '0;
    assign rgmii_tx_data = '0;
    assign rgmii_tx_ctl  = '0;
    
    assign seven_seg_en[0] = stream.startofpacket;
    assign seven_seg_en[1] = stream.endofpacket;
    assign seven_seg_en[2] = stream.valid;
    assign seven_seg_en[3] = stream.error;
    assign seven_seg_led   = stream.data;

    // initial begin
    //     $dumpfile("crc32.vcd");
    //     $dumpvars();
    // end


endmodule
