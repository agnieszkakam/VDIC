class driver extends uvm_component;
	`uvm_component_utils(driver)

	virtual alu_bfm bfm;
	uvm_get_port #(alu_data_in_s) alu_in_port;

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
			$fatal(1, "Failed to get BFM");
		alu_in_port = new("alu_in_port",this);
	endfunction : build_phase

	task run_phase(uvm_phase phase);
		alu_data_in_s alu_data_in;
		//logic [31:0] result_data;
		//logic [7:0] result_ctl;

		forever begin : command_loop
			#1400;
			$display("DRIVER: waiting for cmd");
			alu_in_port.get(alu_data_in);
			$display("DRIVER: cmd received: %h, %h, %s",alu_data_in.A, alu_data_in.B, alu_data_in.op_set.name());
			
			case (alu_data_in.op_set)              
				RST_OP: begin : rst_op
					bfm.reset_alu();
					$display("DRIVER: reset");
				end
				default: begin : norm_op
					bfm.process_instruction(alu_data_in);
					$display("DRIVER: process instructions");
				end
			endcase
						
		end : command_loop
	endtask : run_phase

endclass : driver

