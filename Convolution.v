//------------------------------------------------------//
//- Digital IC Design 2022                              //
//-                                                     //
//- Lab04b: Verilog Behavioral Level                    //
//------------------------------------------------------//
`timescale 1ns/10ps

module Convolution (
CLK,
RESET,
IN_DATA_1,
IN_DATA_2,
IN_DATA_3,
IN_VALID,
KERNEL_VALID,
IN_KERNEL,
OUT_DATA,
OUT_VALID
);

input              CLK, RESET;
input [4:0]        IN_DATA_1, IN_DATA_2, IN_DATA_3;
input              IN_VALID, KERNEL_VALID;
input signed [7:0] IN_KERNEL;
output    reg [15:0]  OUT_DATA;
output    reg        OUT_VALID;

reg		[11:0]	data_count,depth_conv_count,point_conv_count,rlc_count,out_count;
reg		[10:0]	i,num_df,num_relu,num_point,num_point_relu,num_rlc,zero_num,not_zero_count;
reg				out_clk;
reg		[2:0]	out_term_count;
reg     [4:0]   kernal_count;
reg     [3:0]   j,num_dc;
reg		[1:0]	num_dc1, num_df1, num_relu1, p1;
reg signed [4:0]	DATA 			[0:1599][0:2];
reg signed [7:0] 	KERNEL 			[0:6][0:2];
reg signed [15:0]	depth_conv 		[0:6][0:2];
reg signed [15:0]	depth_feature	[0:1593][0:2];
reg signed [15:0]	relu_feature	[0:1593][0:2];
reg signed [7:0] 	point_KERNEL 	[0:2];
reg signed [23:0]	point_conv 		[0:2];
reg signed [23:0]	point_feature	[0:1593];
reg signed [23:0]	relu_point_feature	[0:1593];
reg signed [15:0]	RLC[0:796];
// ==========================================
//  Enter your design below
// ==========================================
always @(posedge CLK) 
begin
	if(RESET)
		data_count <= 12'd0;
	else if(IN_VALID)
		data_count <= data_count + 12'd1;
	else if(data_count > 12'd1599)
		data_count <= 12'd0;
end
//store IN_DATA to DATA[0:1599][0:2] 
always @(posedge CLK) 
begin
	if(RESET)begin
		for(i=0; i<1600 ; i=i+1)begin
			DATA[i][0] <= 5'd0;
			DATA[i][1] <= 5'd0;
			DATA[i][2] <= 5'd0;
		end
	end else if(IN_VALID) begin
		DATA[data_count][0] <= IN_DATA_1;
		DATA[data_count][1] <= IN_DATA_2;
		DATA[data_count][2] <= IN_DATA_3;
	end
end

always @(posedge CLK) 
begin
	if(RESET)
		kernal_count <= 5'd0;
	else if(kernal_count >= 5'd23)
		kernal_count <= 5'd0;
	else if(KERNEL_VALID)
		kernal_count <= kernal_count + 5'd1;
end
//store IN_KERNEL to KERNEL[0:6][0:2]  
always @(posedge CLK) 
begin
	if(RESET)begin
		for(j=0; j<7 ; j=j+1)begin
			KERNEL[j][0] <= 7'd0;
			KERNEL[j][1] <= 7'd0;
			KERNEL[j][2] <= 7'd0;
		end
	end else if(KERNEL_VALID)
		KERNEL[kernal_count % 7][kernal_count / 7] <= IN_KERNEL;
end

always @(posedge CLK) 
begin
	if(RESET)
		depth_conv_count <= 12'd0;
	else if(data_count == 12'd20)//start depth_conv
		depth_conv_count <= 12'd0;
	else
		depth_conv_count <= depth_conv_count + 12'd1;
end
//depth_conv = DATA * KERNEL
always @(posedge CLK) 
begin
	if(RESET)begin
		for(num_dc=0; num_dc<7 ; num_dc=num_dc+1)begin
			for(num_dc1=0; num_dc1<3 ; num_dc1=num_dc1+1)
				depth_conv[num_dc][num_dc1] <= 16'd0;
		end
	end else if(depth_conv_count > 12'd1593) begin
		for(num_dc=0; num_dc<7 ; num_dc=num_dc+1)begin
			for(num_dc1=0; num_dc1<3 ; num_dc1=num_dc1+1)
				depth_conv[num_dc][num_dc1] <= 16'd0;
		end
	end else begin
		for(num_dc=0; num_dc<7 ; num_dc=num_dc+1)begin
			for(num_dc1=0; num_dc1<3 ; num_dc1=num_dc1+1)
				depth_conv[num_dc][num_dc1] <= 
				DATA[(depth_conv_count + num_dc)%(depth_conv_count+7)][num_dc1] * KERNEL[num_dc][num_dc1];
		end
	end
end
//depth_feature = sum(depth_conv)
always @(posedge CLK) 
begin
	if(RESET)begin
		for(num_df=0; num_df<1594 ; num_df=num_df+1)begin
			for(num_df1=0; num_df1<3 ; num_df1=num_df1+1)
				depth_feature[num_df][num_df1] <= 16'd0;
		end
	end else if(depth_conv_count > 12'd1594)begin
		for(num_df=0; num_df<1594 ; num_df=num_df+1)begin
			for(num_df1=0; num_df1<3 ; num_df1=num_df1+1)
				depth_feature[num_df][num_df1] <= 16'd0;
		end
	end else begin
		for(num_df1=0; num_df1<3 ; num_df1=num_df1+1)begin
			depth_feature[depth_conv_count-1][num_df1] <= depth_conv[0][num_df1] + 
			depth_conv[1][num_df1] + depth_conv[2][num_df1] + depth_conv[3][num_df1] + 
			depth_conv[4][num_df1] + depth_conv[5][num_df1] + depth_conv[6][num_df1];
		end
	end
end
//relu_feature = relu(depth_feature)
always @(posedge CLK) 
begin
	if(RESET)begin
		for(num_relu=0; num_relu<1594 ; num_relu=num_relu+1)begin
			for(num_relu1=0; num_relu1<3 ; num_relu1=num_relu1+1)
				relu_feature[num_relu][num_relu1] <= 16'd0;
		end
	end else begin
		for(num_relu=0; num_relu<1594 ; num_relu=num_relu+1)begin
			for(num_relu1=0; num_relu1<3 ; num_relu1=num_relu1+1)begin
				if(depth_feature[num_relu][num_relu1] < 0)
					relu_feature[num_relu][num_relu1] <= 16'd0;
				else
					relu_feature[num_relu][num_relu1] <= depth_feature[num_relu][num_relu1];
			end
		end
	end
end
//store IN_KERNEL to point_KERNEL[0:2]  
always @(posedge CLK) 
begin
	if(RESET)begin
		point_KERNEL[0] <= 7'd0;
		point_KERNEL[1] <= 7'd0;
		point_KERNEL[2] <= 7'd0;
	end else if(kernal_count >= 21)begin
		point_KERNEL[(kernal_count-21)%3] <= IN_KERNEL;
	end
end

always @(posedge CLK) 
begin
	if(RESET)
		point_conv_count <= 12'd0;
	else if(data_count == 12'd23)//start point_conv
		point_conv_count <= 12'd0;
	else
		point_conv_count <= point_conv_count + 12'd1;
end
//point_conv = relu_feature[0:2] * point_KERNEL[0:2]
always @(posedge CLK) 
begin
	if(RESET)begin
		for(p1=0; p1<3 ; p1=p1+1)	point_conv[p1] <= 24'd0;
	end else if(point_conv_count > 12'd1593) begin
		for(p1=0; p1<3 ; p1=p1+1)	point_conv[p1] <= 24'd0;
	end else begin
		for(p1=0; p1<3 ; p1=p1+1)
			point_conv[p1] <= relu_feature[point_conv_count][p1] * point_KERNEL[p1];
	end
end
//point_feature = sum(point_conv)
always @(posedge CLK) 
begin
	if(RESET)begin
		for(num_point=0; num_point<12'd1594 ; num_point=num_point+1)
			point_feature[num_point] <= 24'd0;
	end else if(point_conv_count > 12'd1595)begin
		for(num_point=0; num_point<12'd1594 ; num_point=num_point+1)
			point_feature[num_point] <= 24'd0;
	end else begin
		point_feature[point_conv_count-1] <= point_conv[0] + point_conv[1] + point_conv[2];
	end
end
//relu_point_feature = relu(point_feature)
always @(posedge CLK) 
begin
	if(RESET)begin
		for(num_point_relu=0; num_point_relu<12'd1594 ; num_point_relu=num_point_relu+1)begin
			relu_point_feature[num_point_relu] <= 24'd0;
		end
	end else begin
		for(num_point_relu=0; num_point_relu<12'd1594 ; num_point_relu=num_point_relu+1)begin
			if(point_feature[num_point_relu]< 0)
				relu_point_feature[num_point_relu] <= 24'd0;
			else
				relu_point_feature[num_point_relu] <= point_feature[num_point_relu];
		end
	end
end

always @(posedge CLK) 
begin
	if(RESET)
		rlc_count <= 12'd0;
	else if(data_count == 12'd26)//start store RLC
		rlc_count <= 12'd0;
	else
		rlc_count <= rlc_count + 12'd1;
end
//RLC ready zero_count+level
always @(posedge CLK) 
begin
	if(RESET)begin
		zero_num <= 11'd0;
		not_zero_count <= 11'd0;
		for(num_rlc=0; num_rlc<12'd797 ; num_rlc=num_rlc+1)
			RLC[num_rlc] <= 16'd0;
	end
	else if(point_conv_count == 2)begin //(point_conv_count == 2) == (data_count == 12'd26) //start store RLC
		zero_num <= 11'd0; 
		not_zero_count <= 11'd2;
		for(num_rlc=0; num_rlc<12'd797 ; num_rlc=num_rlc+1)
			RLC[num_rlc] <= 16'd0;
	end else if(rlc_count==1593)begin //final
			not_zero_count <= not_zero_count + 2;
			RLC[not_zero_count - 1][14:0] <= relu_point_feature[rlc_count][14:0];
			RLC[not_zero_count - 1][15] <= ~relu_point_feature[rlc_count][15];	
			zero_num <= 11'd0;
			if(relu_point_feature[rlc_count] == 0)
				RLC[not_zero_count - 2] <= zero_num + 1;
			else
				RLC[not_zero_count - 2] <= zero_num;		
	end else if((rlc_count >= 0) && (rlc_count < 1593))begin
		if(relu_point_feature[rlc_count] == 0)begin
			zero_num <= zero_num + 1;
		end else if(relu_point_feature[rlc_count] > 0)begin
			not_zero_count <= not_zero_count + 2;
			RLC[not_zero_count - 1] <= relu_point_feature[rlc_count][15:0];
			RLC[not_zero_count - 2] <= zero_num;
			zero_num <= 11'd0;
		end
	end else begin // start output (> 31 case)
		if((RLC[out_count] > 16'd31) && (out_clk == 1) && (out_term_count != 6))begin
			RLC[out_count] <= RLC[out_count] - 16'd31;
			RLC[out_count - 1] <= 16'd0;
		end
	end
end
//ready term
always @(posedge CLK) 
begin
	if(RESET)
		out_term_count <= 3'd0;
	else if(rlc_count == 1594) // start term count
		out_term_count  <= 3'd0;
	else if(out_term_count == 6)
		out_term_count <= 3'd0;
	else
		out_term_count <= out_term_count + 3'd1;
end
//ready output rlc clk(run or level)
always @(posedge CLK) 
begin
	if(RESET)
		out_clk <= 2'd0;
	else if(rlc_count <= 1595)
		out_clk  <= 2'd0;
	else if(out_term_count == 6)
		out_clk <= out_clk;
	else if(out_clk == 1)
		out_clk <= 2'd0;
	else
		out_clk <= 2'd1;
end
//output OUT_DATA & OUT_VALID
always @(posedge CLK) 
begin
	if(RESET)begin
		OUT_DATA <= 16'd0;
		out_count <= 12'd0;
		OUT_VALID <=1'd0;
	end
	else if(rlc_count > 1594) begin // start output
		if((RLC[out_count] > 31) && (out_clk == 1))begin //(> 31 case)
			out_count <= out_count - 1;
			OUT_DATA <= 16'd31;
			OUT_VALID <=1'd1;
			if(out_term_count == 6)begin
				OUT_DATA <= 16'd1;
				out_count  <= out_count;
			end
		end
		else if((RLC[out_count][15] == 1)) begin//final term output
			OUT_DATA <= 16'd0;
			OUT_VALID <=1'd1;
			out_count <= out_count + 1;
		end
		else if((RLC[out_count - 1][15] == 1)) begin//final output(run + level)
			OUT_DATA <= 16'd0;
			out_count <= out_count;
			if(out_term_count == 0)begin//final output end
				OUT_VALID <=1'd0;
			end
		end
		else begin
			out_count  <= out_count + 1;
			OUT_DATA <= RLC[out_count];
			OUT_VALID <=1'd1;
			if(out_term_count == 6)begin
				OUT_DATA <= 16'd1;
				out_count <= out_count;
			end
		end
	end
end

endmodule