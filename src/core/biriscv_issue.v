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

module biriscv_issue
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SUPPORT_MULDIV   = 1
    ,parameter SUPPORT_DUAL_ISSUE = 1
    ,parameter SUPPORT_LOAD_BYPASS = 1
    ,parameter SUPPORT_MUL_BYPASS = 1
    ,parameter SUPPORT_REGFILE_XILINX = 0
    ,parameter SYNTH_MODE_ISO = 0 // 1: register all I/Os (standalone synthesis only)
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           fetch0_valid_i
    ,input  [ 31:0]  fetch0_instr_i
    ,input  [ 31:0]  fetch0_pc_i
    ,input           fetch0_fault_fetch_i
    ,input           fetch0_fault_page_i
    ,input           fetch0_instr_exec_i
    ,input           fetch0_instr_lsu_i
    ,input           fetch0_instr_branch_i
    ,input           fetch0_instr_mul_i
    ,input           fetch0_instr_div_i
    ,input           fetch0_instr_csr_i
    ,input           fetch0_instr_rd_valid_i
    ,input           fetch0_instr_invalid_i
    ,input           fetch1_valid_i
    ,input  [ 31:0]  fetch1_instr_i
    ,input  [ 31:0]  fetch1_pc_i
    ,input           fetch1_fault_fetch_i
    ,input           fetch1_fault_page_i
    ,input           fetch1_instr_exec_i
    ,input           fetch1_instr_lsu_i
    ,input           fetch1_instr_branch_i
    ,input           fetch1_instr_mul_i
    ,input           fetch1_instr_div_i
    ,input           fetch1_instr_csr_i
    ,input           fetch1_instr_rd_valid_i
    ,input           fetch1_instr_invalid_i
    ,input           branch_exec0_request_i
    ,input           branch_exec0_is_taken_i
    ,input           branch_exec0_is_not_taken_i
    ,input  [ 31:0]  branch_exec0_source_i
    ,input           branch_exec0_is_call_i
    ,input           branch_exec0_is_ret_i
    ,input           branch_exec0_is_jmp_i
    ,input  [ 31:0]  branch_exec0_pc_i
    ,input           branch_d_exec0_request_i
    ,input  [ 31:0]  branch_d_exec0_pc_i
    ,input  [  1:0]  branch_d_exec0_priv_i
    ,input           branch_exec1_request_i
    ,input           branch_exec1_is_taken_i
    ,input           branch_exec1_is_not_taken_i
    ,input  [ 31:0]  branch_exec1_source_i
    ,input           branch_exec1_is_call_i
    ,input           branch_exec1_is_ret_i
    ,input           branch_exec1_is_jmp_i
    ,input  [ 31:0]  branch_exec1_pc_i
    ,input           branch_d_exec1_request_i
    ,input  [ 31:0]  branch_d_exec1_pc_i
    ,input  [  1:0]  branch_d_exec1_priv_i
    ,input           branch_csr_request_i
    ,input  [ 31:0]  branch_csr_pc_i
    ,input  [  1:0]  branch_csr_priv_i
    ,input  [ 31:0]  writeback_exec0_value_i
    ,input  [ 31:0]  writeback_exec1_value_i
    ,input           writeback_mem_valid_i
    ,input  [ 31:0]  writeback_mem_value_i
    ,input  [  5:0]  writeback_mem_exception_i
    ,input  [ 31:0]  writeback_mul_value_i
    ,input           writeback_div_valid_i
    ,input  [ 31:0]  writeback_div_value_i
    ,input  [ 31:0]  csr_result_e1_value_i
    ,input           csr_result_e1_write_i
    ,input  [ 31:0]  csr_result_e1_wdata_i
    ,input  [  5:0]  csr_result_e1_exception_i
    ,input           lsu_stall_i
    ,input           take_interrupt_i

    // Outputs
    ,output          fetch0_accept_o
    ,output          fetch1_accept_o
    ,output          branch_request_o
    ,output [ 31:0]  branch_pc_o
    ,output [  1:0]  branch_priv_o
    ,output          branch_info_request_o
    ,output          branch_info_is_taken_o
    ,output          branch_info_is_not_taken_o
    ,output [ 31:0]  branch_info_source_o
    ,output          branch_info_is_call_o
    ,output          branch_info_is_ret_o
    ,output          branch_info_is_jmp_o
    ,output [ 31:0]  branch_info_pc_o
    ,output          exec0_opcode_valid_o
    ,output          exec1_opcode_valid_o
    ,output          lsu_opcode_valid_o
    ,output          csr_opcode_valid_o
    ,output          mul_opcode_valid_o
    ,output          div_opcode_valid_o
    ,output [ 31:0]  opcode0_opcode_o
    ,output [ 31:0]  opcode0_pc_o
    ,output          opcode0_invalid_o
    ,output [  4:0]  opcode0_rd_idx_o
    ,output [  4:0]  opcode0_ra_idx_o
    ,output [  4:0]  opcode0_rb_idx_o
    ,output [ 31:0]  opcode0_ra_operand_o
    ,output [ 31:0]  opcode0_rb_operand_o
    ,output [ 31:0]  opcode1_opcode_o
    ,output [ 31:0]  opcode1_pc_o
    ,output          opcode1_invalid_o
    ,output [  4:0]  opcode1_rd_idx_o
    ,output [  4:0]  opcode1_ra_idx_o
    ,output [  4:0]  opcode1_rb_idx_o
    ,output [ 31:0]  opcode1_ra_operand_o
    ,output [ 31:0]  opcode1_rb_operand_o
    ,output [ 31:0]  lsu_opcode_opcode_o
    ,output [ 31:0]  lsu_opcode_pc_o
    ,output          lsu_opcode_invalid_o
    ,output [  4:0]  lsu_opcode_rd_idx_o
    ,output [  4:0]  lsu_opcode_ra_idx_o
    ,output [  4:0]  lsu_opcode_rb_idx_o
    ,output [ 31:0]  lsu_opcode_ra_operand_o
    ,output [ 31:0]  lsu_opcode_rb_operand_o
    ,output [ 31:0]  mul_opcode_opcode_o
    ,output [ 31:0]  mul_opcode_pc_o
    ,output          mul_opcode_invalid_o
    ,output [  4:0]  mul_opcode_rd_idx_o
    ,output [  4:0]  mul_opcode_ra_idx_o
    ,output [  4:0]  mul_opcode_rb_idx_o
    ,output [ 31:0]  mul_opcode_ra_operand_o
    ,output [ 31:0]  mul_opcode_rb_operand_o
    ,output [ 31:0]  csr_opcode_opcode_o
    ,output [ 31:0]  csr_opcode_pc_o
    ,output          csr_opcode_invalid_o
    ,output [  4:0]  csr_opcode_rd_idx_o
    ,output [  4:0]  csr_opcode_ra_idx_o
    ,output [  4:0]  csr_opcode_rb_idx_o
    ,output [ 31:0]  csr_opcode_ra_operand_o
    ,output [ 31:0]  csr_opcode_rb_operand_o
    ,output          csr_writeback_write_o
    ,output [ 11:0]  csr_writeback_waddr_o
    ,output [ 31:0]  csr_writeback_wdata_o
    ,output [  5:0]  csr_writeback_exception_o
    ,output [ 31:0]  csr_writeback_exception_pc_o
    ,output [ 31:0]  csr_writeback_exception_addr_o
    ,output          exec0_hold_o
    ,output          exec1_hold_o
    ,output          mul_hold_o
    ,output          interrupt_inhibit_o
);



`include "biriscv_defs.v"

//-----------------------------------------------------------------
// SYNTH_MODE_ISO: isolation register walls
//   SYNTH_MODE_ISO = 0 -> ports connected straight through (normal)
//   SYNTH_MODE_ISO = 1 -> every input and output (except clock/reset)
//                         is registered, so this module can be
//                         synthesized and timed standalone.
//-----------------------------------------------------------------
// Internal (module side) view of the ports
wire                  fetch0_valid_i_int;
wire [ 31:0]          fetch0_instr_i_int;
wire [ 31:0]          fetch0_pc_i_int;
wire                  fetch0_fault_fetch_i_int;
wire                  fetch0_fault_page_i_int;
wire                  fetch0_instr_exec_i_int;
wire                  fetch0_instr_lsu_i_int;
wire                  fetch0_instr_branch_i_int;
wire                  fetch0_instr_mul_i_int;
wire                  fetch0_instr_div_i_int;
wire                  fetch0_instr_csr_i_int;
wire                  fetch0_instr_rd_valid_i_int;
wire                  fetch0_instr_invalid_i_int;
wire                  fetch1_valid_i_int;
wire [ 31:0]          fetch1_instr_i_int;
wire [ 31:0]          fetch1_pc_i_int;
wire                  fetch1_fault_fetch_i_int;
wire                  fetch1_fault_page_i_int;
wire                  fetch1_instr_exec_i_int;
wire                  fetch1_instr_lsu_i_int;
wire                  fetch1_instr_branch_i_int;
wire                  fetch1_instr_mul_i_int;
wire                  fetch1_instr_div_i_int;
wire                  fetch1_instr_csr_i_int;
wire                  fetch1_instr_rd_valid_i_int;
wire                  fetch1_instr_invalid_i_int;
wire                  branch_exec0_request_i_int;
wire                  branch_exec0_is_taken_i_int;
wire                  branch_exec0_is_not_taken_i_int;
wire [ 31:0]          branch_exec0_source_i_int;
wire                  branch_exec0_is_call_i_int;
wire                  branch_exec0_is_ret_i_int;
wire                  branch_exec0_is_jmp_i_int;
wire [ 31:0]          branch_exec0_pc_i_int;
wire                  branch_d_exec0_request_i_int;
wire [ 31:0]          branch_d_exec0_pc_i_int;
wire [  1:0]          branch_d_exec0_priv_i_int;
wire                  branch_exec1_request_i_int;
wire                  branch_exec1_is_taken_i_int;
wire                  branch_exec1_is_not_taken_i_int;
wire [ 31:0]          branch_exec1_source_i_int;
wire                  branch_exec1_is_call_i_int;
wire                  branch_exec1_is_ret_i_int;
wire                  branch_exec1_is_jmp_i_int;
wire [ 31:0]          branch_exec1_pc_i_int;
wire                  branch_d_exec1_request_i_int;
wire [ 31:0]          branch_d_exec1_pc_i_int;
wire [  1:0]          branch_d_exec1_priv_i_int;
wire                  branch_csr_request_i_int;
wire [ 31:0]          branch_csr_pc_i_int;
wire [  1:0]          branch_csr_priv_i_int;
wire [ 31:0]          writeback_exec0_value_i_int;
wire [ 31:0]          writeback_exec1_value_i_int;
wire                  writeback_mem_valid_i_int;
wire [ 31:0]          writeback_mem_value_i_int;
wire [  5:0]          writeback_mem_exception_i_int;
wire [ 31:0]          writeback_mul_value_i_int;
wire                  writeback_div_valid_i_int;
wire [ 31:0]          writeback_div_value_i_int;
wire [ 31:0]          csr_result_e1_value_i_int;
wire                  csr_result_e1_write_i_int;
wire [ 31:0]          csr_result_e1_wdata_i_int;
wire [  5:0]          csr_result_e1_exception_i_int;
wire                  lsu_stall_i_int;
wire                  take_interrupt_i_int;
wire                  fetch0_accept_o_int;
wire                  fetch1_accept_o_int;
wire                  branch_request_o_int;
wire [ 31:0]          branch_pc_o_int;
wire [  1:0]          branch_priv_o_int;
wire                  branch_info_request_o_int;
wire                  branch_info_is_taken_o_int;
wire                  branch_info_is_not_taken_o_int;
wire [ 31:0]          branch_info_source_o_int;
wire                  branch_info_is_call_o_int;
wire                  branch_info_is_ret_o_int;
wire                  branch_info_is_jmp_o_int;
wire [ 31:0]          branch_info_pc_o_int;
wire                  exec0_opcode_valid_o_int;
wire                  exec1_opcode_valid_o_int;
wire                  lsu_opcode_valid_o_int;
wire                  csr_opcode_valid_o_int;
wire                  mul_opcode_valid_o_int;
wire                  div_opcode_valid_o_int;
wire [ 31:0]          opcode0_opcode_o_int;
wire [ 31:0]          opcode0_pc_o_int;
wire                  opcode0_invalid_o_int;
wire [  4:0]          opcode0_rd_idx_o_int;
wire [  4:0]          opcode0_ra_idx_o_int;
wire [  4:0]          opcode0_rb_idx_o_int;
wire [ 31:0]          opcode0_ra_operand_o_int;
wire [ 31:0]          opcode0_rb_operand_o_int;
wire [ 31:0]          opcode1_opcode_o_int;
wire [ 31:0]          opcode1_pc_o_int;
wire                  opcode1_invalid_o_int;
wire [  4:0]          opcode1_rd_idx_o_int;
wire [  4:0]          opcode1_ra_idx_o_int;
wire [  4:0]          opcode1_rb_idx_o_int;
wire [ 31:0]          opcode1_ra_operand_o_int;
wire [ 31:0]          opcode1_rb_operand_o_int;
wire [ 31:0]          lsu_opcode_opcode_o_int;
wire [ 31:0]          lsu_opcode_pc_o_int;
wire                  lsu_opcode_invalid_o_int;
wire [  4:0]          lsu_opcode_rd_idx_o_int;
wire [  4:0]          lsu_opcode_ra_idx_o_int;
wire [  4:0]          lsu_opcode_rb_idx_o_int;
wire [ 31:0]          lsu_opcode_ra_operand_o_int;
wire [ 31:0]          lsu_opcode_rb_operand_o_int;
wire [ 31:0]          mul_opcode_opcode_o_int;
wire [ 31:0]          mul_opcode_pc_o_int;
wire                  mul_opcode_invalid_o_int;
wire [  4:0]          mul_opcode_rd_idx_o_int;
wire [  4:0]          mul_opcode_ra_idx_o_int;
wire [  4:0]          mul_opcode_rb_idx_o_int;
wire [ 31:0]          mul_opcode_ra_operand_o_int;
wire [ 31:0]          mul_opcode_rb_operand_o_int;
wire [ 31:0]          csr_opcode_opcode_o_int;
wire [ 31:0]          csr_opcode_pc_o_int;
wire                  csr_opcode_invalid_o_int;
wire [  4:0]          csr_opcode_rd_idx_o_int;
wire [  4:0]          csr_opcode_ra_idx_o_int;
wire [  4:0]          csr_opcode_rb_idx_o_int;
wire [ 31:0]          csr_opcode_ra_operand_o_int;
wire [ 31:0]          csr_opcode_rb_operand_o_int;
wire                  csr_writeback_write_o_int;
wire [ 11:0]          csr_writeback_waddr_o_int;
wire [ 31:0]          csr_writeback_wdata_o_int;
wire [  5:0]          csr_writeback_exception_o_int;
wire [ 31:0]          csr_writeback_exception_pc_o_int;
wire [ 31:0]          csr_writeback_exception_addr_o_int;
wire                  exec0_hold_o_int;
wire                  exec1_hold_o_int;
wire                  mul_hold_o_int;
wire                  interrupt_inhibit_o_int;

generate
if (SYNTH_MODE_ISO)
begin : g_synth_iso
    // Input register wall
    reg                   fetch0_valid_i_iso_q;
    reg  [ 31:0]          fetch0_instr_i_iso_q;
    reg  [ 31:0]          fetch0_pc_i_iso_q;
    reg                   fetch0_fault_fetch_i_iso_q;
    reg                   fetch0_fault_page_i_iso_q;
    reg                   fetch0_instr_exec_i_iso_q;
    reg                   fetch0_instr_lsu_i_iso_q;
    reg                   fetch0_instr_branch_i_iso_q;
    reg                   fetch0_instr_mul_i_iso_q;
    reg                   fetch0_instr_div_i_iso_q;
    reg                   fetch0_instr_csr_i_iso_q;
    reg                   fetch0_instr_rd_valid_i_iso_q;
    reg                   fetch0_instr_invalid_i_iso_q;
    reg                   fetch1_valid_i_iso_q;
    reg  [ 31:0]          fetch1_instr_i_iso_q;
    reg  [ 31:0]          fetch1_pc_i_iso_q;
    reg                   fetch1_fault_fetch_i_iso_q;
    reg                   fetch1_fault_page_i_iso_q;
    reg                   fetch1_instr_exec_i_iso_q;
    reg                   fetch1_instr_lsu_i_iso_q;
    reg                   fetch1_instr_branch_i_iso_q;
    reg                   fetch1_instr_mul_i_iso_q;
    reg                   fetch1_instr_div_i_iso_q;
    reg                   fetch1_instr_csr_i_iso_q;
    reg                   fetch1_instr_rd_valid_i_iso_q;
    reg                   fetch1_instr_invalid_i_iso_q;
    reg                   branch_exec0_request_i_iso_q;
    reg                   branch_exec0_is_taken_i_iso_q;
    reg                   branch_exec0_is_not_taken_i_iso_q;
    reg  [ 31:0]          branch_exec0_source_i_iso_q;
    reg                   branch_exec0_is_call_i_iso_q;
    reg                   branch_exec0_is_ret_i_iso_q;
    reg                   branch_exec0_is_jmp_i_iso_q;
    reg  [ 31:0]          branch_exec0_pc_i_iso_q;
    reg                   branch_d_exec0_request_i_iso_q;
    reg  [ 31:0]          branch_d_exec0_pc_i_iso_q;
    reg  [  1:0]          branch_d_exec0_priv_i_iso_q;
    reg                   branch_exec1_request_i_iso_q;
    reg                   branch_exec1_is_taken_i_iso_q;
    reg                   branch_exec1_is_not_taken_i_iso_q;
    reg  [ 31:0]          branch_exec1_source_i_iso_q;
    reg                   branch_exec1_is_call_i_iso_q;
    reg                   branch_exec1_is_ret_i_iso_q;
    reg                   branch_exec1_is_jmp_i_iso_q;
    reg  [ 31:0]          branch_exec1_pc_i_iso_q;
    reg                   branch_d_exec1_request_i_iso_q;
    reg  [ 31:0]          branch_d_exec1_pc_i_iso_q;
    reg  [  1:0]          branch_d_exec1_priv_i_iso_q;
    reg                   branch_csr_request_i_iso_q;
    reg  [ 31:0]          branch_csr_pc_i_iso_q;
    reg  [  1:0]          branch_csr_priv_i_iso_q;
    reg  [ 31:0]          writeback_exec0_value_i_iso_q;
    reg  [ 31:0]          writeback_exec1_value_i_iso_q;
    reg                   writeback_mem_valid_i_iso_q;
    reg  [ 31:0]          writeback_mem_value_i_iso_q;
    reg  [  5:0]          writeback_mem_exception_i_iso_q;
    reg  [ 31:0]          writeback_mul_value_i_iso_q;
    reg                   writeback_div_valid_i_iso_q;
    reg  [ 31:0]          writeback_div_value_i_iso_q;
    reg  [ 31:0]          csr_result_e1_value_i_iso_q;
    reg                   csr_result_e1_write_i_iso_q;
    reg  [ 31:0]          csr_result_e1_wdata_i_iso_q;
    reg  [  5:0]          csr_result_e1_exception_i_iso_q;
    reg                   lsu_stall_i_iso_q;
    reg                   take_interrupt_i_iso_q;

    always @ (posedge clk_i)
    begin
        fetch0_valid_i_iso_q <= fetch0_valid_i;
        fetch0_instr_i_iso_q <= fetch0_instr_i;
        fetch0_pc_i_iso_q <= fetch0_pc_i;
        fetch0_fault_fetch_i_iso_q <= fetch0_fault_fetch_i;
        fetch0_fault_page_i_iso_q <= fetch0_fault_page_i;
        fetch0_instr_exec_i_iso_q <= fetch0_instr_exec_i;
        fetch0_instr_lsu_i_iso_q <= fetch0_instr_lsu_i;
        fetch0_instr_branch_i_iso_q <= fetch0_instr_branch_i;
        fetch0_instr_mul_i_iso_q <= fetch0_instr_mul_i;
        fetch0_instr_div_i_iso_q <= fetch0_instr_div_i;
        fetch0_instr_csr_i_iso_q <= fetch0_instr_csr_i;
        fetch0_instr_rd_valid_i_iso_q <= fetch0_instr_rd_valid_i;
        fetch0_instr_invalid_i_iso_q <= fetch0_instr_invalid_i;
        fetch1_valid_i_iso_q <= fetch1_valid_i;
        fetch1_instr_i_iso_q <= fetch1_instr_i;
        fetch1_pc_i_iso_q <= fetch1_pc_i;
        fetch1_fault_fetch_i_iso_q <= fetch1_fault_fetch_i;
        fetch1_fault_page_i_iso_q <= fetch1_fault_page_i;
        fetch1_instr_exec_i_iso_q <= fetch1_instr_exec_i;
        fetch1_instr_lsu_i_iso_q <= fetch1_instr_lsu_i;
        fetch1_instr_branch_i_iso_q <= fetch1_instr_branch_i;
        fetch1_instr_mul_i_iso_q <= fetch1_instr_mul_i;
        fetch1_instr_div_i_iso_q <= fetch1_instr_div_i;
        fetch1_instr_csr_i_iso_q <= fetch1_instr_csr_i;
        fetch1_instr_rd_valid_i_iso_q <= fetch1_instr_rd_valid_i;
        fetch1_instr_invalid_i_iso_q <= fetch1_instr_invalid_i;
        branch_exec0_request_i_iso_q <= branch_exec0_request_i;
        branch_exec0_is_taken_i_iso_q <= branch_exec0_is_taken_i;
        branch_exec0_is_not_taken_i_iso_q <= branch_exec0_is_not_taken_i;
        branch_exec0_source_i_iso_q <= branch_exec0_source_i;
        branch_exec0_is_call_i_iso_q <= branch_exec0_is_call_i;
        branch_exec0_is_ret_i_iso_q <= branch_exec0_is_ret_i;
        branch_exec0_is_jmp_i_iso_q <= branch_exec0_is_jmp_i;
        branch_exec0_pc_i_iso_q <= branch_exec0_pc_i;
        branch_d_exec0_request_i_iso_q <= branch_d_exec0_request_i;
        branch_d_exec0_pc_i_iso_q <= branch_d_exec0_pc_i;
        branch_d_exec0_priv_i_iso_q <= branch_d_exec0_priv_i;
        branch_exec1_request_i_iso_q <= branch_exec1_request_i;
        branch_exec1_is_taken_i_iso_q <= branch_exec1_is_taken_i;
        branch_exec1_is_not_taken_i_iso_q <= branch_exec1_is_not_taken_i;
        branch_exec1_source_i_iso_q <= branch_exec1_source_i;
        branch_exec1_is_call_i_iso_q <= branch_exec1_is_call_i;
        branch_exec1_is_ret_i_iso_q <= branch_exec1_is_ret_i;
        branch_exec1_is_jmp_i_iso_q <= branch_exec1_is_jmp_i;
        branch_exec1_pc_i_iso_q <= branch_exec1_pc_i;
        branch_d_exec1_request_i_iso_q <= branch_d_exec1_request_i;
        branch_d_exec1_pc_i_iso_q <= branch_d_exec1_pc_i;
        branch_d_exec1_priv_i_iso_q <= branch_d_exec1_priv_i;
        branch_csr_request_i_iso_q <= branch_csr_request_i;
        branch_csr_pc_i_iso_q <= branch_csr_pc_i;
        branch_csr_priv_i_iso_q <= branch_csr_priv_i;
        writeback_exec0_value_i_iso_q <= writeback_exec0_value_i;
        writeback_exec1_value_i_iso_q <= writeback_exec1_value_i;
        writeback_mem_valid_i_iso_q <= writeback_mem_valid_i;
        writeback_mem_value_i_iso_q <= writeback_mem_value_i;
        writeback_mem_exception_i_iso_q <= writeback_mem_exception_i;
        writeback_mul_value_i_iso_q <= writeback_mul_value_i;
        writeback_div_valid_i_iso_q <= writeback_div_valid_i;
        writeback_div_value_i_iso_q <= writeback_div_value_i;
        csr_result_e1_value_i_iso_q <= csr_result_e1_value_i;
        csr_result_e1_write_i_iso_q <= csr_result_e1_write_i;
        csr_result_e1_wdata_i_iso_q <= csr_result_e1_wdata_i;
        csr_result_e1_exception_i_iso_q <= csr_result_e1_exception_i;
        lsu_stall_i_iso_q <= lsu_stall_i;
        take_interrupt_i_iso_q <= take_interrupt_i;
    end

    assign fetch0_valid_i_int = fetch0_valid_i_iso_q;
    assign fetch0_instr_i_int = fetch0_instr_i_iso_q;
    assign fetch0_pc_i_int = fetch0_pc_i_iso_q;
    assign fetch0_fault_fetch_i_int = fetch0_fault_fetch_i_iso_q;
    assign fetch0_fault_page_i_int = fetch0_fault_page_i_iso_q;
    assign fetch0_instr_exec_i_int = fetch0_instr_exec_i_iso_q;
    assign fetch0_instr_lsu_i_int = fetch0_instr_lsu_i_iso_q;
    assign fetch0_instr_branch_i_int = fetch0_instr_branch_i_iso_q;
    assign fetch0_instr_mul_i_int = fetch0_instr_mul_i_iso_q;
    assign fetch0_instr_div_i_int = fetch0_instr_div_i_iso_q;
    assign fetch0_instr_csr_i_int = fetch0_instr_csr_i_iso_q;
    assign fetch0_instr_rd_valid_i_int = fetch0_instr_rd_valid_i_iso_q;
    assign fetch0_instr_invalid_i_int = fetch0_instr_invalid_i_iso_q;
    assign fetch1_valid_i_int = fetch1_valid_i_iso_q;
    assign fetch1_instr_i_int = fetch1_instr_i_iso_q;
    assign fetch1_pc_i_int = fetch1_pc_i_iso_q;
    assign fetch1_fault_fetch_i_int = fetch1_fault_fetch_i_iso_q;
    assign fetch1_fault_page_i_int = fetch1_fault_page_i_iso_q;
    assign fetch1_instr_exec_i_int = fetch1_instr_exec_i_iso_q;
    assign fetch1_instr_lsu_i_int = fetch1_instr_lsu_i_iso_q;
    assign fetch1_instr_branch_i_int = fetch1_instr_branch_i_iso_q;
    assign fetch1_instr_mul_i_int = fetch1_instr_mul_i_iso_q;
    assign fetch1_instr_div_i_int = fetch1_instr_div_i_iso_q;
    assign fetch1_instr_csr_i_int = fetch1_instr_csr_i_iso_q;
    assign fetch1_instr_rd_valid_i_int = fetch1_instr_rd_valid_i_iso_q;
    assign fetch1_instr_invalid_i_int = fetch1_instr_invalid_i_iso_q;
    assign branch_exec0_request_i_int = branch_exec0_request_i_iso_q;
    assign branch_exec0_is_taken_i_int = branch_exec0_is_taken_i_iso_q;
    assign branch_exec0_is_not_taken_i_int = branch_exec0_is_not_taken_i_iso_q;
    assign branch_exec0_source_i_int = branch_exec0_source_i_iso_q;
    assign branch_exec0_is_call_i_int = branch_exec0_is_call_i_iso_q;
    assign branch_exec0_is_ret_i_int = branch_exec0_is_ret_i_iso_q;
    assign branch_exec0_is_jmp_i_int = branch_exec0_is_jmp_i_iso_q;
    assign branch_exec0_pc_i_int = branch_exec0_pc_i_iso_q;
    assign branch_d_exec0_request_i_int = branch_d_exec0_request_i_iso_q;
    assign branch_d_exec0_pc_i_int = branch_d_exec0_pc_i_iso_q;
    assign branch_d_exec0_priv_i_int = branch_d_exec0_priv_i_iso_q;
    assign branch_exec1_request_i_int = branch_exec1_request_i_iso_q;
    assign branch_exec1_is_taken_i_int = branch_exec1_is_taken_i_iso_q;
    assign branch_exec1_is_not_taken_i_int = branch_exec1_is_not_taken_i_iso_q;
    assign branch_exec1_source_i_int = branch_exec1_source_i_iso_q;
    assign branch_exec1_is_call_i_int = branch_exec1_is_call_i_iso_q;
    assign branch_exec1_is_ret_i_int = branch_exec1_is_ret_i_iso_q;
    assign branch_exec1_is_jmp_i_int = branch_exec1_is_jmp_i_iso_q;
    assign branch_exec1_pc_i_int = branch_exec1_pc_i_iso_q;
    assign branch_d_exec1_request_i_int = branch_d_exec1_request_i_iso_q;
    assign branch_d_exec1_pc_i_int = branch_d_exec1_pc_i_iso_q;
    assign branch_d_exec1_priv_i_int = branch_d_exec1_priv_i_iso_q;
    assign branch_csr_request_i_int = branch_csr_request_i_iso_q;
    assign branch_csr_pc_i_int = branch_csr_pc_i_iso_q;
    assign branch_csr_priv_i_int = branch_csr_priv_i_iso_q;
    assign writeback_exec0_value_i_int = writeback_exec0_value_i_iso_q;
    assign writeback_exec1_value_i_int = writeback_exec1_value_i_iso_q;
    assign writeback_mem_valid_i_int = writeback_mem_valid_i_iso_q;
    assign writeback_mem_value_i_int = writeback_mem_value_i_iso_q;
    assign writeback_mem_exception_i_int = writeback_mem_exception_i_iso_q;
    assign writeback_mul_value_i_int = writeback_mul_value_i_iso_q;
    assign writeback_div_valid_i_int = writeback_div_valid_i_iso_q;
    assign writeback_div_value_i_int = writeback_div_value_i_iso_q;
    assign csr_result_e1_value_i_int = csr_result_e1_value_i_iso_q;
    assign csr_result_e1_write_i_int = csr_result_e1_write_i_iso_q;
    assign csr_result_e1_wdata_i_int = csr_result_e1_wdata_i_iso_q;
    assign csr_result_e1_exception_i_int = csr_result_e1_exception_i_iso_q;
    assign lsu_stall_i_int = lsu_stall_i_iso_q;
    assign take_interrupt_i_int = take_interrupt_i_iso_q;

    // Output register wall
    reg                   fetch0_accept_o_iso_q;
    reg                   fetch1_accept_o_iso_q;
    reg                   branch_request_o_iso_q;
    reg  [ 31:0]          branch_pc_o_iso_q;
    reg  [  1:0]          branch_priv_o_iso_q;
    reg                   branch_info_request_o_iso_q;
    reg                   branch_info_is_taken_o_iso_q;
    reg                   branch_info_is_not_taken_o_iso_q;
    reg  [ 31:0]          branch_info_source_o_iso_q;
    reg                   branch_info_is_call_o_iso_q;
    reg                   branch_info_is_ret_o_iso_q;
    reg                   branch_info_is_jmp_o_iso_q;
    reg  [ 31:0]          branch_info_pc_o_iso_q;
    reg                   exec0_opcode_valid_o_iso_q;
    reg                   exec1_opcode_valid_o_iso_q;
    reg                   lsu_opcode_valid_o_iso_q;
    reg                   csr_opcode_valid_o_iso_q;
    reg                   mul_opcode_valid_o_iso_q;
    reg                   div_opcode_valid_o_iso_q;
    reg  [ 31:0]          opcode0_opcode_o_iso_q;
    reg  [ 31:0]          opcode0_pc_o_iso_q;
    reg                   opcode0_invalid_o_iso_q;
    reg  [  4:0]          opcode0_rd_idx_o_iso_q;
    reg  [  4:0]          opcode0_ra_idx_o_iso_q;
    reg  [  4:0]          opcode0_rb_idx_o_iso_q;
    reg  [ 31:0]          opcode0_ra_operand_o_iso_q;
    reg  [ 31:0]          opcode0_rb_operand_o_iso_q;
    reg  [ 31:0]          opcode1_opcode_o_iso_q;
    reg  [ 31:0]          opcode1_pc_o_iso_q;
    reg                   opcode1_invalid_o_iso_q;
    reg  [  4:0]          opcode1_rd_idx_o_iso_q;
    reg  [  4:0]          opcode1_ra_idx_o_iso_q;
    reg  [  4:0]          opcode1_rb_idx_o_iso_q;
    reg  [ 31:0]          opcode1_ra_operand_o_iso_q;
    reg  [ 31:0]          opcode1_rb_operand_o_iso_q;
    reg  [ 31:0]          lsu_opcode_opcode_o_iso_q;
    reg  [ 31:0]          lsu_opcode_pc_o_iso_q;
    reg                   lsu_opcode_invalid_o_iso_q;
    reg  [  4:0]          lsu_opcode_rd_idx_o_iso_q;
    reg  [  4:0]          lsu_opcode_ra_idx_o_iso_q;
    reg  [  4:0]          lsu_opcode_rb_idx_o_iso_q;
    reg  [ 31:0]          lsu_opcode_ra_operand_o_iso_q;
    reg  [ 31:0]          lsu_opcode_rb_operand_o_iso_q;
    reg  [ 31:0]          mul_opcode_opcode_o_iso_q;
    reg  [ 31:0]          mul_opcode_pc_o_iso_q;
    reg                   mul_opcode_invalid_o_iso_q;
    reg  [  4:0]          mul_opcode_rd_idx_o_iso_q;
    reg  [  4:0]          mul_opcode_ra_idx_o_iso_q;
    reg  [  4:0]          mul_opcode_rb_idx_o_iso_q;
    reg  [ 31:0]          mul_opcode_ra_operand_o_iso_q;
    reg  [ 31:0]          mul_opcode_rb_operand_o_iso_q;
    reg  [ 31:0]          csr_opcode_opcode_o_iso_q;
    reg  [ 31:0]          csr_opcode_pc_o_iso_q;
    reg                   csr_opcode_invalid_o_iso_q;
    reg  [  4:0]          csr_opcode_rd_idx_o_iso_q;
    reg  [  4:0]          csr_opcode_ra_idx_o_iso_q;
    reg  [  4:0]          csr_opcode_rb_idx_o_iso_q;
    reg  [ 31:0]          csr_opcode_ra_operand_o_iso_q;
    reg  [ 31:0]          csr_opcode_rb_operand_o_iso_q;
    reg                   csr_writeback_write_o_iso_q;
    reg  [ 11:0]          csr_writeback_waddr_o_iso_q;
    reg  [ 31:0]          csr_writeback_wdata_o_iso_q;
    reg  [  5:0]          csr_writeback_exception_o_iso_q;
    reg  [ 31:0]          csr_writeback_exception_pc_o_iso_q;
    reg  [ 31:0]          csr_writeback_exception_addr_o_iso_q;
    reg                   exec0_hold_o_iso_q;
    reg                   exec1_hold_o_iso_q;
    reg                   mul_hold_o_iso_q;
    reg                   interrupt_inhibit_o_iso_q;

    always @ (posedge clk_i)
    begin
        fetch0_accept_o_iso_q <= fetch0_accept_o_int;
        fetch1_accept_o_iso_q <= fetch1_accept_o_int;
        branch_request_o_iso_q <= branch_request_o_int;
        branch_pc_o_iso_q <= branch_pc_o_int;
        branch_priv_o_iso_q <= branch_priv_o_int;
        branch_info_request_o_iso_q <= branch_info_request_o_int;
        branch_info_is_taken_o_iso_q <= branch_info_is_taken_o_int;
        branch_info_is_not_taken_o_iso_q <= branch_info_is_not_taken_o_int;
        branch_info_source_o_iso_q <= branch_info_source_o_int;
        branch_info_is_call_o_iso_q <= branch_info_is_call_o_int;
        branch_info_is_ret_o_iso_q <= branch_info_is_ret_o_int;
        branch_info_is_jmp_o_iso_q <= branch_info_is_jmp_o_int;
        branch_info_pc_o_iso_q <= branch_info_pc_o_int;
        exec0_opcode_valid_o_iso_q <= exec0_opcode_valid_o_int;
        exec1_opcode_valid_o_iso_q <= exec1_opcode_valid_o_int;
        lsu_opcode_valid_o_iso_q <= lsu_opcode_valid_o_int;
        csr_opcode_valid_o_iso_q <= csr_opcode_valid_o_int;
        mul_opcode_valid_o_iso_q <= mul_opcode_valid_o_int;
        div_opcode_valid_o_iso_q <= div_opcode_valid_o_int;
        opcode0_opcode_o_iso_q <= opcode0_opcode_o_int;
        opcode0_pc_o_iso_q <= opcode0_pc_o_int;
        opcode0_invalid_o_iso_q <= opcode0_invalid_o_int;
        opcode0_rd_idx_o_iso_q <= opcode0_rd_idx_o_int;
        opcode0_ra_idx_o_iso_q <= opcode0_ra_idx_o_int;
        opcode0_rb_idx_o_iso_q <= opcode0_rb_idx_o_int;
        opcode0_ra_operand_o_iso_q <= opcode0_ra_operand_o_int;
        opcode0_rb_operand_o_iso_q <= opcode0_rb_operand_o_int;
        opcode1_opcode_o_iso_q <= opcode1_opcode_o_int;
        opcode1_pc_o_iso_q <= opcode1_pc_o_int;
        opcode1_invalid_o_iso_q <= opcode1_invalid_o_int;
        opcode1_rd_idx_o_iso_q <= opcode1_rd_idx_o_int;
        opcode1_ra_idx_o_iso_q <= opcode1_ra_idx_o_int;
        opcode1_rb_idx_o_iso_q <= opcode1_rb_idx_o_int;
        opcode1_ra_operand_o_iso_q <= opcode1_ra_operand_o_int;
        opcode1_rb_operand_o_iso_q <= opcode1_rb_operand_o_int;
        lsu_opcode_opcode_o_iso_q <= lsu_opcode_opcode_o_int;
        lsu_opcode_pc_o_iso_q <= lsu_opcode_pc_o_int;
        lsu_opcode_invalid_o_iso_q <= lsu_opcode_invalid_o_int;
        lsu_opcode_rd_idx_o_iso_q <= lsu_opcode_rd_idx_o_int;
        lsu_opcode_ra_idx_o_iso_q <= lsu_opcode_ra_idx_o_int;
        lsu_opcode_rb_idx_o_iso_q <= lsu_opcode_rb_idx_o_int;
        lsu_opcode_ra_operand_o_iso_q <= lsu_opcode_ra_operand_o_int;
        lsu_opcode_rb_operand_o_iso_q <= lsu_opcode_rb_operand_o_int;
        mul_opcode_opcode_o_iso_q <= mul_opcode_opcode_o_int;
        mul_opcode_pc_o_iso_q <= mul_opcode_pc_o_int;
        mul_opcode_invalid_o_iso_q <= mul_opcode_invalid_o_int;
        mul_opcode_rd_idx_o_iso_q <= mul_opcode_rd_idx_o_int;
        mul_opcode_ra_idx_o_iso_q <= mul_opcode_ra_idx_o_int;
        mul_opcode_rb_idx_o_iso_q <= mul_opcode_rb_idx_o_int;
        mul_opcode_ra_operand_o_iso_q <= mul_opcode_ra_operand_o_int;
        mul_opcode_rb_operand_o_iso_q <= mul_opcode_rb_operand_o_int;
        csr_opcode_opcode_o_iso_q <= csr_opcode_opcode_o_int;
        csr_opcode_pc_o_iso_q <= csr_opcode_pc_o_int;
        csr_opcode_invalid_o_iso_q <= csr_opcode_invalid_o_int;
        csr_opcode_rd_idx_o_iso_q <= csr_opcode_rd_idx_o_int;
        csr_opcode_ra_idx_o_iso_q <= csr_opcode_ra_idx_o_int;
        csr_opcode_rb_idx_o_iso_q <= csr_opcode_rb_idx_o_int;
        csr_opcode_ra_operand_o_iso_q <= csr_opcode_ra_operand_o_int;
        csr_opcode_rb_operand_o_iso_q <= csr_opcode_rb_operand_o_int;
        csr_writeback_write_o_iso_q <= csr_writeback_write_o_int;
        csr_writeback_waddr_o_iso_q <= csr_writeback_waddr_o_int;
        csr_writeback_wdata_o_iso_q <= csr_writeback_wdata_o_int;
        csr_writeback_exception_o_iso_q <= csr_writeback_exception_o_int;
        csr_writeback_exception_pc_o_iso_q <= csr_writeback_exception_pc_o_int;
        csr_writeback_exception_addr_o_iso_q <= csr_writeback_exception_addr_o_int;
        exec0_hold_o_iso_q <= exec0_hold_o_int;
        exec1_hold_o_iso_q <= exec1_hold_o_int;
        mul_hold_o_iso_q <= mul_hold_o_int;
        interrupt_inhibit_o_iso_q <= interrupt_inhibit_o_int;
    end

    assign fetch0_accept_o = fetch0_accept_o_iso_q;
    assign fetch1_accept_o = fetch1_accept_o_iso_q;
    assign branch_request_o = branch_request_o_iso_q;
    assign branch_pc_o = branch_pc_o_iso_q;
    assign branch_priv_o = branch_priv_o_iso_q;
    assign branch_info_request_o = branch_info_request_o_iso_q;
    assign branch_info_is_taken_o = branch_info_is_taken_o_iso_q;
    assign branch_info_is_not_taken_o = branch_info_is_not_taken_o_iso_q;
    assign branch_info_source_o = branch_info_source_o_iso_q;
    assign branch_info_is_call_o = branch_info_is_call_o_iso_q;
    assign branch_info_is_ret_o = branch_info_is_ret_o_iso_q;
    assign branch_info_is_jmp_o = branch_info_is_jmp_o_iso_q;
    assign branch_info_pc_o = branch_info_pc_o_iso_q;
    assign exec0_opcode_valid_o = exec0_opcode_valid_o_iso_q;
    assign exec1_opcode_valid_o = exec1_opcode_valid_o_iso_q;
    assign lsu_opcode_valid_o = lsu_opcode_valid_o_iso_q;
    assign csr_opcode_valid_o = csr_opcode_valid_o_iso_q;
    assign mul_opcode_valid_o = mul_opcode_valid_o_iso_q;
    assign div_opcode_valid_o = div_opcode_valid_o_iso_q;
    assign opcode0_opcode_o = opcode0_opcode_o_iso_q;
    assign opcode0_pc_o = opcode0_pc_o_iso_q;
    assign opcode0_invalid_o = opcode0_invalid_o_iso_q;
    assign opcode0_rd_idx_o = opcode0_rd_idx_o_iso_q;
    assign opcode0_ra_idx_o = opcode0_ra_idx_o_iso_q;
    assign opcode0_rb_idx_o = opcode0_rb_idx_o_iso_q;
    assign opcode0_ra_operand_o = opcode0_ra_operand_o_iso_q;
    assign opcode0_rb_operand_o = opcode0_rb_operand_o_iso_q;
    assign opcode1_opcode_o = opcode1_opcode_o_iso_q;
    assign opcode1_pc_o = opcode1_pc_o_iso_q;
    assign opcode1_invalid_o = opcode1_invalid_o_iso_q;
    assign opcode1_rd_idx_o = opcode1_rd_idx_o_iso_q;
    assign opcode1_ra_idx_o = opcode1_ra_idx_o_iso_q;
    assign opcode1_rb_idx_o = opcode1_rb_idx_o_iso_q;
    assign opcode1_ra_operand_o = opcode1_ra_operand_o_iso_q;
    assign opcode1_rb_operand_o = opcode1_rb_operand_o_iso_q;
    assign lsu_opcode_opcode_o = lsu_opcode_opcode_o_iso_q;
    assign lsu_opcode_pc_o = lsu_opcode_pc_o_iso_q;
    assign lsu_opcode_invalid_o = lsu_opcode_invalid_o_iso_q;
    assign lsu_opcode_rd_idx_o = lsu_opcode_rd_idx_o_iso_q;
    assign lsu_opcode_ra_idx_o = lsu_opcode_ra_idx_o_iso_q;
    assign lsu_opcode_rb_idx_o = lsu_opcode_rb_idx_o_iso_q;
    assign lsu_opcode_ra_operand_o = lsu_opcode_ra_operand_o_iso_q;
    assign lsu_opcode_rb_operand_o = lsu_opcode_rb_operand_o_iso_q;
    assign mul_opcode_opcode_o = mul_opcode_opcode_o_iso_q;
    assign mul_opcode_pc_o = mul_opcode_pc_o_iso_q;
    assign mul_opcode_invalid_o = mul_opcode_invalid_o_iso_q;
    assign mul_opcode_rd_idx_o = mul_opcode_rd_idx_o_iso_q;
    assign mul_opcode_ra_idx_o = mul_opcode_ra_idx_o_iso_q;
    assign mul_opcode_rb_idx_o = mul_opcode_rb_idx_o_iso_q;
    assign mul_opcode_ra_operand_o = mul_opcode_ra_operand_o_iso_q;
    assign mul_opcode_rb_operand_o = mul_opcode_rb_operand_o_iso_q;
    assign csr_opcode_opcode_o = csr_opcode_opcode_o_iso_q;
    assign csr_opcode_pc_o = csr_opcode_pc_o_iso_q;
    assign csr_opcode_invalid_o = csr_opcode_invalid_o_iso_q;
    assign csr_opcode_rd_idx_o = csr_opcode_rd_idx_o_iso_q;
    assign csr_opcode_ra_idx_o = csr_opcode_ra_idx_o_iso_q;
    assign csr_opcode_rb_idx_o = csr_opcode_rb_idx_o_iso_q;
    assign csr_opcode_ra_operand_o = csr_opcode_ra_operand_o_iso_q;
    assign csr_opcode_rb_operand_o = csr_opcode_rb_operand_o_iso_q;
    assign csr_writeback_write_o = csr_writeback_write_o_iso_q;
    assign csr_writeback_waddr_o = csr_writeback_waddr_o_iso_q;
    assign csr_writeback_wdata_o = csr_writeback_wdata_o_iso_q;
    assign csr_writeback_exception_o = csr_writeback_exception_o_iso_q;
    assign csr_writeback_exception_pc_o = csr_writeback_exception_pc_o_iso_q;
    assign csr_writeback_exception_addr_o = csr_writeback_exception_addr_o_iso_q;
    assign exec0_hold_o = exec0_hold_o_iso_q;
    assign exec1_hold_o = exec1_hold_o_iso_q;
    assign mul_hold_o = mul_hold_o_iso_q;
    assign interrupt_inhibit_o = interrupt_inhibit_o_iso_q;
end
else
begin : g_synth_no_iso
    assign fetch0_valid_i_int = fetch0_valid_i;
    assign fetch0_instr_i_int = fetch0_instr_i;
    assign fetch0_pc_i_int = fetch0_pc_i;
    assign fetch0_fault_fetch_i_int = fetch0_fault_fetch_i;
    assign fetch0_fault_page_i_int = fetch0_fault_page_i;
    assign fetch0_instr_exec_i_int = fetch0_instr_exec_i;
    assign fetch0_instr_lsu_i_int = fetch0_instr_lsu_i;
    assign fetch0_instr_branch_i_int = fetch0_instr_branch_i;
    assign fetch0_instr_mul_i_int = fetch0_instr_mul_i;
    assign fetch0_instr_div_i_int = fetch0_instr_div_i;
    assign fetch0_instr_csr_i_int = fetch0_instr_csr_i;
    assign fetch0_instr_rd_valid_i_int = fetch0_instr_rd_valid_i;
    assign fetch0_instr_invalid_i_int = fetch0_instr_invalid_i;
    assign fetch1_valid_i_int = fetch1_valid_i;
    assign fetch1_instr_i_int = fetch1_instr_i;
    assign fetch1_pc_i_int = fetch1_pc_i;
    assign fetch1_fault_fetch_i_int = fetch1_fault_fetch_i;
    assign fetch1_fault_page_i_int = fetch1_fault_page_i;
    assign fetch1_instr_exec_i_int = fetch1_instr_exec_i;
    assign fetch1_instr_lsu_i_int = fetch1_instr_lsu_i;
    assign fetch1_instr_branch_i_int = fetch1_instr_branch_i;
    assign fetch1_instr_mul_i_int = fetch1_instr_mul_i;
    assign fetch1_instr_div_i_int = fetch1_instr_div_i;
    assign fetch1_instr_csr_i_int = fetch1_instr_csr_i;
    assign fetch1_instr_rd_valid_i_int = fetch1_instr_rd_valid_i;
    assign fetch1_instr_invalid_i_int = fetch1_instr_invalid_i;
    assign branch_exec0_request_i_int = branch_exec0_request_i;
    assign branch_exec0_is_taken_i_int = branch_exec0_is_taken_i;
    assign branch_exec0_is_not_taken_i_int = branch_exec0_is_not_taken_i;
    assign branch_exec0_source_i_int = branch_exec0_source_i;
    assign branch_exec0_is_call_i_int = branch_exec0_is_call_i;
    assign branch_exec0_is_ret_i_int = branch_exec0_is_ret_i;
    assign branch_exec0_is_jmp_i_int = branch_exec0_is_jmp_i;
    assign branch_exec0_pc_i_int = branch_exec0_pc_i;
    assign branch_d_exec0_request_i_int = branch_d_exec0_request_i;
    assign branch_d_exec0_pc_i_int = branch_d_exec0_pc_i;
    assign branch_d_exec0_priv_i_int = branch_d_exec0_priv_i;
    assign branch_exec1_request_i_int = branch_exec1_request_i;
    assign branch_exec1_is_taken_i_int = branch_exec1_is_taken_i;
    assign branch_exec1_is_not_taken_i_int = branch_exec1_is_not_taken_i;
    assign branch_exec1_source_i_int = branch_exec1_source_i;
    assign branch_exec1_is_call_i_int = branch_exec1_is_call_i;
    assign branch_exec1_is_ret_i_int = branch_exec1_is_ret_i;
    assign branch_exec1_is_jmp_i_int = branch_exec1_is_jmp_i;
    assign branch_exec1_pc_i_int = branch_exec1_pc_i;
    assign branch_d_exec1_request_i_int = branch_d_exec1_request_i;
    assign branch_d_exec1_pc_i_int = branch_d_exec1_pc_i;
    assign branch_d_exec1_priv_i_int = branch_d_exec1_priv_i;
    assign branch_csr_request_i_int = branch_csr_request_i;
    assign branch_csr_pc_i_int = branch_csr_pc_i;
    assign branch_csr_priv_i_int = branch_csr_priv_i;
    assign writeback_exec0_value_i_int = writeback_exec0_value_i;
    assign writeback_exec1_value_i_int = writeback_exec1_value_i;
    assign writeback_mem_valid_i_int = writeback_mem_valid_i;
    assign writeback_mem_value_i_int = writeback_mem_value_i;
    assign writeback_mem_exception_i_int = writeback_mem_exception_i;
    assign writeback_mul_value_i_int = writeback_mul_value_i;
    assign writeback_div_valid_i_int = writeback_div_valid_i;
    assign writeback_div_value_i_int = writeback_div_value_i;
    assign csr_result_e1_value_i_int = csr_result_e1_value_i;
    assign csr_result_e1_write_i_int = csr_result_e1_write_i;
    assign csr_result_e1_wdata_i_int = csr_result_e1_wdata_i;
    assign csr_result_e1_exception_i_int = csr_result_e1_exception_i;
    assign lsu_stall_i_int = lsu_stall_i;
    assign take_interrupt_i_int = take_interrupt_i;
    assign fetch0_accept_o = fetch0_accept_o_int;
    assign fetch1_accept_o = fetch1_accept_o_int;
    assign branch_request_o = branch_request_o_int;
    assign branch_pc_o = branch_pc_o_int;
    assign branch_priv_o = branch_priv_o_int;
    assign branch_info_request_o = branch_info_request_o_int;
    assign branch_info_is_taken_o = branch_info_is_taken_o_int;
    assign branch_info_is_not_taken_o = branch_info_is_not_taken_o_int;
    assign branch_info_source_o = branch_info_source_o_int;
    assign branch_info_is_call_o = branch_info_is_call_o_int;
    assign branch_info_is_ret_o = branch_info_is_ret_o_int;
    assign branch_info_is_jmp_o = branch_info_is_jmp_o_int;
    assign branch_info_pc_o = branch_info_pc_o_int;
    assign exec0_opcode_valid_o = exec0_opcode_valid_o_int;
    assign exec1_opcode_valid_o = exec1_opcode_valid_o_int;
    assign lsu_opcode_valid_o = lsu_opcode_valid_o_int;
    assign csr_opcode_valid_o = csr_opcode_valid_o_int;
    assign mul_opcode_valid_o = mul_opcode_valid_o_int;
    assign div_opcode_valid_o = div_opcode_valid_o_int;
    assign opcode0_opcode_o = opcode0_opcode_o_int;
    assign opcode0_pc_o = opcode0_pc_o_int;
    assign opcode0_invalid_o = opcode0_invalid_o_int;
    assign opcode0_rd_idx_o = opcode0_rd_idx_o_int;
    assign opcode0_ra_idx_o = opcode0_ra_idx_o_int;
    assign opcode0_rb_idx_o = opcode0_rb_idx_o_int;
    assign opcode0_ra_operand_o = opcode0_ra_operand_o_int;
    assign opcode0_rb_operand_o = opcode0_rb_operand_o_int;
    assign opcode1_opcode_o = opcode1_opcode_o_int;
    assign opcode1_pc_o = opcode1_pc_o_int;
    assign opcode1_invalid_o = opcode1_invalid_o_int;
    assign opcode1_rd_idx_o = opcode1_rd_idx_o_int;
    assign opcode1_ra_idx_o = opcode1_ra_idx_o_int;
    assign opcode1_rb_idx_o = opcode1_rb_idx_o_int;
    assign opcode1_ra_operand_o = opcode1_ra_operand_o_int;
    assign opcode1_rb_operand_o = opcode1_rb_operand_o_int;
    assign lsu_opcode_opcode_o = lsu_opcode_opcode_o_int;
    assign lsu_opcode_pc_o = lsu_opcode_pc_o_int;
    assign lsu_opcode_invalid_o = lsu_opcode_invalid_o_int;
    assign lsu_opcode_rd_idx_o = lsu_opcode_rd_idx_o_int;
    assign lsu_opcode_ra_idx_o = lsu_opcode_ra_idx_o_int;
    assign lsu_opcode_rb_idx_o = lsu_opcode_rb_idx_o_int;
    assign lsu_opcode_ra_operand_o = lsu_opcode_ra_operand_o_int;
    assign lsu_opcode_rb_operand_o = lsu_opcode_rb_operand_o_int;
    assign mul_opcode_opcode_o = mul_opcode_opcode_o_int;
    assign mul_opcode_pc_o = mul_opcode_pc_o_int;
    assign mul_opcode_invalid_o = mul_opcode_invalid_o_int;
    assign mul_opcode_rd_idx_o = mul_opcode_rd_idx_o_int;
    assign mul_opcode_ra_idx_o = mul_opcode_ra_idx_o_int;
    assign mul_opcode_rb_idx_o = mul_opcode_rb_idx_o_int;
    assign mul_opcode_ra_operand_o = mul_opcode_ra_operand_o_int;
    assign mul_opcode_rb_operand_o = mul_opcode_rb_operand_o_int;
    assign csr_opcode_opcode_o = csr_opcode_opcode_o_int;
    assign csr_opcode_pc_o = csr_opcode_pc_o_int;
    assign csr_opcode_invalid_o = csr_opcode_invalid_o_int;
    assign csr_opcode_rd_idx_o = csr_opcode_rd_idx_o_int;
    assign csr_opcode_ra_idx_o = csr_opcode_ra_idx_o_int;
    assign csr_opcode_rb_idx_o = csr_opcode_rb_idx_o_int;
    assign csr_opcode_ra_operand_o = csr_opcode_ra_operand_o_int;
    assign csr_opcode_rb_operand_o = csr_opcode_rb_operand_o_int;
    assign csr_writeback_write_o = csr_writeback_write_o_int;
    assign csr_writeback_waddr_o = csr_writeback_waddr_o_int;
    assign csr_writeback_wdata_o = csr_writeback_wdata_o_int;
    assign csr_writeback_exception_o = csr_writeback_exception_o_int;
    assign csr_writeback_exception_pc_o = csr_writeback_exception_pc_o_int;
    assign csr_writeback_exception_addr_o = csr_writeback_exception_addr_o_int;
    assign exec0_hold_o = exec0_hold_o_int;
    assign exec1_hold_o = exec1_hold_o_int;
    assign mul_hold_o = mul_hold_o_int;
    assign interrupt_inhibit_o = interrupt_inhibit_o_int;
end
endgenerate


wire enable_dual_issue_w = SUPPORT_DUAL_ISSUE;
wire enable_muldiv_w     = SUPPORT_MULDIV;
wire enable_mul_bypass_w = SUPPORT_MUL_BYPASS;

wire stall_w;
wire squash_w;

//-------------------------------------------------------------
// PC
//-------------------------------------------------------------
wire        single_issue_w;
wire        dual_issue_w;
reg  [31:0] pc_x_q;
reg   [1:0] priv_x_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    pc_x_q <= 32'b0;
else if (branch_csr_request_i_int)
    pc_x_q <= branch_csr_pc_i_int;
else if (branch_d_exec1_request_i_int)
    pc_x_q <= branch_d_exec1_pc_i_int;
else if (branch_d_exec0_request_i_int)
    pc_x_q <= branch_d_exec0_pc_i_int;
else if (dual_issue_w)
    pc_x_q <= pc_x_q + 32'd8;
else if (single_issue_w)
    pc_x_q <= pc_x_q + 32'd4;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    priv_x_q <= `PRIV_MACHINE;
else if (branch_csr_request_i_int)
    priv_x_q <= branch_csr_priv_i_int;

//-------------------------------------------------------------
// Issue Select
//-------------------------------------------------------------
reg mispredicted_r;
reg slot0_valid_r;
reg slot1_valid_r;

always @ *
begin
    mispredicted_r = 1'b0;
    slot0_valid_r  = 1'b0;
    slot1_valid_r  = 1'b0;

    // Flush due to CSR branch
    if (branch_csr_request_i_int || squash_w)
    begin
        slot0_valid_r  = 1'b0;
        slot1_valid_r  = 1'b0;
    end
    // Word 0 valid and expected PC (word 1 may also be valid)
    else if (fetch0_valid_i_int && {fetch0_pc_i_int[31:2], 2'b0} == {pc_x_q[31:2], 2'b0})
        slot0_valid_r  = 1'b1;
    // Word 1 valid and expected PC
    else if (fetch1_valid_i_int && {fetch1_pc_i_int[31:2], 2'b0} == {pc_x_q[31:2], 2'b0})
        slot1_valid_r  = 1'b1;
    // Neither word is the expected PC - must be a branch misprediction
    else if (fetch0_valid_i_int || fetch1_valid_i_int)
        mispredicted_r = 1'b1;
end

// Branch request (CSR branch - ecall, xret, or branch misprediction)
// Note: Correctly predicted branches are silent
assign branch_request_o_int          = branch_csr_request_i_int | mispredicted_r;
assign branch_pc_o_int               = branch_csr_request_i_int ? branch_csr_pc_i_int : pc_x_q;
assign branch_priv_o_int             = branch_csr_request_i_int ? branch_csr_priv_i_int : priv_x_q;

//-------------------------------------------------------------
// Instruction Decoder
//-------------------------------------------------------------
reg        opcode_a_valid_r;
reg        opcode_b_valid_r;
reg [1:0]  opcode_a_fault_r;
reg [1:0]  opcode_b_fault_r;
reg [31:0] opcode_a_r;
reg [31:0] opcode_b_r;
reg [31:0] opcode_a_pc_r;
reg [31:0] opcode_b_pc_r;

always @ *
begin
    opcode_a_r       = 32'b0;
    opcode_b_r       = 32'b0;
    opcode_a_valid_r = 1'b0;
    opcode_b_valid_r = 1'b0;
    opcode_a_fault_r = 2'b0;
    opcode_b_fault_r = 2'b0;
    opcode_a_pc_r    = 32'b0;
    opcode_b_pc_r    = 32'b0;

    // Word 0 (and possibly slot 1) are valid instructions
    if (slot0_valid_r)
    begin
        opcode_a_valid_r = 1'b1;
        opcode_b_valid_r = fetch1_valid_i_int;
        opcode_a_r       = fetch0_instr_i_int;
        opcode_a_pc_r    = fetch0_pc_i_int;
        opcode_a_fault_r = {fetch0_fault_page_i_int, fetch0_fault_fetch_i_int};
        opcode_b_r       = fetch1_instr_i_int;
        opcode_b_pc_r    = fetch1_pc_i_int;
        opcode_b_fault_r = {fetch1_fault_page_i_int, fetch1_fault_fetch_i_int};
    end
    // Word 1 valid - mux to first issue slot
    // Note: Some instruction types can only issue in slot0, hence this muxing
    else if (slot1_valid_r)
    begin
        opcode_a_valid_r = 1'b1;
        opcode_b_valid_r = 1'b0;
        opcode_a_r       = fetch1_instr_i_int;
        opcode_a_pc_r    = fetch1_pc_i_int;
        opcode_a_fault_r = {fetch1_fault_page_i_int, fetch1_fault_fetch_i_int};
        opcode_b_r       = 32'b0;
        opcode_b_pc_r    = 32'b0;
        opcode_b_fault_r = 2'b0;
    end
end

wire [4:0] issue_a_ra_idx_w   = opcode_a_r[19:15];
wire [4:0] issue_a_rb_idx_w   = opcode_a_r[24:20];
wire [4:0] issue_a_rd_idx_w   = opcode_a_r[11:7];
wire       issue_a_sb_alloc_w = (slot0_valid_r ? fetch0_instr_rd_valid_i_int : fetch1_instr_rd_valid_i_int);
wire       issue_a_exec_w     = (slot0_valid_r ? fetch0_instr_exec_i_int     : fetch1_instr_exec_i_int);
wire       issue_a_lsu_w      = (slot0_valid_r ? fetch0_instr_lsu_i_int      : fetch1_instr_lsu_i_int);
wire       issue_a_branch_w   = (slot0_valid_r ? fetch0_instr_branch_i_int   : fetch1_instr_branch_i_int);
wire       issue_a_mul_w      = (slot0_valid_r ? fetch0_instr_mul_i_int      : fetch1_instr_mul_i_int);
wire       issue_a_div_w      = (slot0_valid_r ? fetch0_instr_div_i_int      : fetch1_instr_div_i_int);
wire       issue_a_csr_w      = (slot0_valid_r ? fetch0_instr_csr_i_int      : fetch1_instr_csr_i_int);
wire       issue_a_invalid_w  = (slot0_valid_r ? fetch0_instr_invalid_i_int  : fetch1_instr_invalid_i_int);


wire [4:0] issue_b_ra_idx_w   = opcode_b_r[19:15];
wire [4:0] issue_b_rb_idx_w   = opcode_b_r[24:20];
wire [4:0] issue_b_rd_idx_w   = opcode_b_r[11:7];
wire       issue_b_sb_alloc_w = fetch1_instr_rd_valid_i_int;
wire       issue_b_exec_w     = fetch1_instr_exec_i_int;
wire       issue_b_lsu_w      = fetch1_instr_lsu_i_int;
wire       issue_b_branch_w   = fetch1_instr_branch_i_int;
wire       issue_b_mul_w      = fetch1_instr_mul_i_int;
wire       issue_b_div_w      = fetch1_instr_div_i_int;
wire       issue_b_csr_w      = fetch1_instr_csr_i_int;
wire       issue_b_invalid_w  = fetch1_instr_invalid_i_int;

//-------------------------------------------------------------
// Pipe0 - Status tracking
//------------------------------------------------------------- 
wire        pipe0_squash_e1_e2_w;
wire        pipe1_squash_e1_e2_w;

reg         opcode_a_issue_r;
reg         opcode_a_accept_r;
wire        pipe0_stall_raw_w;

wire        pipe0_load_e1_w;
wire        pipe0_store_e1_w;
wire        pipe0_mul_e1_w;
wire        pipe0_branch_e1_w;
wire [4:0]  pipe0_rd_e1_w;

wire [31:0] pipe0_pc_e1_w;
wire [31:0] pipe0_opcode_e1_w;
wire [31:0] pipe0_operand_ra_e1_w;
wire [31:0] pipe0_operand_rb_e1_w;

wire        pipe0_load_e2_w;
wire        pipe0_mul_e2_w;
wire [4:0]  pipe0_rd_e2_w;
wire [31:0] pipe0_result_e2_w;

wire        pipe0_valid_wb_w;
wire        pipe0_csr_wb_w;
wire [4:0]  pipe0_rd_wb_w;
wire [31:0] pipe0_result_wb_w;
wire [31:0] pipe0_pc_wb_w;
wire [31:0] pipe0_opc_wb_w;
wire [31:0] pipe0_ra_val_wb_w;
wire [31:0] pipe0_rb_val_wb_w;
wire [`EXCEPTION_W-1:0] pipe0_exception_wb_w;

wire [`EXCEPTION_W-1:0] issue_a_fault_w = opcode_a_fault_r[0] ? `EXCEPTION_FAULT_FETCH:
                                          opcode_a_fault_r[1] ? `EXCEPTION_PAGE_FAULT_INST: `EXCEPTION_W'b0;

biriscv_pipe_ctrl
#( 
     .SUPPORT_LOAD_BYPASS(SUPPORT_LOAD_BYPASS)
    ,.SUPPORT_MUL_BYPASS(SUPPORT_MUL_BYPASS)
)
u_pipe0_ctrl
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)    

    // Issue
    ,.issue_valid_i(opcode_a_issue_r)
    ,.issue_accept_i(opcode_a_accept_r)
    ,.issue_stall_i(stall_w)
    ,.issue_lsu_i(issue_a_lsu_w)
    ,.issue_csr_i(issue_a_csr_w)
    ,.issue_div_i(issue_a_div_w)
    ,.issue_mul_i(issue_a_mul_w)
    ,.issue_branch_i(issue_a_branch_w)
    ,.issue_rd_valid_i(issue_a_sb_alloc_w)
    ,.issue_rd_i(issue_a_rd_idx_w)
    ,.issue_exception_i(issue_a_fault_w)
    ,.issue_pc_i(opcode0_pc_o_int)
    ,.issue_opcode_i(opcode0_opcode_o_int)
    ,.issue_operand_ra_i(opcode0_ra_operand_o_int)
    ,.issue_operand_rb_i(opcode0_rb_operand_o_int)
    ,.issue_branch_taken_i(branch_d_exec0_request_i_int)
    ,.issue_branch_target_i(branch_d_exec0_pc_i_int)
    ,.take_interrupt_i(take_interrupt_i_int)

    // Execution stage 1: ALU result
    ,.alu_result_e1_i(writeback_exec0_value_i_int)
    ,.csr_result_value_e1_i(csr_result_e1_value_i_int)
    ,.csr_result_write_e1_i(csr_result_e1_write_i_int)
    ,.csr_result_wdata_e1_i(csr_result_e1_wdata_i_int)
    ,.csr_result_exception_e1_i(csr_result_e1_exception_i_int)

    // Execution stage 1
    ,.load_e1_o(pipe0_load_e1_w)
    ,.store_e1_o(pipe0_store_e1_w)
    ,.mul_e1_o(pipe0_mul_e1_w)
    ,.branch_e1_o(pipe0_branch_e1_w)
    ,.rd_e1_o(pipe0_rd_e1_w)
    ,.pc_e1_o(pipe0_pc_e1_w)
    ,.opcode_e1_o(pipe0_opcode_e1_w)
    ,.operand_ra_e1_o(pipe0_operand_ra_e1_w)
    ,.operand_rb_e1_o(pipe0_operand_rb_e1_w)

    // Execution stage 2: Other results
    ,.mem_complete_i(writeback_mem_valid_i_int)
    ,.mem_result_e2_i(writeback_mem_value_i_int)
    ,.mem_exception_e2_i(writeback_mem_exception_i_int)
    ,.mul_result_e2_i(writeback_mul_value_i_int)

    // Execution stage 2
    ,.load_e2_o(pipe0_load_e2_w)
    ,.mul_e2_o(pipe0_mul_e2_w)
    ,.rd_e2_o(pipe0_rd_e2_w)
    ,.result_e2_o(pipe0_result_e2_w)

    ,.stall_o(pipe0_stall_raw_w)
    ,.squash_e1_e2_o(pipe0_squash_e1_e2_w)
    ,.squash_e1_e2_i(pipe1_squash_e1_e2_w)
    ,.squash_wb_i(1'b0)

    // Out of pipe: Divide Result
    ,.div_complete_i(writeback_div_valid_i_int)
    ,.div_result_i(writeback_div_value_i_int)

    // Commit
    ,.valid_wb_o(pipe0_valid_wb_w)
    ,.csr_wb_o(pipe0_csr_wb_w)
    ,.rd_wb_o(pipe0_rd_wb_w)
    ,.result_wb_o(pipe0_result_wb_w)
    ,.pc_wb_o(pipe0_pc_wb_w)
    ,.opcode_wb_o(pipe0_opc_wb_w)
    ,.operand_ra_wb_o(pipe0_ra_val_wb_w)
    ,.operand_rb_wb_o(pipe0_rb_val_wb_w)
    ,.exception_wb_o(pipe0_exception_wb_w)
    ,.csr_write_wb_o(csr_writeback_write_o_int)
    ,.csr_waddr_wb_o(csr_writeback_waddr_o_int)
    ,.csr_wdata_wb_o(csr_writeback_wdata_o_int)   
);

assign exec0_hold_o_int = stall_w;
assign mul_hold_o_int   = stall_w;

//-------------------------------------------------------------
// Pipe1 - Status tracking
//-------------------------------------------------------------
reg         opcode_b_issue_r;
reg         opcode_b_accept_r;
wire        pipe1_stall_raw_w;

wire        pipe1_load_e1_w;
wire        pipe1_store_e1_w;
wire        pipe1_mul_e1_w;
wire        pipe1_branch_e1_w;
wire [4:0]  pipe1_rd_e1_w;

wire [31:0] pipe1_pc_e1_w;
wire [31:0] pipe1_opcode_e1_w;
wire [31:0] pipe1_operand_ra_e1_w;
wire [31:0] pipe1_operand_rb_e1_w;

wire        pipe1_load_e2_w;
wire        pipe1_mul_e2_w;
wire [4:0]  pipe1_rd_e2_w;
wire [31:0] pipe1_result_e2_w;

wire        pipe1_valid_wb_w;
wire [4:0]  pipe1_rd_wb_w;
wire [31:0] pipe1_result_wb_w;
wire [31:0] pipe1_pc_wb_w;
wire [31:0] pipe1_opc_wb_w;
wire [31:0] pipe1_ra_val_wb_w;
wire [31:0] pipe1_rb_val_wb_w;
wire [`EXCEPTION_W-1:0] pipe1_exception_wb_w;

wire [`EXCEPTION_W-1:0] issue_b_fault_w = opcode_b_fault_r[0] ? `EXCEPTION_FAULT_FETCH:
                                          opcode_b_fault_r[1] ? `EXCEPTION_PAGE_FAULT_INST: `EXCEPTION_W'b0;

biriscv_pipe_ctrl
#( 
     .SUPPORT_LOAD_BYPASS(SUPPORT_LOAD_BYPASS)
    ,.SUPPORT_MUL_BYPASS(SUPPORT_MUL_BYPASS)
)
u_pipe1_ctrl
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    // Issue
    ,.issue_valid_i(opcode_b_issue_r)
    ,.issue_accept_i(opcode_b_accept_r)
    ,.issue_stall_i(stall_w)
    ,.issue_lsu_i(issue_b_lsu_w)
    ,.issue_csr_i(1'b0)
    ,.issue_div_i(1'b0)
    ,.issue_mul_i(issue_b_mul_w)
    ,.issue_branch_i(issue_b_branch_w)
    ,.issue_rd_valid_i(issue_b_sb_alloc_w)
    ,.issue_rd_i(issue_b_rd_idx_w)
    ,.issue_exception_i(issue_b_fault_w)
    ,.issue_pc_i(opcode1_pc_o_int)
    ,.issue_opcode_i(opcode1_opcode_o_int)
    ,.issue_operand_ra_i(opcode1_ra_operand_o_int)
    ,.issue_operand_rb_i(opcode1_rb_operand_o_int)
    ,.issue_branch_taken_i(branch_d_exec1_request_i_int)
    ,.issue_branch_target_i(branch_d_exec1_pc_i_int)
    ,.take_interrupt_i(take_interrupt_i_int)

    // Execution stage 1: ALU, CSR result
    ,.alu_result_e1_i(writeback_exec1_value_i_int)
    ,.csr_result_value_e1_i(csr_result_e1_value_i_int)
    ,.csr_result_write_e1_i(csr_result_e1_write_i_int)
    ,.csr_result_wdata_e1_i(csr_result_e1_wdata_i_int)
    ,.csr_result_exception_e1_i(csr_result_e1_exception_i_int)

    // Execution stage 1
    ,.load_e1_o(pipe1_load_e1_w)
    ,.store_e1_o(pipe1_store_e1_w)
    ,.mul_e1_o(pipe1_mul_e1_w)
    ,.branch_e1_o(pipe1_branch_e1_w)
    ,.rd_e1_o(pipe1_rd_e1_w)
    ,.pc_e1_o(pipe1_pc_e1_w)
    ,.opcode_e1_o(pipe1_opcode_e1_w)
    ,.operand_ra_e1_o(pipe1_operand_ra_e1_w)
    ,.operand_rb_e1_o(pipe1_operand_rb_e1_w)

    // Execution stage 2: Other results
    ,.mem_complete_i(writeback_mem_valid_i_int)
    ,.mem_result_e2_i(writeback_mem_value_i_int)
    ,.mem_exception_e2_i(writeback_mem_exception_i_int)
    ,.mul_result_e2_i(writeback_mul_value_i_int)

    // Execution stage 2
    ,.load_e2_o(pipe1_load_e2_w)
    ,.mul_e2_o(pipe1_mul_e2_w)
    ,.rd_e2_o(pipe1_rd_e2_w)
    ,.result_e2_o(pipe1_result_e2_w)

    ,.stall_o(pipe1_stall_raw_w)
    ,.squash_e1_e2_o(pipe1_squash_e1_e2_w)
    ,.squash_e1_e2_i(pipe0_squash_e1_e2_w)
    ,.squash_wb_i(pipe0_squash_e1_e2_w)

    // Out of pipe: Divide Result
    ,.div_complete_i(writeback_div_valid_i_int)
    ,.div_result_i(writeback_div_value_i_int)

    // Commit
    ,.valid_wb_o(pipe1_valid_wb_w)
    ,.csr_wb_o()
    ,.rd_wb_o(pipe1_rd_wb_w)
    ,.result_wb_o(pipe1_result_wb_w)
    ,.pc_wb_o(pipe1_pc_wb_w)
    ,.opcode_wb_o(pipe1_opc_wb_w)
    ,.operand_ra_wb_o(pipe1_ra_val_wb_w)
    ,.operand_rb_wb_o(pipe1_rb_val_wb_w)
    ,.exception_wb_o(pipe1_exception_wb_w)
    ,.csr_write_wb_o()
    ,.csr_waddr_wb_o()
    ,.csr_wdata_wb_o()
);

assign exec1_hold_o_int = stall_w;

assign csr_writeback_exception_o_int      = pipe0_exception_wb_w | pipe1_exception_wb_w;
assign csr_writeback_exception_pc_o_int   = (|pipe0_exception_wb_w) ? pipe0_pc_wb_w     : pipe1_pc_wb_w;
assign csr_writeback_exception_addr_o_int = (|pipe0_exception_wb_w) ? pipe0_result_wb_w : pipe1_result_wb_w;

//-------------------------------------------------------------
// Branch predictor info
//-------------------------------------------------------------
// This info is used to learn future prediction, and to correct 
// BTB, BHT, GShare, RAS indexes on mispredictions.
assign branch_info_request_o_int      = mispredicted_r;
assign branch_info_is_taken_o_int     = (pipe1_branch_e1_w & branch_exec1_is_taken_i_int)     | (pipe0_branch_e1_w & branch_exec0_is_taken_i_int);
assign branch_info_is_not_taken_o_int = (pipe1_branch_e1_w & branch_exec1_is_not_taken_i_int) | (pipe0_branch_e1_w & branch_exec0_is_not_taken_i_int);
assign branch_info_is_call_o_int      = (pipe1_branch_e1_w & branch_exec1_is_call_i_int)      | (pipe0_branch_e1_w & branch_exec0_is_call_i_int);
assign branch_info_is_ret_o_int       = (pipe1_branch_e1_w & branch_exec1_is_ret_i_int)       | (pipe0_branch_e1_w & branch_exec0_is_ret_i_int);
assign branch_info_is_jmp_o_int       = (pipe1_branch_e1_w & branch_exec1_is_jmp_i_int)       | (pipe0_branch_e1_w & branch_exec0_is_jmp_i_int);
assign branch_info_source_o_int       = (pipe1_branch_e1_w & branch_exec1_request_i_int)      ? branch_exec1_source_i_int : branch_exec0_source_i_int;
assign branch_info_pc_o_int           = (pipe1_branch_e1_w & branch_exec1_request_i_int)      ? branch_exec1_pc_i_int     : branch_exec0_pc_i_int;

//-------------------------------------------------------------
// Blocking events (division, CSR unit access)
//-------------------------------------------------------------
reg div_pending_q;
reg csr_pending_q;

// Division operations take 2 - 34 cycles and stall
// the pipeline (complete out-of-pipe) until completed.
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    div_pending_q <= 1'b0;
else if (pipe0_squash_e1_e2_w || pipe1_squash_e1_e2_w)
    div_pending_q <= 1'b0;
else if (div_opcode_valid_o_int && issue_a_div_w)
    div_pending_q <= 1'b1;
else if (writeback_div_valid_i_int)
    div_pending_q <= 1'b0;

// CSR operations are infrequent - avoid any complications of pipelining them.
// These only take a 2-3 cycles anyway and may result in a pipe flush (e.g. ecall, ebreak..).
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    csr_pending_q <= 1'b0;
else if (pipe0_squash_e1_e2_w || pipe1_squash_e1_e2_w)
    csr_pending_q <= 1'b0;
else if (csr_opcode_valid_o_int && issue_a_csr_w)
    csr_pending_q <= 1'b1;
else if (pipe0_csr_wb_w)
    csr_pending_q <= 1'b0;

assign squash_w = pipe0_squash_e1_e2_w || pipe1_squash_e1_e2_w;

//-------------------------------------------------------------
// Issue / scheduling logic
//-------------------------------------------------------------
reg [31:0] scoreboard_r;
reg        pipe1_mux_lsu_r;
reg        pipe1_mux_mul_r;

// Check instructions can be issued in the second execution unit
wire pipe1_ok_w      = issue_b_exec_w | issue_b_branch_w | issue_b_lsu_w | issue_b_mul_w;

// Is this combination of instructions possible to execute concurrently.
// This excludes result dependencies which may also block secondary execution.
wire dual_issue_ok_w =   enable_dual_issue_w &&  // Second pipe switched on
                         pipe1_ok_w &&           // Instruction 2 is possible on second exec unit
                        (((issue_a_exec_w | issue_a_lsu_w | issue_a_mul_w) && issue_b_exec_w)   ||
                         ((issue_a_exec_w | issue_a_lsu_w | issue_a_mul_w) && issue_b_branch_w) ||
                         ((issue_a_exec_w | issue_a_mul_w) && issue_b_lsu_w)                    ||
                         ((issue_a_exec_w | issue_a_lsu_w) && issue_b_mul_w)
                         ) && ~take_interrupt_i_int;

always @ *
begin
    opcode_a_issue_r     = 1'b0;
    opcode_b_issue_r     = 1'b0;
    opcode_a_accept_r    = 1'b0;
    opcode_b_accept_r    = 1'b0;
    scoreboard_r         = 32'b0;
    pipe1_mux_lsu_r      = 1'b0;
    pipe1_mux_mul_r      = 1'b0;

    // Execution units with >= 2 cycle latency
    if (SUPPORT_LOAD_BYPASS == 0)
    begin
        if (pipe0_load_e2_w)
            scoreboard_r[pipe0_rd_e2_w] = 1'b1;
        if (pipe1_load_e2_w)
            scoreboard_r[pipe1_rd_e2_w] = 1'b1;
    end
    if (SUPPORT_MUL_BYPASS == 0)
    begin
        if (pipe0_mul_e2_w)
            scoreboard_r[pipe0_rd_e2_w] = 1'b1;
        if (pipe1_mul_e2_w)
            scoreboard_r[pipe1_rd_e2_w] = 1'b1;
    end

    // Execution units with >= 1 cycle latency (loads / multiply)
    if (pipe0_load_e1_w || pipe0_mul_e1_w)
        scoreboard_r[pipe0_rd_e1_w] = 1'b1;
    if (pipe1_load_e1_w || pipe1_mul_e1_w)
        scoreboard_r[pipe1_rd_e1_w] = 1'b1;

    // Do not start multiply, division or CSR operation in the cycle after a load (leaving only ALU operations and branches)
    if ((pipe0_load_e1_w || pipe0_store_e1_w || pipe1_load_e1_w || pipe1_store_e1_w ) && (issue_a_mul_w || issue_a_div_w || issue_a_csr_w))
        scoreboard_r = 32'hFFFFFFFF;

    // Stall - no issues...
    if (lsu_stall_i_int || stall_w || div_pending_q || csr_pending_q)
        ;
    // Primary slot (lsu, branch, alu, mul, div, csr)
    else if (opcode_a_valid_r &&
        !(scoreboard_r[issue_a_ra_idx_w] || 
          scoreboard_r[issue_a_rb_idx_w] ||
          scoreboard_r[issue_a_rd_idx_w]))
    begin
        opcode_a_issue_r  = 1'b1;
        opcode_a_accept_r = 1'b1;

        if (opcode_a_accept_r && issue_a_sb_alloc_w && (|issue_a_rd_idx_w))
            scoreboard_r[issue_a_rd_idx_w] = 1'b1;
    end

    // Stall - no issues...
    if (lsu_stall_i_int || stall_w || div_pending_q || csr_pending_q)
        ;
    // Secondary Slot (lsu, branch, alu, mul)
    else if (dual_issue_ok_w && opcode_b_valid_r && opcode_a_accept_r &&
        !(scoreboard_r[issue_b_ra_idx_w] || 
          scoreboard_r[issue_b_rb_idx_w] ||
          scoreboard_r[issue_b_rd_idx_w]))
    begin
        opcode_b_issue_r  = 1'b1;
        opcode_b_accept_r = 1'b1;
        pipe1_mux_lsu_r   = issue_b_lsu_w;
        pipe1_mux_mul_r   = issue_b_mul_w;

        if (opcode_b_accept_r && issue_b_sb_alloc_w && (|issue_b_rd_idx_w))
            scoreboard_r[issue_b_rd_idx_w] = 1'b1;
    end    
end

assign lsu_opcode_valid_o_int   = (pipe1_mux_lsu_r ? opcode_b_issue_r : opcode_a_issue_r) & ~take_interrupt_i_int;
assign exec0_opcode_valid_o_int = opcode_a_issue_r;
assign mul_opcode_valid_o_int   = enable_muldiv_w & (pipe1_mux_mul_r ? opcode_b_issue_r : opcode_a_issue_r);
assign div_opcode_valid_o_int   = enable_muldiv_w & (opcode_a_issue_r);
assign interrupt_inhibit_o_int  = csr_pending_q || issue_a_csr_w;

assign exec1_opcode_valid_o_int = opcode_b_issue_r;

assign dual_issue_w         = opcode_b_issue_r & opcode_b_accept_r & ~take_interrupt_i_int;
assign single_issue_w       = (opcode_a_issue_r & opcode_a_accept_r) & ~dual_issue_w & ~take_interrupt_i_int;

assign fetch0_accept_o_int      = ((slot0_valid_r & opcode_a_accept_r) | slot1_valid_r) & ~take_interrupt_i_int;
assign fetch1_accept_o_int      = ((slot1_valid_r & opcode_a_accept_r) | (opcode_b_accept_r)) & ~take_interrupt_i_int;

assign stall_w              = pipe0_stall_raw_w | pipe1_stall_raw_w;

//-------------------------------------------------------------
// Register File
//------------------------------------------------------------- 
wire [31:0] issue_a_ra_value_w;
wire [31:0] issue_a_rb_value_w;
wire [31:0] issue_b_ra_value_w;
wire [31:0] issue_b_rb_value_w;

// Register file: 2W4R
biriscv_regfile
#(
     .SUPPORT_REGFILE_XILINX(SUPPORT_REGFILE_XILINX)
    ,.SUPPORT_DUAL_ISSUE(SUPPORT_DUAL_ISSUE)
)
u_regfile
(
    .clk_i(clk_i),
    .rst_i(rst_i),

    // Write ports
    .rd0_i(pipe0_rd_wb_w),
    .rd0_value_i(pipe0_result_wb_w),
    .rd1_i(pipe1_rd_wb_w),
    .rd1_value_i(pipe1_result_wb_w),

    // Read ports
    .ra0_i(issue_a_ra_idx_w),
    .rb0_i(issue_a_rb_idx_w),
    .ra0_value_o(issue_a_ra_value_w),
    .rb0_value_o(issue_a_rb_value_w),

    .ra1_i(issue_b_ra_idx_w),
    .rb1_i(issue_b_rb_idx_w),
    .ra1_value_o(issue_b_ra_value_w),
    .rb1_value_o(issue_b_rb_value_w)    
);

//-------------------------------------------------------------
// Issue Slot 0
//------------------------------------------------------------- 
assign opcode0_opcode_o_int = opcode_a_r;
assign opcode0_pc_o_int     = opcode_a_pc_r;
assign opcode0_rd_idx_o_int = issue_a_rd_idx_w;
assign opcode0_ra_idx_o_int = issue_a_ra_idx_w;
assign opcode0_rb_idx_o_int = issue_a_rb_idx_w;
assign opcode0_invalid_o_int= 1'b0; 

reg [31:0] issue_a_ra_value_r;
reg [31:0] issue_a_rb_value_r;

always @ *
begin
    // NOTE: Newest version of operand takes priority
    issue_a_ra_value_r = issue_a_ra_value_w;
    issue_a_rb_value_r = issue_a_rb_value_w;

    // Bypass - WB
    if (pipe0_rd_wb_w == issue_a_ra_idx_w)
        issue_a_ra_value_r = pipe0_result_wb_w;
    if (pipe0_rd_wb_w == issue_a_rb_idx_w)
        issue_a_rb_value_r = pipe0_result_wb_w;

    if (pipe1_rd_wb_w == issue_a_ra_idx_w)
        issue_a_ra_value_r = pipe1_result_wb_w;
    if (pipe1_rd_wb_w == issue_a_rb_idx_w)
        issue_a_rb_value_r = pipe1_result_wb_w;

    // Bypass - E2
    if (pipe0_rd_e2_w == issue_a_ra_idx_w)
        issue_a_ra_value_r = pipe0_result_e2_w;
    if (pipe0_rd_e2_w == issue_a_rb_idx_w)
        issue_a_rb_value_r = pipe0_result_e2_w;

    if (pipe1_rd_e2_w == issue_a_ra_idx_w)
        issue_a_ra_value_r = pipe1_result_e2_w;
    if (pipe1_rd_e2_w == issue_a_rb_idx_w)
        issue_a_rb_value_r = pipe1_result_e2_w;

    // Bypass - E1
    if (pipe0_rd_e1_w == issue_a_ra_idx_w)
        issue_a_ra_value_r = writeback_exec0_value_i_int;
    if (pipe0_rd_e1_w == issue_a_rb_idx_w)
        issue_a_rb_value_r = writeback_exec0_value_i_int;

    if (pipe1_rd_e1_w == issue_a_ra_idx_w)
        issue_a_ra_value_r = writeback_exec1_value_i_int;
    if (pipe1_rd_e1_w == issue_a_rb_idx_w)
        issue_a_rb_value_r = writeback_exec1_value_i_int;

    // Reg 0 source
    if (issue_a_ra_idx_w == 5'b0)
        issue_a_ra_value_r = 32'b0;
    if (issue_a_rb_idx_w == 5'b0)
        issue_a_rb_value_r = 32'b0;
end

assign opcode0_ra_operand_o_int = issue_a_ra_value_r;
assign opcode0_rb_operand_o_int = issue_a_rb_value_r;

//-------------------------------------------------------------
// Issue Slot 1
//------------------------------------------------------------- 
assign opcode1_opcode_o_int = opcode_b_r;
assign opcode1_pc_o_int     = opcode_b_pc_r;
assign opcode1_rd_idx_o_int = issue_b_rd_idx_w;
assign opcode1_ra_idx_o_int = issue_b_ra_idx_w;
assign opcode1_rb_idx_o_int = issue_b_rb_idx_w;
assign opcode1_invalid_o_int= 1'b0;

reg [31:0] issue_b_ra_value_r;
reg [31:0] issue_b_rb_value_r;

always @ *
begin
    // NOTE: Newest version of operand takes priority
    issue_b_ra_value_r = issue_b_ra_value_w;
    issue_b_rb_value_r = issue_b_rb_value_w;

    // Bypass - WB
    if (pipe0_rd_wb_w == issue_b_ra_idx_w)
        issue_b_ra_value_r = pipe0_result_wb_w;
    if (pipe0_rd_wb_w == issue_b_rb_idx_w)
        issue_b_rb_value_r = pipe0_result_wb_w;

    if (pipe1_rd_wb_w == issue_b_ra_idx_w)
        issue_b_ra_value_r = pipe1_result_wb_w;
    if (pipe1_rd_wb_w == issue_b_rb_idx_w)
        issue_b_rb_value_r = pipe1_result_wb_w;

    // Bypass - E2
    if (pipe0_rd_e2_w == issue_b_ra_idx_w)
        issue_b_ra_value_r = pipe0_result_e2_w;
    if (pipe0_rd_e2_w == issue_b_rb_idx_w)
        issue_b_rb_value_r = pipe0_result_e2_w;

    if (pipe1_rd_e2_w == issue_b_ra_idx_w)
        issue_b_ra_value_r = pipe1_result_e2_w;
    if (pipe1_rd_e2_w == issue_b_rb_idx_w)
        issue_b_rb_value_r = pipe1_result_e2_w;

    // Bypass - E1
    if (pipe0_rd_e1_w == issue_b_ra_idx_w)
        issue_b_ra_value_r = writeback_exec0_value_i_int;
    if (pipe0_rd_e1_w == issue_b_rb_idx_w)
        issue_b_rb_value_r = writeback_exec0_value_i_int;

    if (pipe1_rd_e1_w == issue_b_ra_idx_w)
        issue_b_ra_value_r = writeback_exec1_value_i_int;
    if (pipe1_rd_e1_w == issue_b_rb_idx_w)
        issue_b_rb_value_r = writeback_exec1_value_i_int;

    // Reg 0 source
    if (issue_b_ra_idx_w == 5'b0)
        issue_b_ra_value_r = 32'b0;
    if (issue_b_rb_idx_w == 5'b0)
        issue_b_rb_value_r = 32'b0;
end

assign opcode1_ra_operand_o_int = issue_b_ra_value_r;
assign opcode1_rb_operand_o_int = issue_b_rb_value_r;

//-------------------------------------------------------------
// Load store unit
//-------------------------------------------------------------
assign lsu_opcode_opcode_o_int      = pipe1_mux_lsu_r ? opcode1_opcode_o_int     : opcode0_opcode_o_int;
assign lsu_opcode_pc_o_int          = pipe1_mux_lsu_r ? opcode1_pc_o_int         : opcode0_pc_o_int;
assign lsu_opcode_rd_idx_o_int      = pipe1_mux_lsu_r ? opcode1_rd_idx_o_int     : opcode0_rd_idx_o_int;
assign lsu_opcode_ra_idx_o_int      = pipe1_mux_lsu_r ? opcode1_ra_idx_o_int     : opcode0_ra_idx_o_int;
assign lsu_opcode_rb_idx_o_int      = pipe1_mux_lsu_r ? opcode1_rb_idx_o_int     : opcode0_rb_idx_o_int;
assign lsu_opcode_ra_operand_o_int  = pipe1_mux_lsu_r ? opcode1_ra_operand_o_int : opcode0_ra_operand_o_int;
assign lsu_opcode_rb_operand_o_int  = pipe1_mux_lsu_r ? opcode1_rb_operand_o_int : opcode0_rb_operand_o_int;
assign lsu_opcode_invalid_o_int     = 1'b0;

//-------------------------------------------------------------
// Multiply
//-------------------------------------------------------------
assign mul_opcode_opcode_o_int      = pipe1_mux_mul_r ? opcode1_opcode_o_int     : opcode0_opcode_o_int;
assign mul_opcode_pc_o_int          = pipe1_mux_mul_r ? opcode1_pc_o_int         : opcode0_pc_o_int;
assign mul_opcode_rd_idx_o_int      = pipe1_mux_mul_r ? opcode1_rd_idx_o_int     : opcode0_rd_idx_o_int;
assign mul_opcode_ra_idx_o_int      = pipe1_mux_mul_r ? opcode1_ra_idx_o_int     : opcode0_ra_idx_o_int;
assign mul_opcode_rb_idx_o_int      = pipe1_mux_mul_r ? opcode1_rb_idx_o_int     : opcode0_rb_idx_o_int;
assign mul_opcode_ra_operand_o_int  = pipe1_mux_mul_r ? opcode1_ra_operand_o_int : opcode0_ra_operand_o_int;
assign mul_opcode_rb_operand_o_int  = pipe1_mux_mul_r ? opcode1_rb_operand_o_int : opcode0_rb_operand_o_int;
assign mul_opcode_invalid_o_int     = 1'b0;

//-------------------------------------------------------------
// CSR unit
//-------------------------------------------------------------
assign csr_opcode_valid_o_int       = opcode_a_issue_r & ~take_interrupt_i_int;
assign csr_opcode_opcode_o_int      = opcode0_opcode_o_int;
assign csr_opcode_pc_o_int          = opcode0_pc_o_int;
assign csr_opcode_rd_idx_o_int      = opcode0_rd_idx_o_int;
assign csr_opcode_ra_idx_o_int      = opcode0_ra_idx_o_int;
assign csr_opcode_rb_idx_o_int      = opcode0_rb_idx_o_int;
assign csr_opcode_ra_operand_o_int  = opcode0_ra_operand_o_int;
assign csr_opcode_rb_operand_o_int  = opcode0_rb_operand_o_int;
assign csr_opcode_invalid_o_int     = opcode_a_issue_r && issue_a_invalid_w;

//-------------------------------------------------------------
// Checker Interface
//-------------------------------------------------------------
`ifdef verilator
biriscv_trace_sim
u_pipe0_dec0_verif
(
     .valid_i(pipe0_valid_wb_w)
    ,.pc_i(pipe0_pc_wb_w)
    ,.opcode_i(pipe0_opc_wb_w)
);

wire [4:0] v_pipe0_rs1_w = pipe0_opc_wb_w[19:15];
wire [4:0] v_pipe0_rs2_w = pipe0_opc_wb_w[24:20];

function [0:0] complete_valid0; /*verilator public*/
begin
    complete_valid0 = pipe0_valid_wb_w;
end
endfunction
function [31:0] complete_pc0; /*verilator public*/
begin
    complete_pc0 = pipe0_pc_wb_w;
end
endfunction
function [31:0] complete_opcode0; /*verilator public*/
begin
    complete_opcode0 = pipe0_opc_wb_w;
end
endfunction
function [4:0] complete_ra0; /*verilator public*/
begin
    complete_ra0 = v_pipe0_rs1_w;
end
endfunction
function [4:0] complete_rb0; /*verilator public*/
begin
    complete_rb0 = v_pipe0_rs2_w;
end
endfunction
function [4:0] complete_rd0; /*verilator public*/
begin
    complete_rd0 = pipe0_rd_wb_w;
end
endfunction
function [31:0] complete_ra_val0; /*verilator public*/
begin
    complete_ra_val0 = pipe0_ra_val_wb_w;
end
endfunction
function [31:0] complete_rb_val0; /*verilator public*/
begin
    complete_rb_val0 = pipe0_rb_val_wb_w;
end
endfunction
function [31:0] complete_rd_val0; /*verilator public*/
begin
    if (|pipe0_rd_wb_w)
        complete_rd_val0 = pipe0_result_wb_w;
    else
        complete_rd_val0 = 32'b0;
end
endfunction

biriscv_trace_sim
u_pipe0_dec1_verif
(
     .valid_i(pipe1_valid_wb_w)
    ,.pc_i(pipe1_pc_wb_w)
    ,.opcode_i(pipe1_opc_wb_w)
);

wire [4:0] v_pipe1_rs1_w = pipe1_opc_wb_w[19:15];
wire [4:0] v_pipe1_rs2_w = pipe1_opc_wb_w[24:20];

function [0:0] complete_valid1; /*verilator public*/
begin
    complete_valid1 = pipe1_valid_wb_w;
end
endfunction
function [31:0] complete_pc1; /*verilator public*/
begin
    complete_pc1 = pipe1_pc_wb_w;
end
endfunction
function [31:0] complete_opcode1; /*verilator public*/
begin
    complete_opcode1 = pipe1_opc_wb_w;
end
endfunction
function [4:0] complete_ra1; /*verilator public*/
begin
    complete_ra1 = v_pipe1_rs1_w;
end
endfunction
function [4:0] complete_rb1; /*verilator public*/
begin
    complete_rb1 = v_pipe1_rs2_w;
end
endfunction
function [4:0] complete_rd1; /*verilator public*/
begin
    complete_rd1 = pipe1_rd_wb_w;
end
endfunction
function [31:0] complete_ra_val1; /*verilator public*/
begin
    complete_ra_val1 = pipe1_ra_val_wb_w;
end
endfunction
function [31:0] complete_rb_val1; /*verilator public*/
begin
    complete_rb_val1 = pipe1_rb_val_wb_w;
end
endfunction
function [31:0] complete_rd_val1; /*verilator public*/
begin
    if (|pipe1_rd_wb_w)
        complete_rd_val1 = pipe1_result_wb_w;
    else
        complete_rd_val1 = 32'b0;
end
endfunction
function [5:0] complete_exception; /*verilator public*/
begin
    complete_exception = pipe0_exception_wb_w | pipe1_exception_wb_w;
end
endfunction
`endif


endmodule
