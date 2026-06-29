`timescale 1ns / 1ps

module tb_BF();
	reg clk;
    reg [31:0] I;
    reg load_en;
    reg [3:0] read_addr;
    reg ready;
    wire [31:0] O;
    wire finish;

    // 2. Khởi tạo BlockFunction (KHÔNG SỬA CODE BÊN TRONG)
    BlockFunction dut (
        .clk(clk),
        .I(I),
        .load_en(load_en),
        .read_addr(read_addr),
        .ready(ready),
        .O(O),
        .finish(finish)
    );

    // 3. Tạo xung Clock 100MHz
    always #5 clk = ~clk;

    // 4. Mảng chứa cấu hình cho từng Test Vector
    reg [31:0] current_key [0:7];
    reg [31:0] current_nonce [0:2];
    reg [31:0] current_ctr;
    reg [31:0] current_expected [0:15];
    
    integer total_errors = 0;

    // =========================================================================
    // TASK: HÀM TỰ ĐỘNG CHẠY KIỂM THỬ CHO 1 TEST VECTOR
    // =========================================================================
    task run_test_vector;
        input integer tv_id;
        integer k;
        integer local_error;
        begin
            local_error = 0;
            $display("==================================================");
            $display("BAT DAU CHAY TEST VECTOR #%0d", tv_id);
            $display("==================================================");

            // Bước 1: Đưa tín hiệu về 0 để Reset FSM và load_cnt
            ready = 0;
            load_en = 0;
            read_addr = 0;
            I = 0;
            @(negedge clk);
            @(negedge clk);

            // Bước 2: Nạp dữ liệu trong đúng 16 nhịp Clock
            // Mạch tự động tăng load_cnt từ 0 -> 15
            load_en = 1;
            for (k = 0; k < 16; k = k + 1) begin
                if (k < 4)       I = 32'h0; // Constant (không quan trọng vì mạch tự lấy hằng số)
                else if (k < 12) I = current_key[k-4];
                else if (k == 12) I = current_ctr;
                else             I = current_nonce[k-13];
                @(negedge clk);
            end
            load_en = 0;

            // Bước 3: Ra lệnh cho mạch chạy 20 vòng mã hóa
            ready = 1;
            wait(finish == 1'b1); // Chờ cờ finish bật lên
            @(negedge clk);
            ready = 0;

            // Bước 4: Kiểm tra kết quả "ChaCha state at the end"
            $display("-> Doi chieu ChaCha State at the end:");
            for (k = 0; k < 16; k = k + 1) begin
                read_addr = k[3:0]; // Chuyển index để mạch xuất ra ngõ O
                #1; // Delay 1ns để mạch tổ hợp kịp cập nhật ngõ ra O
                
                if (O !== current_expected[k]) begin
                    $display("  [LỖI] Word %02d | Out: %h | Exp: %h", k, O, current_expected[k]);
                    local_error = local_error + 1;
                end
                @(negedge clk);
            end

            // Bước 5: Đánh giá
            if (local_error == 0) begin
                $display("=> [PASSED] Test Vector #%0d khop CHINH XAC 16 Words!\n", tv_id);
            end else begin
                $display("=> [FAILED] Test Vector #%0d sai %0d Words.\n", tv_id, local_error);
                total_errors = total_errors + local_error;
            end
        end
    endtask

    // =========================================================================
    // KHỐI CHẠY CHÍNH
    // =========================================================================
    initial begin
        clk = 0;
        #25; 

        // ----------------------------------------------------
        // CHẠY TEST VECTOR #1
        // ----------------------------------------------------
        current_key[0]=32'h0; current_key[1]=32'h0; current_key[2]=32'h0; current_key[3]=32'h0;
        current_key[4]=32'h0; current_key[5]=32'h0; current_key[6]=32'h0; current_key[7]=32'h0;
        current_ctr = 32'h0;
        current_nonce[0]=32'h0; current_nonce[1]=32'h0; current_nonce[2]=32'h0;

        current_expected[0]=32'hade0b876; current_expected[1]=32'h903df1a0; current_expected[2]=32'he56a5d40; current_expected[3]=32'h28bd8653;
        current_expected[4]=32'hb819d2bd; current_expected[5]=32'h1aed8da0; current_expected[6]=32'hccef36a8; current_expected[7]=32'hc70d778b;
        current_expected[8]=32'h7c5941da; current_expected[9]=32'h8d485751; current_expected[10]=32'h3fe02477; current_expected[11]=32'h374ad8b8;
        current_expected[12]=32'hf4b8436a; current_expected[13]=32'h1ca11815; current_expected[14]=32'h69b687c3; current_expected[15]=32'h8665eeb2;

        run_test_vector(1);

        // ----------------------------------------------------
        // CHẠY TEST VECTOR #2
        // ----------------------------------------------------
        current_key[0]=32'h0; current_key[1]=32'h0; current_key[2]=32'h0; current_key[3]=32'h0;
        current_key[4]=32'h0; current_key[5]=32'h0; current_key[6]=32'h0; current_key[7]=32'h0;
        current_ctr = 32'h1; // Block Counter = 1
        current_nonce[0]=32'h0; current_nonce[1]=32'h0; current_nonce[2]=32'h0;

        current_expected[0]=32'hbee7079f; current_expected[1]=32'h7a385155; current_expected[2]=32'h7c97ba98; current_expected[3]=32'h0d082d73;
        current_expected[4]=32'ha0290fcb; current_expected[5]=32'h6965e348; current_expected[6]=32'h3e53c612; current_expected[7]=32'hed7aee32;
        current_expected[8]=32'h7621b729; current_expected[9]=32'h434ee69c; current_expected[10]=32'hb03371d5; current_expected[11]=32'hd539d874;
        current_expected[12]=32'h281fed31; current_expected[13]=32'h45fb0a51; current_expected[14]=32'h1f0ae1ac; current_expected[15]=32'h6f4d794b;

        run_test_vector(2);

        // ----------------------------------------------------
        // CHẠY TEST VECTOR #3
        // ----------------------------------------------------
        current_key[0]=32'h0; current_key[1]=32'h0; current_key[2]=32'h0; current_key[3]=32'h0;
        current_key[4]=32'h0; current_key[5]=32'h0; current_key[6]=32'h0; 
        current_key[7]=32'h01000000; // Byte cuối cùng là 01 -> Chuẩn Little Endian là 0x01000000
        current_ctr = 32'h1; // Block Counter = 1
        current_nonce[0]=32'h0; current_nonce[1]=32'h0; current_nonce[2]=32'h0;

        current_expected[0]=32'h2452eb3a; current_expected[1]=32'h9249f8ec; current_expected[2]=32'h8d829d9b; current_expected[3]=32'hddd4ceb1;
        current_expected[4]=32'he8252083; current_expected[5]=32'h60818b01; current_expected[6]=32'hf38422b8; current_expected[7]=32'h5aaa49c9;
        current_expected[8]=32'hbb00ca8e; current_expected[9]=32'hda3ba7b4; current_expected[10]=32'hc4b592d1; current_expected[11]=32'hfdf2732f;
        current_expected[12]=32'h4436274e; current_expected[13]=32'h2561b3c8; current_expected[14]=32'hebdd4aa6; current_expected[15]=32'ha0136c00;

        run_test_vector(3);

        // ----------------------------------------------------
        // CHẠY TEST VECTOR #4
        // RFC 8439 - Key có byte 1 là 0xff, counter = 2
        // ----------------------------------------------------
        // SỬA LỖI Ở ĐÂY: current_key[0] = 0x0000ff00
        current_key[0]=32'h0000ff00; current_key[1]=32'h00000000;
        current_key[2]=32'h00000000; current_key[3]=32'h00000000;
        current_key[4]=32'h00000000; current_key[5]=32'h00000000;
        current_key[6]=32'h00000000; current_key[7]=32'h00000000;

        current_ctr = 32'h00000002; 

        current_nonce[0]=32'h00000000;
        current_nonce[1]=32'h00000000;
        current_nonce[2]=32'h00000000;

        // Trả lại nguyên bản các giá trị Expected đúng của bạn
        current_expected[0]  = 32'hfb4dd572;
        current_expected[1]  = 32'h4bc42ef1;
        current_expected[2]  = 32'hdf922636;
        current_expected[3]  = 32'h327f1394;
        current_expected[4]  = 32'ha78dea8f;
        current_expected[5]  = 32'h5e269039;
        current_expected[6]  = 32'ha1bebbc1;
        current_expected[7]  = 32'hcaf09aae;
        current_expected[8]  = 32'ha25ab213;
        current_expected[9]  = 32'h48a6b46c;
        current_expected[10] = 32'h1b9d9bcb;
        current_expected[11] = 32'h092c5be6;
        current_expected[12] = 32'h546ca624;
        current_expected[13] = 32'h1bec45d5;
        current_expected[14] = 32'h87f47473;
        current_expected[15] = 32'h96f0992e;

        run_test_vector(4);

        // ----------------------------------------------------
        // CHẠY TEST VECTOR #5
        // RFC 8439 - Nonce có byte 11 là 0x02
        // ----------------------------------------------------
        current_key[0]=32'h00000000; current_key[1]=32'h00000000;
        current_key[2]=32'h00000000; current_key[3]=32'h00000000;
        current_key[4]=32'h00000000; current_key[5]=32'h00000000;
        current_key[6]=32'h00000000; current_key[7]=32'h00000000;

        current_ctr = 32'h00000000;

        current_nonce[0]=32'h00000000;
        current_nonce[1]=32'h00000000;
        // SỬA LỖI Ở ĐÂY: current_nonce[2] = 0x02000000
        current_nonce[2]=32'h02000000;

        // Trả lại nguyên bản các giá trị Expected đúng của bạn
        current_expected[0]  = 32'h374dc6c2;
        current_expected[1]  = 32'h3736d58c;
        current_expected[2]  = 32'hb904e24a;
        current_expected[3]  = 32'hcd3f93ef;
        current_expected[4]  = 32'h88228b1a;
        current_expected[5]  = 32'h96a4dfb3;
        current_expected[6]  = 32'h5b76ab72;
        current_expected[7]  = 32'hc727ee54;
        current_expected[8]  = 32'h0e0e978a;
        current_expected[9]  = 32'hf3145c95;
        current_expected[10] = 32'h1b748ea8;
        current_expected[11] = 32'hf786c297;
        current_expected[12] = 32'h99c28f5f;
        current_expected[13] = 32'h628314e8;
        current_expected[14] = 32'h398a19fa;
        current_expected[15] = 32'h6ded1b53;

        run_test_vector(5);
        // =====================================================================
        // TỔNG KẾT
        // =====================================================================
        $display("==================================================");
        if (total_errors == 0) begin
            $display("BlockFunction pass % Test Vectors!");
        end else begin
            $display("[FAIL] %0d errors existed during test.", total_errors);
        end
        $display("==================================================");

        #50;
        $finish;
    end

endmodule
