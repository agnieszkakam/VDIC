class corner_tester extends random_tester;

	`uvm_component_utils (corner_tester)

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function logic [31:0] get_data();
		bit random;
		random = 1'($random);
		if (random == 1'b1)
			return 32'hFFFF_FFFF;
		else
			return 32'h0000_0000;
	endfunction : get_data

endclass : corner_tester