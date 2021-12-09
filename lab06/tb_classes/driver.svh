class driver extends uvm_component;
    `uvm_component_utils(driver)

    virtual alu_bfm bfm;
    uvm_get_port #(alu_data_s) alu_data_port;

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
            $fatal(1, "Failed to get BFM");
        alu_data_port = new("alu_data_port",this);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        alu_data_s alu_data;
        logic [31:0] result_data;
	    logic [7:0] result_ctl;

        forever begin : command_loop
	        
            alu_data_port.get(alu_data);
            bfm.process_instruction(alu_data.A, alu_data.B, alu_data.op_set);
	        #2000;
			
        end : command_loop
    endtask : run_phase

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

endclass : driver

