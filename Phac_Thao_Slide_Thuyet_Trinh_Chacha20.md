# Phác thảo Slide Thuyết trình ChaCha20 - Vòng Ý tưởng (5-7 Phút)
**Mục tiêu:** Tập trung vào giá trị thực tiễn cho Smart City, tính khả thi kỹ thuật và lộ trình triển khai tinh gọn.

---

## Slide 1: Bối cảnh & Vấn đề (The Crisis)
*   **Tiêu đề:** Bảo mật dữ liệu tại biên cho Đô thị thông minh.
*   **Nội dung:**
    *   Sự bùng nổ của thiết bị IoT (Cảm biến, đồng hồ thông minh, đèn đường...) trong Smart City.
    *   **Thách thức:** 80% thiết bị IoT không có mã hóa do giới hạn về pin và tài nguyên phần cứng.
    *   **Nghịch lý:** Các chuẩn mã hóa cũ như AES quá "nặng" (tốn diện tích chip, ngốn pin), khiến bảo mật trở thành gánh nặng.

---

## Slide 2: Giải pháp: ChaCha20 Hardware Core (The Choice)
*   **Tiêu đề:** ChaCha20 - Tối ưu hóa bảo mật từ mức phần cứng.
*   **Nội dung:**
    *   **Tại sao là ChaCha20?** Cấu trúc **ARX** (Add-Rotate-XOR) loại bỏ hoàn toàn bộ nhân phức tạp, giúp giảm diện tích chip (Area).
    *   **Hardware vs Software:** Thay vì chạy mã phần mềm tiêu tốn tài nguyên CPU, lõi IP của chúng tôi xử lý trực tiếp trên phần cứng.
    *   **Lợi ích:** Giảm thời gian xử lý dữ liệu (Latency) và cho phép thiết bị IoT quay lại chế độ tiết kiệm điện nhanh hơn, kéo dài tuổi thọ pin.
*   **Script gợi ý:** *"Sự khác biệt của chúng tôi nằm ở việc đưa thuật toán vào trực tiếp cấu trúc phần cứng. Thay vì bắt một vi điều khiển yếu ớt phải gánh vác các dòng code mã hóa nặng nề, lõi IP của chúng tôi giải quyết nó chỉ trong vài chu kỳ clock với mức năng lượng tối thiểu."*

---

## Slide 3: Khả năng ứng dụng thực tiễn (The Impact)
*   **Tiêu đề:** Hệ sinh thái Bảo mật Smart City.
*   **Nội dung (3 Case Study):**
    1.  **Lưới điện thông minh (Smart Grid):** Mã hóa dữ liệu tiêu thụ điện từ hộ gia đình về trung tâm để tránh gian lận hoặc tấn công hạ tầng.
    2.  **Cảm biến đô thị (Environment Nodes):** Bảo vệ tính xác thực của dữ liệu ô nhiễm, mực nước ngập từ các nút cảm biến dùng pin.
    3.  **Điều khiển hạ tầng (Edge Control):** Xác thực lệnh điều khiển cho hệ thống đèn giao thông và biển báo điện tử.

---

## Slide 4: Tính khả thi & Tối ưu hóa kỹ thuật (The Innovation)
*   **Tiêu đề:** Thiết kế thực tế - Hiệu quả cực đoan.
*   **Nội dung:**
    *   **Kiến trúc Lặp (Iterative):** Tái sử dụng linh kiện tối đa để đạt diện tích chip cực nhỏ (Mục tiêu < 5000 cổng logic - tương đương các nghiên cứu hàng đầu).
    *   **Cơ sở kỹ thuật:** Nhóm đã phân tích cấu trúc 1/4 vòng lặp (Quarter Round) và nhận thấy khả năng chia sẻ tài nguyên (Resource Sharing) rất cao giữa các bước tính toán.
    *   **Xác minh:** Sử dụng bộ Test Vector chuẩn từ RFC 7539 để đảm bảo tính đúng đắn ngay từ giai đoạn mô hình hóa.

---

## Slide 5: Kế hoạch triển khai & Cam kết (The Roadmap)
*   **Tiêu đề:** Lộ trình 8 tuần - Từ ý tưởng đến lõi IP sẵn sàng tích hợp.
*   **Nội dung:**
    *   **Giai đoạn 1 (Tuần 1-4):** Xây dựng mô hình toán (Python) và thiết kế RTL (Verilog HDL).
    *   **Giai đoạn 2 (Tuần 5-7):** Mô phỏng và xác minh độ chính xác 100% với Test Vectors chuẩn quốc tế.
    *   **Giai đoạn 3 (Tuần 8):** Tổng hợp phần cứng (Synthesis) và đánh giá các chỉ số diện tích, công suất thực tế.
*   **Thông điệp cuối:** "Chúng tôi không chỉ đưa ra ý tưởng, chúng tôi có lộ trình kỹ thuật để hiện thực hóa nó."
