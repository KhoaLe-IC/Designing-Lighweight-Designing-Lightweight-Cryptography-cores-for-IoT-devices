module BlockFunction(
    input clk,
    input [255:0] key,
    input [31:0] bc,
    input [95:0] nonce,
    input [3:0] fsm_state,
    input [3:0] idx_a, idx_b, idx_c, idx_d, 
    output [511:0] keystream,
    output qr_done
);
    
    reg [31:0] state_matrix [0:15];
    reg [3:0]  step_cnt; // Đã đổi thành bộ đếm 4-bit (chạy từ 0 đến 5)
    reg [31:0] abcd_vars [0:3];
    
    always @(posedge clk) begin
        // Nạp dữ liệu vào State Matrix (IRF) tại FSM State 1
        if (fsm_state == 4'd1) begin
            state_matrix[0] <= 32'h61707865;
            state_matrix[1] <= 32'h3320646e;
            state_matrix[2] <= 32'h79622d32;
            state_matrix[3] <= 32'h6b206574;
            state_matrix[4] <= key[31:0];    
            state_matrix[5] <= key[63:32];   
            state_matrix[6] <= key[95:64];   
            state_matrix[7] <= key[127:96];  
            state_matrix[8] <= key[159:128]; 
            state_matrix[9] <= key[191:160]; 
            state_matrix[10]<= key[223:192]; 
            state_matrix[11]<= key[255:224]; 
            state_matrix[12]<= bc;     
            state_matrix[13]<= nonce[31:0];  
            state_matrix[14]<= nonce[63:32]; 
            state_matrix[15]<= nonce[95:64]; 

            step_cnt <= 4'd0;
        end
        // Tính toán Quarter Round
        else if (fsm_state >= 4'd2 && fsm_state <= 4'd9) begin
            if (step_cnt == 4'd0) begin
                abcd_vars[0] <= state_matrix[idx_a];
                abcd_vars[1] <= state_matrix[idx_b];
                abcd_vars[2] <= state_matrix[idx_c];
                abcd_vars[3] <= state_matrix[idx_d];
                step_cnt <= 4'd1;
            end
            else if (step_cnt == 4'd1) begin
                abcd_vars[0] <= adder_out;
                abcd_vars[3] <= rot_16;
                step_cnt <= 4'd2;
            end
            else if (step_cnt == 4'd2) begin
                abcd_vars[2] <= adder_out;
                abcd_vars[1] <= rot_12;
                step_cnt <= 4'd3;
            end
            else if (step_cnt == 4'd3) begin
                abcd_vars[0] <= adder_out;
                abcd_vars[3] <= rot_8;
                step_cnt <= 4'd4; 
            end
            else if (step_cnt == 4'd4) begin
                abcd_vars[2] <= adder_out;
                abcd_vars[1] <= rot_7;
                step_cnt <= 4'd5;  
            end
            else if (step_cnt == 4'd5) begin
                state_matrix[idx_a] <= abcd_vars[0];
                state_matrix[idx_b] <= abcd_vars[1];
                state_matrix[idx_c] <= abcd_vars[2];
                state_matrix[idx_d] <= abcd_vars[3];
                step_cnt <= 4'd0;  
            end
        end
    end    
    
    // Đổi tên các tín hiệu ALU cho đúng chức năng
    wire [31:0] alu_in_a, alu_in_b, alu_in_d;
    wire [31:0] adder_out, xor_out;
    wire [31:0] rot_16, rot_12, rot_8, rot_7;
    
    // Nếu là bước 2 hoặc 4, ALU sẽ tính toán cho cập (c, b) thay vì (a, d)
    wire is_cb_step = (step_cnt == 4'd2 || step_cnt == 4'd4);

    assign alu_in_a = (is_cb_step) ? abcd_vars[2] : abcd_vars[0];
    assign alu_in_b = (is_cb_step) ? abcd_vars[3] : abcd_vars[1];
    assign alu_in_d = (is_cb_step) ? abcd_vars[1] : abcd_vars[3];
    
    assign adder_out = alu_in_a + alu_in_b;
    assign xor_out   = alu_in_d ^ adder_out;
    
    assign rot_16 = {xor_out[15:0], xor_out[31:16]};
    assign rot_12 = {xor_out[19:0], xor_out[31:20]};
    assign rot_8  = {xor_out[23:0], xor_out[31:24]};
    assign rot_7  = {xor_out[24:0], xor_out[31:25]};
    
    // Xuất chuỗi Keystream
    assign keystream = {
        state_matrix[15] + nonce[95:64], 
        state_matrix[14] + nonce[63:32], 
        state_matrix[13] + nonce[31:0], 
        state_matrix[12] + bc[31:0],
        state_matrix[11] + key[255:224], 
        state_matrix[10] + key[223:192], 
        state_matrix[9]  + key[191:160], 
        state_matrix[8]  + key[159:128],
        state_matrix[7]  + key[127:96],  
        state_matrix[6]  + key[95:64],   
        state_matrix[5]  + key[63:32],   
        state_matrix[4]  + key[31:0],
        state_matrix[3]  + 32'h6b206574, 
        state_matrix[2]  + 32'h79622d32, 
        state_matrix[1]  + 32'h3320646e,  
        state_matrix[0]  + 32'h61707865
    };
    
    // Mạch báo hoàn thành Quarter Round
    assign qr_done = (fsm_state >= 4'd2 && fsm_state <= 4'd9) && (step_cnt == 4'd5);
    
endmodule
