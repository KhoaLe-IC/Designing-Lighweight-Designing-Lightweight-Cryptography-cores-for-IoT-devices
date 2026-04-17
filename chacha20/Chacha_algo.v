module Chacha_algo(clk, start, key, bc, nonce, plaintext, ciphertext, finish);
    input clk, start;
    input [255:0] key;
    input [31:0] bc;
    input [95:0] nonce;
    input [511:0] plaintext;
    output [511:0] ciphertext;
    output finish;

    reg [3:0] state = 4'd0;
    reg [3:0] loop = 4'd0;

    wire [511:0] keystream;
    wire [3:0] p0, p1, p2, p3;
    wire done;

    BlockFunction datapath_inst (
        .key(key), .nonce(nonce), .bc(bc),
        .outp(keystream),
        .state(state),
        .finish(done), 
        .p0(p0), .p1(p1), .p2(p2), .p3(p3),
        .clk(clk)
    );

    always @(posedge clk) begin
        if (state == 4'd0 && start) begin
            state <= 4'd1;
            loop <= 4'd0;
        end
        else if (state >= 4'd1 && state <= 4'd8) begin
            if (done) begin 
                if (state == 4'd8) begin 
                    if (loop == 4'd9) begin
                        state <= 4'd9;
                    end else begin
                        loop <= loop + 1;
                        state <= 4'd1;
                    end
                end else begin
                    state <= state + 1;
                end
            end
        end
        else if (state == 4'd9) begin
            if(!start) begin
                state <= 4'd0;
             end
        end
    end

    
    assign finish = (state == 4'd9);
    assign ciphertext = keystream ^ plaintext;

    
    wire [1:0] ptr;
    wire diag;
    assign ptr = (state == 4'd0 || state > 4'd8) ? 2'd0 : (state - 4'd1);
    assign diag = (state >= 4'd5);

    assign p0 = {2'b00, ptr};
    assign p1 = {2'b01, ptr + {1'b0, diag}};
    assign p2 = {2'b10, ptr + {diag, 1'b0}};
    assign p3 = {2'b11, ptr + ((diag) ? 2'd3 : 2'd0)};

endmodule