`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.09.2022 00:04:55
// Design Name: 
// Module Name: microp_32b
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module microp_32b(clk1,clk2,MEM_WB_IR);
input clk1,clk2;
output MEM_WB_IR;
reg[31:0] PC,IF_ID_IR,IF_ID_NPC;
reg[31:0] ID_EX_IR,ID_EX_NPC,ID_EX_A,ID_EX_B,ID_EX_Imm;
reg[2:0] ID_EX_type,EX_MEM_type,MEM_WB_type;
reg[31:0] EX_MEM_IR,EX_MEM_ALUOut,EX_MEM_B;
reg EX_MEM_cond;
reg[31:0] MEM_WB_IR,MEM_WB_ALUOut,MEM_WB_LMD;
reg[31:0] Reg[0:31];
reg[31:0] Mem[0:1023];
parameter ADD=6'b000000, SUB=6'b000001,NAND=6'b000010,NOR=6'b000011;
parameter SLT=6'b000100,SGT=6'b000101,SET = 6'b000110,HLT=6'b111111,LW=6'b001000,SW=6'b001001,ADDI=6'b001010,SUBI=6'b001011,SLTI=6'b001100,SETI=6'b001111,BNEQZ=6'b001101,BEQZ=6'b001110;
parameter RR_ALU=3'b000,RM_ALU=3'b001,LOAD=3'b010,STORE=3'b011,HALT=3'b101;
reg HALTED;

wire [31:0] EX_MEM_ALUOut1;
wire [31:0] EX_MEM_ALUOut_nand;
wire [31:0] EX_MEM_ALUOut_nor;
wire carry_neg;
wire [31:0] ID_EX_A1;
wire [31:0] ID_EX_B1;
wire  Cin;
reg  [31:0]EX_MEM_ALUOut_reg;
reg  [31:0]EX_MEM_ALUOut_nand_reg;
reg  [31:0]EX_MEM_ALUOut_nor_reg;
wire  gt,lt,eq;
reg   gt_reg,lt_reg,eq_reg;


assign Cin = ((ID_EX_IR[31:26] == SUB) || (ID_EX_IR[31:26]== SUBI))? 1'b1: 1'b0; 

assign ID_EX_B1= (ID_EX_type == RR_ALU)? ID_EX_B : ID_EX_Imm ;

assign ID_EX_A1= ID_EX_A;
// instantiation
carrylookahead_32b   carry1(EX_MEM_ALUOut1,carry_neg,ID_EX_A1,ID_EX_B1,Cin);
nand_32b             nand1(EX_MEM_ALUOut_nand,ID_EX_B1,ID_EX_A1);
nor_32b                nor1(EX_MEM_ALUOut_nor,ID_EX_B1,ID_EX_A1);
comparator_gt_32_bit   comp1(gt,lt,eq,ID_EX_A1,ID_EX_B1);
always@(EX_MEM_ALUOut1)

begin
EX_MEM_ALUOut_reg = EX_MEM_ALUOut1;
end

always@(EX_MEM_ALUOut_nand)                     //nand_operation

begin
EX_MEM_ALUOut_nand_reg = EX_MEM_ALUOut_nand;
end

always@(EX_MEM_ALUOut_nor)                     //nand_operation

begin
EX_MEM_ALUOut_nor_reg = EX_MEM_ALUOut_nor;
end

always@(gt or lt or eq)
begin
gt_reg = gt;
lt_reg = lt;
eq_reg = eq;
end

always @(posedge clk1)  //fetch
if(HALTED==0)
begin 
IF_ID_IR <=  Mem[PC];
IF_ID_NPC <=  PC+1;
PC <=  PC+1;
end
always @(posedge clk2)     ///decode
if(HALTED==0)
begin
if(IF_ID_IR[25:21] == 5'b00000) ID_EX_A <= 0;
else ID_EX_A <=  Reg[IF_ID_IR[25:21]];
if(IF_ID_IR[20:16] == 5'b00000) ID_EX_B <=0;
else ID_EX_B <=  Reg[IF_ID_IR[20:16]];
ID_EX_NPC <=  IF_ID_NPC;
ID_EX_IR <=  IF_ID_IR;
ID_EX_Imm <=  {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}};
case (IF_ID_IR[31:26])
ADD:ID_EX_type <=  RR_ALU;
SUB:ID_EX_type <=  RR_ALU;
NAND:ID_EX_type <= RR_ALU;
NOR:ID_EX_type <=  RR_ALU;
SLT:ID_EX_type <=  RR_ALU;
SGT:ID_EX_type <=  RR_ALU;
SET:ID_EX_type <=  RR_ALU;

ADDI:ID_EX_type <=  RM_ALU;
SUBI:ID_EX_type <=  RM_ALU;
SLTI: ID_EX_type <=  RM_ALU;
SETI: ID_EX_type <=  RM_ALU;
LW: ID_EX_type <=  LOAD;
SW: ID_EX_type <=  STORE;

HLT: ID_EX_type <=  HALT;
default: ID_EX_type <=  HALT;
endcase
end
always @(posedge clk1)   //execute
if(HALTED ==0)
begin
EX_MEM_type <=  ID_EX_type;
EX_MEM_IR <=  ID_EX_IR;

case (ID_EX_type)
RR_ALU: begin
case(ID_EX_IR[31:26])
ADD: EX_MEM_ALUOut <=  EX_MEM_ALUOut_reg;//ID_EX_A + ID_EX_B;
SUB: EX_MEM_ALUOut <=  EX_MEM_ALUOut_reg;//ID_EX_A - ID_EX_B;
NAND: EX_MEM_ALUOut <=  EX_MEM_ALUOut_nand_reg;//ID_EX_A & ID_EX_B;
NOR: EX_MEM_ALUOut  <=  EX_MEM_ALUOut_nor_reg;//ID_EX_A | ID_EX_B;
SLT: EX_MEM_ALUOut <=  lt_reg;//ID_EX_A < ID_EX_B;
SGT: EX_MEM_ALUOut <=  gt_reg;
SET: EX_MEM_ALUOut <=  eq_reg;

default: EX_MEM_ALUOut <= 32'hxxxxxxxx;
endcase 
end
RM_ALU: begin
case(ID_EX_IR[31:26])
ADDI: EX_MEM_ALUOut <= EX_MEM_ALUOut_reg; //ID_EX_A + ID_EX_Imm;
SUBI: EX_MEM_ALUOut <= EX_MEM_ALUOut_reg; //ID_EX_A - ID_EX_Imm;
SLTI: EX_MEM_ALUOut <=  gt_reg;
SETI: EX_MEM_ALUOut <=  eq_reg;
default: EX_MEM_ALUOut <=  32'hxxxxxxxx;
endcase
end
LOAD:
begin
EX_MEM_ALUOut <= EX_MEM_ALUOut_reg; //ID_EX_A + ID_EX_Imm;
EX_MEM_B <=  ID_EX_B;
end
STORE:
begin
EX_MEM_ALUOut <=  EX_MEM_ALUOut_reg; //ID_EX_A + ID_EX_Imm;
EX_MEM_B <=  ID_EX_B;
end

endcase 
end

always @(posedge clk2)  //memory
if(HALTED ==0)
begin
MEM_WB_type <=  EX_MEM_type;
MEM_WB_IR <=  EX_MEM_IR;
case(EX_MEM_type)
RR_ALU:MEM_WB_ALUOut <=  EX_MEM_ALUOut;
RM_ALU:MEM_WB_ALUOut <=  EX_MEM_ALUOut;
LOAD: MEM_WB_LMD <=  Mem[EX_MEM_ALUOut];
STORE: 
            begin
            Mem[EX_MEM_ALUOut] <=  EX_MEM_B;
            end

endcase
end
always @(posedge clk1)    
begin


case(MEM_WB_type)
RR_ALU: Reg[MEM_WB_IR[15:11]] <= MEM_WB_ALUOut;
RM_ALU: Reg[MEM_WB_IR[20:16]] <=  MEM_WB_ALUOut;
LOAD: Reg[MEM_WB_IR[20:16]] <=  MEM_WB_LMD;
HALT: HALTED <= 1'b1;

endcase
end
endmodule


module carrylookahead_32b(Sum,Cout, A , B_ ,Cin

    );
    input [31:0] A;
    input [31:0] B_;
    input  Cin;
    output [31:0] Sum;
    output Cout;
    wire  [31:0] B;
    wire [31:0] P;
    wire [31:0] G;
    wire [31:0] C;
    wire [31:0] X;
    assign Cout = C[31];
    
    genvar M;
    generate 
    for(M =0;M<32;M=M+1)
    begin //Add or Subtract
    xor xadd_sub(B[M],B_[M],Cin);
    end 
    endgenerate
    
    
    
    
    genvar i;
    generate 
    for (i=0;i<32;i=i+1)
    begin //prop_gen
    xor x1(P[i],A[i],B[i]);
    and a1(G[i],A[i],B[i]);
    end
    endgenerate
    
    
    and an1(X[0],P[0],Cin);
    or  o1(C[0],G[0],X[0]);
    
    
    genvar j;
    generate
    for(j=0;j<31;j=j+1)
    begin //genr_car
    and and1( X[j+1],P[j+1],C[j]);
    or  or1(C[j+1],G[j+1],X[j+1]);
    end 
    endgenerate
    
    xor sum0(Sum[0],P[0],Cin);
    
    genvar k;
    generate
    for(k=0;k<31;k=k+1)
    begin //gen_Sum
    xor x_sum(Sum[k+1],P[k+1],C[k]);
    end
    endgenerate
    
    
    
    
endmodule


module nand_32b(C,B,A );
input [31:0] A;
input [31:0] B;
output [31:0] C;

genvar i;
generate

for( i=0; i<=31; i=i+1)
begin //and_operation
nand a1(C[i] , B[i] , A[i]);
end
endgenerate
endmodule


module nor_32b(C,B,A );
input [31:0] A;
input [31:0] B;
output [31:0] C;

genvar i;
generate

for( i=0; i<=31; i=i+1)
begin //nor_operation
nor a1(C[i] , B[i] , A[i]);
end
endgenerate


endmodule


module comparator_gt_32_bit(gt,lt,eq,a,b );
input [31:0] a;
input [31:0] b;
output  lt,gt ,eq;
wire ltm,gtm,eqm;
wire ltl,gtl,eql;
wire tmp1;
comp_16b c1(gtm , ltm, eqm,a[31:16],b[31:16]);
comp_16b c2(gtl,ltl,eql,a[15:0],b[15:0]);

and a1(tmp1, eqm,gtl);
or  or1(gt, tmp1, gtm);

and a2(eq, eql,eqm);

nor n2(lt,eq , gt);


endmodule


module comp_16b(gt1,lt1,eq1,a1,b1);
input [15:0] a1,b1;
output lt1,gt1,eq1;

wire [3:0]eq;
wire [3:0]lt;
wire [3:0]gt;
comp_4b c3(a1[15:12],b1[15:12],gt[3],lt[3],eq[3]);
comp_4b c2(a1[11:8],b1[11:8],gt[2],lt[2],eq[2]);
comp_4b c1(a1[7:4],b1[7:4],gt[1],lt[1],eq[1]);
comp_4b c0(a1[3:0],b1[3:0],gt[0],lt[0],eq[0]);
wire a,b,c,d,e,f;


and and1(a,eq[1],gt[0]);
or  o1(b,a,gt[1]);
and a2(c,b,eq[2]);
or  o2(d,c,gt[2]);
and a3(e,d,eq[3]);
or  o3(gt1,gt[3],e);
and a4(eq1,eq[0],eq[1],eq[2],eq[3]);

nor n1(lt1,eq1,gt1);
endmodule


module comp_4b(A,B,GT,LT,EQ);
input [3:0] A,B;
output LT,GT,EQ;

wire [3:0]eq;
wire [3:0]lt;
wire [3:0]gt;
comparator_1bit c3(A[3],B[3],gt[3],lt[3],eq[3]);
comparator_1bit c2(A[2],B[2],gt[2],lt[2],eq[2]);
comparator_1bit c1(A[1],B[1],gt[1],lt[1],eq[1]);
comparator_1bit c0(A[0],B[0],gt[0],lt[0],eq[0]);
wire a,b,c,d,e,f;


and a1(a,eq[1],gt[0]);
or  o1(b,a,gt[1]);
and a2(c,b,eq[2]);
or  o2(d,c,gt[2]);
and a3(e,d,eq[3]);
or  o3(GT,gt[3],e);


and a4(EQ,eq[0],eq[1],eq[2],eq[3]);

nor n1(LT,EQ,GT);



endmodule

module comparator_1bit(a,b,gt ,lt,eq);

input a,b;
output lt,gt,eq;
wire abar,bbar;

not n1(abar,a);
//assign bbar = ~b;
not n2(bbar,b);
//assign lt = abar & b;

and a1(lt,abar,b);
//assign gt = bbar & a;
and a2(gt,bbar,a);
//assign eq = ~(lt|gt);
nor nor3(eq,lt,gt);
endmodule
