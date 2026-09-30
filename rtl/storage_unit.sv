module storage_unit #(
    parameter int DATA_WIDTH = 16,
    parameter int NUM_REGS   = 4
) (
    input  logic                          clk,
    input  logic                          rst_n,
    input  logic                          wr_en,
    input  logic [$clog2(NUM_REGS)-1:0]  wr_addr,
    input  logic signed [DATA_WIDTH-1:0]  wr_data,
    input  logic [$clog2(NUM_REGS)-1:0]  rd_addr_a,
    input  logic [$clog2(NUM_REGS)-1:0]  rd_addr_b,
    output logic signed [DATA_WIDTH-1:0]  rd_data_a,
    output logic signed [DATA_WIDTH-1:0]  rd_data_b
);

    logic signed [DATA_WIDTH-1:0] reg_bank [0:NUM_REGS-1];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_REGS; i++) begin
                reg_bank[i] <= '0;
            end
        end else if (wr_en) begin
            reg_bank[wr_addr] <= wr_data;
        end
    end

    assign rd_data_a = reg_bank[rd_addr_a];
    assign rd_data_b = reg_bank[rd_addr_b];

endmodule