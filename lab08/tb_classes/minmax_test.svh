class minmax_test extends random_test;
	`uvm_component_utils(minmax_test)

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new (string name, uvm_component parent);
		super.new(name,parent);
	endfunction : new
	
//------------------------------------------------------------------------------
// class methods
//------------------------------------------------------------------------------

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		random_command::type_id::set_type_override(minmax_command::get_type());
	endfunction : build_phase

endclass
