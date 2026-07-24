#
# user core constraints
#
# put your clock groups in here as well as any net assignments
#

# The bridge/housekeeping clocks are genuinely asynchronous to the core.
# All five PLL outputs (12.288 x2, 24.576 game, 6.144 pixel x2) share one VCO and
# are kept in a single synchronous group so STA times the game->video crossing
# (game PCLK = CLK24M/4 and the 6.144 MHz pixel clock are phase-related).
set_clock_groups -asynchronous \
 -group { bridge_spiclk } \
 -group { clk_74a } \
 -group { clk_74b } \
 -group { ic|mp1|mf_pllbase_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk \
          ic|mp1|mf_pllbase_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk \
          ic|mp1|mf_pllbase_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk \
          ic|mp1|mf_pllbase_inst|altera_pll_i|general[3].gpll~PLL_OUTPUT_COUNTER|divclk \
          ic|mp1|mf_pllbase_inst|altera_pll_i|general[4].gpll~PLL_OUTPUT_COUNTER|divclk }
