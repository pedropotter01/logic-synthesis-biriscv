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

module biriscv_divider
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

    // Outputs
    ,output          writeback_valid_o
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
wire                  writeback_valid_o_int;
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

    // Output register wall
    reg                   writeback_valid_o_iso_q;
    reg  [ 31:0]          writeback_value_o_iso_q;

    always @ (posedge clk_i)
    begin
        writeback_valid_o_iso_q <= writeback_valid_o_int;
        writeback_value_o_iso_q <= writeback_value_o_int;
    end

    assign writeback_valid_o = writeback_valid_o_iso_q;
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
    assign writeback_valid_o = writeback_valid_o_int;
    assign writeback_value_o = writeback_value_o_int;
end
endgenerate


//-------------------------------------------------------------
// Registers / Wires
//-------------------------------------------------------------
reg          valid_q;
reg  [31:0]  wb_result_q;

//-------------------------------------------------------------
// Divider
//-------------------------------------------------------------
wire inst_div_w         = (opcode_opcode_i_int & `INST_DIV_MASK) == `INST_DIV;
wire inst_divu_w        = (opcode_opcode_i_int & `INST_DIVU_MASK) == `INST_DIVU;
wire inst_rem_w         = (opcode_opcode_i_int & `INST_REM_MASK) == `INST_REM;
wire inst_remu_w        = (opcode_opcode_i_int & `INST_REMU_MASK) == `INST_REMU;

wire div_rem_inst_w     = ((opcode_opcode_i_int & `INST_DIV_MASK) == `INST_DIV)  || 
                          ((opcode_opcode_i_int & `INST_DIVU_MASK) == `INST_DIVU) ||
                          ((opcode_opcode_i_int & `INST_REM_MASK) == `INST_REM)  ||
                          ((opcode_opcode_i_int & `INST_REMU_MASK) == `INST_REMU);

wire signed_operation_w = ((opcode_opcode_i_int & `INST_DIV_MASK) == `INST_DIV) || ((opcode_opcode_i_int & `INST_REM_MASK) == `INST_REM);
wire div_operation_w    = ((opcode_opcode_i_int & `INST_DIV_MASK) == `INST_DIV) || ((opcode_opcode_i_int & `INST_DIVU_MASK) == `INST_DIVU);

reg [31:0] dividend_q;
reg [62:0] divisor_q;
reg [31:0] quotient_q;
reg [31:0] q_mask_q;
reg        div_inst_q;
reg        div_busy_q;
reg        invert_res_q;

reg [31:0] last_a_q;
reg [31:0] last_b_q;
reg        last_div_q;
reg        last_divu_q;
reg        last_rem_q;
reg        last_remu_q;

wire div_start_w    = opcode_valid_i_int & div_rem_inst_w;
wire div_complete_w = !(|q_mask_q) & div_busy_q;

always @(posedge clk_i or posedge rst_i)
if (rst_i)
begin
    div_busy_q     <= 1'b0;
    dividend_q     <= 32'b0;
    divisor_q      <= 63'b0;
    invert_res_q   <= 1'b0;
    quotient_q     <= 32'b0;
    q_mask_q       <= 32'b0;
    div_inst_q     <= 1'b0;
    last_a_q       <= 32'b0;
    last_b_q       <= 32'b0;
    last_div_q     <= 1'b0;
    last_divu_q    <= 1'b0;
    last_rem_q     <= 1'b0;
    last_remu_q    <= 1'b0;
end
else if (div_start_w)
begin
    // Repeat same operation with same inputs...
    if (last_a_q    == opcode_ra_operand_i_int && 
        last_b_q    == opcode_rb_operand_i_int &&
        last_div_q  == inst_div_w &&
        last_divu_q == inst_divu_w &&
        last_rem_q  == inst_rem_w &&
        last_remu_q == inst_remu_w)
    begin
        div_busy_q     <= 1'b1;
    end
    else
    begin
        last_a_q       <= opcode_ra_operand_i_int;
        last_b_q       <= opcode_rb_operand_i_int;
        last_div_q     <= inst_div_w;
        last_divu_q    <= inst_divu_w;
        last_rem_q     <= inst_rem_w;
        last_remu_q    <= inst_remu_w;

        div_busy_q     <= 1'b1;
        div_inst_q     <= div_operation_w;

        if (signed_operation_w && opcode_ra_operand_i_int[31])
            dividend_q <= -opcode_ra_operand_i_int;
        else
            dividend_q <= opcode_ra_operand_i_int;

        if (signed_operation_w && opcode_rb_operand_i_int[31])
            divisor_q <= {-opcode_rb_operand_i_int, 31'b0};
        else
            divisor_q <= {opcode_rb_operand_i_int, 31'b0};

        invert_res_q  <= (((opcode_opcode_i_int & `INST_DIV_MASK) == `INST_DIV) && (opcode_ra_operand_i_int[31] != opcode_rb_operand_i_int[31]) && |opcode_rb_operand_i_int) || 
                         (((opcode_opcode_i_int & `INST_REM_MASK) == `INST_REM) && opcode_ra_operand_i_int[31]);

        quotient_q     <= 32'b0;
        q_mask_q       <= 32'h80000000;
    end
end
else if (div_complete_w)
begin
    div_busy_q <= 1'b0;
end
else if (div_busy_q)
begin
    if (divisor_q <= {31'b0, dividend_q})
    begin
        dividend_q <= dividend_q - divisor_q[31:0];
        quotient_q <= quotient_q | q_mask_q;
    end

    divisor_q <= {1'b0, divisor_q[62:1]};
    q_mask_q  <= {1'b0, q_mask_q[31:1]};
end

reg [31:0] div_result_r;
always @ *
begin
    div_result_r = 32'b0;

    if (div_inst_q)
        div_result_r = invert_res_q ? -quotient_q : quotient_q;
    else
        div_result_r = invert_res_q ? -dividend_q : dividend_q;
end

always @(posedge clk_i or posedge rst_i)
if (rst_i)
    valid_q <= 1'b0;
else
    valid_q <= div_complete_w;

always @(posedge clk_i or posedge rst_i)
if (rst_i)
    wb_result_q <= 32'b0;
else if (div_complete_w)
    wb_result_q <= div_result_r;

assign writeback_valid_o_int = valid_q;
assign writeback_value_o_int  = wb_result_q;



endmodule
