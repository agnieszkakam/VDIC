class random_command extends uvm_transaction;
	`uvm_object_utils(random_command)

//------------------------------------------------------------------------------
// transaction variables
//------------------------------------------------------------------------------

	rand alu_data_in_s alu_command;

	constraint data {
		alu_command.A dist {32'h0000_0000:= 1, [32'h0000_0001 : 32'hFFFF_FFFE]:/1, 32'hFFFF_FFFF:=1};
		alu_command.B dist {32'h0000_0000:= 1, [32'h0000_0001 : 32'hFFFF_FFFE]:/1, 32'hFFFF_FFFF:=1};
	}

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new(string name = "");
		super.new(name);
	endfunction : new

//------------------------------------------------------------------------------
// transaction methods - do_copy, convert2string, do_compare
//------------------------------------------------------------------------------

	function void do_copy(uvm_object rhs);

		random_command copied_command_h;

		assert(rhs != null) else
			`uvm_fatal("RANDOM COMMAND","Tried to copy null transaction");
		super.do_copy(rhs);

		assert($cast(copied_command_h,rhs)) else
			`uvm_fatal("RANDOM COMMAND","Failed cast in do_copy");

		alu_command = copied_command_h.alu_command;
	endfunction : do_copy

	function string convert2string();
		string s;
		s = $sformatf("command: A=%8h, B=%8h, OP=%s, err=%1d (%s)", alu_command.A, alu_command.B,
			alu_command.op_set.name(), alu_command.error_state, alu_command.error_code.name());
		return s;
	endfunction : convert2string

	function bit do_compare(uvm_object rhs, uvm_comparer comparer);
		random_command RHS;
		bit same;

		assert(rhs != null) else
			`uvm_fatal("RANDOM COMMAND","Tried to compare null transaction");

		same = super.do_compare(rhs, comparer);

		assert($cast(RHS, rhs)) begin
			same = (alu_command == RHS.alu_command) && same;
		end else begin
			same = 1'b0;
		end
		return same;
	endfunction : do_compare

endclass : random_command