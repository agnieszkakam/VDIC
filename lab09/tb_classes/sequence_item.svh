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
	    /*
        `uvm_field_int(alu_command.A, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(alu_command.B, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(alu_command.error_state, UVM_ALL_ON | UVM_DEC)
        `uvm_field_enum(operation_t, alu_command.op_set, UVM_ALL_ON)			   //ERROR: "Invalid ref argument usage because actual argument is not a variable."
        `uvm_field_enum(processing_error_t, alu_command.error_code, UVM_ALL_ON)  //ERROR: "Invalid ref argument usage because actual argument is not a variable.s"
        */
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
/*
function void do_copy(uvm_object rhs);

		sequence_item copied_command_h;

		assert(rhs != null) else
			`uvm_fatal("SEQUENCE ITEM","Tried to copy null transaction");
		super.do_copy(rhs);

		assert($cast(copied_command_h,rhs)) else
			`uvm_fatal("SEQUENCE ITEM","Failed cast in do_copy");

		alu_command = copied_command_h.alu_command;
	endfunction : do_copy

	function string convert2string();
		string s;
		s = $sformatf("command: A=%8h, B=%8h, OP=%s, err=%1d (%s)", alu_command.A, alu_command.B,
			alu_command.op_set.name(), alu_command.error_state, alu_command.error_code.name());
		return s;
	endfunction : convert2string

	function bit do_compare(uvm_object rhs, uvm_comparer comparer);
		sequence_item RHS;
		bit same;

		assert(rhs != null) else
			`uvm_fatal("SEQUENCE ITEM","Tried to compare null transaction");

		same = super.do_compare(rhs, comparer);

		assert($cast(RHS, rhs)) begin
			same = (alu_command == RHS.alu_command) && same;
		end else begin
			same = 1'b0;
		end
		return same;
	endfunction : do_compare
*/

	function string convert2string();
		string s;
		s = $sformatf("command: A=%8h, B=%8h, OP=%s, err=%1d (%s)", alu_command.A, alu_command.B,
			alu_command.op_set.name(), alu_command.error_state, alu_command.error_code.name());
		return s;
	endfunction : convert2string

endclass : sequence_item