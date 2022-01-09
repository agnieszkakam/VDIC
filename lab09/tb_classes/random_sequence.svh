class random_sequence extends uvm_sequence #(sequence_item);
	`uvm_object_utils(random_sequence)

	sequence_item seq;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new(string name = "random_sequence");
		super.new(name);
	endfunction : new

//------------------------------------------------------------------------------
// the sequence body
//------------------------------------------------------------------------------

	task body();
		`uvm_info("SEQ_RANDOM","",UVM_MEDIUM)
		//seq = sequence_item::type_id::create("seq");
		seq = new("seq");
//      `uvm_create(req);

		repeat (5000) begin : random_loop
			start_item(seq);
			if(!seq.randomize()) begin
				`uvm_fatal("RANDOM_SEQUENCE", "Randomization failed.");
			end
			finish_item(seq);
		end : random_loop
	endtask : body

endclass : random_sequence
