//-----------------------------------------------------------------
//                         biRISC-V CPU
//                            V0.8.1
//                     Ultra-Embedded.com
//                     Copyright 2019-2020
//
//                   admin@ultra-embedded.com
//
//                     License: Apache 2.0
//-----------------------------------------------------------------
// Copyright 2020 Ultra-Embedded.com
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------

module biriscv_exec
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SYNTH_MODE_ISO = 0 // 1: register all I/Os (standalone synthesis only)
)
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           opcode_valid_i
    ,input  [ 31:0]  opcode_opcode_i
    ,input  [ 31:0]  opcode_pc_i
    ,input           opcode_invalid_i
    ,input  [  4:0]  opcode_rd_idx_i
    ,input  [  4:0]  opcode_ra_idx_i
    ,input  [  4:0]  opcode_rb_idx_i
    ,input  [ 31:0]  opcode_ra_operand_i
    ,input  [ 31:0]  opcode_rb_operand_i
    ,input           hold_i

    // Outputs
    ,output          branch_request_o
    ,output          branch_is_taken_o
    ,output          branch_is_not_taken_o
    ,output [ 31:0]  branch_source_o
    ,output          branch_is_call_o
    ,output          branch_is_ret_o
    ,output          branch_is_jmp_o
    ,output [ 31:0]  branch_pc_o
    ,output          branch_d_request_o
    ,output [ 31:0]  branch_d_pc_o
    ,output [  1:0]  branch_d_priv_o
    ,output [ 31:0]  writeback_value_o
);



//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "biriscv_defs.v"

//-----------------------------------------------------------------
// SYNTH_MODE_ISO: isolation register walls
//   SYNTH_MODE_ISO = 0 -> ports connected straight through (normal)
//   SYNTH_MODE_ISO = 1 -> every input and output (except clock/reset)
//                         is registered, so this module can be
//                         synthesized and timed standalone.
//-----------------------------------------------------------------
// Internal (module side) view of the ports
wire                  opcode_valid_i_int;
wire [ 31:0]          opcode_opcode_i_int;
wire [ 31:0]          opcode_pc_i_int;
wire                  opcode_invalid_i_int;
wire [  4:0]          opcode_rd_idx_i_int;
wire [  4:0]          opcode_ra_idx_i_int;
wire [  4:0]          opcode_rb_idx_i_int;
wire [ 31:0]          opcode_ra_operand_i_int;
wire [ 31:0]          opcode_rb_operand_i_int;
wire                  hold_i_int;
wire                  branch_request_o_int;
wire                  branch_is_taken_o_int;
wire                  branch_is_not_taken_o_int;
wire [ 31:0]          branch_source_o_int;
wire                  branch_is_call_o_int;
wire                  branch_is_ret_o_int;
wire                  branch_is_jmp_o_int;
wire [ 31:0]          branch_pc_o_int;
wire                  branch_d_request_o_int;
wire [ 31:0]          branch_d_pc_o_int;
wire [  1:0]          branch_d_priv_o_int;
wire [ 31:0]          writeback_value_o_int;

generate
if (SYNTH_MODE_ISO)
begin : g_synth_iso
    // Input register wall
    reg                   opcode_valid_i_iso_q;
    reg  [ 31:0]          opcode_opcode_i_iso_q;
    reg  [ 31:0]          opcode_pc_i_iso_q;
    reg                   opcode_invalid_i_iso_q;
    reg  [  4:0]          opcode_rd_idx_i_iso_q;
    reg  [  4:0]          opcode_ra_idx_i_iso_q;
    reg  [  4:0]          opcode_rb_idx_i_iso_q;
    reg  [ 31:0]          opcode_ra_operand_i_iso_q;
    reg  [ 31:0]          opcode_rb_operand_i_iso_q;
    reg                   hold_i_iso_q;

    always @ (posedge clk_i)
    begin
        opcode_valid_i_iso_q <= opcode_valid_i;
        opcode_opcode_i_iso_q <= opcode_opcode_i;
        opcode_pc_i_iso_q <= opcode_pc_i;
        opcode_invalid_i_iso_q <= opcode_invalid_i;
        opcode_rd_idx_i_iso_q <= opcode_rd_idx_i;
        opcode_ra_idx_i_iso_q <= opcode_ra_idx_i;
        opcode_rb_idx_i_iso_q <= opcode_rb_idx_i;
        opcode_ra_operand_i_iso_q <= opcode_ra_operand_i;
        opcode_rb_operand_i_iso_q <= opcode_rb_operand_i;
        hold_i_iso_q <= hold_i;
    end

    assign opcode_valid_i_int = opcode_valid_i_iso_q;
    assign opcode_opcode_i_int = opcode_opcode_i_iso_q;
    assign opcode_pc_i_int = opcode_pc_i_iso_q;
    assign opcode_invalid_i_int = opcode_invalid_i_iso_q;
    assign opcode_rd_idx_i_int = opcode_rd_idx_i_iso_q;
    assign opcode_ra_idx_i_int = opcode_ra_idx_i_iso_q;
    assign opcode_rb_idx_i_int = opcode_rb_idx_i_iso_q;
    assign opcode_ra_operand_i_int = opcode_ra_operand_i_iso_q;
    assign opcode_rb_operand_i_int = opcode_rb_operand_i_iso_q;
    assign hold_i_int = hold_i_iso_q;

    // Output register wall
    reg                   branch_request_o_iso_q;
    reg                   branch_is_taken_o_iso_q;
    reg                   branch_is_not_taken_o_iso_q;
    reg  [ 31:0]          branch_source_o_iso_q;
    reg                   branch_is_call_o_iso_q;
    reg                   branch_is_ret_o_iso_q;
    reg                   branch_is_jmp_o_iso_q;
    reg  [ 31:0]          branch_pc_o_iso_q;
    reg                   branch_d_request_o_iso_q;
    reg  [ 31:0]          branch_d_pc_o_iso_q;
    reg  [  1:0]          branch_d_priv_o_iso_q;
    reg  [ 31:0]          writeback_value_o_iso_q;

    always @ (posedge clk_i)
    begin
        branch_request_o_iso_q <= branch_request_o_int;
        branch_is_taken_o_iso_q <= branch_is_taken_o_int;
        branch_is_not_taken_o_iso_q <= branch_is_not_taken_o_int;
        branch_source_o_iso_q <= branch_source_o_int;
        branch_is_call_o_iso_q <= branch_is_call_o_int;
        branch_is_ret_o_iso_q <= branch_is_ret_o_int;
        branch_is_jmp_o_iso_q <= branch_is_jmp_o_int;
        branch_pc_o_iso_q <= branch_pc_o_int;
        branch_d_request_o_iso_q <= branch_d_request_o_int;
        branch_d_pc_o_iso_q <= branch_d_pc_o_int;
        branch_d_priv_o_iso_q <= branch_d_priv_o_int;
        writeback_value_o_iso_q <= writeback_value_o_int;
    end

    assign branch_request_o = branch_request_o_iso_q;
    assign branch_is_taken_o = branch_is_taken_o_iso_q;
    assign branch_is_not_taken_o = branch_is_not_taken_o_iso_q;
    assign branch_source_o = branch_source_o_iso_q;
    assign branch_is_call_o = branch_is_call_o_iso_q;
    assign branch_is_ret_o = branch_is_ret_o_iso_q;
    assign branch_is_jmp_o = branch_is_jmp_o_iso_q;
    assign branch_pc_o = branch_pc_o_iso_q;
    assign branch_d_request_o = branch_d_request_o_iso_q;
    assign branch_d_pc_o = branch_d_pc_o_iso_q;
    assign branch_d_priv_o = branch_d_priv_o_iso_q;
    assign writeback_value_o = writeback_value_o_iso_q;
end
else
begin : g_synth_no_iso
    assign opcode_valid_i_int = opcode_valid_i;
    assign opcode_opcode_i_int = opcode_opcode_i;
    assign opcode_pc_i_int = opcode_pc_i;
    assign opcode_invalid_i_int = opcode_invalid_i;
    assign opcode_rd_idx_i_int = opcode_rd_idx_i;
    assign opcode_ra_idx_i_int = opcode_ra_idx_i;
    assign opcode_rb_idx_i_int = opcode_rb_idx_i;
    assign opcode_ra_operand_i_int = opcode_ra_operand_i;
    assign opcode_rb_operand_i_int = opcode_rb_operand_i;
    assign hold_i_int = hold_i;
    assign branch_request_o = branch_request_o_int;
    assign branch_is_taken_o = branch_is_taken_o_int;
    assign branch_is_not_taken_o = branch_is_not_taken_o_int;
    assign branch_source_o = branch_source_o_int;
    assign branch_is_call_o = branch_is_call_o_int;
    assign branch_is_ret_o = branch_is_ret_o_int;
    assign branch_is_jmp_o = branch_is_jmp_o_int;
    assign branch_pc_o = branch_pc_o_int;
    assign branch_d_request_o = branch_d_request_o_int;
    assign branch_d_pc_o = branch_d_pc_o_int;
    assign branch_d_priv_o = branch_d_priv_o_int;
    assign writeback_value_o = writeback_value_o_int;
end
endgenerate


//-------------------------------------------------------------
// Opcode decode
//-------------------------------------------------------------
reg [31:0]  imm20_r;
reg [31:0]  imm12_r;
reg [31:0]  bimm_r;
reg [31:0]  jimm20_r;
reg [4:0]   shamt_r;

always @ *
begin
    imm20_r     = {opcode_opcode_i_int[31:12], 12'b0};
    imm12_r     = {{20{opcode_opcode_i_int[31]}}, opcode_opcode_i_int[31:20]};
    bimm_r      = {{19{opcode_opcode_i_int[31]}}, opcode_opcode_i_int[31], opcode_opcode_i_int[7], opcode_opcode_i_int[30:25], opcode_opcode_i_int[11:8], 1'b0};
    jimm20_r    = {{12{opcode_opcode_i_int[31]}}, opcode_opcode_i_int[19:12], opcode_opcode_i_int[20], opcode_opcode_i_int[30:25], opcode_opcode_i_int[24:21], 1'b0};
    shamt_r     = opcode_opcode_i_int[24:20];
end

//-------------------------------------------------------------
// Execute - ALU operations
//-------------------------------------------------------------
reg [3:0]  alu_func_r;
reg [31:0] alu_input_a_r;
reg [31:0] alu_input_b_r;

always @ *
begin
    alu_func_r     = `ALU_NONE;
    alu_input_a_r  = 32'b0;
    alu_input_b_r  = 32'b0;

    if ((opcode_opcode_i_int & `INST_ADD_MASK) == `INST_ADD) // add
    begin
        alu_func_r     = `ALU_ADD;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = opcode_rb_operand_i_int;
    end
    else if ((opcode_opcode_i_int & `INST_AND_MASK) == `INST_AND) // and
    begin
        alu_func_r     = `ALU_AND;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = opcode_rb_operand_i_int;
    end
    else if ((opcode_opcode_i_int & `INST_OR_MASK) == `INST_OR) // or
    begin
        alu_func_r     = `ALU_OR;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = opcode_rb_operand_i_int;
    end
    else if ((opcode_opcode_i_int & `INST_SLL_MASK) == `INST_SLL) // sll
    begin
        alu_func_r     = `ALU_SHIFTL;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = opcode_rb_operand_i_int;
    end
    else if ((opcode_opcode_i_int & `INST_SRA_MASK) == `INST_SRA) // sra
    begin
        alu_func_r     = `ALU_SHIFTR_ARITH;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = opcode_rb_operand_i_int;
    end
    else if ((opcode_opcode_i_int & `INST_SRL_MASK) == `INST_SRL) // srl
    begin
        alu_func_r     = `ALU_SHIFTR;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = opcode_rb_operand_i_int;
    end
    else if ((opcode_opcode_i_int & `INST_SUB_MASK) == `INST_SUB) // sub
    begin
        alu_func_r     = `ALU_SUB;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = opcode_rb_operand_i_int;
    end
    else if ((opcode_opcode_i_int & `INST_XOR_MASK) == `INST_XOR) // xor
    begin
        alu_func_r     = `ALU_XOR;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = opcode_rb_operand_i_int;
    end
    else if ((opcode_opcode_i_int & `INST_SLT_MASK) == `INST_SLT) // slt
    begin
        alu_func_r     = `ALU_LESS_THAN_SIGNED;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = opcode_rb_operand_i_int;
    end
    else if ((opcode_opcode_i_int & `INST_SLTU_MASK) == `INST_SLTU) // sltu
    begin
        alu_func_r     = `ALU_LESS_THAN;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = opcode_rb_operand_i_int;
    end
    else if ((opcode_opcode_i_int & `INST_ADDI_MASK) == `INST_ADDI) // addi
    begin
        alu_func_r     = `ALU_ADD;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = imm12_r;
    end
    else if ((opcode_opcode_i_int & `INST_ANDI_MASK) == `INST_ANDI) // andi
    begin
        alu_func_r     = `ALU_AND;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = imm12_r;
    end
    else if ((opcode_opcode_i_int & `INST_SLTI_MASK) == `INST_SLTI) // slti
    begin
        alu_func_r     = `ALU_LESS_THAN_SIGNED;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = imm12_r;
    end
    else if ((opcode_opcode_i_int & `INST_SLTIU_MASK) == `INST_SLTIU) // sltiu
    begin
        alu_func_r     = `ALU_LESS_THAN;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = imm12_r;
    end
    else if ((opcode_opcode_i_int & `INST_ORI_MASK) == `INST_ORI) // ori
    begin
        alu_func_r     = `ALU_OR;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = imm12_r;
    end
    else if ((opcode_opcode_i_int & `INST_XORI_MASK) == `INST_XORI) // xori
    begin
        alu_func_r     = `ALU_XOR;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = imm12_r;
    end
    else if ((opcode_opcode_i_int & `INST_SLLI_MASK) == `INST_SLLI) // slli
    begin
        alu_func_r     = `ALU_SHIFTL;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = {27'b0, shamt_r};
    end
    else if ((opcode_opcode_i_int & `INST_SRLI_MASK) == `INST_SRLI) // srli
    begin
        alu_func_r     = `ALU_SHIFTR;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = {27'b0, shamt_r};
    end
    else if ((opcode_opcode_i_int & `INST_SRAI_MASK) == `INST_SRAI) // srai
    begin
        alu_func_r     = `ALU_SHIFTR_ARITH;
        alu_input_a_r  = opcode_ra_operand_i_int;
        alu_input_b_r  = {27'b0, shamt_r};
    end
    else if ((opcode_opcode_i_int & `INST_LUI_MASK) == `INST_LUI) // lui
    begin
        alu_input_a_r  = imm20_r;
    end
    else if ((opcode_opcode_i_int & `INST_AUIPC_MASK) == `INST_AUIPC) // auipc
    begin
        alu_func_r     = `ALU_ADD;
        alu_input_a_r  = opcode_pc_i_int;
        alu_input_b_r  = imm20_r;
    end     
    else if (((opcode_opcode_i_int & `INST_JAL_MASK) == `INST_JAL) || ((opcode_opcode_i_int & `INST_JALR_MASK) == `INST_JALR)) // jal, jalr
    begin
        alu_func_r     = `ALU_ADD;
        alu_input_a_r  = opcode_pc_i_int;
        alu_input_b_r  = 32'd4;
    end
end


//-------------------------------------------------------------
// ALU
//-------------------------------------------------------------
wire [31:0]  alu_p_w;
biriscv_alu
u_alu
(
    .clk_i(clk_i),
    .alu_op_i(alu_func_r),
    .alu_a_i(alu_input_a_r),
    .alu_b_i(alu_input_b_r),
    .alu_p_o(alu_p_w)
);

//-------------------------------------------------------------
// Flop ALU output
//-------------------------------------------------------------
reg [31:0] result_q;
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    result_q  <= 32'b0;
else if (~hold_i_int)
    result_q <= alu_p_w;

assign writeback_value_o_int  = result_q;

//-----------------------------------------------------------------
// less_than_signed: Less than operator (signed)
// Inputs: x = left operand, y = right operand
// Return: (int)x < (int)y
//-----------------------------------------------------------------
function [0:0] less_than_signed;
    input  [31:0] x;
    input  [31:0] y;
    reg [31:0] v;
begin
    v = (x - y);
    if (x[31] != y[31])
        less_than_signed = x[31];
    else
        less_than_signed = v[31];
end
endfunction

//-----------------------------------------------------------------
// greater_than_signed: Greater than operator (signed)
// Inputs: x = left operand, y = right operand
// Return: (int)x > (int)y
//-----------------------------------------------------------------
function [0:0] greater_than_signed;
    input  [31:0] x;
    input  [31:0] y;
    reg [31:0] v;
begin
    v = (y - x);
    if (x[31] != y[31])
        greater_than_signed = y[31];
    else
        greater_than_signed = v[31];
end
endfunction

//-------------------------------------------------------------
// Execute - Branch operations
//-------------------------------------------------------------
reg        branch_r;
reg        branch_taken_r;
reg [31:0] branch_target_r;
reg        branch_call_r;
reg        branch_ret_r;
reg        branch_jmp_r;

always @ *
begin
    branch_r        = 1'b0;
    branch_taken_r  = 1'b0;
    branch_call_r   = 1'b0;
    branch_ret_r    = 1'b0;
    branch_jmp_r    = 1'b0;

    // Default branch_r target is relative to current PC
    branch_target_r = opcode_pc_i_int + bimm_r;

    if ((opcode_opcode_i_int & `INST_JAL_MASK) == `INST_JAL) // jal
    begin
        branch_r        = 1'b1;
        branch_taken_r  = 1'b1;
        branch_target_r = opcode_pc_i_int + jimm20_r;
        branch_call_r   = (opcode_rd_idx_i_int == 5'd1); // RA
        branch_jmp_r    = 1'b1;
    end
    else if ((opcode_opcode_i_int & `INST_JALR_MASK) == `INST_JALR) // jalr
    begin
        branch_r            = 1'b1;
        branch_taken_r      = 1'b1;
        branch_target_r     = opcode_ra_operand_i_int + imm12_r;
        branch_target_r[0]  = 1'b0;
        branch_ret_r        = (opcode_ra_idx_i_int == 5'd1 && imm12_r[11:0] == 12'b0); // RA
        branch_call_r       = ~branch_ret_r && (opcode_rd_idx_i_int == 5'd1); // RA
        branch_jmp_r        = ~(branch_call_r | branch_ret_r);
    end
    else if ((opcode_opcode_i_int & `INST_BEQ_MASK) == `INST_BEQ) // beq
    begin
        branch_r      = 1'b1;
        branch_taken_r= (opcode_ra_operand_i_int == opcode_rb_operand_i_int);
    end
    else if ((opcode_opcode_i_int & `INST_BNE_MASK) == `INST_BNE) // bne
    begin
        branch_r      = 1'b1;    
        branch_taken_r= (opcode_ra_operand_i_int != opcode_rb_operand_i_int);
    end
    else if ((opcode_opcode_i_int & `INST_BLT_MASK) == `INST_BLT) // blt
    begin
        branch_r      = 1'b1;
        branch_taken_r= less_than_signed(opcode_ra_operand_i_int, opcode_rb_operand_i_int);
    end
    else if ((opcode_opcode_i_int & `INST_BGE_MASK) == `INST_BGE) // bge
    begin
        branch_r      = 1'b1;    
        branch_taken_r= greater_than_signed(opcode_ra_operand_i_int,opcode_rb_operand_i_int) | (opcode_ra_operand_i_int == opcode_rb_operand_i_int);
    end
    else if ((opcode_opcode_i_int & `INST_BLTU_MASK) == `INST_BLTU) // bltu
    begin
        branch_r      = 1'b1;    
        branch_taken_r= (opcode_ra_operand_i_int < opcode_rb_operand_i_int);
    end
    else if ((opcode_opcode_i_int & `INST_BGEU_MASK) == `INST_BGEU) // bgeu
    begin
        branch_r      = 1'b1;
        branch_taken_r= (opcode_ra_operand_i_int >= opcode_rb_operand_i_int);
    end
end

reg        branch_taken_q;
reg        branch_ntaken_q;
reg [31:0] pc_x_q;
reg [31:0] pc_m_q;
reg        branch_call_q;
reg        branch_ret_q;
reg        branch_jmp_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    branch_taken_q   <= 1'b0;
    branch_ntaken_q  <= 1'b0;
    pc_x_q           <= 32'b0;
    pc_m_q           <= 32'b0;
    branch_call_q    <= 1'b0;
    branch_ret_q     <= 1'b0;
    branch_jmp_q     <= 1'b0;
end
else if (opcode_valid_i_int)
begin
    branch_taken_q   <= branch_r && opcode_valid_i_int & branch_taken_r;
    branch_ntaken_q  <= branch_r && opcode_valid_i_int & ~branch_taken_r;
    pc_x_q           <= branch_taken_r ? branch_target_r : opcode_pc_i_int + 32'd4;
    branch_call_q    <= branch_r && opcode_valid_i_int && branch_call_r;
    branch_ret_q     <= branch_r && opcode_valid_i_int && branch_ret_r;
    branch_jmp_q     <= branch_r && opcode_valid_i_int && branch_jmp_r;
    pc_m_q           <= opcode_pc_i_int;
end

assign branch_request_o_int   = branch_taken_q | branch_ntaken_q;
assign branch_is_taken_o_int  = branch_taken_q;
assign branch_is_not_taken_o_int = branch_ntaken_q;
assign branch_source_o_int    = pc_m_q;
assign branch_pc_o_int        = pc_x_q;
assign branch_is_call_o_int   = branch_call_q;
assign branch_is_ret_o_int    = branch_ret_q;
assign branch_is_jmp_o_int    = branch_jmp_q;

assign branch_d_request_o_int = (branch_r && opcode_valid_i_int && branch_taken_r);
assign branch_d_pc_o_int      = branch_target_r;
assign branch_d_priv_o_int    = 2'b0; // don't care



endmodule
