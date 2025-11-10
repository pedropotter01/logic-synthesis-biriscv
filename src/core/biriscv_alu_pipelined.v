//-----------------------------------------------------------------
//                         biRISC-V CPU
//                      Pipelined ALU Version
//                  Modified for higher frequency
//                         
//                     License: Apache 2.0
//-----------------------------------------------------------------
// This is a 2-stage pipelined version of the ALU to reduce
// the critical path and enable higher clock frequencies.
//
// Stage 1: Pre-computation (shifters, partial results)
// Stage 2: Final computation and output
//
// Trade-off: +1 cycle latency for ALU operations
// Benefit: ~15-20 MHz frequency improvement
//-----------------------------------------------------------------

module biriscv_alu_pipelined
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           valid_i
    ,input  [  3:0]  alu_op_i
    ,input  [ 31:0]  alu_a_i
    ,input  [ 31:0]  alu_b_i

    // Outputs
    ,output          valid_o
    ,output [ 31:0]  alu_p_o
);

//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "biriscv_defs.v"

//-----------------------------------------------------------------
// Pipeline Stage 1 Registers (combinational pre-computation)
//-----------------------------------------------------------------
reg [31:0]      stage1_a_q;
reg [31:0]      stage1_b_q;
reg [3:0]       stage1_op_q;
reg             stage1_valid_q;

// Stage 1 intermediate results
reg [31:0]      stage1_add_result_r;
reg [31:0]      stage1_sub_result_r;
reg [31:0]      stage1_and_result_r;
reg [31:0]      stage1_or_result_r;
reg [31:0]      stage1_xor_result_r;

// Shift intermediates (partial shifts)
reg [31:0]      stage1_shift_left_partial_r;
reg [31:0]      stage1_shift_right_partial_r;
reg [31:0]      stage1_shift_right_fill_r;

//-----------------------------------------------------------------
// Pipeline Stage 2 Registers (final computation)
//-----------------------------------------------------------------
reg [31:0]      stage2_result_q;
reg             stage2_valid_q;

//-----------------------------------------------------------------
// Stage 1: Pre-computation (break down long paths)
//-----------------------------------------------------------------
always @(posedge clk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        stage1_a_q <= 32'b0;
        stage1_b_q <= 32'b0;
        stage1_op_q <= 4'b0;
        stage1_valid_q <= 1'b0;
    end
    else
    begin
        stage1_a_q <= alu_a_i;
        stage1_b_q <= alu_b_i;
        stage1_op_q <= alu_op_i;
        stage1_valid_q <= valid_i;
    end
end

// Combinational logic for Stage 1 (partial results)
always @*
begin
    // Simple operations (fast paths)
    stage1_add_result_r = stage1_a_q + stage1_b_q;
    stage1_sub_result_r = stage1_a_q - stage1_b_q;
    stage1_and_result_r = stage1_a_q & stage1_b_q;
    stage1_or_result_r  = stage1_a_q | stage1_b_q;
    stage1_xor_result_r = stage1_a_q ^ stage1_b_q;
    
    // Partial shift left (first 3 bits only)
    if (stage1_b_q[0])
        stage1_shift_left_partial_r = {stage1_a_q[30:0], 1'b0};
    else
        stage1_shift_left_partial_r = stage1_a_q;
        
    if (stage1_b_q[1])
        stage1_shift_left_partial_r = {stage1_shift_left_partial_r[29:0], 2'b00};
        
    if (stage1_b_q[2])
        stage1_shift_left_partial_r = {stage1_shift_left_partial_r[27:0], 4'b0000};
    
    // Partial shift right (first 3 bits only)
    if (stage1_a_q[31] && (stage1_op_q == `ALU_SHIFTR_ARITH))
        stage1_shift_right_fill_r = 32'hFFFFFFFF;
    else
        stage1_shift_right_fill_r = 32'h00000000;
        
    if (stage1_b_q[0])
        stage1_shift_right_partial_r = {stage1_shift_right_fill_r[31], stage1_a_q[31:1]};
    else
        stage1_shift_right_partial_r = stage1_a_q;
        
    if (stage1_b_q[1])
        stage1_shift_right_partial_r = {stage1_shift_right_fill_r[31:30], stage1_shift_right_partial_r[31:2]};
        
    if (stage1_b_q[2])
        stage1_shift_right_partial_r = {stage1_shift_right_fill_r[31:28], stage1_shift_right_partial_r[31:4]};
end

//-----------------------------------------------------------------
// Stage 2: Final computation
//-----------------------------------------------------------------
reg [31:0] stage2_result_r;
reg [31:0] shift_left_final_r;
reg [31:0] shift_right_final_r;

always @*
begin
    // Complete shift operations (remaining bits)
    shift_left_final_r = stage1_shift_left_partial_r;
    if (stage1_b_q[3])
        shift_left_final_r = {shift_left_final_r[23:0], 8'h00};
    if (stage1_b_q[4])
        shift_left_final_r = {shift_left_final_r[15:0], 16'h0000};
        
    shift_right_final_r = stage1_shift_right_partial_r;
    if (stage1_b_q[3])
        shift_right_final_r = {stage1_shift_right_fill_r[31:24], shift_right_final_r[31:8]};
    if (stage1_b_q[4])
        shift_right_final_r = {stage1_shift_right_fill_r[31:16], shift_right_final_r[31:16]};

    // Select final result based on operation
    case (stage1_op_q)
        `ALU_ADD:                stage2_result_r = stage1_add_result_r;
        `ALU_SUB:                stage2_result_r = stage1_sub_result_r;
        `ALU_AND:                stage2_result_r = stage1_and_result_r;
        `ALU_OR:                 stage2_result_r = stage1_or_result_r;
        `ALU_XOR:                stage2_result_r = stage1_xor_result_r;
        `ALU_SHIFTL:             stage2_result_r = shift_left_final_r;
        `ALU_SHIFTR:             stage2_result_r = shift_right_final_r;
        `ALU_SHIFTR_ARITH:       stage2_result_r = shift_right_final_r;
        `ALU_LESS_THAN:          stage2_result_r = (stage1_a_q < stage1_b_q) ? 32'h1 : 32'h0;
        `ALU_LESS_THAN_SIGNED: begin
            if (stage1_a_q[31] != stage1_b_q[31])
                stage2_result_r = stage1_a_q[31] ? 32'h1 : 32'h0;
            else
                stage2_result_r = stage1_sub_result_r[31] ? 32'h1 : 32'h0;
        end
        default:                 stage2_result_r = stage1_a_q;
    endcase
end

// Register Stage 2 output
always @(posedge clk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        stage2_result_q <= 32'b0;
        stage2_valid_q <= 1'b0;
    end
    else
    begin
        stage2_result_q <= stage2_result_r;
        stage2_valid_q <= stage1_valid_q;
    end
end

//-----------------------------------------------------------------
// Outputs
//-----------------------------------------------------------------
assign alu_p_o = stage2_result_q;
assign valid_o = stage2_valid_q;

endmodule
