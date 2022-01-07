class env extends uvm_env;
	`uvm_component_utils(env)

	/* xrun 18.1 warns about object definition from abstract class, will be
	 * upgraded to error in future releases.
	 * This is temporary solution -> sequencer/driver will not have this problem
	 */
	 
 
//------------------------------------------------------------------------------
// agents
//------------------------------------------------------------------------------

    alu_agent class_alu_agent_h;
    alu_agent module_alu_agent_h;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new (string name, uvm_component parent);
		super.new(name,parent);
	endfunction : new

//------------------------------------------------------------------------------
// build_phase
//------------------------------------------------------------------------------

	function void build_phase(uvm_phase phase);

        env_config env_config_h;
        alu_agent_config class_config_h;
        alu_agent_config module_config_h;

        if(!uvm_config_db #(env_config)::get(this, "","config", env_config_h))
            `uvm_fatal("ENV", "Failed to get config object");

        class_config_h         = new(.bfm(env_config_h.class_bfm), .is_active(UVM_ACTIVE));
        module_config_h        = new(.bfm(env_config_h.module_bfm), .is_active(UVM_PASSIVE));

        uvm_config_db #(alu_agent_config)::set(this, "class_alu_agent_h*",
            "config", class_config_h);
        uvm_config_db #(alu_agent_config)::set(this, "module_alu_agent_h*",
            "config", module_config_h);

        // create the agents
        class_alu_agent_h  = alu_agent::type_id::create("class_alu_agent_h",this);
        module_alu_agent_h = alu_agent::type_id::create("module_alu_agent_h",this);

    endfunction : build_phase

endclass