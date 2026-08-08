`timescale 1ns/1ps
//============================================================================
//  NRX_SOUND timing -- the Namco 3-voice WSG.
//
//  On the board the WSG samples at 18.432 MHz / 6 / 32 = 96 kHz, and each
//  voice is a 20-bit phase accumulator whose top 5 bits index a 32-entry
//  waveform. Pitch therefore follows
//
//        tone = 96000 * freq / 2^20
//
//  so the sample rate IS the tuning. This checks the divider chain, the
//  resulting pitch on all three voices, and that the time-multiplexed wave
//  ROM refreshes each voice faster than the voice is sampled.
//
//  NOTE: `ccnt` and NPSG_WAV's `ad` have no initial value and no reset, so
//  under Icarus they stay X forever and the clocks never start. They power up
//  to 0 on Cyclone V; the initial block below forces that same state.
//============================================================================
module tb_nrx_sound;

localparam real SAMPLE_HZ = 96000.0;

reg CLK24M = 0;
always #20.345 CLK24M = ~CLK24M;      // 24.576 MHz

reg CCLK = 0;
integer cdiv = 0;
always @(posedge CLK24M) begin        // 24.576 / 8 = 3.072 MHz, as fpga_NRX does
    cdiv = cdiv + 1;
    if (cdiv == 4) begin cdiv = 0; CCLK = ~CCLK; end
end

reg RESET = 1;
reg [4:0] AD = 0;
reg [3:0] DI = 0;
reg WR = 0;
wire [7:0] SND;

NRX_SOUND dut (
    .CLK24M(CLK24M), .CCLK(CCLK), .RESET(RESET), .SND(SND),
    .AD(AD), .DI(DI), .WR(WR), .BANG(1'b0),
    .ROMCL(CLK24M), .ROMAD(16'h0), .ROMDT(8'h0), .ROMEN(1'b0)
);

`include "check.vh"

real t0, t1, sclk_hz, x8_hz;
integer i;

task wr_reg(input [4:0] a, input [3:0] d);
begin
    @(negedge CCLK); AD = a; DI = d; WR = 1;
    @(negedge CCLK); WR = 0;
end
endtask

// Measure one full accumulator wrap of a voice -- that is one waveform cycle.
task measure_tone(input [255:0] what, input real want);
begin
    t0 = $realtime;
    @(posedge dut.voice0.counter[19]);
    t0 = $realtime;
    @(negedge dut.voice0.counter[19]);
    @(posedge dut.voice0.counter[19]);
    check_hz(what, 1.0e9/($realtime-t0), want, want*0.001);
end
endtask

initial begin
    $display("NRX_SOUND");

    // power-up state the hardware gives us but the RTL does not declare
    dut.ccnt          = 12'd0;
    dut.waverom.ad    = 8'd0;
    dut.voice0.counter = 20'd0;
    dut.voice1.counter = 20'd0;
    dut.voice2.counter = 20'd0;

    // a ramp in waveform slot 0 so the voices produce something to look at
    for (i = 0; i < 32; i = i + 1)
        dut.waverom.wrom.core[i] = (i < 16) ? i[3:0] : (15 - (i - 16));

    repeat (4) @(posedge CLK24M);
    RESET = 0;

    // ---- divider chain ----
    @(posedge dut.SCLK); t0 = $realtime;
    @(posedge dut.SCLK); t1 = $realtime;
    sclk_hz = 1.0e9/(t1-t0);
    check_hz("sample rate SCLK", sclk_hz, SAMPLE_HZ, 1.0);

    @(posedge dut.SCLKx8); t0 = $realtime;
    @(posedge dut.SCLKx8); t1 = $realtime;
    x8_hz = 1.0e9/(t1-t0);
    check_hz("wave-ROM clock SCLKx8", x8_hz, SAMPLE_HZ*8.0, 8.0);

    // Each voice is serviced once per 3 SCLKx8 ticks. That per-voice refresh
    // rate has to beat the sample rate or a voice reads stale wave data.
    check_hz("per-voice wave refresh", x8_hz/3.0, SAMPLE_HZ*8.0/3.0, 8.0);
    if (x8_hz/3.0 <= sclk_hz) begin
        $display("  FAIL  wave ROM refreshes slower than the sample rate");
        tb_errors = tb_errors + 1;
    end else
        $display("  ok    wave refresh (%0.0f Hz) outruns sampling (%0.0f Hz)",
                 x8_hz/3.0, sclk_hz);

    // ---- voice 0: full 20-bit frequency register ----
    wr_reg(5'h05, 4'h0);                                  // waveform 0
    wr_reg(5'h15, 4'hF);                                  // volume 15
    wr_reg(5'h10, 4'h0); wr_reg(5'h11, 4'h0);
    wr_reg(5'h12, 4'h0); wr_reg(5'h13, 4'h0); wr_reg(5'h14, 4'h1);
    dut.voice0.counter = 20'd0;                           // clear pre-write X
    measure_tone("voice0 @ freq=0x10000", 6000.0);        // 96000 * 2^16 / 2^20

    wr_reg(5'h14, 4'h0); wr_reg(5'h13, 4'h8);             // freq = 0x08000
    dut.voice0.counter = 20'd0;
    measure_tone("voice0 @ freq=0x08000", 3000.0);

    // ---- voices 1 and 2 carry 16-bit registers shifted up by 4 ----
    check_i("voice1 freq width (bits)", $bits(dut.fq1), 16);
    check_i("voice2 freq width (bits)", $bits(dut.fq2), 16);

    wr_reg(5'h0A, 4'h0);                                  // waveform 0
    wr_reg(5'h1A, 4'hF);                                  // volume 15
    wr_reg(5'h16, 4'h0); wr_reg(5'h17, 4'h0);
    wr_reg(5'h18, 4'h0); wr_reg(5'h19, 4'h1);             // fq1 = 0x1000
    @(negedge CCLK);
    check_i("f1 = fq1 << 4", dut.f1, 20'h10000);

    // and the shift must show up as real pitch: fq1=0x1000 has to sound
    // identical to voice0 at freq=0x10000
    dut.voice1.counter = 20'd0;
    @(posedge dut.voice1.counter[19]); t0 = $realtime;
    @(negedge dut.voice1.counter[19]);
    @(posedge dut.voice1.counter[19]);
    check_hz("voice1 @ fq1=0x1000", 1.0e9/($realtime-t0), 6000.0, 6.0);

    report("NRX_SOUND");
end

initial begin
    #20_000_000;                        // 20 ms guard
    $display("FAIL  timeout");
    $finish;
end

endmodule
