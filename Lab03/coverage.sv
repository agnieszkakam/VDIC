module coverage(alu_bfm bfm);
	import alu_pkg::*;

	bit                  [31:0] A;
	bit                  [31:0] B;
	operation_t                 op_set;

	// Covergroup checking the op codes and their sequences
	covergroup op_cov;

		option.name = "cg_op_cov";

		coverpoint op_set {
			// #A1 test all operations
			bins A1_all_op[] = {[AND_OP : OR_OP], [ADD_OP : SUB_OP]};

			// #A2 test all operations after reset
			bins A2_rst_opn[]      = (RST_OP => [AND_OP : OR_OP], [ADD_OP : SUB_OP]);

			// #A3 test reset after all operations
			bins A3_opn_rst[]      = ([AND_OP : OR_OP], [ADD_OP : SUB_OP] => RST_OP);

			// #A4 two operations in row
			bins A4_twoops[]       = ([AND_OP : OR_OP], [ADD_OP : SUB_OP] [* 2]);

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

		error_leg: coverpoint bfm.error_code    {
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

			ignore_bins others_only   = binsof(a_leg.others) && binsof(b_leg.others);

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

	initial begin : coverage_block
		oc          = new();
		c_data_corn = new();

		forever begin : sampling_block
			@(posedge bfm.clk);
			A      = bfm.A;
			B      = bfm.B;
			op_set = bfm.op_set;

			if(bfm.done || !bfm.rst_n) begin
				oc.sample();
				c_data_corn.sample();
			end
		end : sampling_block
	end 	: coverage_block

endmodule 	: coverage