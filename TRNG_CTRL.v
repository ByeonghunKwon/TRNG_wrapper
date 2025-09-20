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
// DATA_IN         (8) --->|                   | ---> DATA         (8)
// TRNG_MODE       (9) --->|                   | ---> TRNG_MODE    (9)
// TRNG_BIT        (3) --->|                   |
//                         |                   | 
// MEM_IN        (144) --->|                   |
//                         |                   | <--- OUTPUT       (8)
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
    output reg clk_200ns,
    output reg csn,
    output reg wen,
    output reg [6:0]ROW_ADDR,
    output reg [3:0]COL_ADDR,
    output reg [1:0]DETOUR,
    output reg RP_SEL,
    output reg [5:0]DMODE,
    output reg [7:0]DATA,
    output reg [8:0]TRNG_MODE
    
    // -------------------------
    // Outputs to TOP
    // -------------------------
    output reg [143:0] DATA_OUT,
    output reg err,            // used only for Write and Read when invalid addr
    output Done,

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
    input  [7:0]  DATA_IN,
    input  [2:0]  TRNG_BIT,
    input  [143:0] MEM_IN,

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

reg DETOUR_temp;
reg RP_SEL_temp;
reg DMODE_READ_temp;
reg DMODE_WRITE_temp;
reg [8:0] TRNG_MODE_temp;

reg clkgen_rstn;
reg cnt_rstn;
reg [4:0] cnt;

reg [10:0] WR_ADDR;    // input ADDR x 18 + cnt
reg [3:0] WR_cnt;

always @(posedge clk) begin
    if (!rstn) begin
        // resetting output signals 
        csn <= n'd1;
        wen <= n'd1;
        ROW_ADDR <= 8'd0;
        COL_ADDR <= 4'd0;
        DETOUR <= 2'd0;
        RP_SEL <= 1'd0;
        DMODE <= 6'd0;
        DATA <= 8'd0;
        TRNG_MODE <= 9'd0;

        DATA_OUT <= 144'd0;
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
        WR_cnt <= 4'd0;

    end else begin
        case (CMD)
            // RNG: begin

            // end
            SET_VAR: begin

                clkgen_rstn <= 1'b0;
                cnt_rstn <= 1'b0;

                if (start) begin
                    // starting SET_VAR
                    if (!SET_VAR_working) begin
                        DETOUR_temp <= DETOUR;
                        RP_SEL_temp <= RP_SEL;
                        DMODE_READ_temp <= DMODE_READ;
                        DMODE_WRITE_temp <= DMODE_WRITE;
                        TRNG_MODE_temp <= TRNG_MODE;

                        SET_VAR_working <= 1'b1;
                        SET_VAR_DONE <= 1'b1;
                    end
                    // resetting SET_VAR ctrl signals
                    else begin
                        DETOUR_temp <= DETOUR_temp;
                        RP_SEL_temp <= RP_SEL_temp;
                        DMODE_READ_temp <= DMODE_READ_temp;
                        DMODE_WRITE_temp <= DMODE_WRITE_temp;
                        TRNG_MODE_temp <= TRNG_MODE_temp;

                        SET_VAR_working <= 1'b0;
                        SET_VAR_DONE <= 1'b0;
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

                            WR_ADDR <= 11'd0;
                            DETOUR <= 2'b00; 
                            RP_SEL <= 1'b0; 
                            DMODE <= 6'd0; 
                            DATA <= 8'd0; 
                            // TRNG_MODE <= TRNG_MODE_temp;

                            WRITE_working <= 1'b1;
                            WRITE_DONE <= 1'b1;
                            err <= 1'b1;
                            WR_cnt <= 4'd0;
                        end
                        // normal operation
                        else begin
                            clkgen_rstn <= 1'b0;
                            cnt_rstn <= 1'b1;                        

                            WR_ADDR <= ADDR[6:0] * 18;
                            DETOUR <= 2'b00; 
                            RP_SEL <= RP_SEL_temp; 
                            DMODE <= 6'b11_1111; 
                            DATA <= DATA_temp; 
                            // TRNG_MODE <= TRNG_MODE_temp;

                            WRITE_working <= 1'b1;
                            WRITE_DONE <= 1'b0;
                            err <= 1'b0;
                            WR_cnt <= 4'd1;
                        end
                    end
                    else begin
                        if (err) begin
                            clkgen_rstn <= 1'b0;
                            cnt_rstn <= 1'b0;      

                            WR_ADDR <= 11'd0;
                            DETOUR <= 2'b00; 
                            RP_SEL <= 1'b0; 
                            DMODE <= 6'd0; 
                            DATA <= 8'd0; 
                            // TRNG_MODE <= TRNG_MODE_temp;

                            WRITE_working <= 1'b0;
                            WRITE_DONE <= 1'b0;
                            err <= 1'b1;
                            WR_cnt <= 4'd0;
                        end
                        else begin
                            clkgen_rstn <= 1'b1;
                            cnt_rstn <= 1'b1;                        

                            WR_ADDR <= WR_ADDR;
                            DETOUR <= 2'b00; 
                            RP_SEL <= RP_SEL_temp; 
                            DMODE <= 6'b11_1111; 
                            DATA <= DATA_temp; 
                            // TRNG_MODE <= TRNG_MODE_temp;

                            WRITE_working <= 1'b1;
                            WRITE_DONE <= 1'b0;
                            err <= 1'b0;
                            WR_cnt <= 4'd1;
                        end
                    end
                end else begin
                    // 18 iterations
                    if (WRITE_working) begin
                        // WRITE
                        if (WR_cnt < 4'd18 && cnt == 5'd20) begin
                            clkgen_rstn <= 1'b1;
                            cnt_rstn <= 1'b1;                        

                            WR_ADDR <= WR_ADDR+ 1;
                            DETOUR <= 2'b00; 
                            RP_SEL <= RP_SEL_temp; 
                            DMODE <= 6'b11_1111; 
                            DATA <= DATA_temp; 
                            // TRNG_MODE <= TRNG_MODE_temp;

                            WRITE_working <= 1'b1;
                            WRITE_DONE <= 1'b0;
                            err <= 1'b0;
                            WR_cnt <= WR_cnt + 1;
                        end
                        // the last state of write operation
                        // resetting every signals after two cycle of done signal
                        else if (WR_cnt == 4'd18) begin
                            if (cnt == 5'd3) begin
                                clkgen_rstn <= 1'b1;
                                cnt_rstn <= 1'b1;                        

                                WR_ADDR <= WR_ADDR;
                                DETOUR <= 2'b00; 
                                RP_SEL <= RP_SEL_temp; 
                                DMODE <= 6'b11_1111; 
                                DATA <= DATA_temp; 
                                // TRNG_MODE <= TRNG_MODE_temp;

                                WRITE_working <= 1'b1;
                                WRITE_DONE <= 1'b1;
                                err <= 1'b0;
                                // WR_cnt <= WR_cnt + 1;  
                            end
                            else if (cnt == 5'd5) begin
                                clkgen_rstn <= 1'b0;
                                cnt_rstn <= 1'b0;                        

                                WR_ADDR <= 11'd0;
                                DETOUR <= 2'b00; 
                                RP_SEL <= 1'd0; 
                                DMODE <= 6'd0; 
                                DATA <= 8'd0; 
                                // TRNG_MODE <= TRNG_MODE_temp;

                                WRITE_working <= 1'b0;
                                WRITE_DONE <= 1'b0;
                                err <= 1'b0;
                                // WR_cnt <= WR_cnt + 1;  
                            end
                        end
                        // Retaining signals
                        else begin
                            clkgen_rstn <= clkgen_rstn;
                            cnt_rstn <= cnt_rstn;                        

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
            // READ: begin

            // end
            // default: 
        endcase
    end
end

clk_generator clk_gen(clk_200, clk, clkgen_rstn);

count_20 counter0(cnt, clk, cnt_rstn);

endmodule

module count_20(
    output reg [4:0] q,
    input clk,
    input rstn
)

    always @(posedge clk) begin
        if (!rstn) begin
            q <= 5'd0;
        end else begin
            q <= q + 1;
        end
    end

endmodule

// clock generator
module clk_generator(
    output reg clk_200,
    input clk,
    input rstn,
);

    reg [4:0] cnt;

    always @(posedge clk) begin
        if (!rstn) begin
            clk_200 <= 1'b0;
            cnt <= 5'b0;
        end else begin
            if (cnt == 4'd20) begin
                clk_200 <= ~clk_200;
                cnt <= 5'd0;
            end else begin
                clk_200 <= clk_200;
                cnt <= cnt + 1;
            end
        end
    end

endmodule


CSN, clk_200은 read 19번 반복하고 마지막에 한 번 더 posedge 올라가도록 dummy cycle 한 사이클 추가하기 
