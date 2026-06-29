`timescale 1ns / 1ps

module Testbench();
    reg clk, start, encrypt, valid, is_last;
    reg [31:0] I;
    reg [2:0] byte_vld, type_in;
    
    wire ready, valid_out, finish;
    wire [31:0] O, tag_out;

    // =========================================================================
    // 2. KHỞI TẠO MODULE CẦN KIỂM THỬ (DUT)
    // =========================================================================
    ChachaPoly_AEAD dut (
        .clk(clk), .start(start), .encrypt(encrypt),
        .I(I), .byte_vld(byte_vld), .type_in(type_in),
        .valid(valid), .is_last(is_last),
        .ready(ready), .O(O), .valid_out(valid_out),
        .tag_out(tag_out), .finish(finish)
    );

    // =========================================================================
    // 3. TẠO XUNG CLOCK & TIMEOUT
    // =========================================================================
    always #5 clk = ~clk;

    initial begin
        #5000000; 
        $display("\nFATAL: TIMEOUT!");
        $finish;
    end

    // =========================================================================
    // 4. MẢNG LƯU TRỮ TEST VECTORS
    // =========================================================================
    // Vector 1 (RFC Encrypt - 114 bytes)
    reg [31:0] pt_words [0:28];
    reg [31:0] ct_words [0:28];
    
    // Vector 2 (RFC Decrypt - 265 bytes)
    reg [31:0] pt_dec_words [0:66];
    reg [31:0] ct_dec_words [0:66];

    // Mảng hứng dữ liệu từ DUT
    reg [31:0] cap_ct [0:299];
    reg [31:0] cap_tag [0:3];
    integer cap_ct_idx;
    integer cap_tag_idx;

    // Bắt ngõ ra O và Tag
    always @(posedge clk) begin
        if (valid_out) begin
            cap_ct[cap_ct_idx] <= O;
            cap_ct_idx <= cap_ct_idx + 1;
        end
        if (finish) begin
            cap_tag[cap_tag_idx] <= tag_out;
            cap_tag_idx <= cap_tag_idx + 1;
        end
    end

    // =========================================================================
    // 5. CÁC TASK GIAO TIẾP VỚI MODULE
    // =========================================================================
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

    task setup_key_nonce_vec1;
        begin
            // Key
            send_word(3'd0, 32'h80818283, 3'd4, 1'b0);
            send_word(3'd0, 32'h84858687, 3'd4, 1'b0);
            send_word(3'd0, 32'h88898a8b, 3'd4, 1'b0);
            send_word(3'd0, 32'h8c8d8e8f, 3'd4, 1'b0);
            send_word(3'd0, 32'h90919293, 3'd4, 1'b0);
            send_word(3'd0, 32'h94959697, 3'd4, 1'b0);
            send_word(3'd0, 32'h98999a9b, 3'd4, 1'b0);
            send_word(3'd0, 32'h9c9d9e9f, 3'd4, 1'b0);
            // Nonce
            send_word(3'd1, 32'h07000000, 3'd4, 1'b0);
            send_word(3'd1, 32'h40414243, 3'd4, 1'b0);
            send_word(3'd1, 32'h44454647, 3'd4, 1'b0);
        end
    endtask

    task send_aad_vec1;
        begin
            send_word(3'd2, 32'h50515253, 3'd4, 1'b0);
            send_word(3'd2, 32'hc0c1c2c3, 3'd4, 1'b0);
            send_word(3'd2, 32'hc4c5c6c7, 3'd4, 1'b1);
        end
    endtask

    task setup_key_nonce_vec2;
        begin
            // Key
            send_word(3'd0, 32'h1c9240a5, 3'd4, 1'b0);
            send_word(3'd0, 32'heb55d38a, 3'd4, 1'b0);
            send_word(3'd0, 32'hf3338886, 3'd4, 1'b0);
            send_word(3'd0, 32'h04f6b5f0, 3'd4, 1'b0);
            send_word(3'd0, 32'h473917c1, 3'd4, 1'b0);
            send_word(3'd0, 32'h402b8009, 3'd4, 1'b0);
            send_word(3'd0, 32'h9dca5cbc, 3'd4, 1'b0);
            send_word(3'd0, 32'h207075c0, 3'd4, 1'b0);
            // Nonce
            send_word(3'd1, 32'h00000000, 3'd4, 1'b0);
            send_word(3'd1, 32'h01020304, 3'd4, 1'b0);
            send_word(3'd1, 32'h05060708, 3'd4, 1'b0);
        end
    endtask

    task send_aad_vec2;
        begin
            send_word(3'd2, 32'hf3338886, 3'd4, 1'b0);
            send_word(3'd2, 32'h00000000, 3'd4, 1'b0);
            send_word(3'd2, 32'h00004e91, 3'd4, 1'b1);
        end
    endtask

    task reset_caps;
        begin
            cap_ct_idx = 0; cap_tag_idx = 0; err_ct = 0; err_tag = 0;
        end
    endtask

    integer i, err_ct, err_tag;

    // =========================================================================
    // 6. KHỐI ĐIỀU KHIỂN CHÍNH (MAIN BENCH)
    // =========================================================================
    initial begin
        clk = 0; start = 0; encrypt = 1; valid = 0; is_last = 0; I = 0; byte_vld = 0; type_in = 0;
        reset_caps();
        #50;

        // --- KHỞI TẠO DATA TEST VECTOR 1 ---
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

        // --- KHỞI TẠO DATA TEST VECTOR 2 ---
        ct_dec_words[0]=32'h64a08615; ct_dec_words[1]=32'h75861af4; ct_dec_words[2]=32'h60f062c7; ct_dec_words[3]=32'h9be643bd;
        ct_dec_words[4]=32'h5e805cfd; ct_dec_words[5]=32'h345cf389; ct_dec_words[6]=32'hf108670a; ct_dec_words[7]=32'hc76c8cb2;
        ct_dec_words[8]=32'h4c6cfc18; ct_dec_words[9]=32'h755d43ee; ct_dec_words[10]=32'ha09ee94e; ct_dec_words[11]=32'h382d26b0;
        ct_dec_words[12]=32'hbdb7b73c; ct_dec_words[13]=32'h321b0100; ct_dec_words[14]=32'hd4f03b7f; ct_dec_words[15]=32'h355894cf;
        ct_dec_words[16]=32'h332f830e; ct_dec_words[17]=32'h710b97ce; ct_dec_words[18]=32'h98c8a84a; ct_dec_words[19]=32'hbd0b9481;
        ct_dec_words[20]=32'h14ad176e; ct_dec_words[21]=32'h008d33bd; ct_dec_words[22]=32'h60f982b1; ct_dec_words[23]=32'hff37c855;
        ct_dec_words[24]=32'h9797a06e; ct_dec_words[25]=32'hf4f0ef61; ct_dec_words[26]=32'hc186324e; ct_dec_words[27]=32'h2b350638;
        ct_dec_words[28]=32'h3606907b; ct_dec_words[29]=32'h6a7c02b0; ct_dec_words[30]=32'hf9f6157b; ct_dec_words[31]=32'h53c867e4;
        ct_dec_words[32]=32'hb9166c76; ct_dec_words[33]=32'h7b804d46; ct_dec_words[34]=32'ha59b5216; ct_dec_words[35]=32'hcde7a4e9;
        ct_dec_words[36]=32'h9040c5a4; ct_dec_words[37]=32'h0433225e; ct_dec_words[38]=32'he282a1b0; ct_dec_words[39]=32'ha06c523e;
        ct_dec_words[40]=32'haf4534d7; ct_dec_words[41]=32'hf83fa115; ct_dec_words[42]=32'h5b004771; ct_dec_words[43]=32'h8cbc546a;
        ct_dec_words[44]=32'h0d072b04; ct_dec_words[45]=32'hb3564eea; ct_dec_words[46]=32'h1b422273; ct_dec_words[47]=32'hf548271a;
        ct_dec_words[48]=32'h0bb23160; ct_dec_words[49]=32'h53fa7699; ct_dec_words[50]=32'h1955ebd6; ct_dec_words[51]=32'h3159434e;
        ct_dec_words[52]=32'hcebb4e46; ct_dec_words[53]=32'h6dae5a10; ct_dec_words[54]=32'h73a67276; ct_dec_words[55]=32'h27097a10;
        ct_dec_words[56]=32'h49e617d9; ct_dec_words[57]=32'h1d361094; ct_dec_words[58]=32'hfa68f0ff; ct_dec_words[59]=32'h77987130;
        ct_dec_words[60]=32'h305beaba; ct_dec_words[61]=32'h2eda04df; ct_dec_words[62]=32'h997b714d; ct_dec_words[63]=32'h6c6f2c29;
        ct_dec_words[64]=32'ha6ad5cb4; ct_dec_words[65]=32'h022b0270; ct_dec_words[66]=32'h9b000000;

        pt_dec_words[0]=32'h496e7465; pt_dec_words[1]=32'h726e6574; pt_dec_words[2]=32'h2d447261; pt_dec_words[3]=32'h66747320;
        pt_dec_words[4]=32'h61726520; pt_dec_words[5]=32'h64726166; pt_dec_words[6]=32'h7420646f; pt_dec_words[7]=32'h63756d65;
        pt_dec_words[8]=32'h6e747320; pt_dec_words[9]=32'h76616c69; pt_dec_words[10]=32'h6420666f; pt_dec_words[11]=32'h72206120;
        pt_dec_words[12]=32'h6d617869; pt_dec_words[13]=32'h6d756d20; pt_dec_words[14]=32'h6f662073; pt_dec_words[15]=32'h6978206d;
        pt_dec_words[16]=32'h6f6e7468; pt_dec_words[17]=32'h7320616e; pt_dec_words[18]=32'h64206d61; pt_dec_words[19]=32'h79206265;
        pt_dec_words[20]=32'h20757064; pt_dec_words[21]=32'h61746564; pt_dec_words[22]=32'h2c207265; pt_dec_words[23]=32'h706c6163;
        pt_dec_words[24]=32'h65642c20; pt_dec_words[25]=32'h6f72206f; pt_dec_words[26]=32'h62736f6c; pt_dec_words[27]=32'h65746564;
        pt_dec_words[28]=32'h20627920; pt_dec_words[29]=32'h6f746865; pt_dec_words[30]=32'h7220646f; pt_dec_words[31]=32'h63756d65;
        pt_dec_words[32]=32'h6e747320; pt_dec_words[33]=32'h61742061; pt_dec_words[34]=32'h6e792074; pt_dec_words[35]=32'h696d652e;
        pt_dec_words[36]=32'h20497420; pt_dec_words[37]=32'h69732069; pt_dec_words[38]=32'h6e617070; pt_dec_words[39]=32'h726f7072;
        pt_dec_words[40]=32'h69617465; pt_dec_words[41]=32'h20746f20; pt_dec_words[42]=32'h75736520; pt_dec_words[43]=32'h496e7465;
        pt_dec_words[44]=32'h726e6574; pt_dec_words[45]=32'h2d447261; pt_dec_words[46]=32'h66747320; pt_dec_words[47]=32'h61732072;
        pt_dec_words[48]=32'h65666572; pt_dec_words[49]=32'h656e6365; pt_dec_words[50]=32'h206d6174; pt_dec_words[51]=32'h65726961;
        pt_dec_words[52]=32'h6c206f72; pt_dec_words[53]=32'h20746f20; pt_dec_words[54]=32'h63697465; pt_dec_words[55]=32'h20746865;
        pt_dec_words[56]=32'h6d206f74; pt_dec_words[57]=32'h68657220; pt_dec_words[58]=32'h7468616e; pt_dec_words[59]=32'h20617320;
        pt_dec_words[60]=32'h2fe2809c; pt_dec_words[61]=32'h776f726b; pt_dec_words[62]=32'h20696e20; pt_dec_words[63]=32'h70726f67;
        pt_dec_words[64]=32'h72657373; pt_dec_words[65]=32'h2e2fe280; pt_dec_words[66]=32'h9d000000;


        // =====================================================================
        // CASE 1: RFC 8439 ENCRYPTION (LADIES AND GENTLEMEN)
        // =====================================================================
        @(negedge clk); start = 1; encrypt = 1; @(negedge clk); start = 0;
        setup_key_nonce_vec1();
        send_aad_vec1();
        for (i = 0; i < 29; i = i + 1) send_word(3'd3, pt_words[i], (i == 28) ? 3'd2 : 3'd4, (i == 28) ? 1'b1 : 1'b0);
        send_word(3'd4, 32'd0, 3'd4, 1'b1); // Gửi cờ hoàn tất block
        while(cap_tag_idx < 4) @(negedge clk);
        
        $display("\n=======================================================");
        $display(" CASE 1: RFC 8439 ENCRYPTION CHECK");
        $display("=======================================================");
        for (i = 0; i < 29; i = i + 1) begin
            if (cap_ct[i] !== ct_words[i]) begin
                $display("[FAIL] CT[%02d] : Output = %08x | Expected = %08x", i, cap_ct[i], ct_words[i]);
                err_ct = err_ct + 1;
            end
        end
        
        if (cap_tag[0] !== 32'h1ae10b59) err_tag = err_tag + 1;
        if (cap_tag[1] !== 32'h4f09e26a) err_tag = err_tag + 1;
        if (cap_tag[2] !== 32'h7e902ecb) err_tag = err_tag + 1;
        if (cap_tag[3] !== 32'hd0600691) err_tag = err_tag + 1;
        
        if (err_ct == 0 && err_tag == 0) $display(">>> CASE 1 SUCCESS\n");
        else $display(">>> CASE 1 FAILED (Err CT: %0d, Err Tag: %0d)\n", err_ct, err_tag);


        // =====================================================================
        // CASE 2: REVERSE DECRYPTION OF VECTOR 1 (CT -> PT)
        // =====================================================================
        #100;
        reset_caps();
        @(negedge clk); start = 1; encrypt = 0; @(negedge clk); start = 0;
        setup_key_nonce_vec1();
        send_aad_vec1();
        for (i = 0; i < 29; i = i + 1) send_word(3'd3, ct_words[i], (i == 28) ? 3'd2 : 3'd4, (i == 28) ? 1'b1 : 1'b0);
        send_word(3'd4, 32'd0, 3'd4, 1'b1);
        while(cap_tag_idx < 4) @(negedge clk);
        
        $display("\n=======================================================");
        $display(" CASE 2: REVERSE DECRYPTION CHECK (VECTOR 1)");
        $display("=======================================================");
        for (i = 0; i < 29; i = i + 1) begin
            if (cap_ct[i] !== pt_words[i]) err_ct = err_ct + 1;
        end
        if (cap_tag[0] !== 32'h1ae10b59) err_tag = err_tag + 1;
        if (cap_tag[1] !== 32'h4f09e26a) err_tag = err_tag + 1;
        if (cap_tag[2] !== 32'h7e902ecb) err_tag = err_tag + 1;
        if (cap_tag[3] !== 32'hd0600691) err_tag = err_tag + 1;
        
        if (err_ct == 0 && err_tag == 0) $display(">>> CASE 2 SUCCESS\n");
        else $display(">>> CASE 2 FAILED (Err CT: %0d, Err Tag: %0d)\n", err_ct, err_tag);


        // =====================================================================
        // CASE 3: RFC 8439 DECRYPTION (INTERNET-DRAFTS - 265 BYTES)
        // =====================================================================
        #100;
        reset_caps();
        @(negedge clk); start = 1; encrypt = 0; @(negedge clk); start = 0;
        setup_key_nonce_vec2();
        send_aad_vec2();
        // 265 bytes = 66 words + 1 byte => word cuối cùng byte_vld = 1
        for (i = 0; i < 67; i = i + 1) send_word(3'd3, ct_dec_words[i], (i == 66) ? 3'd1 : 3'd4, (i == 66) ? 1'b1 : 1'b0);
        send_word(3'd4, 32'd0, 3'd4, 1'b1);
        while(cap_tag_idx < 4) @(negedge clk);
        
        $display("\n=======================================================");
        $display(" CASE 3: RFC 8439 DECRYPTION CHECK (265 Bytes Payload)");
        $display("=======================================================");
        for (i = 0; i < 67; i = i + 1) begin
            if (cap_ct[i] !== pt_dec_words[i]) begin
                $display("[FAIL] PT[%02d] : Output = %08x | Expected = %08x", i, cap_ct[i], pt_dec_words[i]);
                err_ct = err_ct + 1;
            end
        end
        
        if (cap_tag[0] !== 32'heead9d67) err_tag = err_tag + 1;
        if (cap_tag[1] !== 32'h890cbb22) err_tag = err_tag + 1;
        if (cap_tag[2] !== 32'h392336fe) err_tag = err_tag + 1;
        if (cap_tag[3] !== 32'ha1851f38) err_tag = err_tag + 1;

        if (err_ct == 0 && err_tag == 0) $display(">>> CASE 3 SUCCESS\n");
        else $display(">>> CASE 3 FAILED (Err PT: %0d, Err Tag: %0d)\n", err_ct, err_tag);


        // =====================================================================
        // CASE 4: REVERSE ENCRYPTION OF VECTOR 2 (PT -> CT)
        // =====================================================================
        #100;
        reset_caps();
        @(negedge clk); start = 1; encrypt = 1; @(negedge clk); start = 0;
        setup_key_nonce_vec2();
        send_aad_vec2();
        for (i = 0; i < 67; i = i + 1) send_word(3'd3, pt_dec_words[i], (i == 66) ? 3'd1 : 3'd4, (i == 66) ? 1'b1 : 1'b0);
        send_word(3'd4, 32'd0, 3'd4, 1'b1);
        while(cap_tag_idx < 4) @(negedge clk);
        
        $display("\n=======================================================");
        $display(" CASE 4: REVERSE ENCRYPTION CHECK (VECTOR 2)");
        $display("=======================================================");
        for (i = 0; i < 67; i = i + 1) begin
            if (cap_ct[i] !== ct_dec_words[i]) err_ct = err_ct + 1;
        end
        if (cap_tag[0] !== 32'heead9d67) err_tag = err_tag + 1;
        if (cap_tag[1] !== 32'h890cbb22) err_tag = err_tag + 1;
        if (cap_tag[2] !== 32'h392336fe) err_tag = err_tag + 1;
        if (cap_tag[3] !== 32'ha1851f38) err_tag = err_tag + 1;

        if (err_ct == 0 && err_tag == 0) $display(">>> CASE 4 SUCCESS\n");
        else $display(">>> CASE 4 FAILED (Err CT: %0d, Err Tag: %0d)\n", err_ct, err_tag);

        $display("\nAll Tests Executed.");
        #100; $finish;
    end
endmodule
