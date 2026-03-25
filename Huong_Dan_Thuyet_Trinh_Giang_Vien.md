# Hướng dẫn Thuyết trình & Phản biện cho Sinh viên (ChaCha20 IoT)

Tài liệu này giúp bạn định hình phong cách trình bày chuyên nghiệp cho chủ đề **Thiết kế lõi mã hóa hạng nhẹ (Lightweight Cryptography Cores)**.

---

## 1. Tại sao nội dung này thuyết phục được Giảng viên?
Giảng viên vi mạch sẽ đánh giá cao bạn nếu bạn làm nổi bật được các yếu tố:
*   **Lựa chọn giải pháp thông minh:** Giải thích tại sao ChaCha20 lại "nhẹ" hơn các giải pháp truyền thống (như AES) khi triển khai trên phần cứng thực tế.
*   **Kỹ thuật thiết kế tối ưu:** Chứng minh bạn biết cách tiết kiệm từng cổng logic (Gates) thông qua kiến trúc lặp (Iterative) và tái sử dụng tài nguyên.
*   **Khả năng hiện thực hóa:** Thể hiện quy trình từ thuật toán đến Verilog và cách bạn kiểm chứng (Verification) kết quả.

---

## 2. Các thuật ngữ "Ăn điểm" nên sử dụng
*   **PPA (Power, Performance, Area):** Luôn nhắc đến việc cân bằng 3 yếu tố này.
*   **Area-efficient Design:** Thiết kế tối ưu diện tích.
*   **Throughput-to-Area Ratio:** Chỉ số đánh giá hiệu quả của lõi mật mã trên một đơn vị diện tích.
*   **Combinational Path:** Đường dẫn tổ hợp, cần được tối ưu để giảm độ trễ.
*   **Resource Sharing:** Chia sẻ tài nguyên phần cứng giữa các bước tính toán.
*   **Hard-wired Rotation:** Kỹ thuật nối dây để thực hiện phép xoay bit mà không tốn tài nguyên.

---

## 3. Dự đoán câu hỏi phản biện & Cách trả lời (Q&A)

### Câu 1: "Tại sao em chọn ChaCha20 mà không phải là các thuật toán mã hóa khối (Block Cipher) hạng nhẹ khác như PRESENT hay CLEFIA?"
*   **Trả lời:** "Thưa thầy/cô, ChaCha20 là một mã hóa luồng (Stream Cipher) hiện đại có cấu trúc ARX cực kỳ tinh gọn. So với các mã hóa khối khác, ChaCha20 không cần bảng S-Box và có khả năng chống lại các cuộc tấn công kênh kề (Side-channel attacks) tốt hơn khi hiện thực hóa trên phần cứng. Ngoài ra, tốc độ của nó trên các nền tảng IoT vượt trội hơn đáng kể, phù hợp cho dữ liệu có kích thước thay đổi linh hoạt."

### Câu 2: "Kiến trúc của em có khả năng chống lại các cuộc tấn công vật lý (Side-channel attacks) không?"
*   **Trả lời:** "Trong giai đoạn ý tưởng này, nhóm tập trung vào tối ưu hóa diện tích (Area). Tuy nhiên, vì cấu trúc ChaCha20 không dùng bảng tra (S-Box) - vốn là mục tiêu chính của các cuộc tấn công năng lượng (Power Analysis) - nên về bản chất nó đã có độ an toàn tự nhiên cao hơn. Ở các giai đoạn tiếp theo, nhóm có thể nghiên cứu thêm các kỹ thuật Masking để tăng cường bảo mật nếu tài nguyên cho phép."

### Câu 3: "Thông lượng (Throughput) của lõi này là bao nhiêu và có đáp ứng được nhu cầu IoT không?"
*   **Trả lời:** "Với kiến trúc Iterative, thông lượng sẽ phụ thuộc vào tần số hoạt động của chip. Tuy nhiên, theo tính toán sơ bộ, với tần số khoảng 50-100MHz trên FPGA, lõi có thể đạt thông lượng hàng trăm Mbps, hoàn toàn dư sức đáp ứng các chuẩn truyền thông IoT như LoRa hay Zigbee thường chỉ yêu cầu tốc độ Kbps đến Mbps."

---

## 4. Lời khuyên về phong thái
*   **Tâm thế Kỹ sư:** Hãy nói về "Implementation" (Hiện thực hóa) nhiều hơn là "Theory" (Lý thuyết).
*   **Show your work:** Nếu có sơ đồ khối do chính bạn vẽ, hãy đưa vào slide. Giảng viên đánh giá rất cao sự tự chủ trong thiết kế.
*   **Thẳng thắn về giới hạn:** Nếu một kỹ thuật nào đó quá khó (như Pipeline phức tạp), hãy thẳng thắn nói rằng đó là sự lựa chọn đánh đổi để giữ thiết kế "Lightweight".
