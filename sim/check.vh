//============================================================================
//  Shared assertion helpers. `include this inside a testbench module.
//
//  Every check prints a line, so a passing run still shows what was measured
//  -- the numbers are the point, not just the verdict.
//============================================================================

integer tb_errors = 0;

task check_i(input [511:0] what, input integer got, input integer want);
begin
    if (got !== want) begin
        $display("  FAIL  %0s = %0d, expected %0d", what, got, want);
        tb_errors = tb_errors + 1;
    end else
        $display("  ok    %0s = %0d", what, got);
end
endtask

// Frequencies never land exactly on the tick because the testbench clock
// period is rounded to the picosecond, so compare within a tolerance.
task check_hz(input [511:0] what, input real got, input real want, input real tol);
begin
    if ((got - want > tol) || (want - got > tol)) begin
        $display("  FAIL  %0s = %0.3f Hz, expected %0.3f +/- %0.3f", what, got, want, tol);
        tb_errors = tb_errors + 1;
    end else
        $display("  ok    %0s = %0.3f Hz", what, got);
end
endtask

task note(input [511:0] msg);
begin
    $display("  info  %0s", msg);
end
endtask

task report(input [511:0] name);
begin
    $display("");
    if (tb_errors == 0)
        $display("PASS  %0s", name);
    else
        $display("FAIL  %0s -- %0d mismatch(es)", name, tb_errors);
    $finish;
end
endtask
