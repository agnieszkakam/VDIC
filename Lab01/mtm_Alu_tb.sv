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

	/**
	 * Local variables and signals
	 */

	localparam start_bit = 1'b0;
	localparam stop_bit = 1'b1;

	bit                     clk;
	bit                     rst_n;
	bit                 sin, sout;

	bit         [31:0]  A;
	bit         [31:0]  B;
	reg         [31:0]  result;
	operation_t         op_set;
	string              test_result = "PASSED";
	logic       [31:0]  expected;

	/**
	 * DUT instantiation
	 */

	mtm_Alu DUT (.clk, .rst_n, .sin, .sout);


	/**
	 * Tasks and functions definitions
	 */

	function logic [31:0] get_expected_result(
			bit [31:0] A,
			bit [31:0] B,
			operation_t op_set
		);
		bit [31:0] ret;

		case(op_set)
			AND_OP      : ret = A & B;
			ADD_OP      : ret = A + B;
			OR_OP       : ret = A | B;
			SUB_OP      : ret = A - B;
			INVALID_OP  : ret = 32'b0;  // TODO handle error!
			default: begin
				$display("%0t INTERNAL ERROR. get_expected_result: unexpected case argument: %s", $time, op_set);
				test_result = "FAILED";
				return -1;
			end
		endcase
		return(ret);
	endfunction

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

	task send_packet (input packet_t packet_type, byte data_byte);
		begin
			automatic logic [10:0] packet = {start_bit, packet_type, data_byte, stop_bit};

			for (int i = 0; i < 11; i++) begin
				@(negedge clk) ;
				sin = packet[10 - i];
			end
		end
	endtask

	task process_instruction (input logic [31:0] A, input logic [31:0] B, input operation_t opcode);
		begin
			automatic logic [3:0] CRC;
			CRC = CRC4_D68({B, A, 1'b1, opcode}, 4'b0);

			for (int i = 3; i >= 0; i--) begin
				send_packet(DATA, B [8*i +: 8]);
			end

			for (int i = 3; i >= 0; i--) begin
				send_packet(DATA, A [8*i +: 8]);
			end

			send_packet(CMD, {1'b0, opcode, CRC});
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

	task process_ALU_response (output logic [31:0] C);
		begin
			logic [7:0] cmd_response;

			for (int i = 3; i >= 0; i--) begin
				receive_packet(C [8*i +: 8]);
			end

			receive_packet(cmd_response);
		// TODO check CRC, make use of returned flags

		end
	endtask

	task reset_alu();
		
		rst_n = 1'b0;
		@(negedge clk);
		rst_n = 1'b1;
		sin = 1'b1;			//idle bus state
	endtask

	function operation_t get_op();
		bit [2:0] op_choice;
		op_choice = $random;
		case (op_choice)
			3'b000 : return AND_OP;
			3'b001 : return OR_OP;
			3'b100 : return ADD_OP;
			3'b101 : return SUB_OP;
			default: return /*INVALID_OP*/ AND_OP;		// TODO add support for invalid opcode!
		endcase // case (op_choice)
	endfunction : get_op

	function [31:0] get_data();
		bit [1:0] zero_ones;
		zero_ones = 2'($urandom);
		if (zero_ones == 2'b00)
			return 32'h00;
		else if (zero_ones == 2'b11)
			return 32'hFF;
		else
			return 32'($urandom);
	endfunction : get_data


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

		//@(negedge clk) ;	
		repeat (5) begin : tester_main
			@(negedge clk) ;
			 op_set = get_op();
			 $display(op_set.name);
			 A      = get_data();
			 B      = get_data();

			@(negedge clk) ;
			process_instruction(A, B, op_set);

			expected = get_expected_result(A, B, op_set);
			process_ALU_response(result);

			assert (result === expected) else
				$error("Test FAILED for A=%x B=%x op_set=%s: rcv:%x, exp:%x", A, B, op_set.name, result, expected);
			
			reset_alu();
			@(negedge clk) ;
		/*case (op_set)
		 default: begin : case_default
		 @(negedge clk);
		 process_instruction(A, B, op_set);
		 //------------------------------------------------------------------------------
		 // temporary data check - scoreboard will do the job later
		 begin
		 automatic bit [31:0] expected = get_expected_result(A, B, op_set);
		 process_ALU_response(result);
		 assert(result === expected) begin
		 `ifdef DEBUG
		 $display("Test passed for A=%0d B=%0d op_set=%0d", A, B, op_set);
		 `endif
		 end
		 else begin
		 $display("Test FAILED for A=%0d B=%0d op_set=%0d", A, B, op_set);
		 $display("Expected: %d  received: %d", expected, result);
		 test_result = "FAILED";
		 end;
		 end

		 end
		 endcase*/ // case (op_set)
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