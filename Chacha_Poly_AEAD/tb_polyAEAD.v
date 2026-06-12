`timescale 1ns / 1ps

module tb_polyAEAD;
    // Khai báo tín hi?u
    reg clk, start, valid, is_last;
    reg [31:0] I;
    reg [2:0] byte_vld, type_in;
    
    wire [31:0] O;
    wire finish, ready;

    // Kh?i t?o Top Module UUT
    PolyAEAD uut (
        .clk(clk), 
        .start(start), 
        .I(I), 
        .byte_vld(byte_vld),
        .type_in(type_in), 
        .valid(valid), 
        .is_last(is_last),
        .O(O), 
        .finish(finish), 
        .ready(ready)
    );

    // Xung Clock 10ns
    always #5 clk = ~clk;

    // Task n?p d? li?u ch? Ready
    task feed_word(input [31:0] data, input [2:0] bytes, input [2:0] t_in, input last);
    begin
        wait (ready == 1'b1);
        @(negedge clk);
        valid = 1;
        I = data;
        byte_vld = bytes;
        type_in = t_in;
        is_last = last;
        @(negedge clk);
        valid = 0;
        is_last = 0;
    end
    endtask

    // Hàm Swap dành riêng cho in Log ra màn hình mô ph?ng
    function [31:0] swap;
        input [31:0] in_word;
        begin
            swap = {in_word[7:0], in_word[15:8], in_word[23:16], in_word[31:24]};
        end
    endfunction

    reg [31:0] ctx [0:28];
    integer i;

    initial begin
        // D? li?u Ciphertext t? RFC 7539
        // ???c vi?t l?i theo m?ng Byte nguyên b?n (T? trái sang ph?i)
        ctx[0]  = 32'hd31a8d34; ctx[1]  = 32'h648e60db; ctx[2]  = 32'h7b86afbc; ctx[3]  = 32'h53ef7ec2;
        ctx[4]  = 32'ha4aded51; ctx[5]  = 32'h296e08fe; ctx[6]  = 32'ha9e2b5a7; ctx[7]  = 32'h36ee62d6;
        ctx[8]  = 32'h3dbea45e; ctx[9]  = 32'h8ca96712; 
        ctx[10] = 32'h82fafb69; // ?ã fix Typo byte 69
        ctx[11] = 32'hda92728b;
        ctx[12] = 32'h1a71de0a; ctx[13] = 32'h9e060b29; ctx[14] = 32'h05d6a5b6; ctx[15] = 32'h7ecd3b36;
        ctx[16] = 32'h92ddbd7f; ctx[17] = 32'h2d778b8c; ctx[18] = 32'h9803aee3; ctx[19] = 32'h28091b58;
        ctx[20] = 32'hfab324e4; ctx[21] = 32'hfad67594; ctx[22] = 32'h5585808b; ctx[23] = 32'h4831d7bc;
        ctx[24] = 32'h3ff4def0; ctx[25] = 32'h8e4b7a9d; ctx[26] = 32'he576d265; ctx[27] = 32'h86cec64b;
        
        // 2 Byte cu?i cùng (61 16)
        ctx[28] = 32'h61160000; 

        clk = 0; start = 0; valid = 0; I = 0;
        
        #20;
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;

        // =========================================================
        // 1. N?P KHÓA R VÀ S (D?ng chu?i byte nguyên b?n trái -> ph?i)
        // Module s? dùng hàm swap() ?? ??o l?i thành s? Little-Endian
        // =========================================================
        feed_word(32'h7bac2b25, 4, 0, 0); feed_word(32'h2db447af, 4, 0, 0);
        feed_word(32'h09b67a55, 4, 0, 0); feed_word(32'ha4e95584, 4, 0, 0);
        
        feed_word(32'h0ae1d673, 4, 1, 0); feed_word(32'h1075d9eb, 4, 1, 0);
        feed_word(32'h2a937578, 4, 1, 0); feed_word(32'h3ed553ff, 4, 1, 0);

        // =========================================================
        // 2. N?P AAD (12 bytes - Byte string: 50 51 52 53 ...)
        // =========================================================
        feed_word(32'h50515253, 4, 2, 0); 
        feed_word(32'hc0c1c2c3, 4, 2, 0); 
        feed_word(32'hc4c5c6c7, 4, 2, 1); // 4 bytes h?p l?, is_last = 1
        
        // =========================================================
        // 3. N?P CIPHERTEXT (114 bytes)
        // =========================================================
        for (i = 0; i < 28; i = i + 1) begin
            feed_word(ctx[i], 4, 3, 0);
        end
        feed_word(ctx[28], 2, 3, 1); // 2 bytes h?p l?, is_last = 1

        // =========================================================
        // 4. CH? K?T QU? VÀ HI?N TH?
        // =========================================================
        wait (finish == 1'b1);
        
        $display("\n=======================================");
        $display("      K?T QU? TAG XU?T RA (RFC 7539)");
        $display("=======================================");
        
        // In ra v?a d?ng s? (Little-Endian) v?a d?ng chu?i Byte ?? d? ??i chi?u
        @(posedge clk); 
        $display("Word 0: %08x | (K? v?ng byte: 1ae10b59)", O);
        @(posedge clk); 
        $display("Word 1: %08x | (K? v?ng byte: 4f09e26a)", O);
        @(posedge clk); 
        $display("Word 2: %08x | (K? v?ng byte: 7e902ecb)", O);
        @(posedge clk); 
        $display("Word 3: %08x | (K? v?ng byte: d0600691)", O);
        $display("=======================================\n");
        
        #100;
        $finish;
    end
endmodule