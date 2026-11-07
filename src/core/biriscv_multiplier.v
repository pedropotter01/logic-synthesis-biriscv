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

module biriscv_multiplier
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
    reg  [ 31:0]          writeback_value_o_iso_q;

    always @ (posedge clk_i)
    begin
        writeback_value_o_iso_q <= writeback_value_o_int;
    end

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
    assign writeback_value_o = writeback_value_o_int;
end
endgenerate


localparam MULT_STAGES = 2; // 2 or 3

//-------------------------------------------------------------
// Registers / Wires
//-------------------------------------------------------------
reg  [31:0]  result_e2_q;
reg  [31:0]  result_e3_q;

reg [32:0]   operand_a_e1_q;
reg [32:0]   operand_b_e1_q;
reg          mulhi_sel_e1_q;

//-------------------------------------------------------------
// Multiplier
//-------------------------------------------------------------
wire [64:0]  mult_result_w;
reg  [32:0]  operand_b_r;
reg  [32:0]  operand_a_r;
reg  [31:0]  result_r;

wire mult_inst_w    = ((opcode_opcode_i_int & `INST_MUL_MASK) == `INST_MUL)        || 
                      ((opcode_opcode_i_int & `INST_MULH_MASK) == `INST_MULH)      ||
                      ((opcode_opcode_i_int & `INST_MULHSU_MASK) == `INST_MULHSU)  ||
                      ((opcode_opcode_i_int & `INST_MULHU_MASK) == `INST_MULHU);


always @ *
begin
    if ((opcode_opcode_i_int & `INST_MULHSU_MASK) == `INST_MULHSU)
        operand_a_r = {opcode_ra_operand_i_int[31], opcode_ra_operand_i_int[31:0]};
    else if ((opcode_opcode_i_int & `INST_MULH_MASK) == `INST_MULH)
        operand_a_r = {opcode_ra_operand_i_int[31], opcode_ra_operand_i_int[31:0]};
    else // MULHU || MUL
        operand_a_r = {1'b0, opcode_ra_operand_i_int[31:0]};
end

always @ *
begin
    if ((opcode_opcode_i_int & `INST_MULHSU_MASK) == `INST_MULHSU)
        operand_b_r = {1'b0, opcode_rb_operand_i_int[31:0]};
    else if ((opcode_opcode_i_int & `INST_MULH_MASK) == `INST_MULH)
        operand_b_r = {opcode_rb_operand_i_int[31], opcode_rb_operand_i_int[31:0]};
    else // MULHU || MUL
        operand_b_r = {1'b0, opcode_rb_operand_i_int[31:0]};
end


// Pipeline flops for multiplier
always @(posedge clk_i or posedge rst_i)
if (rst_i)
begin
    operand_a_e1_q <= 33'b0;
    operand_b_e1_q <= 33'b0;
    mulhi_sel_e1_q <= 1'b0;
end
else if (hold_i_int)
    ;
else if (opcode_valid_i_int && mult_inst_w)
begin
    operand_a_e1_q <= operand_a_r;
    operand_b_e1_q <= operand_b_r;
    mulhi_sel_e1_q <= ~((opcode_opcode_i_int & `INST_MUL_MASK) == `INST_MUL);
end
else
begin
    operand_a_e1_q <= 33'b0;
    operand_b_e1_q <= 33'b0;
    mulhi_sel_e1_q <= 1'b0;
end

assign mult_result_w = {{ 32 {operand_a_e1_q[32]}}, operand_a_e1_q}*{{ 32 {operand_b_e1_q[32]}}, operand_b_e1_q};

always @ *
begin
    result_r = mulhi_sel_e1_q ? mult_result_w[63:32] : mult_result_w[31:0];
end

always @(posedge clk_i or posedge rst_i)
if (rst_i)
    result_e2_q <= 32'b0;
else if (~hold_i_int)
    result_e2_q <= result_r;

always @(posedge clk_i or posedge rst_i)
if (rst_i)
    result_e3_q <= 32'b0;
else if (~hold_i_int)
    result_e3_q <= result_e2_q;

assign writeback_value_o_int  = (MULT_STAGES == 3) ? result_e3_q : result_e2_q;


endmodule
