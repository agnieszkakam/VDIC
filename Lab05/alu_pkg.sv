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
	} packet_t;

	typedef enum bit [2:0] {
		ERR_DATA    = 3'b100,
		ERR_CRC     = 3'b010,
		ERR_OP      = 3'b001
	} processing_error_t;

`include "coverage.svh"
`include "base_tester.svh"
`include "random_tester.svh"
`include "corner_tester.svh"   
`include "scoreboard.svh"
`include "env.svh"
`include "random_test.svh"
`include "corner_test.svh"

endpackage : alu_pkg