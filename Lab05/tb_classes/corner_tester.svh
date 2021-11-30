class corner_tester extends base_tester;
    
    `uvm_component_utils (random_tester)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function logic [31:0] get_data();
        bit [1:0] zero_ones;
        zero_ones = $random;
        if (zero_ones <= 2'b01)
            return 32'h0000_0000;
        else
            return 32'hFFFF_FFFF;
    endfunction : get_data

    function operation_t get_op();
        automatic bit [2:0] op_choice = $random;
		case (op_choice)
			3'b000, 3'b001, 3'b100, 3'b101, 3'b110 : return operation_t'(op_choice);
			default: return INVALID_OP;
		endcase // case (op_choice)
    endfunction : get_op

endclass : corner_tester