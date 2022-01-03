class scoreboard extends uvm_subscriber #(result_transaction);

	`uvm_component_utils(scoreboard)

	virtual alu_bfm bfm;
	uvm_tlm_analysis_fifo #(random_command) command_f;
	protected string test_result = "PASSED";

	protected function bit IsOverflow;
		input [31:0] A, B, result;
		input operation_t opcode;
		begin
			case(opcode)
				ADD_OP:     IsOverflow = ((!A[31] && !B[31] && result[31]) || (A[31] && B[31] && !result[31]));
				SUB_OP:     IsOverflow = (1'b1 ~^ !A[31] ~^ B[31]) && (!A[31] ^ result[31]);
				default:    IsOverflow = 1'b0;
			endcase
		end
		return(IsOverflow);
	endfunction

	protected function generate_parity_bit(input logic [6:0] data);
		begin
			bit parity_bit;
			automatic logic [2:0] sum = 3'b0;
			for(int bit_nr = 0; bit_nr < 7; bit_nr++) begin
				sum = (data[bit_nr]) ? sum++ : sum;
			end
			parity_bit = !(sum % 2);
			return parity_bit;
		end
	endfunction

// polynomial: x^3 + x^1 + 1
// data width: 37
// convention: the first serial bit is D[36]
	protected function [2:0] CRC3_D37;

		input [36:0] Data;
		input [2:0] crc;
		reg [36:0] d;
		reg [2:0] c;
		reg [2:0] newcrc;
		begin
			d = Data;
			c = crc;

			newcrc[0] = d[35] ^ d[32] ^ d[31] ^ d[30] ^ d[28] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ d[18] ^ d[17] ^ d[16] ^ d[14] ^ d[11] ^ d[10] ^ d[9] ^ d[7] ^ d[4] ^ d[3] ^ d[2] ^ d[0] ^ c[1];
			newcrc[1] = d[36] ^ d[35] ^ d[33] ^ d[30] ^ d[29] ^ d[28] ^ d[26] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[16] ^ d[15] ^ d[14] ^ d[12] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[2] ^ d[1] ^ d[0] ^ c[1] ^ c[2];
			newcrc[2] = d[36] ^ d[34] ^ d[31] ^ d[30] ^ d[29] ^ d[27] ^ d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[17] ^ d[16] ^ d[15] ^ d[13] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[3] ^ d[2] ^ d[1] ^ c[0] ^ c[2];
			CRC3_D37 = newcrc;
		end
	endfunction

	protected function result_transaction get_expected_result (random_command cmd);
		begin
			result_transaction predicted;
			logic  [32:0] result_data_33b;
			logic  [39:0] result_packet;
			logic  [31:0] A,B;
			operation_t op_set;

			predicted = new("predicted");
			A = cmd.alu_command.A;
			B = cmd.alu_command.B;
			op_set = cmd.alu_command.op_set;

			case(cmd.alu_command.op_set)
				AND_OP: begin
					result_packet[39:8] = A & B;
					result_data_33b = A & B;
					result_packet[7] = 1'b0;
					result_packet[6:3] = {result_data_33b[32], IsOverflow(A, B, result_packet[39:8], op_set), (result_packet[39:8] == 0), result_packet[39]};        /*Carry, Overflow, Zero, Negative*/
					result_packet[2:0] = CRC3_D37({result_packet[39:8], 1'b0, result_packet[6:3]}, 3'b0);
				end
				ADD_OP: begin
					result_packet[39:8] = A + B;
					result_data_33b = A + B;
					result_packet[7] = 1'b0;
					result_packet[6:3] = {result_data_33b[32], IsOverflow(A, B, result_packet[39:8], op_set), (result_packet[39:8] == 0), result_packet[39]};
					result_packet[2:0] = CRC3_D37({result_packet[39:8], 1'b0, result_packet[6:3]}, 3'b0);
				end
				OR_OP : begin
					result_packet[39:8] = A | B;
					result_data_33b = A | B;
					result_packet[7] = 1'b0;
					result_packet[6:3] = {result_data_33b[32], IsOverflow(A, B, result_packet[39:8], op_set), (result_packet[39:8] == 0), result_packet[39]};
					result_packet[2:0] = CRC3_D37({result_packet[39:8], 1'b0, result_packet[6:3]}, 3'b0);
				end
				SUB_OP: begin
					result_packet[39:8] = B - A;
					result_data_33b = B - A;
					result_packet[7] = 1'b0;
					result_packet[6:3] = {result_data_33b[32], IsOverflow(A, B, result_packet[39:8], op_set), (result_packet[39:8] == 0), result_packet[39]};
					result_packet[2:0] = CRC3_D37({result_packet[39:8], 1'b0, result_packet[6:3]}, 3'b0);
				end
				INVALID_OP  : begin
					result_packet[7] = 1'b1;
					result_packet[6:1] = {2{ERR_OP}};
					result_packet[0] = generate_parity_bit(result_packet[7:1]);
				end
				RST_OP: begin end
				default: begin
					$display("%0t INTERNAL ERROR. get_expected_result_data: unexpected case argument: %s", $time, op_set);
					test_result = "FAILED";
				end
			endcase

			predicted.alu_result.rcv_control_packet = result_packet[7:0];
			predicted.alu_result.rcv_data = result_packet[39:8];
			return predicted;
		end
	endfunction

	protected function result_transaction get_expected_error_packet (random_command cmd);
		begin
			result_transaction exp_result;
			bit parity_bit;
			automatic logic [5:0] err_flags = {2{cmd.alu_command.error_code}};

			exp_result = new("exp_result");

			parity_bit = generate_parity_bit({1'b1,err_flags});
			exp_result.alu_result.rcv_control_packet = {1'b1, err_flags, parity_bit};
			exp_result.alu_result.rcv_data = 32'h0000_0000;
			return exp_result;
		end
	endfunction

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		command_f = new ("command_f", this);
	endfunction : build_phase

	function void write(result_transaction t);

		string data_str;
		result_transaction predicted;
		random_command cmd;

		logic [39:0] exp_packet;
		logic [31:0] exp_result;
		logic [7:0] exp_ctl;

		do
			if (!command_f.try_get(cmd))
				$fatal(1, "Missing command in self checker");
		while (cmd.alu_command.op_set == RST_OP);

		case (cmd.alu_command.error_state)
			1'b0: begin     : CHK_NOMINAL
				predicted = get_expected_result(cmd);
			end
			1'b1: begin : CHK_ERR
				predicted = get_expected_error_packet(cmd);
			end
		endcase

		data_str = { cmd.convert2string(),
			"  ==> Actual ", t.convert2string(),
			"/Predicted ", predicted.convert2string()};

		if (!predicted.compare(t)) begin
			`uvm_error("SELF CHECKER", {"\nFAIL: ", data_str});
			test_result = "FAILED";
		end else begin
			`uvm_info("SELF CHECKER", {"\nPASS: ", data_str}, UVM_HIGH);
		end


	endfunction : write

	function void report_phase(uvm_phase phase);
		$display("\n\t\t\t\t************************************************************\n\
				  \t\t************************************************************\n\
				  \t\t************************************************************\n\
				  \t\t******************** Test %s.***********************\n\
				  \t\t************************************************************\n\
				  \t\t************************************************************\n\
				  \t\t************************************************************\n",test_result);
	endfunction : report_phase


endclass : scoreboard
