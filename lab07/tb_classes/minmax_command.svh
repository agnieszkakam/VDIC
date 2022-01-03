class minmax_command extends random_command;
	`uvm_object_utils(minmax_command)

//------------------------------------------------------------------------------
// transaction variables
//------------------------------------------------------------------------------

	constraint data {
		alu_command.A dist {32'h0000_0000:=1, 32'hFFFF_FFFF:=1};
		alu_command.B dist {32'h0000_0000:=1, 32'hFFFF_FFFF:=1};
	}

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new(string name = "");
		super.new(name);
	endfunction : new

endclass : minmax_command