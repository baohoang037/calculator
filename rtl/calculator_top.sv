module calculator_top #(
    parameter int DATA_WIDTH = 16,
    parameter int OUT_WIDTH  = 32,
    parameter int NUM_REGS   = 4
) (
    input  logic                          clk,
    input  logic                          rst_n,
    input  logic                          wr_en,
    input  logic [$clog2(NUM_REGS)-1:0]  wr_addr,
    input  logic signed [DATA_WIDTH-1:0]  data_in,
    input  logic [$clog2(NUM_REGS)-1:0]  rd_addr_a,
    input  logic [$clog2(NUM_REGS)-1:0]  rd_addr_b,
    input  logic [2:0]                    opcode,
    input  logic                          op_valid,
    output logic signed [OUT_WIDTH-1:0]   data_out,
    output logic                          result_valid,
    output logic                          div_by_zero_flag
);

    logic signed [DATA_WIDTH-1:0] op_a, op_b;
    logic signed [OUT_WIDTH-1:0]  alu_out_comb;
    logic                         zero_err_comb;

    storage_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REGS  (NUM_REGS)
    ) u_storage (
        .clk       (clk),
        .rst_n     (rst_n),
        .wr_en     (wr_en),
        .wr_addr   (wr_addr),
        .wr_data   (data_in),
        .rd_addr_a (rd_addr_a),
        .rd_addr_b (rd_addr_b),
        .rd_data_a (op_a),
        .rd_data_b (op_b)
    );

    alu_core #(
        .IN_WIDTH  (DATA_WIDTH),
        .OUT_WIDTH (OUT_WIDTH)
    ) u_alu (
        .opcode       (opcode),
        .operand_a    (op_a),
        .operand_b    (op_b),
        .alu_result   (alu_out_comb),
        .zero_div_err (zero_err_comb)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out         <= '0;
            result_valid     <= 1'b0;
            div_by_zero_flag <= 1'b0;
        end else begin
            result_valid     <= op_valid;
            if (op_valid) begin
                data_out         <= alu_out_comb;
                div_by_zero_flag <= zero_err_comb;
            end else begin
                div_by_zero_flag <= 1'b0;
            end
        end
    end

endmodule