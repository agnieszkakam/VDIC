class command_monitor extends uvm_component;
	`uvm_component_utils(command_monitor)

	uvm_analysis_port #(alu_data_in_s) ap;

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
		$display("COMMAND MONITOR: A:%8h B:%8h op: %s, ERR=%d(%s)", cmd.A, cmd.B, cmd.op_set.name(), cmd.error_state, cmd.error_code.name() );
		ap.write(cmd);
		$display("COMMAND MONITOR: done");
	endfunction : write_to_monitor

endclass : command_monitor

