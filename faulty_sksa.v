module sksa(a,b,cin,s,carry4,carry8,carry12,cout);
input [15:0] a,b;
input cin;
output [15:0] s;
output carry4,carry8,carry12;
output cout;

wire [15:0] P, G,P_A, G_A, P_B, G_B, P_C, G_C, G_D, P_D, G_E;

and_xor level_k0(a[0], b[0], P[0], G[0]);
and_xor level_k1(a[1], b[1], P[1], G[1]);
and_xor level_k2(a[2], b[2], P[2], G[2]);
and_xor level_k3(a[3], b[3], P[3], G[3]);
and_xor level_k4(a[4], b[4], P[4], G[4]);
and_xor level_k5(a[5], b[5], P[5], G[5]);
and_xor level_k6(a[6], b[6], P[6], G[6]);
and_xor level_k7(a[7], b[7], P[7], G[7]);
and_xor level_k8(a[8], b[8], P[8], G[8]);
and_xor level_k9(a[9], b[9], P[9], G[9]);
and_xor level_k10(a[10], b[10], P[10], G[10]);
and_xor level_k11(a[11], b[11], P[11], G[11]);
and_xor level_k12(a[12], b[12], P[12], G[12]);
and_xor level_k13(a[13], b[13], P[13], G[13]);
and_xor level_k14(a[14], b[14], P[14], G[14]);
and_xor level_k15(a[15], b[15], P[15], G[15]);

//level 1
black_cell level_1A(G[0], P[1], G[1], P[0], G_A[1], P_A[1]);
black_cell level_3A(G[2], P[3], G[3], P[2], G_A[3], P_A[3]);
black_cell level_5A(G[4], P[5], G[5], P[4], G_A[5], P_A[5]);
black_cell level_7A(G[6], P[7], G[7], P[6], G_A[7], P_A[7]);
black_cell level_9A(G[8], P[9], G[9], P[8], G_A[9], P_A[9]);
black_cell level_11A(G[10], P[11], G[11], P[10], G_A[11], P_A[11]);
black_cell level_13A(G[12], P[13], G[13], P[12], G_A[13], P_A[13]);
black_cell level_15A(G[14], P[15], G[15], P[14], G_A[15], P_A[15]);

//level 2
black_cell level_3B(G_A[1], P_A[3], G_A[3], P_A[1], G_B[3], P_B[3]);
black_cell level_7B(G_A[5], P_A[7], G_A[7], P_A[5], G_B[7], P_B[7]);
black_cell level_11B(G_A[9], P_A[11], G_A[11], P_A[9], G_B[11], P_B[11]);
black_cell level_15B(G_A[13], P_A[15], G_A[15], P_A[13], G_B[15], P_B[15]);

//level 3
gray_cell level_3C(cin, P_B[3], G_B[3], G_C[3]);
black_cell level_7C(G_B[3], P_B[7], G_B[7], P_B[3], G_C[7], P_C[7]);
black_cell level_11C(G_B[7], P_B[11], G_B[11], P_B[7], G_C[11], P_C[11]);
black_cell level_15C(G_B[11], P_B[15], G_B[15], P_B[11], G_C[15], P_C[15]);

//level 4
gray_cell level_7D(cin, P_C[7], G_C[7], G_D[7]);
gray_cell level_11D(G_C[3], P_C[11], G_C[11], G_D[11]);
black_cell level_15D(G_C[7], P_C[15], G_C[15], P_B[7], G_D[15], P_D[15]);

//level 5
gray_cell level_15E(cin, P_D[15], G_D[15], cout);

wire m,n,o,p;
assign m=G_C[3];
assign n=G_D[7];
assign o=G_D[11];

assign carry4=G_C[3];
assign carry8=G_D[7];
assign carry12=G_D[11];

wire [3:0] pa,q,r,sa,t,u,v,w,x,y,z,za;
assign pa[3:0]=a[3:0];
assign r[3:0]=a[7:4];
assign q[3:0]=a[11:8];
assign sa[3:0]=a[15:12];
assign t[3:0]=b[3:0];
assign u[3:0]=b[7:4];
assign v[3:0]=b[11:8];
assign w[3:0]=b[15:12];

//adders
adder1 rca1(pa,t,cin,x);
adder1 rca2(r,u,m,y);
adder1 rca3(q,u,n,z);
adder1 rca4(sa,w,o,za);

assign s[3:0]=x;
assign s[7:4]=y;
assign s[11:8]=z;
assign s[15:12]=za;



endmodule



module and_xor(a, b, p, g);
 input a, b;
 output p, g;
 
 xor(p, a, b);
 and(g, a, b);

endmodule


module black_cell(Gkj, Pik, Gik, Pkj, G, P);
 //black cell  
 input Gkj, Pik, Gik, Pkj;
 output G, P;
 wire Y;
  
 and(Y, Gkj, Pik);
 or(G, Gik, Y);
 and(P, Pkj, Pik);
 
endmodule


module gray_cell(Gkj, Pik, Gik, G);
 //gray cell
 input Gkj, Pik, Gik;
 output G;
 wire Y;
 
 and(Y, Gkj, Pik);
 or(G, Y, Gik);
 
endmodule


module adder1(a,b, cin, s);
    input [3:0] a,b;
    input cin;
    output [3:0] s;

	       assign s={4'b0000, a}+{4'b0000, b}+cin;
			 
endmodule
 
 
 module fa_4bit(a,b, cin, s, cout);
    input [3:0] a,b;
    input cin;
    output [3:0] s;
    output cout;

    wire [4:0] sum;
	       assign sum={4'b0000, a}+{4'b0000, b}+cin;
			 assign cout=sum[4];
			 assign s[3:0]=sum[3:0];
			 

endmodule

 

 
 