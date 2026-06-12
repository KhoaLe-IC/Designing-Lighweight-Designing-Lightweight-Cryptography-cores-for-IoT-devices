module PolyMAC(
    input clk, start, in_r, in_s, data_in, // Các tín hiệu điều khiển từ Controller
    input [4:0] msg_bytes,                 // Số lượng byte hợp lệ của khối dữ liệu hiện tại (1-16)
    input [31:0] I,                        // Cổng nhập dữ liệu 32-bit (vào Khóa r, s hoặc Message)
    output reg [31:0] O,                   // Cổng xuất MAC Tag 32-bit
    output reg finish                      // Cờ báo hiệu đã tính toán xong 1 khối hoặc đã xuất xong Tag
);

    // =========================================================================
    // BỘ NHỚ LƯU TRỮ (Registers)
    // =========================================================================
    reg [127:0] r_reg;     // Thanh ghi 128-bit chứa Khóa 'r' (Dùng trong vòng lặp nhân)
    reg [127:0] s_reg;     // Thanh ghi 128-bit chứa Khóa 's' (Dùng để cộng ở bước cuối cùng)
    reg [131:0] h;         // Bộ tích lũy (Accumulator) chính. Độ rộng 132-bit để chứa tạm các bit tràn.
    reg [137:0] Acc;       // Thanh ghi đa nhiệm: Ban đầu chứa Message, sau đó chứa kết quả tính toán tạm.
                           // Độ rộng 138-bit để chứa kết quả cộng dồn của 128 vòng lặp mà không bị tràn.

    // =========================================================================
    // CÁC BIẾN TRẠNG THÁI VÀ BỘ ĐẾM
    // =========================================================================
    reg [3:0] state;       // Biến trạng thái của Máy Trạng Thái (FSM) (Từ 0 đến 8)
    reg [1:0] in_cnt;      // Đếm số chu kỳ nạp dữ liệu vào (0 -> 3 tương đương 4 Words = 16 bytes)
    reg [1:0] out_cnt;     // Đếm số chu kỳ xuất MAC Tag ra ngoài (0 -> 3)
    reg [7:0] mul_cnt;     // Bộ đếm vòng lặp nhân 256 chu kỳ (Mỗi bit của r cần 2 chu kỳ chẵn/lẻ)

    // =========================================================================
    // BỘ GIẢI MÃ PADDING (Padding Decoder)
    // =========================================================================
    // Thuật toán Poly1305 yêu cầu chèn 1 bit '1' ngay sau byte thông điệp cuối cùng.
    // Khối case này dò tìm chính xác vị trí cần chèn bit '1' dựa vào chiều dài msg_bytes.
    reg [137:0] pad_bit;
    always @(*) begin
        pad_bit = 138'd0; // Mặc định tất cả các bit là 0
        case (msg_bytes)
            5'd1: pad_bit[8] = 1'b1;     // Nếu 1 byte, chèn số 1 ở bit thứ 8
            5'd2: pad_bit[16] = 1'b1;    // Nếu 2 bytes, chèn số 1 ở bit thứ 16
            5'd3: pad_bit[24] = 1'b1;
            5'd4: pad_bit[32] = 1'b1;
            5'd5: pad_bit[40] = 1'b1;
            5'd6: pad_bit[48] = 1'b1;
            5'd7: pad_bit[56] = 1'b1;
            5'd9: pad_bit[72] = 1'b1;
            5'd10: pad_bit[80] = 1'b1;
            5'd11: pad_bit[88] = 1'b1;
            5'd12: pad_bit[96] = 1'b1;
            5'd13: pad_bit[104] = 1'b1;
            5'd14: pad_bit[112] = 1'b1;
            5'd15: pad_bit[120] = 1'b1;
            default: pad_bit[128] = 1'b1; // Mặc định (hoặc 16 bytes), chèn số 1 ở bit 128
        endcase
    end

    // =========================================================================
    // MẠCH XỬ LÝ TRÀN MODULO (Modulo 2^130 - 5)
    // =========================================================================
    // Thuật toán: Phần tràn (từ bit 130 trở đi) sẽ bị cắt ra, nhân với 5, rồi cộng ngược lại.
    // Phép nhân 5 được tối ưu bằng phép dịch trái 2 bit (nhân 4) rồi cộng với chính nó (X + X*4 = X*5).
    // {X, 2'b00} tương đương với việc dịch trái X đi 2 bit.

    // 1. Rút gọn cho thanh ghi Acc (dùng ở State 2 và 4)
    wire [7:0] acc_top = Acc[137:130];                      // Cắt 8 bit cao nhất bị tràn
    wire [10:0] acc_top_5 = acc_top + {acc_top, 2'b00};     // Nhân 8 bit đó với 5
    
    // 2. Rút gọn cho thanh ghi h (dùng ở State 5)
    wire [1:0] h_top = h[131:130];                          // Cắt 2 bit bị tràn
    wire [4:0] h_top_5 = h_top + {h_top, 2'b00};            // Nhân 2 bit đó với 5
    
    // 3. Rút gọn cho thanh ghi h khi đang bị dịch trái 1 bit (dùng ở Pha Lẻ của State 3)
    wire [132:0] h_shl = {h[131:0], 1'b0};                  // Tạo một bản sao của h, dịch trái 1 bit
    wire [2:0] h_shl_top = h_shl[132:130];                  // Cắt 3 bit bị tràn của bản dịch
    wire [5:0] h_shl_top_5 = h_shl_top + {h_shl_top, 2'b00};// Nhân 3 bit đó với 5

    // =========================================================================
    // TRẠM KIỂM SOÁT VÒNG LẶP NHÂN (Dò bit của khóa r)
    // =========================================================================
    // Trong vòng lặp State 3, ta cần kiểm tra từng bit của r (từ bit 0 đến bit 127).
    // mul_cnt[7:1] sẽ tạo ra địa chỉ từ 0 đến 127 để chọn đúng 1 bit trong r_reg.
    wire current_r_bit = r_reg[mul_cnt[7:1]]; 

    // =========================================================================
    // TRÁI TIM CỦA MẠCH: BỘ CỘNG DUY NHẤT (Shared ALU)
    // =========================================================================
    reg [137:0] alu_A, alu_B;              // 2 đầu vào của bộ cộng
    wire [137:0] alu_sum = alu_A + alu_B;  // Phép cộng duy nhất (Tối ưu diện tích tuyệt đối)

    // Khối MUX quyết định đưa tín hiệu nào vào bộ cộng dựa trên State hiện tại
    always @(*) begin
        alu_A = 138'd0; alu_B = 138'd0; // Khởi tạo mặc định để chống nhiễu Latch
        case (state)
            4'd1: begin // State 1: Cộng dồn h + Message + Padding bit
                alu_A = {6'd0, h};
                alu_B = Acc | pad_bit; 
            end
            4'd2, 4'd4: begin // State 2 & 4: Rút gọn Modulo cho thanh ghi Acc
                alu_A = {8'd0, Acc[129:0]}; // Lấy 130 bit dưới (chưa tràn)
                alu_B = {127'd0, acc_top_5}; // Cộng với phần tràn đã được nhân 5
            end
            4'd3: begin // State 3: Vòng lặp nhân Shift-and-Add (256 chu kỳ)
                if (!mul_cnt[0]) begin
                    // Pha Chẵn: Tích lũy (Nếu bit r hiện tại = 1, cộng h vào Acc, nếu = 0 thì không cộng)
                    alu_A = Acc;
                    alu_B = current_r_bit ? {6'd0, h} : 138'd0;
                end else begin
                    // Pha Lẻ: Dịch h (nhân 2) và Rút gọn Modulo cho bản dịch đó
                    alu_A = {8'd0, h_shl[129:0]};
                    alu_B = {132'd0, h_shl_top_5};
                end
            end
            4'd5: begin // State 5: Rút gọn Modulo lần cuối cho thanh ghi h
                alu_A = {8'd0, h[129:0]};
                alu_B = {133'd0, h_top_5};
            end
            4'd6: begin // State 6: Tính thử h + 5 để xem h có lớn hơn hoặc bằng (2^130 - 5) không
                alu_A = {6'd0, h};
                alu_B = 138'd5;
            end
            4'd7: begin // State 7: Tạo Tag cuối cùng = h + s
                // Nếu phép h+5 ở State 6 tràn (tức Acc[130] = 1), ta lấy giá trị đã trừ P (nằm trong Acc). 
                // Nếu không, ta lấy h ban đầu.
                alu_A = {8'd0, (Acc[130] ? Acc[129:0] : h[129:0])};
                alu_B = {10'd0, s_reg}; // Cộng với khóa s
            end
        endcase
    end

    // =========================================================================
    // MÁY TRẠNG THÁI (FSM) - ĐIỀU KHIỂN LUỒNG HOẠT ĐỘNG
    // =========================================================================
    always @(posedge clk) begin
        if (start) begin
            // Xung start sẽ Reset FSM và các bộ nhớ tạm (nhưng giữ nguyên khóa r và s)
            state <= 4'd0;
            in_cnt <= 2'd0;
            h <= 132'd0;
            finish <= 1'b0;
            O <= 32'd0;
            Acc <= 138'd0;
        end else begin
            case (state)
                4'd0: begin // TRẠNG THÁI 0: CHỜ VÀ NẠP DỮ LIỆU
                    finish <= 1'b0;
                    if (in_r) begin
                        // Nạp Khóa r: Mỗi nhịp nạp 32 bit.
                        // Đồng thời thực hiện "Clamp" (xóa các bit quy định về 0 theo chuẩn RFC)
                        case (in_cnt) 
                            2'd0: r_reg[31:0]   <= I & 32'h0fffffff; // Xóa 4 bit cao nhất của Word 0
                            2'd1: r_reg[63:32]  <= I & 32'h0ffffffc; // Xóa 4 bit cao nhất và 2 bit thấp nhất
                            2'd2: r_reg[95:64]  <= I & 32'h0ffffffc;
                            2'd3: r_reg[127:96] <= I & 32'h0ffffffc;
                        endcase
                        in_cnt <= in_cnt + 1'b1;
                    end else if (in_s) begin
                        // Nạp Khóa s: Nạp thô, không cần Clamp
                        case (in_cnt)
                            2'd0: s_reg[31:0]   <= I;
                            2'd1: s_reg[63:32]  <= I;
                            2'd2: s_reg[95:64]  <= I;
                            2'd3: s_reg[127:96] <= I;
                        endcase
                        in_cnt <= in_cnt + 1'b1;
                    end else if (data_in) begin
                        // Nạp Thông điệp: Nạp vào thanh ghi đa nhiệm Acc
                        case (in_cnt) 
                            2'd0: Acc <= {106'd0, I}; // Ép các bit thừa (từ 32 đến 137) về 0 để dọn rác
                            2'd1: Acc[63:32]  <= I;
                            2'd2: Acc[95:64]  <= I;
                            2'd3: begin Acc[127:96] <= I; state <= 4'd1; end // Đủ 4 nhịp -> Kích hoạt FSM chạy
                        endcase
                        in_cnt <= in_cnt + 1'b1;
                    end
                end
                
                // Mạch tính toán tuần tự dựa vào ALU
                4'd1: begin 
                    Acc <= alu_sum; // Lưu h + message + padding vào Acc
                    state <= 4'd2;
                end
                
                4'd2: begin 
                    h <= alu_sum[131:0]; // Lưu kết quả rút gọn Modulo của Acc vào h
                    Acc <= 138'd0;       // Xóa sạch Acc để chuẩn bị làm bộ Tích lũy cho phép nhân
                    mul_cnt <= 8'd0;     // Khởi động bộ đếm vòng lặp nhân
                    state <= 4'd3;
                end
                
                4'd3: begin // VÒNG LẶP NHÂN BIT-SERIAL (256 chu kỳ)
                    if (!mul_cnt[0]) begin // Pha Chẵn
                        Acc <= alu_sum; // Cộng tích lũy vào Acc
                    end else begin         // Pha Lẻ
                        h <= alu_sum[131:0]; // Cập nhật h thành giá trị đã dịch và rút gọn
                    end
                    
                    if (mul_cnt == 8'd255) state <= 4'd4; // Chạy đủ 256 nhịp thì thoát vòng lặp
                    else mul_cnt <= mul_cnt + 1'b1;
                end
                
                4'd4: begin 
                    h <= alu_sum[131:0]; // Rút gọn Modulo lần 1 sau phép nhân
                    state <= 4'd5;
                end
                
                4'd5: begin 
                    h <= alu_sum[131:0]; // Rút gọn Modulo lần 2 cho chắc chắn (vì h có thể vẫn hơi lớn)
                    state <= 4'd6;
                end
                
                4'd6: begin 
                    Acc <= alu_sum; // Tính mồi (h + 5) lưu tạm vào Acc để State 7 quyết định
                    state <= 4'd7;
                end
                
                4'd7: begin 
                    Acc <= alu_sum; // Tính MAC Tag cuối cùng (h + s)
                    state <= 4'd8;
                    out_cnt <= 2'd0; // Reset bộ đếm xuất dữ liệu
                end
                
                4'd8: begin // TRẠNG THÁI 8: ĐẨY MAC TAG RA NGOÀI (4 CHU KỲ)
                    finish <= 1'b1; // Bật cờ báo hiệu
                    case (out_cnt) 
                        2'd0: O <= Acc[31:0];   // Nhịp 1: Đẩy 32 bit thấp
                        2'd1: O <= Acc[63:32];  // Nhịp 2: Đẩy 32 bit tiếp theo
                        2'd2: O <= Acc[95:64];  // Nhịp 3
                        2'd3: O <= Acc[127:96]; // Nhịp 4: Đẩy 32 bit cao nhất
                    endcase
                    if (out_cnt == 2'd3) begin
                        state <= 4'd0; // Đẩy xong 4 Words, quay về trạng thái ngủ chờ gói tin mới
                        in_cnt <= 2'd0;
                    end else begin
                        out_cnt <= out_cnt + 1'b1;
                    end
                end
            endcase
        end
    end
endmodule