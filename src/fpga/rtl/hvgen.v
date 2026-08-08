//============================================================================
//  HVGEN - Rally-X video timing generator
//  Extracted from MiSTer Arcade-RallyX.sv (MrX-8B / MiSTer-devel).
//  Produces H/V position for the game core and HSync/VSync/blank for output.
//============================================================================

module HVGEN
(
	output  [8:0]		HPOS,
	output  [8:0]		VPOS,
	input 				PCLK,
	input	 [11:0]		iRGB,

	output reg [11:0]	oRGB,
	output reg			HBLK = 1,
	output reg			VBLK = 1,
	output reg			HSYN = 1,
	output reg			VSYN = 1
);

// Raster geometry, matching the Namco board: 384 pixels x 264 lines off the
// 6.144 MHz pixel clock -> 16.000 kHz line rate, 60.6061 Hz frame rate.
// Both counters skip a range rather than wrapping, so the totals are
// (0..last_before_jump) + (jump_target..511), not 512.
//   H: 0..342 + 471..511 = 384
//   V: 0..233 + 482..511 = 264
reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt;
assign VPOS = vcnt;

always @(posedge PCLK) begin
	case (hcnt)
		288: begin HBLK <= 1; hcnt <= hcnt + 9'd1; end
		311: begin HSYN <= 0; hcnt <= hcnt + 9'd1; end
		342: begin HSYN <= 1; hcnt <= 9'd471;    end
		511: begin HBLK <= 0; hcnt <= 9'd0;
			case (vcnt)
				223: begin VBLK <= 1; vcnt <= vcnt + 9'd1; end
				226: begin VSYN <= 0; vcnt <= vcnt + 9'd1; end
				233: begin VSYN <= 1; vcnt <= 9'd482;	  end
				511: begin VBLK <= 0; vcnt <= 9'd0;		  end
				default: vcnt <= vcnt + 9'd1;
			endcase
		end
		default: hcnt <= hcnt + 9'd1;
	endcase
	oRGB <= (HBLK|VBLK) ? 12'h0 : iRGB;
end

endmodule
