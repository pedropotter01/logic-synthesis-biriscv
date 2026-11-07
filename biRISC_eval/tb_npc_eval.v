`timescale 1ns/1ps

`ifndef BHT_VAL
  `define BHT_VAL 512
  `define BHT_W_VAL 9
  `define BTB_VAL 32
  `define BTB_W_VAL 5
  `define RAS_VAL 8
  `define RAS_W_VAL 3
`endif

module tb_npc_eval;

    reg clk;
    reg rst;

    reg         invalidate;
    reg         branch_request;
    reg         branch_is_taken;
    reg         branch_is_not_taken;
    reg  [31:0] branch_source;
    reg         branch_is_call;
    reg         branch_is_ret;
    reg         branch_is_jmp;
    reg  [31:0] branch_pc;
    reg  [31:0] pc_f;
    reg         pc_accept;

    wire [31:0] next_pc_f;
    wire [ 1:0] next_taken_f;

    biriscv_npc #(
        .SUPPORT_BRANCH_PREDICTION(1),
        .NUM_BTB_ENTRIES(`BTB_VAL),
        .NUM_BTB_ENTRIES_W(`BTB_W_VAL),
        .NUM_BHT_ENTRIES(`BHT_VAL),
        .NUM_BHT_ENTRIES_W(`BHT_W_VAL),
        .NUM_RAS_ENTRIES(`RAS_VAL),
        .NUM_RAS_ENTRIES_W(`RAS_W_VAL),
        .RAS_ENABLE(1),
        .BHT_ENABLE(1),
        .GSHARE_ENABLE(1)
    ) u_npc (
        .clk_i(clk),
        .rst_i(rst),
        .invalidate_i(invalidate),
        .branch_request_i(branch_request),
        .branch_is_taken_i(branch_is_taken),
        .branch_is_not_taken_i(branch_is_not_taken),
        .branch_source_i(branch_source),
        .branch_is_call_i(branch_is_call),
        .branch_is_ret_i(branch_is_ret),
        .branch_is_jmp_i(branch_is_jmp),
        .branch_pc_i(branch_pc),
        .pc_f_i(pc_f),
        .pc_accept_i(pc_accept),
        .next_pc_f_o(next_pc_f),
        .next_taken_f_o(next_taken_f)
    );

    always #5 clk = ~clk;

    integer file, status;
    reg [31:0] trace_pc;
    reg [63:0] trace_str;
    integer    trace_taken;
    reg [31:0] trace_target;
    integer    trace_type;

    integer total_branches    = 0;
    integer mispredicts       = 0;
    integer btb_target_misses = 0;

    reg pred_taken;
    reg [31:0] pred_target;
    reg misp_dir;
    reg misp_target;

    initial begin
        clk = 0;
        rst = 1;
        invalidate = 0;
        pc_accept = 0;
        branch_request = 0;
        branch_is_taken = 0;
        branch_is_not_taken = 0;
        branch_source = 0;
        branch_pc = 0;
        branch_is_call = 0;
        branch_is_ret = 0;
        branch_is_jmp = 0;
        pc_f = 0;

        #20;
        @(negedge clk);
        rst = 0;
        #10;

        file = $fopen("slre.trace", "r");
        if (file == 0) begin
            $display("ERRO: slre.trace nao encontrado!");
            $finish;
        end

        while (!$feof(file)) begin
            status = $fscanf(file, "0x%h %s %d 0x%h\n", trace_pc, trace_str, trace_taken, trace_target);
            if (status == 4) begin
                total_branches = total_branches + 1;

                // Decodifica o tipo (suporta tanto string quanto código numérico)
                if (trace_str == "0" || trace_str == "beq" || trace_str == "bne" || 
                    trace_str == "blt" || trace_str == "bge" || trace_str == "bltu" || trace_str == "bgeu")
                    trace_type = 0;
                else if (trace_str == "1" || trace_str == "jal" || trace_str == "call")
                    trace_type = 1;
                else if (trace_str == "2" || trace_str == "ret" || trace_str == "jalr")
                    trace_type = 2;
                else
                    trace_type = 3;

                // 1. FASE DE FETCH
                @(posedge clk);
                pc_f      <= trace_pc;
                pc_accept <= 1'b1;

                branch_request      <= 1'b0;
                branch_is_taken     <= 1'b0;
                branch_is_not_taken <= 1'b0;
                branch_is_call      <= 1'b0;
                branch_is_ret       <= 1'b0;
                branch_is_jmp       <= 1'b0;

                #1;
                pred_taken  = |next_taken_f;
                pred_target = next_pc_f;

                misp_dir = (pred_taken != (trace_taken != 0));
                if (misp_dir)
                    mispredicts = mispredicts + 1;

                misp_target = 1'b0;
                if (trace_taken != 0) begin
                    if (pred_target != trace_target) begin
                        btb_target_misses = btb_target_misses + 1;
                        misp_target = 1'b1;
                    end
                end

                // 2. FASE DE ATUALIZACAO
                @(posedge clk);
                pc_accept <= 1'b0;

                branch_source  <= trace_pc;
                branch_pc      <= trace_target;
                branch_request <= (misp_dir || misp_target);

                if (trace_type == 0) begin
                    branch_is_taken     <= (trace_taken != 0);
                    branch_is_not_taken <= (trace_taken == 0);
                    branch_is_call      <= 1'b0;
                    branch_is_ret       <= 1'b0;
                    branch_is_jmp       <= 1'b0;
                end
                else if (trace_type == 1) begin
                    branch_is_taken     <= 1'b1;
                    branch_is_not_taken <= 1'b0;
                    branch_is_call      <= 1'b1;
                    branch_is_ret       <= 1'b0;
                    branch_is_jmp       <= 1'b0;
                end
                else if (trace_type == 2) begin
                    branch_is_taken     <= 1'b1;
                    branch_is_not_taken <= 1'b0;
                    branch_is_call      <= 1'b0;
                    branch_is_ret       <= 1'b1;
                    branch_is_jmp       <= 1'b0;
                end
                else begin
                    branch_is_taken     <= 1'b1;
                    branch_is_not_taken <= 1'b0;
                    branch_is_call      <= 1'b0;
                    branch_is_ret       <= 1'b0;
                    branch_is_jmp       <= 1'b1;
                end
            end
        end

        $fclose(file);
        @(posedge clk);

        if (total_branches > 0) begin
            $display("RESULT: TOTAL=%0d MISP=%0d (%0.2f%%) BTB_ERR=%0d",
                     total_branches, mispredicts,
                     (mispredicts * 100.0) / total_branches, btb_target_misses);
        end else begin
            $display("ERRO: Nenhum branch foi lido de slre.trace!");
        end
        $finish;
    end

endmodule
