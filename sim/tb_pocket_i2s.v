`timescale 1ns/1ps
//============================================================================
//  pocket_i2s timing -- the audio clock tree feeding the Pocket's DAC.
//
//  There is no audio PLL output; MCLK is squeezed out of the 74.25 MHz
//  housekeeping clock by a fractional accumulator, so it is not exact on any
//  single period -- only on average. That makes it the one clock here that a
//  single-period measurement would mis-report, and the one worth averaging
//  over thousands of edges.
//
//      MCLK = 12.288 MHz   (74.25 MHz * 245760 / 742500)
//      SCLK = MCLK / 4 = 3.072 MHz          <- the I2S bit clock
//      LRCK = SCLK / 64 = 48.000 kHz        <- the sample rate
//
//  64 bit clocks per frame is what makes SCLK land on 48 kHz * 64; if the
//  channel counter were wrong the sample rate would drift even with MCLK
//  perfect, so the divide ratios are checked as integers too.
//============================================================================
module tb_pocket_i2s;

localparam real MCLK_HZ = 12288000.0;
localparam real SCLK_HZ = 3072000.0;
localparam real LRCK_HZ = 48000.0;

reg iCLK_74 = 0;
always #6.734 iCLK_74 = ~iCLK_74;     // 74.25 MHz

wire I2S_MCLK, I2S_DAC, I2S_LRCK;

pocket_i2s dut (
    .iCLK_74(iCLK_74),
    .AUDIO_L(16'h1234), .AUDIO_R(16'h5678),
    .I2S_MCLK(I2S_MCLK), .I2S_DAC(I2S_DAC), .I2S_LRCK(I2S_LRCK)
);

`include "check.vh"

localparam integer N_MCLK = 20000;    // average over enough edges to see the
localparam integer N_SCLK = 4000;     // fractional accumulator settle
localparam integer N_LRCK = 40;

real t0, t1, mclk_hz, sclk_hz, lrck_hz;
integer i, bits;

initial begin
    $display("pocket_i2s");

    dut.audio_accum      = 22'd0;
    dut.audio_mclk       = 1'b0;
    dut.aud_mclk_divider = 2'd0;
    dut.audio_lrck_cnt   = 5'd0;
    dut.audio_lrck       = 1'b0;

    repeat (10) @(posedge iCLK_74);

    // ---- MCLK, averaged: a fractional divider jitters period to period ----
    @(posedge I2S_MCLK); t0 = $realtime;
    for (i = 0; i < N_MCLK; i = i + 1) @(posedge I2S_MCLK);
    t1 = $realtime;
    mclk_hz = 1.0e9 * N_MCLK / (t1 - t0);
    check_hz("MCLK (averaged)", mclk_hz, MCLK_HZ, 2000.0);

    // ---- SCLK = MCLK / 4, the I2S bit clock ----
    @(posedge dut.audio_sclk); t0 = $realtime;
    for (i = 0; i < N_SCLK; i = i + 1) @(posedge dut.audio_sclk);
    t1 = $realtime;
    sclk_hz = 1.0e9 * N_SCLK / (t1 - t0);
    check_hz("SCLK bit clock (averaged)", sclk_hz, SCLK_HZ, 500.0);
    check_i("MCLK : SCLK ratio", $rtoi(mclk_hz/sclk_hz + 0.5), 4);

    // ---- LRCK = the sample rate the Pocket actually consumes ----
    @(posedge I2S_LRCK); t0 = $realtime;
    for (i = 0; i < N_LRCK; i = i + 1) @(posedge I2S_LRCK);
    t1 = $realtime;
    lrck_hz = 1.0e9 * N_LRCK / (t1 - t0);
    check_hz("LRCK sample rate (averaged)", lrck_hz, LRCK_HZ, 10.0);

    // ---- 64 bit clocks per stereo frame, 32 per channel ----
    bits = 0;
    @(posedge I2S_LRCK);
    @(negedge dut.audio_sclk);
    while (I2S_LRCK === 1'b1) begin
        @(negedge dut.audio_sclk);
        bits = bits + 1;
    end
    check_i("bit clocks per channel", bits, 32);
    check_i("bit clocks per frame", bits*2, 64);
    check_i("SCLK : LRCK ratio", $rtoi(sclk_hz/lrck_hz + 0.5), 64);

    report("pocket_i2s");
end

initial begin
    #20_000_000;                        // 20 ms guard
    $display("FAIL  timeout");
    $finish;
end

endmodule
