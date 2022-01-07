class tester extends uvm_component;
	`uvm_component_utils (tester)

	uvm_put_port #(random_command) command_port;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

//------------------------------------------------------------------------------
// class methods
//------------------------------------------------------------------------------



//------------------------------------------------------------------------------
// build_phase
//------------------------------------------------------------------------------

	function void build_phase(uvm_phase phase);
		command_port = new("command_port", this);
	endfunction : build_phase

//------------------------------------------------------------------------------
// run_phase
//------------------------------------------------------------------------------

	task run_phase(uvm_phase phase);

		random_command command_h;

		phase.raise_objection(this);

		command_h = new("command");
		command_h.alu_command.op_set = RST_OP;
		command_port.put(command_h);

		command_h = random_command::type_id::create("command");     //factory-created cmd (transaction type) may be overwritten later on

		repeat (10) begin : tester_main
			if(!command_h.randomize()) begin
				`uvm_fatal("TESTER","Randomization failed.");
			end else begin
				command_h.alu_command.op_set = get_valid_op();
				command_h.alu_command.error_state = 1'b0;
				command_port.put(command_h);
			end
		end

		repeat(10) begin   : tester_errors
			if(!command_h.randomize()) begin
				`uvm_fatal("TESTER","Randomization failed.");
			end else begin
				command_h.alu_command.error_state = 1'b1;
				get_error_code(command_h.alu_command.error_code);
				command_h.alu_command.op_set = (command_h.alu_command.error_code == ERR_OP) ? INVALID_OP : get_valid_op();
				command_port.put(command_h);
			end
		end

	#5000;
	phase.drop_objection(this);

endtask : run_phase

endclass
