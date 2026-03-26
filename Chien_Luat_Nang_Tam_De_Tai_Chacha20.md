# Chiến thuật Nâng tầm Kỹ thuật: Lõi IP ChaCha20 cho IoT

Tài liệu này cung cấp các lập luận chuyên sâu và thuật ngữ kỹ thuật để khẳng định độ khó, tính chuyên nghiệp và sự vượt trội của đề tài trước Ban giám khảo (Hội đồng chuyên gia Vi mạch).

---

## 1. Khẳng định "Độ khó" của Kiến trúc Phần cứng

Đừng chỉ nói "Kiến trúc Lặp" (Iterative), hãy trình bày nó dưới góc độ **Tối ưu hóa Vi kiến trúc (Micro-architecture Optimization)**:

*   **FSM-driven Controller:** Việc tái sử dụng 1 khối Quarter Round (QR) đòi hỏi thiết kế một Máy trạng thái hữu hạn (FSM) cực kỳ tinh vi. Bạn phải điều khiển việc nạp/xuất dữ liệu từ ma trận 16 thanh ghi (512-bit) qua 20 vòng mã hóa (Column & Diagonal rounds) với độ chính xác tuyệt đối.
*   **Data Path Steering:** Thách thức nằm ở việc thiết kế mạng lưới **Multiplexer (MUX)** và **Bus dữ liệu nội bộ** sao cho đường truyền (Critical Path) là ngắn nhất, giúp đạt tần số hoạt động ($F_{max}$) cao trên các chip giá rẻ/FPGA đời cũ.
*   **Pipeline Stage Balancing:** Nếu có thể, hãy đề cập đến việc phân chia các giai đoạn cộng/xoay/XOR để cân bằng trễ, tránh hiện tượng thắt cổ chai về hiệu năng.

---

## 2. Vũ khí "Tương thích Hệ thống" (System Integration)

Để đề tài không bị coi là "module rời rạc", hãy nhấn mạnh khả năng tích hợp vào **SoC (System on Chip)**:

*   **AXI4-Lite/APB Interface:** Tuyên bố lõi IP của bạn tích hợp giao tiếp bus chuẩn công nghiệp. Điều này biến nó từ một mạch logic đơn thuần thành một **Bộ tăng tốc phần cứng (Hardware Accelerator)** mà các vi xử lý (như RISC-V, ARM) có thể điều khiển trực tiếp qua sơ đồ địa chỉ (Memory-mapped IO).
*   **Interrupt Mechanism:** Lõi có khả năng gửi tín hiệu ngắt (Interrupt) cho CPU khi hoàn thành khối dữ liệu 512-bit, giúp tối ưu hóa hiệu suất tổng thể của hệ thống IoT.

---

## 3. Chiến lược Kiểm thử (Verification Rigor)

Trong vi mạch, thiết kế chỉ chiếm 30%, **Kiểm thử (Verification)** chiếm 70% công sức. Hãy nhấn mạnh điểm này:

*   **Automated Verification Environment:** Xây dựng môi trường kiểm thử tự động (Self-checking Testbench) kết hợp giữa Verilog và **Golden Model (Python/C)**.
*   **RFC 7539 Test Vectors:** Sử dụng các bộ dữ liệu thử nghiệm chuẩn quốc tế để đảm bảo tính đúng đắn 100% của thuật toán. Sai 1 bit trong mật mã là thất bại, và bạn chứng minh được sự tin cậy tuyệt đối của lõi IP.

---

## 4. So sánh Chiến thuật với các đối thủ (ASCON/SHA-256)

Dựa trên danh sách các đội thi (vòng ý tưởng), bạn cần làm nổi bật sự khác biệt:

| Tiêu chí | Đối thủ (ASCON, SHA, NTT) | **Lõi ChaCha20 của bạn** |
| :--- | :--- | :--- |
| **Tính ứng dụng** | Thuật toán mới, chưa phổ cập hạ tầng. | **Tương thích TLS 1.3 (Internet-Ready).** |
| **Độ phức tạp** | Cố gắng làm thuật toán khó. | **Tối ưu hóa sâu vi kiến trúc PPA.** |
| **Thực tế triển khai** | Cần Gateway trung gian tốn kém. | **Kết nối trực tiếp từ Cảm biến lên Cloud.** |
| **Chiến lược** | Chạy theo xu hướng học thuật. | **Giải quyết bài toán thực tế của IoT 2025.** |

---

## 5. Từ khóa "Ghi điểm" (Keywords for Presentation)

Khi thuyết trình hoặc viết báo cáo, hãy sử dụng các cụm từ sau để tăng tính chuyên nghiệp:
1.  **"Throughput-per-Area Optimization":** Tối ưu hóa băng thông trên mỗi đơn vị diện tích chip.
2.  **"Hardware Hardening":** Bảo mật mức phần cứng (chống lại việc quên cập nhật firmware).
3.  **"Resource Sharing Architecture":** Kiến trúc chia sẻ tài nguyên (để giải thích cho việc dùng kiến trúc lặp).
4.  **"End-to-End Security with TLS 1.3 compatibility":** Bảo mật đầu-cuối tương thích chuẩn Internet hiện đại.

---

## Kết luận cho nhóm 40% Đậu:
Đề tài của bạn không "dễ", nó là một thiết kế **Thông minh (Smart Design)**. Bạn chọn một thuật toán có tính thực tiễn cao nhất để tập trung giải quyết bài toán khó nhất của TKVM: **Làm sao để mạch chạy nhanh nhất, tốn ít diện tích nhất và tương thích tốt nhất.** Đây chính là tư duy của một kỹ sư thiết kế vi mạch thực thụ.
