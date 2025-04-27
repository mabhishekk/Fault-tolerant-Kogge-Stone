//Test bench
module kogge_tb;
	// Inputs
	reg clk;
	reg rst;
	reg [15:0] a;
	reg [15:0] b;
	reg cin;
	reg correction_enable;
//	reg carry4,carry8,carry12;
	
	// Outputs
	wire [15:0] corrected_sum, uncorrected_sum;
	wire cout;
	// Instantiate the Unit Under Test (UUT)
	kogge_16_fault_correction uut (
															.clk(clk),
															.rst(rst), 
															.a(a), 
															.b(b), 
															.cin(cin), 
															.correction_enable(correction_enable), 
															.corrected_sum(corrected_sum),
															.uncorrected_sum(uncorrected_sum),
															.cout(cout)
											);
	
	initial
	begin
		clk = 0;
		forever #10 clk = !clk;
	end

	initial begin
		// Initialize Inputs
		rst = 1;
		a = 0;
		b = 0;
		cin = 0;
		correction_enable = 0;

		// Wait 100 ns for global reset to finish
		#100;
      rst = 0;
		
		// Add stimulus here
		a = 16'h1111;
		b = 16'h1010;
		
		#100;
		

	end
      
endmodule



//Uut
module kogge_16_fault_correction(
												 input clk,
												 input rst,
												 input [15:0] a,
												 input [15:0] b,
												 input cin,
												 input correction_enable,
												 output reg [15:0] corrected_sum,
												 output [15:0] uncorrected_sum,
												 output cout
											);
											
wire [15:0] untested_sum;

wire [3:0] sum0, sum1, sum2, sum3;
wire [3:0] a0, a1, a2, a3;
wire [3:0] b0, b1, b2, b3;
wire       c0, c1, c2, c3, c4;

reg [1:0] counter;	
reg c_prev;										

sksa sksa1(
							 .a(a), 
							 .b(b), 
							 .cin(cin),
							 .s(untested_sum), 
							 .carry4(c1), 
							 .carry8(c2), 
							 .carry12(c3), 
							 .cout(c4)
    );

assign c0 = cin;
assign uncorrected_sum = untested_sum;

assign b0 = b[3:0];
assign b1 = b[7:4];
assign b2 = b[11:8];
assign b3 = b[15:12];

assign a0 = a[3:0];
assign a1 = a[7:4];
assign a2 = a[11:8];
assign a3 = a[15:12];

assign sum0 = untested_sum[3:0];
assign sum1 = untested_sum[7:4];
assign sum2 = untested_sum[11:8];
assign sum3 = untested_sum[15:12];


// ------------------------------------------------------------------ //

always@(posedge clk or posedge rst)
	if (rst) counter <= 0;
	else if (correction_enable) counter <= counter + 1;
	else counter <= counter;
	
reg [3:0] s1, rca1_a, rca1_b, rca2_a, rca2_b, tested_sum;
reg cout1, rca1_cin, rca2_cin, tested_cout;
	
always@(*)
	case(counter)
		0: begin
		   {s1, cout1} = {sum0, c1};
		   {rca1_a, rca1_b, rca1_cin} = {a0, b0, c0};
			{rca2_a, rca2_b, rca2_cin} = {a0, b0, c0};
			end
			
		1: begin
		   {s1, cout1} = {sum1, c2};
		   {rca1_a, rca1_b, rca1_cin} = {a1, b1, c_prev};
			{rca2_a, rca2_b, rca2_cin} = {a1, b1, c_prev};
			end

		2: begin
		   {s1, cout1} = {sum2, c3};
		   {rca1_a, rca1_b, rca1_cin} = {a2, b2, c_prev};
			{rca2_a, rca2_b, rca2_cin} = {a2, b2, c_prev};
			end
			
		3: begin
		   {s1, cout1} = {sum3, c4};
		   {rca1_a, rca1_b, rca1_cin} = {a3, b3, c_prev};
			{rca2_a, rca2_b, rca2_cin} = {a3, b3, c_prev};
			end
			
	endcase
		
		
// ------------------------------------------------------------------ //

	
	
	wire  [3:0]s3,s2;
	
	
			fa_4bit rca2 (
											 .a(rca1_a), 
											 .b(rca1_b), 
											 .cin(rca1_cin), 
											 .s(s2), 
											 .cout(cout2)
											 );

			fa_4bit rca3 (
											 .a(rca2_a), 
											 .b(rca2_b), 
											 .cin(rca2_cin), 
											 .s(s3), 
											 .cout(cout3)
											 );
											 
			// Comparator Logic
											 
			assign cond1 = (s1 == s2);
			assign cond2 = (s1 == s3);
			assign cond3 = (s3 == s2);
			assign cond4 = (cond1 & cond2 & cond3);
			
			always@(*)
				if(cond4 | cond1 | cond2) 
				begin
					tested_sum = s1;
					tested_cout = cout1;
				end
				else
				begin	
					tested_sum = s3;
					tested_cout = cout3;
				end

// ----------------------------------------------------------------------

always@(posedge clk)
	if(rst) corrected_sum <= 0;
	else
		case(counter)
			0: {c_prev, corrected_sum} <= {tested_cout, corrected_sum[15:4], tested_sum};
			1: {c_prev, corrected_sum} <= {tested_cout, corrected_sum[15:8], tested_sum, corrected_sum[3:0]};
			2: {c_prev, corrected_sum} <= {tested_cout, corrected_sum[15:12], tested_sum, corrected_sum[7:0]};
			3: {c_prev, corrected_sum} <= {tested_cout, tested_sum, corrected_sum[11:0]};
       endcase

assign cout = c_prev;

endmodule



