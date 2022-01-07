module alu_tester (alu_bfm bfm);
	import alu_pkg::*;

	initial begin

		alu_data_in_s alu_in;
		alu_data_out_s alu_data_out;

		bfm.reset_alu();

		repeat (4000) begin : tester_main

			alu_in.A = get_data();
			alu_in.B = get_data();
			alu_in.op_set = get_valid_op();

			bfm.op_set = alu_in.op_set;
			bfm.A  = alu_in.A;
			bfm.B  = alu_in.B;

			case (bfm.op_set)
				RST_OP: begin : rst_op
					bfm.reset_alu();
				end
				default: begin : norm_op
					bfm.process_instruction(alu_in);
				end
			endcase
		end

		repeat(4000) begin   : tester_errors
			alu_in.A = get_data();
			alu_in.B = get_data();
			get_error_code(alu_in.error_code);
			alu_in.op_set = (alu_in.error_code == ERR_OP) ? INVALID_OP : get_valid_op();
			alu_in.error_state = 1'b1;

			bfm.op_set = alu_in.op_set;
			bfm.A  = alu_in.A;
			bfm.B  = alu_in.B;
			bfm.error_code = alu_in.error_code;
			bfm.error_state = alu_in.error_state;

			case (bfm.op_set)
				RST_OP: begin : rst_op
					bfm.reset_alu();
				end
				default: begin : norm_op
					bfm.process_instruction(alu_in);
				end
			endcase
		end
	end
endmodule
