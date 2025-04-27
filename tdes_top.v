`timescale 1ns / 1ns
module tdes_top(
						 input clock,
						 input reset,
						 output data_tx,
						 input data_rx,
						 input ed_bar,
						 output ref_baud_clock,
						 output [7:0] led_status
                );


reg [2:0] enable_sync;
reg [5:0] round_select_e, round_select_d;
wire [5:0] round_select;
reg enable_round_select, reset_round_select;
//wire round_e_complete;
reg round_e_complete; 
wire round_d_complete, xmit_done;

wire	[63:0]	des_in;
wire	[15:0] a,b;
wire cin;
wire cout;
wire  [15:0]   corrected_sum;
wire  [15:0]   uncorrected_sum;
reg cout_reg;
reg [15:0] uncorrected_sum_reg;
reg [15:0] corrected_sum_reg;






// ------------------------ UART TRANSMITTER/ RECEIVER LOGIC ---------------------------------- //

parameter NTRANSFER  = 6;     // in bytes
parameter NRECEIVE   = 8;    // in bytes
parameter BAUD_RATE_IMPL = 5; // for 9600 baud rate
parameter BAUD_RATE_SIM  = 1;

integer i;

reg  [7:0] rxd_data_buf [255:0];
reg  [7:0] txd_data_buf;
reg  [7:0] rxd_pointer, txd_pointer;

wire baud_clock;
wire [7:0] rxd_data;
wire rxd_new_byte, rec_ready, max_transfers_reached;
reg [2:0] rec_ready_sync;
reg xmit_new_byte, select_next_byte, reset_txd_pointer;
reg begin_transfer, transfer_started, sample_crypt_data;
wire data_rx_complete;

baud baud (
    .sys_clk(clock), 
    .sys_rst_l(reset), 
    .baud_clk(baud_clock),
	 .baud_rate_div(BAUD_RATE_IMPL)
    );

assign ref_baud_clock = baud_clock;
	 
// ------------------ RECEIVER ----------------- //
	 
u_rec u_rec (
    .sys_rst_l(reset), 
    .sys_clk(baud_clock), 
	 
    .uart_dataH(data_rx), 
	 
    .rec_dataH(rxd_data), 
    .rec_readyH(rec_ready)
    );
	 
assign led_status = corrected_sum_reg[7:0];
	 
// rec_ready is active low
// produce one shot of this signal to sample the data in to the buffer

always@(posedge baud_clock)
		if(!reset) rec_ready_sync <= 0;
		else rec_ready_sync <= { rec_ready_sync[1:0], rec_ready };

assign rxd_new_byte = ~rec_ready_sync[2] & rec_ready_sync[1];

// Pointer 
			
always@(posedge baud_clock or negedge reset)
	if(!reset) rxd_pointer <= 0;
	else if (rxd_pointer > NRECEIVE) rxd_pointer <= rxd_pointer;
	else if(rxd_new_byte) rxd_pointer <= rxd_pointer + 1;
	else rxd_pointer <= rxd_pointer;
	
// Receive data buffer

always@(posedge baud_clock or negedge reset)
	if(!reset)
		for(i = 0;i <= 255; i = i + 1)
			rxd_data_buf[i] <= 0;
	else if(rxd_new_byte) 
			rxd_data_buf[rxd_pointer] <= rxd_data;
	else 
	 	for(i = 0;i <= 255; i = i + 1)
			rxd_data_buf[i] <= rxd_data_buf[i];
			
			
// --------------------- TRANSMITTER -------------------- //

u_xmit u_xmit (
    .sys_clk(baud_clock), 
    .sys_rst_l(reset), 
	 
    .uart_xmitH(data_tx), 
	 
    .xmitH(xmit_new_byte), 
    .xmit_dataH(txd_data_buf), 
	 
    .xmit_doneH(xmit_done)
    );

// Messages to send

always@(posedge baud_clock or negedge reset)
	if(!reset) txd_pointer <= 0;
	else if(reset_txd_pointer) txd_pointer <= 0;
	else if(select_next_byte) txd_pointer <= txd_pointer + 1;
	else txd_pointer <= txd_pointer;
	
// Depending on txd_pointer size any number of transfers can be initiated
always@(*)
begin
	txd_data_buf = 8'h23;
	case( txd_pointer )
		5: txd_data_buf = 8'h00;//uncorrected_sum_reg[7:0];
		4: txd_data_buf = 8'h00;//uncorrected_sum_reg[15:8];
		3: txd_data_buf = {7'b0,cout_reg};//uncorrected_sum_reg[23:16];
		2: txd_data_buf = corrected_sum_reg[7:0];
		1: txd_data_buf = corrected_sum_reg[15:8];
		0: txd_data_buf = 8'h00;
		//1: txd_data_buf = 0;
		//0: txd_data_buf = 0;
		default: txd_data_buf = 8'h23;
	endcase

    
end


assign max_transfers_reached = (txd_pointer == NTRANSFER - 1);

localparam RESET_STATE = 5,
			  WAIT_FOR_START_TRANSFER = 0,
           SEND_BYTE = 1,
			  WAIT_FOR_COMPLETION_OF_BYTE_TRANSFER = 2,
			  CHECK_FOR_MAX_TRANSFERS = 3,
			  NOP = 4,
			  NOP1 = 5,
			  NOP2 = 6,
			  NOP3 = 7,
			  NOP4 = 8,
			  NOP5 = 9,
			  NOP6 = 10,
			  NOP7 = 11;
			  
reg [2:0] TXR_CS, TXR_NS;

always@(posedge baud_clock or negedge reset)
	if(!reset) TXR_CS <= RESET_STATE;
	else TXR_CS <= TXR_NS;
	
always@(*)
begin
	xmit_new_byte = 0;
   reset_txd_pointer = 0;
	select_next_byte = 0;
	transfer_started = 1;
	
	case(TXR_CS)
	
		RESET_STATE:
		begin
		   transfer_started = 0;
			/*if (max_transfers_reached)*/ TXR_NS = WAIT_FOR_START_TRANSFER;
			  //else TXR_NS = RESET_STATE;
		end
		
		 NOP3:
		 begin
		 TXR_NS=NOP4;
		 end
     NOP4:
    begin
      TXR_NS=NOP5;
    end
     NOP5:
    begin
      TXR_NS=NOP6;
    end
     NOP6:
    begin
      TXR_NS=NOP7;
    end
     NOP7:
    begin
      TXR_NS=WAIT_FOR_START_TRANSFER;
    end
		
		WAIT_FOR_START_TRANSFER:
		begin
		  
			transfer_started = 0;
			if( round_e_complete ) TXR_NS = SEND_BYTE;
			/*else TXR_NS = NOP1;
		end
    NOP1:
    begin
    TXR_NS=NOP2;
    end
    NOP2:
    begin*/
    else
    TXR_NS=WAIT_FOR_START_TRANSFER;
  end
  

		
		
		

		
		
		SEND_BYTE:
		begin
			xmit_new_byte = 1;
			if( !xmit_done ) TXR_NS = WAIT_FOR_COMPLETION_OF_BYTE_TRANSFER;
			else TXR_NS = SEND_BYTE;
		end
		
		WAIT_FOR_COMPLETION_OF_BYTE_TRANSFER:
		begin
			if( xmit_done ) TXR_NS = CHECK_FOR_MAX_TRANSFERS;
			else TXR_NS = WAIT_FOR_COMPLETION_OF_BYTE_TRANSFER;
		end
		
		CHECK_FOR_MAX_TRANSFERS:
		begin
			if( max_transfers_reached ) TXR_NS = WAIT_FOR_START_TRANSFER;
			else begin
				select_next_byte = 1;
				TXR_NS = NOP;
			end
		end
		
		NOP:
		begin
			TXR_NS = SEND_BYTE;
		end
		
		default:
		 TXR_NS = RESET_STATE;
		 
	 endcase
end


// PS: Signals to consider
// begin_transfer : should be in terms of baud_clk should come as an input
// 

// ------------------------------------------------------------------------------- //

assign data_rx_complete = (rxd_pointer == NRECEIVE + 1);
	
parameter WAIT_DATA = 0,
          ENABLE_ROUNDS = 1,
			 WAIT = 2,
			 
			 WAIT1 = 3,
			 WAIT2 = 4,
			 WAIT3 = 5,
			 WAIT4 = 6,
			 WAIT5 = 7;
			 
			 
			 
reg [2:0] NS,CS;

always@(posedge baud_clock or negedge reset)
	if(!reset) CS <= WAIT_DATA;
	else CS <= NS;
	
always@(*)
begin
	reset_round_select = 0;
	//enable_round_select = 0;
	sample_crypt_data = 0;
	begin_transfer = 0;
	
	case(CS)
		WAIT_DATA:
		begin
			reset_round_select = 1;
			if( data_rx_complete ) NS = ENABLE_ROUNDS;
			else NS = WAIT_DATA;
		end
		
		ENABLE_ROUNDS:
		begin
			enable_round_select = 1;
			NS = WAIT1;
			//if(round_e_complete) NS = WAIT;
			//else NS = ENABLE_ROUNDS;
		end
		
		WAIT1: NS = WAIT2;
		
		WAIT2: NS = WAIT3;
		
		WAIT3: NS = WAIT4;
		
		WAIT4: NS = WAIT5;
		
		WAIT5: begin round_e_complete = 1'b1; NS = WAIT; enable_round_select = 0;  
		             $display("corrected_sum = %b", corrected_sum); 
		             //corrected_sum_reg <= corrected_sum; 
		             end
		
		WAIT: NS = WAIT;
		
		default: NS = WAIT_DATA;
	endcase
end

always@(posedge baud_clock or negedge reset)
	if(!reset) round_select_e <= 0;
	else if (reset_round_select) round_select_e <= 0;
	else if (enable_round_select) round_select_e <= round_select_e + 1;
	else round_select_e <= round_select_e;

assign a =	{ rxd_data_buf[2],
					  rxd_data_buf[1]/*,
					  rxd_data_buf[3][7:1],
					  rxd_data_buf[4][7:1],
					  rxd_data_buf[5][7:1],
					  rxd_data_buf[6][7:1],
					  rxd_data_buf[7][7:1],
					  rxd_data_buf[8][7:1] */
					 };

assign b =	{ 
                 rxd_data_buf[4],                                            
					  rxd_data_buf[3]/*,
					  rxd_data_buf[11][7:1],
					  rxd_data_buf[12][7:1],
					  rxd_data_buf[13][7:1],
					  rxd_data_buf[14][7:1],
					  rxd_data_buf[15][7:1],
                      rxd_data_buf[16][7:1]*/					  
					  };

assign cin =	{ 
                     {rxd_data_buf[5][0]}/*[7:1],
					  rxd_data_buf[18][7:1],
					  rxd_data_buf[19][7:1],
					  rxd_data_buf[20][7:1],
					  rxd_data_buf[21][7:1],
					  rxd_data_buf[22][7:1],
					  rxd_data_buf[23][7:1], 
                      rxd_data_buf[24][7:1]*/
					  
					 };
kogge_16_fault_correction ksa1(
												 .clk(ref_baud_clock),
												 .rst(!reset),
												 .a(a),
												 .b(b),
												 .cin(cin),
												 .correction_enable(enable_round_select),
												 .corrected_sum(corrected_sum),
												 .uncorrected_sum(uncorrected_sum),
												 .cout(cout)
	);

always@(negedge baud_clock or negedge reset)
	if(!reset) 
	       begin 
	           cout_reg <= 0;
	           uncorrected_sum_reg<=0;
	           corrected_sum_reg<=0;
	       end
	else if(round_e_complete) 
	       begin 
	           cout_reg <= cout;
	           uncorrected_sum_reg <= uncorrected_sum;
	           corrected_sum_reg<=corrected_sum;
	       end
	else 
	       begin 
	            cout_reg<= cout_reg;
	            uncorrected_sum_reg <= uncorrected_sum_reg;
	            corrected_sum_reg <= corrected_sum_reg;
	       end
	  
	  


											
endmodule











