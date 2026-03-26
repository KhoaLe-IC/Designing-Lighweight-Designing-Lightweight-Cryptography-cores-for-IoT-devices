# Kiến trúc IP Core ChaCha20

Phần này trình bày kiến trúc của IP core ChaCha20 theo ba mức:

1. **Kiến trúc tổng thể của IP core**
2. **Kiến trúc bên trong của Round Engine**
3. **Kiến trúc Quarter-Round** *(tái sử dụng từ paper tham khảo)*

Ba figure có mối liên hệ phân cấp như sau:

- **Figure 1** mô tả kiến trúc tổng thể của toàn bộ IP core ChaCha20.
- **Figure 2** mô tả chi tiết kiến trúc bên trong khối **Round Engine** trong Figure 1.
- **Figure 3** mô tả khối **Quarter-Round**, là đơn vị tính toán cơ bản được sử dụng trong Figure 2.

---

## Figure 1. Kiến trúc tổng thể của IP core ChaCha20

<p align="center">
  <img src="./images/figure1.png" alt="Figure 1 - Kiến trúc tổng thể của IP core ChaCha20" width="850">
</p>

<p align="center"><i>Figure 1. Kiến trúc tổng thể của IP core ChaCha20.</i></p>

Figure 1 mô tả kiến trúc tổng quan của IP core ChaCha20 ở mức hệ thống.  
Mục tiêu của khối này là sinh ra **keystream** theo thuật toán ChaCha20, sau đó thực hiện phép **XOR** giữa keystream và plaintext để tạo ra **ciphertext** đầu ra.

Về luồng xử lý, kiến trúc trong hình có thể được chia thành ba giai đoạn chính:

- **Khởi tạo trạng thái ban đầu**
- **Biến đổi trạng thái qua các round**
- **Sinh keystream và tạo ciphertext**

### 1. Khối `Constant Generator`

Khối `Constant Generator` cung cấp bốn hằng số cố định đầu tiên của state ChaCha20.  
Các hằng số này tương ứng với chuỗi ASCII:

```text
"expand 32-byte k"
```

Bốn word 32 bit được sử dụng là:

```text
0x61707865
0x3320646e
0x79622d32
0x6b206574
```

Khối này không thực hiện tính toán phức tạp, mà chỉ đóng vai trò cung cấp các giá trị hằng để tạo trạng thái ban đầu.

### 2. Khối `State Initialization Unit`

Khối `State Initialization Unit` tạo ra:

```text
initial_state[0..15]
```

Trạng thái này gồm tổng cộng **16 word 32 bit**, được xây dựng từ:

- 4 word hằng số
- 8 word key
- 1 word counter
- 3 word nonce

Đây là trạng thái đầu vào chuẩn của thuật toán ChaCha20 trước khi đi vào các vòng biến đổi.

### 3. Khối `Initial State Register`

Sau khi `initial_state` được tạo ra, nó được lưu vào `Initial State Register`.

Việc lưu riêng trạng thái ban đầu là cần thiết vì sau khi hoàn thành 20 rounds, thuật toán ChaCha20 yêu cầu cộng từng word của trạng thái hiện tại với chính trạng thái ban đầu để tạo ra đầu ra cuối cùng.

### 4. Khối `Working State Register`

Khối `Working State Register` lưu:

```text
working_state[0..15]
```

Ban đầu, working state được nạp từ initial state.  
Trong suốt quá trình xử lý, round engine sẽ liên tục đọc, biến đổi và ghi lại working state vào khối này.

Nói cách khác:

- `Initial State Register` lưu bản gốc
- `Working State Register` lưu bản đang được xử lý

### 5. Khối `Round Engine`

Đây là khối tính toán trung tâm của toàn bộ IP core.

Khối này thực hiện:

- **10 double-round**
- tương đương **20 rounds** của ChaCha20
- bao gồm:
  - **Column Round**
  - **Diagonal Round**

Trong mỗi round, working state được cập nhật dựa trên các phép toán đặc trưng của ChaCha20:

- cộng modulo \(2^{32}\)
- XOR
- rotate-left

Kết quả sau mỗi pha sẽ được ghi trở lại `Working State Register` để sử dụng cho vòng lặp tiếp theo.

### 6. Khối `Final Addition Unit`

Sau khi hoàn thành 20 rounds, ChaCha20 chưa tạo output ngay mà cần thực hiện bước cộng cuối:

```text
final_state[i] = working_state[i] + initial_state[i]
```

Khối `Final Addition Unit` thực hiện phép cộng này cho toàn bộ 16 word của state.

Đây là bước bắt buộc trong block function của ChaCha20.

### 7. Khối `Keystream Output Buffer [511:0]`

Đầu ra sau bước cộng cuối được gom lại thành một khối **512 bit**, tương ứng **64 byte**, và được lưu trong `Keystream Output Buffer`.

Khối này đóng vai trò như bộ đệm đầu ra cho keystream sinh ra từ thuật toán.

### 8. Khối `XOR`

Vì ChaCha20 là một **stream cipher**, nên ciphertext được tạo bằng cách XOR giữa plaintext và keystream:

```text
ciphertext = plaintext XOR keystream
```

Khối `XOR` thực hiện chính phép toán này để tạo ra đầu ra cuối cùng:

```text
ciphertext[511:0]
```

### 9. Kết luận cho Figure 1

Figure 1 thể hiện rõ toàn bộ datapath chính của IP core ChaCha20, từ quá trình khởi tạo state, biến đổi state qua các round, cho đến bước tạo keystream và mã hóa dữ liệu đầu vào. Đây là mức mô tả tổng quát nhất của hệ thống.

---

## Figure 2. Kiến trúc bên trong của Round Engine

<p align="center">
  <img src="./images/figure2.png" alt="Figure 2 - Kiến trúc bên trong của Round Engine" width="850">
</p>

<p align="center"><i>Figure 2. Kiến trúc bên trong của khối Round Engine.</i></p>

Figure 2 mô tả kiến trúc chi tiết hơn của khối **Round Engine**, là thành phần tính toán trung tâm trong Figure 1.

Nhiệm vụ chính của khối này là cập nhật:

```text
working_state[0..15]
```

theo đúng lịch xử lý của thuật toán ChaCha20.

### 1. Đầu vào `working_state[0..15]`

Đầu vào của Round Engine là trạng thái hiện tại lấy từ `Working State Register`.  
Trạng thái này gồm 16 word 32 bit và sẽ được xử lý qua các pha round khác nhau.

### 2. Khối `State Word Selection Network`

Khối `State Word Selection Network` có nhiệm vụ lựa chọn đúng các word trong working state để cấp cho các QR unit.

Trong ChaCha20, tại mỗi pha xử lý, state không được đưa vào một khối duy nhất, mà được chia thành các nhóm bốn word để thực hiện **quarter-round**.

#### Trong `Column Round`, các nhóm word được chọn là:

- `(0,4,8,12)`
- `(1,5,9,13)`
- `(2,6,10,14)`
- `(3,7,11,15)`

#### Trong `Diagonal Round`, các nhóm word được chọn là:

- `(0,5,10,15)`
- `(1,6,11,12)`
- `(2,7,8,13)`
- `(3,4,9,14)`

Như vậy, `State Word Selection Network` đóng vai trò như một mạng chọn chỉ số và phân phối dữ liệu cho các QR unit.

### 3. Các khối `QR Unit`

Các `QR Unit` thực hiện phép **quarter-round** trên bốn word đầu vào:

```text
a, b, c, d
```

Mỗi QR unit tạo ra bốn word đầu ra mới sau khi thực hiện chuỗi phép toán:

- cộng modulo \(2^{32}\)
- XOR
- rotate-left

Trong kiến trúc ChaCha20, các QR unit có thể hoạt động song song ở mức pha xử lý.  
Đây là cơ sở để tăng tốc độ thực thi so với việc chỉ dùng một QR unit duy nhất và tái sử dụng tuần tự cho toàn bộ state.

### 4. Khối `State Update / Writeback`

Sau khi các QR unit hoàn tất tính toán, đầu ra của chúng cần được ghi trở lại đúng vị trí tương ứng trong state.

Khối `State Update / Writeback` đảm nhiệm chức năng này.  
Nó tạo ra một trạng thái mới:

```text
updated_working_state[0..15]
```

Trạng thái cập nhật này sẽ được ghi trở lại `Working State Register` và tiếp tục được sử dụng ở pha kế tiếp.

### 5. Cơ chế lặp của Round Engine

Round Engine hoạt động theo cơ chế vòng lặp khép kín:

```text
working_state
-> chọn word
-> quarter-round
-> writeback
-> updated_working_state
-> lưu lại
-> round tiếp theo
```

Quy trình này được lặp lại cho đến khi hoàn tất đủ:

- **10 double-round**
- tương đương **20 rounds**

### 6. Kết luận cho Figure 2

Figure 2 cho thấy cách Round Engine hiện thực hóa phần cốt lõi của thuật toán ChaCha20 trong phần cứng.  
Khối này chịu trách nhiệm đọc state hiện tại, lựa chọn các word cần thiết, thực hiện quarter-round song song, cập nhật state và lặp lại quá trình đó cho đến khi hoàn tất toàn bộ các round.

---

## Figure 3. Kiến trúc Quarter-Round (tái sử dụng từ paper)

<p align="center">
  <img src="./images/figure3.png" alt="Figure 3 - Kiến trúc Quarter-Round tái sử dụng từ paper" width="700">
</p>

<p align="center"><i>Figure 3. Kiến trúc Quarter-Round tái sử dụng từ paper tham khảo.</i></p>

Figure 3 được tái sử dụng từ paper tham khảo và mô tả chi tiết khối **Quarter-Round**, là đơn vị tính toán cơ bản nhất của ChaCha20.

Nếu Figure 1 mô tả ở mức hệ thống và Figure 2 mô tả ở mức round engine, thì Figure 3 đi xuống mức thấp nhất của datapath, tức là mô tả trực tiếp cấu trúc của một quarter-round.

### 1. Hình (a) – Quarter-round operation in graph form

Hình (a) biểu diễn phép quarter-round dưới dạng đồ thị luồng dữ liệu.  
Bốn đường tín hiệu đầu vào tương ứng với bốn word:

- `a`
- `b`
- `c`
- `d`

Dữ liệu đi qua bốn tầng xử lý liên tiếp.  
Mỗi tầng kết hợp ba loại phép toán cơ bản của ChaCha20:

- **ADD mod \(2^{32}\)**
- **XOR**
- **Rotate-left**

Các lượng quay trái được sử dụng lần lượt là:

- `16`
- `12`
- `8`
- `7`

Dạng biểu diễn này giúp nhìn rõ quan hệ phụ thuộc dữ liệu giữa các bước và thứ tự truyền tín hiệu từ đầu vào đến đầu ra.

### 2. Hình (b) – Two Add-Rotate-XOR Basis Cells

Hình (b) mô tả quarter-round dưới dạng các **ARX basis cells**.

Ở đây, quarter-round được phân rã thành các ô xử lý cơ bản, mỗi ô thực hiện tổ hợp các phép:

- Add
- Rotate
- XOR

Cách biểu diễn này rất phù hợp khi phân tích kiến trúc phần cứng, vì nó cho thấy quarter-round có thể được xây dựng từ các khối xử lý nhỏ hơn, từ đó thuận lợi cho việc thiết kế và tối ưu datapath.

### 3. Hình (c) – Pipelined Add-Rotate-XOR Cell

Hình (c) mô tả phiên bản có pipeline của ARX cell.  
Các hình chữ nhật nhỏ trong sơ đồ chính là các thanh ghi pipeline được chèn vào đường dữ liệu.

Việc thêm pipeline giúp:

- rút ngắn đường truyền tổ hợp
- tăng tần số hoạt động cực đại
- cải thiện throughput của hệ thống

Tuy nhiên, đổi lại, số chu kỳ trễ sẽ tăng lên và việc điều khiển dữ liệu sẽ phức tạp hơn.

### 4. Vai trò của Figure 3 trong toàn bộ kiến trúc

Figure 3 có thể xem là mức chi tiết nhất của toàn bộ thiết kế.  
Trong Figure 2, mỗi `QR Unit` thực chất là một hiện thực phần cứng của quarter-round như được mô tả trong Figure 3.

Nói cách khác:

- **Figure 3** mô tả phần tử tính toán cơ sở
- nhiều phần tử Figure 3 tạo thành **Figure 2**
- Figure 2 kết hợp với các khối khác để tạo thành **Figure 1**

### 5. Kết luận cho Figure 3

Figure 3 giúp làm rõ cách thuật toán quarter-round của ChaCha20 được ánh xạ thành phần cứng.  
Đây là cơ sở quan trọng để xây dựng các QR unit trong Round Engine, đồng thời cũng là nền tảng cho các hướng tối ưu hóa như pipeline hoặc song song hóa trong các nghiên cứu kiến trúc phần cứng.

---

## Mối liên hệ giữa ba figure

Ba figure mô tả kiến trúc ChaCha20 IP core theo cấu trúc phân cấp:

- **Figure 1**: mức tổng thể của IP core
- **Figure 2**: mức trung gian của Round Engine
- **Figure 3**: mức chi tiết của Quarter-Round

Có thể hiểu mối quan hệ giữa ba hình như sau:

```text
Figure 3 (Quarter-Round)
    -> tạo thành các QR Unit trong Figure 2
Figure 2 (Round Engine)
    -> là khối tính toán trung tâm trong Figure 1
Figure 1 (ChaCha20 IP Core)
    -> là kiến trúc hoàn chỉnh của toàn bộ hệ thống
```

Nhờ cách tổ chức này, kiến trúc của ChaCha20 IP core được mô tả đầy đủ từ mức hệ thống đến mức đơn vị tính toán cơ sở. Điều này giúp người đọc dễ theo dõi quá trình ánh xạ thuật toán ChaCha20 sang phần cứng, đồng thời tạo nền tảng tốt cho giai đoạn thiết kế RTL và hiện thực trên FPGA.
