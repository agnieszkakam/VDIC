`timescale 1ns/1ps

package alu_pkg;
	import uvm_pkg::*;
	`include "uvm_macros.svh"

// Type definitions

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
	} packet_type_t;

	typedef enum bit [2:0] {
		ERR_DATA    = 3'b100,
		ERR_CRC     = 3'b010,
		ERR_OP      = 3'b001
	} processing_error_t;

	typedef struct packed {
		logic  [31:0]  rcv_data;
		logic  [7:0]   rcv_control_packet;
	} alu_data_out_s;

	typedef struct packed {
		rand logic  [31:0]  A, B;
		rand bit error_state;
		rand operation_t op_set;
		rand processing_error_t error_code;
	} alu_data_in_s;

// Functions & Tasks

	function operation_t get_valid_op();
		automatic bit [2:0] op_choice = $random;
		case (op_choice)
			3'b000, 3'b001, 3'b100, 3'b101, 3'b110 : return operation_t'(op_choice);
			default: return AND_OP;
		endcase // case (op_choice)
	endfunction : get_valid_op

	task get_error_code (output processing_error_t error_code);
		begin
			error_code = processing_error_t'(3'b000);
			error_code[$urandom_range(2,0)] = 1'b1;
		end
	endtask

//   - polynomial: x^4 + x^1 + 1
	function logic [3:0] CRC4_D68;
		input [67:0] Data;
		input [3:0] crc;
		reg [67:0] d;
		reg [3:0] c, newcrc;
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

	function logic [31:0] get_data();
		bit [1:0] zero_ones;
		zero_ones = 2'($urandom);
		if (zero_ones == 2'b00)
			return 32'h00;
		else if (zero_ones == 2'b11)
			return 32'hFFFF_FFFF;
		else
			return 32'($urandom);
	endfunction : get_data

// Configs
`include "env_config.svh"
`include "alu_agent_config.svh"

// Transactions
`include "random_command.svh"
`include "result_transaction.svh"

// Testbench components
`include "command_monitor.svh"
`include "result_monitor.svh"
`include "driver.svh"

`include "coverage.svh"
`include "tester.svh"
`include "scoreboard.svh"

`include "alu_agent.svh"
`include "env.svh"

// Test
`include "dual_test.svh"


endpackage : alu_pkg