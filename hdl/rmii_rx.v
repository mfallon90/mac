`timescale 1ns / 1ps
// `define ADDR_VLD ((rx_cnt == 12) & ((mac_addr == P_MAC_ADDR)))
`define ADDR_VLD ((rx_cnt == 12) & ((mac_addr == P_MAC_ADDR) | (mac_addr == C_BRDCST)))

//////////////////////////////////////////////////////////////////////////////////
//
// Engineer: Michael Fallon
//
// Design Name: rmii_rx
// Module Name: fm_synth_top
// Tool Versions: Vivado 2020.2
//
// Description: This module receives data from phy using standard MII protocol.
// Data is received in nibbles and sent out as bytes, along with a byte valid 
// flag to indicate a valid byte. The MII protocol specifies that data is received
// Most Significant Byte first, but within that byte, the Least Significant Nibble
// is received first, followed by the Most significant nibble. So if the following
// data is seen on rx_data : 0xA 0xC 0x4 0xD then the intended bytes are 0xCA 0xD4
//
// Note that the MAC address for the PHY must be provided with the nibbles
// inverted in order to conform to the MII receive data format
//
//////////////////////////////////////////////////////////////////////////////////

module rmii_rx
    (
    // RX signals
    input   wire            rx_clk,
    input   wire            rx_rst_n,
    input   wire    [3:0]   rx_data,
    input   wire            rx_dv,
    input   wire            rx_er,
    input   wire            crs,
    input   wire            col,

    // Byte out interface
    output  wire    [8:0]   rx_byte,
    output  wire            rx_byte_vld
    );

    localparam          S_IDLE  = 1'b0;
    localparam          S_RX    = 1'b1;

    reg                 state;
    reg     [3:0]       rx_data_reg;
    reg                 byte_vld;

    assign rx_byte      = (state==S_RX) ? {state, rx_data, rx_data_reg} : 0;
    assign rx_byte_vld  = byte_vld;

    always @(posedge rx_clk) begin
        if (~rx_rst_n) begin
            state           <= S_IDLE;
            rx_data_reg     <= 0;
            byte_vld        <= 0;
        end

        else begin

            case (state)
                S_IDLE: begin
                    state       <= S_IDLE;
                    rx_data_reg <= 0;
                    byte_vld    <= ~byte_vld;

                    if ((rx_dv == 1'b1) && (rx_data == 4'hD)) begin
                        state       <= S_RX;
                        rx_data_reg <= rx_data;
                        byte_vld    <= 1'b0;
                    end
                end

                S_RX: begin
                    state       <= S_RX;
                    rx_data_reg <= rx_data;
                    byte_vld    <= ~byte_vld;

                    if (~rx_dv) begin
                        state       <= S_IDLE;
                        rx_data_reg <= 0;
                        byte_vld    <= 1'b0;
                    end
                end
            endcase
        end
    end

    // initial begin
    //     $dumpfile("rmii_rx.vcd");
    //     $dumpvars();
    // end


endmodule