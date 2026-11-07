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
module biriscv_alu
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SYNTH_MODE_ISO = 0 // 1: register all I/Os (standalone synthesis only)
)
(
    // Inputs
     input           clk_i  // Only used when SYNTH_MODE_ISO = 1
    ,input  [  3:0]  alu_op_i
    ,input  [ 31:0]  alu_a_i
    ,input  [ 31:0]  alu_b_i

    // Outputs
    ,output [ 31:0]  alu_p_o
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
wire [  3:0]          alu_op_i_int;
wire [ 31:0]          alu_a_i_int;
wire [ 31:0]          alu_b_i_int;
wire [ 31:0]          alu_p_o_int;

generate
if (SYNTH_MODE_ISO)
begin : g_synth_iso
    // Input register wall
    reg  [  3:0]          alu_op_i_iso_q;
    reg  [ 31:0]          alu_a_i_iso_q;
    reg  [ 31:0]          alu_b_i_iso_q;

    always @ (posedge clk_i)
    begin
        alu_op_i_iso_q <= alu_op_i;
        alu_a_i_iso_q  <= alu_a_i;
        alu_b_i_iso_q  <= alu_b_i;
    end

    assign alu_op_i_int = alu_op_i_iso_q;
    assign alu_a_i_int  = alu_a_i_iso_q;
    assign alu_b_i_int  = alu_b_i_iso_q;

    // Output register wall
    reg  [ 31:0]          alu_p_o_iso_q;

    always @ (posedge clk_i)
    begin
        alu_p_o_iso_q <= alu_p_o_int;
    end

    assign alu_p_o = alu_p_o_iso_q;
end
else
begin : g_synth_no_iso
    assign alu_op_i_int = alu_op_i;
    assign alu_a_i_int  = alu_a_i;
    assign alu_b_i_int  = alu_b_i;
    assign alu_p_o      = alu_p_o_int;
end
endgenerate

//-----------------------------------------------------------------
// Submodule Interconnect Wires
// Explicitly modularized to preserve functional hierarchy during
// synthesis and static timing analysis.
//-----------------------------------------------------------------
wire [31:0] shift_res_w;
wire [31:0] add_res_w;
wire [31:0] sub_res_w;
wire [31:0] sltu_res_w;
wire [31:0] slt_res_w;
wire [31:0] and_res_w;
wire [31:0] or_res_w;
wire [31:0] xor_res_w;

//-----------------------------------------------------------------
// ALU Functional Submodules
//-----------------------------------------------------------------

// Multi-stage Barrel Shifter (Left, Right Logical, Right Arithmetic)
biriscv_alu_shifter u_shifter (
    .alu_op_i      (alu_op_i_int),
    .alu_a_i       (alu_a_i_int),
    .alu_b_i       (alu_b_i_int),
    .shift_res_o   (shift_res_w)
);

// 32-bit Adder and Subtractor
biriscv_alu_adder u_adder (
    .alu_a_i       (alu_a_i_int),
    .alu_b_i       (alu_b_i_int),
    .add_res_o     (add_res_w),
    .sub_res_o     (sub_res_w)
);

// Comparator (Signed & Unsigned Less Than)
biriscv_alu_cmp u_cmp (
    .alu_a_i       (alu_a_i_int),
    .alu_b_i       (alu_b_i_int),
    .sub_res_i     (sub_res_w),
    .sltu_res_o    (sltu_res_w),
    .slt_res_o     (slt_res_w)
);

// Bitwise Logic Operations (AND, OR, XOR)
biriscv_alu_logic u_logic (
    .alu_a_i       (alu_a_i_int),
    .alu_b_i       (alu_b_i_int),
    .and_res_o     (and_res_w),
    .or_res_o      (or_res_w),
    .xor_res_o     (xor_res_w)
);

// Output Multiplexer
biriscv_alu_mux u_mux (
    .alu_op_i      (alu_op_i_int),
    .alu_a_i       (alu_a_i_int),
    .shift_res_i   (shift_res_w),
    .add_res_i     (add_res_w),
    .sub_res_i     (sub_res_w),
    .sltu_res_i    (sltu_res_w),
    .slt_res_i     (slt_res_w),
    .and_res_i     (and_res_w),
    .or_res_i      (or_res_w),
    .xor_res_i     (xor_res_w),
    .result_o      (alu_p_o_int)
);

endmodule


//=================================================================
// Submodule: biriscv_alu_shifter
// Multi-stage barrel shifter for Left and Right shifts
//=================================================================
module biriscv_alu_shifter
(
     input  [ 3:0]  alu_op_i
    ,input  [31:0]  alu_a_i
    ,input  [31:0]  alu_b_i
    ,output [31:0]  shift_res_o
);

`include "biriscv_defs.v"

wire [31:0] shift_left_res_w;
wire [31:0] shift_right_res_w;
wire        is_arith_shift_w = (alu_op_i == `ALU_SHIFTR_ARITH);

biriscv_alu_shift_left u_shifter_left (
    .alu_a_i     (alu_a_i),
    .shift_amt_i (alu_b_i[4:0]),
    .res_o       (shift_left_res_w)
);

biriscv_alu_shift_right u_shifter_right (
    .alu_a_i     (alu_a_i),
    .shift_amt_i (alu_b_i[4:0]),
    .is_arith_i  (is_arith_shift_w),
    .res_o       (shift_right_res_w)
);

assign shift_res_o = (alu_op_i == `ALU_SHIFTL) ? shift_left_res_w : shift_right_res_w;

endmodule


//=================================================================
// Submodule: biriscv_alu_shift_left
// 5-stage logarithmic barrel shifter (Left Shift)
//=================================================================
module biriscv_alu_shift_left
(
     input  [31:0]  alu_a_i
    ,input  [ 4:0]  shift_amt_i
    ,output [31:0]  res_o
);

wire [31:0] stage_1  = shift_amt_i[0] ? {alu_a_i[30:0], 1'b0} : alu_a_i;
wire [31:0] stage_2  = shift_amt_i[1] ? {stage_1[29:0], 2'b00} : stage_1;
wire [31:0] stage_4  = shift_amt_i[2] ? {stage_2[27:0], 4'b0000} : stage_2;
wire [31:0] stage_8  = shift_amt_i[3] ? {stage_4[23:0], 8'b00000000} : stage_4;
wire [31:0] stage_16 = shift_amt_i[4] ? {stage_8[15:0], 16'b0000000000000000} : stage_8;

assign res_o = stage_16;

endmodule


//=================================================================
// Submodule: biriscv_alu_shift_right
// 5-stage logarithmic barrel shifter (Right Shift Logical/Arithmetic)
//=================================================================
module biriscv_alu_shift_right
(
     input  [31:0]  alu_a_i
    ,input  [ 4:0]  shift_amt_i
    ,input          is_arith_i
    ,output [31:0]  res_o
);

wire [15:0] fill = (is_arith_i && alu_a_i[31]) ? 16'hFFFF : 16'h0000;

wire [31:0] stage_1  = shift_amt_i[0] ? {fill[15], alu_a_i[31:1]} : alu_a_i;
wire [31:0] stage_2  = shift_amt_i[1] ? {fill[15:14], stage_1[31:2]} : stage_1;
wire [31:0] stage_4  = shift_amt_i[2] ? {fill[15:12], stage_2[31:4]} : stage_2;
wire [31:0] stage_8  = shift_amt_i[3] ? {fill[15:8], stage_4[31:8]} : stage_4;
wire [31:0] stage_16 = shift_amt_i[4] ? {fill[15:0], stage_8[31:16]} : stage_8;

assign res_o = stage_16;

endmodule


//=================================================================
// Submodule: biriscv_alu_adder
// 32-bit Adder and Subtractor
//=================================================================
module biriscv_alu_adder
(
     input  [31:0]  alu_a_i
    ,input  [31:0]  alu_b_i
    ,output [31:0]  add_res_o
    ,output [31:0]  sub_res_o
);

assign add_res_o = alu_a_i + alu_b_i;
assign sub_res_o = alu_a_i - alu_b_i;

endmodule


//=================================================================
// Submodule: biriscv_alu_cmp
// Comparator (Unsigned & Signed Less Than)
//=================================================================
module biriscv_alu_cmp
(
     input  [31:0]  alu_a_i
    ,input  [31:0]  alu_b_i
    ,input  [31:0]  sub_res_i
    ,output [31:0]  sltu_res_o
    ,output [31:0]  slt_res_o
);

assign sltu_res_o = (alu_a_i < alu_b_i) ? 32'h00000001 : 32'h00000000;

wire slt_bit_w = (alu_a_i[31] != alu_b_i[31]) ? alu_a_i[31] : sub_res_i[31];
assign slt_res_o = slt_bit_w ? 32'h00000001 : 32'h00000000;

endmodule


//=================================================================
// Submodule: biriscv_alu_logic
// Bitwise Logic Operations (AND, OR, XOR)
//=================================================================
module biriscv_alu_logic
(
     input  [31:0]  alu_a_i
    ,input  [31:0]  alu_b_i
    ,output [31:0]  and_res_o
    ,output [31:0]  or_res_o
    ,output [31:0]  xor_res_o
);

assign and_res_o = alu_a_i & alu_b_i;
assign or_res_o  = alu_a_i | alu_b_i;
assign xor_res_o = alu_a_i ^ alu_b_i;

endmodule


//=================================================================
// Submodule: biriscv_alu_mux
// Output Multiplexer for ALU Operation Selection
//=================================================================
module biriscv_alu_mux
(
     input      [ 3:0]  alu_op_i
    ,input      [31:0]  alu_a_i
    ,input      [31:0]  shift_res_i
    ,input      [31:0]  add_res_i
    ,input      [31:0]  sub_res_i
    ,input      [31:0]  sltu_res_i
    ,input      [31:0]  slt_res_i
    ,input      [31:0]  and_res_i
    ,input      [31:0]  or_res_i
    ,input      [31:0]  xor_res_i
    ,output reg [31:0]  result_o
);

`include "biriscv_defs.v"

always @ (*)
begin
    case (alu_op_i)
        `ALU_SHIFTL:           result_o = shift_res_i;
        `ALU_SHIFTR:           result_o = shift_res_i;
        `ALU_SHIFTR_ARITH:     result_o = shift_res_i;
        `ALU_ADD:              result_o = add_res_i;
        `ALU_SUB:              result_o = sub_res_i;
        `ALU_AND:              result_o = and_res_i;
        `ALU_OR:               result_o = or_res_i;
        `ALU_XOR:              result_o = xor_res_i;
        `ALU_LESS_THAN:        result_o = sltu_res_i;
        `ALU_LESS_THAN_SIGNED: result_o = slt_res_i;
        default:               result_o = alu_a_i;
    endcase
end

endmodule
