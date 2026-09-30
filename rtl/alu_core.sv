module alu_core #(
    parameter int IN_WIDTH  = 16,
    parameter int OUT_WIDTH = 32
) (
    input  logic [2:0]                   opcode,
    input  logic signed [IN_WIDTH-1:0]   operand_a,
    input  logic signed [IN_WIDTH-1:0]   operand_b,
    output logic signed [OUT_WIDTH-1:0]  alu_result,
    output logic                         zero_div_err
);

    always_comb begin
        alu_result   = '0;
        zero_div_err = 1'b0;

        case (opcode)
            3'b001: alu_result = 32'(operand_a) + 32'(operand_b); // ADD
            3'b010: alu_result = 32'(operand_a) - 32'(operand_b); // SUB
            3'b011: alu_result = 32'(operand_a) * 32'(operand_b); // MUL
            3'b100: begin                                         // DIV
                if (operand_b == '0) begin
                    zero_div_err = 1'b1;
                    alu_result   = '0;
                end else begin
                    alu_result   = 32'(operand_a / operand_b);
                end
            end
            default: begin
                alu_result   = '0;
                zero_div_err = 1'b0;
            end
        endcase
    end

endmodule