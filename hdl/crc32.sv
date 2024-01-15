`timescale 1ns / 1ps

module crc32 #(
    parameter [31:0]    P_RESIDUE = 32'hC704DD7B
    )(
    input   wire            clk,
    input   wire            rst_n,
    input   wire            stream_in_startofpacket,
    input   wire            stream_in_endofpacket,
    input   wire            stream_in_valid,
    input   wire  [7:0]     stream_in_data,
    input   wire            stream_in_error,
    output  logic           stream_out_startofpacket,
    output  logic           stream_out_endofpacket,
    output  logic           stream_out_valid,
    output  logic [7:0]     stream_out_data,
    output  logic           stream_out_error
    );

    typedef struct packed {
        logic                   startofpacket;
        logic                   endofpacket;
        logic                   valid;
        logic [7:0]             data;
        logic                   error;
    } stream_t;

    stream_t        stream0;
    stream_t        stream1;
    stream_t        stream2;
    stream_t        stream3;
    stream_t        stream4;
    stream_t        stream5;
    logic   [7:0]   data;
    logic   [7:0]   rev_data;
    logic   [31:0]  crc_q;
    logic   [31:0]  crc_d;
    logic           crc_valid;

    assign crc_valid = (crc_d == P_RESIDUE);

    always_ff @(posedge clk) begin
        stream0 <= stream1;
        stream1 <= stream2;
        stream2 <= stream3;
        stream3 <= stream4;
        stream4 <= stream5;
    end

    generate
        for (genvar i=0; i<8; i=i+1)
            assign rev_data[i]  = stream_in_data[7-i];
    endgenerate

    always @(posedge clk) begin
        if(rst_n == 0) begin
            crc_q <= '1;
            data  <= 'x;
        end else begin
            data <= rev_data;
            if (stream_in_valid == 1) begin
                crc_q   <= crc_d;
                if (stream_in_startofpacket == 1) begin
                    crc_q   <= '1;
                end
            end
        end
    end

    always_comb begin
        crc_d[0]  = crc_q[24] ^ crc_q[30] ^ data[0]   ^ data[6];
        crc_d[1]  = crc_q[24] ^ crc_q[25] ^ crc_q[30] ^ crc_q[31] ^ data[0]   ^ data[1]   ^ data[6]   ^ data[7];
        crc_d[2]  = crc_q[24] ^ crc_q[25] ^ crc_q[26] ^ crc_q[30] ^ crc_q[31] ^ data[0]   ^ data[1]   ^ data[2] ^ data[6] ^ data[7];
        crc_d[3]  = crc_q[25] ^ crc_q[26] ^ crc_q[27] ^ crc_q[31] ^ data[1]   ^ data[2]   ^ data[3]   ^ data[7];
        crc_d[4]  = crc_q[24] ^ crc_q[26] ^ crc_q[27] ^ crc_q[28] ^ crc_q[30] ^ data[0]   ^ data[2]   ^ data[3] ^ data[4] ^ data[6];
        crc_d[5]  = crc_q[24] ^ crc_q[25] ^ crc_q[27] ^ crc_q[28] ^ crc_q[29] ^ crc_q[30] ^ crc_q[31] ^ data[0] ^ data[1] ^ data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[7];
        crc_d[6]  = crc_q[25] ^ crc_q[26] ^ crc_q[28] ^ crc_q[29] ^ crc_q[30] ^ crc_q[31] ^ data[1]   ^ data[2] ^ data[4] ^ data[5] ^ data[6] ^ data[7];
        crc_d[7]  = crc_q[24] ^ crc_q[26] ^ crc_q[27] ^ crc_q[29] ^ crc_q[31] ^ data[0]   ^ data[2]   ^ data[3] ^ data[5] ^ data[7];
        crc_d[8]  = crc_q[0]  ^ crc_q[24] ^ crc_q[25] ^ crc_q[27] ^ crc_q[28] ^ data[0]   ^ data[1]   ^ data[3] ^ data[4];
        crc_d[9]  = crc_q[1]  ^ crc_q[25] ^ crc_q[26] ^ crc_q[28] ^ crc_q[29] ^ data[1]   ^ data[2]   ^ data[4] ^ data[5];
        crc_d[10] = crc_q[2]  ^ crc_q[24] ^ crc_q[26] ^ crc_q[27] ^ crc_q[29] ^ data[0]   ^ data[2]   ^ data[3] ^ data[5];
        crc_d[11] = crc_q[3]  ^ crc_q[24] ^ crc_q[25] ^ crc_q[27] ^ crc_q[28] ^ data[0]   ^ data[1]   ^ data[3] ^ data[4];
        crc_d[12] = crc_q[4]  ^ crc_q[24] ^ crc_q[25] ^ crc_q[26] ^ crc_q[28] ^ crc_q[29] ^ crc_q[30] ^ data[0] ^ data[1] ^ data[2] ^ data[4] ^ data[5] ^ data[6];
        crc_d[13] = crc_q[5]  ^ crc_q[25] ^ crc_q[26] ^ crc_q[27] ^ crc_q[29] ^ crc_q[30] ^ crc_q[31] ^ data[1] ^ data[2] ^ data[3] ^ data[5] ^ data[6] ^ data[7];
        crc_d[14] = crc_q[6]  ^ crc_q[26] ^ crc_q[27] ^ crc_q[28] ^ crc_q[30] ^ crc_q[31] ^ data[2]   ^ data[3] ^ data[4] ^ data[6] ^ data[7];
        crc_d[15] = crc_q[7]  ^ crc_q[27] ^ crc_q[28] ^ crc_q[29] ^ crc_q[31] ^ data[3]   ^ data[4]   ^ data[5] ^ data[7];
        crc_d[16] = crc_q[8]  ^ crc_q[24] ^ crc_q[28] ^ crc_q[29] ^ data[0]   ^ data[4]   ^ data[5];
        crc_d[17] = crc_q[9]  ^ crc_q[25] ^ crc_q[29] ^ crc_q[30] ^ data[1]   ^ data[5]   ^ data[6];
        crc_d[18] = crc_q[10] ^ crc_q[26] ^ crc_q[30] ^ crc_q[31] ^ data[2]   ^ data[6]   ^ data[7];
        crc_d[19] = crc_q[11] ^ crc_q[27] ^ crc_q[31] ^ data[3]   ^ data[7];
        crc_d[20] = crc_q[12] ^ crc_q[28] ^ data[4];
        crc_d[21] = crc_q[13] ^ crc_q[29] ^ data[5];
        crc_d[22] = crc_q[14] ^ crc_q[24] ^ data[0];
        crc_d[23] = crc_q[15] ^ crc_q[24] ^ crc_q[25] ^ crc_q[30] ^ data[0]   ^ data[1] ^ data[6];
        crc_d[24] = crc_q[16] ^ crc_q[25] ^ crc_q[26] ^ crc_q[31] ^ data[1]   ^ data[2] ^ data[7];
        crc_d[25] = crc_q[17] ^ crc_q[26] ^ crc_q[27] ^ data[2]   ^ data[3];
        crc_d[26] = crc_q[18] ^ crc_q[24] ^ crc_q[27] ^ crc_q[28] ^ crc_q[30] ^ data[0] ^ data[3] ^ data[4] ^ data[6];
        crc_d[27] = crc_q[19] ^ crc_q[25] ^ crc_q[28] ^ crc_q[29] ^ crc_q[31] ^ data[1] ^ data[4] ^ data[5] ^ data[7];
        crc_d[28] = crc_q[20] ^ crc_q[26] ^ crc_q[29] ^ crc_q[30] ^ data[2]   ^ data[5] ^ data[6];
        crc_d[29] = crc_q[21] ^ crc_q[27] ^ crc_q[30] ^ crc_q[31] ^ data[3]   ^ data[6] ^ data[7];
        crc_d[30] = crc_q[22] ^ crc_q[28] ^ crc_q[31] ^ data[4]   ^ data[7];
        crc_d[31] = crc_q[23] ^ crc_q[29] ^ data[5];
    end
    
    assign stream5.startofpacket = stream_in_startofpacket;
    assign stream5.endofpacket   = stream_in_endofpacket;
    assign stream5.valid         = stream_in_valid;
    assign stream5.data          = stream_in_data;
    assign stream5.error         = stream_in_error;

    assign stream_out_startofpacket = stream0.startofpacket;
    assign stream_out_endofpacket   = stream0.endofpacket;
    assign stream_out_valid         = stream0.valid;
    assign stream_out_data          = stream0.data;
    assign stream_out_error         = stream0.error;

    // initial begin
    //     $dumpfile("crc32.vcd");
    //     $dumpvars();
    // end


endmodule
