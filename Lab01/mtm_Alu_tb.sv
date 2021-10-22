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

	reg [31:0]  result;         //TODO move to 'tester' block?
	operation_t op_set;
	string test_result = "PASSED";


	/**
	 * DUT instantiation
	 */

	mtm_Alu DUT (.clk, .rst_n, .sin, .sout);


	/**
	 * Tasks and functions definitions
	 */

	function bit IsOverflow;
		input [31:0] A, B, result;
		input operation_t opcode;
		begin
			case(opcode)
				ADD_OP:     begin
					IsOverflow = ((!A[31] && !B[31] && result[31]) || (A[31] && B[31] && !result[31]));
				end
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

	task receive_packet (output byte data_byte);
		begin
			logic [10:0] full_packet;
			full_packet = 11'b0;

			@(negedge sout) ;
			for (int i = 10; i >= 0; i--) begin
				@(negedge clk) ;
				full_packet[i] = sout;
			end

			data_byte = full_packet [8:1];
		end
	endtask

	task process_ALU_response (output logic  [31:0] C, logic [3:0] flags, logic [2:0] crc);
		begin
			logic [7:0] ctl_response;

			for (int i = 3; i >= 0; i--) begin
				receive_packet(C [8*i +: 8]);
			end

			receive_packet(ctl_response);
			{flags, crc} = ctl_response [6:0];
		end
	endtask

	task test_alu_processing_error (/*output logic [7:0] ctl,*/ input processing_error_t Alu_error);
		begin
			automatic logic [31:0] A = 32'($urandom), B = 32'($urandom);  
			operation_t  operation;
			logic [7:0] exp_ALU_reponse, ALU_reponse;
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
			//default:  //other errors not supported - handle it (instructions below should not be executed if invalid)
			// check if Alu supports merged errors, e.g. ERR_CRC+ERR_OP
			endcase

			receive_packet(ALU_reponse);
			get_expected_error_packet(exp_ALU_reponse,Alu_error);
			assert (ALU_reponse === exp_ALU_reponse) else begin
				$error("Test FAILED for ALU Processing Error testing: exp:%08b, rcv:%08b", exp_ALU_reponse, ALU_reponse);
			end;
		end
	endtask

//move this task to the end of tasks list
	task get_expected_error_packet (output logic [7:0] exp_error_packet, input processing_error_t error_type);
		begin
			bit parity_bit;
			automatic logic [5:0] err_flags = {2{error_type}};

			generate_parity_bit(parity_bit, {1'b1,err_flags});
			exp_error_packet = {1'b1, err_flags, parity_bit};
		end
	endtask

	task reset_alu();
		rst_n = 1'b0;
		@(negedge clk) ;
		rst_n = 1'b1;
		sin = 1'b1;
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
		bit [2:0] op_choice;
		op_choice = $random;
		case (op_choice)
			3'b000 : return AND_OP;
			3'b001 : return OR_OP;
			3'b100 : return ADD_OP;
			3'b101 : return SUB_OP;
			default: return /*INVALID_OP*/AND_OP;   //TODO handle OP
		endcase // case (op_choice)
	endfunction : get_op

	function get_error_code;

		output processing_error_t error_code;

		begin
			error_code = processing_error_t'(3'b000);
			error_code[$urandom_range(2,0)] = 1'b1;;
		end

	endfunction


	task get_expected_result ( output logic [31:0] result, logic [3:0] flags, output logic [3:0] crc, input bit  [31:0] A, bit  [31:0] B, operation_t op_set);
		begin

			logic  [32:0] result_33b;

			case(op_set)
				AND_OP: begin
					result = A & B;
					result_33b = A & B;
				end
				ADD_OP: begin
					result = A + B;
					result_33b = A + B;
				end
				OR_OP : begin
					result = A | B;
					result_33b = A | B;
				end
				SUB_OP: begin
					result = B - A;
					result_33b = B - A;
				end
				INVALID_OP  : result = 32'b0;  // TODO handle error!
				default: begin
					$display("%0t INTERNAL ERROR. get_expected_result: unexpected case argument: %s", $time, op_set);
					test_result = "FAILED";
				end
			endcase

			flags = {result_33b[32], IsOverflow(A, B, result, op_set), (result == 0), result[31]};        /*Carry, Overflow, Zero, Negative*/
			crc = CRC3_D37({result, 1'b0, flags}, 3'b0);
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

		logic  [31:0]  A;
		logic  [31:0]  B;
		processing_error_t error_code;

		reset_alu();

		repeat (100) begin : tester_main
			@(negedge clk) ;
			op_set = get_op();
			A      = get_data();
			B      = get_data();

			case (op_set)

				INVALID_OP: begin : case_invalid
				//do nothing for now; TODO
				end

				default: begin : case_default
					@(negedge clk);
					process_instruction(A, B, op_set);
					//------------------------------------------------------------------------------
					// temporary data check - scoreboard will do the job later
					begin
						bit [31:0] expected_data;
						logic [3:0] expected_flags, rcv_flags;
						logic [2:0] expected_crc, rcv_crc;
						get_expected_result(expected_data, expected_flags, expected_crc, A, B, op_set);
						process_ALU_response(result, rcv_flags, rcv_crc);
						assert (result === expected_data) else begin
							$error("Test FAILED for A=%x B=%x op_set=%s (data): rcv:%x, exp:%x", A, B, op_set.name, result, expected_data);
							test_result = "FAILED";
						end;
						assert (rcv_flags === expected_flags) else begin
							$error("Test FAILED for A=%x B=%x op_set=%s (flags): rcv:%04b, exp:%04b", A, B, op_set.name, rcv_flags, expected_flags);
							test_result = "FAILED";
						end;
						assert (rcv_crc === expected_crc) else begin
							$error("Test FAILED for A=%x B=%x op_set=%s (crc): rcv:%03b, exp:%03b", A, B, op_set.name, rcv_crc, expected_crc);
							test_result = "FAILED";
						end;

						get_error_code(error_code);
						test_alu_processing_error(error_code);
					end

				end
			endcase         //case(op_set)

		// print coverage after each loop
		// $strobe("%0t coverage: %.4g\%",$time, $get_coverage());
		// if($get_coverage() == 100) break;
		end
		$finish;
	end : tester

//**********************************************************************/
// Temporary. The scoreboard data will be later used.
	final begin : finish_of_the_test
		$display("Test %s.",test_result);
	end
//**********************************************************************/

endmodule : top