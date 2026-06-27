module Chacha_algo(
    input clk, start;          // Xung nhịp và tín hiệu khởi động (Active-High)
    input [31:0] I;            // Luồng dữ liệu vào (Khóa, Nonce, Dữ liệu bản rõ)
    input ready_in;            // Cờ cho biết thiết bị nhận dữ liệu đã sẵn sàng

    output reg [31:0] O;       // Luồng dữ liệu ra (Bản mã - Ciphertext)
    output reg valid_out;      // Cờ báo hiệu dữ liệu ngõ ra hợp lệ
);
    
    wire finish;               // Cờ từ BlockFunction báo đã cộng xong ma trận gốc
    wire [31:0] block_O;       // 1 Word (32-bit) xuất ra từ ma trận trạng thái
    reg [3:0] read_addr;       // Con trỏ địa chỉ để đọc lần lượt 16 Word từ ma trận

    reg [1:0] state;           // Máy trạng thái chính (FSM)
    reg [4:0] word_cnt;        // Bộ đếm đếm đủ 16 Word (1 Block = 512 bit)

    // -------------------------------------------------------------------------
    // HÀM SWAP_BYTES: Chuyển đổi Little-Endian <-> Big-Endian
    // ChaCha20 yêu cầu nạp và xuất dữ liệu theo chuẩn Little-Endian.
    // -------------------------------------------------------------------------
    function [31:0] swap_bytes;
        input [31:0] in_word;
        begin
            swap_bytes = {in_word[7:0], in_word[15:8], in_word[23:16], in_word[31:24]};
        end
    endfunction

    wire [31:0] I_math = swap_bytes(I);        // Chuyển ngõ vào sang dạng tính toán
    wire load_en = start && (state == 2'd0);   // Cho phép nạp dữ liệu khi FSM ở State 0
    wire ready   = start && (state != 2'd0);   // Kích hoạt BlockFunction tính toán

    // Khởi tạo Lõi tính toán Ma trận ChaCha20
    BlockFunction BF (
        .clk(clk),
        .I(I_math),
        .load_en(load_en),
        .read_addr(read_addr),
        .ready(ready),
        .O(block_O),
        .finish(finish)
    );

    // -------------------------------------------------------------------------
    // KHỐI XOR LUỒNG (XOR STREAM) VÀ KIỂM SOÁT VALID
    // -------------------------------------------------------------------------
    always @(*) begin
        if (state == 2'd2) begin
            // Nếu mạch đang ở State XOR (2): Thực hiện phép XOR giữa Bản rõ (I) 
            // và luồng khóa Keystream (block_O) để tạo ra Bản mã (O).
            O = I ^ swap_bytes(block_O);
            valid_out = 1'b1; // Bật cờ valid cho hệ thống AEAD chốt data
        end else begin
            O = 32'd0;
            valid_out = 1'b0;
        end
    end

    // -------------------------------------------------------------------------
    // MÁY TRẠNG THÁI FSM CHÍNH
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!start) begin
            state     <= 2'd0;
            word_cnt  <= 5'd0;
            read_addr <= 4'd0;
        end
        else begin
            case (state)
                // STATE 0: Nạp 16 Word (Khóa, Nonce, Counter) vào Ma trận
                2'd0: begin
                    if (word_cnt == 5'd15) begin
                        state <= 2'd1;     // Nạp đủ 16 từ -> Nhảy sang State 1
                        word_cnt <= 5'd0;
                    end
                    else
                        word_cnt <= word_cnt + 5'd1;
                end

                // STATE 1: Chờ BlockFunction băm 20 vòng và cộng ma trận gốc
                2'd1: begin
                    if (finish) begin      // Khi cờ finish từ BF bật lên
                        state <= 2'd2;     // Nhảy sang State xuất dữ liệu
                        word_cnt <= 5'd0;
                        read_addr <= 4'd0; // Bắt đầu đọc từ Word 0
                    end
                end

                // STATE 2: Đẩy 16 Word Bản rõ vào để XOR và xuất ra Bản mã
                2'd2: begin
                    if (ready_in) begin // Mạch sau (PolyMAC) đã sẵn sàng nhận
                        if (word_cnt == 5'd15) begin
                            state <= 2'd3; // XOR xong 16 Word -> Chờ lệnh tiếp
                        end
                        else begin
                            read_addr <= read_addr + 4'd1; // Tăng con trỏ đọc ma trận
                            word_cnt  <= word_cnt + 5'd1;
                        end
                    end
                end

                // STATE 3: Trạng thái chờ/kết thúc 1 Block
                2'd3: begin
                end

                default: state <= 2'd0;
            endcase
        end
    end
endmodule
