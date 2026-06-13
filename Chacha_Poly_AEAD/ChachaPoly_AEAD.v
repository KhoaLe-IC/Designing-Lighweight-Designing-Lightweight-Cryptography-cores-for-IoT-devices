module ChachaPoly_AEAD(
    input clk, start, encrypt,           // Tín hiệu điều khiển: Clock, Bắt đầu (reset FSM), Chế độ (1 = Mã hóa, 0 = Giải mã)
    input [31:0] I,                      // Dữ liệu đầu vào (Key, Nonce, AAD, Plaintext/Ciphertext)
    input [2:0] byte_vld, type_in,       // byte_vld: Số byte hợp lệ (1-4). type_in: Loại dữ liệu (0=Key, 1=Nonce, 2=AAD, 3=Payload, 4=End)
    input valid, is_last,                // valid: Báo I có dữ liệu. is_last: Báo đây là Word cuối cùng của luồng
    
    output ready,                        // Báo hiệu Top Module đã sẵn sàng nhận dữ liệu từ Testbench
    output reg [31:0] O,                 // Dữ liệu đầu ra (Ciphertext nếu encrypt=1, Plaintext nếu encrypt=0)
    output reg valid_out,                // Báo hiệu đầu ra O đã có dữ liệu hợp lệ
    output [31:0] tag_out,               // Đầu ra chứa MAC Tag 128-bit (Chia làm 4 Word xuất liên tiếp ở cuối quá trình)
    output finish                        // Cờ báo hiệu quá trình xác thực AEAD đã hoàn tất
);

    // BỘ NHỚ LƯU TRỮ TRẠNG THÁI (Context Registers)
    reg [31:0] key_reg [0:7];            // Lưu khóa ChaCha20 (256-bit = 8 Words)
    reg [31:0] nonce_reg [0:2];          // Lưu Nonce (96-bit = 3 Words)
    reg [31:0] block_counter;            // Bộ đếm khối ChaCha20 (Bắt đầu từ 0 cho PolyKey, từ 1 cho Payload)

    // BỘ ĐẾM VÀ TRẠNG THÁI (FSM Control)
    reg [3:0] cnt;                       // Bộ đếm dùng chung để nạp/xả dữ liệu (tiết kiệm Area so với dùng 2 biến)
    reg [3:0] main_state;                // Máy trạng thái chính của Top Module

    // GIAO TIẾP VỚI LÕI CHACHA20
    reg chacha_start, chacha_ready_in;   // Điều khiển nạp khối vào ChaCha
    reg [31:0] chacha_I;                 // Dữ liệu nạp vào ChaCha (Gồm Hằng số, Key, Counter, Nonce)
    wire [31:0] chacha_O;                // Keystream xuất ra từ ChaCha
    wire chacha_valid_out;               // Báo hiệu Keystream đã sẵn sàng

    Chacha_algo chacha_core (
        .clk(clk), .start(chacha_start), .I(chacha_I),
        .ready_in(chacha_ready_in), .O(chacha_O), .valid_out(chacha_valid_out)
    );

    // GIAO TIẾP VỚI LÕI POLY1305 (MAC)
    reg poly_valid, poly_is_last;        // Điều khiển nạp dữ liệu vào Poly
    reg [31:0] poly_I;                   // Dữ liệu nạp vào Poly (PolyKey, AAD, Ciphertext)
    reg [2:0] poly_type_in, poly_byte_vld; // Loại dữ liệu và số byte hợp lệ nạp vào Poly
    wire poly_ready, poly_finish;        // Tín hiệu Handshake từ Poly phản hồi lại Top Module

    PolyAEAD poly_core (
        .clk(clk), .start(start), .valid(poly_valid), .is_last(poly_is_last),
        .I(poly_I), .byte_vld(poly_byte_vld), .type_in(poly_type_in),
        .ready(poly_ready), .finish(poly_finish), .O(tag_out)
    );

    assign finish = poly_finish;         // Top Module báo Finish khi lõi Poly báo Finish
    
    // MẠCH MỞ CỬA (Ready Logic): Top Module chỉ sẵn sàng nhận dữ liệu khi:
    // - Đang nạp Key/Nonce (State 1, 2)
    // - Đã xong xuôi (State 0 hoặc 10) và gặp lệnh kết thúc (type_in = 4)
    // - Đang băm Payload (State 9) VÀ cả lõi Poly + ChaCha đều đang rảnh.
    assign ready = (main_state == 4'd1 || main_state == 4'd2 || main_state == 4'd10 || (main_state == 4'd0 && type_in == 3'd4)) ? 1'b1 :
                   (main_state == 4'd9) ? ((type_in == 3'd3) ? (poly_ready && chacha_valid_out) : poly_ready) : 1'b0;

    // MẠCH MẶT NẠ (Byte Masking): Xóa các byte rác ở đuôi nếu khối dữ liệu bị lẻ (vd: chỉ có 1, 2, 3 bytes hợp lệ)
    wire [31:0] mask = (byte_vld == 3'd1) ? 32'hFF000000 :
                       (byte_vld == 3'd2) ? 32'hFFFF0000 :
                       (byte_vld == 3'd3) ? 32'hFFFFFF00 : 32'hFFFFFFFF;
                     
    wire [31:0] clean_O = chacha_O & mask;  // Keystream đã lọc byte thừa
    wire [31:0] clean_I = I & mask;         // Dữ liệu đầu vào đã lọc byte thừa

    // =========================================================================
    // MẠCH ĐỊNH TUYẾN DỮ LIỆU TỔ HỢP (Datapath Routing)
    // =========================================================================
		always @(*) begin

		// Trạng thái mặc định: Đóng toàn bộ cửa xả
		poly_valid      = 1'b0;
		poly_I          = 32'd0;
		poly_type_in    = 3'd0;
		poly_byte_vld   = 3'd4;
		poly_is_last    = 1'b0;

		chacha_ready_in = 1'b0;
		chacha_I        = 32'd0;

		valid_out       = 1'b0;
		O               = 32'd0;

		// KHI CHACHA CẦN NẠP STATE MATRIX
		// (Block_0 để tạo Khóa Poly, hoặc Block_1,2... để mã hóa Payload)
		if (main_state == 4'd4 || main_state == 4'd8) begin

			if (cnt < 4) begin
				// 4 Word hằng số "expand 32-byte k"
				chacha_I = 32'd0;
			end
			else if (cnt < 12) begin
				// 8 Word Key
				chacha_I = key_reg[cnt - 4];
			end
			else if (cnt == 12) begin
				// Counter (Little Endian)
				chacha_I = {
					block_counter[7:0],
					block_counter[15:8],
					block_counter[23:16],
					block_counter[31:24]
				};
			end
			else begin
				// 3 Word Nonce
				chacha_I = nonce_reg[cnt - 13];
			end

		end

		// KHI TẠO KHÓA POLY (block_counter = 0)
		else if (main_state == 4'd6) begin

			poly_I = chacha_O;

			// 4 Word đầu là r, 4 Word sau là s
			poly_type_in = (cnt < 4) ? 3'd0 : 3'd1;

			poly_byte_vld = 3'd4;

			if (cnt < 8) begin

				poly_valid      = chacha_valid_out;
				chacha_ready_in = poly_ready;

			end
			else begin

				// Xả bỏ 8 Word còn lại
				chacha_ready_in = 1'b1;

			end
		end

		// KHI MÃ HÓA/GIẢI MÃ PAYLOAD & BĂM AAD
		else if (main_state == 4'd9 || main_state == 4'd10) begin

			if (valid) begin

				// AAD (Additional Authenticated Data)
				if (type_in == 3'd2) begin

					poly_valid    = 1'b1;
					poly_I        = clean_I;
					poly_type_in  = 3'd2;
					poly_byte_vld = byte_vld;
					poly_is_last  = is_last;

					// AAD không qua ChaCha

				end

				// Payload cần mã hóa/giải mã
				else if (type_in == 3'd3) begin

					chacha_I = I;

					poly_valid    = chacha_valid_out;
					poly_type_in  = 3'd3;
					poly_byte_vld = byte_vld;
					poly_is_last  = is_last;

					// AEAD luôn băm Ciphertext
					if (encrypt)
						poly_I = clean_O;
					else
						poly_I = clean_I;

					O = clean_O;

					valid_out       = poly_ready && chacha_valid_out;
					chacha_ready_in = poly_ready;

				end

				// Lệnh kết thúc
				else if (type_in == 3'd4) begin

					poly_valid   = 1'b1;
					poly_type_in = 3'd4;
					poly_is_last = 1'b1;

				end
			end
		end

	end

    // =========================================================================
    // MÁY TRẠNG THÁI ĐIỀU KHIỂN FSM (Sequential Logic)
    // =========================================================================
    always @(posedge clk) begin
        if (start) begin
            // RESET: Đưa hệ thống về trạng thái nạp Key
            main_state <= 4'd1; cnt <= 0; block_counter <= 32'd0; chacha_start <= 0;
        end else begin
			case (main_state)
				4'd0: ;
				// STATE 1: Nạp 8 Words Khóa ChaCha
				4'd1: begin
					if (valid && type_in == 3'd0) begin
						key_reg[cnt[2:0]] <= I;

						if (cnt == 7) begin
							main_state <= 4'd2;
							cnt        <= 0;
						end
						else begin
							cnt <= cnt + 1;
						end
					end
				end

				// STATE 2: Nạp 3 Words Nonce
				4'd2: begin
					if (valid && type_in == 3'd1) begin
						nonce_reg[cnt[1:0]] <= I;

						if (cnt == 2) begin
							main_state    <= 4'd3;
							cnt           <= 0;
							block_counter <= 0;
						end
						else begin
							cnt <= cnt + 1;
						end
					end
				end

				// STATE 3: Kích hoạt lõi ChaCha bắt đầu chạy
				4'd3: begin
					chacha_start <= 1;
					main_state   <= 4'd4;
					cnt          <= 0;
				end

				// STATE 4: Bơm 16 Words cấu hình vào ChaCha
				4'd4: begin
					if (cnt < 15)
						cnt <= cnt + 1;
					else
						main_state <= 4'd5;
				end

				// STATE 5: Đợi ChaCha trộn xong 20 Rounds
				4'd5: begin
					if (chacha_valid_out) begin
						main_state <= 4'd6;
						cnt        <= 0;
					end
				end

				// STATE 6: Rút Keystream Block 0 làm khóa PolyMAC
				4'd6: begin
					if (chacha_ready_in && chacha_valid_out) begin
						if (cnt == 15) begin
							main_state    <= 4'd7;
							chacha_start  <= 0;
							block_counter <= 1;
						end
						else begin
							cnt <= cnt + 1;
						end
					end
				end

				// STATE 7: Kích hoạt ChaCha cho Payload
				4'd7: begin
					chacha_start <= 1;
					main_state   <= 4'd8;
					cnt          <= 0;
				end

				// STATE 8: Bơm 16 Words cấu hình Block 1,2,...
				4'd8: begin
					if (cnt < 15) begin
						cnt <= cnt + 1;
					end
					else begin
						main_state <= 4'd9;
						cnt        <= 0;
					end
				end
                
                // STATE 9: PHA XỬ LÝ PAYLOAD CHÍNH
                4'd9: begin 
                    if (valid && ready) begin
                        if (type_in == 3'd3) begin
                            // Nếu hết luồng dữ liệu -> Nhảy sang đợi chốt sổ
                            if (is_last) begin main_state <= 4'd10; chacha_start <= 0; end 
                            // Nếu đã dùng hết 1 khối Keystream (16 Words) -> Nhảy về State 7 tạo khối Keystream mới
                            else if (cnt == 15) begin main_state <= 4'd7; chacha_start <= 0; block_counter <= block_counter + 1; end 
                            // Đang băm dở khối -> Tăng đếm
                            else cnt <= cnt + 1;
                        end
                        // Nếu Testbench gửi lệnh đóng gói tin khẩn cấp
                        else if (type_in == 3'd4) begin
                            main_state <= 4'd10; chacha_start <= 0;
                        end
                    end
                end
                
                // STATE 10: Chờ lõi Poly băm nốt chiều dài (Lengths) và nhả MAC Tag, rồi về IDLE.
                4'd10: begin if (poly_finish) main_state <= 4'd0; end
                
                default: main_state <= 4'd0;
            endcase
        end
    end
endmodule