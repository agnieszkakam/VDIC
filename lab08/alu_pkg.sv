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

// Configs
`include "env_config.svh"
`include "alu_agent_config.svh"

// Transactions
`include "random_command.svh"
`include "minmax_command.svh"
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