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
//  It also pins the controller/switch read path: which address returns which
//  port, and that the byte gets to the CPU without a clock edge, the way the
//  board's input buffers do it.
//
//  T80s is VHDL and stubbed out (see stubs.v) -- what is under test is the
//  clock divider, the interrupt raster position and the bus glue, not the CPU.
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

// Driveable so the input read path can be exercised; idle is all-ones because
// CTR1/CTR2 are negative logic.
reg [7:0] dsw_r  = 8'hFF;
reg [7:0] ctr1_r = 8'hFF;
reg [7:0] ctr2_r = 8'hFF;

wire [8:0] HP, VP;
wire PCLK;
wire [7:0] POUT, SND;
wire [1:0] LAMP;
wire [11:0] oRGB;
wire HBLK, VBLK, HSYN, VSYN;

fpga_NRX dut (
    .RESET(RESET), .CLK24M(CLK24M),
    .HP(HP), .VP(VP), .PCLK(PCLK), .POUT(POUT), .SND(SND),
    .DSW(dsw_r), .CTR1(ctr1_r), .CTR2(ctr2_r), .LAMP(LAMP),
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

task check_b(input [511:0] what, input [7:0] got, input [7:0] want);
begin
    if (got !== want) begin
        $display("  FAIL  %0s = %02h, expected %02h", what, got, want);
        tb_errors = tb_errors + 1;
    end else
        $display("  ok    %0s = %02h", what, got);
end
endtask

// Hold a memory read on the bus. The Z80 stub drives its outputs with
// continuous assignments, so force is the only way in; mr = RFSH_n & ~MREQ_n &
// ~RD_n is what the glue decodes. No clock edge is waited on deliberately --
// the point is that the input byte arrives without one.
task bus_read(input [15:0] addr);
begin
    force dut.z80.A      = addr;
    force dut.z80.RFSH_n = 1'b1;
    force dut.z80.MREQ_n = 1'b0;
    force dut.z80.RD_n   = 1'b0;
    #1;
end
endtask

task bus_idle;
begin
    release dut.z80.A;
    release dut.z80.RFSH_n;
    release dut.z80.MREQ_n;
    release dut.z80.RD_n;
    #1;
end
endtask

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

    // ---- input read path ----
    // Rally-X has no Namco I/O custom: IN0, IN1 and the switch card sit behind
    // buffers on the data bus, so a read is combinational and same-cycle. Three
    // distinct patterns, so a swapped mux leg fails rather than aliasing.
    ctr1_r = 8'hA5;
    ctr2_r = 8'h3C;
    dsw_r  = 8'h5A;

    bus_read(16'hA000); check_b("$A000 reads IN0 (CTR1)", dut.idt, 8'hA5);
    bus_read(16'hA080); check_b("$A080 reads IN1 (CTR2)", dut.idt, 8'h3C);
    bus_read(16'hA100); check_b("$A100 reads the switch card (DSW)", dut.idt, 8'h5A);

    // Unlatched: with the address parked on IN0, a button change reaches the
    // CPU's data bus with no clock edge in between. If someone registers this
    // path, the game samples last frame's buttons and this check fails.
    bus_read(16'hA000);
    ctr1_r = 8'hFE;                      // one button pressed, negative logic
    #1;
    check_b("IN0 is unlatched (no added cycle)", dut.idt, 8'hFE);

    bus_idle;
    check_b("data bus is quiet when no read is active", dut.idt, 8'h00);

    report("fpga_NRX");
end

initial begin
    #200_000_000;                       // 200 ms guard -- a few frames
    $display("FAIL  timeout");
    $finish;
end

endmodule
