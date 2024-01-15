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
    
    logic rst, rst_d;
    logic rst_n, rst_n_d;
    always_ff @(posedge sys_clk) begin
        rst_d   <= sys_rst;
        rst_n_d <= ~sys_rst;
        rst     <= rst_d;
        rst_n   <= rst_n_d;
    end

    rgmii i_rgmii (
        .mac_clk    (sys_clk),
        .mac_rst_n  (rst_n),
        .mac_startofpacket  (seven_seg_en[0]),
        .mac_endofpacket    (seven_seg_en[1]),
        .mac_valid          (seven_seg_en[2]),
        .mac_data           (seven_seg_led),
        .mac_error          (seven_seg_en[3]),
        .rx_rgmii_clk       (rgmii_rx_clk),
        .rx_rgmii_data      (rgmii_rx_data),
        .rx_rgmii_ctl       (rgmii_rx_ctl)
    );

    assign led           = '0;
    assign mdc           = '0;
    assign rgmii_tx_data = '0;
    assign rgmii_tx_ctl  = '0;

    // initial begin
    //     $dumpfile("crc32.vcd");
    //     $dumpvars();
    // end


endmodule
