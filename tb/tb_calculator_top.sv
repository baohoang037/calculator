`timescale 1ns/1ps

module tb_calculator_top;

    localparam int DATA_WIDTH = 16;
    localparam int OUT_WIDTH  = 32;
    localparam int NUM_REGS   = 4;

    logic                          clk;
    logic                          rst_n;
    logic                          wr_en;
    logic [$clog2(NUM_REGS)-1:0]  wr_addr;
    logic signed [DATA_WIDTH-1:0]  data_in;
    logic [$clog2(NUM_REGS)-1:0]  rd_addr_a;
    logic [$clog2(NUM_REGS)-1:0]  rd_addr_b;
    logic [2:0]                    opcode;
    logic                          op_valid;
    logic signed [OUT_WIDTH-1:0]   data_out;
    logic                          result_valid;
    logic                          div_by_zero_flag;

    int error_count = 0;

    // Instantiate DUT
    calculator_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .OUT_WIDTH (OUT_WIDTH),
        .NUM_REGS  (NUM_REGS)
    ) dut (.*);

    // Clock Generation: 50MHz (Period = 20ns)
    initial clk = 0;
    always #10 clk = ~clk;

    // Coverage sample ngầm định (QuestaSim sẽ ghi nhận qua cờ makefile)
    covergroup cg_calculator @(posedge clk);
        cp_opcode: coverpoint opcode {
            bins op_nop = {3'b000};
            bins op_add = {3'b001};
            bins op_sub = {3'b010};
            bins op_mul = {3'b011};
            bins op_div = {3'b100};
        }
        cp_div_err: coverpoint div_by_zero_flag {
            bins no_error  = {1'b0};
            bins has_error = {1'b1};
        }
    endgroup

    cg_calculator cov_inst = new();

    // Reusable Tasks
    task automatic write_reg(input logic [1:0] addr, input logic signed [15:0] val);
        @(negedge clk);
        wr_en   <= 1'b1;
        wr_addr <= addr;
        data_in <= val;
        @(posedge clk);
        #1;
        wr_en   <= 1'b0;
    endtask

    task automatic run_op(
        input logic [2:0]  op,
        input logic [1:0]  a,
        input logic [1:0]  b,
        input logic signed [31:0] exp_out,
        input logic        exp_err
    );
        @(negedge clk);
        opcode    <= op;
        rd_addr_a <= a;
        rd_addr_b <= b;
        op_valid  <= 1'b1;

        @(posedge clk);
        #1;
        op_valid  <= 1'b0;

        assert (result_valid === 1'b1)
            else $error("[FAIL] result_valid is 0!");

        assert (data_out === exp_out && div_by_zero_flag === exp_err)
            else $error("[FAIL] Op %0d Mismatch!", op);

        $display("[PASS] Op %0b (R%0d, R%0d) -> Out=%0d, Err=%b", 
                 op, a, b, data_out, div_by_zero_flag);
    endtask

    // Reset Task
    task automatic apply_reset();
        rst_n     <= 1'b0;
        wr_en     <= 1'b0;
        wr_addr   <= '0;
        data_in   <= '0;
        rd_addr_a <= '0;
        rd_addr_b <= '0;
        opcode    <= '0;
        op_valid  <= 1'b0;
        repeat (3) @(posedge clk);
        rst_n     <= 1'b1;
        @(posedge clk);
    endtask

    // Include testcases from tc directory
    `include "tc_basic_arithmetic.sv"

endmodule