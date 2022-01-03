class random_tester extends base_tester;

	`uvm_component_utils (random_tester)

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function logic [31:0] get_data();
		return $urandom;
	endfunction : get_data

endclass : random_tester
