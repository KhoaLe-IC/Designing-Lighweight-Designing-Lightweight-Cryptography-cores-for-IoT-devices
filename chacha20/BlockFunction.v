module BlockFunction(key, nonce, bc, outp, state, finish, p0, p1, p2, p3, clk);
    input [255:0] key;
    input [31:0] bc;
    input [95:0] nonce;
    input [3:0] state;
    input [3:0] p0, p1, p2, p3; 
    input clk;
    output [511:0] outp;
    output finish;
    
    reg [31:0] IRF [0:15];
    reg [4:0] SReg;
    reg [31:0] Temp [0:3];
    
    always @(posedge clk) begin
        if(state == 4'd0) begin
            IRF[0] <= 32'h61707865;
            IRF[1] <= 32'h3320646e;
            IRF[2] <= 32'h79622d32;
            IRF[3] <= 32'h6b206574;
            IRF[4] <= key[31:0];    
            IRF[5] <= key[63:32];   
            IRF[6] <= key[95:64];   
            IRF[7] <= key[127:96];  
            IRF[8] <= key[159:128]; 
            IRF[9] <= key[191:160]; 
            IRF[10]<= key[223:192]; 
            IRF[11]<= key[255:224]; 
            IRF[12]<= bc[31:0];     
            IRF[13]<= nonce[31:0];  
            IRF[14]<= nonce[63:32]; 
            IRF[15]<= nonce[95:64]; 

            SReg <= 5'd0;
        end
        else if(state >= 4'd1 && state <= 4'd8) begin
            if(SReg == 5'd0) begin
                Temp[0] <= IRF[p0];
                Temp[1] <= IRF[p1];
                Temp[2] <= IRF[p2];
                Temp[3] <= IRF[p3];
                SReg <= 5'd1;
            end
            else if(SReg[0]) begin
                Temp[0] <= addO;
                Temp[3] <= rO[0];
                SReg <= SReg << 1;
            end
            else if(SReg[1]) begin
                Temp[2] <= addO;
                Temp[1] <= rO[1];
                SReg <= SReg << 1;
            end
            else if(SReg[2]) begin
                Temp[0] <= addO;
                Temp[3] <= rO[2];
                SReg <= SReg << 1; 
            end
            else if(SReg[3]) begin
                Temp[2] <= addO;
                Temp[1] <= rO[3];
                SReg <= SReg << 1;  
            end
            else if(SReg[4]) begin
                IRF[p0] <= Temp[0];
                IRF[p1] <= Temp[1];
                IRF[p2] <= Temp[2];
                IRF[p3] <= Temp[3];
                 
                SReg <= 5'd0;  
            end
        end
    end    
    
    wire [31:0] WT [0:2];
    wire [31:0] rO [0:3];
    wire [31:0] addO, xorO;
    
    assign WT[0] = (SReg[1] || SReg[3]) ? Temp[2] : Temp[0];
    assign WT[1] = (SReg[1] || SReg[3]) ? Temp[3] : Temp[1];
    assign WT[2] = (SReg[1] || SReg[3]) ? Temp[1] : Temp[3];
    
    assign addO = WT[0] + WT[1];
    assign xorO = WT[2] ^ addO;
    
    assign rO[0] = {xorO[15:0], xorO[31:16]};
    assign rO[1] = {xorO[19:0], xorO[31:20]};
    assign rO[2] = {xorO[23:0], xorO[31:24]};
    assign rO[3] = {xorO[24:0], xorO[31:25]};
    
    assign outp = {IRF[15]+nonce[95:64], IRF[14]+nonce[63:32], IRF[13]+nonce[31:0], IRF[12]+bc[31:0],
                   IRF[11]+key[255:224], IRF[10]+key[223:192], IRF[9] +key[191:160], IRF[8] +key[159:128],
                   IRF[7] +key[127:96], IRF[6] +key[95:64], IRF[5] +key[63:32], IRF[4] +key[31:0],
                   IRF[3] +32'h6b206574, IRF[2] +32'h79622d32, IRF[1] +32'h3320646e,  IRF[0] +32'h61707865};
    
    
    assign finish = (state >= 4'd1 && state <= 4'd8) && SReg[4];
    
endmodule