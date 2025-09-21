`timescale 1ns/10ps

module TB_TRNG_CTRL;
  // -------------------------
  // Clock / Reset
  // -------------------------
  reg clk = 1'b0;
  always #5 clk = ~clk;  // 100 MHz

  reg rstn;

  // -------------------------
  // DUT I/O
  // -------------------------
  wire        clk_200;
  wire        csn;
  wire        wen;
  wire [6:0]  ROW_ADDR;
  wire [3:0]  COL_ADDR;
  wire [1:0]  DETOUR;
  wire        RP_SEL;
  wire [5:0]  DMODE;
  wire [7:0]  DATA;
  wire [8:0]  TRNG_MODE;

  wire [143:0] MEM_OUT;
  wire         err;
  wire         Done;

  reg          start;
  reg  [1:0]   CMD;
  reg  [11:0]  ADDR;
  reg  [1:0]   DETOUR_IN;
  reg          RP_SEL_IN;
  reg  [5:0]   DMODE_WRITE;
  reg  [5:0]   DMODE_READ;
  reg  [2:0]   TRNG_BIT;
  reg  [143:0] MEM_IN;
  reg  [8:0]   TRNG_MODE_IN;
  reg          DATA_TRNG;

  // MRAM OUTPUT (to DUT)
  reg  [7:0]   OUTPUT;

  // -------------------------
  // Instantiate DUT
  // -------------------------
  TRNG_CTRL dut (
    .clk_200     (clk_200),
    .csn         (csn),
    .wen         (wen),
    .ROW_ADDR    (ROW_ADDR),
    .COL_ADDR    (COL_ADDR),
    .DETOUR      (DETOUR),
    .RP_SEL      (RP_SEL),
    .DMODE       (DMODE),
    .DATA        (DATA),
    .TRNG_MODE   (TRNG_MODE),

    .MEM_OUT     (MEM_OUT),
    .err         (err),
    .Done        (Done),

    .clk         (clk),
    .rstn        (rstn),
    .start       (start),
    .CMD         (CMD),
    .ADDR        (ADDR),
    .DETOUR_IN   (DETOUR_IN),
    .RP_SEL_IN   (RP_SEL_IN),
    .DMODE_WRITE (DMODE_WRITE),
    .DMODE_READ  (DMODE_READ),
    .TRNG_BIT    (TRNG_BIT),
    .MEM_IN      (MEM_IN),
    .TRNG_MODE_IN(TRNG_MODE_IN),
    .DATA_TRNG   (DATA_TRNG),

    .OUTPUT      (OUTPUT)
  );

 
  // -------------------------
  // Stimulus 
  // -------------------------
  localparam TRNG     = 2'b00;
  localparam SET_VAR = 2'b01;
  localparam WRITE   = 2'b10;
  localparam READ    = 2'b11;

  integer k;
  reg [143:0] mem_pattern;
  reg [143:0] captured;

  initial begin

    // defaults
    rstn         = 1'b0;
    start        = 1'b0;
    CMD          = TRNG;
    ADDR         = 12'd0;
    DETOUR_IN    = 2'b00;
    RP_SEL_IN    = 1'b0;
    DMODE_WRITE  = 6'h00;
    DMODE_READ   = 6'h00;
    TRNG_BIT     = 3'd0;
    MEM_IN       = 144'd0;
    TRNG_MODE_IN = 9'd0;
    DATA_TRNG    = 1'b0;

    #22;
    rstn = 1'b1;
    #8;

  // -------------------------
  // write
  // -------------------------


    // 1. set_var
    #30
    CMD = SET_VAR;
    #20;

    DETOUR_IN    = 2'b10;
    RP_SEL_IN    = 1'b1;
    DMODE_WRITE  = 6'h3F;
    DMODE_READ   = 6'h15;
    TRNG_MODE_IN = 9'h1A5;
    DATA_TRNG    = 1'b1;
    OUTPUT = 8'd0;
    start = 1'b1;

    #20;
    start = 1'b0;
    #20;

    // 2. write error
    #40;
    CMD = WRITE;
    #20;

    ADDR   = 12'd3000;
    MEM_IN = 144'h1234567887654321;
    start = 1;

    #20;
    start = 1'b0;

    #100;

    // 3. normal write
    #40;
    CMD = WRITE;
    #20;

    ADDR   = 12'd30;
    MEM_IN = 144'h987654321123456789987654321123456789;
    start = 1;

    #20;
    start = 1'b0;

    #5000;



  // -------------------------
  // read
  // -------------------------


    // 1. set_var
    #30
    CMD = SET_VAR;
    #20;

    DETOUR_IN    = 2'b10;
    RP_SEL_IN    = 1'b1;
    DMODE_WRITE  = 6'h3F;
    DMODE_READ   = 6'h15;
    TRNG_MODE_IN = 9'h1A5;
    DATA_TRNG    = 1'b1;
    start = 1'b1;

    #20;
    start = 1'b0;
    #20;

    // 2. read error
    #40;
    CMD = READ;
    #20;

    ADDR   = 12'd3000;
    start = 1;

    #20;
    start = 1'b0;

    #100;

    // 3. normal read
    #40;
    CMD = READ;
    #20;

    ADDR   = 12'd30;
    start = 1;

    #20;
    start = 1'b0;

    #215;
    OUTPUT = 8'h12;
    #200;
    OUTPUT = 8'h34;
    #200;
    OUTPUT = 8'h56;    

    #5000;



  // -------------------------
  // TRNG_MODE0
  // -------------------------


    // 1. set_var
    #30
    CMD = SET_VAR;
    #20;

    DETOUR_IN    = 2'b10;
    RP_SEL_IN    = 1'b1;
    DMODE_WRITE  = 6'h26;
    DMODE_READ   = 6'h03;
    TRNG_MODE_IN = 9'h077;  // TRNG_MODE0
    DATA_TRNG    = 1'b1;
    start = 1'b1;

    #20;
    start = 1'b0;
    #20;

    // 2. trng error
    #40;
    CMD = TRNG;
    #20;

    ADDR   = 12'b1011_1010_1101;
    start = 1;

    #20;
    start = 1'b0;

    #100;

    // 3. normal trng
    #40;
    CMD = TRNG;
    #20;

    ADDR   = 12'd30;
    start = 1;

    #20;
    start = 1'b0;

    // #215;
    // OUTPUT = 8'h12;
    // #200;
    // OUTPUT = 8'h34;
    // #200;
    // OUTPUT = 8'h56;    

    #13000;



  // -------------------------
  // TRNG_MODE0
  // -------------------------


    // 1. set_var
    #30
    CMD = SET_VAR;
    #20;

    DETOUR_IN    = 2'b10;
    RP_SEL_IN    = 1'b1;
    DMODE_WRITE  = 6'h26;
    DMODE_READ   = 6'h03;
    TRNG_MODE_IN = 9'h177;  // TRNG_MODE0
    DATA_TRNG    = 1'b1;
    start = 1'b1;

    #20;
    start = 1'b0;
    #20;

    // 2. trng error
    #40;
    CMD = TRNG;
    #20;

    ADDR   = 12'b1011_1010_1101;
    start = 1;

    #20;
    start = 1'b0;

    #100;

    // 3. normal trng
    #40;
    CMD = TRNG;
    #20;

    ADDR   = 12'd70;
    start = 1;

    #20;
    start = 1'b0;

    // #215;
    // OUTPUT = 8'h12;
    // #200;
    // OUTPUT = 8'h34;
    // #200;
    // OUTPUT = 8'h56;    

    #100000;


  // -------------------------
  // read
  // -------------------------


    // 1. set_var
    #30
    CMD = SET_VAR;
    #20;

    DETOUR_IN    = 2'b10;
    RP_SEL_IN    = 1'b1;
    DMODE_WRITE  = 6'h3F;
    DMODE_READ   = 6'h15;
    TRNG_MODE_IN = 9'h1A5;
    DATA_TRNG    = 1'b1;
    start = 1'b1;

    #20;
    start = 1'b0;
    #20;

    // 2. read error
    #40;
    CMD = READ;
    #20;

    ADDR   = 12'd3000;
    start = 1;

    #20;
    start = 1'b0;

    #100;

    // 3. normal read
    #40;
    CMD = READ;
    #20;

    ADDR   = 12'd30;
    start = 1;

    #20;
    start = 1'b0;

    #215;
    OUTPUT = 8'h12;
    #200;
    OUTPUT = 8'h34;
    #200;
    OUTPUT = 8'h56;    

    #5000;


    $stop;
  end

endmodule
