// TRNG_CTRL_under revision

//=================================================================
//                         +-------------------+
//  [TOP]                  |                   |           [MRAM]
//-------------------------|                   |-------------------------
// clk             (1) --->|                   | ---> clk_200ns    (1)
//                         |                   | ---> csn          (1)
//                         |                   | ---> wen          (1)
// start           (1) --->|                   |
// rstn            (1) --->|                   |
// CMD             (2) --->|                   |
// ADDR           (12) --->|                   | ---> ROW_ADDR     (7)
//                         |                   | ---> COL_ADDR     (4)
//                         |                   | 
// DETOUR_IN       (2) --->|        CTRL       | ---> DETOUR       (2)
// RP_SEL_IN       (1) --->|                   | ---> RP_SEL       (1)
// DMODE_WRITE     (6) --->|                   | ---> DMODE        (6) 
// DMODE_READ      (6) --->|                   | 
// TRNG_MODE_IN    (9) --->|                   | ---> TRNG_MODE    (9)
// TRNG_BIT        (3) --->|                   |
// DATA_TRNG       (1) --->|                   |
//                         |                   | 
//                         |                   | ---> DATA         (8)
//                         |                   | <--- OUTPUT       (8)
// MEM_IN        (144) --->|                   |
// MEM_OUT       (144) <---|                   |
// Done            (1) <---|                   |
// err             (1) <---|                   |  /// reset, start 전까지 유지
//                         |                   |
//                         +-------------------+
//
//=================================================================


module TRNG_CTRL(
    
    // -------------------------
    // Outputs to MRAM
    // -------------------------
    output     clk_200,
    output reg csn,
    output reg wen,
    output reg [6:0] ROW_ADDR,
    output reg [3:0] COL_ADDR,
    output reg [1:0] DETOUR,
    output reg RP_SEL,
    output reg [5:0] DMODE,
    output reg [7:0] DATA,
    output reg [8:0] TRNG_MODE,
    
    // -------------------------
    // Outputs to TOP
    // -------------------------
    output reg [143:0] MEM_OUT,
    output reg err,            // used only for Write and Read when invalid addr
    output reg Done,

    // -------------------------
    // Inputs from TOP
    // -------------------------
    input         clk,
    input         rstn,
    input         start,
    input  [1:0]  CMD,
    input  [11:0] ADDR,         // will be split to ROW_ADDR[6:0], COL_ADDR[3:0]
    input  [1:0]  DETOUR_IN,
    input         RP_SEL_IN,
    input  [5:0]  DMODE_WRITE,
    input  [5:0]  DMODE_READ,
    input  [2:0]  TRNG_BIT,
    input  [143:0] MEM_IN,
    input  [8:0]  TRNG_MODE_IN,
    input         DATA_TRNG,

    // -------------------------
    // Inputs from MRAM
    // -------------------------
    input  [7:0]  OUTPUT
);


localparam RNG     = 2'b00;
localparam SET_VAR = 2'b01;
localparam WRITE   = 2'b10;
localparam READ    = 2'b11;

reg RNG_working;
reg SET_VAR_working;
reg WRITE_working;
reg READ_working;

reg RNG_DONE;
reg READ_DONE;
reg WRITE_DONE;
reg SET_VAR_DONE;

reg [1:0] DETOUR_temp;
reg RP_SEL_temp;
reg [5:0] DMODE_READ_temp;
reg [5:0] DMODE_WRITE_temp;
reg [8:0] TRNG_MODE_temp;
reg DATA_temp;

reg clkgen_rstn;
reg cnt_rstn;
wire [4:0] cnt;

reg [10:0] WR_ADDR;    // input ADDR x 18 + cnt
reg [4:0] WR_cnt;

reg [143:0] MEM_OUT_BUF;

always @(posedge clk) begin
    if (!rstn) begin
        // resetting output signals 
        csn <= 1'b1;
        wen <= 1'b1;
        DETOUR <= 2'd0;
        RP_SEL <= 1'd0;
        DMODE <= 6'd0;
        DATA <= 8'd0;
        TRNG_MODE <= 9'd0;
        MEM_OUT <= 144'd0;
        MEM_OUT_BUF <= 144'd0;

        MEM_OUT <= 144'd0;
        err <= 1'd0;

        // resetting clk/counter reset signals
        clkgen_rstn <= 1'b0;
        cnt_rstn <= 1'b0;

        // resetting working/done signals
        RNG_working <= 1'b0;
        SET_VAR_working <= 1'b0;
        WRITE_working <= 1'b0;
        READ_working <= 1'b0;

        RNG_DONE <= 1'b0;
        READ_DONE <= 1'b0;
        WRITE_DONE <= 1'b0;
        SET_VAR_DONE <= 1'b0;

        // resetting operation signals
        // for write/read
        WR_ADDR <= 11'd0;
        WR_cnt <= 5'd0;

        DETOUR_temp <= 2'd0;
        RP_SEL_temp <= 1'd0;
        DMODE_READ_temp <= 6'd0;
        DMODE_WRITE_temp <= 6'd0;
        TRNG_MODE_temp <= 9'd0;
        DATA_temp <= 1'd0;

    end else begin
        case (CMD)
            // RNG: begin
            //     if (start) begin

            //     end
            //     else begin

            //     end
            // end
            SET_VAR: begin
                if (start) begin
                    // starting SET_VAR
                    if (!SET_VAR_working) begin
                        DETOUR_temp <= DETOUR_IN;
                        RP_SEL_temp <= RP_SEL_IN;
                        DMODE_READ_temp <= DMODE_READ;
                        DMODE_WRITE_temp <= DMODE_WRITE;
                        TRNG_MODE_temp <= TRNG_MODE_IN;
                        DATA_temp <= DATA_TRNG;

                        SET_VAR_working <= 1'b1;
                        SET_VAR_DONE <= 1'b0;
                    end
                    // resetting SET_VAR ctrl signals
                    else begin
                        DETOUR_temp <= DETOUR_temp;
                        RP_SEL_temp <= RP_SEL_temp;
                        DMODE_READ_temp <= DMODE_READ_temp;
                        DMODE_WRITE_temp <= DMODE_WRITE_temp;
                        TRNG_MODE_temp <= TRNG_MODE_temp;
                        DATA_temp <= DATA_temp;

                        SET_VAR_working <= 1'b0;
                        SET_VAR_DONE <= 1'b1;
                    end
                end else begin
                    DETOUR_temp <= DETOUR_temp;
                    RP_SEL_temp <= RP_SEL_temp;
                    DMODE_READ_temp <= DMODE_READ_temp;
                    DMODE_WRITE_temp <= DMODE_WRITE_temp;
                    TRNG_MODE_temp <= TRNG_MODE_temp;

                    SET_VAR_working <= 1'b0;
                    SET_VAR_DONE <= 1'b0;
                end
            end
            WRITE: begin
                if (start) begin
                    // the first cycle after start signal
                    if (!WRITE_working) begin
                        // Error : when improper address is given
                        if (ADDR > 113) begin
                            clkgen_rstn <= 1'b0;
                            cnt_rstn <= 1'b0;      

                            csn <= 1'b1;
                            wen <= 1'b1;

                            WR_ADDR <= 11'd0;
                            DETOUR <= 2'b00; 
                            RP_SEL <= 1'b0; 
                            DMODE <= 6'd0; 
                            DATA <= 8'd0; 
                            // TRNG_MODE <= TRNG_MODE_temp;

                            WRITE_working <= 1'b1;
                            WRITE_DONE <= 1'b1;
                            err <= 1'b1;
                            WR_cnt <= 5'd0;
                        end
                        // normal operation
                        else begin
                            clkgen_rstn <= 1'b1;
                            cnt_rstn <= 1'b1;                        

                            csn <= 1'b1;
                            wen <= 1'b1;

                            WR_ADDR <= WR_ADDR;
                            DETOUR <= DETOUR; 
                            RP_SEL <= RP_SEL; 
                            DMODE <= DMODE; 
                            DATA <= DATA; 
                            // TRNG_MODE <= TRNG_MODE_temp;

                            WRITE_working <= 1'b1;
                            WRITE_DONE <= 1'b0;
                            err <= 1'b0;
                            WR_cnt <= 5'd1;
                        end
                    end
                    else begin
                        if (err) begin
                            clkgen_rstn <= 1'b0;
                            cnt_rstn <= 1'b0;      

                            csn <= 1'b1;
                            wen <= 1'b1;

                            WR_ADDR <= 11'd0;
                            DETOUR <= 2'b00; 
                            RP_SEL <= 1'b0; 
                            DMODE <= 6'd0; 
                            DATA <= 8'd0; 
                            // TRNG_MODE <= TRNG_MODE_temp;

                            WRITE_working <= 1'b0;
                            WRITE_DONE <= 1'b0;
                            err <= 1'b1;
                            WR_cnt <= 5'd0;
                        end
                        else begin
                            clkgen_rstn <= 1'b1;
                            cnt_rstn <= 1'b1;                        

                            csn <= 1'b0;
                            wen <= 1'b0;

                            WR_ADDR <= ADDR[6:0] * 18;
                            DETOUR <= 2'b00; 
                            RP_SEL <= RP_SEL_temp; 
                            DMODE <= 6'b11_1111; 
                            DATA <= MEM_IN[7:0]; 
                            // TRNG_MODE <= TRNG_MODE_temp;

                            WRITE_working <= 1'b1;
                            WRITE_DONE <= 1'b0;
                            err <= 1'b0;
                            WR_cnt <= 5'd1;
                        end
                    end
                end else begin
                    // 18 iterations
                    if (WRITE_working) begin
                        // WRITE
                        if ((WR_cnt < 5'd18) && (cnt == 5'd20)) begin
                            clkgen_rstn <= 1'b1;
                            cnt_rstn <= 1'b1;       

                            csn <= 1'b0;
                            wen <= 1'b0;

                            WR_ADDR <= WR_ADDR+ 1;
                            DETOUR <= 2'b00; 
                            RP_SEL <= RP_SEL_temp; 
                            DMODE <= 6'b11_1111; 
                            // DATA <= 8'd0; 
                            // TRNG_MODE <= TRNG_MODE_temp;

                            WRITE_working <= 1'b1;
                            WRITE_DONE <= 1'b0;
                            err <= 1'b0;
                            WR_cnt <= WR_cnt + 1;

                            case (WR_cnt)
                                5'd1 :  DATA <= MEM_IN[15 : 8];
                                5'd2 :  DATA <= MEM_IN[23 : 16];
                                5'd3 :  DATA <= MEM_IN[31 : 24];
                                5'd4 :  DATA <= MEM_IN[39 : 32];
                                5'd5 :  DATA <= MEM_IN[47 : 40];
                                5'd6 :  DATA <= MEM_IN[55 : 48];
                                5'd7 :  DATA <= MEM_IN[63 : 56];
                                5'd8 :  DATA <= MEM_IN[71 : 64];
                                5'd9 :  DATA <= MEM_IN[79 : 72];
                                5'd10:  DATA <= MEM_IN[87 : 80];
                                5'd11:  DATA <= MEM_IN[95 : 88];
                                5'd12:  DATA <= MEM_IN[103: 96];
                                5'd13:  DATA <= MEM_IN[111:104];
                                5'd14:  DATA <= MEM_IN[119:112];
                                5'd15:  DATA <= MEM_IN[127:120];
                                5'd16:  DATA <= MEM_IN[135:128];
                                5'd17:  DATA <= MEM_IN[143:136];
                                default: DATA <= 8'h00;
                            endcase
                        end
                        else if (WR_cnt == 5'd18 && (cnt == 5'd20)) begin
                            clkgen_rstn <= 1'b1;
                            cnt_rstn <= 1'b1;       

                            csn <= 1'b1;
                            wen <= 1'b1;

                            WR_ADDR <= WR_ADDR;
                            DETOUR <= 2'b00; 
                            RP_SEL <= RP_SEL_temp; 
                            DMODE <= 6'b11_1111; 
                            // DATA <= 8'd0; 
                            // TRNG_MODE <= TRNG_MODE_temp;

                            WRITE_working <= 1'b1;
                            WRITE_DONE <= 1'b0;
                            err <= 1'b0;
                            WR_cnt <= WR_cnt + 1;
                        end
                        // post state of write operation
                        // resetting every signals after two cycle of done signal
                        else if (WR_cnt == 5'd19) begin
                            if (cnt == 5'd2) begin
                                clkgen_rstn <= 1'b1;
                                cnt_rstn <= 1'b1;                        
                    
                                csn <= 1'b1;
                                wen <= 1'b1;

                                WR_ADDR <= WR_ADDR;
                                DETOUR <= 2'b00; 
                                RP_SEL <= RP_SEL_temp; 
                                DMODE <= 6'b11_1111; 
                                DATA <= 8'd0; 
                                // TRNG_MODE <= TRNG_MODE_temp;

                                WRITE_working <= 1'b1;
                                WRITE_DONE <= 1'b1;
                                err <= 1'b0;
                                // WR_cnt <= WR_cnt + 1;  
                            end
                            else if (cnt == 5'd3) begin
                                clkgen_rstn <= 1'b0;
                                cnt_rstn <= 1'b0;                        
                    
                                csn <= 1'b1;
                                wen <= 1'b1;

                                WR_ADDR <= 11'd0;
                                DETOUR <= 2'b00; 
                                RP_SEL <= 1'd0; 
                                DMODE <= 6'd0; 
                                DATA <= 8'd0; 
                                // TRNG_MODE <= TRNG_MODE_temp;

                                WRITE_working <= 1'b0;
                                WRITE_DONE <= 1'b0;
                                err <= 1'b0;
                                WR_cnt <= 5'd0;  
                            end
                        end
                        // Retaining signals
                        else begin
                            clkgen_rstn <= clkgen_rstn;
                            cnt_rstn <= cnt_rstn;                        
                    
                            csn <= csn;
                            wen <= wen;

                            WR_ADDR <= WR_ADDR;
                            DETOUR <= DETOUR; 
                            RP_SEL <= RP_SEL; 
                            DMODE <= DMODE; 
                            DATA <= DATA; 
                            // TRNG_MODE <= TRNG_MODE_temp;

                            WRITE_working <= WRITE_working;
                            WRITE_DONE <= WRITE_DONE;
                            err <= err;
                            WR_cnt <= WR_cnt;                            
                        end
                    end
                    else begin
                        clkgen_rstn <= clkgen_rstn;
                        cnt_rstn <= cnt_rstn;                        
                    
                        csn <= csn;
                        wen <= wen;

                        WR_ADDR <= WR_ADDR;
                        DETOUR <= DETOUR; 
                        RP_SEL <= RP_SEL; 
                        DMODE <= DMODE; 
                        DATA <= DATA; 
                        // TRNG_MODE <= TRNG_MODE_temp;

                        WRITE_working <= WRITE_working;
                        WRITE_DONE <= WRITE_DONE;
                        err <= err;
                        WR_cnt <= WR_cnt;                                
                    end
                end
            end
            READ: begin
                if (start) begin
                    // the first cycle after start signal
                    if (!READ_working) begin
                        // Error : when improper address is given
                        if (ADDR > 113) begin
                            clkgen_rstn <= 1'b0;
                            cnt_rstn <= 1'b0;      

                            csn <= 1'b1;
                            wen <= 1'b1;

                            WR_ADDR <= 11'd0;
                            DETOUR <= 2'b00; 
                            RP_SEL <= 1'b0; 
                            DMODE <= 6'd0; 
                            DATA <= 8'd0; 
                            // TRNG_MODE <= TRNG_MODE_temp;
                            MEM_OUT <= 144'd0;
                            MEM_OUT_BUF <= 144'd0;

                            READ_working <= 1'b1;
                            READ_DONE <= 1'b1;
                            err <= 1'b1;
                            WR_cnt <= 5'd0;
                        end
                        // normal operation
                        else begin
                            clkgen_rstn <= 1'b1;
                            cnt_rstn <= 1'b1;                        

                            csn <= 1'b0;
                            wen <= 1'b1;

                            WR_ADDR <= ADDR[6:0] * 18;
                            DETOUR <= 2'b00; 
                            RP_SEL <= RP_SEL_temp; 
                            DMODE <= DMODE_READ_temp;
                            DATA <= 8'd0; 
                            // TRNG_MODE <= TRNG_MODE_temp;
                            MEM_OUT <= 144'd0;
                            MEM_OUT_BUF <= 144'd0;

                            READ_working <= 1'b1;
                            READ_DONE <= 1'b0;
                            err <= 1'b0;
                            WR_cnt <= 5'd1;
                        end
                    end
                    else begin
                        if (err) begin
                            clkgen_rstn <= 1'b0;
                            cnt_rstn <= 1'b0;      

                            csn <= 1'b1;
                            wen <= 1'b1;

                            WR_ADDR <= 11'd0;
                            DETOUR <= 2'b00; 
                            RP_SEL <= 1'b0; 
                            DMODE <= 6'd0; 
                            DATA <= 8'd0; 
                            // TRNG_MODE <= TRNG_MODE_temp;
                            MEM_OUT <= 144'd0;
                            MEM_OUT_BUF <= 144'd0;

                            READ_working <= 1'b0;
                            READ_DONE <= 1'b0;
                            err <= 1'b1;
                            WR_cnt <= 5'd0;
                        end
                        else begin
                            clkgen_rstn <= 1'b1;
                            cnt_rstn <= 1'b1;                        

                            csn <= 1'b0;
                            wen <= 1'b1;

                            WR_ADDR <= WR_ADDR;
                            DETOUR <= 2'b00; 
                            RP_SEL <= RP_SEL_temp; 
                            DMODE <= DMODE_READ_temp; 
                            DATA <= 8'd0; 
                            // TRNG_MODE <= TRNG_MODE_temp;
                            MEM_OUT <= 144'd0;
                            MEM_OUT_BUF <= 144'd0;

                            READ_working <= 1'b1;
                            READ_DONE <= 1'b0;
                            err <= 1'b0;
                            WR_cnt <= 5'd1;
                        end
                    end
                end else begin
                    // 18 iterations
                    if (READ_working) begin
                        // READ
                        if (WR_cnt < 5'd18 && cnt == 5'd20) begin
                            clkgen_rstn <= 1'b1;
                            cnt_rstn <= 1'b1;                        

                            csn <= 1'b0;
                            wen <= 1'b1;

                            WR_ADDR <= WR_ADDR+ 1;
                            DETOUR <= 2'b00; 
                            RP_SEL <= RP_SEL_temp; 
                            DMODE <= DMODE_READ_temp;
                            DATA <= 8'd0; 
                            // TRNG_MODE <= TRNG_MODE_temp;
                            MEM_OUT <= MEM_OUT;
                            MEM_OUT_BUF <= MEM_OUT_BUF;

                            READ_working <= 1'b1;
                            READ_DONE <= 1'b0;
                            err <= 1'b0;
                            WR_cnt <= WR_cnt + 1;
                        end
                        // end of the last reading 
                        else if (WR_cnt == 5'd18 && cnt == 5'd20) begin
                            clkgen_rstn <= 1'b1;
                            cnt_rstn <= 1'b1;                        

                            csn <= 1'b1;
                            wen <= 1'b1;

                            WR_ADDR <= 11'd0;
                            DETOUR <= 2'b00; 
                            RP_SEL <= RP_SEL_temp; 
                            DMODE <= DMODE_READ_temp;
                            DATA <= 8'd0; 
                            // TRNG_MODE <= TRNG_MODE_temp;
                            MEM_OUT <= MEM_OUT;
                            MEM_OUT_BUF <= MEM_OUT_BUF;

                            READ_working <= 1'b1;
                            READ_DONE <= 1'b0;
                            err <= 1'b0;
                            WR_cnt <= WR_cnt + 1;                            
                        end
                        // output sensing
                        else if ((WR_cnt != 5'd1) && (WR_cnt < 5'd19) && (cnt == 5'd2)) begin
                            clkgen_rstn <= 1'b1;
                            cnt_rstn <= 1'b1;                        

                            csn <= 1'b0;
                            wen <= 1'b1;

                            WR_ADDR <= WR_ADDR;
                            DETOUR <= 2'b00; 
                            RP_SEL <= RP_SEL_temp; 
                            DMODE <= DMODE_READ_temp; 
                            DATA <= 8'd0; 
                            // TRNG_MODE <= TRNG_MODE_temp;
                            MEM_OUT <= MEM_OUT;
                            // MEM_OUT_BUF <= MEM_OUT_BUF;  // described below

                            READ_working <= 1'b1;
                            READ_DONE <= 1'b0;
                            err <= 1'b0;
                            WR_cnt <= WR_cnt;

                            case (WR_cnt)
                                5'd2 : begin
                                    MEM_OUT_BUF[143:8]   <= MEM_OUT_BUF[143:8];
                                    MEM_OUT_BUF[7:0]     <= OUTPUT;
                                end
                                5'd3 : begin
                                    MEM_OUT_BUF[143:16]  <= MEM_OUT_BUF[143:16];
                                    MEM_OUT_BUF[15:8]    <= OUTPUT;
                                    MEM_OUT_BUF[7:0]     <= MEM_OUT_BUF[7:0];
                                end
                                5'd4 : begin
                                    MEM_OUT_BUF[143:24]  <= MEM_OUT_BUF[143:24];
                                    MEM_OUT_BUF[23:16]   <= OUTPUT;
                                    MEM_OUT_BUF[15:0]    <= MEM_OUT_BUF[15:0];
                                end
                                5'd5 : begin
                                    MEM_OUT_BUF[143:32]  <= MEM_OUT_BUF[143:32];
                                    MEM_OUT_BUF[31:24]   <= OUTPUT;
                                    MEM_OUT_BUF[23:0]    <= MEM_OUT_BUF[23:0];
                                end
                                5'd6 : begin
                                    MEM_OUT_BUF[143:40]  <= MEM_OUT_BUF[143:40];
                                    MEM_OUT_BUF[39:32]   <= OUTPUT;
                                    MEM_OUT_BUF[31:0]    <= MEM_OUT_BUF[31:0];
                                end
                                5'd7 : begin
                                    MEM_OUT_BUF[143:48]  <= MEM_OUT_BUF[143:48];
                                    MEM_OUT_BUF[47:40]   <= OUTPUT;
                                    MEM_OUT_BUF[39:0]    <= MEM_OUT_BUF[39:0];
                                end
                                5'd8 : begin
                                    MEM_OUT_BUF[143:56]  <= MEM_OUT_BUF[143:56];
                                    MEM_OUT_BUF[55:48]   <= OUTPUT;
                                    MEM_OUT_BUF[47:0]    <= MEM_OUT_BUF[47:0];
                                end
                                5'd9 : begin
                                    MEM_OUT_BUF[143:64]  <= MEM_OUT_BUF[143:64];
                                    MEM_OUT_BUF[63:56]   <= OUTPUT;
                                    MEM_OUT_BUF[55:0]    <= MEM_OUT_BUF[55:0];
                                end
                                5'd10: begin
                                    MEM_OUT_BUF[143:72]  <= MEM_OUT_BUF[143:72];
                                    MEM_OUT_BUF[71:64]   <= OUTPUT;
                                    MEM_OUT_BUF[63:0]    <= MEM_OUT_BUF[63:0];
                                end
                                5'd11: begin
                                    MEM_OUT_BUF[143:80]  <= MEM_OUT_BUF[143:80];
                                    MEM_OUT_BUF[79:72]   <= OUTPUT;
                                    MEM_OUT_BUF[71:0]    <= MEM_OUT_BUF[71:0];
                                end
                                5'd12: begin
                                    MEM_OUT_BUF[143:88]  <= MEM_OUT_BUF[143:88];
                                    MEM_OUT_BUF[87:80]   <= OUTPUT;
                                    MEM_OUT_BUF[79:0]    <= MEM_OUT_BUF[79:0];
                                end
                                5'd13: begin
                                    MEM_OUT_BUF[143:96]  <= MEM_OUT_BUF[143:96];
                                    MEM_OUT_BUF[95:88]   <= OUTPUT;
                                    MEM_OUT_BUF[87:0]    <= MEM_OUT_BUF[87:0];
                                end
                                5'd14: begin
                                    MEM_OUT_BUF[143:104] <= MEM_OUT_BUF[143:104];
                                    MEM_OUT_BUF[103:96]  <= OUTPUT;
                                    MEM_OUT_BUF[95:0]    <= MEM_OUT_BUF[95:0];
                                end
                                5'd15: begin
                                    MEM_OUT_BUF[143:112] <= MEM_OUT_BUF[143:112];
                                    MEM_OUT_BUF[111:104] <= OUTPUT;
                                    MEM_OUT_BUF[103:0]   <= MEM_OUT_BUF[103:0];
                                end
                                5'd16: begin
                                    MEM_OUT_BUF[143:120] <= MEM_OUT_BUF[143:120];
                                    MEM_OUT_BUF[119:112] <= OUTPUT;
                                    MEM_OUT_BUF[111:0]   <= MEM_OUT_BUF[111:0];
                                end
                                5'd17: begin
                                    MEM_OUT_BUF[143:128] <= MEM_OUT_BUF[143:128];
                                    MEM_OUT_BUF[127:120] <= OUTPUT;
                                    MEM_OUT_BUF[119:0]   <= MEM_OUT_BUF[119:0];
                                end
                                5'd18: begin
                                    MEM_OUT_BUF[143:136] <= MEM_OUT_BUF[143:136];
                                    MEM_OUT_BUF[135:128] <= OUTPUT;
                                    MEM_OUT_BUF[127:0]   <= MEM_OUT_BUF[127:0];
                                end
                                default: MEM_OUT_BUF <= MEM_OUT_BUF;
                            endcase

                        end
                        // post state of read operation
                        // resetting every signals after two cycle of done signal
                        else if (WR_cnt == 5'd19) begin
                            if (cnt == 5'd2) begin
                                clkgen_rstn <= 1'b1;
                                cnt_rstn <= 1'b1;                        

                                csn <= 1'b1;
                                wen <= 1'b1;

                                WR_ADDR <= 11'd0;
                                DETOUR <= 2'b00; 
                                RP_SEL <= RP_SEL_temp; 
                                DMODE <= DMODE_READ_temp;
                                DATA <= 8'd0; 
                                // TRNG_MODE <= TRNG_MODE_temp;
                                MEM_OUT <= {OUTPUT, MEM_OUT_BUF[135:0]};
                                MEM_OUT_BUF <= MEM_OUT_BUF;                                

                                READ_working <= 1'b1;
                                READ_DONE <= 1'b1;
                                err <= 1'b0;
                                // WR_cnt <= WR_cnt + 1;  
                            end
                            else if (cnt == 5'd3) begin
                                clkgen_rstn <= 1'b0;
                                cnt_rstn <= 1'b0;                        

                                csn <= 1'b1;
                                wen <= 1'b1;

                                WR_ADDR <= 11'd0;
                                DETOUR <= 2'b00; 
                                RP_SEL <= RP_SEL_temp; 
                                DMODE <= DMODE_READ_temp;
                                DATA <= 8'd0; 
                                // TRNG_MODE <= TRNG_MODE_temp;
                                MEM_OUT <= MEM_OUT;
                                MEM_OUT_BUF <= 144'd0;                                

                                READ_working <= 1'b1;
                                READ_DONE <= 1'b0;
                                err <= 1'b0;
                                // WR_cnt <= WR_cnt + 1;  
                            end
                            else if (cnt == 5'd4) begin
                                clkgen_rstn <= 1'b0;
                                cnt_rstn <= 1'b0;                        

                                csn <= 1'b1;
                                wen <= 1'b1;

                                WR_ADDR <= 11'd0;
                                DETOUR <= 2'b00; 
                                RP_SEL <= RP_SEL_temp; 
                                DMODE <= DMODE_READ_temp;
                                DATA <= 8'd0; 
                                // TRNG_MODE <= TRNG_MODE_temp;
                                MEM_OUT <= 144'd0;
                                MEM_OUT_BUF <= 144'd0;                                

                                READ_working <= 1'b0;
                                READ_DONE <= 1'b0;
                                err <= 1'b0;
                                // WR_cnt <= WR_cnt + 1;  
                            end
                            else begin
                                clkgen_rstn <= clkgen_rstn;
                                cnt_rstn <= cnt_rstn;                        

                                csn <= csn;
                                wen <= wen;

                                WR_ADDR <= WR_ADDR;
                                DETOUR <= DETOUR; 
                                RP_SEL <= RP_SEL; 
                                DMODE <= DMODE; 
                                DATA <= DATA; 
                                // TRNG_MODE <= TRNG_MODE_temp;
                                MEM_OUT <= MEM_OUT;
                                MEM_OUT_BUF <= MEM_OUT_BUF;

                                READ_working <= READ_working;
                                READ_DONE <= READ_DONE;
                                err <= err;
                                WR_cnt <= WR_cnt;                                  
                            end                            
                        end
                        // Retaining signals
                        else begin
                            clkgen_rstn <= clkgen_rstn;
                            cnt_rstn <= cnt_rstn;                        

                            csn <= csn;
                            wen <= wen;

                            WR_ADDR <= WR_ADDR;
                            DETOUR <= DETOUR; 
                            RP_SEL <= RP_SEL; 
                            DMODE <= DMODE; 
                            DATA <= DATA; 
                            // TRNG_MODE <= TRNG_MODE_temp;
                            MEM_OUT <= 144'd0;
                            MEM_OUT_BUF <= MEM_OUT_BUF;

                            READ_working <= READ_working;
                            READ_DONE <= READ_DONE;
                            err <= err;
                            WR_cnt <= WR_cnt;                            
                        end
                    end
                    else begin
                        clkgen_rstn <= clkgen_rstn;
                        cnt_rstn <= cnt_rstn;                        

                        csn <= csn;
                        wen <= wen;

                        WR_ADDR <= WR_ADDR;
                        DETOUR <= DETOUR; 
                        RP_SEL <= RP_SEL; 
                        DMODE <= DMODE; 
                        DATA <= DATA; 
                        // TRNG_MODE <= TRNG_MODE_temp;

                        READ_working <= READ_working;
                        READ_DONE <= READ_DONE;
                        err <= err;
                        WR_cnt <= WR_cnt;                                
                    end
                end
            end
        endcase
    end
end

clk_generator clk_gen(clk_200, clk, clkgen_rstn);

count_20 counter0(cnt, clk, cnt_rstn);

always @(*) begin
    // combined DONE signal
    Done = SET_VAR_DONE || WRITE_DONE || READ_DONE || RNG_DONE;

    case (CMD)
        // RNG: begin
        //     ROW_ADDR <= WR_ADDR[10:4];
        //     COL_ADDR <= WR_ADDR[3:0];        //! TODO 채우기. RNG_ADDR?
        // end
        SET_VAR:begin
            ROW_ADDR <= ADDR[10:4];
            COL_ADDR <= ADDR[3:0];
        end
        WRITE:begin
            ROW_ADDR <= WR_ADDR[10:4];
            COL_ADDR <= WR_ADDR[3:0];
        end
        READ:begin
            ROW_ADDR <= WR_ADDR[10:4];
            COL_ADDR <= WR_ADDR[3:0];
        end
        default: begin
            ROW_ADDR <= ADDR[10:4];
            COL_ADDR <= ADDR[3:0];
        end
    endcase
end

endmodule

module count_20(
    output reg [4:0] q,
    input clk,
    input rstn
);

    always @(posedge clk) begin
        if (!rstn) begin
            q <= 5'd0;
        end else begin
            if (q == 5'd20) begin
                q <= 5'd1; 
            end else begin
                q <= q + 1; 
            end
        end
    end

endmodule

// clock generator
module clk_generator(
    output reg clk_200,
    input clk,
    input rstn
);

    reg [4:0] cnt;

    always @(posedge clk) begin
        if (!rstn) begin
            clk_200 <= 1'b0;
            cnt <= 5'd0;
        end else begin
            if (cnt == 5'd1) begin
                clk_200 <= ~clk_200;
                cnt <= cnt + 1;
            end 
            else if (cnt == 5'd11) begin
                clk_200 <= ~clk_200;
                cnt <= cnt + 1;                
            end
            else if (cnt == 5'd20) begin
                clk_200 <= clk_200;
                cnt <= 5'd1;
            end
            else begin
                clk_200 <= clk_200;
                cnt <= cnt + 1;
            end
        end
    end

endmodule
