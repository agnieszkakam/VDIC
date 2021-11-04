`timescale 1ns/1ps

/*
 Copyright 2013 Ray Salemi

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

////////////////////////////////////////////////////////////////////////////////
// Copyright (C) 1999-2008 Easics NV.
// This source file may be used and distributed without restriction
// provided that this copyright statement is not removed from the file
// and that any derivative work contains the original copyright notice
// and the associated disclaimer.
//
// THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
// WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
//
// Purpose : synthesizable CRC function
//   - polynomial: x^4 + x^1 + 1
//   - data width: 68
//   - convention: the first serial bit is D[67]

// Info : tools@easics.be
//        http://www.easics.com
////////////////////////////////////////////////////////////////////////////////

module top;

	/**
	 * User defined types
	 */

	typedef enum bit[2:0] {
		AND_OP       = 3'b000,
		OR_OP        = 3'b001,
		ADD_OP       = 3'b100,
		SUB_OP       = 3'b101,
		RST_OP       = 3'b110,
		INVALID_OP   = 3'b111
	} operation_t;

	typedef enum bit {
		DATA = 1'b0,
		CMD = 1'b1
	} packet_t;

	typedef enum bit [2:0] {
		ERR_DATA    = 3'b100,
		ERR_CRC     = 3'b010,
		ERR_OP      = 3'b001
	} processing_error_t;


	/**
	 * Local variables, parameters and signals
	 */

	localparam start_bit = 1'b0;
	localparam stop_bit = 1'b1;

	bit clk;
	bit rst_n;
	bit sin, sout;

	logic  [31:0]  A, B, rcv_data;
	logic  [7:0]   rcv_control_packet, error_response;
	bit done, error_state;

	processing_error_t error_code;
	operation_t op_set;
	string test_result = "PASSED";


	/**
	 * DUT instantiation
	 */

	mtm_Alu DUT (.clk, .rst_n, .sin, .sout);


	/**
	 * Coverage block
	 */

	// Covergroup checking the op codes and their sequences
	covergroup op_cov;

		option.name = "cg_op_cov";

		coverpoint op_set {
			// #A1 test all operations
			bins A1_all_op[] = {[AND_OP : SUB_OP]};

			// #A2 test all operations after reset
			bins A2_rst_opn[]      = (RST_OP => [AND_OP : SUB_OP]);

			// #A3 test reset after all operations
			bins A3_opn_rst[]      = ([AND_OP : SUB_OP] => RST_OP);

			// #A4 two operations in row
			bins A4_twoops[]       = ([AND_OP : SUB_OP] [* 2]);

		}

	endgroup

	// Covergroup checking for specific data corners
	covergroup data_corners;

		option.name = "cg_specific_data_corners";

		all_ops : coverpoint op_set {
			ignore_bins null_ops = {RST_OP, INVALID_OP};
		}

		a_leg: coverpoint A {
			bins zeros = {32'h0000_0000};
			bins others= {[32'h0000_0001 : 32'hFFFF_FFFE]};
			bins ones  = {32'hFFFF_FFFF};
		}

		b_leg: coverpoint B {
			bins zeros = {32'h0000_0000};
			bins others= {[32'h0000_0001 : 32'hFFFF_FFFE]};
			bins ones  = {32'hFFFF_FFFF};
		}

		error_leg: coverpoint error_code	{
			bins err_data = {ERR_DATA};
			bins err_crc = {ERR_CRC};
			bins err_op = {ERR_OP};
		}

		c_zeros_ones: cross a_leg, b_leg, all_ops, error_leg {

			// #C1 simulate all zero input for all the operations

			bins C1_add_zeros          = binsof (all_ops) intersect {ADD_OP} &&
			(binsof (a_leg.zeros) || binsof (b_leg.zeros));

			bins C1_and_zeros          = binsof (all_ops) intersect {AND_OP} &&
			(binsof (a_leg.zeros) || binsof (b_leg.zeros));

			bins C1_or_zeros          = binsof (all_ops) intersect {OR_OP} &&
			(binsof (a_leg.zeros) || binsof (b_leg.zeros));

			bins C1_sub_zeros          = binsof (all_ops) intersect {SUB_OP} &&
			(binsof (a_leg.zeros) || binsof (b_leg.zeros));

			// #C2 simulate all one input for all the operations

			bins C2_add_ones          = binsof (all_ops) intersect {ADD_OP} &&
			(binsof (a_leg.ones) || binsof (b_leg.ones));

			bins C2_and_ones          = binsof (all_ops) intersect {AND_OP} &&
			(binsof (a_leg.ones) || binsof (b_leg.ones));

			bins C2_or_ones           = binsof (all_ops) intersect {OR_OP} &&
			(binsof (a_leg.ones) || binsof (b_leg.ones));

			bins C2_sub_ones          = binsof (all_ops) intersect {SUB_OP} &&
			(binsof (a_leg.ones) || binsof (b_leg.ones));

			bins C2_add_ones_max      = binsof (all_ops) intersect {ADD_OP} &&
			(binsof (a_leg.ones) && binsof (b_leg.ones));

			ignore_bins others_only   =	binsof(a_leg.others) && binsof(b_leg.others);
			
			// #C4 simulate invalid OP on an input 

			bins C4_invalid_op        = binsof (error_leg.err_op);

			// #C5 simulate invalid CRC on an input for all operations 

			bins C5_invalid_crc_add   = binsof (all_ops) intersect {ADD_OP} &&
			binsof (error_leg.err_crc);
			
			bins C5_invalid_crc_and   = binsof (all_ops) intersect {AND_OP} &&
			binsof (error_leg.err_crc);
			
			bins C5_invalid_crc_or    = binsof (all_ops) intersect {OR_OP} &&
			binsof (error_leg.err_crc);
			
			bins C5_invalid_crc_sub   = binsof (all_ops) intersect {SUB_OP} &&
			binsof (error_leg.err_crc);
			
			// #C6 simulate invalid DATA on an input for all operations 

			bins C6_invalid_crc_add   = binsof (all_ops) intersect {ADD_OP} &&
			binsof (error_leg.err_data);
			
			bins C6_invalid_crc_and   = binsof (all_ops) intersect {AND_OP} &&
			binsof (error_leg.err_data);
			
			bins C6_invalid_crc_or    = binsof (all_ops) intersect {OR_OP} &&
			binsof (error_leg.err_data);
			
			bins C6_invalid_crc_sub   = binsof (all_ops) intersect {SUB_OP} &&
			binsof (error_leg.err_data);
		}

	endgroup

	op_cov                      oc;
	data_corners        c_data_corn;

	initial begin : coverage
		oc      = new();
		c_data_corn = new();
		
		forever begin : sample_cov
			@(posedge clk);
			if(done || !rst_n) begin
				oc.sample();
				c_data_corn.sample();
			end
		end
	end : coverage


	/**
	 * Tasks and functions definitions
	 */

	function bit IsOverflow;
		input [31:0] A, B, result;
		input operation_t opcode;
		begin
			case(opcode)
				ADD_OP:     IsOverflow = ((!A[31] && !B[31] && result[31]) || (A[31] && B[31] && !result[31]));
				SUB_OP:     IsOverflow = (1'b1 ~^ !A[31] ~^ B[31]) && (!A[31] ^ result[31]);
				default:    IsOverflow = 1'b0;
			endcase
		end
	endfunction

	task generate_parity_bit(output bit parity_bit, input logic [6:0] data);
		begin
			automatic logic [2:0] sum = 3'b0;
			for(int bit_nr = 0; bit_nr < 7; bit_nr++) begin
				sum = (data[bit_nr]) ? sum++ : sum;
			end
			parity_bit = !(sum % 2);
		end
	endtask

//   - polynomial: x^4 + x^1 + 1
//   - data width: 68
//   - convention: the first serial bit is D[67]
	function [3:0] CRC4_D68;

		input [67:0] Data;
		input [3:0] crc;
		reg [67:0] d;
		reg [3:0] c;
		reg [3:0] newcrc;
		begin
			d = Data;
			c = crc;

			newcrc[0] = d[66] ^ d[64] ^ d[63] ^ d[60] ^ d[56] ^ d[55] ^ d[54] ^ d[53] ^ d[51] ^ d[49] ^ d[48] ^ d[45] ^ d[41] ^ d[40] ^ d[39] ^ d[38] ^ d[36] ^ d[34] ^ d[33] ^ d[30] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ d[19] ^ d[18] ^ d[15] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[4] ^ d[3] ^ d[0] ^ c[0] ^ c[2];
			newcrc[1] = d[67] ^ d[66] ^ d[65] ^ d[63] ^ d[61] ^ d[60] ^ d[57] ^ d[53] ^ d[52] ^ d[51] ^ d[50] ^ d[48] ^ d[46] ^ d[45] ^ d[42] ^ d[38] ^ d[37] ^ d[36] ^ d[35] ^ d[33] ^ d[31] ^ d[30] ^ d[27] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[18] ^ d[16] ^ d[15] ^ d[12] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[1] ^ d[0] ^ c[1] ^ c[2] ^ c[3];
			newcrc[2] = d[67] ^ d[66] ^ d[64] ^ d[62] ^ d[61] ^ d[58] ^ d[54] ^ d[53] ^ d[52] ^ d[51] ^ d[49] ^ d[47] ^ d[46] ^ d[43] ^ d[39] ^ d[38] ^ d[37] ^ d[36] ^ d[34] ^ d[32] ^ d[31] ^ d[28] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[17] ^ d[16] ^ d[13] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[2] ^ d[1] ^ c[0] ^ c[2] ^ c[3];
			newcrc[3] = d[67] ^ d[65] ^ d[63] ^ d[62] ^ d[59] ^ d[55] ^ d[54] ^ d[53] ^ d[52] ^ d[50] ^ d[48] ^ d[47] ^ d[44] ^ d[40] ^ d[39] ^ d[38] ^ d[37] ^ d[35] ^ d[33] ^ d[32] ^ d[29] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[18] ^ d[17] ^ d[14] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[3] ^ d[2] ^ c[1] ^ c[3];
			CRC4_D68 = newcrc;
		end
	endfunction

// polynomial: x^3 + x^1 + 1
// data width: 37
// convention: the first serial bit is D[36]
	function [2:0] CRC3_D37;

		input [36:0] Data;
		input [2:0] crc;
		reg [36:0] d;
		reg [2:0] c;
		reg [2:0] newcrc;
		begin
			d = Data;
			c = crc;

			newcrc[0] = d[35] ^ d[32] ^ d[31] ^ d[30] ^ d[28] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ d[18] ^ d[17] ^ d[16] ^ d[14] ^ d[11] ^ d[10] ^ d[9] ^ d[7] ^ d[4] ^ d[3] ^ d[2] ^ d[0] ^ c[1];
			newcrc[1] = d[36] ^ d[35] ^ d[33] ^ d[30] ^ d[29] ^ d[28] ^ d[26] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[16] ^ d[15] ^ d[14] ^ d[12] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[2] ^ d[1] ^ d[0] ^ c[1] ^ c[2];
			newcrc[2] = d[36] ^ d[34] ^ d[31] ^ d[30] ^ d[29] ^ d[27] ^ d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[17] ^ d[16] ^ d[15] ^ d[13] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[3] ^ d[2] ^ d[1] ^ c[0] ^ c[2];
			CRC3_D37 = newcrc;
		end
	endfunction

	task send_packet (input packet_t packet_type, byte data_byte);
		begin
			automatic logic [10:0] packet = {start_bit, packet_type, data_byte, stop_bit};

			for (int i = 0; i < 11; i++) begin
				@(negedge clk) ;
				sin = packet[10 - i];
			end
		end
	endtask

	task process_instruction (input logic  [31:0] A, input logic  [31:0] B, input operation_t opcode);
		begin
			logic [3:0] crc;

			for (int i = 3; i >= 0; i--) begin
				send_packet(DATA, B [8*i +: 8]);
			end

			for (int i = 3; i >= 0; i--) begin
				send_packet(DATA, A [8*i +: 8]);
			end

			crc = CRC4_D68({B, A, 1'b1, opcode}, 4'b0);
			send_packet(CMD, {1'b0, opcode, crc});
		end
	endtask

	task receive_packet (output byte rcv_byte, output packet_t packet_type);
		begin
			@(negedge sout) ;

			for (int i = 0; i < 2; i++)
				@(negedge clk) ;

			packet_type = (sout == 1'b1) ? CMD : DATA;

			for (int i = 7; i >= 0; i--) begin
				@(negedge clk) ;
				rcv_byte[i] = sout;
			end

			@(negedge clk) ;
		end
	endtask

	task process_ALU_response (output logic  [31:0] data, logic [7:0] ctl);
		begin
			logic [39:0] maximum_response;
			automatic logic [2:0] i = 3'd4;
			packet_t packet;

			do begin
				receive_packet(maximum_response [8*i +: 8], packet);
				i--;
			end while (packet == DATA);

			if (i == 3'b111) begin                      //i - roll over
				data = maximum_response[39:8];
				ctl = maximum_response[7:0];
			end
			else begin
				ctl = maximum_response[39:32];
			end
		end

		done = 1'b1;
		@(negedge clk) ;
		done = 1'b0;

	endtask

	task test_alu_processing_error (output logic [7:0] ctl, input processing_error_t Alu_error);
		begin
			automatic logic [31:0] A = 32'($urandom), B = 32'($urandom);
			operation_t  operation;
			packet_t ALU_reponse_type;
			logic [31:0] ALU_data;
			logic [5:0] err_flags;
			logic [3:0] crc;
			bit parity_bit;

			case(Alu_error)
				ERR_DATA:
				begin
					automatic logic [2:0] nr_of_packets = 2'($urandom_range(3,0));
					operation = get_op();

					for (int i = nr_of_packets; i >= 0; i--) begin
						send_packet(DATA, B [8*i +: 8]);
					end
					nr_of_packets = 2'($urandom_range(2,0));
					for (int i = nr_of_packets; i >= 0; i--) begin
						send_packet(DATA, A [8*i +: 8]);
					end
					crc = CRC4_D68({B, A, 1'b1, operation}, 4'b0);
					send_packet(CMD, {1'b0, operation, crc});
				end

				ERR_OP:
				begin
					operation = operation_t'(3'($urandom_range(7,6)));
					process_instruction(A,B,operation);
				end

				ERR_CRC:
				begin
					operation = get_op();

					for (int i = 3; i >= 0; i--) begin
						send_packet(DATA, B [8*i +: 8]);
					end
					for (int i = 3; i >= 0; i--) begin
						send_packet(DATA, A [8*i +: 8]);
					end

					crc = CRC4_D68({B, A, 1'b1, operation}, 4'b0);
					send_packet(CMD, {1'b0, operation, ~crc});
				end
			endcase

			process_ALU_response(ALU_data,ctl);

		end
	endtask

	task reset_alu();

		  `ifdef DEBUG
		$display("*** ALU RESET ***");
		   `endif

		rst_n = 1'b0;
		@(negedge clk) ;
		rst_n = 1'b1;

		sin = 1'b1;
		done = 1'b0;
		error_state = 1'b0;
	endtask

	function [31:0] get_data();
		bit [1:0] zero_ones;
		zero_ones = 2'($urandom);
		if (zero_ones == 2'b00)
			return 32'h00;
		else if (zero_ones == 2'b11)
			return 32'hFFFF_FFFF;
		else
			return 32'($urandom);
	endfunction : get_data

	function operation_t get_op();
		automatic bit [2:0] op_choice = $random;
		case (op_choice)
			3'b000, 3'b001, 3'b100, 3'b101, 3'b110 : return operation_t'(op_choice);
			default: return INVALID_OP;
		endcase // case (op_choice)
	endfunction : get_op

	task get_error_code (output processing_error_t error_code);
		begin
			error_code = processing_error_t'(3'b000);
			error_code[$urandom_range(2,0)] = 1'b1;
		end
	endtask

	task get_expected_result ( output logic [31:0] result_data, logic [7:0] result_ctl, input bit  [31:0] A, bit  [31:0] B, operation_t op_set);
		begin

			logic  [32:0] result_data_33b;

			case(op_set)
				AND_OP: begin
					result_data = A & B;
					result_data_33b = A & B;
					result_ctl[7] = 1'b0;
					result_ctl[6:3] = {result_data_33b[32], IsOverflow(A, B, result_data, op_set), (result_data == 0), result_data[31]};        /*Carry, Overflow, Zero, Negative*/
					result_ctl[2:0] = CRC3_D37({result_data, 1'b0, result_ctl[6:3]}, 3'b0);
				end
				ADD_OP: begin
					result_data = A + B;
					result_data_33b = A + B;
					result_ctl[7] = 1'b0;
					result_ctl[6:3] = {result_data_33b[32], IsOverflow(A, B, result_data, op_set), (result_data == 0), result_data[31]};
					result_ctl[2:0] = CRC3_D37({result_data, 1'b0, result_ctl[6:3]}, 3'b0);
				end
				OR_OP : begin
					result_data = A | B;
					result_data_33b = A | B;
					result_ctl[7] = 1'b0;
					result_ctl[6:3] = {result_data_33b[32], IsOverflow(A, B, result_data, op_set), (result_data == 0), result_data[31]};
					result_ctl[2:0] = CRC3_D37({result_data, 1'b0, result_ctl[6:3]}, 3'b0);
				end
				SUB_OP: begin
					result_data = B - A;
					result_data_33b = B - A;
					result_ctl[7] = 1'b0;
					result_ctl[6:3] = {result_data_33b[32], IsOverflow(A, B, result_data, op_set), (result_data == 0), result_data[31]};
					result_ctl[2:0] = CRC3_D37({result_data, 1'b0, result_ctl[6:3]}, 3'b0);
				end
				INVALID_OP  : begin
					result_ctl[7] = 1'b1;
					result_ctl[6:1] = {2{ERR_OP}};
					generate_parity_bit(result_ctl[0], result_ctl[7:1]);
				end
				RST_OP: begin end
				default: begin
					$display("%0t INTERNAL ERROR. get_expected_result_data: unexpected case argument: %s", $time, op_set);
					test_result = "FAILED";
				end
			endcase
		end
	endtask

	task get_expected_error_packet (output logic [7:0] exp_error_packet, input processing_error_t error_type);
		begin
			bit parity_bit;
			automatic logic [5:0] err_flags = {2{error_type}};

			generate_parity_bit(parity_bit, {1'b1,err_flags});
			exp_error_packet = {1'b1, err_flags, parity_bit};
		end
	endtask


	/**
	 * Clock generator
	 */

	initial begin : clk_gen
		clk = 0;
		forever begin : clk_frv
			#10;
			clk = ~clk;
		end
	end


	/**
	 * Test
	 */

	initial begin : tester

		reset_alu();

		repeat (500) begin : tester_main
			@(negedge clk) ;
			op_set = get_op();
			A      = get_data();
			B      = get_data();

			@(negedge clk) ;

			case (op_set)
				RST_OP: begin : rst_op
					reset_alu();
				end
				default: begin : norm_op
					process_instruction(A, B, op_set);
					process_ALU_response(rcv_data, rcv_control_packet);
				end
			endcase

		// print coverage after each loop
		// $strobe("%0t coverage: %.4g\%",$time, $get_coverage());
		// if($get_coverage() == 100) break;
		end

		@(negedge clk) ;

		repeat(500) begin   : tester_errors
			op_set = get_op();
			A      = get_data();
			B      = get_data();

			error_state = 1'b1;
			get_error_code(error_code);
			test_alu_processing_error(error_response, error_code);
			error_state = 1'b0;

		end

		$finish;
	end : tester


	/**
	 * Scoreboard
	 */

	always @(negedge clk) begin : scoreboard
		if(done) begin : verify_result
			logic [31:0] expected_data;
			logic [7:0]  expected_ctl_packet, exp_error_response;

			get_expected_result(expected_data, expected_ctl_packet, A, B, op_set);
			get_expected_error_packet(exp_error_response, error_code);

			@(posedge clk) ;
			case (error_state)
				1'b0: begin : CHK_RESULT_AND_CTL
					assert(rcv_data === expected_data) begin
		   `ifdef DEBUG
						$display("%0t Test passed for A=%08x B=%08x op_set=%s (data)", $time, A, B, op_set.name);
		   `endif
					end
					else begin
						$warning("%0t Test FAILED for A=%08x B=%08x op_set=%s (data)\nexp: %08x  rcv: %08x",
							$time, A, B, op_set.name, expected_data, rcv_data);
						test_result = "FAILED";
					end;

					assert(rcv_control_packet === expected_ctl_packet) begin
		   `ifdef DEBUG
						$display("%0t Test passed for A=%08x B=%08x op_set=%s (ctl)", $time, A, B, op_set.name);
		   `endif
					end
					else begin
						$warning("%0t Test FAILED for A=%08x B=%08x op_set=%s (ctl)\nexp: %08x  rcv: %08x",
							$time, A, B, op_set.name, expected_ctl_packet, rcv_control_packet);
						test_result = "FAILED";
					end;
				end

				1'b1: begin : CHK_ERR
					assert(exp_error_response === error_response) begin
		   `ifdef DEBUG
						$display("%0t Test passed for A=%08x B=%08x op_set=%s (%s)", $time, A, B, op_set.name, error_code.name);
		   `endif
					end
					else begin
						$warning("%0t Test FAILED for A=%08x B=%08x op_set=%s (%s)\nexp: %08b  rcv: %08b",
							$time, A, B, op_set.name, error_code.name, exp_error_response, error_response);
						test_result = "FAILED";
					end;
				end
			endcase
		end
	end : scoreboard

	final begin : finish_of_the_test
		$display("Test %s.",test_result);
	end

endmodule : top