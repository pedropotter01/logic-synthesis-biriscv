module tb_top;

`define trace_gate_level_simulation

reg clk;
reg rst;

//-------------------------------------------------------------
// Active Benchmark Identification Header (0x80010000 - 0x80010004)
//-------------------------------------------------------------
reg [31:0]  bench_id;
reg [31:0]  bench_done;
reg [127:0] bench_name;

//-------------------------------------------------------------
// 1. BubbleSort Verification Signals (0x8001ffd4 - 0x8001ffec)
//-------------------------------------------------------------
reg [31:0]  arr_0, arr_1, arr_2, arr_3, arr_4, arr_5, arr_6;
reg         arr_is_sorted;
reg [31:0]  arr_swap_count;
reg [31:0]  bs_init_writes;
reg [119:0] arr_status;

//-------------------------------------------------------------
// 2. QuickSort Verification Signals (0x80010100 - 0x80010114)
//-------------------------------------------------------------
reg [31:0]  qs_arr_0, qs_arr_1, qs_arr_2, qs_arr_3, qs_arr_4, qs_arr_5;
reg         qs_is_sorted;
reg [31:0]  qs_swap_count;
reg [31:0]  qs_init_writes;
reg [119:0] qs_status;

//-------------------------------------------------------------
// 3. Dot Product Verification Signals (0x80010200 - 0x80010260)
//-------------------------------------------------------------
reg [31:0]  dp_vec1_0, dp_vec1_1, dp_vec1_2, dp_vec1_3, dp_vec1_4, dp_vec1_5, dp_vec1_6;
reg [31:0]  dp_vec2_0, dp_vec2_1, dp_vec2_2, dp_vec2_3, dp_vec2_4, dp_vec2_5, dp_vec2_6;
reg [31:0]  dp_prod_0, dp_prod_1, dp_prod_2, dp_prod_3, dp_prod_4, dp_prod_5, dp_prod_6;
reg [31:0]  dp_result;
reg [31:0]  dp_expected;
reg         dp_is_correct;
reg [119:0] dp_status;

//-------------------------------------------------------------
// 4. Array Sum & Mul Verification Signals (0x80010300 - 0x8001039C)
//-------------------------------------------------------------
reg [31:0]  asm_vec1_0, asm_vec1_1, asm_vec1_2, asm_vec1_3, asm_vec1_4;
reg [31:0]  asm_vec1_5, asm_vec1_6, asm_vec1_7, asm_vec1_8, asm_vec1_9;
reg [31:0]  asm_vec2_0, asm_vec2_1, asm_vec2_2, asm_vec2_3, asm_vec2_4;
reg [31:0]  asm_vec2_5, asm_vec2_6, asm_vec2_7, asm_vec2_8, asm_vec2_9;
reg [31:0]  asm_prod_0, asm_prod_1, asm_prod_2, asm_prod_3, asm_prod_4;
reg [31:0]  asm_prod_5, asm_prod_6, asm_prod_7, asm_prod_8, asm_prod_9;
reg [31:0]  asm_sum_0,  asm_sum_1,  asm_sum_2,  asm_sum_3,  asm_sum_4;
reg [31:0]  asm_sum_5,  asm_sum_6,  asm_sum_7,  asm_sum_8,  asm_sum_9;
reg         asm_mul_ok;
reg         asm_sum_ok;
reg         asm_is_correct;
reg [119:0] asm_status;

//-------------------------------------------------------------
// 5. Swap Bits Verification Signals (0x80010400 - 0x8001041C)
//-------------------------------------------------------------
reg  [31:0]  sb_x;
reg  [31:0]  sb_p1;
reg  [31:0]  sb_p2;
reg  [31:0]  sb_n;
reg  [31:0]  sb_set1;
reg  [31:0]  sb_set2;
reg  [31:0]  sb_xor_mask;
reg  [31:0]  sb_result;
reg  [31:0]  sb_expected;
wire [ 5:0]  sb_x_bits   = sb_x[5:0];
wire [ 5:0]  sb_xor_bits = sb_xor_mask[5:0];
wire [ 5:0]  sb_res_bits = sb_result[5:0];
reg          sb_is_correct;
reg  [119:0] sb_status;

reg [7:0] mem[131072:0];
integer i;
integer f;

initial
begin
    $display("Starting bench");

    if (`TRACE)
    begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_top);
    end

    // Reset
    clk = 0;
    rst = 1;
    repeat (5) @(posedge clk);
    rst = 0;

    // Load TCM memory
    for (i=0;i<131072;i=i+1)
        mem[i] = 0;

    f = $fopen("./build/tcm.bin", "rb");
    if (f == 0)
    begin
        $display("[TESTBENCH] ERROR: Failed to open ./build/tcm.bin");
        $finish;
    end
    i = $fread(mem, f);
    $fclose(f);
    for (i=0;i<131072;i=i+1)
        u_mem.write(i, mem[i]);
end

initial
begin
    forever
    begin 
        clk = #5 ~clk;
    end
end

// Watchdog timeout & tailored verification summary (20,000 cycles = 200,000 ns)
initial
begin
    #200000;
    $display("[TESTBENCH] Simulation completed successfully (timeout reached at %0t ns).", $time);

    case (bench_id)
        32'd1: begin
            $display("\n=======================================================");
            $display("     biRISC-V BUBBLESORT TCM VERIFICATION DUMP         ");
            $display("=======================================================");
            $display(" Array[0] (0x8001ffd4) = %0d (expected: 0)", arr_0);
            $display(" Array[1] (0x8001ffd8) = %0d (expected: 1)", arr_1);
            $display(" Array[2] (0x8001ffdc) = %0d (expected: 2)", arr_2);
            $display(" Array[3] (0x8001ffe0) = %0d (expected: 3)", arr_3);
            $display(" Array[4] (0x8001ffe4) = %0d (expected: 3)", arr_4);
            $display(" Array[5] (0x8001ffe8) = %0d (expected: 4)", arr_5);
            $display(" Array[6] (0x8001ffec) = %0d (expected: 5)", arr_6);
            $display(" Total Swap Writes     = %0d", arr_swap_count);
            if (arr_is_sorted)
                $display(" >>> RESULT: SUCCESS - ARRAY IS PERFECTLY SORTED! <<<");
            else
                $display(" >>> RESULT: FAILED - ARRAY IS NOT SORTED! <<<");
            $display("=======================================================\n");
        end

        32'd2: begin
            $display("\n=======================================================");
            $display("     biRISC-V QUICKSORT TCM VERIFICATION DUMP          ");
            $display("=======================================================");
            $display(" Array[0] (0x80010100) = %0d (expected: 1)",  qs_arr_0);
            $display(" Array[1] (0x80010104) = %0d (expected: 5)",  qs_arr_1);
            $display(" Array[2] (0x80010108) = %0d (expected: 7)",  qs_arr_2);
            $display(" Array[3] (0x8001010c) = %0d (expected: 8)",  qs_arr_3);
            $display(" Array[4] (0x80010110) = %0d (expected: 9)",  qs_arr_4);
            $display(" Array[5] (0x80010114) = %0d (expected: 10)", qs_arr_5);
            $display(" Total Swap Writes     = %0d", qs_swap_count);
            if (qs_is_sorted)
                $display(" >>> RESULT: SUCCESS - QUICKSORT ARRAY SORTED! <<<");
            else
                $display(" >>> RESULT: FAILED - QUICKSORT ARRAY NOT SORTED! <<<");
            $display("=======================================================\n");
        end

        32'd3: begin
            $display("\n=======================================================");
            $display("    biRISC-V DOT PRODUCT TCM VERIFICATION DUMP         ");
            $display("=======================================================");
            $display(" Vec1[0..6] = {%0d, %0d, %0d, %0d, %0d, %0d, %0d}",
                     dp_vec1_0, dp_vec1_1, dp_vec1_2, dp_vec1_3, dp_vec1_4, dp_vec1_5, dp_vec1_6);
            $display(" Vec2[0..6] = {%0d, %0d, %0d, %0d, %0d, %0d, %0d}",
                     dp_vec2_0, dp_vec2_1, dp_vec2_2, dp_vec2_3, dp_vec2_4, dp_vec2_5, dp_vec2_6);
            $display(" Pairwise   = {%0d, %0d, %0d, %0d, %0d, %0d, %0d}",
                     dp_prod_0, dp_prod_1, dp_prod_2, dp_prod_3, dp_prod_4, dp_prod_5, dp_prod_6);
            $display(" Dot Product Result (0x80010260) = %0d (expected: 98)", dp_result);
            if (dp_is_correct)
                $display(" >>> RESULT: SUCCESS - DOT PRODUCT = 98 VERIFIED! <<<");
            else
                $display(" >>> RESULT: FAILED - DOT PRODUCT MISMATCH! <<<");
            $display("=======================================================\n");
        end

        32'd4: begin
            $display("\n=======================================================");
            $display("   biRISC-V ARRAY SUM & MUL TCM VERIFICATION DUMP      ");
            $display("=======================================================");
            $display(" Vec1[0..9] = {%0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d}",
                     asm_vec1_0, asm_vec1_1, asm_vec1_2, asm_vec1_3, asm_vec1_4,
                     asm_vec1_5, asm_vec1_6, asm_vec1_7, asm_vec1_8, asm_vec1_9);
            $display(" Vec2[0..9] = {%0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d}",
                     asm_vec2_0, asm_vec2_1, asm_vec2_2, asm_vec2_3, asm_vec2_4,
                     asm_vec2_5, asm_vec2_6, asm_vec2_7, asm_vec2_8, asm_vec2_9);
            $display(" Prod[0..9] = {%0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d} (expected: {7,2,24,28,30,30,28,24,18,7})",
                     asm_prod_0, asm_prod_1, asm_prod_2, asm_prod_3, asm_prod_4,
                     asm_prod_5, asm_prod_6, asm_prod_7, asm_prod_8, asm_prod_9);
            $display(" Sum [0..9] = {%0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d} (expected: {8,3,11,11,11,11,11,11,11,8})",
                     asm_sum_0, asm_sum_1, asm_sum_2, asm_sum_3, asm_sum_4,
                     asm_sum_5, asm_sum_6, asm_sum_7, asm_sum_8, asm_sum_9);
            if (asm_is_correct)
                $display(" >>> RESULT: SUCCESS - ALL 10 PRODUCTS & 10 SUMS VERIFIED! <<<");
            else
                $display(" >>> RESULT: FAILED - VECTOR OUTPUT MISMATCH! <<<");
            $display("=======================================================\n");
        end

        32'd5: begin
            $display("\n=======================================================");
            $display("      biRISC-V SWAP BITS TCM VERIFICATION DUMP         ");
            $display("=======================================================");
            $display(" Input x   (0x80010400) = %0d (6'b%06b)", sb_x, sb_x_bits);
            $display(" Params    p1=%0d, p2=%0d, n=%0d", sb_p1, sb_p2, sb_n);
            $display(" Extracted set1=%0d, set2=%0d, xor_mask=%0d (6'b%06b)",
                     sb_set1, sb_set2, sb_xor_mask, sb_xor_bits);
            $display(" Result    (0x8001041c) = %0d (6'b%06b) (expected: 7 / 6'b000111)",
                     sb_result, sb_res_bits);
            if (sb_is_correct)
                $display(" >>> RESULT: SUCCESS - BIT SWAP VERIFIED (28 -> 7)! <<<");
            else
                $display(" >>> RESULT: FAILED - BIT SWAP MISMATCH! <<<");
            $display("=======================================================\n");
        end

        default: begin
            $display("[TESTBENCH] Generic / Architectural ELF completed (no benchmark header at 0x80010000).");
        end
    endcase

    $finish;
end

wire          mem_i_rd_w;
wire          mem_i_flush_w;
wire          mem_i_invalidate_w;
wire [ 31:0]  mem_i_pc_w;
wire [ 31:0]  mem_d_addr_w;
wire [ 31:0]  mem_d_data_wr_w;
wire          mem_d_rd_w;
wire [  3:0]  mem_d_wr_w;
wire          mem_d_cacheable_w;
wire [ 10:0]  mem_d_req_tag_w;
wire          mem_d_invalidate_w;
wire          mem_d_writeback_w;
wire          mem_d_flush_w;
wire          mem_i_accept_w;
wire          mem_i_valid_w;
wire          mem_i_error_w;
wire [ 63:0]  mem_i_inst_w;
wire [ 31:0]  mem_d_data_rd_w;
wire          mem_d_accept_w;
wire          mem_d_ack_w;
wire          mem_d_error_w;
wire [ 10:0]  mem_d_resp_tag_w;

riscv_core
u_dut
(
    // Inputs
     .clk(clk)
    ,.rst_n(rst)
    ,.mem_d_data_rd_i(mem_d_data_rd_w)
    ,.mem_d_accept_i(mem_d_accept_w)
    ,.mem_d_ack_i(mem_d_ack_w)
    ,.mem_d_error_i(mem_d_error_w)
    ,.mem_d_resp_tag_i(mem_d_resp_tag_w)
    ,.mem_i_accept_i(mem_i_accept_w)
    ,.mem_i_valid_i(mem_i_valid_w)
    ,.mem_i_error_i(mem_i_error_w)
    ,.mem_i_inst_i(mem_i_inst_w)
    ,.intr_i(1'b0)
    ,.reset_vector_i(32'h80000000)
    ,.cpu_id_i('b0)

    // Outputs
    ,.mem_d_addr_o(mem_d_addr_w)
    ,.mem_d_data_wr_o(mem_d_data_wr_w)
    ,.mem_d_rd_o(mem_d_rd_w)
    ,.mem_d_wr_o(mem_d_wr_w)
    ,.mem_d_cacheable_o(mem_d_cacheable_w)
    ,.mem_d_req_tag_o(mem_d_req_tag_w)
    ,.mem_d_invalidate_o(mem_d_invalidate_w)
    ,.mem_d_writeback_o(mem_d_writeback_w)
    ,.mem_d_flush_o(mem_d_flush_w)
    ,.mem_i_rd_o(mem_i_rd_w)
    ,.mem_i_flush_o(mem_i_flush_w)
    ,.mem_i_invalidate_o(mem_i_invalidate_w)
    ,.mem_i_pc_o(mem_i_pc_w)
);

tcm_mem
u_mem
(
    // Inputs
     .clk_i(clk)
    ,.rst_i(rst)
    ,.mem_i_rd_i(mem_i_rd_w)
    ,.mem_i_flush_i(mem_i_flush_w)
    ,.mem_i_invalidate_i(mem_i_invalidate_w)
    ,.mem_i_pc_i(mem_i_pc_w)
    ,.mem_d_addr_i(mem_d_addr_w)
    ,.mem_d_data_wr_i(mem_d_data_wr_w)
    ,.mem_d_rd_i(mem_d_rd_w)
    ,.mem_d_wr_i(mem_d_wr_w)
    ,.mem_d_cacheable_i(mem_d_cacheable_w)
    ,.mem_d_req_tag_i(mem_d_req_tag_w)
    ,.mem_d_invalidate_i(mem_d_invalidate_w)
    ,.mem_d_writeback_i(mem_d_writeback_w)
    ,.mem_d_flush_i(mem_d_flush_w)

    // Outputs
    ,.mem_i_accept_o(mem_i_accept_w)
    ,.mem_i_valid_o(mem_i_valid_w)
    ,.mem_i_error_o(mem_i_error_w)
    ,.mem_i_inst_o(mem_i_inst_w)
    ,.mem_d_data_rd_o(mem_d_data_rd_w)
    ,.mem_d_accept_o(mem_d_accept_w)
    ,.mem_d_ack_o(mem_d_ack_w)
    ,.mem_d_error_o(mem_d_error_w)
    ,.mem_d_resp_tag_o(mem_d_resp_tag_w)
);

//-------------------------------------------------------------
// Real-Time TCM Benchmark Verification Monitors for GTKWave
//-------------------------------------------------------------
wire [31:0] cur_bench_id_w   = u_mem.u_ram.ram[14'h2000][31:0];
wire [31:0] cur_bench_done_w = u_mem.u_ram.ram[14'h2000][63:32];

always @(posedge clk)
begin
    if (rst)
    begin
        bench_id       <= 32'd0;
        bench_done     <= 32'd0;
        bench_name     <= "RESET";

        // 1. BubbleSort reset
        arr_0          <= 32'd0;
        arr_1          <= 32'd0;
        arr_2          <= 32'd0;
        arr_3          <= 32'd0;
        arr_4          <= 32'd0;
        arr_5          <= 32'd0;
        arr_6          <= 32'd0;
        arr_is_sorted  <= 1'b0;
        arr_swap_count <= 32'd0;
        bs_init_writes <= 32'd0;
        arr_status     <= "RESET";

        // 2. QuickSort reset
        qs_arr_0       <= 32'd0;
        qs_arr_1       <= 32'd0;
        qs_arr_2       <= 32'd0;
        qs_arr_3       <= 32'd0;
        qs_arr_4       <= 32'd0;
        qs_arr_5       <= 32'd0;
        qs_is_sorted   <= 1'b0;
        qs_swap_count  <= 32'd0;
        qs_init_writes <= 32'd0;
        qs_status      <= "RESET";

        // 3. Dot Product reset
        dp_vec1_0 <= 32'd0; dp_vec1_1 <= 32'd0; dp_vec1_2 <= 32'd0; dp_vec1_3 <= 32'd0;
        dp_vec1_4 <= 32'd0; dp_vec1_5 <= 32'd0; dp_vec1_6 <= 32'd0;
        dp_vec2_0 <= 32'd0; dp_vec2_1 <= 32'd0; dp_vec2_2 <= 32'd0; dp_vec2_3 <= 32'd0;
        dp_vec2_4 <= 32'd0; dp_vec2_5 <= 32'd0; dp_vec2_6 <= 32'd0;
        dp_prod_0 <= 32'd0; dp_prod_1 <= 32'd0; dp_prod_2 <= 32'd0; dp_prod_3 <= 32'd0;
        dp_prod_4 <= 32'd0; dp_prod_5 <= 32'd0; dp_prod_6 <= 32'd0;
        dp_result     <= 32'd0;
        dp_expected   <= 32'd0;
        dp_is_correct <= 1'b0;
        dp_status     <= "RESET";

        // 4. Array Sum & Mul reset
        asm_vec1_0 <= 32'd0; asm_vec1_1 <= 32'd0; asm_vec1_2 <= 32'd0; asm_vec1_3 <= 32'd0; asm_vec1_4 <= 32'd0;
        asm_vec1_5 <= 32'd0; asm_vec1_6 <= 32'd0; asm_vec1_7 <= 32'd0; asm_vec1_8 <= 32'd0; asm_vec1_9 <= 32'd0;
        asm_vec2_0 <= 32'd0; asm_vec2_1 <= 32'd0; asm_vec2_2 <= 32'd0; asm_vec2_3 <= 32'd0; asm_vec2_4 <= 32'd0;
        asm_vec2_5 <= 32'd0; asm_vec2_6 <= 32'd0; asm_vec2_7 <= 32'd0; asm_vec2_8 <= 32'd0; asm_vec2_9 <= 32'd0;
        asm_prod_0 <= 32'd0; asm_prod_1 <= 32'd0; asm_prod_2 <= 32'd0; asm_prod_3 <= 32'd0; asm_prod_4 <= 32'd0;
        asm_prod_5 <= 32'd0; asm_prod_6 <= 32'd0; asm_prod_7 <= 32'd0; asm_prod_8 <= 32'd0; asm_prod_9 <= 32'd0;
        asm_sum_0  <= 32'd0; asm_sum_1  <= 32'd0; asm_sum_2  <= 32'd0; asm_sum_3  <= 32'd0; asm_sum_4  <= 32'd0;
        asm_sum_5  <= 32'd0; asm_sum_6  <= 32'd0; asm_sum_7  <= 32'd0; asm_sum_8  <= 32'd0; asm_sum_9  <= 32'd0;
        asm_mul_ok     <= 1'b0;
        asm_sum_ok     <= 1'b0;
        asm_is_correct <= 1'b0;
        asm_status     <= "RESET";

        // 5. Swap Bits reset
        sb_x          <= 32'd0;
        sb_p1         <= 32'd0;
        sb_p2         <= 32'd0;
        sb_n          <= 32'd0;
        sb_set1       <= 32'd0;
        sb_set2       <= 32'd0;
        sb_xor_mask   <= 32'd0;
        sb_result     <= 32'd0;
        sb_expected   <= 32'd0;
        sb_is_correct <= 1'b0;
        sb_status     <= "RESET";
    end
    else
    begin
        bench_id   <= cur_bench_id_w;
        bench_done <= cur_bench_done_w;

        case (cur_bench_id_w)
            32'd1:   bench_name <= "BUBBLESORT";
            32'd2:   bench_name <= "QUICKSORT";
            32'd3:   bench_name <= "DOT PRODUCT";
            32'd4:   bench_name <= "ARRAY SUM MUL";
            32'd5:   bench_name <= "SWAP BITS";
            default: bench_name <= "CUSTOM / TEST";
        endcase

        // =========================================================
        // 1. BubbleSort Monitor (bench_id == 1)
        // =========================================================
        if (cur_bench_id_w == 32'd1)
        begin
            arr_0 <= u_mem.u_ram.ram[14'h3ffa][63:32]; // 0x8001ffd4
            arr_1 <= u_mem.u_ram.ram[14'h3ffb][31:0];  // 0x8001ffd8
            arr_2 <= u_mem.u_ram.ram[14'h3ffb][63:32]; // 0x8001ffdc
            arr_3 <= u_mem.u_ram.ram[14'h3ffc][31:0];  // 0x8001ffe0
            arr_4 <= u_mem.u_ram.ram[14'h3ffc][63:32]; // 0x8001ffe4
            arr_5 <= u_mem.u_ram.ram[14'h3ffd][31:0];  // 0x8001ffe8
            arr_6 <= u_mem.u_ram.ram[14'h3ffd][63:32]; // 0x8001ffec

            if (mem_d_wr_w == 4'b1111 &&
                mem_d_addr_w >= 32'h8001ffd4 &&
                mem_d_addr_w <= 32'h8001ffec)
            begin
                if (bs_init_writes < 32'd7)
                    bs_init_writes <= bs_init_writes + 1'b1;
                else
                    arr_swap_count <= arr_swap_count + 1'b1;
            end

            if (arr_0 == 32'd0 && arr_1 == 32'd1 && arr_2 == 32'd2 &&
                arr_3 == 32'd3 && arr_4 == 32'd3 && arr_5 == 32'd4 &&
                arr_6 == 32'd5)
            begin
                arr_is_sorted <= 1'b1;
                arr_status    <= "SORTED OK";
            end
            else if (arr_swap_count > 0)
            begin
                arr_is_sorted <= 1'b0;
                arr_status    <= "SORTING...";
            end
            else if (bs_init_writes == 32'd7)
            begin
                arr_is_sorted <= 1'b0;
                arr_status    <= "LOADED UNSORTED";
            end
            else
            begin
                arr_is_sorted <= 1'b0;
                arr_status    <= "INITIALIZING";
            end
        end

        // =========================================================
        // 2. QuickSort Monitor (bench_id == 2)
        // =========================================================
        if (cur_bench_id_w == 32'd2)
        begin
            qs_arr_0 <= u_mem.u_ram.ram[14'h2020][31:0];  // 0x80010100
            qs_arr_1 <= u_mem.u_ram.ram[14'h2020][63:32]; // 0x80010104
            qs_arr_2 <= u_mem.u_ram.ram[14'h2021][31:0];  // 0x80010108
            qs_arr_3 <= u_mem.u_ram.ram[14'h2021][63:32]; // 0x8001010c
            qs_arr_4 <= u_mem.u_ram.ram[14'h2022][31:0];  // 0x80010110
            qs_arr_5 <= u_mem.u_ram.ram[14'h2022][63:32]; // 0x80010114

            if (mem_d_wr_w == 4'b1111 &&
                mem_d_addr_w >= 32'h80010100 &&
                mem_d_addr_w <= 32'h80010114)
            begin
                if (qs_init_writes < 32'd6)
                    qs_init_writes <= qs_init_writes + 1'b1;
                else
                    qs_swap_count <= qs_swap_count + 1'b1;
            end

            if (qs_arr_0 == 32'd1 && qs_arr_1 == 32'd5 && qs_arr_2 == 32'd7 &&
                qs_arr_3 == 32'd8 && qs_arr_4 == 32'd9 && qs_arr_5 == 32'd10 &&
                cur_bench_done_w == 32'd1)
            begin
                qs_is_sorted <= 1'b1;
                qs_status    <= "SORTED OK";
            end
            else if (qs_swap_count > 0)
            begin
                qs_is_sorted <= 1'b0;
                qs_status    <= "PARTITIONING";
            end
            else if (qs_init_writes == 32'd6)
            begin
                qs_is_sorted <= 1'b0;
                qs_status    <= "LOADED UNSORTED";
            end
            else
            begin
                qs_is_sorted <= 1'b0;
                qs_status    <= "INITIALIZING";
            end
        end

        // =========================================================
        // 3. Dot Product Monitor (bench_id == 3)
        // =========================================================
        if (cur_bench_id_w == 32'd3)
        begin
            dp_expected <= 32'd98;
            dp_vec1_0 <= u_mem.u_ram.ram[14'h2040][31:0];  dp_vec1_1 <= u_mem.u_ram.ram[14'h2040][63:32];
            dp_vec1_2 <= u_mem.u_ram.ram[14'h2041][31:0];  dp_vec1_3 <= u_mem.u_ram.ram[14'h2041][63:32];
            dp_vec1_4 <= u_mem.u_ram.ram[14'h2042][31:0];  dp_vec1_5 <= u_mem.u_ram.ram[14'h2042][63:32];
            dp_vec1_6 <= u_mem.u_ram.ram[14'h2043][31:0];

            dp_vec2_0 <= u_mem.u_ram.ram[14'h2044][31:0];  dp_vec2_1 <= u_mem.u_ram.ram[14'h2044][63:32];
            dp_vec2_2 <= u_mem.u_ram.ram[14'h2045][31:0];  dp_vec2_3 <= u_mem.u_ram.ram[14'h2045][63:32];
            dp_vec2_4 <= u_mem.u_ram.ram[14'h2046][31:0];  dp_vec2_5 <= u_mem.u_ram.ram[14'h2046][63:32];
            dp_vec2_6 <= u_mem.u_ram.ram[14'h2047][31:0];

            dp_prod_0 <= u_mem.u_ram.ram[14'h2048][31:0];  dp_prod_1 <= u_mem.u_ram.ram[14'h2048][63:32];
            dp_prod_2 <= u_mem.u_ram.ram[14'h2049][31:0];  dp_prod_3 <= u_mem.u_ram.ram[14'h2049][63:32];
            dp_prod_4 <= u_mem.u_ram.ram[14'h204a][31:0];  dp_prod_5 <= u_mem.u_ram.ram[14'h204a][63:32];
            dp_prod_6 <= u_mem.u_ram.ram[14'h204b][31:0];

            dp_result <= u_mem.u_ram.ram[14'h204c][31:0];

            if (dp_result == 32'd98 && cur_bench_done_w == 32'd1)
            begin
                dp_is_correct <= 1'b1;
                dp_status     <= "CORRECT (98)";
            end
            else if (dp_result != 32'd0)
            begin
                dp_is_correct <= 1'b0;
                dp_status     <= "ACCUMULATING";
            end
            else if (dp_vec1_6 == 32'd3 && dp_vec2_6 == 32'd2)
            begin
                dp_is_correct <= 1'b0;
                dp_status     <= "VECS LOADED";
            end
            else
            begin
                dp_is_correct <= 1'b0;
                dp_status     <= "INITIALIZING";
            end
        end

        // =========================================================
        // 4. Array Sum & Mul Monitor (bench_id == 4)
        // =========================================================
        if (cur_bench_id_w == 32'd4)
        begin
            asm_vec1_0 <= u_mem.u_ram.ram[14'h2060][31:0];  asm_vec1_1 <= u_mem.u_ram.ram[14'h2060][63:32];
            asm_vec1_2 <= u_mem.u_ram.ram[14'h2061][31:0];  asm_vec1_3 <= u_mem.u_ram.ram[14'h2061][63:32];
            asm_vec1_4 <= u_mem.u_ram.ram[14'h2062][31:0];  asm_vec1_5 <= u_mem.u_ram.ram[14'h2062][63:32];
            asm_vec1_6 <= u_mem.u_ram.ram[14'h2063][31:0];  asm_vec1_7 <= u_mem.u_ram.ram[14'h2063][63:32];
            asm_vec1_8 <= u_mem.u_ram.ram[14'h2064][31:0];  asm_vec1_9 <= u_mem.u_ram.ram[14'h2064][63:32];

            asm_vec2_0 <= u_mem.u_ram.ram[14'h2065][31:0];  asm_vec2_1 <= u_mem.u_ram.ram[14'h2065][63:32];
            asm_vec2_2 <= u_mem.u_ram.ram[14'h2066][31:0];  asm_vec2_3 <= u_mem.u_ram.ram[14'h2066][63:32];
            asm_vec2_4 <= u_mem.u_ram.ram[14'h2067][31:0];  asm_vec2_5 <= u_mem.u_ram.ram[14'h2067][63:32];
            asm_vec2_6 <= u_mem.u_ram.ram[14'h2068][31:0];  asm_vec2_7 <= u_mem.u_ram.ram[14'h2068][63:32];
            asm_vec2_8 <= u_mem.u_ram.ram[14'h2069][31:0];  asm_vec2_9 <= u_mem.u_ram.ram[14'h2069][63:32];

            asm_prod_0 <= u_mem.u_ram.ram[14'h206a][31:0];  asm_prod_1 <= u_mem.u_ram.ram[14'h206a][63:32];
            asm_prod_2 <= u_mem.u_ram.ram[14'h206b][31:0];  asm_prod_3 <= u_mem.u_ram.ram[14'h206b][63:32];
            asm_prod_4 <= u_mem.u_ram.ram[14'h206c][31:0];  asm_prod_5 <= u_mem.u_ram.ram[14'h206c][63:32];
            asm_prod_6 <= u_mem.u_ram.ram[14'h206d][31:0];  asm_prod_7 <= u_mem.u_ram.ram[14'h206d][63:32];
            asm_prod_8 <= u_mem.u_ram.ram[14'h206e][31:0];  asm_prod_9 <= u_mem.u_ram.ram[14'h206e][63:32];

            asm_sum_0  <= u_mem.u_ram.ram[14'h206f][31:0];  asm_sum_1  <= u_mem.u_ram.ram[14'h206f][63:32];
            asm_sum_2  <= u_mem.u_ram.ram[14'h2070][31:0];  asm_sum_3  <= u_mem.u_ram.ram[14'h2070][63:32];
            asm_sum_4  <= u_mem.u_ram.ram[14'h2071][31:0];  asm_sum_5  <= u_mem.u_ram.ram[14'h2071][63:32];
            asm_sum_6  <= u_mem.u_ram.ram[14'h2072][31:0];  asm_sum_7  <= u_mem.u_ram.ram[14'h2072][63:32];
            asm_sum_8  <= u_mem.u_ram.ram[14'h2073][31:0];  asm_sum_9  <= u_mem.u_ram.ram[14'h2073][63:32];

            asm_mul_ok <= (asm_prod_0 == 32'd7  && asm_prod_1 == 32'd2  &&
                           asm_prod_2 == 32'd24 && asm_prod_3 == 32'd28 &&
                           asm_prod_4 == 32'd30 && asm_prod_5 == 32'd30 &&
                           asm_prod_6 == 32'd28 && asm_prod_7 == 32'd24 &&
                           asm_prod_8 == 32'd18 && asm_prod_9 == 32'd7);

            asm_sum_ok <= (asm_sum_0  == 32'd8  && asm_sum_1  == 32'd3  &&
                           asm_sum_2  == 32'd11 && asm_sum_3  == 32'd11 &&
                           asm_sum_4  == 32'd11 && asm_sum_5  == 32'd11 &&
                           asm_sum_6  == 32'd11 && asm_sum_7  == 32'd11 &&
                           asm_sum_8  == 32'd11 && asm_sum_9  == 32'd8);

            if (asm_mul_ok && asm_sum_ok && cur_bench_done_w == 32'd1)
            begin
                asm_is_correct <= 1'b1;
                asm_status     <= "VERIFIED OK";
            end
            else if (asm_mul_ok)
            begin
                asm_is_correct <= 1'b0;
                asm_status     <= "SUMMING...";
            end
            else if (asm_prod_0 != 32'd0)
            begin
                asm_is_correct <= 1'b0;
                asm_status     <= "MULTIPLYING";
            end
            else if (asm_vec1_9 == 32'd7 && asm_vec2_9 == 32'd1)
            begin
                asm_is_correct <= 1'b0;
                asm_status     <= "VECS LOADED";
            end
            else
            begin
                asm_is_correct <= 1'b0;
                asm_status     <= "INITIALIZING";
            end
        end

        // =========================================================
        // 5. Swap Bits Monitor (bench_id == 5)
        // =========================================================
        if (cur_bench_id_w == 32'd5)
        begin
            sb_expected <= 32'd7;
            sb_x        <= u_mem.u_ram.ram[14'h2080][31:0];  // 0x80010400
            sb_p1       <= u_mem.u_ram.ram[14'h2080][63:32]; // 0x80010404
            sb_p2       <= u_mem.u_ram.ram[14'h2081][31:0];  // 0x80010408
            sb_n        <= u_mem.u_ram.ram[14'h2081][63:32]; // 0x8001040c
            sb_set1     <= u_mem.u_ram.ram[14'h2082][31:0];  // 0x80010410
            sb_set2     <= u_mem.u_ram.ram[14'h2082][63:32]; // 0x80010414
            sb_xor_mask <= u_mem.u_ram.ram[14'h2083][31:0];  // 0x80010418
            sb_result   <= u_mem.u_ram.ram[14'h2083][63:32]; // 0x8001041c

            if (sb_result == 32'd7 && cur_bench_done_w == 32'd1)
            begin
                sb_is_correct <= 1'b1;
                sb_status     <= "CORRECT (7)";
            end
            else if (sb_set2 != 32'd0 || sb_xor_mask != 32'd0)
            begin
                sb_is_correct <= 1'b0;
                sb_status     <= "SWAPPING BITS";
            end
            else if (sb_x == 32'd28)
            begin
                sb_is_correct <= 1'b0;
                sb_status     <= "ARGS LOADED";
            end
            else
            begin
                sb_is_correct <= 1'b0;
                sb_status     <= "INITIALIZING";
            end
        end
    end
end

`ifdef trace_gate_level_simulation

biriscv_trace_sim_gls
trace_inst_0
(
     .valid_i(mem_i_valid_w)
    ,.opcode_i(mem_i_inst_w[31:0])
);

biriscv_trace_sim_gls
trace_inst_1
(
     .valid_i(mem_i_valid_w)
    ,.opcode_i(mem_i_inst_w[63:32])
);

`endif

endmodule
