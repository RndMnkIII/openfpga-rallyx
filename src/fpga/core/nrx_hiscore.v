//============================================================================
//  High-score save and restore for Rally-X / New Rally-X.
//
//  Rally-X keeps no numeric high score. The eight bytes at $8060-$8067 ARE
//  the HI-SCORE row of the status panel, held as character codes, and the
//  game reads them back when the player's score catches up. Saving the high
//  score means copying those eight tiles out, and painting them back at a
//  moment when the game will not immediately redraw them.
//
//  That moment is boot. The panel comes up showing the game's factory score --
//  20000 on Rally-X, measured -- so we let the game settle, read the row, and
//  overwrite it only if what we have actually beats it. Comparing scores
//  rather than matching a known row is what lets one bitstream serve both
//  games with no per-game configuration.
//
//  The row is not in display order. nrx_video fetches the panel as
//  { VP[7:3], 2'b00, HP[5:3] } across HPOS 224 to 287, so the eight cells read
//  $8064-$8067 then $8060-$8063 left to right. See score_of below.
//
//  Reaching the RAM steals the CPU's port -- nrx_video forces V0DO to zero
//  while hs_access is high -- so every access pauses the Z80 either side of
//  itself. hs_write stays low across both edges of hs_access, because
//  wram0_clk is a combinational mux between ROMCL and CPUCLK and switching it
//  can glitch. A glitch with no write enable behind it costs nothing.
//============================================================================
module NRX_HISCORE #(
    // ~12.7 s at 24.576 MHz, the delay the MiSTer core waits before it first
    // looks at the panel. Long enough for boot and the first attract pass,
    // short enough that a restore lands before anyone has played a round.
    parameter [31:0] START_WAIT   = 32'h1298BE00,
    parameter [31:0] RETRY_WAIT   = 32'd12288000,  // 0.5 s between probes
    parameter [31:0] TRACK_WAIT   = 32'd24576000,  // 1 s between captures
    parameter [15:0] PAUSE_PAD    = 16'd32,        // CPU settle either side
    parameter [3:0]  MAX_ATTEMPTS = 4'd8
)(
    input  wire        clk,          // 24.576 MHz core clock
    input  wire        reset,        // active high, follows the game reset
    input  wire        loading,      // a data slot is being written; new game
    input  wire        core_paused,  // menu or user pause; holds the timers

    // save file, byte 0 is $8060 and byte 7 is $8067. All ones means the
    // Pocket had no file to load.
    input  wire [63:0] save_in,
    output reg  [63:0] save_out  = {64{1'b1}},
    output reg         save_tgl  = 1'b0,   // toggles when save_out is fresh

    output reg  [15:0] hs_address = 16'h0,
    output reg   [7:0] hs_data_in = 8'h0,
    input  wire  [7:0] hs_data_out,
    output reg         hs_write   = 1'b0,
    output reg         hs_access  = 1'b0,
    output reg         pause_cpu  = 1'b0
);

localparam [15:0] HS_BASE = 16'h8060;

localparam [2:0] S_WAIT  = 3'd0;   // counting down to the next access
localparam [2:0] S_OPEN  = 3'd1;   // CPU paused, waiting out the pad
localparam [2:0] S_SETUP = 3'd2;   // drive address, and data if writing
localparam [2:0] S_XFER  = 3'd3;   // the RAM clocks
localparam [2:0] S_STEP  = 3'd4;   // capture, then advance or finish
localparam [2:0] S_CLOSE = 3'd5;   // access down, pad out, release the CPU
localparam [2:0] S_JUDGE = 3'd6;   // decide what the pass just told us

reg  [2:0]  state    = S_WAIT;
reg  [31:0] timer    = START_WAIT;
reg  [15:0] pad      = 16'd0;
reg  [2:0]  idx      = 3'd0;
reg         op_write = 1'b0;       // 0 reads the row, 1 writes it back
reg  [63:0] row      = 64'd0;      // the row as last read out of the RAM

reg         restoring  = 1'b1;     // still trying to put a saved score back
reg  [3:0]  attempts   = 4'd0;
reg         captured   = 1'b0;     // a live row has been read at least once
reg         have_score = 1'b0;     // save_out holds something worth writing

function [7:0] byte_of;
    input [63:0] v;
    input  [2:0] i;
begin
    case (i)
    3'd0: byte_of = v[ 7: 0];
    3'd1: byte_of = v[15: 8];
    3'd2: byte_of = v[23:16];
    3'd3: byte_of = v[31:24];
    3'd4: byte_of = v[39:32];
    3'd5: byte_of = v[47:40];
    3'd6: byte_of = v[55:48];
    3'd7: byte_of = v[63:56];
    endcase
end
endfunction

// A panel character is a digit or the blank the game tests for with CP $40.
// The game draws digits from two places in the character ROM: $00-$09 for
// most of them and $30-$39 for the trailing zero, which are separate glyphs
// that both render as numerals. Measured on hardware, the Rally-X default row
// is 40 40 40 02 00 00 00 30 -- "   20000" -- so a check that only accepted
// $00-$09 threw away every real row as junk.
//
// An all-zero row is the power-up state of the block RAM rather than a score;
// the game always leaves blanks ahead of the leading digit.
function panel_char;
    input [7:0] c;
begin
    panel_char = (c == 8'h40) || (c <= 8'h09) || (c >= 8'h30 && c <= 8'h39);
end
endfunction

// The panel does not show this row in address order. nrx_video fetches it as
// { VP[7:3], 2'b00, HP[5:3] }, and the panel spans HPOS 224 to 287, so HP[5:3]
// runs 4,5,6,7,0,1,2,3 across the eight cells. The leftmost character on
// screen -- the most significant digit -- is $8064, and $8060 sits fifth.
//
// Both digit encodings carry their value in the low nibble and a blank is a
// leading zero, so reading the row in that order gives eight nibbles most
// significant first. Comparing those as one number is what decides whether a
// saved score is worth putting back.
function [31:0] score_of;
    input [63:0] r;
begin
    score_of = { r[35:32], r[43:40], r[51:48], r[59:56],     // $8064..$8067
                 r[ 3: 0], r[11: 8], r[19:16], r[27:24] };   // $8060..$8063
end
endfunction

wire row_sane = panel_char(row[ 7: 0]) & panel_char(row[15: 8]) &
                panel_char(row[23:16]) & panel_char(row[31:24]) &
                panel_char(row[39:32]) & panel_char(row[47:40]) &
                panel_char(row[55:48]) & panel_char(row[63:56]) &
                (row != 64'd0);

// The same test on the way in. A first run has no file and leaves save_in all
// ones, but the slot takes anything up to eight bytes, so a short or damaged
// file arrives as a part-written row -- and painting that onto the panel puts
// garbage tiles where the score should be. Nothing that fails here is worth
// restoring.
wire save_sane = panel_char(save_in[ 7: 0]) & panel_char(save_in[15: 8]) &
                 panel_char(save_in[23:16]) & panel_char(save_in[31:24]) &
                 panel_char(save_in[39:32]) & panel_char(save_in[47:40]) &
                 panel_char(save_in[55:48]) & panel_char(save_in[63:56]) &
                 (save_in != 64'd0);

// Put the saved score back only if it actually beats what the panel shows.
// That is the rule the feature means, and unlike matching a specific default
// row it does not care which game booted or which factory score it drew --
// Rally-X ships 20000 and the same ROM table holds 10000, 30000 and 40000.
wire gate_ok = row_sane && (score_of(save_out) > score_of(row));

always @(posedge clk) begin
    if (reset) begin
        state     <= S_WAIT;
        timer     <= START_WAIT;
        pad       <= 16'd0;
        idx       <= 3'd0;
        attempts  <= 4'd0;
        op_write  <= 1'b0;
        restoring <= 1'b1;
        hs_access <= 1'b0;
        hs_write  <= 1'b0;
        pause_cpu <= 1'b0;

        // Loading is the one reset that must forget. Switching between
        // Rally-X and New Rally-X from the core menu restarts the core
        // without necessarily reconfiguring the FPGA, so a score held over
        // from the last game would be painted into the next one. A slot write
        // means a different game is arriving, and the only score that counts
        // then is the one APF is loading with it.
        //
        // Everything else that resets the game -- a DIP change, the host
        // reset -- must NOT forget, or changing a switch would roll the
        // running score back to whatever was on the SD card at boot.
        if (loading) captured <= 1'b0;
    end else begin
        case (state)

        S_WAIT: begin
            hs_write <= 1'b0;
            if (timer != 32'd0) begin
                if (!core_paused) timer <= timer - 32'd1;
                // Take the save file while the startup timer runs, not while
                // reset is asserted. Reset lifts the same cycle the load
                // finishes, so priming there would sample save_in before the
                // loader had drained. Here there are twelve seconds of slack,
                // and once a live row has been captured the file stops being
                // the better answer.
                //
                // Publishing it is what keeps a good file intact when nothing
                // is ever captured: the Pocket reads back whatever was last
                // published, so without this a short session would flush the
                // power-up value over a real score. Comparing before assigning
                // makes this settle instead of toggling every cycle.
                if (!captured && save_out != save_in) begin
                    save_out   <= save_in;
                    have_score <= save_sane;
                    save_tgl   <= ~save_tgl;
                end
            end else if (restoring && !have_score) begin
                restoring <= 1'b0;          // nothing to put back
                timer     <= TRACK_WAIT;
            end else begin
                op_write  <= 1'b0;          // every pass starts by reading
                idx       <= 3'd0;
                pad       <= PAUSE_PAD;
                pause_cpu <= 1'b1;
                state     <= S_OPEN;
            end
        end

        S_OPEN: begin
            if (pad != 16'd0)
                pad <= pad - 16'd1;
            else begin
                hs_access <= 1'b1;
                state     <= S_SETUP;
            end
        end

        S_SETUP: begin
            hs_address <= HS_BASE + {13'd0, idx};
            if (op_write) begin
                hs_data_in <= byte_of(save_out, idx);
                hs_write   <= 1'b1;
            end
            state <= S_XFER;
        end

        S_XFER: begin
            hs_write <= 1'b0;               // one clock of write enable
            state    <= S_STEP;
        end

        S_STEP: begin
            if (!op_write) begin
                case (idx)
                3'd0: row[ 7: 0] <= hs_data_out;
                3'd1: row[15: 8] <= hs_data_out;
                3'd2: row[23:16] <= hs_data_out;
                3'd3: row[31:24] <= hs_data_out;
                3'd4: row[39:32] <= hs_data_out;
                3'd5: row[47:40] <= hs_data_out;
                3'd6: row[55:48] <= hs_data_out;
                3'd7: row[63:56] <= hs_data_out;
                endcase
            end
            if (idx == 3'd7) begin
                pad   <= PAUSE_PAD;
                state <= S_CLOSE;
            end else begin
                idx   <= idx + 3'd1;
                state <= S_SETUP;
            end
        end

        S_CLOSE: begin
            hs_access <= 1'b0;
            hs_write  <= 1'b0;
            if (pad != 16'd0)
                pad <= pad - 16'd1;
            else begin
                pause_cpu <= 1'b0;
                state     <= S_JUDGE;
            end
        end

        S_JUDGE: begin
            state <= S_WAIT;
            timer <= TRACK_WAIT;
            if (op_write) begin
                restoring <= 1'b0;          // the saved row is on the panel
            end else if (restoring) begin
                if (gate_ok) begin
                    op_write  <= 1'b1;
                    idx       <= 3'd0;
                    pad       <= PAUSE_PAD;
                    pause_cpu <= 1'b1;
                    state     <= S_OPEN;
                end else if (attempts != MAX_ATTEMPTS - 4'd1) begin
                    attempts <= attempts + 4'd1;
                    timer    <= RETRY_WAIT;
                end else begin
                    restoring <= 1'b0;      // the panel has moved on; leave it
                end
            end else if (row_sane) begin
                captured   <= 1'b1;
                have_score <= 1'b1;
                if (row != save_out) begin
                    save_out <= row;
                    save_tgl <= ~save_tgl;
                end
            end
        end

        default: state <= S_WAIT;
        endcase
    end
end

endmodule
