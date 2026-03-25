# Kế hoạch Thuyết trình: Lightweight ChaCha20 Core for IoT Devices
**Thời lượng dự kiến:** 5 - 7 phút | **Số lượng:** 5 Slide nội dung chính

---

## Slide 1: Bối cảnh & Thách thức (The "Why")
*   **Tiêu đề:** Bảo mật dữ liệu tại biên cho Smart City.
*   **Nội dung chính:**
    *   Sự bùng nổ của IoT: Hàng tỷ thiết bị cảm biến (đèn đường, môi trường) kết nối liên tục.
    *   **Lỗ hổng:** Dữ liệu cảm biến nhạy cảm thường truyền "trần" hoặc mã hóa yếu do hạn chế tài nguyên.
    *   **Thách thức "Tam giác vàng":** 
        1. **Diện tích (Area):** Chip IoT siêu nhỏ, không đủ chỗ cho các bộ mã hóa phức tạp.
        2. **Năng lượng (Power):** Chạy pin/năng lượng thấp, cần tối ưu hóa từng cổng logic.
        3. **Hiệu năng (Latency):** Đảm bảo mã hóa thời gian thực mà không làm trễ hệ thống.
*   **Hình ảnh gợi ý:** Biểu đồ tăng trưởng IoT và hình ảnh minh họa một node cảm biến bị tấn công.

---

## Slide 2: Tại sao chọn ChaCha20? (The "Solution")
*   **Tiêu đề:** ChaCha20 - Sự thay thế hoàn hảo cho AES trong IoT.
*   **Nội dung chính:**
    *   **Cấu trúc ARX (Addition - Rotation - XOR):** Không sử dụng bảng tra (S-Box) như AES -> Tiết kiệm cực lớn diện tích Silicon.
    *   **Độ bảo mật cao:** Key 256-bit, chống lại các cuộc tấn công thám mã hiện đại.
    *   **Thân thiện phần cứng:** Các phép toán cộng 32-bit và dịch bit cực kỳ dễ hiện thực hóa bằng Verilog với độ trễ thấp.
    *   **Ưu điểm mã hóa luồng:** Có thể mã hóa ngay lập tức khi dữ liệu cảm biến vừa đến (Stream-based).
*   **Hình ảnh gợi ý:** Bảng so sánh nhanh ChaCha20 vs AES (về độ phức tạp tính toán và tài nguyên).

---

## Slide 3: Kiến trúc Phần cứng Đề xuất (The "How")
*   **Tiêu đề:** Kiến trúc Lặp lại (Iterative) tối ưu diện tích.
*   **Nội dung chính:**
    *   **Ma trận trạng thái (State Matrix):** Xử lý khối 512-bit (16 từ 32-bit).
    *   **Khối Quarter Round (QR):** Trái tim của hệ thống, thực hiện các phép toán ARX cốt lõi.
    *   **Chiến lược thiết kế:** Thay vì dùng 20 khối QR song song, chúng tôi dùng **1 khối QR lặp lại** thông qua bộ điều khiển FSM.
    *   **Pipeline đơn giản:** Tối ưu hóa đường dẫn dữ liệu (Datapath) để đạt tần số hoạt động mục tiêu.
*   **Hình ảnh gợi ý:** Sơ đồ khối (Block Diagram) gồm: State Register, QR Logic, và FSM Controller.

---

## Slide 4: Giải pháp Tối ưu hóa PPA (The "Magic")
*   **Tiêu đề:** Thiết kế hướng Low-Power & Low-Area.
*   **Nội dung chính:**
    *   **Tái sử dụng tài nguyên (Resource Sharing):** Tận dụng tối đa bộ cộng 32-bit cho cả 80 lần chạy QR.
    *   **Clock Gating:** Tắt các khối logic khi không trong quá trình mã hóa để giảm công suất tiêu thụ tĩnh.
    *   **Tối ưu hóa phép xoay (Rotation):** Sử dụng Hard-wired (nối dây trực tiếp) trong Verilog thay vì dùng Barrel Shifter để diện tích gần như bằng 0.
    *   **Ưu tiên linh hoạt:** Khả năng thay đổi số vòng lặp (Rounds) để cân bằng giữa bảo mật và tốc độ theo yêu cầu ứng dụng.
*   **Hình ảnh gợi ý:** Sơ đồ minh họa kỹ thuật "Folding" (Gập kiến trúc) để giảm diện tích.

---

## Slide 5: Mục tiêu & Kết quả dự kiến (The "Impact")
*   **Tiêu đề:** Hiện thực hóa lõi IP "Made by Students".
*   **Nội dung chính:**
    *   **Chỉ số đo lường (KPIs):**
        *   Gate Count (Số lượng cổng logic) cực thấp (mục tiêu < 5000 gates).
        *   Thông lượng (Throughput) đáp ứng các chuẩn giao tiếp IoT (SPI/I2C).
    *   **Khả năng mở rộng:** Tích hợp vào các SoC cảm biến đèn đường thông minh (như đề tài đã nêu).
    *   **Tính đóng góp:** Tạo ra một lõi IP bảo mật nhẹ, có thể ứng dụng ngay vào các dự án vi mạch thực tế tại Việt Nam.
*   **Hình ảnh gợi ý:** Bảng dự kiến các thông số kỹ thuật (Area, Power, Speed) và hình ảnh ứng dụng trong Smart City.

---

### Mẹo nhỏ cho thuyết trình 5-7 phút:
1. **Slide 1 (1 phút):** Đánh vào nỗi sợ (bảo mật yếu) và sự cần thiết (IoT tăng trưởng).
2. **Slide 2 (1 phút):** Giải thích ngắn gọn tại sao ARX lại "thông minh" hơn S-Box trong phần cứng.
3. **Slide 3 (1.5 phút):** Tập trung vào sơ đồ khối, giải thích cách dữ liệu "chạy" trong vòng lặp.
4. **Slide 4 (1.5 phút):** Đây là phần ghi điểm kỹ thuật, hãy nói sâu về cách bạn tiết kiệm từng cổng logic.
5. **Slide 5 (1 phút):** Chốt lại bằng các con số và ý nghĩa thực tiễn.
