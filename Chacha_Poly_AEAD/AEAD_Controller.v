module AEAD_controller(
    input clk, start,
    input [31:0] I,          // Dữ liệu đầu vào 32-bit (1 Word)
    input [2:0] byte_vld,    // Số byte hợp lệ trong Word hiện tại (1 đến 4)
    input [2:0] type_in,     // Loại dữ liệu: 0 (Key R), 1 (Key S), 2 (AAD), 3 (Ciphertext), 4 (Lệnh End)
    input valid, is_last,    // valid = 1 khi có dữ liệu mới; is_last = 1 báo hiệu Word cuối cùng của chuỗi
    
    output ready,            // = 1 khi Controller sẵn sàng nhận Word tiếp theo
    
    // =========================================================================
    // 2. CỔNG GIAO TIẾP VỚI LÕI POLYMAC BÊN DƯỚI
    // =========================================================================
    output reg [31:0] mac_I,     // Dữ liệu đã được tiền xử lý (mask rác, độn 0) bơm vào PolyMAC
    output mac_start, mac_in_r, mac_in_s, mac_data_in, // Các tín hiệu ra lệnh nạp khóa/dữ liệu
    output [4:0] mac_msg_bytes, // Số byte hợp lệ gửi xuống PolyMAC (luôn ép cứng là 16)
    input mac_finish,        // Cờ báo hiệu từ PolyMAC: Đã băm xong 1 block
    output finish            // Cờ báo hiệu tổng: Toàn bộ quá trình AEAD đã hoàn tất
);

    // =========================================================================
    // 3. KHAI BÁO THANH GHI NỘI BỘ (REGISTERS)
    // =========================================================================
    reg [2:0] state;         // Trạng thái của FSM (0 đến 5)
    reg [1:0] word_cnt;      // Bộ đếm từ 0->3 (Tương đương 4 Words = 16 bytes = 1 Block chuẩn)
    reg [31:0] aad_len, ctx_len; // Thanh ghi tích lũy chiều dài thực tế của AAD và Ciphertext

    // =========================================================================
    // 4. MẠCH THEO DÕI TRẠNG THÁI BẬN CỦA POLYMAC (BUSY TRACKER)
    // =========================================================================
    reg mac_busy;            // = 1 khi PolyMAC đang băm dữ liệu, = 0 khi rảnh
    reg [1:0] finish_cnt;    // Đếm số chu kỳ xung nhịp để chờ PolyMAC xả xong kết quả Tag
    
    always @(posedge clk) begin
        if (start) begin
            mac_busy <= 1'b0;
            finish_cnt <= 2'd0;
        end else begin
            // Khi PolyMAC báo finish, đếm đủ 3 chu kỳ (vì MAC Tag đẩy ra mất 4 chu kỳ cho 4 Words)
            if (mac_finish) finish_cnt <= finish_cnt + 1'b1;
            else finish_cnt <= 2'd0;

            // Nếu đã bơm đủ 4 Words (word_cnt == 3), chốt cửa lại (busy = 1) để PolyMAC tính toán
            if (mac_data_in && word_cnt == 2'd3) mac_busy <= 1'b1; 
            // Khi PolyMAC xả xong Tag (finish_cnt == 3), mở cửa lại (busy = 0)
            else if (finish_cnt == 2'd3) mac_busy <= 1'b0;         
        end
    end

    // =========================================================================
    // 5. MẠCH LÀM SẠCH DỮ LIỆU (DATA MASKING)
    // =========================================================================
    // Xóa các byte "rác" thành 0 dựa vào tín hiệu byte_vld để PolyMAC không băm nhầm rác
    wire [31:0] masked_I = (byte_vld == 3'd0) ? 32'd0 :
                           (byte_vld == 3'd1) ? {24'd0, I[7:0]} :
                           (byte_vld == 3'd2) ? {16'd0, I[15:0]} :
                           (byte_vld == 3'd3) ? {8'd0, I[23:0]} : I;

    // =========================================================================
    // 6. MẠCH ĐỊNH TUYẾN TÍN HIỆU ĐIỀU KHIỂN (ROUTING LOGIC)
    // =========================================================================
    assign mac_start = start;
    
    // Chỉ cho phép nạp khóa R/S khi mạch đang rảnh (!mac_busy) và đúng loại (type_in)
    assign mac_in_r = valid && (type_in == 3'd0) && !mac_busy;
    assign mac_in_s = valid && (type_in == 3'd1) && !mac_busy;
    
    // Mở cổng nạp dữ liệu (data_in) cho PolyMAC trong các trường hợp:
    // - Khi Top module bơm AAD (2) hoặc CTX (3) hợp lệ.
    // - Khi FSM tự động sinh các Word đệm 0 (state 1, 3).
    // - Khi FSM gửi block chiều dài (state 4).
    assign mac_data_in = (!mac_busy && ((valid && (type_in == 3'd2 || type_in == 3'd3) && (state == 3'd0 || state == 3'd2)) ||
                         (state == 3'd1) || (state == 3'd3) || (state == 3'd4))) ? 1'b1 : 1'b0;

    // Báo cho PolyMAC biết mỗi block bơm xuống luôn luôn đủ 16 bytes (128-bit)
    assign mac_msg_bytes = 5'd16; 

    // Bộ chọn đa kênh (MUX) cấp dữ liệu thực tế xuống chân mac_I của PolyMAC:
    // - Nếu đang ở State 1 hoặc 3 (Padding): Bơm số 0 (32'd0).
    // - Nếu đang ở State 4 (Block Length): Lần lượt bơm chiều dài AAD và CTX.
    // - Nếu không phải các trường hợp trên: Bơm dữ liệu thật đã được làm sạch (masked_I).
    always @(*) begin
        if (state == 3'd1 || state == 3'd3) mac_I = 32'd0;
        else if (state == 3'd4) begin
            case (word_cnt)
                2'd0: mac_I = aad_len;    // Word 1: AAD Length (32-bit thấp)
                2'd1: mac_I = 32'd0;      // Word 2: AAD Length (32-bit cao = 0)
                2'd2: mac_I = ctx_len;    // Word 3: CTX Length (32-bit thấp)
                default:
                    mac_I = 32'd0;        // Word 4: CTX Length (32-bit cao = 0)
            endcase
        end
        else mac_I = masked_I;
    end

    // =========================================================================
    // 7. MÁY TRẠNG THÁI FSM (FINITE STATE MACHINE)
    // =========================================================================
    
    // Báo ready cho Top Module chỉ khi rảnh và đang ở state chờ AAD (0) hoặc chờ CTX (2)
    assign ready = !mac_busy && (state == 3'd0 || state == 3'd2);
    
    // Phát cờ hoàn tất toàn cục khi đã nhảy đến State 5 và PolyMAC nhả cờ finish
    assign finish = (state == 3'd5) && mac_finish;

    always @(posedge clk) begin
        if (start) begin
            state <= 3'd0;
            word_cnt <= 2'd0;
            aad_len <= 32'd0;
            ctx_len <= 32'd0;
        end else begin
            // Tự động tăng bộ đếm 0->3 mỗi khi nạp 1 Word vào PolyMAC
            if (mac_in_r || mac_in_s || mac_data_in) 
                word_cnt <= word_cnt + 1'b1;

            // Cộng dồn tổng số byte nhận được (Dành riêng cho block Length ở cuối)
            if (valid && ready) begin
                if (type_in == 3'd2) aad_len <= aad_len + {29'd0, byte_vld};
                if (type_in == 3'd3) ctx_len <= ctx_len + {29'd0, byte_vld};
            end

            case (state)
                // -------------------------------------------------------------
                // STATE 0: CHỜ VÀ NHẬN AAD
                // -------------------------------------------------------------
                3'd0: begin 
                    // Nhận được Word cuối cùng (is_last = 1) của luồng AAD
                    if (valid && ready && type_in == 3'd2 && is_last) begin
                        if (word_cnt != 2'd3) state <= 3'd1; // Nếu block chưa đủ 16 byte -> Qua State 1 để đệm 0
                        else state <= 3'd2;                  // Nếu block vừa khít -> Chuyển sang nhận Ciphertext
                    end
                end
                
                // -------------------------------------------------------------
                // STATE 1: TỰ ĐỘNG ĐỆM SỐ 0 CHO AAD LẺ
                // -------------------------------------------------------------
                3'd1: begin 
                    // Chờ bơm đủ số 0 cho tới khi word_cnt = 3 (Đầy block 16 byte)
                    if (!mac_busy && word_cnt == 2'd3) state <= 3'd2;
                end
                
                // -------------------------------------------------------------
                // STATE 2: CHỜ VÀ NHẬN CIPHERTEXT (CTX)
                // -------------------------------------------------------------
                3'd2: begin 
                    // Nhận được Word cuối cùng (is_last = 1) của luồng CTX
                    if (valid && ready && type_in == 3'd3 && is_last) begin
                        if (word_cnt != 2'd3) state <= 3'd3; // Nếu block chưa đủ 16 byte -> Qua State 3 để đệm 0
                        else state <= 3'd4;                  // Nếu block vừa khít -> Chuyển sang gửi mảng Chiều dài
                    end
                end
                
                // -------------------------------------------------------------
                // STATE 3: TỰ ĐỘNG ĐỆM SỐ 0 CHO CIPHERTEXT LẺ
                // -------------------------------------------------------------
                3'd3: begin 
                    // Chờ bơm đủ số 0 cho tới khi word_cnt = 3
                    if (!mac_busy && word_cnt == 2'd3) state <= 3'd4;
                end
                
                // -------------------------------------------------------------
                // STATE 4: BƠM BLOCK CHIỀU DÀI (LENGTH BLOCK)
                // -------------------------------------------------------------
                3'd4: begin 
                    // Gửi đi 4 Words chứa (aad_len) và (ctx_len). Gửi xong thì qua State 5.
                    if (!mac_busy && word_cnt == 2'd3) state <= 3'd5;
                end
                
                default: ;
            endcase
        end
    end
endmodule
