class command_monitor extends uvm_component;
	`uvm_component_utils(command_monitor)

	uvm_analysis_port #(sequence_item) ap;

	function new (string name, uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		virtual alu_bfm bfm;

		if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
			$fatal(1, "Failed to get BFM");
		bfm.command_monitor_h = this;
		ap                    = new("ap",this);

	endfunction : build_phase

	function void write_to_monitor(alu_data_in_s cmd);
		sequence_item transaction_cmd;		
		`uvm_info	("COMMAND MONITOR",
					$sformatf("MONITOR: A:%8h B:%8h op: %s, ERR=%d(%s)",
					transaction_cmd.alu_command.A, transaction_cmd.alu_command.B, transaction_cmd.alu_command.op_set.name(),
					transaction_cmd.alu_command.error_state, transaction_cmd.alu_command.error_code.name()),
					UVM_HIGH);
		
		transaction_cmd = new("transaction_cmd");
		transaction_cmd.alu_command.A = cmd.A;
		transaction_cmd.alu_command.B = cmd.B;
		transaction_cmd.alu_command.op_set = cmd.op_set;
		transaction_cmd.alu_command.error_code = cmd.error_code;
		transaction_cmd.alu_command.error_state = cmd.error_state;

		ap.write(transaction_cmd);
		
	endfunction : write_to_monitor

endclass : command_monitor

