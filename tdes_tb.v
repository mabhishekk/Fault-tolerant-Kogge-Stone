`timescale 1ns / 1ps

module tdes_tb;

	// Inputs
	reg clock;
	reg reset;
	
	reg ed_bar;
	reg [7:0] idata;
	reg tx_start;

	// Outputs
	wire data_tx;
	wire ref_baud_clock;
	wire [7:0] rec_dataH;
	wire rec_readyH;
	wire data_rx;
	
	integer i;

	// Instantiate the Unit Under Test (UUT)
	tdes_top uut (
		.clock(clock), 
		.reset(!reset), 
		.data_tx(data_tx), 
		.data_rx(data_rx), 
		.ed_bar(ed_bar), 
		.ref_baud_clock(ref_baud_clock),
		.led_status(rec_dataH)
		
	);
	
	u_rec u_rec (
    .sys_rst_l(!reset), 
    .sys_clk(ref_baud_clock), 
	 
    .uart_dataH(data_tx), 
	 
    .rec_dataH(rec_dataH), 
    .rec_readyH(rec_readyH)
    );
	 
	u_xmit uart_tranmitter_tb_component (
    .sys_clk(ref_baud_clock), 
    .sys_rst_l(!reset), 
	 
    .uart_xmitH(data_rx), 
    .xmitH(tx_start), 
    .xmit_dataH(idata), 
    .xmit_doneH(tx_done)
    );
	 
	task send;
		input [7:0] data;
	begin
		idata = data;
		#10 @( posedge ref_baud_clock ) tx_start = 1;
		    @( posedge ref_baud_clock ) tx_start = 0;
		
		#100 @(posedge tx_done) $display("Data transferred = %x", idata);
		#100;
	end
	endtask
	
	initial
	begin
		clock = 0;
		forever #3 clock = !clock;
	end

	initial begin
		// Initialize Inputs
		clock = 0;
		reset = 1;
		#10;
		reset = 0;
		#10 reset = 1;
		//ed_bar = 1; // Encrypt
      ed_bar = 0; // Decrypt
		
		// Wait 100 ns for global reset to finish
		#1000;
      reset = 0;
		
		// Add stimulus here
		
		/*
		for(i = 0; i<= 7; i = i + 1) send(8'h01);
		for(i = 0; i<= 7; i = i + 1) send(8'h01);
		for(i = 0; i<= 7; i = i + 1) send(8'h01);
		*/
		// Encrypt
/*   	send(8'h95);
		send(8'hf8);
		send(8'ha5);
		send(8'he5);
		send(8'hdd);
		send(8'h31);
		send(8'hd9);
		send(8'h00);
*/
		// Decrypt
	   send(8'h88);
		send(8'h89);
		send(8'h88);
		send(8'h89);
		send(8'h01);
		send(8'h00);
		send(8'h00);
		send(8'h00);

		#100000 $stop;


	end
	
	always@(posedge rec_readyH)
	begin
	 $display("Received = %h", rec_dataH);
    end
    
endmodule

