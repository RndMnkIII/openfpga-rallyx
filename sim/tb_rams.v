`timescale 1ns/1ps
//============================================================================
//  rams.v timing -- read latency of the memory primitives.
//
//  Every read port here is registered: data lands exactly one clock after the
//  address, never combinationally and never two clocks late. The video
//  pipeline is built around that single cycle -- NRX_VIDEO's HPOS = HPOSi + 2
//  and core_top's H_OFF = 1 are both compensating for fetch latency -- so if
//  a primitive ever changed to unregistered or extra-registered output, the
//  picture would shift and nothing else would complain.
//
//  LINEBUF1024_9 wraps a real altsyncram, so this runs against Quartus's own
//  simulation model when it can be found rather than a hand-written stand-in.
//============================================================================
module tb_rams;

reg CLK = 0;
always #10 CLK = ~CLK;                // 50 MHz, arbitrary -- latency is in cycles

reg CLKB = 0;
always #35 CLKB = ~CLKB;              // deliberately unrelated, for port independence

`include "check.vh"

// ---------------- DLROM: downloadable ROM, read port + write port ----------
reg  [7:0] rom_ad = 0;
wire [7:0] rom_do;
reg  [7:0] rom_wad = 0, rom_wdt = 0;
reg        rom_we = 0;
DLROM #(8,8) rom (CLK, rom_ad, rom_do, CLKB, rom_wad, rom_wdt, rom_we);

// ---------------- GSPRAM: single-port work RAM -----------------------------
reg  [7:0] sp_ad = 0, sp_di = 0;
reg        sp_we = 0;
wire [7:0] sp_do;
GSPRAM #(8,8) spram (CLK, sp_ad, sp_we, sp_di, sp_do);

// ---------------- GDPRAM: dual-port video RAM ------------------------------
reg  [7:0] dp_ad0 = 0;
wire [7:0] dp_do0;
reg  [7:0] dp_ad1 = 0, dp_di1 = 0;
reg        dp_we1 = 0;
wire [7:0] dp_do1;
GDPRAM #(8,8) dpram (CLK, dp_ad0, dp_do0, CLKB, dp_ad1, dp_we1, dp_di1, dp_do1);

// ---------------- LINEBUF1024_9: the sprite line buffer --------------------
reg  [9:0] lb_ad0 = 0;
reg        lb_we0 = 0;
wire [8:0] lb_do0;
reg  [9:0] lb_ad1 = 0;
reg        lb_we1 = 0;
reg  [8:0] lb_di1 = 0;
LINEBUF1024_9 lbuf (CLK, lb_ad0, lb_we0, lb_do0, CLKB, lb_ad1, lb_we1, lb_di1);

integer i;

initial begin
    $display("rams.v");

    // ---- DLROM: load through the write port, read back on the read port ----
    for (i = 0; i < 8; i = i + 1) begin
        @(negedge CLKB);
        rom_wad = i[7:0]; rom_wdt = 8'hA0 + i[7:0]; rom_we = 1;
    end
    @(negedge CLKB); rom_we = 0;

    // latency proper: settle on one address, switch to another, and confirm
    // the output still holds the OLD value until a clock edge has passed
    @(negedge CLK); rom_ad = 8'd0;
    @(posedge CLK); @(negedge CLK);
    check_i("DLROM data at address 0", rom_do, 8'hA0);

    @(negedge CLK); rom_ad = 8'd3;      // new address, no clock yet
    #1;
    check_i("DLROM holds old data before the clock", rom_do, 8'hA0);
    @(posedge CLK); @(negedge CLK);
    check_i("DLROM data one clock later", rom_do, 8'hA3);

    // ---- GSPRAM: registered read, and read-before-write on a collision ----
    @(negedge CLK); sp_ad = 8'd10; sp_di = 8'h5A; sp_we = 1;
    @(posedge CLK); @(negedge CLK); sp_we = 0;
    @(negedge CLK); sp_ad = 8'd10;
    @(posedge CLK); @(negedge CLK);
    check_i("GSPRAM stored value", sp_do, 8'h5A);

    @(negedge CLK); sp_ad = 8'd10; sp_di = 8'h77; sp_we = 1;
    @(posedge CLK); @(negedge CLK); sp_we = 0;
    check_i("GSPRAM read-during-write returns old data", sp_do, 8'h5A);
    @(negedge CLK); sp_ad = 8'd10;
    @(posedge CLK); @(negedge CLK);
    check_i("GSPRAM write did land", sp_do, 8'h77);

    // ---- GDPRAM: the two ports run on unrelated clocks ----
    @(negedge CLKB); dp_ad1 = 8'd20; dp_di1 = 8'h3C; dp_we1 = 1;
    @(posedge CLKB); @(negedge CLKB); dp_we1 = 0;
    repeat (4) @(posedge CLK);
    @(negedge CLK); dp_ad0 = 8'd20;
    @(posedge CLK); @(negedge CLK);
    check_i("GDPRAM cross-port read", dp_do0, 8'h3C);

    // ---- LINEBUF1024_9: write on port B, read (and clear) on port A ----
    @(negedge CLKB); lb_ad1 = 10'd100; lb_di1 = 9'h155; lb_we1 = 1;
    @(posedge CLKB); @(negedge CLKB); lb_we1 = 0;
    repeat (4) @(posedge CLK);

    @(negedge CLK); lb_ad0 = 10'd100; lb_we0 = 0;
    @(posedge CLK); @(negedge CLK);
    check_i("LINEBUF read-back", lb_do0, 9'h155);

    // reading with wren_a asserted writes zero back -- the line buffer self-clears
    @(negedge CLK); lb_ad0 = 10'd100; lb_we0 = 1;
    @(posedge CLK); @(negedge CLK); lb_we0 = 0;
    repeat (2) @(posedge CLK);
    @(negedge CLK); lb_ad0 = 10'd100;
    @(posedge CLK); @(negedge CLK);
    check_i("LINEBUF self-cleared after read", lb_do0, 9'h0);

    report("rams.v");
end

initial begin
    #200_000;
    $display("FAIL  timeout");
    $finish;
end

endmodule
