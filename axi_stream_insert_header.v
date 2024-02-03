`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/02/02 09:54:31
// Design Name: 
// Module Name: axi_stream_insert_header
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


module axi_stream_insert_header#(
    parameter DATA_WD = 32,
    parameter DATA_BYTE_WD = DATA_WD / 8,
    parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
    )(
    input 						clk,
    input 						rst_n,
    // AXI Stream input original data
    input 						valid_in,
    input [DATA_WD-1 : 0]		data_in,
    input [DATA_BYTE_WD-1 : 0]	keep_in,
    input 						last_in,
    output 						ready_in,
    // AXI Stream output with header inserted
    output 						valid_out,
    output [DATA_WD-1 : 0] 		data_out,
    output [DATA_BYTE_WD-1 : 0] keep_out,
    output 						last_out,
    input 						ready_out,
    // The header to be inserted to AXI Stream input
    input 						valid_insert,
    input [DATA_WD-1 : 0] 		header_insert,
    input [DATA_BYTE_WD-1 : 0] 	keep_insert,
    input [BYTE_CNT_WD : 0] 	byte_insert_cnt,
    output 						ready_insert
);
// Your code here

reg 						last_in_r1		= 'd0	;
reg 						last_in_r2		= 'd0	;
wire 						last_in_pulse_p		 	;
reg [DATA_WD-1 : 0] 		data_out_r1		= 'd0	;//缓存数据
reg [DATA_WD-1 : 0] 		data_out_r2		= 'd0	;
reg [DATA_BYTE_WD-1 : 0] 	keep_in_r		= 'd0	;
wire 						axis_ready_in			;
//////////////////实现data_out传输//////////////////////////

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		last_in_r1 <= 'd0;
		last_in_r2 <= 'd0;
	end
	else begin
		last_in_r1 <= last_in;
		last_in_r2 <= last_in_r1;
	end
end

assign last_in_pulse_p = ~last_in_r1 & last_in_r2;
assign axis_ready_in = last_in_pulse_p ? 1'b0 : 1'b1;
assign ready_in = axis_ready_in;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		keep_in_r	<= 'd0;
		data_out_r1 <= 'd0;
		data_out_r2 <= 'd0;
	end
	else if(valid_in && axis_ready_in)begin
		keep_in_r 	<= keep_in;
		data_out_r1 <= data_in;
		data_out_r2 <= data_out_r1;
	end
	else begin
		keep_in_r	<= keep_in_r;
		data_out_r1 <= data_out_r1;
		data_out_r2 <= data_out_r2;
	end
end


//////////////实现header数据处理/////////////////////////////
reg [DATA_WD-1 : 0]		header_out_r		= 'd0;
reg 					insert_flag			= 'd0;
reg [DATA_BYTE_WD-1 : 0]keep_insert_out_r	= 'd0;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		header_out_r 		<= 'd0;
		insert_flag 		<= 'd0;
		keep_insert_out_r	<= 'd0;
	end
	else if(valid_insert && ready_insert)begin
		case(keep_insert)
		4'b1111:begin 
			header_out_r<=header_insert;
			insert_flag<='d1;end
		4'b0111:begin 
			header_out_r<={8'b0,header_insert[23:0]};
			insert_flag<='d1;end
		4'b0011:begin 
			header_out_r<={16'b0,header_insert[15:0]};
			insert_flag<='d1;end
		4'b0001:begin 
			header_out_r<={24'b0,header_insert[7:0]};
			insert_flag<='d1;end
		default:begin 
			header_out_r<=header_out_r;
			insert_flag<='d1;end
		endcase
		keep_insert_out_r <= keep_insert;
	end
	else if(insert_flag)
		insert_flag <= 'd0;
end

////////////header插入到data////////////////

reg [DATA_WD-1 : 0]	header_data_out_r	= 'd0;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		header_data_out_r <= 'd0;
	end
	/* else if(insert_flag)begin
		case(keep_insert)
		4'b1111:begin header_data_out_r<=header_out_r;insert_flag<=0; end
		4'b0111:begin header_data_out_r<={header_insert[23:0],data_out_r1[31:24]};insert_flag<=0;end
		4'b0011:begin header_data_out_r<={header_insert[15:0],data_out_r1[31:16]};insert_flag<=0;end
		4'b0001:begin header_data_out_r<={header_insert[7:0],data_out_r1[31:8]};insert_flag<=0;end
		default:begin header_data_out_r<=header_data_out_r;insert_flag<=0; end
		endcase
	end */
	else if(insert_flag)begin
		case(keep_insert)
		4'b1111: header_data_out_r<=header_out_r;
		4'b0111: header_data_out_r<={header_insert[23:0],data_out_r1[31:24]};
		4'b0011: header_data_out_r<={header_insert[15:0],data_out_r1[31:16]};
		4'b0001: header_data_out_r<={header_insert[7:0],data_out_r1[31:8]};
		default: header_data_out_r<=header_data_out_r;
		endcase
	end
	//else if(last_in_pulse_p)
	else begin
        case(keep_insert_out_r)
        4'b1111:begin header_data_out_r<=data_out_r2; end
        4'b0111:begin header_data_out_r<={data_out_r2[23:0],data_out_r1[31:24]};end
        4'b0011:begin header_data_out_r<={data_out_r2[15:0],data_out_r1[31:16]};end
        4'b0001:begin header_data_out_r<={data_out_r2[7:0],data_out_r1[31:8]};end
        default:begin header_data_out_r<=header_data_out_r; end
		endcase
    end
end

/*
else
begin
    header_data_out_r<=header_data_out_r;
end
*/
reg s_ready_insert	= 'd0;
assign data_out = ready_out ? header_data_out_r : data_out_r2;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        s_ready_insert <= 'd0;
    else
        s_ready_insert <= insert_flag=='d1 ? 'd0 : 'd1;
end
assign ready_insert	=	s_ready_insert;

//////////判断valid_out
reg [1:0]insert_flag_r;
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        insert_flag_r <= 'd0;
    else
        insert_flag_r <= {insert_flag_r[0], insert_flag};
end
assign neg_flag = ~insert_flag_r[1] & insert_flag_r[0];
assign valid_out = neg_flag ? 'd0 : 'd1;

//////////判断keep_out输出
wire last_out_p;
reg [DATA_BYTE_WD-1 : 0] keep_out_r	= 'd0;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        keep_out_r	<= 'd0;
    else if(valid_out)
        keep_out_r 	<= 4'b1111;
    else if(last_out_p)begin
        case(keep_insert)
            4'b1111: keep_out_r <= keep_in_r;
            4'b0111: keep_out_r <= keep_in_r<<1;
            4'b0011: keep_out_r <= keep_in_r<<2;
            4'b0001: keep_out_r <= keep_in_r<<3;
        endcase
    end
    else
        keep_out_r	<= 'd0;
end
assign keep_out = keep_out_r;

/////////判断last_out
reg [1:0]last_out_r;

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        last_out_r <= 'd0;
    else 
    begin
        last_out_r <= {last_out_r[0],last_in_pulse_p};
    end

end

assign last_out_p = ~last_out_r[0]&last_out_r[1];
assign last_out = last_out_p;




endmodule