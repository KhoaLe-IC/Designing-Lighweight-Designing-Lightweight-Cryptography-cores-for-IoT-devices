`timescale 1ns / 1ps

module tb_PolyMAC();

    reg clk, start, in_r, in_s, data_in;
    reg [4:0] msg_bytes; 
    reg [31:0] I;
    wire [31:0] O;
    wire finish;

    PolyMAC dut (
        .I(I), .clk(clk), .start(start),
        .in_r(in_r), .in_s(in_s), .data_in(data_in),
        .msg_bytes(msg_bytes),
        .O(O), .finish(finish)
    );

    always #5 clk = ~clk;

    reg [7:0] msg_buf [0:1023];
    integer msg_len;
    integer error_count = 0;
    integer current_test = 0;
    integer global_i;

    task clear_msg;
        begin
            msg_len = 0;
        end
    endtask

    task push_byte;
        input [7:0] b;
        begin
            msg_buf[msg_len] = b;
            msg_len = msg_len + 1;
        end
    endtask

    task push_hex_block;
        input [127:0] blk;
        integer k;
        reg [7:0] val;
        begin
            for(k = 0; k < 16; k = k + 1) begin
                val = (blk >> ((15 - k) * 8)) & 8'hFF;
                push_byte(val);
            end
        end
    endtask

    task load_string;
        input [8*500-1:0] str;
        input integer str_len;
        integer i;
        reg [7:0] val;
        begin
            clear_msg();
            for (i = 0; i < str_len; i = i + 1) begin
                val = (str >> ((str_len - 1 - i) * 8)) & 8'hFF;
                push_byte(val);
            end
        end
    endtask

    task run_test;
        input [127:0] key_r; 
        input [127:0] key_s; 
        input [127:0] expected_tag;
        
        integer i, blocks, rem_bytes, b;
        reg [31:0] w0, w1, w2, w3;
        reg [127:0] tag_hw_str;
        begin
            current_test = current_test + 1;
            $display("\n================================================================");
            $display(" RUNNING PolyMAC TEST VECTOR #%0d (Msg Length: %0d bytes)", current_test, msg_len);
            $display("================================================================");

            @(negedge clk); start = 1; @(negedge clk); start = 0;

            in_r = 1;
            I = {key_r[103:96], key_r[111:104], key_r[119:112], key_r[127:120]}; @(negedge clk);
            I = {key_r[71:64],  key_r[79:72],   key_r[87:80],   key_r[95:88]};   @(negedge clk);
            I = {key_r[39:32],  key_r[47:40],   key_r[55:48],   key_r[63:56]};   @(negedge clk);
            I = {key_r[7:0],    key_r[15:8],    key_r[23:16],   key_r[31:24]};   @(negedge clk);
            in_r = 0;

            in_s = 1;
            I = {key_s[103:96], key_s[111:104], key_s[119:112], key_s[127:120]}; @(negedge clk);
            I = {key_s[71:64],  key_s[79:72],   key_s[87:80],   key_s[95:88]};   @(negedge clk);
            I = {key_s[39:32],  key_s[47:40],   key_s[55:48],   key_s[63:56]};   @(negedge clk);
            I = {key_s[7:0],    key_s[15:8],    key_s[23:16],   key_s[31:24]};   @(negedge clk);
            in_s = 0;

            blocks = msg_len / 16;
            rem_bytes = msg_len % 16;

            for (i = 0; i < blocks; i = i + 1) begin
                data_in = 1;
                msg_bytes = 16;
                I = {msg_buf[i*16+3], msg_buf[i*16+2], msg_buf[i*16+1], msg_buf[i*16+0]}; @(negedge clk);
                I = {msg_buf[i*16+7], msg_buf[i*16+6], msg_buf[i*16+5], msg_buf[i*16+4]}; @(negedge clk);
                I = {msg_buf[i*16+11], msg_buf[i*16+10], msg_buf[i*16+9], msg_buf[i*16+8]}; @(negedge clk);
                I = {msg_buf[i*16+15], msg_buf[i*16+14], msg_buf[i*16+13], msg_buf[i*16+12]}; @(negedge clk);
                data_in = 0;
                
                wait(finish == 1'b1);
                if (i < blocks - 1 || rem_bytes > 0) begin
                    wait(finish == 1'b0); 
                    @(negedge clk);
                end
            end

            if (rem_bytes > 0) begin
                data_in = 1;
                msg_bytes = rem_bytes; 
                w0 = 0; w1 = 0; w2 = 0; w3 = 0;
                for (b = 0; b < rem_bytes; b = b + 1) begin
                    if (b < 4) w0 = w0 | (msg_buf[blocks*16 + b] << (b*8));
                    else if (b < 8) w1 = w1 | (msg_buf[blocks*16 + b] << ((b-4)*8));
                    else if (b < 12) w2 = w2 | (msg_buf[blocks*16 + b] << ((b-8)*8));
                    else w3 = w3 | (msg_buf[blocks*16 + b] << ((b-12)*8));
                end
                I = w0; @(negedge clk);
                I = w1; @(negedge clk);
                I = w2; @(negedge clk);
                I = w3; @(negedge clk);
                data_in = 0;
                
                wait(finish == 1'b1);
            end

            if (msg_len == 0) wait(finish == 1'b1);

            @(negedge clk); w0 = O;
            @(negedge clk); w1 = O;
            @(negedge clk); w2 = O;
            @(negedge clk); w3 = O;
            
            tag_hw_str = {w0[7:0], w0[15:8], w0[23:16], w0[31:24], 
                          w1[7:0], w1[15:8], w1[23:16], w1[31:24], 
                          w2[7:0], w2[15:8], w2[23:16], w2[31:24], 
                          w3[7:0], w3[15:8], w3[23:16], w3[31:24]};
            
            if (tag_hw_str === expected_tag) begin
                $display("-> [PASS] Output: %032x | Expected: %032x", tag_hw_str, expected_tag);
            end else begin
                $display("-> [FAIL] Output: %032x | Expected: %032x", tag_hw_str, expected_tag);
                error_count = error_count + 1;
            end
            
            wait(finish == 1'b0);
            @(negedge clk);
        end
    endtask

    initial begin
        clk = 0; start = 0; in_r = 0; in_s = 0; data_in = 0; I = 0; msg_bytes = 16;
        #25;
        
        clear_msg();
        for(global_i = 0; global_i < 64; global_i = global_i + 1) push_byte(8'h00);
        run_test(128'h00000000000000000000000000000000, 
                 128'h00000000000000000000000000000000, 
                 128'h00000000000000000000000000000000);

        load_string("Any submission to the IETF intended by the Contributor for publication as all or part of an IETF Internet-Draft or RFC and any statement made within the context of an IETF activity is considered an \"IETF Contribution\". Such statements include oral statements in IETF sessions, as well as written and electronic communications made at any time or place, which are addressed to", 375);
        run_test(128'h00000000000000000000000000000000, 
                 128'h36e5f6b5c5e06070f0efca96227a863e, 
                 128'h36e5f6b5c5e06070f0efca96227a863e);

        load_string("Any submission to the IETF intended by the Contributor for publication as all or part of an IETF Internet-Draft or RFC and any statement made within the context of an IETF activity is considered an \"IETF Contribution\". Such statements include oral statements in IETF sessions, as well as written and electronic communications made at any time or place, which are addressed to", 375);
        run_test(128'h36e5f6b5c5e06070f0efca96227a863e, 
                 128'h00000000000000000000000000000000, 
                 128'hf3477e7cd95417af89a6b8794c310cf0);

        clear_msg();
        push_hex_block(128'h2754776173206272696c6c69672c2061);
        push_hex_block(128'h6e642074686520736c6974687920746f);
        push_hex_block(128'h7665730a446964206779726520616e64);
        push_hex_block(128'h2067696d626c6520696e207468652077);
        push_hex_block(128'h6162653a0a416c6c206d696d73792077);
        push_hex_block(128'h6572652074686520626f726f676f7665);
        push_hex_block(128'h732c0a416e6420746865206d6f6d6520);
        push_byte(8'h72); push_byte(8'h61); push_byte(8'h74); push_byte(8'h68);
        push_byte(8'h73); push_byte(8'h20); push_byte(8'h6f); push_byte(8'h75);
        push_byte(8'h74); push_byte(8'h67); push_byte(8'h72); push_byte(8'h61);
        push_byte(8'h62); push_byte(8'h65); push_byte(8'h2e);
        run_test(128'h1c9240a5eb55d38af333888604f6b5f0, 
                 128'h473917c1402b80099dca5cbc207075c0, 
                 128'h4541669a7eaaee61e708dc7cbcc5eb62); 

        clear_msg();
        push_hex_block(128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        run_test(128'h02000000000000000000000000000000, 
                 128'h00000000000000000000000000000000, 
                 128'h03000000000000000000000000000000);

        clear_msg();
        push_hex_block(128'h02000000000000000000000000000000);
        run_test(128'h02000000000000000000000000000000, 
                 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 
                 128'h03000000000000000000000000000000);

        clear_msg();
        push_hex_block(128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        push_hex_block(128'hF0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        push_hex_block(128'h11000000000000000000000000000000);
        run_test(128'h01000000000000000000000000000000, 
                 128'h00000000000000000000000000000000, 
                 128'h05000000000000000000000000000000);

        clear_msg();
        push_hex_block(128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        push_hex_block(128'hFBFEFEFEFEFEFEFEFEFEFEFEFEFEFEFE);
        push_hex_block(128'h01010101010101010101010101010101);
        run_test(128'h01000000000000000000000000000000, 
                 128'h00000000000000000000000000000000, 
                 128'h00000000000000000000000000000000);

        clear_msg();
        push_hex_block(128'hFDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        run_test(128'h02000000000000000000000000000000, 
                 128'h00000000000000000000000000000000, 
                 128'hFAFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        clear_msg();
        push_hex_block(128'hE33594D7505E43B90000000000000000);
        push_hex_block(128'h3394D7505E4379CD0100000000000000);
        push_hex_block(128'h00000000000000000000000000000000);
        push_hex_block(128'h01000000000000000000000000000000);
        run_test(128'h01000000000000000400000000000000, 
                 128'h00000000000000000000000000000000, 
                 128'h14000000000000005500000000000000);

        clear_msg();
        push_hex_block(128'hE33594D7505E43B90000000000000000);
        push_hex_block(128'h3394D7505E4379CD0100000000000000);
        push_hex_block(128'h00000000000000000000000000000000);
        run_test(128'h01000000000000000400000000000000, 
                 128'h00000000000000000000000000000000, 
                 128'h13000000000000000000000000000000);

        $display("\n================================================================");
        if (error_count == 0) $display("  [SUCCESS] 11/11 TEST VECTORS PASSED PERFECTLY!");
        else $display("  [FAILED] %0d/11 TEST VECTORS FAILED.", error_count);
        $display("================================================================\n");

        #50; $finish;
    end
endmodule