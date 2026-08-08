`timescale 1ns/1ps
//============================================================================
//  HVGEN raster-geometry regression.
//
//  Checks the video timing generator against the Namco Rally-X board, whose
//  numbers MAME records in rallyx.cpp:
//
//      PIXEL_CLOCK = 18.432 MHz / 3 = 6.144 MHz
//      HTOTAL 384   HBSTART 288      -> 16.000 kHz line rate
//      VTOTAL 264   VBSTART 224      -> 60.6061 Hz frame rate
//
//  HVGEN's counters skip a range instead of wrapping at 512, so the totals are
//  easy to get wrong by one -- which is exactly what this guards.
//
//  Run:  iverilog -g2012 -o tb_hvgen.vvp sim/tb_hvgen.v src/fpga/rtl/hvgen.v
//        vvp tb_hvgen.vvp
//============================================================================
module tb_hvgen;

localparam integer EXP_HTOTAL = 384;
localparam integer EXP_VTOTAL = 264;
localparam integer EXP_VACT   = 224;

reg PCLK = 0;
always #81.380 PCLK = ~PCLK;           // 6.144 MHz

wire [8:0] HPOS, VPOS;
wire [11:0] oRGB;
wire HBLK, VBLK, HSYN, VSYN;

HVGEN dut (
    .HPOS(HPOS), .VPOS(VPOS), .PCLK(PCLK), .iRGB(12'hFFF),
    .oRGB(oRGB), .HBLK(HBLK), .VBLK(VBLK), .HSYN(HSYN), .VSYN(VSYN)
);

integer htotal, vtotal, vact, hsyn_w, vsyn_w;
integer errors;
real    fps, khz;

task check_i(input [255:0] what, input integer got, input integer want);
begin
    if (got !== want) begin
        $display("FAIL  %0s = %0d, expected %0d", what, got, want);
        errors = errors + 1;
    end else
        $display("ok    %0s = %0d", what, got);
end
endtask

initial begin
    errors = 0;
    htotal = 0; vtotal = 0; vact = 0; hsyn_w = 0; vsyn_w = 0;

    @(negedge VSYN); @(posedge VSYN);   // let the counters settle

    // ---- H total: pixel clocks between successive HPOS==0 ----
    // Sample on the falling edge, where the counters have settled. Land on a
    // negedge first: @(posedge VSYN) returns mid-edge, and HPOS is 0 there.
    @(negedge PCLK);
    while (HPOS !== 9'd0) @(negedge PCLK);
    htotal = 0;
    do begin
        if (HSYN === 1'b0) hsyn_w = hsyn_w + 1;
        @(negedge PCLK); htotal = htotal + 1;
    end while (HPOS !== 9'd0);

    // ---- V total / active lines: sample once per line at HPOS==0 ----
    while (VPOS !== 9'd0) @(negedge PCLK);
    vtotal = 0;
    begin : vloop
        forever begin
            // we are at HPOS==0 of some line
            vtotal = vtotal + 1;
            if (VBLK === 1'b0) vact   = vact + 1;
            if (VSYN === 1'b0) vsyn_w = vsyn_w + 1;
            while (HPOS === 9'd0) @(negedge PCLK);
            while (HPOS !== 9'd0) @(negedge PCLK);
            if (VPOS === 9'd0) disable vloop;
        end
    end

    khz = 6144.0 / htotal;
    fps = 6144000.0 / (htotal * vtotal);

    $display("");
    check_i("H total (pixels)", htotal, EXP_HTOTAL);
    check_i("V total (lines)",  vtotal, EXP_VTOTAL);
    check_i("V active (lines)", vact,   EXP_VACT);
    $display("info  HSYN low = %0d px (%0.2f us), VSYN low = %0d lines",
             hsyn_w, hsyn_w*1000.0/6144.0, vsyn_w);
    $display("");
    $display("      line rate  = %0.4f kHz  (board: 16.0000 kHz)", khz);
    $display("      frame rate = %0.4f Hz   (board: 60.6061 Hz)",  fps);
    $display("");

    if (errors == 0) $display("PASS  HVGEN raster matches the Namco board.");
    else             $display("FAIL  %0d mismatch(es).", errors);
    $finish;
end

// safety net so a broken counter can't hang CI
initial begin
    #(384.0 * 300.0 * 162.76 * 4);
    $display("FAIL  timeout -- counters never returned to origin");
    $finish;
end

endmodule
