class minmax_sequence extends uvm_sequence #(sequence_item);
    `uvm_object_utils(minmax_sequence)

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

    function new(string name = "minmax_sequence");
        super.new(name);
    endfunction : new
    
//------------------------------------------------------------------------------
// the sequence body
//------------------------------------------------------------------------------

    task body();
        `uvm_info("SEQ_MINMAX", "", UVM_MEDIUM)
        `uvm_do_with(req, {req.alu_command.A dist {32'h0000_0000:=10, 32'hFFFF_FFFF:=10};
	        			   req.alu_command.B dist {32'h0000_0000:=10, 32'hFFFF_FFFF:=10};})
    endtask : body
    
endclass : minmax_sequence
