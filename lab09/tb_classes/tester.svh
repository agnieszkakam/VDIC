virtual class tester extends uvm_component;
	`uvm_component_utils (tester)

	uvm_put_port #(random_command) alu_in_port;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

//------------------------------------------------------------------------------
// class methods
//------------------------------------------------------------------------------

	pure virtual function [31:0] get_data();



//------------------------------------------------------------------------------
// build_phase
//------------------------------------------------------------------------------

	function void build_phase(uvm_phase phase);
		alu_in_port = new("alu_in_port", this);
	endfunction : build_phase

//------------------------------------------------------------------------------
// run_phase
//------------------------------------------------------------------------------

	task run_phase(uvm_phase phase);

		random_command command_h;

		phase.raise_objection(this);

		command_h = new("command");
		command_h.alu_command.op_set = RST_OP;
		alu_in_port.put(command_h);

		command_h = random_command::type_id::create("command");     //factory-created cmd (transaction type) may be overwritten later on

		repeat (4000) begin : tester_main
			if(!command_h.randomize()) begin
				`uvm_fatal("TESTER","Randomization failed.");
			end else begin
				command_h.alu_command.op_set = get_valid_op();
				command_h.alu_command.error_state = 1'b0;
				alu_in_port.put(command_h);
			end
		end

		repeat(4000) begin   : tester_errors
			if(!command_h.randomize()) begin
				`uvm_fatal("TESTER","Randomization failed.");
			end else begin
				command_h.alu_command.error_state = 1'b1;
				get_error_code(command_h.alu_command.error_code);
				command_h.alu_command.op_set = (command_h.alu_command.error_code == ERR_OP) ? INVALID_OP : get_valid_op();
				alu_in_port.put(command_h);
			end
		end

	#5000;
	phase.drop_objection(this);

endtask : run_phase

endclass
