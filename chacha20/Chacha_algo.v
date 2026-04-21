module Chacha_algo(
    input clk, start,
    input [255:0] key,
    input [31:0] bc,
    input [95:0] nonce,
    input [511:0] plaintext,
    output [511:0] ciphertext,
    output finish
);

    // FSM States: 0(Idle), 1(Init Matrix), 2-9(Quarter Rounds), 10(Done)
    reg [3:0] fsm_state = 4'd0;
    reg [3:0] round_cnt = 4'd0;

    wire [511:0] keystream;
    wire [3:0] idx_a, idx_b, idx_c, idx_d;
    wire qr_done;

    BlockFunction BK (
        .clk(clk),
        .key(key), .nonce(nonce), .bc(bc),
        .fsm_state(fsm_state),
        .idx_a(idx_a), .idx_b(idx_b), .idx_c(idx_c), .idx_d(idx_d),
        .keystream(keystream),
        .qr_done(qr_done)
    );

    always @(posedge clk) begin
        // STATE 0: Đứng chờ input đã sẵn sàng và đợi lệnh start
        if (fsm_state == 4'd0) begin
            if (start) begin
                fsm_state <= 4'd1;  // Chuyển sang nạp ma trận
                round_cnt <= 4'd0;
            end
        end
        // STATE 1: Quá trình nạp dữ liệu vào ma trận diễn ra ở đây
        else if (fsm_state == 4'd1) begin
            fsm_state <= 4'd2;      // Nạp xong, sang Quarter Round đầu tiên
        end
        // STATE 2 -> 9: Thực thi 8 Quarter Rounds (4 cột, 4 chéo)
        else if (fsm_state >= 4'd2 && fsm_state <= 4'd9) begin
            if (qr_done) begin 
                if (fsm_state == 4'd9) begin 
                    if (round_cnt == 4'd9) begin
                        fsm_state <= 4'd10; // Đã xong đủ 10 vòng Double Round
                    end else begin
                        round_cnt <= round_cnt + 1'b1;
                        fsm_state <= 4'd2;  // Quay lại cột đầu tiên của vòng mới
                    end
                end else begin
                    fsm_state <= fsm_state + 1'b1;
                end
            end
        end
        // STATE 10: Xong, xuất tín hiệu finish và đợi reset
        else if (fsm_state == 4'd10) begin
            if (!start) begin
                fsm_state <= 4'd0;
            end
        end
    end

    assign finish = (fsm_state == 4'd10);
    assign ciphertext = keystream ^ plaintext;

    // Bộ giải mã địa chỉ ma trận (Căn chỉnh lại index do dời state)
    wire [1:0] qr_idx;
    wire is_diag;
    
    assign qr_idx = (fsm_state >= 4'd2 && fsm_state <= 4'd9) ? (fsm_state - 4'd2) : 2'd0;
    assign is_diag = (fsm_state >= 4'd6);

    assign idx_a = {2'b00, qr_idx};
    assign idx_b = {2'b01, qr_idx + {1'b0, is_diag}};
    assign idx_c = {2'b10, qr_idx + {is_diag, 1'b0}};
    assign idx_d = {2'b11, qr_idx + ((is_diag) ? 2'd3 : 2'd0)};

endmodule
