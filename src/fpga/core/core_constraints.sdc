#
# user core constraints
#
# put your clock groups in here as well as any net assignments
#
# The bridge/housekeeping clocks are genuinely asynchronous to the core.
# The three active PLL outputs (24.576 game, 6.144 pixel, 6.144 pixel@90) share
# one VCO and stay in a single group so cross-domain paths between them are
# analyzed rather than false-pathed.
#
# The game's internal fabric-divided clocks (Z80/pixel/sprite) are intentionally
# left to Quartus's defaults, matching MiSTer and every reference openFPGA core.
# The one game-pixel -> video-clock crossing is same-frequency, same-PLL-source
# (constant phase); worst-case is a cosmetic artifact, verified on hardware. If
# one appears, replace the resample with a dual-clock line buffer.

set_clock_groups -asynchronous \
 -group { bridge_spiclk } \
 -group { clk_74a } \
 -group { clk_74b } \
 -group { ic|mp1|mf_pllbase_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk \
          ic|mp1|mf_pllbase_inst|altera_pll_i|general[3].gpll~PLL_OUTPUT_COUNTER|divclk \
          ic|mp1|mf_pllbase_inst|altera_pll_i|general[4].gpll~PLL_OUTPUT_COUNTER|divclk }
