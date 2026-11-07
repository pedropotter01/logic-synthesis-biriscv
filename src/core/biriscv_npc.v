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

module biriscv_npc
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SUPPORT_BRANCH_PREDICTION = 1
    ,parameter NUM_BTB_ENTRIES  = 32
    ,parameter NUM_BTB_ENTRIES_W = 5
    ,parameter NUM_BHT_ENTRIES  = 512
    ,parameter NUM_BHT_ENTRIES_W = 9
    ,parameter RAS_ENABLE       = 1
    ,parameter GSHARE_ENABLE    = 1
    ,parameter BHT_ENABLE       = 1
    ,parameter NUM_RAS_ENTRIES  = 8
    ,parameter NUM_RAS_ENTRIES_W = 3
    ,parameter SYNTH_MODE_ISO = 0 // 1: register all I/Os (standalone synthesis only)
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           invalidate_i
    ,input           branch_request_i
    ,input           branch_is_taken_i
    ,input           branch_is_not_taken_i
    ,input  [ 31:0]  branch_source_i
    ,input           branch_is_call_i
    ,input           branch_is_ret_i
    ,input           branch_is_jmp_i
    ,input  [ 31:0]  branch_pc_i
    ,input  [ 31:0]  pc_f_i
    ,input           pc_accept_i

    // Outputs
    ,output [ 31:0]  next_pc_f_o
    ,output [  1:0]  next_taken_f_o
);

//-----------------------------------------------------------------
// SYNTH_MODE_ISO: isolation register walls
//   SYNTH_MODE_ISO = 0 -> ports connected straight through (normal)
//   SYNTH_MODE_ISO = 1 -> every input and output (except clock/reset)
//                         is registered, so this module can be
//                         synthesized and timed standalone.
//-----------------------------------------------------------------
// Internal (module side) view of the ports
wire                  invalidate_i_int;
wire                  branch_request_i_int;
wire                  branch_is_taken_i_int;
wire                  branch_is_not_taken_i_int;
wire [ 31:0]          branch_source_i_int;
wire                  branch_is_call_i_int;
wire                  branch_is_ret_i_int;
wire                  branch_is_jmp_i_int;
wire [ 31:0]          branch_pc_i_int;
wire [ 31:0]          pc_f_i_int;
wire                  pc_accept_i_int;
wire [ 31:0]          next_pc_f_o_int;
wire [  1:0]          next_taken_f_o_int;

generate
if (SYNTH_MODE_ISO)
begin : g_synth_iso
    // Input register wall
    reg                   invalidate_i_iso_q;
    reg                   branch_request_i_iso_q;
    reg                   branch_is_taken_i_iso_q;
    reg                   branch_is_not_taken_i_iso_q;
    reg  [ 31:0]          branch_source_i_iso_q;
    reg                   branch_is_call_i_iso_q;
    reg                   branch_is_ret_i_iso_q;
    reg                   branch_is_jmp_i_iso_q;
    reg  [ 31:0]          branch_pc_i_iso_q;
    reg  [ 31:0]          pc_f_i_iso_q;
    reg                   pc_accept_i_iso_q;

    always @ (posedge clk_i)
    begin
        invalidate_i_iso_q <= invalidate_i;
        branch_request_i_iso_q <= branch_request_i;
        branch_is_taken_i_iso_q <= branch_is_taken_i;
        branch_is_not_taken_i_iso_q <= branch_is_not_taken_i;
        branch_source_i_iso_q <= branch_source_i;
        branch_is_call_i_iso_q <= branch_is_call_i;
        branch_is_ret_i_iso_q <= branch_is_ret_i;
        branch_is_jmp_i_iso_q <= branch_is_jmp_i;
        branch_pc_i_iso_q <= branch_pc_i;
        pc_f_i_iso_q <= pc_f_i;
        pc_accept_i_iso_q <= pc_accept_i;
    end

    assign invalidate_i_int = invalidate_i_iso_q;
    assign branch_request_i_int = branch_request_i_iso_q;
    assign branch_is_taken_i_int = branch_is_taken_i_iso_q;
    assign branch_is_not_taken_i_int = branch_is_not_taken_i_iso_q;
    assign branch_source_i_int = branch_source_i_iso_q;
    assign branch_is_call_i_int = branch_is_call_i_iso_q;
    assign branch_is_ret_i_int = branch_is_ret_i_iso_q;
    assign branch_is_jmp_i_int = branch_is_jmp_i_iso_q;
    assign branch_pc_i_int = branch_pc_i_iso_q;
    assign pc_f_i_int = pc_f_i_iso_q;
    assign pc_accept_i_int = pc_accept_i_iso_q;

    // Output register wall
    reg  [ 31:0]          next_pc_f_o_iso_q;
    reg  [  1:0]          next_taken_f_o_iso_q;

    always @ (posedge clk_i)
    begin
        next_pc_f_o_iso_q <= next_pc_f_o_int;
        next_taken_f_o_iso_q <= next_taken_f_o_int;
    end

    assign next_pc_f_o = next_pc_f_o_iso_q;
    assign next_taken_f_o = next_taken_f_o_iso_q;
end
else
begin : g_synth_no_iso
    assign invalidate_i_int = invalidate_i;
    assign branch_request_i_int = branch_request_i;
    assign branch_is_taken_i_int = branch_is_taken_i;
    assign branch_is_not_taken_i_int = branch_is_not_taken_i;
    assign branch_source_i_int = branch_source_i;
    assign branch_is_call_i_int = branch_is_call_i;
    assign branch_is_ret_i_int = branch_is_ret_i;
    assign branch_is_jmp_i_int = branch_is_jmp_i;
    assign branch_pc_i_int = branch_pc_i;
    assign pc_f_i_int = pc_f_i;
    assign pc_accept_i_int = pc_accept_i;
    assign next_pc_f_o = next_pc_f_o_int;
    assign next_taken_f_o = next_taken_f_o_int;
end
endgenerate





localparam RAS_INVALID = 32'h00000001;

//-----------------------------------------------------------------
// Branch prediction (BTB, BHT, RAS)
//-----------------------------------------------------------------
generate
if (SUPPORT_BRANCH_PREDICTION)
begin: BRANCH_PREDICTION

wire        pred_taken_w;
wire        pred_ntaken_w;

// Info from BTB
wire        btb_valid_w;
wire        btb_upper_w;
wire [31:0] btb_next_pc_w;
wire        btb_is_call_w;
wire        btb_is_ret_w;

//-----------------------------------------------------------------
// Return Address Stack (actual)
//-----------------------------------------------------------------
reg [NUM_RAS_ENTRIES_W-1:0] ras_index_real_q;
reg [NUM_RAS_ENTRIES_W-1:0] ras_index_real_r;

always @ *
begin
    ras_index_real_r = ras_index_real_q;

    if (branch_request_i_int & branch_is_call_i_int)
        ras_index_real_r = ras_index_real_q + 1;
    else if (branch_request_i_int & branch_is_ret_i_int)
        ras_index_real_r = ras_index_real_q - 1;
end

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    ras_index_real_q <= {NUM_RAS_ENTRIES_W{1'b0}};
else
    ras_index_real_q <= ras_index_real_r;

//-----------------------------------------------------------------
// Return Address Stack (speculative)
//-----------------------------------------------------------------
reg [31:0] ras_stack_q[NUM_RAS_ENTRIES-1:0];
reg [NUM_RAS_ENTRIES_W-1:0] ras_index_q;

reg [NUM_RAS_ENTRIES_W-1:0] ras_index_r;

wire [31:0] ras_pc_pred_w   = ras_stack_q[ras_index_q];
wire        ras_call_pred_w = RAS_ENABLE & (btb_valid_w & btb_is_call_w) & ~ras_pc_pred_w[0];
wire        ras_ret_pred_w  = RAS_ENABLE & (btb_valid_w & btb_is_ret_w) & ~ras_pc_pred_w[0];

always @ *
begin
    ras_index_r = ras_index_q;

    // Mispredict - go from confirmed call stack index
    if (branch_request_i_int & branch_is_call_i_int)
        ras_index_r = ras_index_real_q + 1;
    else if (branch_request_i_int & branch_is_ret_i_int)
        ras_index_r = ras_index_real_q - 1;
    // Speculative call / returns
    else if (ras_call_pred_w & pc_accept_i_int)
        ras_index_r = ras_index_q + 1;
    else if (ras_ret_pred_w & pc_accept_i_int)
        ras_index_r = ras_index_q - 1;
end

integer i3;
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    for (i3 = 0; i3 < NUM_RAS_ENTRIES; i3 = i3 + 1) 
    begin
        ras_stack_q[i3] <= RAS_INVALID;
    end

    ras_index_q <= {NUM_RAS_ENTRIES_W{1'b0}};
end
// On a call push return address onto RAS stack (current PC + 4)
else if (branch_request_i_int & branch_is_call_i_int)
begin
    ras_stack_q[ras_index_r] <= branch_source_i_int + 32'd4;
    ras_index_q              <= ras_index_r;
end
// On a call push return address onto RAS stack (current PC + 4)
else if (ras_call_pred_w & pc_accept_i_int)
begin
    ras_stack_q[ras_index_r] <= (btb_upper_w ? (pc_f_i_int | 32'd4) : pc_f_i_int) + 32'd4;
    ras_index_q              <= ras_index_r;
end
// Return - pop item from stack
else if ((ras_ret_pred_w & pc_accept_i_int) || (branch_request_i_int & branch_is_ret_i_int))
begin
    ras_index_q              <= ras_index_r;
end

//-----------------------------------------------------------------
// Global history register (actual history)
//-----------------------------------------------------------------
reg [NUM_BHT_ENTRIES_W-1:0] global_history_real_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    global_history_real_q <= {NUM_BHT_ENTRIES_W{1'b0}};
else if (branch_is_taken_i_int || branch_is_not_taken_i_int)
    global_history_real_q <= {global_history_real_q[NUM_BHT_ENTRIES_W-2:0], branch_is_taken_i_int};

//-----------------------------------------------------------------
// Global history register (speculative)
//-----------------------------------------------------------------
reg [NUM_BHT_ENTRIES_W-1:0] global_history_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    global_history_q <= {NUM_BHT_ENTRIES_W{1'b0}};
// Mispredict - revert to actual branch history to flush out speculative errors
else if (branch_request_i_int)
    global_history_q <= {global_history_real_q[NUM_BHT_ENTRIES_W-2:0], branch_is_taken_i_int};
// Predicted branch
else if (pred_taken_w || pred_ntaken_w)
    global_history_q <= {global_history_q[NUM_BHT_ENTRIES_W-2:0], pred_taken_w};

wire [NUM_BHT_ENTRIES_W-1:0] gshare_wr_entry_w = (branch_request_i_int ? global_history_real_q : global_history_q) ^ branch_source_i_int[2+NUM_BHT_ENTRIES_W-1:2];
wire [NUM_BHT_ENTRIES_W-1:0] gshare_rd_entry_w = global_history_q ^ {pc_f_i_int[3+NUM_BHT_ENTRIES_W-2:3],btb_upper_w};

//-----------------------------------------------------------------
// Branch prediction bits
//-----------------------------------------------------------------
reg [2:0]                    bht_sat_q[NUM_BHT_ENTRIES-1:0];

wire [NUM_BHT_ENTRIES_W-1:0] bht_wr_entry_w = GSHARE_ENABLE ? gshare_wr_entry_w : branch_source_i_int[2+NUM_BHT_ENTRIES_W-1:2];
wire [NUM_BHT_ENTRIES_W-1:0] bht_rd_entry_w = GSHARE_ENABLE ? gshare_rd_entry_w : {pc_f_i_int[3+NUM_BHT_ENTRIES_W-2:3],btb_upper_w};

integer i4;
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    for (i4 = 0; i4 < NUM_BHT_ENTRIES; i4 = i4 + 1)
    begin
        bht_sat_q[i4] <= 3'd4; // weakly taken start
    end
end
else if (branch_is_taken_i_int && bht_sat_q[bht_wr_entry_w] < 3'd7)
    bht_sat_q[bht_wr_entry_w] <= bht_sat_q[bht_wr_entry_w] + 3'd1;
else if (branch_is_not_taken_i_int && bht_sat_q[bht_wr_entry_w] > 3'd0)
    bht_sat_q[bht_wr_entry_w] <= bht_sat_q[bht_wr_entry_w] - 3'd1;

wire bht_predict_taken_w = BHT_ENABLE && bht_sat_q[bht_rd_entry_w][2]; // if msb is 1, it's taken

//-----------------------------------------------------------------
// Branch target buffer
//-----------------------------------------------------------------
reg [31:0]  btb_pc_q[NUM_BTB_ENTRIES-1:0];
reg [31:0]  btb_target_q[NUM_BTB_ENTRIES-1:0];
reg         btb_is_call_q[NUM_BTB_ENTRIES-1:0];
reg         btb_is_ret_q[NUM_BTB_ENTRIES-1:0];
reg         btb_is_jmp_q[NUM_BTB_ENTRIES-1:0];

reg         btb_valid_r;
reg         btb_upper_r;
reg         btb_is_call_r;
reg         btb_is_ret_r;
reg [31:0]  btb_next_pc_r;
reg         btb_is_jmp_r;

reg [NUM_BTB_ENTRIES_W-1:0] btb_entry_r;
integer i0;

always @ *
begin
    btb_valid_r   = 1'b0;
    btb_upper_r   = 1'b0;
    btb_is_call_r = 1'b0;
    btb_is_ret_r  = 1'b0;
    btb_is_jmp_r  = 1'b0;
    btb_next_pc_r = {pc_f_i_int[31:3],3'b0} + 32'd8;
    btb_entry_r   = {NUM_BTB_ENTRIES_W{1'b0}};

    for (i0 = 0; i0 < NUM_BTB_ENTRIES; i0 = i0 + 1)
    begin
        if (btb_pc_q[i0] == pc_f_i_int)
        begin
            btb_valid_r   = 1'b1;
            btb_upper_r   = pc_f_i_int[2];
            btb_is_call_r = btb_is_call_q[i0];
            btb_is_ret_r  = btb_is_ret_q[i0];
            btb_is_jmp_r  = btb_is_jmp_q[i0];
            btb_next_pc_r = btb_target_q[i0];
/* verilator lint_off WIDTH */
            btb_entry_r   = i0;
/* verilator lint_on WIDTH */
        end
    end

    if (~btb_valid_r && ~pc_f_i_int[2])
        for (i0 = 0; i0 < NUM_BTB_ENTRIES; i0 = i0 + 1)
        begin
            if (btb_pc_q[i0] == (pc_f_i_int | 32'd4))
            begin
                btb_valid_r   = 1'b1;
                btb_upper_r   = 1'b1;
                btb_is_call_r = btb_is_call_q[i0];
                btb_is_ret_r  = btb_is_ret_q[i0];
                btb_is_jmp_r  = btb_is_jmp_q[i0];
                btb_next_pc_r = btb_target_q[i0];
/* verilator lint_off WIDTH */
                btb_entry_r   = i0;
/* verilator lint_on WIDTH */
            end
        end
end

reg [NUM_BTB_ENTRIES_W-1:0]  btb_wr_entry_r;
wire [NUM_BTB_ENTRIES_W-1:0] btb_wr_alloc_w;

reg btb_hit_r;
reg btb_miss_r;
integer i1;
always @ *
begin
    btb_wr_entry_r = {NUM_BTB_ENTRIES_W{1'b0}};
    btb_hit_r      = 1'b0;
    btb_miss_r     = 1'b0;

    // Misprediction - learn / update branch details
    if (branch_request_i_int)
    begin
        for (i1 = 0; i1 < NUM_BTB_ENTRIES; i1 = i1 + 1)
        begin
            if (btb_pc_q[i1] == branch_source_i_int)
            begin
                btb_hit_r      = 1'b1;
    /* verilator lint_off WIDTH */
                btb_wr_entry_r = i1;
    /* verilator lint_on WIDTH */
            end
        end
        btb_miss_r = ~btb_hit_r;
    end
end

integer i2;
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    for (i2 = 0; i2 < NUM_BTB_ENTRIES; i2 = i2 + 1)
    begin
        btb_pc_q[i2]     <= 32'b0;
        btb_target_q[i2] <= 32'b0;
        btb_is_call_q[i2]<= 1'b0;
        btb_is_ret_q[i2] <= 1'b0;
        btb_is_jmp_q[i2] <= 1'b0;
    end
end
// Hit - update entry
else if (btb_hit_r)
begin
    btb_pc_q[btb_wr_entry_r]     <= branch_source_i_int;
    if (branch_is_taken_i_int)
        btb_target_q[btb_wr_entry_r] <= branch_pc_i_int;
    btb_is_call_q[btb_wr_entry_r]<= branch_is_call_i_int;
    btb_is_ret_q[btb_wr_entry_r] <= branch_is_ret_i_int;
    btb_is_jmp_q[btb_wr_entry_r] <= branch_is_jmp_i_int;
end
// Miss - allocate entry
else if (btb_miss_r)
begin
    btb_pc_q[btb_wr_alloc_w]     <= branch_source_i_int;
    btb_target_q[btb_wr_alloc_w] <= branch_pc_i_int;
    btb_is_call_q[btb_wr_alloc_w]<= branch_is_call_i_int;
    btb_is_ret_q[btb_wr_alloc_w] <= branch_is_ret_i_int;
    btb_is_jmp_q[btb_wr_alloc_w] <= branch_is_jmp_i_int;
end

//-----------------------------------------------------------------
// Replacement Selection
//-----------------------------------------------------------------
biriscv_npc_lfsr
#(
    .DEPTH(NUM_BTB_ENTRIES)
   ,.ADDR_W(NUM_BTB_ENTRIES_W)
)
u_lru
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.hit_i(btb_valid_r)
    ,.hit_entry_i(btb_entry_r)

    ,.alloc_i(btb_miss_r)
    ,.alloc_entry_o(btb_wr_alloc_w)
);

//-----------------------------------------------------------------
// Outputs
//-----------------------------------------------------------------
assign btb_valid_w   = btb_valid_r;
assign btb_upper_w   = btb_upper_r;
assign btb_is_call_w = btb_is_call_r;
assign btb_is_ret_w  = btb_is_ret_r;
assign next_pc_f_o_int   = ras_ret_pred_w      ? ras_pc_pred_w : 
                       (bht_predict_taken_w | btb_is_jmp_r) ? btb_next_pc_r :
                       {pc_f_i_int[31:3],3'b0} + 32'd8;

assign next_taken_f_o_int = (btb_valid_w & (ras_ret_pred_w | bht_predict_taken_w | btb_is_jmp_r)) ? 
                        pc_f_i_int[2] ? {btb_upper_r, 1'b0} :
                        {btb_upper_r, ~btb_upper_r} : 2'b0;

assign pred_taken_w   = btb_valid_w & (ras_ret_pred_w | bht_predict_taken_w | btb_is_jmp_r) & pc_accept_i_int;
assign pred_ntaken_w  = btb_valid_w & ~pred_taken_w & pc_accept_i_int;


end
//-----------------------------------------------------------------
// No branch prediction
//-----------------------------------------------------------------
else
begin: NO_BRANCH_PREDICTION

assign next_pc_f_o_int    = {pc_f_i_int[31:3],3'b0} + 32'd8;
assign next_taken_f_o_int = 2'b0;

end
endgenerate

endmodule


module biriscv_npc_lfsr
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter DEPTH            = 32
    ,parameter ADDR_W           = 5
    ,parameter INITIAL_VALUE    = 16'h0001
    ,parameter TAP_VALUE        = 16'hB400
    ,parameter SYNTH_MODE_ISO = 0 // 1: register all I/Os (standalone synthesis only)
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           hit_i
    ,input  [ADDR_W-1:0]  hit_entry_i
    ,input           alloc_i

    // Outputs
    ,output [ADDR_W-1:0]  alloc_entry_o
);

//-----------------------------------------------------------------
// SYNTH_MODE_ISO: isolation register walls
//   SYNTH_MODE_ISO = 0 -> ports connected straight through (normal)
//   SYNTH_MODE_ISO = 1 -> every input and output (except clock/reset)
//                         is registered, so this module can be
//                         synthesized and timed standalone.
//-----------------------------------------------------------------
// Internal (module side) view of the ports
wire                  hit_i_int;
wire [ADDR_W-1:0]     hit_entry_i_int;
wire                  alloc_i_int;
wire [ADDR_W-1:0]     alloc_entry_o_int;

generate
if (SYNTH_MODE_ISO)
begin : g_synth_iso
    // Input register wall
    reg                   hit_i_iso_q;
    reg  [ADDR_W-1:0]     hit_entry_i_iso_q;
    reg                   alloc_i_iso_q;

    always @ (posedge clk_i)
    begin
        hit_i_iso_q <= hit_i;
        hit_entry_i_iso_q <= hit_entry_i;
        alloc_i_iso_q <= alloc_i;
    end

    assign hit_i_int = hit_i_iso_q;
    assign hit_entry_i_int = hit_entry_i_iso_q;
    assign alloc_i_int = alloc_i_iso_q;

    // Output register wall
    reg  [ADDR_W-1:0]     alloc_entry_o_iso_q;

    always @ (posedge clk_i)
    begin
        alloc_entry_o_iso_q <= alloc_entry_o_int;
    end

    assign alloc_entry_o = alloc_entry_o_iso_q;
end
else
begin : g_synth_no_iso
    assign hit_i_int = hit_i;
    assign hit_entry_i_int = hit_entry_i;
    assign alloc_i_int = alloc_i;
    assign alloc_entry_o = alloc_entry_o_int;
end
endgenerate



//-----------------------------------------------------------------
// Scheme: LFSR
//-----------------------------------------------------------------
reg [15:0] lfsr_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    lfsr_q <= INITIAL_VALUE;
else if (alloc_i_int)
begin
    if (lfsr_q[0])
        lfsr_q <= {1'b0, lfsr_q[15:1]} ^ TAP_VALUE;
    else
        lfsr_q <= {1'b0, lfsr_q[15:1]};
end

assign alloc_entry_o_int = lfsr_q[ADDR_W-1:0];





endmodule
