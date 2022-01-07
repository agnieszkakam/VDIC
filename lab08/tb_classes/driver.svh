class driver extends uvm_component;
	`uvm_component_utils(driver)

	virtual alu_bfm bfm;
	uvm_get_port #(random_command) command_port;

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
		alu_agent_config alu_agent_config_h;
		if(!uvm_config_db #(alu_agent_config)::get(this, "","config", alu_agent_config_h))
			$fatal(1, "Failed to get ALU_AGENT_CONFIG");
		bfm = alu_agent_config_h.bfm;
		command_port = new("command_port",this);
	endfunction : build_phase

//------------------------------------------------------------------------------
// run_phase
//------------------------------------------------------------------------------

	task run_phase(uvm_phase phase);
		random_command cmd;
		result_transaction alu_data_out;

		forever begin : command_loop
			command_port.get(cmd);
			//$display("DRIVER: cmd received: A=%h, B=%h, %s, ERR=%d(%s)", alu_data_in.A, alu_data_in.B, alu_data_in.op_set.name(), alu_data_in.error_state, alu_data_in.error_code.name() );
			case (cmd.alu_command.op_set)
				RST_OP: begin : rst_op
					bfm.reset_alu();
				end
				default: begin : norm_op
					bfm.process_instruction(cmd.alu_command);
				end
			endcase

		end : command_loop
	endtask : run_phase

endclass : driver

