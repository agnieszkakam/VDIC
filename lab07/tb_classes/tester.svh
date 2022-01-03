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

	function operation_t get_valid_op();
		automatic bit [2:0] op_choice = $random;
		case (op_choice)
			3'b000, 3'b001, 3'b100, 3'b101, 3'b110 : return operation_t'(op_choice);
			default: return AND_OP;
		endcase // case (op_choice)
	endfunction : get_valid_op

	protected task get_error_code (output processing_error_t error_code);
		begin
			error_code = processing_error_t'(3'b000);
			error_code[$urandom_range(2,0)] = 1'b1;
		end
	endtask

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
