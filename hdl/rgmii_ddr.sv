`timescale 1ns / 1ps

module rgmii_ddr #(
    parameter int SIM = 0
    )(
    input  wire           ddr_clk_in,
    input  wire  [4:0]    ddr_data_in,
    input  wire           ddr_ctl_in,
    output logic          ddr_clk_out,
    output logic [7:0]    ddr_data_out,
    output logic          ddr_valid,
    output logic          ddr_valid_comb,
    output logic          ddr_error
    );

    typedef struct packed {
        logic [3:0] upper_nibble;
        logic [3:0] lower_nibble;
    } byte_t;

    logic  ddr_clk_buf;
    byte_t data;
    logic  valid;
    logic  error;

    assign ddr_clk_out = ddr_clk_buf;

    generate
        if (SIM == 0) begin: g_synth_rx_data

            BUFG i_BUFG_rgmii_rx (
                .I (ddr_clk_in),
                .O (ddr_clk_buf)
            );

            for (genvar i=0; i<4; i=i+1) begin
                IDDR #(
                   .DDR_CLK_EDGE ("SAME_EDGE_PIPELINED"),
                   .SRTYPE       ("ASYNC")
                ) i_IDDR_data (
                   .Q1      (data.lower_nibble[i]),
                   .Q2      (data.upper_nibble[i]),
                   .C       (ddr_clk_buf),
                   .CE      (1),
                   .D       (ddr_data_in[i]),
                   .R       (0),
                   .S       (0)
                );
            end

            IDDR #(
               .DDR_CLK_EDGE ("SAME_EDGE_PIPELINED"),
               .SRTYPE       ("ASYNC")
            ) i_IDDR_ctl (
               .Q1      (valid),
               .Q2      (error),
               .C       (ddr_clk_buf),
               .CE      (1),
               .D       (ddr_ctl_in),
               .R       (0),
               .S       (0)
            );

        end else begin: g_sim_rx_data

            assign ddr_clk_buf = ddr_clk_in;

            always_ff @(posedge ddr_clk_buf) begin
                data.lower_nibble <= ddr_data_in;
                valid             <= ddr_ctl_in;
            end

            always_ff @(negedge ddr_clk_buf) begin
                data.upper_nibble <= ddr_data_in;
                error             <= ddr_ctl_in;
            end
        end
    endgenerate

    always_ff @(posedge ddr_clk_buf) begin
        ddr_valid    <= valid;
        ddr_error    <= error ^ valid;
        ddr_data_out <= data;
    end

    assign ddr_valid_comb = valid;

endmodule
