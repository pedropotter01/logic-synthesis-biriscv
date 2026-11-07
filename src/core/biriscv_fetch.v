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

module biriscv_fetch
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SUPPORT_MMU      = 1
    ,parameter SYNTH_MODE_ISO = 0 // 1: register all I/Os (standalone synthesis only)
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           fetch_accept_i
    ,input           icache_accept_i
    ,input           icache_valid_i
    ,input           icache_error_i
    ,input  [ 63:0]  icache_inst_i
    ,input           icache_page_fault_i
    ,input           fetch_invalidate_i
    ,input           branch_request_i
    ,input  [ 31:0]  branch_pc_i
    ,input  [  1:0]  branch_priv_i
    ,input  [ 31:0]  next_pc_f_i
    ,input  [  1:0]  next_taken_f_i

    // Outputs
    ,output          fetch_valid_o
    ,output [ 63:0]  fetch_instr_o
    ,output [  1:0]  fetch_pred_branch_o
    ,output          fetch_fault_fetch_o
    ,output          fetch_fault_page_o
    ,output [ 31:0]  fetch_pc_o
    ,output          icache_rd_o
    ,output          icache_flush_o
    ,output          icache_invalidate_o
    ,output [ 31:0]  icache_pc_o
    ,output [  1:0]  icache_priv_o
    ,output [ 31:0]  pc_f_o
    ,output          pc_accept_o
);

//-----------------------------------------------------------------
// SYNTH_MODE_ISO: isolation register walls
//   SYNTH_MODE_ISO = 0 -> ports connected straight through (normal)
//   SYNTH_MODE_ISO = 1 -> every input and output (except clock/reset)
//                         is registered, so this module can be
//                         synthesized and timed standalone.
//-----------------------------------------------------------------
// Internal (module side) view of the ports
wire                  fetch_accept_i_int;
wire                  icache_accept_i_int;
wire                  icache_valid_i_int;
wire                  icache_error_i_int;
wire [ 63:0]          icache_inst_i_int;
wire                  icache_page_fault_i_int;
wire                  fetch_invalidate_i_int;
wire                  branch_request_i_int;
wire [ 31:0]          branch_pc_i_int;
wire [  1:0]          branch_priv_i_int;
wire [ 31:0]          next_pc_f_i_int;
wire [  1:0]          next_taken_f_i_int;
wire                  fetch_valid_o_int;
wire [ 63:0]          fetch_instr_o_int;
wire [  1:0]          fetch_pred_branch_o_int;
wire                  fetch_fault_fetch_o_int;
wire                  fetch_fault_page_o_int;
wire [ 31:0]          fetch_pc_o_int;
wire                  icache_rd_o_int;
wire                  icache_flush_o_int;
wire                  icache_invalidate_o_int;
wire [ 31:0]          icache_pc_o_int;
wire [  1:0]          icache_priv_o_int;
wire [ 31:0]          pc_f_o_int;
wire                  pc_accept_o_int;

generate
if (SYNTH_MODE_ISO)
begin : g_synth_iso
    // Input register wall
    reg                   fetch_accept_i_iso_q;
    reg                   icache_accept_i_iso_q;
    reg                   icache_valid_i_iso_q;
    reg                   icache_error_i_iso_q;
    reg  [ 63:0]          icache_inst_i_iso_q;
    reg                   icache_page_fault_i_iso_q;
    reg                   fetch_invalidate_i_iso_q;
    reg                   branch_request_i_iso_q;
    reg  [ 31:0]          branch_pc_i_iso_q;
    reg  [  1:0]          branch_priv_i_iso_q;
    reg  [ 31:0]          next_pc_f_i_iso_q;
    reg  [  1:0]          next_taken_f_i_iso_q;

    always @ (posedge clk_i)
    begin
        fetch_accept_i_iso_q <= fetch_accept_i;
        icache_accept_i_iso_q <= icache_accept_i;
        icache_valid_i_iso_q <= icache_valid_i;
        icache_error_i_iso_q <= icache_error_i;
        icache_inst_i_iso_q <= icache_inst_i;
        icache_page_fault_i_iso_q <= icache_page_fault_i;
        fetch_invalidate_i_iso_q <= fetch_invalidate_i;
        branch_request_i_iso_q <= branch_request_i;
        branch_pc_i_iso_q <= branch_pc_i;
        branch_priv_i_iso_q <= branch_priv_i;
        next_pc_f_i_iso_q <= next_pc_f_i;
        next_taken_f_i_iso_q <= next_taken_f_i;
    end

    assign fetch_accept_i_int = fetch_accept_i_iso_q;
    assign icache_accept_i_int = icache_accept_i_iso_q;
    assign icache_valid_i_int = icache_valid_i_iso_q;
    assign icache_error_i_int = icache_error_i_iso_q;
    assign icache_inst_i_int = icache_inst_i_iso_q;
    assign icache_page_fault_i_int = icache_page_fault_i_iso_q;
    assign fetch_invalidate_i_int = fetch_invalidate_i_iso_q;
    assign branch_request_i_int = branch_request_i_iso_q;
    assign branch_pc_i_int = branch_pc_i_iso_q;
    assign branch_priv_i_int = branch_priv_i_iso_q;
    assign next_pc_f_i_int = next_pc_f_i_iso_q;
    assign next_taken_f_i_int = next_taken_f_i_iso_q;

    // Output register wall
    reg                   fetch_valid_o_iso_q;
    reg  [ 63:0]          fetch_instr_o_iso_q;
    reg  [  1:0]          fetch_pred_branch_o_iso_q;
    reg                   fetch_fault_fetch_o_iso_q;
    reg                   fetch_fault_page_o_iso_q;
    reg  [ 31:0]          fetch_pc_o_iso_q;
    reg                   icache_rd_o_iso_q;
    reg                   icache_flush_o_iso_q;
    reg                   icache_invalidate_o_iso_q;
    reg  [ 31:0]          icache_pc_o_iso_q;
    reg  [  1:0]          icache_priv_o_iso_q;
    reg  [ 31:0]          pc_f_o_iso_q;
    reg                   pc_accept_o_iso_q;

    always @ (posedge clk_i)
    begin
        fetch_valid_o_iso_q <= fetch_valid_o_int;
        fetch_instr_o_iso_q <= fetch_instr_o_int;
        fetch_pred_branch_o_iso_q <= fetch_pred_branch_o_int;
        fetch_fault_fetch_o_iso_q <= fetch_fault_fetch_o_int;
        fetch_fault_page_o_iso_q <= fetch_fault_page_o_int;
        fetch_pc_o_iso_q <= fetch_pc_o_int;
        icache_rd_o_iso_q <= icache_rd_o_int;
        icache_flush_o_iso_q <= icache_flush_o_int;
        icache_invalidate_o_iso_q <= icache_invalidate_o_int;
        icache_pc_o_iso_q <= icache_pc_o_int;
        icache_priv_o_iso_q <= icache_priv_o_int;
        pc_f_o_iso_q <= pc_f_o_int;
        pc_accept_o_iso_q <= pc_accept_o_int;
    end

    assign fetch_valid_o = fetch_valid_o_iso_q;
    assign fetch_instr_o = fetch_instr_o_iso_q;
    assign fetch_pred_branch_o = fetch_pred_branch_o_iso_q;
    assign fetch_fault_fetch_o = fetch_fault_fetch_o_iso_q;
    assign fetch_fault_page_o = fetch_fault_page_o_iso_q;
    assign fetch_pc_o = fetch_pc_o_iso_q;
    assign icache_rd_o = icache_rd_o_iso_q;
    assign icache_flush_o = icache_flush_o_iso_q;
    assign icache_invalidate_o = icache_invalidate_o_iso_q;
    assign icache_pc_o = icache_pc_o_iso_q;
    assign icache_priv_o = icache_priv_o_iso_q;
    assign pc_f_o = pc_f_o_iso_q;
    assign pc_accept_o = pc_accept_o_iso_q;
end
else
begin : g_synth_no_iso
    assign fetch_accept_i_int = fetch_accept_i;
    assign icache_accept_i_int = icache_accept_i;
    assign icache_valid_i_int = icache_valid_i;
    assign icache_error_i_int = icache_error_i;
    assign icache_inst_i_int = icache_inst_i;
    assign icache_page_fault_i_int = icache_page_fault_i;
    assign fetch_invalidate_i_int = fetch_invalidate_i;
    assign branch_request_i_int = branch_request_i;
    assign branch_pc_i_int = branch_pc_i;
    assign branch_priv_i_int = branch_priv_i;
    assign next_pc_f_i_int = next_pc_f_i;
    assign next_taken_f_i_int = next_taken_f_i;
    assign fetch_valid_o = fetch_valid_o_int;
    assign fetch_instr_o = fetch_instr_o_int;
    assign fetch_pred_branch_o = fetch_pred_branch_o_int;
    assign fetch_fault_fetch_o = fetch_fault_fetch_o_int;
    assign fetch_fault_page_o = fetch_fault_page_o_int;
    assign fetch_pc_o = fetch_pc_o_int;
    assign icache_rd_o = icache_rd_o_int;
    assign icache_flush_o = icache_flush_o_int;
    assign icache_invalidate_o = icache_invalidate_o_int;
    assign icache_pc_o = icache_pc_o_int;
    assign icache_priv_o = icache_priv_o_int;
    assign pc_f_o = pc_f_o_int;
    assign pc_accept_o = pc_accept_o_int;
end
endgenerate





//-------------------------------------------------------------
// Registers / Wires
//-------------------------------------------------------------
reg         active_q;

wire        icache_busy_w;
wire        stall_w       = !fetch_accept_i_int || icache_busy_w || !icache_accept_i_int;

//-------------------------------------------------------------
// Buffered branch
//-------------------------------------------------------------
reg         branch_q;
reg [31:0]  branch_pc_q;
reg [1:0]   branch_priv_q;

wire        branch_w;
wire [31:0] branch_pc_w;
wire [1:0]  branch_priv_w;

generate
if (SUPPORT_MMU)
begin
    assign branch_w      = branch_q;
    assign branch_pc_w   = branch_pc_q;
    assign branch_priv_w = branch_priv_q;
    
    always @ (posedge clk_i or posedge rst_i)
    if (rst_i)
    begin
        branch_q       <= 1'b0;
        branch_pc_q    <= 32'b0;
        branch_priv_q  <= `PRIV_MACHINE;
    end
    else if (branch_request_i_int)
    begin
        branch_q       <= 1'b1;
        branch_pc_q    <= branch_pc_i_int;
        branch_priv_q  <= branch_priv_i_int;
    end
    else if (icache_rd_o_int && icache_accept_i_int)
    begin
        branch_q       <= 1'b0;
        branch_pc_q    <= 32'b0;
    end
end
else
begin
    assign branch_w      = branch_q || branch_request_i_int;
    assign branch_pc_w   = (branch_q & !branch_request_i_int) ? branch_pc_q   : branch_pc_i_int;
    assign branch_priv_w = `PRIV_MACHINE; // don't care

    always @ (posedge clk_i or posedge rst_i)
    if (rst_i)
    begin
        branch_q       <= 1'b0;
        branch_pc_q    <= 32'b0;
    end
    else if (branch_request_i_int && (icache_busy_w || !active_q))
    begin
        branch_q       <= branch_w;
        branch_pc_q    <= branch_pc_w;
    end
    else if (~icache_busy_w)
    begin
        branch_q       <= 1'b0;
        branch_pc_q    <= 32'b0;
    end

end
endgenerate

//-------------------------------------------------------------
// Active flag
//-------------------------------------------------------------
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    active_q    <= 1'b0;
else if (SUPPORT_MMU && branch_w && ~stall_w)
    active_q    <= 1'b1;
else if (!SUPPORT_MMU && branch_w)
    active_q    <= 1'b1;

//-------------------------------------------------------------
// Stall flag
//-------------------------------------------------------------
reg stall_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    stall_q    <= 1'b0;
else
    stall_q    <= stall_w;

//-------------------------------------------------------------
// Request tracking
//-------------------------------------------------------------
reg icache_fetch_q;
reg icache_invalidate_q;

// ICACHE fetch tracking
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    icache_fetch_q <= 1'b0;
else if (icache_rd_o_int && icache_accept_i_int)
    icache_fetch_q <= 1'b1;
else if (icache_valid_i_int)
    icache_fetch_q <= 1'b0;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    icache_invalidate_q <= 1'b0;
else if (icache_invalidate_o_int && !icache_accept_i_int)
    icache_invalidate_q <= 1'b1;
else
    icache_invalidate_q <= 1'b0;

//-------------------------------------------------------------
// PC
//-------------------------------------------------------------
reg [31:0]  pc_f_q;
reg [31:0]  pc_d_q;
reg [1:0]   pred_d_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    pc_f_q  <= 32'b0;
// Branch request
else if (SUPPORT_MMU && branch_w && ~stall_w)
    pc_f_q  <= branch_pc_w;
else if (!SUPPORT_MMU && (stall_w || !active_q || stall_q) && branch_w)
    pc_f_q  <= branch_pc_w;
// NPC
else if (!stall_w)
    pc_f_q  <= next_pc_f_i_int;

wire [31:0] icache_pc_w;
wire [1:0]  icache_priv_w;
wire        fetch_resp_drop_w;

generate
if (SUPPORT_MMU)
begin
    reg [1:0] priv_f_q;
    reg       branch_d_q;

    always @ (posedge clk_i or posedge rst_i)
    if (rst_i)
        priv_f_q  <= `PRIV_MACHINE;
    // Branch request
    else if (branch_w && ~stall_w)
        priv_f_q  <= branch_priv_w;

    always @ (posedge clk_i or posedge rst_i)
    if (rst_i)
        branch_d_q  <= 1'b0;
    // Branch request
    else if (branch_w && ~stall_w)
        branch_d_q  <= 1'b1;
    // NPC
    else if (!stall_w)
        branch_d_q  <= 1'b0;

    assign icache_pc_w       = pc_f_q;
    assign icache_priv_w     = priv_f_q;
    assign fetch_resp_drop_w = branch_w | branch_d_q;
end
else
begin
    assign icache_pc_w       = (branch_w & ~stall_q) ? branch_pc_w : pc_f_q;
    assign icache_priv_w     = `PRIV_MACHINE; // Don't care
    assign fetch_resp_drop_w = branch_w;
end
endgenerate

// Last fetch address
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    pc_d_q <= 32'b0;
else if (icache_rd_o_int && icache_accept_i_int)
    pc_d_q <= icache_pc_w;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    pred_d_q <= 2'b0;
else if (icache_rd_o_int && icache_accept_i_int)
    pred_d_q <= next_taken_f_i_int;
else if (icache_valid_i_int)
    pred_d_q <= 2'b0;

//-------------------------------------------------------------
// Outputs
//-------------------------------------------------------------
assign icache_rd_o_int         = active_q & fetch_accept_i_int & !icache_busy_w;
assign icache_pc_o_int         = {icache_pc_w[31:3],3'b0};
assign icache_priv_o_int       = icache_priv_w;
assign icache_flush_o_int      = fetch_invalidate_i_int | icache_invalidate_q;
assign icache_invalidate_o_int = 1'b0;

assign icache_busy_w       =  icache_fetch_q && !icache_valid_i_int;

//-------------------------------------------------------------
// Response Buffer
//-------------------------------------------------------------
reg [99:0]  skid_buffer_q;
reg         skid_valid_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    skid_buffer_q  <= 100'b0;
    skid_valid_q   <= 1'b0;
end 
// Instruction output back-pressured - hold in skid buffer
else if (fetch_valid_o_int && !fetch_accept_i_int)
begin
    skid_valid_q  <= 1'b1;
    skid_buffer_q <= {fetch_fault_page_o_int, fetch_fault_fetch_o_int, fetch_pred_branch_o_int, fetch_pc_o_int, fetch_instr_o_int};
end
else
begin
    skid_valid_q  <= 1'b0;
    skid_buffer_q <= 100'b0;
end

assign fetch_valid_o_int       = (icache_valid_i_int || skid_valid_q) & !fetch_resp_drop_w;
assign fetch_pc_o_int          = skid_valid_q ? skid_buffer_q[95:64] : {pc_d_q[31:3],3'b0};
assign fetch_instr_o_int       = skid_valid_q ? skid_buffer_q[63:0]  : icache_inst_i_int;
assign fetch_pred_branch_o_int = skid_valid_q ? skid_buffer_q[97:96] : pred_d_q;

// Faults
assign fetch_fault_fetch_o_int = skid_valid_q ? skid_buffer_q[98] : icache_error_i_int;
assign fetch_fault_page_o_int  = skid_valid_q ? skid_buffer_q[99] : icache_page_fault_i_int;

assign pc_f_o_int              = icache_pc_w;
assign pc_accept_o_int         = ~stall_w;



endmodule
