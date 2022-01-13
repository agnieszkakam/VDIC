class minmax_sequence extends uvm_sequence #(sequence_item);
    `uvm_object_utils(minmax_sequence)

	sequence_item seq;

constraint corners {
		seq.alu_command.A dist { 32'h0000_0000 := 50, 32'hFFFF_FFFF := 50};
		seq.alu_command.B dist { 32'h0000_0000 := 50, 32'hFFFF_FFFF := 50};
}		// this constraint does not force a MIN MAX SEQUENCE*/

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

    function new(string name = "minmax_sequence");
        super.new(name);
    endfunction : new
    
//------------------------------------------------------------------------------
// post_randomize
//------------------------------------------------------------------------------    
    /*
    function void post_randomize();
	    seq.alu_command.A = 32'hFFFF_FFFF;
		seq.alu_command.B = 32'hFFFF_FFFF;
    endfunction
    */
//------------------------------------------------------------------------------
// the sequence body
//------------------------------------------------------------------------------

    task body();
        `uvm_info("SEQ_MINMAX", "", UVM_MEDIUM)
        `uvm_create(req)
        `uvm_do_with(req, {alu_command.op_set == RST_OP;})
/*
        seq = new("seq");
	    
		start_item(seq);
		seq.alu_command.op_set = RST_OP;
		finish_item(seq);
  */      
	    repeat(250)  begin : minmax_loop
			/*start_item(seq);
			if(!seq.randomize()) begin
				`uvm_fatal("MINMAX_SEQUENCE", "Randomization failed.");
			end
			post_randomize();
			$display("%s", seq.convert2string());
			finish_item(seq);*/
			`uvm_do_with(req, {
							alu_command.A dist { 32'h0000_0000 := 10, 32'hFFFF_FFFF := 10};
							alu_command.B dist { 32'h0000_0000 := 10, 32'hFFFF_FFFF := 10};
			})
			//$display("%s", req.convert2string());
		end : minmax_loop
    endtask : body
    
endclass : minmax_sequence
