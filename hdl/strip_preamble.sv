
`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
// Author: Michael Fallon
//
// Design Name: strip_preamble
//
//////////////////////////////////////////////////////////////////////////////////

module strip_crc #(
    parameter int           DATA_WIDTH = 8
    )(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     stream_in_startofpacket,
    input  wire                     stream_in_endofpacket,
    input  wire                     stream_in_valid,
    input  wire [DATA_WIDTH-1:0]    stream_in_data,
    input  wire                     stream_in_error
    );


    initial begin
        $dumpfile("rgmii_rx.vcd");
        $dumpvars();
    end

endmodule
