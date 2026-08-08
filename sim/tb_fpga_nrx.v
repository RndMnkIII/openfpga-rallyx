`timescale 1ns/1ps
//============================================================================
//  fpga_NRX timing -- CPU clock and the frame interrupt.
//
//  The board clocks its Z80 at 18.432 MHz / 6 = 3.072 MHz and interrupts it
//  once per frame at the top of vertical blanking. Rally-X paces all of its
//  game logic off that interrupt, so the interrupt rate IS the game speed --
//  it has to land on the raster's 60.6061 Hz, not merely "about 60".
//
//  HVGEN is wired up exactly as core_top does it, so this measures the real
//  closed loop: fpga_NRX drives PCLK, HVGEN counts it, and the resulting
//  HP/VP feed the vblank strobe back into the CPU glue.
//
//  T80s is VHDL and stubbed out (see stubs.v) -- what is under test is the
//  clock divider and the interrupt raster position, not the CPU.
//
//  NOTE: the divider regs have no initial value and no reset; forced below to
//  the zero the hardware powers up with.
//============================================================================
module tb_fpga_nrx;

localparam real MASTER_HZ = 24576000.0;
localparam real CPU_HZ    = 3072000.0;
localparam real FRAME_HZ  = 60.60606;

reg CLK24M = 0;
always #20.345 CLK24M = ~CLK24M;      // 24.576 MHz

reg RESET = 1;
wire [8:0] HP, VP;
wire PCLK;
wire [7:0] POUT, SND;
wire [1:0] LAMP;
wire [11:0] oRGB;
wire HBLK, VBLK, HSYN, VSYN;

fpga_NRX dut (
    .RESET(RESET), .CLK24M(CLK24M),
    .HP(HP), .VP(VP), .PCLK(PCLK), .POUT(POUT), .SND(SND),
    .DSW(8'hFF), .CTR1(8'hFF), .CTR2(8'hFF), .LAMP(LAMP),
    .ROMCL(CLK24M), .ROMAD(16'h0), .ROMDT(8'h0), .ROMEN(1'b0),
    .pause(1'b0),
    .hs_address(16'h0), .hs_data_in(8'h0), .hs_data_out(),
    .hs_write(1'b0), .hs_access(1'b0)
);

HVGEN hvgen (
    .HPOS(HP), .VPOS(VP), .PCLK(PCLK), .iRGB(12'h0),
    .oRGB(oRGB), .HBLK(HBLK), .VBLK(VBLK), .HSYN(HSYN), .VSYN(VSYN)
);

`include "check.vh"

real t0, t1, thigh, cclk_hz, x2_hz, duty, frame_hz;
integer in_blank;

initial begin
    $display("fpga_NRX");

    // power-up state the hardware gives us but the RTL does not declare
    dut._CCLK               = 3'd0;
    dut.video.VCLK          = 1'b0;
    dut.video.VCLKx2        = 1'b0;
    dut.video.speng.clkcnt  = 2'b00;
    dut.sound.ccnt          = 12'd0;
    dut.sound.waverom.ad    = 8'd0;

    repeat (8) @(posedge CLK24M);
    RESET = 0;

    // ---- CPU clock = master / 8 ----
    @(posedge dut.CCLK); t0 = $realtime;
    @(negedge dut.CCLK); thigh = $realtime;
    @(posedge dut.CCLK); t1 = $realtime;
    cclk_hz = 1.0e9/(t1-t0);
    duty = 100.0*(thigh-t0)/(t1-t0);
    check_hz("Z80 clock CCLK", cclk_hz, CPU_HZ, 100.0);
    if (duty < 49.0 || duty > 51.0) begin
        $display("  FAIL  CCLK duty = %0.1f%%, expected 50%%", duty);
        tb_errors = tb_errors + 1;
    end else
        $display("  ok    CCLK duty = %0.1f%%", duty);

    @(posedge dut.CCLKx2); t0 = $realtime;
    @(posedge dut.CCLKx2); t1 = $realtime;
    x2_hz = 1.0e9/(t1-t0);
    check_hz("CCLKx2", x2_hz, CPU_HZ*2.0, 200.0);
    check_i("CCLKx2 : CCLK ratio", $rtoi(x2_hz/cclk_hz + 0.5), 2);

    // ---- frame interrupt ----
    // vblk is the strobe that latches the CPU's frame interrupt. It must fire
    // once per frame, inside vertical blanking, at the raster's frame rate.
    @(posedge dut.vblk); t0 = $realtime;
    in_blank = (VBLK === 1'b1);
    @(negedge dut.vblk);
    @(posedge dut.vblk); t1 = $realtime;
    frame_hz = 1.0e9/(t1-t0);

    check_hz("frame interrupt rate", frame_hz, FRAME_HZ, 0.05);
    check_i("interrupt line (VP)", VP, 224);
    if (in_blank)
        $display("  ok    interrupt fires inside vertical blanking");
    else begin
        $display("  FAIL  interrupt fires while the picture is live");
        tb_errors = tb_errors + 1;
    end

    $display("  info  one interrupt every %0.3f ms", 1000.0/frame_hz);

    report("fpga_NRX");
end

initial begin
    #200_000_000;                       // 200 ms guard -- a few frames
    $display("FAIL  timeout");
    $finish;
end

endmodule
