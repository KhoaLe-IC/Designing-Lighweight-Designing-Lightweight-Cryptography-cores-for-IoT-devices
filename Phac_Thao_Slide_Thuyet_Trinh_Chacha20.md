# Kế hoạch Thuyết trình: Lightweight ChaCha20 Core for IoT Devices
**Thời lượng dự kiến:** 5 - 7 phút | **Số lượng:** 5 Slide nội dung chính

---

## Slide 1: Bối cảnh & Thách thức (The "Why")
*   **Tiêu đề:** Bảo mật dữ liệu tại biên cho kỷ nguyên IoT.
*   **Nội dung chính:**
    *   **Sự bùng nổ của IoT:** Hàng tỷ thiết bị kết nối từ y tế thông minh, nhà thông minh đến hạ tầng công nghiệp.
    *   **Lỗ hổng:** Dữ liệu nhạy cảm thường được truyền mà không có mã hóa hoặc mã hóa yếu do hạn chế tài nguyên.
    *   **Thách thức "Tam giác vàng" trong thiết kế:** 
        1. **Diện tích (Area):** Các thiết bị IoT siêu nhỏ (Edge nodes) có tài nguyên phần cứng cực kỳ hạn chế.
        2. **Năng lượng (Power):** Đa số chạy pin, yêu cầu mức tiêu thụ điện năng cực thấp.
        3. **Hiệu năng (Latency):** Đảm bảo tốc độ mã hóa thời gian thực mà không làm nghẽn hệ thống.
*   **Hình ảnh gợi ý:** Hệ sinh thái IoT đa dạng và biểu đồ về các cuộc tấn công dữ liệu vào thiết bị đầu cuối.

---

## Slide 2: Tại sao chọn ChaCha20? (The "Solution")
*   **Tiêu đề:** ChaCha20 - Chuẩn mã hóa hạng nhẹ tối ưu.
*   **Nội dung chính:**
    *   **Cấu trúc ARX (Addition - Rotation - XOR):** Loại bỏ hoàn toàn các bảng tra phức tạp (S-Box) -> Tiết kiệm diện tích Silicon tối đa.
    *   **Hiệu suất vượt trội:** Tốc độ xử lý nhanh hơn AES trên các nền tảng phần cứng không có bộ tăng tốc chuyên dụng.
    *   **Độ bảo mật tin cậy:** Sử dụng khóa 256-bit, khả năng chống lại các cuộc tấn công thám mã vi sai và thám mã tuyến tính.
    *   **Thân thiện với phần cứng:** Chỉ sử dụng các phép toán cơ bản, dễ dàng tối ưu hóa đường dẫn dữ liệu (Datapath).
*   **Hình ảnh gợi ý:** Minh họa cấu trúc ARX đơn giản so với cấu trúc nhiều tầng của AES.

---

## Slide 3: Kiến trúc Phần cứng Đề xuất (The "How")
*   **Tiêu đề:** Kiến trúc Iterative - Tối thiểu hóa tài nguyên.
*   **Nội dung chính:**
    *   **Cấu trúc ma trận:** Quản lý trạng thái 512-bit thông qua hệ thống thanh ghi tối ưu.
    *   **Khối Quarter Round (QR) linh hoạt:** Thiết kế một lõi QR duy nhất có khả năng tái sử dụng.
    *   **Bộ điều khiển FSM:** Máy trạng thái quản lý quy trình lặp lại (20 vòng mã hóa) một cách chặt chẽ.
    *   **Giao tiếp chuẩn:** Thiết kế sẵn sàng để tích hợp vào các hệ thống SoC thông qua các bus dữ liệu phổ biến.
*   **Hình ảnh gợi ý:** Sơ đồ khối (Block Diagram) thể hiện sự kết nối giữa FSM, Registers và khối QR.

---

## Slide 4: Giải pháp Tối ưu hóa PPA (The "Magic")
*   **Tiêu đề:** Kỹ thuật thiết kế hướng Low-Power & Low-Area.
*   **Nội dung chính:**
    *   **Resource Sharing:** Tái sử dụng các bộ cộng và logic XOR để giảm số lượng cổng logic (Gate count).
    *   **Hard-wired Rotation:** Thực hiện phép xoay bit bằng cách nối dây trực tiếp (Wiring) thay vì dùng bộ dịch bit, giúp diện tích bộ dịch xấp xỉ bằng 0.
    *   **Clock Gating:** Ngắt tín hiệu clock cho các khối không hoạt động để giảm công suất tiêu thụ động.
    *   **Tối ưu Critical Path:** Rút ngắn đường dẫn dữ liệu dài nhất để đạt tần số hoạt động tối ưu với năng lượng thấp nhất.
*   **Hình ảnh gợi ý:** Minh họa kỹ thuật nối dây cho phép xoay bit và sơ đồ Clock Gating.

---

## Slide 5: Mục tiêu & Kết quả dự kiến (The "Impact")
*   **Tiêu đề:** Hiện thực hóa lõi IP bảo mật cho ứng dụng thực tiễn.
*   **Nội dung chính:**
    *   **Chỉ số đo lường (KPIs):**
        *   Gate Count: Mục tiêu đạt mức "Lightweight" (dưới 5000-7000 cổng logic).
        *   Hiệu năng: Đạt thông lượng (Throughput) đủ cho các chuẩn truyền thông không dây (LoRa, Zigbee, BLE).
    *   **Tính ứng dụng:** Sẵn sàng làm lõi IP bảo mật cho các chip SoC IoT tùy biến.
    *   **Đóng góp chuyên môn:** Xây dựng quy trình thiết kế, mô phỏng và xác minh (Verification) lõi mật mã hoàn chỉnh.
*   **Hình ảnh gợi ý:** Logo các chuẩn kết nối IoT và bảng dự kiến thông số kỹ thuật (PPA table).
