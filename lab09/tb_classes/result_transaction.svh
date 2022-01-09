class result_transaction extends uvm_transaction;

//------------------------------------------------------------------------------
// transaction variables
//------------------------------------------------------------------------------

    alu_data_out_s alu_result;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

    function new(string name = "");
        super.new(name);
    endfunction : new

//------------------------------------------------------------------------------
// transaction methods - do_copy, convert2string, do_compare
//------------------------------------------------------------------------------

    function void do_copy(uvm_object rhs);
        result_transaction copied_transaction_h;
        assert(rhs != null) else
            `uvm_fatal("RESULT TRANSACTION","Tried to copy null transaction");
        super.do_copy(rhs);
        assert($cast(copied_transaction_h,rhs)) else
            `uvm_fatal("RESULT TRANSACTION","Failed cast in do_copy");
        alu_result.rcv_data = copied_transaction_h.alu_result.rcv_data;
        alu_result.rcv_control_packet = copied_transaction_h.alu_result.rcv_control_packet;
    endfunction : do_copy

    function string convert2string();
        string s;
        s = $sformatf("result data: %8h, ctl: %2h",alu_result.rcv_data, alu_result.rcv_control_packet);
        return s;
    endfunction : convert2string

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        result_transaction RHS;
        bit same;
        assert(rhs != null) else
            `uvm_fatal("RESULT TRANSACTION","Tried to compare null transaction");

        same = super.do_compare(rhs, comparer);

		assert($cast(RHS, rhs)) begin
        same = (alu_result == RHS.alu_result) && same;
		end else begin
			same = 1'b0;
		end
        return same;
    endfunction : do_compare



endclass : result_transaction