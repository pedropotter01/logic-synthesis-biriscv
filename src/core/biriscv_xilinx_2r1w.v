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
//-----------------------------------------------------------------
// Module - Xilinx register file (2 async read, 1 write port)
//-----------------------------------------------------------------
module biriscv_xilinx_2r1w
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
    ,input  [  4:0]  rd0_i
    ,input  [ 31:0]  rd0_value_i
    ,input  [  4:0]  ra_i
    ,input  [  4:0]  rb_i

    // Outputs
    ,output [ 31:0]  ra_value_o
    ,output [ 31:0]  rb_value_o
);

//-----------------------------------------------------------------
// SYNTH_MODE_ISO: isolation register walls
//   SYNTH_MODE_ISO = 0 -> ports connected straight through (normal)
//   SYNTH_MODE_ISO = 1 -> every input and output (except clock/reset)
//                         is registered, so this module can be
//                         synthesized and timed standalone.
//-----------------------------------------------------------------
// Internal (module side) view of the ports
wire [  4:0]          rd0_i_int;
wire [ 31:0]          rd0_value_i_int;
wire [  4:0]          ra_i_int;
wire [  4:0]          rb_i_int;
wire [ 31:0]          ra_value_o_int;
wire [ 31:0]          rb_value_o_int;

generate
if (SYNTH_MODE_ISO)
begin : g_synth_iso
    // Input register wall
    reg  [  4:0]          rd0_i_iso_q;
    reg  [ 31:0]          rd0_value_i_iso_q;
    reg  [  4:0]          ra_i_iso_q;
    reg  [  4:0]          rb_i_iso_q;

    always @ (posedge clk_i)
    begin
        rd0_i_iso_q <= rd0_i;
        rd0_value_i_iso_q <= rd0_value_i;
        ra_i_iso_q <= ra_i;
        rb_i_iso_q <= rb_i;
    end

    assign rd0_i_int = rd0_i_iso_q;
    assign rd0_value_i_int = rd0_value_i_iso_q;
    assign ra_i_int = ra_i_iso_q;
    assign rb_i_int = rb_i_iso_q;

    // Output register wall
    reg  [ 31:0]          ra_value_o_iso_q;
    reg  [ 31:0]          rb_value_o_iso_q;

    always @ (posedge clk_i)
    begin
        ra_value_o_iso_q <= ra_value_o_int;
        rb_value_o_iso_q <= rb_value_o_int;
    end

    assign ra_value_o = ra_value_o_iso_q;
    assign rb_value_o = rb_value_o_iso_q;
end
else
begin : g_synth_no_iso
    assign rd0_i_int = rd0_i;
    assign rd0_value_i_int = rd0_value_i;
    assign ra_i_int = ra_i;
    assign rb_i_int = rb_i;
    assign ra_value_o = ra_value_o_int;
    assign rb_value_o = rb_value_o_int;
end
endgenerate




//-----------------------------------------------------------------
// Registers / Wires
//-----------------------------------------------------------------
wire [31:0]     reg_rs1_w;
wire [31:0]     reg_rs2_w;
wire [31:0]     rs1_0_15_w;
wire [31:0]     rs1_16_31_w;
wire [31:0]     rs2_0_15_w;
wire [31:0]     rs2_16_31_w;
wire            write_enable_w;
wire            write_banka_w;
wire            write_bankb_w;

//-----------------------------------------------------------------
// Register File (using RAM16X1D )
//-----------------------------------------------------------------
genvar i;

// Registers 0 - 15
generate
for (i=0;i<32;i=i+1)
begin : reg_loop1
    RAM16X1D reg_bit1a(.WCLK(clk_i), .WE(write_banka_w), .A0(rd0_i_int[0]), .A1(rd0_i_int[1]), .A2(rd0_i_int[2]), .A3(rd0_i_int[3]), .D(rd0_value_i_int[i]), .DPRA0(ra_i_int[0]), .DPRA1(ra_i_int[1]), .DPRA2(ra_i_int[2]), .DPRA3(ra_i_int[3]), .DPO(rs1_0_15_w[i]), .SPO(/* open */));
    RAM16X1D reg_bit2a(.WCLK(clk_i), .WE(write_banka_w), .A0(rd0_i_int[0]), .A1(rd0_i_int[1]), .A2(rd0_i_int[2]), .A3(rd0_i_int[3]), .D(rd0_value_i_int[i]), .DPRA0(rb_i_int[0]), .DPRA1(rb_i_int[1]), .DPRA2(rb_i_int[2]), .DPRA3(rb_i_int[3]), .DPO(rs2_0_15_w[i]), .SPO(/* open */));
end
endgenerate

// Registers 16 - 31
generate
for (i=0;i<32;i=i+1)
begin : reg_loop2
    RAM16X1D reg_bit1b(.WCLK(clk_i), .WE(write_bankb_w), .A0(rd0_i_int[0]), .A1(rd0_i_int[1]), .A2(rd0_i_int[2]), .A3(rd0_i_int[3]), .D(rd0_value_i_int[i]), .DPRA0(ra_i_int[0]), .DPRA1(ra_i_int[1]), .DPRA2(ra_i_int[2]), .DPRA3(ra_i_int[3]), .DPO(rs1_16_31_w[i]), .SPO(/* open */));
    RAM16X1D reg_bit2b(.WCLK(clk_i), .WE(write_bankb_w), .A0(rd0_i_int[0]), .A1(rd0_i_int[1]), .A2(rd0_i_int[2]), .A3(rd0_i_int[3]), .D(rd0_value_i_int[i]), .DPRA0(rb_i_int[0]), .DPRA1(rb_i_int[1]), .DPRA2(rb_i_int[2]), .DPRA3(rb_i_int[3]), .DPO(rs2_16_31_w[i]), .SPO(/* open */));
end
endgenerate

//-----------------------------------------------------------------
// Combinatorial Assignments
//-----------------------------------------------------------------
assign reg_rs1_w       = (ra_i_int[4] == 1'b0) ? rs1_0_15_w : rs1_16_31_w;
assign reg_rs2_w       = (rb_i_int[4] == 1'b0) ? rs2_0_15_w : rs2_16_31_w;

assign write_enable_w = (rd0_i_int != 5'b00000);

assign write_banka_w  = (write_enable_w & (~rd0_i_int[4]));
assign write_bankb_w  = (write_enable_w & rd0_i_int[4]);

reg [31:0] ra_value_r;
reg [31:0] rb_value_r;

// Register read ports
always @ *
begin
    if (ra_i_int == 5'b00000)
        ra_value_r = 32'h00000000;
    else
        ra_value_r = reg_rs1_w;

    if (rb_i_int == 5'b00000)
        rb_value_r = 32'h00000000;
    else
        rb_value_r = reg_rs2_w;
end

assign ra_value_o_int = ra_value_r;
assign rb_value_o_int = rb_value_r;

endmodule

//-------------------------------------------------------------
// RAM16X1D: Verilator target RAM16X1D model
//-------------------------------------------------------------
`ifdef verilator
module RAM16X1D (DPO, SPO, A0, A1, A2, A3, D, DPRA0, DPRA1, DPRA2, DPRA3, WCLK, WE);

    parameter INIT = 16'h0000;

    output DPO, SPO;

    input  A0, A1, A2, A3, D, DPRA0, DPRA1, DPRA2, DPRA3, WCLK, WE;

    reg  [15:0] mem;
    wire [3:0] adr;

    assign adr = {A3, A2, A1, A0};
    assign SPO = mem[adr];
    assign DPO = mem[{DPRA3, DPRA2, DPRA1, DPRA0}];

    initial 
        mem = INIT;

    always @(posedge WCLK) 
        if (WE == 1'b1)
            mem[adr] <= D;

endmodule
`endif
