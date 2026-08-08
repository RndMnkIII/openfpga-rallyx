`timescale 1ns/1ps
//============================================================================
//  NRX_SPRITE timing -- does the scan fit in horizontal blanking?
//
//  The sprite engine does all its work while the beam is off-screen: it walks
//  the sprite list, then the radar-dot list, then renders into the line
//  buffer, all on VCLKx2 while HBLK is asserted. If that does not finish
//  before the picture restarts, sprites drop off the right-hand side.
//
//  So the number that matters is margin: cycles available in blanking versus
//  cycles the scan actually consumes. This drives the real HVGEN raster and
//  the same oHB = (HPOS > 288) that NRX_VIDEO feeds it.
//
//  NOTE: clkcnt has no initial value and no reset; forced below to the zero
//  the hardware powers up with.
//============================================================================
module tb_nrx_sprite;

localparam real PIXEL_HZ = 6144000.0;

reg VCLKx4 = 0;
always #20.345 VCLKx4 = ~VCLKx4;      // 24.576 MHz

// PCLK = VCLKx4 / 4, exactly as NRX_VIDEO derives it
reg [1:0] pdiv = 0;
always @(posedge VCLKx4) pdiv <= pdiv + 1'b1;
wire PCLK = pdiv[1];

wire [8:0] HPOSi, VPOSi;
wire HBLK_hv, VBLK_hv, HSYN, VSYN;
HVGEN hvgen (
    .HPOS(HPOSi), .VPOS(VPOSi), .PCLK(PCLK), .iRGB(12'h0),
    .oRGB(), .HBLK(HBLK_hv), .VBLK(VBLK_hv), .HSYN(HSYN), .VSYN(VSYN)
);

// NRX_VIDEO's view of the raster
wire [8:0] HPOS = HPOSi + 9'd2;
wire [8:0] VPOS = VPOSi + (HPOSi >= 9'd504);
wire       oHB  = (HPOS > 9'd288);

wire [10:0] SPRAADRS;
wire  [3:0] ARAMADRS;
wire [11:0] SPCHRADR;
wire  [7:0] DROMAD;
wire  [8:0] SPCOL;

NRX_SPRITE dut (
    VCLKx4, oHB, HPOS, VPOS,
    SPRAADRS, 16'h0000,
    ARAMADRS, 8'h00,
    SPCHRADR, 8'h00,
    DROMAD,   8'hFF,
    SPCOL
);

`include "check.vh"

real t0, t1, x2_hz, vclk_hz;
integer available, consumed, blank_px;
reg done;

initial begin
    $display("NRX_SPRITE");

    dut.clkcnt = 2'b00;                 // power-up state the RTL does not declare

    repeat (8) @(posedge VCLKx4);

    // ---- its private dividers ----
    @(posedge dut.VCLKx2); t0 = $realtime;
    @(posedge dut.VCLKx2); t1 = $realtime;
    x2_hz = 1.0e9/(t1-t0);
    check_hz("VCLKx2", x2_hz, PIXEL_HZ*2.0, 200.0);

    @(posedge dut.VCLK); t0 = $realtime;
    @(posedge dut.VCLK); t1 = $realtime;
    vclk_hz = 1.0e9/(t1-t0);
    check_hz("VCLK", vclk_hz, PIXEL_HZ, 100.0);

    // ---- budget: how wide is blanking? ----
    // Counted mid-pixel, on the falling edge, so the count is not sensitive to
    // which side of the oHB transition the sampling edge lands.
    @(posedge oHB);
    blank_px = 0;
    begin : measure
        forever begin
            @(negedge PCLK);
            if (oHB !== 1'b1) disable measure;
            blank_px = blank_px + 1;
        end
    end
    check_i("blanking width (pixels)", blank_px, 95);
    available = blank_px * 2;           // the engine runs at VCLKx2

    // ---- cost: cycles until the scan walks past the end of both lists ----
    @(posedge oHB);
    consumed = 0;
    done     = 1'b0;
    while (oHB === 1'b1 && !done) begin
        @(posedge dut.VCLKx2);
        consumed = consumed + 1;
        if (SPRAADRS >= 11'h40) done = 1'b1;
    end

    if (!done) begin
        $display("  FAIL  scan did not reach the end of the list within blanking");
        tb_errors = tb_errors + 1;
    end else if (consumed >= available) begin
        $display("  FAIL  scan used %0d of %0d cycles -- no margin", consumed, available);
        tb_errors = tb_errors + 1;
    end else
        $display("  ok    scan finished in %0d of %0d cycles (%0d spare, %0d%% margin)",
                 consumed, available, available - consumed,
                 (100*(available - consumed))/available);

    // ---- and it must be idle again once the picture restarts ----
    @(negedge oHB);
    @(posedge dut.VCLKx2);
    @(posedge dut.VCLKx2);
    check_i("SPRAADRS reset for the next line", SPRAADRS, 11'h14);

    report("NRX_SPRITE");
end

initial begin
    #10_000_000;                        // 10 ms guard
    $display("FAIL  timeout");
    $finish;
end

endmodule
