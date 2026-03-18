# Lộ trình Học tập và Triển khai: Thiết kế lõi mã hóa Chacha20 (Dành cho Sinh viên Năm 2)

Tài liệu này cung cấp các kiến thức nền tảng, tài liệu tham khảo và kế hoạch chi tiết để một sinh viên năm 2 ngành Kỹ thuật Máy tính/Điện tử có thể tự thiết kế thành công một lõi IP (Intellectual Property) mật mã hạng nhẹ.

## 1. Kiến thức cần trang bị

### 1.1. Kiến thức về Mật mã học (Cryptography Basics)
*   **Mã hóa luồng (Stream Cipher):** Hiểu cơ chế tạo ra `Keystream` (chuỗi khóa) độc lập với bản rõ để thực hiện phép toán `XOR` (Plaintext ⊕ Keystream = Ciphertext).
*   **Cấu trúc ARX (Add-Rotate-XOR):** Đây là thành phần cơ bản của Chacha20. Ưu điểm lớn nhất là không sử dụng phép nhân hay bảng tra (S-Box), cực kỳ tối ưu cho phần cứng (Low-Area).
*   **Hiểu các tham số đầu vào:** 
    *   `Key` (256-bit): Khóa bảo mật.
    *   `Nonce` (96-bit): Số dùng một lần để đảm bảo tính duy nhất.
    *   `Counter` (32-bit): Số đếm khối.
    *   `Constants`: Các hằng số mặc định để tránh các cuộc tấn công toán học.

### 1.2. Kiến thức Thiết kế Hệ thống Số (Digital Design)
*   **Máy trạng thái hữu hạn (FSM):** Bạn cần nắm vững cách thiết kế FSM để điều khiển vòng lặp (20 Rounds). Cần phân biệt trạng thái *Idle*, *Initialization*, *Processing (Column/Diagonal Round)*, và *Final Addition*.
*   **Tối ưu hóa Datapath (Iterative Design):** Thay vì thiết kế 20 vòng mã hóa cứng (unrolled - tốn rất nhiều diện tích), bạn nên thiết kế 1 vòng mã hóa duy nhất và dùng bộ đếm để tái sử dụng phần cứng đó 20 lần.
*   **Xử lý số học 32-bit:** Hiểu về bộ cộng (Adder), các phép toán logic (XOR) và đặc biệt là phép xoay bit (Rotate) trong Verilog (phép xoay bit thực tế chỉ là nối lại dây, không tốn tài nguyên logic).

### 1.3. Kỹ năng Verilog HDL & Verification
*   **Thiết kế Phân cấp (Hierarchy):** Chia dự án thành các module nhỏ: `quarter_round.v`, `chacha_core.v`, `top_module.v`.
*   **Viết Testbench nâng cao:** Biết cách nạp dữ liệu từ file văn bản (`$readmemh`) để so sánh kết quả mô phỏng với kết quả mẫu (Golden Model) từ RFC 7539.

## 2. Tài liệu tham khảo quan trọng

| Loại tài liệu | Tên & Link tham khảo | Mô tả |
| :--- | :--- | :--- |
| **Tiêu chuẩn gốc** | [RFC 7539 - Section 2](https://datatracker.ietf.org/doc/html/rfc7539#section-2) | Mô tả thuật toán chính xác nhất từng bước một (NÊN ĐỌC). |
| **Video trực quan** | [ChaCha20 and Poly1305 - Computerphile](https://www.youtube.com/watch?v=UeIPHlK_U0I) | Giúp hiểu ý tưởng tại sao Chacha20 lại an toàn và nhanh. |
| **Bài báo khoa học** | [Hardware Implementation of ChaCha20](https://ieeexplore.ieee.org/) | Tìm trên IEEE Xplore hoặc Google Scholar để xem các kiến trúc tối ưu diện tích. |
| **Mã nguồn mẫu** | [OpenCores - Chacha20](https://opencores.org/) | Tham khảo cách các chuyên gia viết code Verilog cho lõi IP chuyên nghiệp. |

## 3. Lộ trình thực hiện chi tiết (8 Tuần)

### Giai đoạn 1: Nghiên cứu & Mô phỏng (Tuần 1-2)
*   **Nhiệm vụ:** Viết một đoạn code Python/C thực hiện đúng thuật toán Chacha20 theo đúng từng bước của RFC 7539.
*   **Mục tiêu:** Hiểu rõ giá trị của các biến thay đổi như thế nào sau mỗi phép toán Quarter Round.

### Giai đoạn 2: Thiết kế RTL (Tuần 3-5)
*   **Tuần 3:** Viết module `quarter_round.v`. Đây là khối quan trọng nhất.
*   **Tuần 4:** Thiết kế thanh ghi trạng thái (State Registers) để lưu ma trận 4x4 (512-bit).
*   **Tuần 5:** Hoàn thiện bộ điều khiển FSM để điều phối 20 vòng lặp.

### Giai đoạn 3: Kiểm tra & Sửa lỗi (Tuần 6-7)
*   **Nhiệm vụ:** Viết Testbench sử dụng "Test Vectors" từ RFC 7539.
*   **Công cụ:** Sử dụng ModelSim hoặc QuestaSim để quan sát dạng sóng (Waveform).

### Giai đoạn 4: Tổng hợp & Đánh giá (Tuần 8)
*   **Nhiệm vụ:** Chạy tổng hợp trên Intel Quartus hoặc Xilinx Vivado.
*   **Mục tiêu:** Đánh giá số lượng logic gates (Area) và tần số tối đa (Performance).

## 4. Lời khuyên dành cho bạn
1.  **Đừng bắt đầu bằng Verilog ngay:** Hãy đảm bảo bạn có thể tính tay hoặc code bằng ngôn ngữ bậc cao (Python) ra kết quả đúng trước.
2.  **Vẽ sơ đồ khối (Block Diagram):** Trước khi code module nào, hãy vẽ sơ đồ kết nối các thanh ghi và bộ cộng ra giấy.
3.  **Tập trung vào Low-Area:** Vì đây là đề tài cho IoT, hãy cố gắng dùng ít bộ cộng nhất có thể (ví dụ: dùng 4 bộ cộng 32-bit thay vì 16 bộ).
