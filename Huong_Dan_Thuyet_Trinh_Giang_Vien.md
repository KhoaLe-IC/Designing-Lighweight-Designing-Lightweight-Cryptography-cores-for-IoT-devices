# Hướng dẫn Thuyết trình & Phản biện: Nâng tầm chuyên môn (ChaCha20)

Tài liệu này bổ sung các nội dung "Hard-core" để bạn trả lời các giảng viên khó tính và chứng minh đề tài không hề "dễ".

---

## 1. Cách trả lời khi bị nói: "ChaCha20 quá dễ, chỉ có Cộng, XOR và Xoay bit?"
*   **Trả lời:** "Dạ thưa thầy, về mặt thuật toán ChaCha20 rất tường minh, nhưng về mặt **hiện thực hóa phần cứng tối ưu (Hardware Optimization)**, nó đặt ra những bài toán rất khó:
    1. Làm sao quản lý ma trận **512-bit** (16 thanh ghi 32-bit) mà không làm bùng nổ diện tích định tuyến (Routing congestion)?
    2. Việc sử dụng cấu trúc ARX tuy đơn giản nhưng các bộ cộng 32-bit lại là nguồn gây ra **Glitch Power** (công suất nhiễu) rất lớn. Nhóm em tập trung vào việc áp dụng các kỹ thuật như **Operand Isolation** để xử lý vấn đề này.
    3. Thách thức lớn nhất là tìm ra điểm **AT Product** tối ưu nhất thông qua việc khảo sát nhiều kiến trúc khác nhau (Design Space Exploration)."

---

## 2. Các khái niệm chuyên sâu cần "nằm lòng" để ghi điểm
*   **Critical Path Analysis:** Bạn phải biết đường dẫn dài nhất trong thiết kế của mình nằm ở đâu (thường là bộ cộng 32-bit và logic XOR nối tiếp). Hãy nói về việc bạn tối ưu nó như thế nào.
*   **Throughput-per-Area (TPA):** Đây là thước đo hiệu quả của một lõi mật mã. Hãy nói: *"Mục tiêu của nhóm em không chỉ là làm cho chạy đúng, mà là đạt được chỉ số TPA cao nhất trong các công bố khoa học gần đây."*
*   **Hardware Complexity:** Nhấn mạnh rằng bạn đang tự thiết kế **FSM điều khiển** thay vì dùng các thư viện có sẵn, điều này giúp kiểm soát chặt chẽ tài nguyên.

---

## 3. Dự đoán câu hỏi "Hóc búa" về PPA

### Câu hỏi: "Em tối ưu Diện tích (Area) bằng cách nào khác ngoài việc lặp lại vòng lặp?"
*   **Trả lời:** "Dạ, nhóm em còn tối ưu ở mức cổng logic. Ví dụ, thay vì dùng các bộ cộng chuẩn của thư viện, nhóm nghiên cứu sử dụng kiến trúc bộ cộng có diện tích thấp (như **Ripple Carry Adder**) nếu tần số hoạt động cho phép, vì trong IoT, diện tích và năng lượng quan trọng hơn tốc độ tuyệt đối."

### Câu hỏi: "Làm sao em biết thiết kế của em là Low-Power?"
*   **Trả lời:** "Nhóm em áp dụng **Clock Gating** để tắt Clock của các thanh ghi không thay đổi giá trị trong các chu kỳ trung gian. Đồng thời, chúng em thiết kế Datapath sao cho giảm thiểu số lượng bit chuyển trạng thái (Switching Activity) trong mỗi chu kỳ clock."

---

## 4. Bí quyết thuyết phục Giảng viên
1.  **Đừng nói "Em chọn ChaCha20 vì nó dễ":** Hãy nói *"Em chọn ChaCha20 vì cấu trúc ARX của nó cho phép đạt được mức hiệu quả năng lượng mà các thuật toán mã hóa khối (Block Ciphers) khác không thể làm được ở cùng mức bảo mật."*
2.  **Sử dụng số liệu so sánh:** Nếu có thể, hãy tìm một bảng so sánh diện tích (Gate count) của các bài báo khoa học về ChaCha20 để đưa vào slide cuối. Nó chứng minh bạn đã nghiên cứu rất sâu (Research-oriented).

