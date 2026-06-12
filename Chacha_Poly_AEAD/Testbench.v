`timescale 1ns / 1ps
module Testbench();
    reg clk, start, encrypt, valid, is_last;
    reg [31:0] I;
    reg [2:0] byte_vld, type_in;
    
    wire ready, valid_out, finish;
    wire [31:0] O, tag_out;

    ChachaPoly_AEAD dut (
        .clk(clk), .start(start), .encrypt(encrypt),
        .I(I), .byte_vld(byte_vld), .type_in(type_in),
        .valid(valid), .is_last(is_last),
        .ready(ready), .O(O), .valid_out(valid_out),
        .tag_out(tag_out), .finish(finish)
    );

    always #5 clk = ~clk;

    initial begin
        #5000000; 
        $display("\nFATAL: TIMEOUT!");
        $finish;
    end

    reg [31:0] pt_words [0:28];
    reg [31:0] ct_words [0:28];
    
    reg [31:0] cap_ct [0:299];
    reg [31:0] cap_tag [0:3];
    integer cap_ct_idx;
    integer cap_tag_idx;

    reg [31:0] dyn_pt [0:299];
    reg [31:0] dyn_ct [0:299];
    reg [31:0] dyn_tag [0:3];

    always @(posedge clk) begin
        if (valid && ready && type_in == 3'd3) begin
            cap_ct[cap_ct_idx] <= O;
            cap_ct_idx <= cap_ct_idx + 1;
        end
        if (finish) begin
            cap_tag[cap_tag_idx] <= tag_out;
            cap_tag_idx <= cap_tag_idx + 1;
        end
    end

    task send_word;
        input [2:0] t_in;
        input [31:0] data;
        input [2:0] b_vld;
        input last;
        reg hs_done;
        begin
            @(negedge clk);
            type_in = t_in; I = data; byte_vld = b_vld; is_last = last; valid = 1;
            hs_done = 0;
            while (!hs_done) begin
                @(posedge clk);
                if (ready == 1'b1) hs_done = 1;
            end
            @(negedge clk);
            valid = 0; is_last = 0;
        end
    endtask

    task setup_key_nonce;
        begin
            send_word(3'd0, 32'h80818283, 3'd4, 1'b0);
            send_word(3'd0, 32'h84858687, 3'd4, 1'b0);
            send_word(3'd0, 32'h88898a8b, 3'd4, 1'b0);
            send_word(3'd0, 32'h8c8d8e8f, 3'd4, 1'b0);
            send_word(3'd0, 32'h90919293, 3'd4, 1'b0);
            send_word(3'd0, 32'h94959697, 3'd4, 1'b0);
            send_word(3'd0, 32'h98999a9b, 3'd4, 1'b0);
            send_word(3'd0, 32'h9c9d9e9f, 3'd4, 1'b0);
            send_word(3'd1, 32'h07000000, 3'd4, 1'b0);
            send_word(3'd1, 32'h40414243, 3'd4, 1'b0);
            send_word(3'd1, 32'h44454647, 3'd4, 1'b0);
        end
    endtask

    task send_aad;
        begin
            send_word(3'd2, 32'h50515253, 3'd4, 1'b0);
            send_word(3'd2, 32'hc0c1c2c3, 3'd4, 1'b0);
            send_word(3'd2, 32'hc4c5c6c7, 3'd4, 1'b1);
        end
    endtask

    task reset_caps;
        begin
            cap_ct_idx = 0; cap_tag_idx = 0; err_ct = 0; err_tag = 0;
        end
    endtask

    integer i, err_ct, err_tag;

    initial begin
        clk = 0; start = 0; encrypt = 1; valid = 0; is_last = 0; I = 0; byte_vld = 0; type_in = 0;
        reset_caps();
        #50;

        pt_words[0] = 32'h4c616469; pt_words[1] = 32'h65732061; pt_words[2] = 32'h6e642047; pt_words[3] = 32'h656e746c;
        pt_words[4] = 32'h656d656e; pt_words[5] = 32'h206f6620; pt_words[6] = 32'h74686520; pt_words[7] = 32'h636c6173;
        pt_words[8] = 32'h73206f66; pt_words[9] = 32'h20273939; pt_words[10]= 32'h3a204966; pt_words[11]= 32'h20492063;
        pt_words[12]= 32'h6f756c64; pt_words[13]= 32'h206f6666; pt_words[14]= 32'h65722079; pt_words[15]= 32'h6f75206f;
        pt_words[16]= 32'h6e6c7920; pt_words[17]= 32'h6f6e6520; pt_words[18]= 32'h74697020; pt_words[19]= 32'h666f7220;
        pt_words[20]= 32'h74686520; pt_words[21]= 32'h66757475; pt_words[22]= 32'h72652c20; pt_words[23]= 32'h73756e73;
        pt_words[24]= 32'h63726565; pt_words[25]= 32'h6e20776f; pt_words[26]= 32'h756c6420; pt_words[27]= 32'h62652069;
        pt_words[28]= 32'h742e0000;

        ct_words[0]  = 32'hd31a8d34; ct_words[1]  = 32'h648e60db; ct_words[2]  = 32'h7b86afbc; ct_words[3]  = 32'h53ef7ec2;
        ct_words[4]  = 32'ha4aded51; ct_words[5]  = 32'h296e08fe; ct_words[6]  = 32'ha9e2b5a7; ct_words[7]  = 32'h36ee62d6;
        ct_words[8]  = 32'h3dbea45e; ct_words[9]  = 32'h8ca96712; ct_words[10] = 32'h82fafb69; ct_words[11] = 32'hda92728b;
        ct_words[12] = 32'h1a71de0a; ct_words[13] = 32'h9e060b29; ct_words[14] = 32'h05d6a5b6; ct_words[15] = 32'h7ecd3b36;
        ct_words[16] = 32'h92ddbd7f; ct_words[17] = 32'h2d778b8c; ct_words[18] = 32'h9803aee3; ct_words[19] = 32'h28091b58;
        ct_words[20] = 32'hfab324e4; ct_words[21] = 32'hfad67594; ct_words[22] = 32'h5585808b; ct_words[23] = 32'h4831d7bc;
        ct_words[24] = 32'h3ff4def0; ct_words[25] = 32'h8e4b7a9d; ct_words[26] = 32'he576d265; ct_words[27] = 32'h86cec64b;
        ct_words[28] = 32'h61160000;

        @(negedge clk); start = 1; encrypt = 1; @(negedge clk); start = 0;
        setup_key_nonce();
        send_aad();
        for (i = 0; i < 29; i = i + 1) send_word(3'd3, pt_words[i], (i == 28) ? 3'd2 : 3'd4, (i == 28) ? 1'b1 : 1'b0);
        send_word(3'd4, 32'd0, 3'd4, 1'b1);
        while(cap_tag_idx < 4) @(negedge clk);
        
        $display("\n=======================================================");
        $display(" CASE 1: RFC 7539 ENCRYPTION CHECK");
        $display("=======================================================");
        for (i = 0; i < 29; i = i + 1) begin
            if (cap_ct[i] !== ct_words[i]) begin
                $display("[FAIL] CT[%02d] : Output = %08x | Expected = %08x", i, cap_ct[i], ct_words[i]);
                err_ct = err_ct + 1;
            end else begin
                $display("[PASS] CT[%02d] : Output = %08x | Expected = %08x", i, cap_ct[i], ct_words[i]);
            end
        end
        $display("-------------------------------------------------------");
        if (cap_tag[0] !== 32'h1ae10b59) begin $display("[FAIL] TAG[0] : Output = %08x | Expected = 1ae10b59", cap_tag[0]); err_tag = err_tag + 1; end else $display("[PASS] TAG[0] : Output = %08x | Expected = 1ae10b59", cap_tag[0]);
        if (cap_tag[1] !== 32'h4f09e26a) begin $display("[FAIL] TAG[1] : Output = %08x | Expected = 4f09e26a", cap_tag[1]); err_tag = err_tag + 1; end else $display("[PASS] TAG[1] : Output = %08x | Expected = 4f09e26a", cap_tag[1]);
        if (cap_tag[2] !== 32'h7e902ecb) begin $display("[FAIL] TAG[2] : Output = %08x | Expected = 7e902ecb", cap_tag[2]); err_tag = err_tag + 1; end else $display("[PASS] TAG[2] : Output = %08x | Expected = 7e902ecb", cap_tag[2]);
        if (cap_tag[3] !== 32'hd0600691) begin $display("[FAIL] TAG[3] : Output = %08x | Expected = d0600691", cap_tag[3]); err_tag = err_tag + 1; end else $display("[PASS] TAG[3] : Output = %08x | Expected = d0600691", cap_tag[3]);
        
        if (err_ct == 0 && err_tag == 0) $display(">>> CASE 1 SUCCESS\n");
        else $display(">>> CASE 1 FAILED\n");

        #100;
        reset_caps();
        @(negedge clk); start = 1; encrypt = 0; @(negedge clk); start = 0;
        setup_key_nonce();
        send_aad();
        for (i = 0; i < 29; i = i + 1) send_word(3'd3, ct_words[i], (i == 28) ? 3'd2 : 3'd4, (i == 28) ? 1'b1 : 1'b0);
        send_word(3'd4, 32'd0, 3'd4, 1'b1);
        while(cap_tag_idx < 4) @(negedge clk);
        
        $display("\n=======================================================");
        $display(" CASE 2: RFC 7539 DECRYPTION CHECK");
        $display("=======================================================");
        for (i = 0; i < 29; i = i + 1) begin
            if (cap_ct[i] !== pt_words[i]) begin
                $display("[FAIL] PT[%02d] : Output = %08x | Expected = %08x", i, cap_ct[i], pt_words[i]);
                err_ct = err_ct + 1;
            end else begin
                $display("[PASS] PT[%02d] : Output = %08x | Expected = %08x", i, cap_ct[i], pt_words[i]);
            end
        end
        $display("-------------------------------------------------------");
        if (cap_tag[0] !== 32'h1ae10b59) begin $display("[FAIL] TAG[0] : Output = %08x | Expected = 1ae10b59", cap_tag[0]); err_tag = err_tag + 1; end else $display("[PASS] TAG[0] : Output = %08x | Expected = 1ae10b59", cap_tag[0]);
        if (cap_tag[1] !== 32'h4f09e26a) begin $display("[FAIL] TAG[1] : Output = %08x | Expected = 4f09e26a", cap_tag[1]); err_tag = err_tag + 1; end else $display("[PASS] TAG[1] : Output = %08x | Expected = 4f09e26a", cap_tag[1]);
        if (cap_tag[2] !== 32'h7e902ecb) begin $display("[FAIL] TAG[2] : Output = %08x | Expected = 7e902ecb", cap_tag[2]); err_tag = err_tag + 1; end else $display("[PASS] TAG[2] : Output = %08x | Expected = 7e902ecb", cap_tag[2]);
        if (cap_tag[3] !== 32'hd0600691) begin $display("[FAIL] TAG[3] : Output = %08x | Expected = d0600691", cap_tag[3]); err_tag = err_tag + 1; end else $display("[PASS] TAG[3] : Output = %08x | Expected = d0600691", cap_tag[3]);
        
        if (err_ct == 0 && err_tag == 0) $display(">>> CASE 2 SUCCESS\n");
        else $display(">>> CASE 2 FAILED\n");

        #100;
        reset_caps();
        @(negedge clk); start = 1; encrypt = 1; @(negedge clk); start = 0;
        setup_key_nonce();
        send_aad();
        for (i = 0; i < 75; i = i + 1) begin
            dyn_pt[i] = 32'haabbccdd ^ i;
            send_word(3'd3, dyn_pt[i], 3'd4, (i == 74) ? 1'b1 : 1'b0);
        end
        send_word(3'd4, 32'd0, 3'd4, 1'b1);
        while(cap_tag_idx < 4) @(negedge clk);
        
        for (i = 0; i < 75; i = i + 1) dyn_ct[i] = cap_ct[i];
        for (i = 0; i < 4; i = i + 1) dyn_tag[i] = cap_tag[i];
        $display("\n=======================================================");
        $display(" CASE 3: LARGE PAYLOAD ENCRYPTION (No Expected Data to show)");
        $display("=======================================================");
        $display(">>> CASE 3 DONE (Data Saved for Case 4)\n");

        #100;
        reset_caps();
        @(negedge clk); start = 1; encrypt = 0; @(negedge clk); start = 0;
        setup_key_nonce();
        send_aad();
        for (i = 0; i < 75; i = i + 1) begin
            send_word(3'd3, dyn_ct[i], 3'd4, (i == 74) ? 1'b1 : 1'b0);
        end
        send_word(3'd4, 32'd0, 3'd4, 1'b1);
        while(cap_tag_idx < 4) @(negedge clk);
        
        $display("\n=======================================================");
        $display(" CASE 4: LARGE PAYLOAD DECRYPTION CHECK");
        $display("=======================================================");
        for (i = 0; i < 75; i = i + 1) begin
            if (cap_ct[i] !== dyn_pt[i]) begin
                $display("[FAIL] PT[%02d] : Output = %08x | Expected = %08x", i, cap_ct[i], dyn_pt[i]);
                err_ct = err_ct + 1;
            end else begin
                $display("[PASS] PT[%02d] : Output = %08x | Expected = %08x", i, cap_ct[i], dyn_pt[i]);
            end
        end
        $display("-------------------------------------------------------");
        for (i = 0; i < 4; i = i + 1) begin
            if (cap_tag[i] !== dyn_tag[i]) begin
                $display("[FAIL] TAG[%0d] : Output = %08x | Expected = %08x", i, cap_tag[i], dyn_tag[i]);
                err_tag = err_tag + 1;
            end else begin
                $display("[PASS] TAG[%0d] : Output = %08x | Expected = %08x", i, cap_tag[i], dyn_tag[i]);
            end
        end
        
        if (err_ct == 0 && err_tag == 0) $display(">>> CASE 4 SUCCESS\n");
        else $display(">>> CASE 4 FAILED\n");

        #100; $finish;
    end
endmodule