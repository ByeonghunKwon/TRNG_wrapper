//=================================================================
//                         +-------------------+
//  [TOP]                  |                   |           [MRAM]
//-------------------------|                   |-------------------------
// clk             (1) --->|                   |
// start_TOP       (1) --->|                   | ---> start       (1)
// rstn            (1) --->|                   |
//                         |                   |
// ADDR_TOP       (12) --->|                   | ---> ADDR       (12)
// DETOUR_IN_TOP   (2) --->|                   | ---> DETOUR_IN   (2)
// RP_SEL_IN_TOP   (1) --->|      wrapper      | ---> RP_SEL_IN   (1)
// DMODE_WRITE_TOP (6) --->|                   | ---> DMODE_WRITE (6)
// DMODE_READ_TOP  (6) --->|                   | ---> DMODE_READ  (6)
// DATA_IN_TOP     (8) --->|                   | ---> DATA_IN     (8)
// TRNG_MODE_TOP   (9) --->|                   | ---> TRNG_MODE   (9)
// TRNG_BIT_TOP    (3) --->|                   | ---> TRNG_BIT    (3)
// MEM_IN_TOP    (144) --->|                   | ---> MEM_IN    (144)
// DATA_TRNG_TOP   (1) --->|                   | ---> DATA_TRNG   (1)
//                         |                   |
// MEM_OUT_TOP   (144) <---|                   | <--- MEM_OUT   (144)
// Done_TOP        (1) <---|                   | <--- Done        (1)
// err_TOP         (1) <---|                   | <--- err         (1)
//                         |                   |
//                         +-------------------+
//
//=================================================================

module TRNG_wrapper (

    // -------------------------
    // From TOP
    // -------------------------
    input         clk,
    input         rstn,
    input         start_TOP,
    input  [11:0] ADDR_TOP,
    input  [1:0]  DETOUR_IN_TOP,
    input         RP_SEL_IN_TOP,
    input  [5:0]  DMODE_WRITE_TOP,
    input  [5:0]  DMODE_READ_TOP,
    input  [7:0]  DATA_IN_TOP,
    input  [8:0]  TRNG_MODE_TOP,
    input  [2:0]  TRNG_BIT_TOP,
    input  [143:0] MEM_IN_TOP,
    input          DATA_TRNG_TOP,

    // -------------------------
    // To TOP
    // -------------------------
    output reg [143:0] MEM_OUT_TOP,
    output reg         Done_TOP,
    output reg         err_TOP,

    // -------------------------
    // To MRAM
    // -------------------------
    output reg         start,
    output reg [11:0]  ADDR,
    output reg [1:0]   DETOUR_IN,
    output reg         RP_SEL_IN,
    output reg [5:0]   DMODE_WRITE,
    output reg [5:0]   DMODE_READ,
    output reg [7:0]   DATA_IN,
    output reg [8:0]   TRNG_MODE,
    output reg [2:0]   TRNG_BIT,
    output reg [143:0] MEM_IN,
    output reg         DATA_TRNG, 

    // -------------------------
    // From MRAM
    // -------------------------
    input  [143:0] MEM_OUT,
    input          Done,
    input          err
);

always @(posedge clk) begin
    if (!rstn) begin
        start       <= 1'd0;
        ADDR        <= 12'd0;
        DETOUR_IN   <= 2'd0;
        RP_SEL_IN   <= 1'd0;
        DMODE_WRITE <= 6'd0;
        DMODE_READ  <= 6'd0;
        DATA_IN     <= 8'd0;
        TRNG_MODE   <= 9'd0;
        TRNG_BIT    <= 3'd0;
        MEM_IN      <= 144'd0;
        DATA_TRNG   <= 1'b0;

        MEM_OUT_TOP <= 144'd0;
        Done_TOP    <= 1'd0;
        err_TOP     <= 1'd0;
    end else begin
        start       <= start_TOP;
        ADDR        <= ADDR_TOP;
        DETOUR_IN   <= DETOUR_IN_TOP;
        RP_SEL_IN   <= RP_SEL_IN_TOP;
        DMODE_WRITE <= DMODE_WRITE_TOP;
        DMODE_READ  <= DMODE_READ_TOP;
        DATA_IN     <= DATA_IN_TOP;
        TRNG_MODE   <= TRNG_MODE_TOP;
        TRNG_BIT    <= TRNG_BIT_TOP;
        MEM_IN      <= MEM_IN_TOP;
        DATA_TRNG   <= DATA_TRNG_TOP;

        MEM_OUT_TOP <= MEM_OUT;
        Done_TOP    <= Done;
        err_TOP     <= err;
    end
end   


endmodule
