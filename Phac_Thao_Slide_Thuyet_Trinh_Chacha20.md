# Kế hoạch Thuyết trình: High-Efficiency ChaCha20 Core for Resource-Constrained IoT
**Thời lượng:** 5 - 7 phút | **Mục tiêu:** Thuyết phục hội đồng bằng chiều sâu tối ưu PPA.

---

## Slide 1: Bối cảnh & Thách thức (The "Why")
*   **Tiêu đề:** Bảo mật dữ liệu tại biên cho kỷ nguyên IoT.
*   **Nội dung:**
    *   **Lỗ hổng:** Thiết bị IoT biên (Edge nodes) là "mắt xích yếu nhất" trong chuỗi bảo mật Smart City.
    *   **Nghịch lý thiết kế:** Bảo mật càng cao -> Tài nguyên tốn kém -> Năng lượng cạn kiệt.
    *   **Thách thức Tam giác PPA:** Làm sao để đạt chuẩn mật mã quân đội (ChaCha20-256) trên một chip diện tích chỉ vài nghìn cổng logic?
*   **Thông điệp:** Chúng tôi không chỉ làm mật mã, chúng tôi tối ưu hóa phần cứng cho bảo mật.

---

## Slide 2: Giải pháp: Tại sao lại là ChaCha20 ARX?
*   **Tiêu đề:** ChaCha20 - Sự lựa chọn chiến lược cho Hardware-efficient.
*   **Nội dung:**
    *   **ARX Architecture:** Chỉ dùng Addition, Rotation, XOR. Không S-Box (tiết kiệm Area), không Multiplier (tiết kiệm Power).
    *   **Kháng tấn công kênh kề (Side-channel resistance):** Cấu trúc tính toán thời gian thực (Constant-time) tự nhiên, giúp chống lại các cuộc tấn công thám mã dựa trên thời gian.
    *   **Hiệu suất:** Vượt trội hơn AES 128/256 khi triển khai trên các dòng chip Low-end.

---

## Slide 3: Kiến trúc Đề xuất & Design Space Exploration
*   **Tiêu đề:** Tối ưu hóa kiến trúc lặp (Iterative Architecture).
*   **Nội dung:**
    *   **Quản lý 512-bit State:** Thử thách trong việc thiết kế hệ thống thanh ghi tập trung để giảm thiểu diện tích định tuyến (Routing Area).
    *   **Khối Quarter Round (QR) tùy biến:** Thiết kế lõi QR có khả năng cấu hình (Configurable) để cân bằng giữa tốc độ và diện tích.
    *   **Chiến lược tối ưu:** Sử dụng 1 khối QR duy nhất kết hợp với FSM đa tầng để xử lý 80 bước tính toán trong 20 chu kỳ/vòng.
*   **Hình ảnh:** Sơ đồ khối chi tiết thể hiện rõ sự tách biệt giữa Datapath và FSM.

---

## Slide 4: Kỹ thuật Tối ưu hóa PPA chuyên sâu (Key Innovation)
*   **Tiêu đề:** Giải pháp tối ưu hóa cực đoan.
*   **Nội dung:**
    *   **Arithmetic Sharing:** Tái sử dụng bộ cộng 32-bit thông qua kỹ thuật Time-multiplexing.
    *   **Zero-cost Rotation:** Phép xoay bit được hiện thực hóa bằng Hard-wiring (nối dây trực tiếp), triệt tiêu hoàn toàn diện tích logic.
    *   **Clock Gating & Operand Isolation:** Ngắt tín hiệu chuyển mạch khi dữ liệu không thay đổi để đạt mức Low-Power tối đa.
    *   **AT Product Optimization:** Phân tích biểu đồ đánh đổi giữa Diện tích và Thời gian để tìm điểm hoạt động tối ưu.

---

## Slide 5: Kế hoạch thực hiện & Xác minh (Verification)
*   **Tiêu đề:** Quy trình thiết kế và Cam kết chất lượng.
*   **Nội dung:**
    *   **Quy trình xác minh (Verification Flow):** Sử dụng Self-checking Testbench với dữ liệu tham chiếu từ RFC 7539 (Golden Model).
    *   **Chỉ số mục tiêu (KPIs):** 
        *   Diện tích: < 5000 Gates (tương đương các giải pháp Lightweight hàng đầu).
        *   Công suất: Mức nW/MHz (Nano-Watt trên mỗi MHz).
    *   **Định hướng:** Phát triển lõi IP sẵn sàng tích hợp (Silicon Ready).
