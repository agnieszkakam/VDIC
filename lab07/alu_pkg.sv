`timescale 1ns/1ps

package alu_pkg;
	import uvm_pkg::*;
	`include "uvm_macros.svh"

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

`include "random_command.svh"
`include "minmax_command.svh"
`include "result_transaction.svh"

`include "command_monitor.svh"
`include "result_monitor.svh"
`include "driver.svh"

`include "coverage.svh"
`include "tester.svh"
`include "scoreboard.svh"

`include "env.svh"

`include "random_test.svh"
`include "minmax_test.svh"


endpackage : alu_pkg