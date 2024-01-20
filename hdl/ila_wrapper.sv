`timescale 1ns / 1ps

module ila_wrapper #(
    parameter int   NUM_PROBES =  11,
    parameter int   WIDTH_MASK = 32'hC704DD7B
    )(
    input   wire            mac_clk,
    input   wire            startofpacket,
    input   wire            endofpacket,
    input   wire            valid,
    input   wire [7:0]      data,
    input   wire            error
    );

    i_ila inst_ila (
        .clk    (mac_clk),
        .probe0 (startofpacket),
        .probe1 (endofpacket),
        .probe2 (valid),
        .probe3 (data),
        .probe4 (error)
    );

    endmodule
