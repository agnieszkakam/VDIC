class result_monitor extends uvm_component;
	`uvm_component_utils(result_monitor)

	uvm_analysis_port #(result_transaction) ap;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

//------------------------------------------------------------------------------
// class methods
//------------------------------------------------------------------------------

	function void build_phase(uvm_phase phase);
		virtual alu_bfm bfm;
		if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
			$fatal(1, "Failed to get BFM");
		bfm.result_monitor_h = this;
		ap                   = new("ap",this);
	endfunction : build_phase

	function void write_to_monitor(alu_data_out_s r);
		result_transaction result_t;
		
		`uvm_info	("RESULT MONITOR", $sformatf("MONITOR: res=%08x, ctl=%02x",
					result_t.alu_result.rcv_data, result_t.alu_result.rcv_control_packet),
					UVM_HIGH);
		
		result_t = new("result_t");
		result_t.alu_result.rcv_control_packet = r.rcv_control_packet;
		result_t.alu_result.rcv_data  = r.rcv_data;
		ap.write(result_t);
	endfunction : write_to_monitor

endclass : result_monitor
