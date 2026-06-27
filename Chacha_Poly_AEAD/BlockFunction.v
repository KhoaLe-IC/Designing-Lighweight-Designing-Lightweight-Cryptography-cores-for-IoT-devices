module BlockFunction(
    input clk, load_en, ready,
	input [31:0] I,
	input [3:0] read_addr,     // Địa chỉ word cần đọc xuất ra ngoài
	output [31:0] O,           // Dữ liệu word ngõ ra
    output reg finish         // Cờ báo cộng xong ma trận gốc (Hoàn thành)
);
	
    reg [2:0] state;           // 8 nhịp (Steps) cho mỗi cụm QuarterRound
    reg [1:0] qr_id;           // ID của hàm QuarterRound (0 đến 3)
    reg [4:0] round_cnt;       // Đếm số vòng (0 đến 19, tổng cộng 20 vòng)
    reg [3:0] Add_count, load_cnt;

    reg [31:0] Matrix [0:15];   // Ma trận trạng thái 4x4 (Chứa dữ liệu đang băm)
    reg [31:0] OGMatrix [0:15]; // Ma trận gốc (Original) để lưu Khóa/Nonce ban đầu

    // -------------------------------------------------------------------------
    // HÀM HẰNG SỐ (ChaCha20 Constants)
    // 4 Word đầu tiên luôn là chuỗi ASCII "expand 32-byte k"
    // -------------------------------------------------------------------------
    function [31:0] Constant;
        input [1:0] idx;
        begin
            case(idx)
                2'd0: Constant = 32'h61707865;
                2'd1: Constant = 32'h3320646e;
                2'd2: Constant = 32'h79622d32;
                2'd3: Constant = 32'h6b206574;
            endcase
        end
    endfunction

    wire done = (round_cnt == 5'd20); // Dừng sau 20 vòng

    // -------------------------------------------------------------------------
    // LOGIC ĐỊNH TUYẾN CHỈ SỐ (Index Routing cho Ma trận)
    // Lẻ = Vòng chéo (Diagonal), Chẵn = Vòng cột (Column)
    // -------------------------------------------------------------------------
    wire diag = round_cnt[0];
    wire [1:0] b_idx = qr_id + 2'd1;
    wire [1:0] c_idx = qr_id + 2'd2;
    wire [1:0] d_idx = qr_id + 2'd3;

    // Xác định 4 phần tử (A, B, C, D) tham gia vào 1 QuarterRound
    wire [3:0] A = {2'b00, qr_id};
    wire [3:0] B = (diag) ? {2'b01, b_idx} : {2'b01, qr_id};
    wire [3:0] C = (diag) ? {2'b10, c_idx} : {2'b10, qr_id};
    wire [3:0] D = (diag) ? {2'b11, d_idx} : {2'b11, qr_id};

    // Bộ chọn: Đưa 2 phần tử nào vào ALU để tính trước?
    reg [3:0] indx0, indx1;
    always @(*) begin
        if(state == 3'd0 || state == 3'd4) begin 
			indx0 = A; indx1 = B;  // Bước tính: a = a + b, d = d ^ a
		end
        else if (state == 3'd1 || state == 3'd5) begin 
			indx0 = D; indx1 = A;
		end
        else if(state == 3'd2 || state == 3'd6) begin 
			indx0 = C; indx1 = D;  // Bước tính: c = c + d, b = b ^ c
		end
        else begin
			indx0 = B; indx1 = C;
		end
    end

    // -------------------------------------------------------------------------
    // TÍN HIỆU ĐIỀU KHIỂN ALU CHIA SẺ
    // -------------------------------------------------------------------------
    wire add_xr = ~state[0];  // 1 = Cộng (+), 0 = XOR (^)
    wire [1:0] rot_sw = state[2:1]; // Mức dịch bit (16, 12, 8, 7)
    
    // Nguồn dữ liệu cộng cuối cùng (Cộng ma trận gốc)
    wire [31:0] Pick = (Add_count < 4) ? Constant(Add_count[1:0]) : OGMatrix[Add_count];
    
    // -------------------------------------------------------------------------
    // FSM CỐT LÕI (Thực hiện Băm 20 Vòng và Cộng chốt)
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!ready) begin
            // Trạng thái Reset & Nạp ban đầu
            state <= 3'd0; qr_id <= 2'd0; round_cnt <= 5'd0; Add_count <= 4'd0; finish <= 1'b0;
            if (load_en) begin
                if (load_cnt >= 4) OGMatrix[load_cnt] <= I; // Lưu khóa/nonce gốc
                // Nạp tự động 4 hằng số đầu, 12 word sau là Input
                Matrix[load_cnt] <= (load_cnt < 4) ? Constant(load_cnt[1:0]) : I;
                load_cnt <= load_cnt + 1'b1;
            end else load_cnt <= 4'd0;
        end 
        else if (!done) begin 
            // VÒNG LẶP CHÍNH: Xoay QuarterRound 20 vòng
            Matrix[indx0] <= QuarterRound(Matrix[indx0], Matrix[indx1], rot_sw, add_xr);            
            state <= state + 3'd1; // Chạy 8 bước cho 1 QuarterRound
            if (state == 3'd7) begin
                if (qr_id == 2'd3) begin // Tính xong 4 cột/đường chéo
					qr_id <= 2'd0;
					round_cnt <= round_cnt + 5'd1; // Tăng số vòng băm
				end 
                else qr_id <= qr_id + 2'd1;
            end
        end 
        else if (done && !finish) begin 
            // BƯỚC CUỐI: Cộng Ma trận gốc vào Ma trận đã băm
            // Dùng lại hàm QuarterRound nhưng ép làm phép Cộng (+)
            Matrix[Add_count] <= QuarterRound(Matrix[Add_count], Pick, 2'b00, 1'b1);
            if (Add_count == 4'd15) finish <= 1'b1; // Cộng xong 16 Word
            else Add_count <= Add_count + 4'd1;
        end
    end

    // Kéo dây xuất Word theo yêu cầu của FSM (bên ngoài)
    assign O = Matrix[read_addr]; 

    // -------------------------------------------------------------------------
    // HÀM QUARTER ROUND (Dùng chung cho cả Cộng, XOR và Dịch bit)
    // Tiết kiệm ALU: Gộp các phép tính lại và điều khiển bằng Switch
    // -------------------------------------------------------------------------
    function [31:0] QuarterRound;
        input [31:0] in_A, in_B; 
        input [1:0] Rsw;   // Công tắc Dịch bit (Rotation Switch)
        input AXsw;        // Công tắc Cộng/XOR (Add/XOR Switch)
        
        reg [31:0] Xor_result;
        begin
            if (AXsw) 
                QuarterRound = in_A + in_B; // Phép Cộng
            else begin
                Xor_result = in_A ^ in_B;   // Phép XOR
                case (Rsw) // Dịch vòng trái (Left Rotate) tùy nhịp
                    2'b00: QuarterRound = {Xor_result[15:0], Xor_result[31:16]}; // ROL 16
                    2'b01: QuarterRound = {Xor_result[19:0], Xor_result[31:20]}; // ROL 12
                    2'b10: QuarterRound = {Xor_result[23:0], Xor_result[31:24]}; // ROL 8
                    2'b11: QuarterRound = {Xor_result[24:0], Xor_result[31:25]}; // ROL 7
                    default: QuarterRound = Xor_result;
                endcase
            end
        end
    endfunction
endmodule
