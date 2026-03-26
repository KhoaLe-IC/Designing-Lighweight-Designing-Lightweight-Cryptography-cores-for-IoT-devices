# Phác thảo Slide & Kịch bản Thuyết trình 5 Phút: ChaCha20 IoT Core

Tài liệu này được tối ưu hóa cho bài thuyết trình ngắn (5-7 phút) với 5 slide trọng tâm, nhấn mạnh vào tính thực tiễn và khả năng ứng dụng trong Đô thị thông minh.

---

## PHẦN 1: CẤU TRÚC 5 SLIDE TRỌNG TÂM

### Slide 1: Vấn đề & Tầm nhìn (The "Why")
*   **Tiêu đề:** Bảo mật Đô thị Thông minh: Nhẹ - An toàn - Tương thích.
*   **Nội dung:**
    *   **Thực trạng:** 98% dữ liệu IoT hiện nay không được mã hóa (Palo Alto Networks).
    *   **Nghịch lý:** Thiết bị IoT (đèn đường, cảm biến) chạy pin, tài nguyên cực thấp nhưng đòi hỏi bảo mật cao.
    *   **Hạn chế:** AES quá nặng; các chuẩn LWC khác lại "cô lập", không tương thích trực tiếp với Internet.
*   **Thông điệp:** Giải pháp **Lõi mật mã ChaCha20** - Bảo mật hạng nhẹ chuẩn quốc tế cho Smart City.

### Slide 2: Giải pháp ChaCha20: Sự lựa chọn tối ưu (The Solution)
*   **Tiêu đề:** Tại sao lại là ChaCha20 Core?
*   **Nội dung:**
    *   **ARX Architecture:** Chỉ dùng Cộng (Add), Xoay (Rotate), XOR. Không S-Box, không bộ nhân -> Tiết kiệm tối đa cổng logic.
    *   **Bảo mật 256-bit:** Chuẩn an toàn quân đội, cao hơn mức 128-bit của nhiều đối thủ LWC.
    *   **Internet-Ready:** Tương thích mặc định với **TLS 1.3** (Google, Cloudflare). Kết nối thẳng lên Cloud không cần Gateway trung gian.
*   **Điểm nhấn:** Thuật toán duy nhất vừa cực nhẹ, vừa là "ngôn ngữ chung" của Internet.

### Slide 3: Đột phá Kỹ thuật & Tính khả thi (The "How")
*   **Tiêu đề:** Tối ưu hóa Phần cứng (Hardware IP Core).
*   **Nội dung:**
    *   **Kiến trúc Lặp (Iterative):** Tái sử dụng 01 khối Quarter Round duy nhất cho 20 vòng lặp. Diện tích chip cực nhỏ (~3.000 - 5.000 cổng logic).
    *   **Zero-cost Rotation:** Phép xoay bit thực hiện bằng cách nối dây (Wiring) trong Verilog -> **0 năng lượng, 0 diện tích**.
    *   **Xác thực nghiêm ngặt:** Kiểm chứng bằng bộ Test Vectors từ **RFC 7539** (Đảm bảo đúng đắn 100%).
*   **Thông điệp:** Tối ưu hóa tỷ lệ **Hiệu năng trên Diện tích (Throughput-per-Area)**.

### Slide 4: Ứng dụng & Kế hoạch Triển khai (Application & Plan)
*   **Tiêu đề:** Hiện thực hóa trong Đô thị Thông minh.
*   **Nội dung:**
    *   **Ứng dụng:** 
        *   **Smart Lighting:** Bảo mật lệnh điều khiển đèn đường, chống tấn công hạ tầng.
        *   **Traffic Sensors:** Mã hóa luồng dữ liệu giao thông thời gian thực.
    *   **Lộ trình 8 tuần:**
        *   **T1-2:** Mô hình hóa Python & Sơ đồ khối.
        *   **T3-5:** Thiết kế RTL (Verilog) & FSM điều khiển.
        *   **T6-8:** Mô phỏng & Tổng hợp (FPGA/ASIC) đánh giá PPA.
*   **Thông điệp:** Lộ trình rõ ràng, công cụ chuyên nghiệp (Quartus/Vivado), tính khả thi cao.

### Slide 5: Giá trị & Kết luận (The Impact)
*   **Tiêu đề:** Bảo mật không là gánh nặng cho thiết bị.
*   **Nội dung:**
    1.  **Siêu nhẹ:** Tối ưu cho thiết bị chạy pin tài nguyên thấp.
    2.  **Siêu an toàn:** Khóa 256-bit, chuẩn mật mã hiện đại nhất.
    3.  **Siêu tương thích:** Kết nối trực tiếp hạ tầng Internet Cloud qua TLS 1.3.
*   **Kết thúc:** "Kiến tạo nền tảng an toàn cho Đô thị Thông minh bền vững."

---

## PHẦN 2: KỊCH BẢN THUYẾT TRÌNH 5 PHÚT

1.  **Phút 1 (Vấn đề):** "Thưa Ban giám khảo, trong Đô thị thông minh, dữ liệu là mạch máu nhưng hiện có tới **98% lưu lượng IoT đang 'hở' hoàn toàn**. Các thiết bị chạy pin không đủ sức gánh các bộ mã hóa nặng như AES. Chúng em mang đến **Lõi mật mã ChaCha20** - giải pháp xóa bỏ nghịch lý giữa bảo mật và tài nguyên."

2.  **Phút 2 (Giải pháp):** "Tại sao là ChaCha20? Vì nó cực kỳ thông minh: Thay vì dùng các bảng tra cứu tốn diện tích, nó chỉ dùng các phép toán cơ bản. Quan trọng nhất, đây là **ngôn ngữ chung của Internet**. Thiết bị dùng lõi của chúng em có thể kết nối thẳng tới Server Google/Amazon qua chuẩn TLS 1.3 mà không cần trạm trung gian phức tạp."

3.  **Phút 3 (Kỹ thuật):** "Về mặt phần cứng, chúng em đột phá bằng **Kiến trúc Lặp**. Chúng em không làm 20 vòng mã hóa cồng kềnh mà chỉ thiết kế một khối xử lý duy nhất và tái sử dụng nó. Đặc biệt, phép xoay bit được thực hiện bằng cách nối dây, nghĩa là **tiêu tốn 0 diện tích và 0 năng lượng**. Chúng em kiểm chứng thiết kế bằng bộ Test Vectors quốc tế RFC 7539."

4.  **Phút 4 (Ứng dụng & Kế hoạch):** "Lõi IP này có thể tích hợp ngay vào hệ thống Đèn đường thông minh hay Cảm biến giao thông. Chúng em đã xây dựng lộ trình **8 tuần** chuyên nghiệp: từ mô hình hóa thuật toán đến tổng hợp trên FPGA để đo đạc thông số thực tế Power-Area-Performance."

5.  **Phút 5 (Kết luận):** "Tóm lại, giải pháp của chúng em hội tụ 3 yếu tố: **Nhẹ - An toàn - Tương thích**. Chúng em tin rằng bảo mật không nên là gánh nặng, mà phải là nền tảng của sự bền vững. Cảm ơn Ban giám khảo đã lắng nghe!"
