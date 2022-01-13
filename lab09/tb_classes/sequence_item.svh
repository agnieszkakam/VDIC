class sequence_item extends uvm_sequence_item;

//------------------------------------------------------------------------------
// sequence item variables
//------------------------------------------------------------------------------

	rand alu_data_in_s alu_command;

//------------------------------------------------------------------------------
// Macros providing copy, compare, pack, record, print functions.
//------------------------------------------------------------------------------

    `uvm_object_utils_begin(sequence_item)
	    `uvm_field_int(alu_command,UVM_DEFAULT)
    `uvm_object_utils_end

//------------------------------------------------------------------------------
// constraints
//------------------------------------------------------------------------------

	constraint data {
		alu_command.A dist { [32'h0000_0000 : 32'hFFFF_FFFF] := 1 };
		alu_command.B dist { [32'h0000_0000 : 32'hFFFF_FFFF] := 1 };
		alu_command.error_code == ERR_OP -> alu_command.op_set == INVALID_OP;			// implication constraint
		if (alu_command.op_set == INVALID_OP) {
			alu_command.error_code == ERR_OP;
			alu_command.error_state == 1'b1;
		}
	}

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

    function new(string name = "sequence_item");
        super.new(name);
    endfunction : new

//------------------------------------------------------------------------------
// 
//------------------------------------------------------------------------------

	function string convert2string();
		string s;
		s = $sformatf("command: A=%8h, B=%8h, OP=%s, err=%1d (%s)", alu_command.A, alu_command.B,
			alu_command.op_set.name(), alu_command.error_state, alu_command.error_code.name());
		return s;
	endfunction : convert2string

endclass : sequence_item