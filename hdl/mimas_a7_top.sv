`timescale 1ns / 1ps

module mimas_a7_top #(
    parameter [31:0]    P_RESIDUE = 32'hC704DD7B,
    parameter int       SIM = 0
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

    localparam int BCD_BITS = $clog2(9999);

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
    logic rst;
    logic rst_n;
    logic [BCD_BITS-1:0] packet_counter;

    delay #(
        .NUM_CYCLES     (4),
        .WIDTH          (2)
    ) i_rst_delay (
        .clk        (mac_clk),
        .data_in    ({sys_rst, ~sys_rst}),
        .data_out   ({rst,      rst_n})
    );

    rgmii #(
        .SIM    (SIM)
    ) i_rgmii (
        .mac_clk           (mac_clk),
        .mac_rst_n         (rst_n),
        .mac_startofpacket (stream.startofpacket),
        .mac_endofpacket   (stream.endofpacket),
        .mac_valid         (stream.valid),
        .mac_data          (stream.data),
        .mac_error         (stream.error),
        .rgmii_rx_clk      (rgmii_rx_clk),
        .rgmii_rx_data     (rgmii_rx_data),
        .rgmii_rx_ctl      (rgmii_rx_ctl)
    );

    logic valid;
    assign valid = stream.error & stream.valid;

    always_ff @(posedge mac_clk) begin
        if (rst == 1) begin
            packet_counter <= '0;
        end else begin
            if (valid == 1) begin
                packet_counter <= packet_counter + 1;
            end
        end
    end

    seven_segment_display #(
        .HEX      (0),
        .CLK_FREQ (125),
        .SIM      (SIM)
    ) i_seven_segment_display (
        .clk           (mac_clk),
        .reset         (rst),
        .data_in       (packet_counter),
        .data_in_valid (valid),
        .enable        (seven_seg_en),
        .led_out       (seven_seg_led)
    );

    generate
        if (1) begin
            ila_wrapper i_ila_wrapper (
                .mac_clk       (mac_clk),
                .startofpacket (stream.startofpacket),
                .endofpacket   (stream.endofpacket),
                .valid         (stream.valid),
                .data          (stream.data),
                .error         (stream.error)
            );
        end
    endgenerate

    // assign led           = '0;
    // assign mdc           = '0;
    assign rgmii_tx_data = '0;
    assign rgmii_tx_ctl  = '0;
    
    // assign [0] = stream.startofpacket;
    assign mdc = stream.endofpacket;
    // assign [2] = stream.valid;
    // assign [3] = stream.error;
    assign led = stream.data;

    // initial begin
    //     $dumpfile("crc32.vcd");
    //     $dumpvars();
    // end


endmodule
