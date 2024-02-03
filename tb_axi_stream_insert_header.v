`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/02/03 11:39:23
// Design Name: 
// Module Name: tb_axi_stream_insert_header
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


module tb_axi_stream_insert_header(

    );
parameter DATA_DEPTH =256;
parameter DATA_WD = 32;
parameter DATA_BYTE_WD = DATA_WD / 8;
parameter DATA_CNT=DATA_DEPTH / DATA_WD;
parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD);

reg	clk		= 'd0;
reg	rst_n	= 'd0;
initial begin
	clk		= 'd0;
	rst_n	= 'd0;
	
	#20 rst_n = 'd1;
end
always #10 clk = !clk;
	

// AXI Stream input original data
reg 					valid_in	= 'd1;
reg [DATA_WD-1 : 0] 	data_in		= 'd0;
reg [DATA_BYTE_WD-1 : 0]keep_in		= 4'b1111;
reg 					last_in		= 'd0;
wire ready_in;
// AXI Stream output with header inserted
wire valid_out;
wire [DATA_WD-1 : 0] data_out;
wire [DATA_BYTE_WD-1 : 0] keep_out;
wire last_out;
reg 					ready_out	= 'd1;
// The header to be inserted to AXI Stream input
reg 					valid_insert= 'd0;
reg [DATA_WD-1 : 0] 	header_insert='d0;
reg [DATA_BYTE_WD-1 : 0]keep_insert = 'd0;
wire 					ready_insert;
reg [3:0]				cnt			= 'd0;
reg	[3:0]				cnt1		= 'd0;


reg [3:0]rand_interval;
always@(posedge clk)begin
     rand_interval = $random % 10+6;
     repeat (rand_interval) @(posedge clk);
     valid_in <= 'd0;
     repeat (1) @(posedge clk);
     valid_in <= 'd1;
end

reg [3:0]interval;
always@(posedge clk)begin
     interval = $random % 10+6;
     repeat (interval) @(posedge clk);
     ready_out <= 'd0;
     repeat (1) @(posedge clk);
     ready_out <= 'd1;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        data_in <= 'd0;
    else if(valid_in && ready_in)
        data_in <= {$random}%2**(DATA_WD-1)-1;    
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        cnt <= 'd0;
    else 
        cnt <= cnt=='d10 ? 'd0 : cnt+'d1;
end
   
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        header_insert	<= {$random}%2**(DATA_WD-1)-1;
    else if(cnt == 'd7)
        valid_insert	<= 'd1;
    else if(cnt == 'd9)begin
        header_insert 	<= {$random}%2**(DATA_WD-1)-1;
        valid_insert	<= 'd0;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        cnt1 <= 'd0;
    else 
        cnt1 <= cnt1=='d8 ? 'd0 : cnt+'d1;
end
   
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        last_in = 'd0;
    else if(cnt == 'd8)
        last_in = 'd1;
    else
        last_in = 'd0;
end
reg [2:0]	num	= 'd0;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        keep_insert <= 'd0;
    end
    else begin
        num ={$random}%4;
        if(num == 'd0)
            keep_insert<=4'b1111;
		else if(num == 'd1)
            keep_insert<=4'b0111;
        else if(num == 'd2)
            keep_insert<=4'b0011;
        else
            keep_insert<=4'b0001;
    end
end

axi_stream_insert_header axi_stream_insert_header_u0(
	.clk			( clk			),
	.rst_n			( rst_n			),
	.valid_in		( valid_in		),
	.data_in		( data_in		),
	.keep_in		( keep_in		),
	.last_in		( last_in		),
	.ready_in		( ready_in		),
	.valid_out		( valid_out		),
	.data_out		( data_out		),
	.keep_out		( keep_out		),
	.last_out		( last_out		),
	.ready_out		( ready_out		),
	.valid_insert	( valid_insert	),
	.header_insert	( header_insert	),
	.keep_insert	( keep_insert	),
	.ready_insert	( ready_insert	)
);
endmodule
