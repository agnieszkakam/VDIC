virtual class base_tester extends uvm_component;

`uvm_component_utils(base_tester)

    uvm_put_port #(alu_data_in_s) alu_in_port;
	
	pure virtual function [31:0] get_data();

	function operation_t get_op();
		automatic bit [2:0] op_choice = $random;
		case (op_choice)
			3'b000, 3'b001, 3'b100, 3'b101, 3'b110 : return operation_t'(op_choice);
			default: return INVALID_OP;
		endcase // case (op_choice)
	endfunction : get_op

	protected task get_error_code (output processing_error_t error_code);
		begin
			error_code = processing_error_t'(3'b000);
			error_code[$urandom_range(2,0)] = 1'b1;
		end
	endtask

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        alu_in_port = new("alu_in_port", this);
    endfunction : build_phase

	task run_phase(uvm_phase phase);

        alu_data_in_s alu_data_in;

        phase.raise_objection(this);
        alu_data_in.op_set = RST_OP;
        alu_in_port.put(alu_data_in);
		
		repeat (50) begin : tester_main
            alu_data_in.A  = get_data();
            alu_data_in.B  = get_data();
            alu_data_in.op_set = get_op();
			alu_data_in.error_state = 1'b0;
			alu_data_in.error_code = ERR_DATA;		//TODO REMOVE
            alu_in_port.put(alu_data_in);
		end
/*
		@(negedge bfm.clk) ;

		repeat(1000) begin   : tester_errors
			bfm.op_set = get_op();
			bfm.A  = get_data();
			bfm.B  = get_data();

			bfm.error_state = 1'b1;
			get_error_code(bfm.error_code);
			bfm.test_alu_processing_error(bfm.error_response, bfm.error_code);
			bfm.error_state = 1'b0;
		end
*/
		#500;
        phase.drop_objection(this);

	endtask : run_phase
	
endclass
