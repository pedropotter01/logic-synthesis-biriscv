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
module biriscv_pipe_ctrl
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SUPPORT_LOAD_BYPASS = 1
    ,parameter SUPPORT_MUL_BYPASS  = 1
    ,parameter SYNTH_MODE_ISO = 0 // 1: register all I/Os (standalone synthesis only)
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
     input           clk_i
    ,input           rst_i

    // Issue
    ,input           issue_valid_i
    ,input           issue_accept_i
    ,input           issue_stall_i
    ,input           issue_lsu_i
    ,input           issue_csr_i
    ,input           issue_div_i
    ,input           issue_mul_i
    ,input           issue_branch_i
    ,input           issue_rd_valid_i
    ,input  [4:0]    issue_rd_i
    ,input  [5:0]    issue_exception_i
    ,input           take_interrupt_i
    ,input           issue_branch_taken_i
    ,input [31:0]    issue_branch_target_i
    ,input [31:0]    issue_pc_i
    ,input [31:0]    issue_opcode_i
    ,input [31:0]    issue_operand_ra_i
    ,input [31:0]    issue_operand_rb_i

    // Execution stage 1: ALU result
    ,input [31:0]    alu_result_e1_i

    // Execution stage 1: CSR read result / early exceptions
    ,input [ 31:0]   csr_result_value_e1_i
    ,input           csr_result_write_e1_i
    ,input [ 31:0]   csr_result_wdata_e1_i
    ,input [  5:0]   csr_result_exception_e1_i

    // Execution stage 1
    ,output          load_e1_o
    ,output          store_e1_o
    ,output          mul_e1_o
    ,output          branch_e1_o
    ,output [  4:0]  rd_e1_o
    ,output [31:0]   pc_e1_o
    ,output [31:0]   opcode_e1_o
    ,output [31:0]   operand_ra_e1_o
    ,output [31:0]   operand_rb_e1_o

    // Execution stage 2: Other results
    ,input           mem_complete_i
    ,input [31:0]    mem_result_e2_i
    ,input  [5:0]    mem_exception_e2_i
    ,input [31:0]    mul_result_e2_i

    // Execution stage 2
    ,output          load_e2_o
    ,output          mul_e2_o
    ,output [  4:0]  rd_e2_o
    ,output [31:0]   result_e2_o

    // Out of pipe: Divide Result
    ,input           div_complete_i
    ,input  [31:0]   div_result_i

    // Commit
    ,output          valid_wb_o
    ,output          csr_wb_o
    ,output [  4:0]  rd_wb_o
    ,output [31:0]   result_wb_o
    ,output [31:0]   pc_wb_o
    ,output [31:0]   opcode_wb_o
    ,output [31:0]   operand_ra_wb_o
    ,output [31:0]   operand_rb_wb_o
    ,output [5:0]    exception_wb_o
    ,output          csr_write_wb_o
    ,output [11:0]   csr_waddr_wb_o
    ,output [31:0]   csr_wdata_wb_o

    ,output          stall_o
    ,output          squash_e1_e2_o
    ,input           squash_e1_e2_i
    ,input           squash_wb_i
);

//-------------------------------------------------------------
// Includes
//-------------------------------------------------------------
`include "biriscv_defs.v"

//-----------------------------------------------------------------
// SYNTH_MODE_ISO: isolation register walls
//   SYNTH_MODE_ISO = 0 -> ports connected straight through (normal)
//   SYNTH_MODE_ISO = 1 -> every input and output (except clock/reset)
//                         is registered, so this module can be
//                         synthesized and timed standalone.
//-----------------------------------------------------------------
// Internal (module side) view of the ports
wire                  issue_valid_i_int;
wire                  issue_accept_i_int;
wire                  issue_stall_i_int;
wire                  issue_lsu_i_int;
wire                  issue_csr_i_int;
wire                  issue_div_i_int;
wire                  issue_mul_i_int;
wire                  issue_branch_i_int;
wire                  issue_rd_valid_i_int;
wire [4:0]            issue_rd_i_int;
wire [5:0]            issue_exception_i_int;
wire                  take_interrupt_i_int;
wire                  issue_branch_taken_i_int;
wire [31:0]           issue_branch_target_i_int;
wire [31:0]           issue_pc_i_int;
wire [31:0]           issue_opcode_i_int;
wire [31:0]           issue_operand_ra_i_int;
wire [31:0]           issue_operand_rb_i_int;
wire [31:0]           alu_result_e1_i_int;
wire [ 31:0]          csr_result_value_e1_i_int;
wire                  csr_result_write_e1_i_int;
wire [ 31:0]          csr_result_wdata_e1_i_int;
wire [  5:0]          csr_result_exception_e1_i_int;
wire                  load_e1_o_int;
wire                  store_e1_o_int;
wire                  mul_e1_o_int;
wire                  branch_e1_o_int;
wire [  4:0]          rd_e1_o_int;
wire [31:0]           pc_e1_o_int;
wire [31:0]           opcode_e1_o_int;
wire [31:0]           operand_ra_e1_o_int;
wire [31:0]           operand_rb_e1_o_int;
wire                  mem_complete_i_int;
wire [31:0]           mem_result_e2_i_int;
wire [5:0]            mem_exception_e2_i_int;
wire [31:0]           mul_result_e2_i_int;
wire                  load_e2_o_int;
wire                  mul_e2_o_int;
wire [  4:0]          rd_e2_o_int;
wire [31:0]           result_e2_o_int;
wire                  div_complete_i_int;
wire [31:0]           div_result_i_int;
wire                  valid_wb_o_int;
wire                  csr_wb_o_int;
wire [  4:0]          rd_wb_o_int;
wire [31:0]           result_wb_o_int;
wire [31:0]           pc_wb_o_int;
wire [31:0]           opcode_wb_o_int;
wire [31:0]           operand_ra_wb_o_int;
wire [31:0]           operand_rb_wb_o_int;
wire [5:0]            exception_wb_o_int;
wire                  csr_write_wb_o_int;
wire [11:0]           csr_waddr_wb_o_int;
wire [31:0]           csr_wdata_wb_o_int;
wire                  stall_o_int;
wire                  squash_e1_e2_o_int;
wire                  squash_e1_e2_i_int;
wire                  squash_wb_i_int;

generate
if (SYNTH_MODE_ISO)
begin : g_synth_iso
    // Input register wall
    reg                   issue_valid_i_iso_q;
    reg                   issue_accept_i_iso_q;
    reg                   issue_stall_i_iso_q;
    reg                   issue_lsu_i_iso_q;
    reg                   issue_csr_i_iso_q;
    reg                   issue_div_i_iso_q;
    reg                   issue_mul_i_iso_q;
    reg                   issue_branch_i_iso_q;
    reg                   issue_rd_valid_i_iso_q;
    reg  [4:0]            issue_rd_i_iso_q;
    reg  [5:0]            issue_exception_i_iso_q;
    reg                   take_interrupt_i_iso_q;
    reg                   issue_branch_taken_i_iso_q;
    reg  [31:0]           issue_branch_target_i_iso_q;
    reg  [31:0]           issue_pc_i_iso_q;
    reg  [31:0]           issue_opcode_i_iso_q;
    reg  [31:0]           issue_operand_ra_i_iso_q;
    reg  [31:0]           issue_operand_rb_i_iso_q;
    reg  [31:0]           alu_result_e1_i_iso_q;
    reg  [ 31:0]          csr_result_value_e1_i_iso_q;
    reg                   csr_result_write_e1_i_iso_q;
    reg  [ 31:0]          csr_result_wdata_e1_i_iso_q;
    reg  [  5:0]          csr_result_exception_e1_i_iso_q;
    reg                   mem_complete_i_iso_q;
    reg  [31:0]           mem_result_e2_i_iso_q;
    reg  [5:0]            mem_exception_e2_i_iso_q;
    reg  [31:0]           mul_result_e2_i_iso_q;
    reg                   div_complete_i_iso_q;
    reg  [31:0]           div_result_i_iso_q;
    reg                   squash_e1_e2_i_iso_q;
    reg                   squash_wb_i_iso_q;

    always @ (posedge clk_i)
    begin
        issue_valid_i_iso_q <= issue_valid_i;
        issue_accept_i_iso_q <= issue_accept_i;
        issue_stall_i_iso_q <= issue_stall_i;
        issue_lsu_i_iso_q <= issue_lsu_i;
        issue_csr_i_iso_q <= issue_csr_i;
        issue_div_i_iso_q <= issue_div_i;
        issue_mul_i_iso_q <= issue_mul_i;
        issue_branch_i_iso_q <= issue_branch_i;
        issue_rd_valid_i_iso_q <= issue_rd_valid_i;
        issue_rd_i_iso_q <= issue_rd_i;
        issue_exception_i_iso_q <= issue_exception_i;
        take_interrupt_i_iso_q <= take_interrupt_i;
        issue_branch_taken_i_iso_q <= issue_branch_taken_i;
        issue_branch_target_i_iso_q <= issue_branch_target_i;
        issue_pc_i_iso_q <= issue_pc_i;
        issue_opcode_i_iso_q <= issue_opcode_i;
        issue_operand_ra_i_iso_q <= issue_operand_ra_i;
        issue_operand_rb_i_iso_q <= issue_operand_rb_i;
        alu_result_e1_i_iso_q <= alu_result_e1_i;
        csr_result_value_e1_i_iso_q <= csr_result_value_e1_i;
        csr_result_write_e1_i_iso_q <= csr_result_write_e1_i;
        csr_result_wdata_e1_i_iso_q <= csr_result_wdata_e1_i;
        csr_result_exception_e1_i_iso_q <= csr_result_exception_e1_i;
        mem_complete_i_iso_q <= mem_complete_i;
        mem_result_e2_i_iso_q <= mem_result_e2_i;
        mem_exception_e2_i_iso_q <= mem_exception_e2_i;
        mul_result_e2_i_iso_q <= mul_result_e2_i;
        div_complete_i_iso_q <= div_complete_i;
        div_result_i_iso_q <= div_result_i;
        squash_e1_e2_i_iso_q <= squash_e1_e2_i;
        squash_wb_i_iso_q <= squash_wb_i;
    end

    assign issue_valid_i_int = issue_valid_i_iso_q;
    assign issue_accept_i_int = issue_accept_i_iso_q;
    assign issue_stall_i_int = issue_stall_i_iso_q;
    assign issue_lsu_i_int = issue_lsu_i_iso_q;
    assign issue_csr_i_int = issue_csr_i_iso_q;
    assign issue_div_i_int = issue_div_i_iso_q;
    assign issue_mul_i_int = issue_mul_i_iso_q;
    assign issue_branch_i_int = issue_branch_i_iso_q;
    assign issue_rd_valid_i_int = issue_rd_valid_i_iso_q;
    assign issue_rd_i_int = issue_rd_i_iso_q;
    assign issue_exception_i_int = issue_exception_i_iso_q;
    assign take_interrupt_i_int = take_interrupt_i_iso_q;
    assign issue_branch_taken_i_int = issue_branch_taken_i_iso_q;
    assign issue_branch_target_i_int = issue_branch_target_i_iso_q;
    assign issue_pc_i_int = issue_pc_i_iso_q;
    assign issue_opcode_i_int = issue_opcode_i_iso_q;
    assign issue_operand_ra_i_int = issue_operand_ra_i_iso_q;
    assign issue_operand_rb_i_int = issue_operand_rb_i_iso_q;
    assign alu_result_e1_i_int = alu_result_e1_i_iso_q;
    assign csr_result_value_e1_i_int = csr_result_value_e1_i_iso_q;
    assign csr_result_write_e1_i_int = csr_result_write_e1_i_iso_q;
    assign csr_result_wdata_e1_i_int = csr_result_wdata_e1_i_iso_q;
    assign csr_result_exception_e1_i_int = csr_result_exception_e1_i_iso_q;
    assign mem_complete_i_int = mem_complete_i_iso_q;
    assign mem_result_e2_i_int = mem_result_e2_i_iso_q;
    assign mem_exception_e2_i_int = mem_exception_e2_i_iso_q;
    assign mul_result_e2_i_int = mul_result_e2_i_iso_q;
    assign div_complete_i_int = div_complete_i_iso_q;
    assign div_result_i_int = div_result_i_iso_q;
    assign squash_e1_e2_i_int = squash_e1_e2_i_iso_q;
    assign squash_wb_i_int = squash_wb_i_iso_q;

    // Output register wall
    reg                   load_e1_o_iso_q;
    reg                   store_e1_o_iso_q;
    reg                   mul_e1_o_iso_q;
    reg                   branch_e1_o_iso_q;
    reg  [  4:0]          rd_e1_o_iso_q;
    reg  [31:0]           pc_e1_o_iso_q;
    reg  [31:0]           opcode_e1_o_iso_q;
    reg  [31:0]           operand_ra_e1_o_iso_q;
    reg  [31:0]           operand_rb_e1_o_iso_q;
    reg                   load_e2_o_iso_q;
    reg                   mul_e2_o_iso_q;
    reg  [  4:0]          rd_e2_o_iso_q;
    reg  [31:0]           result_e2_o_iso_q;
    reg                   valid_wb_o_iso_q;
    reg                   csr_wb_o_iso_q;
    reg  [  4:0]          rd_wb_o_iso_q;
    reg  [31:0]           result_wb_o_iso_q;
    reg  [31:0]           pc_wb_o_iso_q;
    reg  [31:0]           opcode_wb_o_iso_q;
    reg  [31:0]           operand_ra_wb_o_iso_q;
    reg  [31:0]           operand_rb_wb_o_iso_q;
    reg  [5:0]            exception_wb_o_iso_q;
    reg                   csr_write_wb_o_iso_q;
    reg  [11:0]           csr_waddr_wb_o_iso_q;
    reg  [31:0]           csr_wdata_wb_o_iso_q;
    reg                   stall_o_iso_q;
    reg                   squash_e1_e2_o_iso_q;

    always @ (posedge clk_i)
    begin
        load_e1_o_iso_q <= load_e1_o_int;
        store_e1_o_iso_q <= store_e1_o_int;
        mul_e1_o_iso_q <= mul_e1_o_int;
        branch_e1_o_iso_q <= branch_e1_o_int;
        rd_e1_o_iso_q <= rd_e1_o_int;
        pc_e1_o_iso_q <= pc_e1_o_int;
        opcode_e1_o_iso_q <= opcode_e1_o_int;
        operand_ra_e1_o_iso_q <= operand_ra_e1_o_int;
        operand_rb_e1_o_iso_q <= operand_rb_e1_o_int;
        load_e2_o_iso_q <= load_e2_o_int;
        mul_e2_o_iso_q <= mul_e2_o_int;
        rd_e2_o_iso_q <= rd_e2_o_int;
        result_e2_o_iso_q <= result_e2_o_int;
        valid_wb_o_iso_q <= valid_wb_o_int;
        csr_wb_o_iso_q <= csr_wb_o_int;
        rd_wb_o_iso_q <= rd_wb_o_int;
        result_wb_o_iso_q <= result_wb_o_int;
        pc_wb_o_iso_q <= pc_wb_o_int;
        opcode_wb_o_iso_q <= opcode_wb_o_int;
        operand_ra_wb_o_iso_q <= operand_ra_wb_o_int;
        operand_rb_wb_o_iso_q <= operand_rb_wb_o_int;
        exception_wb_o_iso_q <= exception_wb_o_int;
        csr_write_wb_o_iso_q <= csr_write_wb_o_int;
        csr_waddr_wb_o_iso_q <= csr_waddr_wb_o_int;
        csr_wdata_wb_o_iso_q <= csr_wdata_wb_o_int;
        stall_o_iso_q <= stall_o_int;
        squash_e1_e2_o_iso_q <= squash_e1_e2_o_int;
    end

    assign load_e1_o = load_e1_o_iso_q;
    assign store_e1_o = store_e1_o_iso_q;
    assign mul_e1_o = mul_e1_o_iso_q;
    assign branch_e1_o = branch_e1_o_iso_q;
    assign rd_e1_o = rd_e1_o_iso_q;
    assign pc_e1_o = pc_e1_o_iso_q;
    assign opcode_e1_o = opcode_e1_o_iso_q;
    assign operand_ra_e1_o = operand_ra_e1_o_iso_q;
    assign operand_rb_e1_o = operand_rb_e1_o_iso_q;
    assign load_e2_o = load_e2_o_iso_q;
    assign mul_e2_o = mul_e2_o_iso_q;
    assign rd_e2_o = rd_e2_o_iso_q;
    assign result_e2_o = result_e2_o_iso_q;
    assign valid_wb_o = valid_wb_o_iso_q;
    assign csr_wb_o = csr_wb_o_iso_q;
    assign rd_wb_o = rd_wb_o_iso_q;
    assign result_wb_o = result_wb_o_iso_q;
    assign pc_wb_o = pc_wb_o_iso_q;
    assign opcode_wb_o = opcode_wb_o_iso_q;
    assign operand_ra_wb_o = operand_ra_wb_o_iso_q;
    assign operand_rb_wb_o = operand_rb_wb_o_iso_q;
    assign exception_wb_o = exception_wb_o_iso_q;
    assign csr_write_wb_o = csr_write_wb_o_iso_q;
    assign csr_waddr_wb_o = csr_waddr_wb_o_iso_q;
    assign csr_wdata_wb_o = csr_wdata_wb_o_iso_q;
    assign stall_o = stall_o_iso_q;
    assign squash_e1_e2_o = squash_e1_e2_o_iso_q;
end
else
begin : g_synth_no_iso
    assign issue_valid_i_int = issue_valid_i;
    assign issue_accept_i_int = issue_accept_i;
    assign issue_stall_i_int = issue_stall_i;
    assign issue_lsu_i_int = issue_lsu_i;
    assign issue_csr_i_int = issue_csr_i;
    assign issue_div_i_int = issue_div_i;
    assign issue_mul_i_int = issue_mul_i;
    assign issue_branch_i_int = issue_branch_i;
    assign issue_rd_valid_i_int = issue_rd_valid_i;
    assign issue_rd_i_int = issue_rd_i;
    assign issue_exception_i_int = issue_exception_i;
    assign take_interrupt_i_int = take_interrupt_i;
    assign issue_branch_taken_i_int = issue_branch_taken_i;
    assign issue_branch_target_i_int = issue_branch_target_i;
    assign issue_pc_i_int = issue_pc_i;
    assign issue_opcode_i_int = issue_opcode_i;
    assign issue_operand_ra_i_int = issue_operand_ra_i;
    assign issue_operand_rb_i_int = issue_operand_rb_i;
    assign alu_result_e1_i_int = alu_result_e1_i;
    assign csr_result_value_e1_i_int = csr_result_value_e1_i;
    assign csr_result_write_e1_i_int = csr_result_write_e1_i;
    assign csr_result_wdata_e1_i_int = csr_result_wdata_e1_i;
    assign csr_result_exception_e1_i_int = csr_result_exception_e1_i;
    assign mem_complete_i_int = mem_complete_i;
    assign mem_result_e2_i_int = mem_result_e2_i;
    assign mem_exception_e2_i_int = mem_exception_e2_i;
    assign mul_result_e2_i_int = mul_result_e2_i;
    assign div_complete_i_int = div_complete_i;
    assign div_result_i_int = div_result_i;
    assign squash_e1_e2_i_int = squash_e1_e2_i;
    assign squash_wb_i_int = squash_wb_i;
    assign load_e1_o = load_e1_o_int;
    assign store_e1_o = store_e1_o_int;
    assign mul_e1_o = mul_e1_o_int;
    assign branch_e1_o = branch_e1_o_int;
    assign rd_e1_o = rd_e1_o_int;
    assign pc_e1_o = pc_e1_o_int;
    assign opcode_e1_o = opcode_e1_o_int;
    assign operand_ra_e1_o = operand_ra_e1_o_int;
    assign operand_rb_e1_o = operand_rb_e1_o_int;
    assign load_e2_o = load_e2_o_int;
    assign mul_e2_o = mul_e2_o_int;
    assign rd_e2_o = rd_e2_o_int;
    assign result_e2_o = result_e2_o_int;
    assign valid_wb_o = valid_wb_o_int;
    assign csr_wb_o = csr_wb_o_int;
    assign rd_wb_o = rd_wb_o_int;
    assign result_wb_o = result_wb_o_int;
    assign pc_wb_o = pc_wb_o_int;
    assign opcode_wb_o = opcode_wb_o_int;
    assign operand_ra_wb_o = operand_ra_wb_o_int;
    assign operand_rb_wb_o = operand_rb_wb_o_int;
    assign exception_wb_o = exception_wb_o_int;
    assign csr_write_wb_o = csr_write_wb_o_int;
    assign csr_waddr_wb_o = csr_waddr_wb_o_int;
    assign csr_wdata_wb_o = csr_wdata_wb_o_int;
    assign stall_o = stall_o_int;
    assign squash_e1_e2_o = squash_e1_e2_o_int;
end
endgenerate


wire squash_e1_e2_w;
wire branch_misaligned_w = (issue_branch_taken_i_int && issue_branch_target_i_int[1:0] != 2'b0);

//-------------------------------------------------------------
// E1 / Address
//------------------------------------------------------------- 
`define PCINFO_W     10
`define PCINFO_ALU       0
`define PCINFO_LOAD      1
`define PCINFO_STORE     2
`define PCINFO_CSR       3
`define PCINFO_DIV       4
`define PCINFO_MUL       5
`define PCINFO_BRANCH    6
`define PCINFO_RD_VALID  7
`define PCINFO_INTR      8
`define PCINFO_COMPLETE  9

`define RD_IDX_R    11:7

reg                     valid_e1_q;
reg [`PCINFO_W-1:0]     ctrl_e1_q;
reg [31:0]              pc_e1_q;
reg [31:0]              npc_e1_q;
reg [31:0]              opcode_e1_q;
reg [31:0]              operand_ra_e1_q;
reg [31:0]              operand_rb_e1_q;
reg [`EXCEPTION_W-1:0]  exception_e1_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    valid_e1_q      <= 1'b0;
    ctrl_e1_q       <= `PCINFO_W'b0;
    pc_e1_q         <= 32'b0;
    npc_e1_q        <= 32'b0;
    opcode_e1_q     <= 32'b0;
    operand_ra_e1_q <= 32'b0;
    operand_rb_e1_q <= 32'b0;
    exception_e1_q  <= `EXCEPTION_W'b0;
end
// Stall - no change in E1 state
else if (issue_stall_i_int)
    ;
else if ((issue_valid_i_int && issue_accept_i_int) && ~(squash_e1_e2_o_int || squash_e1_e2_i_int))
begin
    valid_e1_q                  <= 1'b1;
    ctrl_e1_q[`PCINFO_ALU]      <= ~(issue_lsu_i_int | issue_csr_i_int | issue_div_i_int | issue_mul_i_int);
    ctrl_e1_q[`PCINFO_LOAD]     <= issue_lsu_i_int &  issue_rd_valid_i_int & ~take_interrupt_i_int; // TODO: Check
    ctrl_e1_q[`PCINFO_STORE]    <= issue_lsu_i_int & ~issue_rd_valid_i_int & ~take_interrupt_i_int;
    ctrl_e1_q[`PCINFO_CSR]      <= issue_csr_i_int & ~take_interrupt_i_int;
    ctrl_e1_q[`PCINFO_DIV]      <= issue_div_i_int & ~take_interrupt_i_int;
    ctrl_e1_q[`PCINFO_MUL]      <= issue_mul_i_int & ~take_interrupt_i_int;
    ctrl_e1_q[`PCINFO_BRANCH]   <= issue_branch_i_int & ~take_interrupt_i_int;
    ctrl_e1_q[`PCINFO_RD_VALID] <= issue_rd_valid_i_int & ~take_interrupt_i_int;
    ctrl_e1_q[`PCINFO_INTR]     <= take_interrupt_i_int;
    ctrl_e1_q[`PCINFO_COMPLETE] <= 1'b1;

    pc_e1_q         <= issue_pc_i_int;
    npc_e1_q        <= issue_branch_taken_i_int ? issue_branch_target_i_int : issue_pc_i_int + 32'd4;
    opcode_e1_q     <= issue_opcode_i_int;
    operand_ra_e1_q <= issue_operand_ra_i_int;
    operand_rb_e1_q <= issue_operand_rb_i_int;
    exception_e1_q  <= (|issue_exception_i_int) ? issue_exception_i_int : 
                       branch_misaligned_w  ? `EXCEPTION_MISALIGNED_FETCH : `EXCEPTION_W'b0;
end
// No valid instruction (or pipeline flush event)
else
begin
    valid_e1_q      <= 1'b0;
    ctrl_e1_q       <= `PCINFO_W'b0;
    pc_e1_q         <= 32'b0;
    npc_e1_q        <= 32'b0;
    opcode_e1_q     <= 32'b0;
    operand_ra_e1_q <= 32'b0;
    operand_rb_e1_q <= 32'b0;
    exception_e1_q  <= `EXCEPTION_W'b0;
end

wire   alu_e1_w        = ctrl_e1_q[`PCINFO_ALU];
assign load_e1_o_int       = ctrl_e1_q[`PCINFO_LOAD];
assign store_e1_o_int      = ctrl_e1_q[`PCINFO_STORE];
wire   csr_e1_w        = ctrl_e1_q[`PCINFO_CSR];
wire   div_e1_w        = ctrl_e1_q[`PCINFO_DIV];
assign mul_e1_o_int        = ctrl_e1_q[`PCINFO_MUL];
assign branch_e1_o_int     = ctrl_e1_q[`PCINFO_BRANCH];
assign rd_e1_o_int         = {5{ctrl_e1_q[`PCINFO_RD_VALID]}} & opcode_e1_q[`RD_IDX_R];
assign pc_e1_o_int         = pc_e1_q;
assign opcode_e1_o_int     = opcode_e1_q;
assign operand_ra_e1_o_int = operand_ra_e1_q;
assign operand_rb_e1_o_int = operand_rb_e1_q;

//-------------------------------------------------------------
// E2 / Mem result
//------------------------------------------------------------- 
reg                     valid_e2_q;
reg [`PCINFO_W-1:0]     ctrl_e2_q;
reg                     csr_wr_e2_q;
reg [31:0]              csr_wdata_e2_q;
reg [31:0]              result_e2_q;
reg [31:0]              pc_e2_q;
reg [31:0]              npc_e2_q;
reg [31:0]              opcode_e2_q;
reg [31:0]              operand_ra_e2_q;
reg [31:0]              operand_rb_e2_q;
reg [`EXCEPTION_W-1:0]  exception_e2_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    valid_e2_q      <= 1'b0;
    ctrl_e2_q       <= `PCINFO_W'b0;
    csr_wr_e2_q     <= 1'b0;
    csr_wdata_e2_q  <= 32'b0;
    pc_e2_q         <= 32'b0;
    npc_e2_q        <= 32'b0;
    opcode_e2_q     <= 32'b0;
    operand_ra_e2_q <= 32'b0;
    operand_rb_e2_q <= 32'b0;
    result_e2_q     <= 32'b0;
    exception_e2_q  <= `EXCEPTION_W'b0;
end
// Stall - no change in E2 state
else if (issue_stall_i_int)
    ;
// Pipeline flush
else if (squash_e1_e2_o_int || squash_e1_e2_i_int)
begin
    valid_e2_q      <= 1'b0;
    ctrl_e2_q       <= `PCINFO_W'b0;
    csr_wr_e2_q     <= 1'b0;
    csr_wdata_e2_q  <= 32'b0;
    pc_e2_q         <= 32'b0;
    npc_e2_q        <= 32'b0;
    opcode_e2_q     <= 32'b0;
    operand_ra_e2_q <= 32'b0;
    operand_rb_e2_q <= 32'b0;
    result_e2_q     <= 32'b0;
    exception_e2_q  <= `EXCEPTION_W'b0;
end
// Normal pipeline advance
else
begin
    valid_e2_q      <= valid_e1_q;
    ctrl_e2_q       <= ctrl_e1_q;
    csr_wr_e2_q     <= csr_result_write_e1_i_int;
    csr_wdata_e2_q  <= csr_result_wdata_e1_i_int;
    pc_e2_q         <= pc_e1_q;
    npc_e2_q        <= npc_e1_q;
    opcode_e2_q     <= opcode_e1_q;
    operand_ra_e2_q <= operand_ra_e1_q;
    operand_rb_e2_q <= operand_rb_e1_q;

    // Launch interrupt
    if (ctrl_e1_q[`PCINFO_INTR])
        exception_e2_q  <= `EXCEPTION_INTERRUPT;
    // If frontend reports bad instruction, ignore later CSR errors...
    else if (|exception_e1_q)
    begin
        valid_e2_q      <= 1'b0;
        exception_e2_q  <= exception_e1_q;
    end
    else
        exception_e2_q  <= csr_result_exception_e1_i_int;

    if (ctrl_e1_q[`PCINFO_DIV])
        result_e2_q <= div_result_i_int; 
    else if (ctrl_e1_q[`PCINFO_CSR])
        result_e2_q <= csr_result_value_e1_i_int;
    else
        result_e2_q <= alu_result_e1_i_int;
end

reg [31:0] result_e2_r;

wire valid_e2_w      = valid_e2_q & ~issue_stall_i_int;

always @ *
begin
    // Default: ALU result
    result_e2_r = result_e2_q;

    if (SUPPORT_LOAD_BYPASS && valid_e2_w && (ctrl_e2_q[`PCINFO_LOAD] || ctrl_e2_q[`PCINFO_STORE]))
        result_e2_r = mem_result_e2_i_int;
    else if (SUPPORT_MUL_BYPASS && valid_e2_w && ctrl_e2_q[`PCINFO_MUL])
        result_e2_r = mul_result_e2_i_int;
end

wire   load_store_e2_w = ctrl_e2_q[`PCINFO_LOAD] | ctrl_e2_q[`PCINFO_STORE];
assign load_e2_o_int       = ctrl_e2_q[`PCINFO_LOAD];
assign mul_e2_o_int        = ctrl_e2_q[`PCINFO_MUL];
assign rd_e2_o_int         = {5{(valid_e2_w && ctrl_e2_q[`PCINFO_RD_VALID] && ~stall_o_int)}} & opcode_e2_q[`RD_IDX_R];
assign result_e2_o_int     = result_e2_r;

// Load store result not ready when reaching E2
assign stall_o_int         = (ctrl_e1_q[`PCINFO_DIV] && ~div_complete_i_int) || ((ctrl_e2_q[`PCINFO_LOAD] | ctrl_e2_q[`PCINFO_STORE]) & ~mem_complete_i_int);

reg [`EXCEPTION_W-1:0] exception_e2_r;
always @ *
begin
    if (valid_e2_q && (ctrl_e2_q[`PCINFO_LOAD] || ctrl_e2_q[`PCINFO_STORE]) && mem_complete_i_int)
        exception_e2_r = mem_exception_e2_i_int;
    else
        exception_e2_r = exception_e2_q;
end

assign squash_e1_e2_w = |exception_e2_r;

reg squash_e1_e2_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    squash_e1_e2_q <= 1'b0;
else if (~issue_stall_i_int)
    squash_e1_e2_q <= squash_e1_e2_w;

assign squash_e1_e2_o_int = squash_e1_e2_w | squash_e1_e2_q;

//-------------------------------------------------------------
// Writeback / Commit
//------------------------------------------------------------- 
reg                     valid_wb_q;
reg [`PCINFO_W-1:0]     ctrl_wb_q;
reg                     csr_wr_wb_q;
reg [31:0]              csr_wdata_wb_q;
reg [31:0]              result_wb_q;
reg [31:0]              pc_wb_q;
reg [31:0]              npc_wb_q;
reg [31:0]              opcode_wb_q;
reg [31:0]              operand_ra_wb_q;
reg [31:0]              operand_rb_wb_q;
reg [`EXCEPTION_W-1:0]  exception_wb_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    valid_wb_q      <= 1'b0;
    ctrl_wb_q       <= `PCINFO_W'b0;
    csr_wr_wb_q     <= 1'b0;
    csr_wdata_wb_q  <= 32'b0;
    pc_wb_q         <= 32'b0;
    npc_wb_q        <= 32'b0;
    opcode_wb_q     <= 32'b0;
    operand_ra_wb_q <= 32'b0;
    operand_rb_wb_q <= 32'b0;
    result_wb_q     <= 32'b0;
    exception_wb_q  <= `EXCEPTION_W'b0;
end
// Stall - no change in WB state
else if (issue_stall_i_int)
    ;
else if (squash_wb_i_int)
begin
    valid_wb_q      <= 1'b0;
    ctrl_wb_q       <= `PCINFO_W'b0;
    csr_wr_wb_q     <= 1'b0;
    csr_wdata_wb_q  <= 32'b0;
    pc_wb_q         <= 32'b0;
    npc_wb_q        <= 32'b0;
    opcode_wb_q     <= 32'b0;
    operand_ra_wb_q <= 32'b0;
    operand_rb_wb_q <= 32'b0;
    result_wb_q     <= 32'b0;
    exception_wb_q  <= `EXCEPTION_W'b0;
end
else
begin
    // Squash instruction valid on memory faults
    case (exception_e2_r)
    `EXCEPTION_MISALIGNED_LOAD,
    `EXCEPTION_FAULT_LOAD,
    `EXCEPTION_MISALIGNED_STORE,
    `EXCEPTION_FAULT_STORE,
    `EXCEPTION_PAGE_FAULT_LOAD,
    `EXCEPTION_PAGE_FAULT_STORE:
        valid_wb_q      <= 1'b0;
    default:
        valid_wb_q      <= valid_e2_q;
    endcase

    csr_wr_wb_q     <= csr_wr_e2_q;  // TODO: Fault disable???
    csr_wdata_wb_q  <= csr_wdata_e2_q;

    // Exception - squash writeback
    if (|exception_e2_r)
        ctrl_wb_q       <= ctrl_e2_q & ~(1 << `PCINFO_RD_VALID);
    else
        ctrl_wb_q       <= ctrl_e2_q;

    pc_wb_q         <= pc_e2_q;
    npc_wb_q        <= npc_e2_q;
    opcode_wb_q     <= opcode_e2_q;
    operand_ra_wb_q <= operand_ra_e2_q;
    operand_rb_wb_q <= operand_rb_e2_q;
    exception_wb_q  <= exception_e2_r;

    if (valid_e2_w && (ctrl_e2_q[`PCINFO_LOAD] || ctrl_e2_q[`PCINFO_STORE]))
        result_wb_q <= mem_result_e2_i_int;
    else if (valid_e2_w && ctrl_e2_q[`PCINFO_MUL])
        result_wb_q <= mul_result_e2_i_int;
    else
        result_wb_q <= result_e2_q;
end

// Instruction completion (for debug)
wire complete_wb_w     = ctrl_wb_q[`PCINFO_COMPLETE] & ~issue_stall_i_int;

assign valid_wb_o_int      = valid_wb_q & ~issue_stall_i_int;
assign csr_wb_o_int        = ctrl_wb_q[`PCINFO_CSR] & ~issue_stall_i_int; // TODO: Fault disable???
assign rd_wb_o_int         = {5{(valid_wb_o_int && ctrl_wb_q[`PCINFO_RD_VALID] && ~stall_o_int)}} & opcode_wb_q[`RD_IDX_R];
assign result_wb_o_int     = result_wb_q;
assign pc_wb_o_int         = pc_wb_q;
assign opcode_wb_o_int     = opcode_wb_q;
assign operand_ra_wb_o_int = operand_ra_wb_q;
assign operand_rb_wb_o_int = operand_rb_wb_q;

assign exception_wb_o_int  = exception_wb_q;

assign csr_write_wb_o_int  = csr_wr_wb_q;
assign csr_waddr_wb_o_int  = opcode_wb_q[31:20];
assign csr_wdata_wb_o_int  = csr_wdata_wb_q;

`ifdef verilator
biriscv_trace_sim
u_trace_d
(
     .valid_i(issue_valid_i_int)
    ,.pc_i(issue_pc_i_int)
    ,.opcode_i(issue_opcode_i_int)
);

biriscv_trace_sim
u_trace_wb
(
     .valid_i(valid_wb_o_int)
    ,.pc_i(pc_wb_o_int)
    ,.opcode_i(opcode_wb_o_int)
);
`endif

endmodule