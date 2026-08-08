`timescale 1ns/1ps
//============================================================================
//  NRX_BANG timing.
//
//  The explosion generator runs its LFSR, envelope and high-pass off a single
//  2 kHz enable divided from the 24.576 MHz master clock. Both the noise
//  colour and the length of the bang follow from that rate, so this checks:
//
//    - ce_2k is exactly 24.576 MHz / 12288 = 2000 Hz
//    - one and only one envelope tick happens per ce_2k
//    - the burst loads BURST_LEN = 3584 ticks -> 3584 / 2000 = 1.792 s
//
//  Burst length is checked by watching the counter load and decrement rather
//  than by simulating 1.8 s of silence, which would be ~44M clock edges.
//============================================================================
module tb_nrx_bang;

localparam real    MASTER_HZ  = 24576000.0;
localparam real    CE_HZ      = 2000.0;
localparam integer BURST_LEN  = 3584;

reg CLK24M = 0;
always #20.345 CLK24M = ~CLK24M;      // 24.576 MHz

reg RESET = 1;
reg BANG  = 0;
wire [5:0] OUT;

NRX_BANG dut (.CLK24M(CLK24M), .RESET(RESET), .BANG(BANG), .OUT(OUT));

`include "check.vh"

real t0, t1;
integer ticks, decrements;
real burst_seconds;

initial begin
    $display("NRX_BANG");

    repeat (4) @(posedge CLK24M);
    RESET = 0;
    @(posedge CLK24M);

    // ---- idle level: silence must sit at mid-scale, not at 0 ----
    check_i("idle OUT (mid-scale)", OUT, 32);

    // ---- ce_2k rate ----
    @(posedge dut.ce_2k); t0 = $realtime;
    @(posedge dut.ce_2k); t1 = $realtime;
    check_hz("ce_2k", 1.0e9/(t1-t0), CE_HZ, 0.5);

    // ---- one envelope tick per ce_2k, and the burst loads to BURST_LEN ----
    @(negedge CLK24M);
    BANG = 1;
    @(posedge dut.ce_2k);
    @(negedge CLK24M);                 // let the load settle
    check_i("burst load", dut.burst, BURST_LEN);
    check_i("envelope load", dut.env, 12'hFFF);
    BANG = 0;

    // count decrements over 50 enable ticks -- exactly one per tick
    decrements = 0;
    ticks = 0;
    while (ticks < 50) begin
        @(posedge dut.ce_2k);
        @(negedge CLK24M);
        decrements = decrements + 1;
        ticks = ticks + 1;
    end
    check_i("burst after 50 ticks", dut.burst, BURST_LEN - decrements);

    burst_seconds = BURST_LEN / CE_HZ;
    $display("  info  burst = %0d ticks / %0.0f Hz = %0.3f s", BURST_LEN, CE_HZ, burst_seconds);

    // ---- the bang must actually move the output ----
    if (OUT === 6'd32) begin
        $display("  FAIL  output never left idle during the burst");
        tb_errors = tb_errors + 1;
    end else
        $display("  ok    output is swinging during the burst (OUT = %0d)", OUT);

    report("NRX_BANG");
end

initial begin
    #50_000_000;                        // 50 ms guard
    $display("FAIL  timeout");
    $finish;
end

endmodule
