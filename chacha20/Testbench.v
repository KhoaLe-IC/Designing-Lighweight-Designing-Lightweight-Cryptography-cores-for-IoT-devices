`timescale 1ns / 1ps

module Testbench();

    reg clk;
    reg start; 
    reg [255:0] key;
    reg [31:0] bc;
    reg [95:0] nonce;
    reg [511:0] plaintext;
    
    wire [511:0] ciphertext;
    wire finish;

    Chacha_algo chacha (
        .clk(clk), 
        .start(start),
        .key(key), 
        .bc(bc), 
        .nonce(nonce), 
        .plaintext(plaintext), 
        .ciphertext(ciphertext), 
        .finish(finish)
    );

    always #5 clk = ~clk;

    initial begin
        
        clk = 0;
        start = 0;
        //Test vector 3:
        key = {32'hc0757020, 32'hbc5cca9d, 32'h09802b40, 32'hc1173947, 32'hf0b5f604, 32'h868833f3, 32'h8ad355eb, 32'ha540921c};
        nonce = {32'h02000000, 32'h00000000, 32'h00000000};
        bc = 32'h0000002a;
        plaintext = {32'h77206568, 32'h74206e69, 32'h20656c62, 32'h6d696720, 32'h646e6120, 32'h65727967, 32'h20646944, 32'h0a736576, 32'h6f742079, 32'h6874696c, 32'h73206568, 32'h7420646e, 32'h61202c67, 32'h696c6c69, 32'h72622073, 32'h61775427};
        
        /*Test vector 1:
        key = 256'd0;
        nonce = 96'd0;
        bc = 32'd0;
        plaintext = 512'd0;
        */
        /*Test vector 2:
        key = {32'h01000000, 32'h00000000, 32'h00000000, 32'h00000000, 
               32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000};
        nonce = {32'h02000000, 32'h00000000, 32'h00000000};
        bc = 32'h00000001;
        plaintext = {
            32'h696c6275, 32'h7020726f, 32'h6620726f, 32'h74756269,
            32'h72746e6f, 32'h43206568, 32'h74207962, 32'h20646564,
            32'h6e65746e, 32'h69204654, 32'h45492065, 32'h6874206f,
            32'h74206e6f, 32'h69737369, 32'h6d627573, 32'h20796e41
        };
        */
        
        #20; 
        start = 1; 
        wait(finish == 1'b1); // ??i cho ??n khi m?ch ch?y t?i state 9
        
        #20;
        $stop; 
    end

endmodule