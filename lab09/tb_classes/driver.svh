class driver extends uvm_driver #(sequence_item);
	`uvm_component_utils(driver)

	protected virtual alu_bfm bfm;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

//------------------------------------------------------------------------------
// build_phase
//------------------------------------------------------------------------------

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
			`uvm_fatal(1, "Failed to get BFM");
	endfunction : build_phase

//------------------------------------------------------------------------------
// run_phase
//------------------------------------------------------------------------------

	task run_phase(uvm_phase phase);
		sequence_item cmd;

		forever begin : command_loop
			alu_data_out_s alu_result;
			seq_item_port.get_next_item(cmd);
			//$display("DRIVER: cmd received: A=%h, B=%h, %s, ERR=%d(%s)", alu_data_in.A, alu_data_in.B, alu_data_in.op_set.name(), alu_data_in.error_state, alu_data_in.error_code.name() );
			case (cmd.alu_command.op_set)
				RST_OP: begin : rst_op
					bfm.reset_alu();
				end
				default: begin : norm_op
					bfm.process_instruction(cmd.alu_command);
				end
			endcase
			seq_item_port.item_done();
		end : command_loop
	endtask : run_phase

endclass : driver

