
//
// Receiver state definition
//
parameter	r_START 	= 3'b001,
          	r_CENTER	= 3'b010,
          	r_WAIT  	= 3'b011,
          	r_SAMPLE	= 3'b100,
		  	r_STOP  	= 3'b101;

//
// Xmitter state definition
//
parameter x_IDLE		= 3'b000,
			x_START		= 3'b001,
			x_WAIT		= 3'b010,
			x_SHIFT		= 3'b011,
			x_STOP		= 3'b100;


parameter   x_STARTbit  = 2'b00,
			x_STOPbit   = 2'b01,
			x_ShiftReg  = 2'b10;

//
// Common parameter Definition
//
parameter	LO 		= 1'b0,
          	HI		= 1'b1,		
 		  	X		= 1'bx;


// *****************************
//
// Receiver Configuration
//
// *****************************

// Word length.  
// This defines the number of bits 
// in a "word".  Typcially 8.
// min=0, max=8

parameter	WORD_LEN = 8;



//
// The xtal-osc clock freq
//
//parameter XTAL_CLK = 25175000;
parameter XTAL_CLK = 53125000;

//
// The desired baud rate
//
parameter BAUD = 2400;

parameter CLK_DIV = XTAL_CLK / (BAUD * 16 * 2);

//
// CW >= log2(CLK_DIV)
//
parameter CW   = 10;


// If defined,
// this UART design becomes a loop-back.
// That is, whatever the micro-UART receives,
// it send it back
//
`define DEBUG


// mini-UART register address map definition
parameter  SEL_XMIT_DAT     = 3'b000,
		   SEL_REC_DAT      = 3'b000,
		   SEL_BAUD_REG_LO  = 3'b001,
           SEL_BAUD_REG_HI  = 3'b010,
           SEL_STAT_REG     = 3'b011,
           SEL_INT_STAT_REG = 3'b100,
           SEL_INT_ENA_REG  = 3'b101;

