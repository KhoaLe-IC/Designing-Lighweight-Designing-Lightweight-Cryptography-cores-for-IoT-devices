// ==============================================================================
// MODULE: PolyAEAD (Top-level Wrapper cho Poly1305 trong chế độ AEAD)
// Chức năng: Đóng gói Controller và MAC Core, xử lý định tuyến tín hiệu 
//            và đảo chiều Byte (Endianness) để giao tiếp với Bus bên ngoài.
// ==============================================================================
module PolyAEAD (
    // ---------------------------------------------------------
    // 1. TÍN HIỆU ĐIỀU KHIỂN HỆ THỐNG (SYSTEM CONTROLS)
    // ---------------------------------------------------------
    input clk,          // Xung nhịp hệ thống (Clock)
    input start,        // Tín hiệu kích hoạt/Reset mạch để bắt đầu gói tin mới
    input valid,        // Cờ báo hiệu dữ liệu ở cổng I đang hợp lệ
    input is_last,      // Cờ báo hiệu đây là từ (word) dữ liệu cuối cùng của luồng

    // ---------------------------------------------------------
    // 2. BUS DỮ LIỆU ĐẦU VÀO (INPUT DATA BUS)
    // ---------------------------------------------------------
    input [31:0] I,         // Dữ liệu đầu vào 32-bit (4 bytes)
    input [2:0] byte_vld,   // Số lượng byte hợp lệ trong I (từ 1 đến 4 byte)
    input [2:0] type_in,    // Định tuyến loại dữ liệu: 0(Khóa r), 1(Khóa s), 2(AAD), 3(Ciphertext), 4(End)

    // ---------------------------------------------------------
    // 3. TÍN HIỆU GIAO TIẾP VÀ ĐẦU RA (HANDSHAKE & OUTPUT)
    // ---------------------------------------------------------
    output ready,       // Mạch báo sẵn sàng nhận dữ liệu mới (Handshake với valid)
    output finish,      // Cờ báo hiệu đã tính toán xong toàn bộ MAC Tag
    output [31:0] O     // Dữ liệu đầu ra 32-bit (Chứa MAC Tag trả về)
);

    // ---------------------------------------------------------
    // 4. DÂY DẪN NỘI BỘ (INTERNAL WIRES) - Dùng để nối 2 module con
    // ---------------------------------------------------------
    wire [31:0] mac_I;          // Dữ liệu đã được controller xử lý trước khi đưa vào lõi MAC
    wire [31:0] O_temp;         // MAC Tag nguyên bản từ lõi MAC xuất ra (chưa đảo byte)
    wire [31:0] inp;            // Dữ liệu đầu vào I sau khi đã đảo byte
    
    // Các dây tín hiệu điều khiển (Control Wires) do Controller phát ra để lái PolyMAC
    wire mac_start;             // Lệnh khởi động lõi MAC
    wire mac_in_r;              // Lệnh nạp khóa r vào lõi MAC
    wire mac_in_s;              // Lệnh nạp khóa s vào lõi MAC
    wire mac_data_in;           // Lệnh nạp dữ liệu (message) vào lõi MAC
    wire mac_finish;            // Tín hiệu báo xong từ lõi MAC dội ngược lại Controller
    wire [4:0] mac_msg_bytes;   // Chỉ định số byte hợp lệ cho khối dữ liệu cuối cùng của MAC

    // ---------------------------------------------------------
    // 5. MẠCH ĐẢO CHIỀU BYTE ĐẦU VÀO (LITTLE-ENDIAN -> BIG-ENDIAN)
    // Chức năng: Vi mạch mã hóa thường xử lý theo Big-Endian, 
    // trong khi Bus dữ liệu thường là Little-Endian. Nối dây chéo để đảo thứ tự.
    // ---------------------------------------------------------
    assign inp = {I[7:0], I[15:8], I[23:16], I[31:24]};

    // ---------------------------------------------------------
    // 6. INSTANTIATION: BỘ NÃO ĐIỀU KHIỂN (AEAD_CONTROLLER)
    // Chức năng: Đếm byte, đệm số 0 (Padding) cho đủ block 16 bytes, 
    // và điều phối luồng dữ liệu chuẩn xác xuống lõi tính toán.
    // ---------------------------------------------------------
    AEAD_controller ctrl (
        .clk(clk), 
        .start(start), 
        .I(inp),                // Nhận dữ liệu đã đảo byte
        .byte_vld(byte_vld),
        .type_in(type_in), 
        .valid(valid), 
        .is_last(is_last),
        .ready(ready),          // Xuất tín hiệu ready ra ngoài hệ thống
        
        // Cụm tín hiệu điều khiển bắn xuống PolyMAC
        .mac_I(mac_I), 
        .mac_start(mac_start), 
        .mac_in_r(mac_in_r), 
        .mac_in_s(mac_in_s), 
        .mac_data_in(mac_data_in), 
        .mac_msg_bytes(mac_msg_bytes), 
        
        // Cụm tín hiệu nhận về và chốt trạng thái
        .mac_finish(mac_finish), 
        .finish(finish)         // Báo cáo hoàn thành ra ngoài hệ thống
    );

    // ---------------------------------------------------------
    // 7. INSTANTIATION: LÕI TÍNH TOÁN TOÁN HỌC (POLYMAC)
    // Chức năng: Chứa ALU để tính toán Modulo 2^130-5 và thực hiện
    // thuật toán nhân cộng Shift-and-Add cốt lõi của Poly1305.
    // ---------------------------------------------------------
    PolyMAC mac (
        .clk(clk), 
        .start(mac_start),      // Nhận lệnh start từ controller
        .I(mac_I),              // Nhận dữ liệu đã được controller "làm sạch" và đệm chuẩn
        .in_r(mac_in_r), 
        .in_s(mac_in_s), 
        .data_in(mac_data_in), 
        .msg_bytes(mac_msg_bytes), 
        .O(O_temp),             // Xuất MAC Tag nguyên bản
        .finish(mac_finish)     // Báo cáo cho controller biết đã tính xong
    );

    // ---------------------------------------------------------
    // 8. MẠCH ĐẢO CHIỀU BYTE ĐẦU RA (BIG-ENDIAN -> LITTLE-ENDIAN)
    // Chức năng: Trả lại MAC Tag về chuẩn byte ban đầu để trả ra Bus.
    // ---------------------------------------------------------
    assign O = {O_temp[7:0], O_temp[15:8], O_temp[23:16], O_temp[31:24]};

endmodule