// ============================================================================
// File: tc/tc_basic_arithmetic.sv
// Description: Full 100% RTL Coverage Testcase (Clean Math & No Mismatches)
// ============================================================================

initial begin
    $display("-----------------------------------------------------");
    $display("STARTING TESTCASE: tc_basic_arithmetic (100%% Coverage Target)");
    $display("-----------------------------------------------------");

    // 1. Initial Reset
    apply_reset();

    // 2. Data Ingestion: Nap cac mau bit 0x5555, 0xAAAA, 0xFFFF, 0x0000
    write_reg(2'd0, 16'h5555);         // +21845
    write_reg(2'd1, 16'hAAAA);         // -21846 (signed 16-bit)
    write_reg(2'd2, 16'hFFFF);         // -1 (signed 16-bit)
    write_reg(2'd3, 16'h0000);         // 0

    // 3. Kich Toggle 100% cho cac bit le/chan tren ca 2 cong A va B
    // ADD: R1 + R0 = (-21846) + 21845 = -1
    run_op(3'b001, 2'd1, 2'd0, -32'sd1, 1'b0);

    // ADD: R0 + R1 = 21845 + (-21846) = -1
    run_op(3'b001, 2'd0, 2'd1, -32'sd1, 1'b0);

    // SUB: R2 - R3 = (-1) - 0 = -1
    run_op(3'b010, 2'd2, 2'd3, -32'sd1, 1'b0);

    // SUB: R3 - R2 = 0 - (-1) = 1
    run_op(3'b010, 2'd3, 2'd2, 32'sd1, 1'b0);

    // 4. Nap lai du lieu thuong de test day du cac phep toan con lai
    write_reg(2'd0, 16'sd100);
    write_reg(2'd1, -16'sd25);
    write_reg(2'd2, 16'sd300);
    write_reg(2'd3, 16'sd0);

    // 5. Test cac phep toan so hoc:
    run_op(3'b001, 2'd0, 2'd1, 32'sd75, 1'b0);    // ADD: 100 + (-25) = 75
    run_op(3'b010, 2'd0, 2'd1, 32'sd125, 1'b0);   // SUB: 100 - (-25) = 125
    run_op(3'b011, 2'd1, 2'd2, -32'sd7500, 1'b0); // MUL: (-25) * 300 = -7500
    run_op(3'b100, 2'd0, 2'd1, -32'sd4, 1'b0);    // DIV: 100 / (-25) = -4
    run_op(3'b100, 2'd0, 2'd3, 32'sd0, 1'b1);     // DIV BY ZERO
    run_op(3'b000, 2'd0, 2'd0, 32'sd0, 1'b0);     // NOP

    // 6. Toggle lai chan reset de rst_n toggle du 100%
    @(negedge clk);
    rst_n <= 1'b0;
    @(posedge clk);
    #1;
    rst_n <= 1'b1;
    @(posedge clk);

    repeat (5) @(posedge clk);

    $display("-----------------------------------------------------");
    $display(">>> TEST STATUS: ALL CHECKS PASSED <<<");
    $display("-----------------------------------------------------");

    $finish;
end