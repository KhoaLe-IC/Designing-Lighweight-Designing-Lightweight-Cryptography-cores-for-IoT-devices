# Hướng dẫn Thuyết trình & Phản biện cho Sinh viên (ChaCha20 IoT)

Tài liệu này giúp bạn định hình phong cách trình bày chuyên nghiệp, sử dụng đúng thuật ngữ kỹ thuật và chuẩn bị cho các câu hỏi "hóc búa" từ giảng viên trong buổi thuyết trình ý tưởng.

---

## 1. Tại sao nội dung này thuyết phục được Giảng viên?
Giảng viên vi mạch/hệ thống nhúng thường đánh giá cao sinh viên ở 3 điểm sau trong bài thuyết trình này:
*   **Tư duy Trade-off (Sự đánh đổi):** Bạn không chọn thuật toán mạnh nhất hay nhanh nhất, mà chọn thuật toán **phù hợp nhất** cho tài nguyên hạn hẹp của IoT (Lightweight).
*   **Hiểu bản chất Hardware:** Nhấn mạnh vào việc ChaCha20 không dùng S-Box (bảng tra) giúp tiết kiệm diện tích Silicon (Area) - đây là "điểm chạm" kỹ thuật cực kỳ quan trọng.
*   **Cấu trúc RTL rõ ràng:** Phân tách rõ ràng giữa **Datapath** (khối tính toán QR) và **Control Logic** (FSM) là nền tảng của thiết kế vi mạch chuyên nghiệp.

---

## 2. Các thuật ngữ "Ăn điểm" nên sử dụng
Hãy lồng ghép các từ khóa này vào lời nói khi thuyết trình:
*   **PPA (Power, Performance, Area):** Bộ 3 chỉ số vàng trong thiết kế vi mạch.
*   **Iterative Architecture (Kiến trúc lặp):** Giải thích lý do dùng 1 khối QR chạy nhiều lần để tiết kiệm diện tích thay vì dùng kiến trúc song song.
*   **Critical Path (Đường dẫn tới hạn):** Đề cập đến việc tối ưu khối cộng 32-bit để đảm bảo tần số hoạt động (Frequency).
*   **Resource Sharing (Chia sẻ tài nguyên):** Cách tái sử dụng các bộ cộng/XOR trong các vòng lặp khác nhau.
*   **Hard-wired Rotation:** Giải thích rằng phép xoay bit trong Verilog thực chất chỉ là việc nối dây (Wiring), giúp diện tích bộ dịch gần như bằng 0.

---

## 3. Dự đoán câu hỏi phản biện & Cách trả lời (Q&A)

### Câu 1: "Tại sao em chọn kiến trúc Iterative (Lặp) mà không dùng Pipeline (Đường ống) để tăng tốc độ?"
*   **Trả lời:** "Thưa thầy/cô, mục tiêu trọng tâm của đề tài này là **Lightweight (Hạng nhẹ)** cho thiết bị IoT biên. Kiến trúc Pipeline sẽ giúp tăng thông lượng (Throughput) nhưng lại làm tăng đáng kể diện tích chip (Area) và công suất tiêu thụ (Power). Với dữ liệu cảm biến đèn đường có tốc độ không quá cao, kiến trúc Iterative là sự lựa chọn tối ưu nhất để cân bằng giữa bảo mật và chi phí phần cứng."

### Câu 2: "Làm sao em đảm bảo tính đúng đắn (Correctness) của lõi IP sau khi thiết kế?"
*   **Trả lời:** "Nhóm sẽ thực hiện quy trình **Verification** (Xác minh) nghiêm ngặt:
    1. Sử dụng bộ dữ liệu mẫu (Test Vectors) tiêu chuẩn từ **RFC 7539**.
    2. Viết **Testbench** tự động so sánh kết quả đầu ra từ mô phỏng Verilog với kết quả tính toán từ một mô hình tham chiếu (Reference Model) bằng Python hoặc C."

### Câu 3: "Em tối ưu hóa năng lượng (Power) như thế nào trong thiết kế này?"
*   **Trả lời:** "Ngoài việc tối ưu diện tích để giảm dòng rò (Leakage), nhóm dự kiến áp dụng kỹ thuật **Clock Gating** cho bộ điều khiển FSM và các thanh ghi trạng thái. Khi lõi không trong quá trình mã hóa (Idle), tín hiệu Clock sẽ bị ngắt để triệt tiêu công suất động (Dynamic Power)."

---

## 4. Lời khuyên về phong thái
*   **Tập trung vào "Thiết kế":** Đừng dành quá nhiều thời gian nói về lý thuyết mã hóa (toán học), hãy dành thời gian nói về **"Cách tôi đưa toán học vào cổng logic (Gates)"**.
*   **Sử dụng sơ đồ khối (Block Diagram):** Giảng viên thích nhìn sơ đồ luồng dữ liệu hơn là nhìn slide toàn chữ.
*   **Quyết đoán về con số:** Nếu được hỏi về diện tích, hãy đưa ra một con số ước lượng (ví dụ: < 5000 cổng logic) dựa trên các bài báo khoa học mà bạn đã tham khảo trong thư mục `documents`.
