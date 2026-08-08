`timescale 1ns/1ps
//============================================================================
//  NRX_VIDEO timing -- the pixel clock the whole raster hangs off.
//
//  The board runs pixels at 18.432 MHz / 3 = 6.144 MHz. Here that comes from
//  dividing the 24.576 MHz master by four, through two chained toggles.
//  PCLK is what HVGEN counts, so if this rate is wrong every number in
//  tb_hvgen is wrong too.
//
//  NRX_SPRITE, instantiated inside, builds its OWN divider off the same
//  VCLKx4. Nothing ties the two together except that both power up at zero --
//  so this also checks they agree on rate and stay in step.
//
//  NOTE: VCLK, VCLKx2 and the sprite's clkcnt have no initial value and no
//  reset; under Icarus they stay X forever. Forced below to the zero the
//  hardware powers up with.
//============================================================================
module tb_nrx_video;

localparam real MASTER_HZ = 24576000.0;
localparam real PIXEL_HZ  = 6144000.0;

reg VCLKx4 = 0;
always #20.345 VCLKx4 = ~VCLKx4;      // 24.576 MHz

reg [8:0] HPOSi = 0, VPOSi = 0;
reg CPUCLK = 0;
wire PCLK;
wire [7:0] POUT, CPUDO;
wire CPUDT;

NRX_VIDEO dut (
    .VCLKx4(VCLKx4), .HPOSi(HPOSi), .VPOSi(VPOSi), .PCLK(PCLK), .POUT(POUT),
    .CPUCLK(CPUCLK), .CPUADDR(16'h0), .CPUDI(8'h0), .CPUDO(CPUDO),
    .CPUME(1'b0), .CPUWE(1'b0), .CPUDT(CPUDT),
    .ROMCL(VCLKx4), .ROMAD(16'h0), .ROMDT(8'h0), .ROMEN(1'b0),
    .hs_address(16'h0), .hs_data_in(8'h0), .hs_data_out(),
    .hs_write(1'b0), .hs_access(1'b0)
);

`include "check.vh"

real t0, t1, thigh, pclk_hz, x2_hz, spr_hz, duty, skew0, skew;
integer mismatches, samples;

initial begin
    $display("NRX_VIDEO");

    // power-up state the hardware gives us but the RTL does not declare
    dut.VCLK          = 1'b0;
    dut.VCLKx2        = 1'b0;
    dut.speng.clkcnt  = 2'b00;

    repeat (4) @(posedge VCLKx4);

    // ---- VCLKx2 = master / 2 ----
    @(posedge dut.VCLKx2); t0 = $realtime;
    @(posedge dut.VCLKx2); t1 = $realtime;
    x2_hz = 1.0e9/(t1-t0);
    check_hz("VCLKx2", x2_hz, MASTER_HZ/2.0, 200.0);

    // ---- PCLK = master / 4 = the board's pixel clock ----
    @(posedge PCLK); t0 = $realtime;
    @(negedge PCLK); thigh = $realtime;
    @(posedge PCLK); t1 = $realtime;
    pclk_hz = 1.0e9/(t1-t0);
    duty = 100.0*(thigh-t0)/(t1-t0);
    check_hz("PCLK (pixel clock)", pclk_hz, PIXEL_HZ, 100.0);
    if (duty < 49.0 || duty > 51.0) begin
        $display("  FAIL  PCLK duty = %0.1f%%, expected 50%%", duty);
        tb_errors = tb_errors + 1;
    end else
        $display("  ok    PCLK duty = %0.1f%%", duty);

    // ---- the sprite engine's private divider must land on the same rate ----
    @(posedge dut.speng.VCLK); t0 = $realtime;
    @(posedge dut.speng.VCLK); t1 = $realtime;
    spr_hz = 1.0e9/(t1-t0);
    check_hz("sprite VCLK", spr_hz, PIXEL_HZ, 100.0);

    // ---- and hold a constant phase against the video divider ----
    // Two independent dividers off one source. They need not be in phase --
    // they sit a quarter pixel apart -- but that offset must never change,
    // or sprite pixels would slide against background pixels.
    @(posedge dut.VCLK); t0 = $realtime;
    @(posedge dut.speng.VCLK);
    skew0 = $realtime - t0;

    // 1 ps tolerance: $realtime is a real, and the clock period is not a whole
    // number of ns, so exact equality would trip on rounding rather than drift.
    mismatches = 0;
    samples    = 0;
    repeat (500) begin
        @(posedge dut.VCLK); t0 = $realtime;
        @(posedge dut.speng.VCLK);
        skew = $realtime - t0;
        samples = samples + 1;
        if ((skew - skew0 > 0.001) || (skew0 - skew > 0.001))
            mismatches = mismatches + 1;
    end
    if (mismatches == 0)
        $display("  ok    sprite VCLK holds a constant %0.1f ns (%0.0f deg) offset over %0d pixels",
                 skew0, 360.0*skew0*PIXEL_HZ/1.0e9, samples);
    else begin
        $display("  FAIL  video/sprite VCLK phase drifts on %0d of %0d pixels",
                 mismatches, samples);
        tb_errors = tb_errors + 1;
    end

    report("NRX_VIDEO");
end

initial begin
    #10_000_000;                        // 10 ms guard
    $display("FAIL  timeout");
    $finish;
end

endmodule
