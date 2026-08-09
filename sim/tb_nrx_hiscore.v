`timescale 1ns/1ps
//============================================================================
//  NRX_HISCORE -- putting the saved score back on the panel, and taking it
//  off again.
//
//  The row lives at $8060-$8067 in vram0, so this drives the real NRX_VIDEO
//  rather than a model of it: the block RAM, the port the CPU normally owns,
//  and the mux that hands it over are all the ones the game sees.
//
//  Every row below is a real one. RX_DEFAULT was read off a Pocket running
//  this core, and the rest come from the score table the ROM draws from --
//  rallyx.rom 0x2207 onwards, nrallyx.rom 0x24C9 onwards. The trailing zero is
//  character $30 where the other digits are $00-$09, and the panel reads
//  $8064-$8067 then $8060-$8063 rather than straight up from $8060. Both cost
//  a hardware pass to learn, so they are pinned down here rather than left to
//  a comment.
//
//  NOTE: VCLK, VCLKx2 and the sprite engine's clkcnt have no initial value
//  and no reset; under Icarus they stay X forever. Forced below to the zero
//  the hardware powers up with, same as tb_nrx_video.
//============================================================================
module tb_nrx_hiscore;

// Panel rows, packed with $8060 in the low byte -- RAM order, NOT the order
// they appear on screen. The panel reads $8064-$8067 then $8060-$8063, so a
// row that displays "   20000" sits in RAM as 00 00 00 30 40 40 40 02. Getting
// this backwards is what put "7650   8" on a Pocket, so the display string is
// written against every row below and the packing is worked from it.
localparam [63:0] RX_DEFAULT  = 64'h0240_4040_3000_0000;  // "   20000", measured
localparam [63:0] ALT_DEFAULT = 64'h0140_4040_3000_0000;  // "   10000", ROM table
localparam [63:0] BIG_DEFAULT = 64'h0840_4040_3000_0000;  // "   80000", ROM table
localparam [63:0] SAVED       = 64'h0840_4040_3005_0607;  // "   87650"
localparam [63:0] NRX_SAVED   = 64'h0440_4040_3000_0005;  // "   45000"
localparam [63:0] NO_SAVE     = {64{1'b1}};
// a four-byte file in an eight-byte slot: APF writes what it has, the rest of
// the register keeps the ones it powered up with
localparam [63:0] TRUNCATED   = 64'hFFFF_FFFF_3005_0607;

// These two disagree depending on which order you read them in. Compared down
// the panel they are 19000 and 90000, so the save loses and must not be put
// back. Compared in RAM order they come out 90000001 and 9, so a module that
// read the row in address order would overwrite the panel. That is exactly the
// bug that shipped, so it gets its own case.
localparam [63:0] SAVE_19000  = 64'h0140_4040_3000_0009;  // "   19000"
localparam [63:0] PANEL_90000 = 64'h0940_4040_3000_0000;  // "   90000"

reg clk = 0;
always #20.345 clk = ~clk;              // 24.576 MHz

reg [3:0] cdiv = 0;
always @(posedge clk) cdiv <= cdiv + 4'd1;
wire cpuclk = cdiv[2];                  // stand-in for CCLK, master / 8

reg reset = 1'b1;
reg loading = 1'b0;
reg [63:0] save_in = SAVED;

wire [15:0] hs_address;
wire  [7:0] hs_data_in, hs_data_out;
wire        hs_write, hs_access, pause_cpu;
wire [63:0] save_out;
wire        save_tgl;

NRX_HISCORE #(
    .START_WAIT   ( 32'd40 ),
    .RETRY_WAIT   ( 32'd20 ),
    .TRACK_WAIT   ( 32'd60 ),
    .PAUSE_PAD    ( 16'd4  ),
    .MAX_ATTEMPTS ( 4'd4   )
) hs (
    .clk(clk), .reset(reset), .loading(loading), .core_paused(1'b0),
    .save_in(save_in), .save_out(save_out), .save_tgl(save_tgl),
    .hs_address(hs_address), .hs_data_in(hs_data_in), .hs_data_out(hs_data_out),
    .hs_write(hs_write), .hs_access(hs_access), .pause_cpu(pause_cpu)
);

NRX_VIDEO vid (
    .VCLKx4(clk), .HPOSi(9'h0), .VPOSi(9'h0), .PCLK(), .POUT(),
    .CPUCLK(cpuclk), .CPUADDR(16'h0), .CPUDI(8'h0), .CPUDO(),
    .CPUME(1'b0), .CPUWE(1'b0), .CPUDT(),
    .ROMCL(clk), .ROMAD(16'h0), .ROMDT(8'h0), .ROMEN(1'b0),
    .hs_address(hs_address), .hs_data_in(hs_data_in), .hs_data_out(hs_data_out),
    .hs_write(hs_write), .hs_access(hs_access)
);

// `captured` latches for the life of a module, so each never-saved-before case
// needs a pair that has not yet seen a panel.
reg reset2 = 1'b1;
wire [15:0] hs2_address;
wire  [7:0] hs2_data_in, hs2_data_out;
wire        hs2_write, hs2_access, pause2_cpu;
wire [63:0] save2_out;
wire        save2_tgl;

NRX_HISCORE #(
    .START_WAIT(32'd40), .RETRY_WAIT(32'd20), .TRACK_WAIT(32'd60),
    .PAUSE_PAD(16'd4), .MAX_ATTEMPTS(4'd4)
) hs2 (
    .clk(clk), .reset(reset2), .loading(1'b0), .core_paused(1'b0),
    .save_in(NO_SAVE), .save_out(save2_out), .save_tgl(save2_tgl),
    .hs_address(hs2_address), .hs_data_in(hs2_data_in), .hs_data_out(hs2_data_out),
    .hs_write(hs2_write), .hs_access(hs2_access), .pause_cpu(pause2_cpu)
);

NRX_VIDEO vid2 (
    .VCLKx4(clk), .HPOSi(9'h0), .VPOSi(9'h0), .PCLK(), .POUT(),
    .CPUCLK(cpuclk), .CPUADDR(16'h0), .CPUDI(8'h0), .CPUDO(),
    .CPUME(1'b0), .CPUWE(1'b0), .CPUDT(),
    .ROMCL(clk), .ROMAD(16'h0), .ROMDT(8'h0), .ROMEN(1'b0),
    .hs_address(hs2_address), .hs_data_in(hs2_data_in), .hs_data_out(hs2_data_out),
    .hs_write(hs2_write), .hs_access(hs2_access)
);

reg reset3 = 1'b1;
wire [15:0] hs3_address;
wire  [7:0] hs3_data_in, hs3_data_out;
wire        hs3_write, hs3_access, pause3_cpu;
wire [63:0] save3_out;
wire        save3_tgl;

NRX_HISCORE #(
    .START_WAIT(32'd40), .RETRY_WAIT(32'd20), .TRACK_WAIT(32'd60),
    .PAUSE_PAD(16'd4), .MAX_ATTEMPTS(4'd4)
) hs3 (
    .clk(clk), .reset(reset3), .loading(1'b0), .core_paused(1'b0),
    .save_in(TRUNCATED), .save_out(save3_out), .save_tgl(save3_tgl),
    .hs_address(hs3_address), .hs_data_in(hs3_data_in), .hs_data_out(hs3_data_out),
    .hs_write(hs3_write), .hs_access(hs3_access), .pause_cpu(pause3_cpu)
);

NRX_VIDEO vid3 (
    .VCLKx4(clk), .HPOSi(9'h0), .VPOSi(9'h0), .PCLK(), .POUT(),
    .CPUCLK(cpuclk), .CPUADDR(16'h0), .CPUDI(8'h0), .CPUDO(),
    .CPUME(1'b0), .CPUWE(1'b0), .CPUDT(),
    .ROMCL(clk), .ROMAD(16'h0), .ROMDT(8'h0), .ROMEN(1'b0),
    .hs_address(hs3_address), .hs_data_in(hs3_data_in), .hs_data_out(hs3_data_out),
    .hs_write(hs3_write), .hs_access(hs3_access)
);

// a fourth pair, for a save that loses only when the row is read down the
// panel rather than up the address space
reg reset4 = 1'b1;
wire [15:0] hs4_address;
wire  [7:0] hs4_data_in, hs4_data_out;
wire        hs4_write, hs4_access, pause4_cpu;
wire [63:0] save4_out;
wire        save4_tgl;

NRX_HISCORE #(
    .START_WAIT(32'd40), .RETRY_WAIT(32'd20), .TRACK_WAIT(32'd60),
    .PAUSE_PAD(16'd4), .MAX_ATTEMPTS(4'd4)
) hs4 (
    .clk(clk), .reset(reset4), .loading(1'b0), .core_paused(1'b0),
    .save_in(SAVE_19000), .save_out(save4_out), .save_tgl(save4_tgl),
    .hs_address(hs4_address), .hs_data_in(hs4_data_in), .hs_data_out(hs4_data_out),
    .hs_write(hs4_write), .hs_access(hs4_access), .pause_cpu(pause4_cpu)
);

NRX_VIDEO vid4 (
    .VCLKx4(clk), .HPOSi(9'h0), .VPOSi(9'h0), .PCLK(), .POUT(),
    .CPUCLK(cpuclk), .CPUADDR(16'h0), .CPUDI(8'h0), .CPUDO(),
    .CPUME(1'b0), .CPUWE(1'b0), .CPUDT(),
    .ROMCL(clk), .ROMAD(16'h0), .ROMDT(8'h0), .ROMEN(1'b0),
    .hs_address(hs4_address), .hs_data_in(hs4_data_in), .hs_data_out(hs4_data_out),
    .hs_write(hs4_write), .hs_access(hs4_access)
);

`include "check.vh"

// ---- invariants, watched for the whole run ----
// The CPU reads zero out of $8000-$87FF for as long as hs_access is high, so
// it must be held in WAIT across every access. And hs_write must be low on
// both sides of an hs_access edge, because wram0_clk is a combinational mux
// and switching it glitches -- a glitch with no write enable costs nothing.
integer unpaused = 0;
integer glitched = 0;
reg     acc_d = 0, wr_d = 0;
always @(posedge clk) begin
    acc_d <= hs_access;
    wr_d  <= hs_write;
    if (hs_access && !pause_cpu) unpaused = unpaused + 1;
    if ((hs_access !== acc_d) && (hs_write || wr_d)) glitched = glitched + 1;
end

integer i;
reg [63:0] got;
reg        tgl_before;

task load_row(input [63:0] r);
begin
    for (i = 0; i < 8; i = i + 1)
        vid.vram0.core[11'h060 + i] = r[i*8 +: 8];
end
endtask

task read_row;
begin
    got = 64'd0;
    for (i = 0; i < 8; i = i + 1)
        got[i*8 +: 8] = vid.vram0.core[11'h060 + i];
end
endtask

task restart;
begin
    reset = 1'b1;
    repeat (4) @(posedge clk);
    reset = 1'b0;
end
endtask

task settle(input integer cycles);
begin
    repeat (cycles) @(posedge clk);
end
endtask

task expect_row(input [511:0] what, input [63:0] want);
begin
    read_row;
    if (got === want)
        $display("  ok    %0s = %h", what, got);
    else begin
        $display("  FAIL  %0s = %h, expected %h", what, got, want);
        tb_errors = tb_errors + 1;
    end
end
endtask

initial begin
    $display("NRX_HISCORE");

    // power-up state the hardware gives us but the RTL does not declare
    vid.VCLK  = 1'b0;  vid.VCLKx2  = 1'b0;  vid.speng.clkcnt  = 2'b00;
    vid2.VCLK = 1'b0;  vid2.VCLKx2 = 1'b0;  vid2.speng.clkcnt = 2'b00;
    vid3.VCLK = 1'b0;  vid3.VCLKx2 = 1'b0;  vid3.speng.clkcnt = 2'b00;
    vid4.VCLK = 1'b0;  vid4.VCLKx2 = 1'b0;  vid4.speng.clkcnt = 2'b00;

    repeat (4) @(posedge clk);

    // ---- 87650 beats the 20000 the Pocket actually showed us ----
    load_row(RX_DEFAULT);
    save_in = SAVED;
    restart;
    settle(200);
    expect_row("restore over the measured 20000 default", SAVED);

    // ---- and over the other factory rows the same ROM table holds ----
    load_row(ALT_DEFAULT);
    restart;
    settle(200);
    expect_row("restore over a 10000 default", SAVED);

    load_row(BIG_DEFAULT);
    restart;
    settle(200);
    expect_row("restore over an 80000 default", SAVED);

    // ---- a row the game has already beaten is left alone ----
    load_row(SAVED);
    restart;
    settle(600);
    expect_row("panel already at 87650, left alone", SAVED);
    check_i("stopped trying to restore", hs.restoring, 0);

    // ---- the trailing $30 zero is a digit, not junk: this is the capture
    //      that the first hardware pass silently threw away ----
    tgl_before = save_tgl;
    load_row(RX_DEFAULT);
    settle(300);
    if (save_out === RX_DEFAULT)
        $display("  ok    captured a row ending in char $30 = %h", save_out);
    else begin
        $display("  FAIL  captured %h, expected %h", save_out, RX_DEFAULT);
        tb_errors = tb_errors + 1;
    end
    if (save_tgl !== tgl_before)
        $display("  ok    save_tgl flipped to publish the capture");
    else begin
        $display("  FAIL  save_tgl did not flip on a changed row");
        tb_errors = tb_errors + 1;
    end

    // a row the game has not drawn yet must never reach the save file
    tgl_before = save_tgl;
    for (i = 0; i < 8; i = i + 1) vid.vram0.core[11'h060 + i] = 8'hA5;
    settle(300);
    check_i("junk row rejected, save_out unchanged", save_out === RX_DEFAULT, 1);
    check_i("junk row rejected, save_tgl steady",    save_tgl === tgl_before, 1);

    // ---- first run: no save file, so nothing is put back ----
    for (i = 0; i < 8; i = i + 1) vid2.vram0.core[11'h060 + i] = RX_DEFAULT[i*8 +: 8];
    reset2 = 1'b1; repeat (4) @(posedge clk); reset2 = 1'b0;
    settle(200);
    got = 64'd0;
    for (i = 0; i < 8; i = i + 1) got[i*8 +: 8] = vid2.vram0.core[11'h060 + i];
    check_i("no save file, panel untouched", got === RX_DEFAULT, 1);
    check_i("no save file, still captures",  save2_out === RX_DEFAULT, 1);

    // ---- a short or damaged file is not a score ----
    for (i = 0; i < 8; i = i + 1) vid3.vram0.core[11'h060 + i] = RX_DEFAULT[i*8 +: 8];
    reset3 = 1'b1; repeat (4) @(posedge clk); reset3 = 1'b0;
    settle(200);
    got = 64'd0;
    for (i = 0; i < 8; i = i + 1) got[i*8 +: 8] = vid3.vram0.core[11'h060 + i];
    check_i("short save file ignored", got === RX_DEFAULT, 1);

    // ---- a losing save does not overwrite, judged down the panel ----
    // 19000 against 90000. In address order these compare the other way round,
    // so a module reading the row the wrong way would restore here.
    for (i = 0; i < 8; i = i + 1) vid4.vram0.core[11'h060 + i] = PANEL_90000[i*8 +: 8];
    reset4 = 1'b1; repeat (4) @(posedge clk); reset4 = 1'b0;
    // before the startup timer has even run down, the loaded file must already
    // be published -- the Pocket flushes whatever was last published, so a
    // short session would otherwise write the power-up value over a real score
    settle(20);
    check_i("save file published before any capture", save4_out === SAVE_19000, 1);
    settle(580);
    got = 64'd0;
    for (i = 0; i < 8; i = i + 1) got[i*8 +: 8] = vid4.vram0.core[11'h060 + i];
    check_i("19000 does not overwrite a 90000 panel", got === PANEL_90000, 1);

    // ---- switching games must not carry a score across ----
    // hs has a Rally-X row captured by now. Load the other game: a slot write,
    // its own save file, its own factory row. The old score must not survive.
    load_row(ALT_DEFAULT);
    save_in = NRX_SAVED;
    loading = 1'b1;
    reset   = 1'b1;
    repeat (8) @(posedge clk);
    loading = 1'b0;
    reset   = 1'b0;
    settle(300);
    expect_row("game switch restores the new game's save", NRX_SAVED);

    // ---- but a DIP change reboots the game and must keep the running score --
    // Same reset, no slot write. save_in goes back to a smaller, older file to
    // prove it is ignored once a live row has been captured.
    load_row(ALT_DEFAULT);
    save_in = ALT_DEFAULT;
    restart;
    settle(400);
    expect_row("DIP-style reset keeps the running score", NRX_SAVED);

    // ---- invariants ----
    check_i("cycles with RAM access but no CPU pause", unpaused, 0);
    check_i("write enable live across an access edge", glitched, 0);

    report("NRX_HISCORE");
end

initial begin
    #10_000_000;                        // 10 ms guard
    $display("FAIL  timeout");
    $finish;
end

endmodule
