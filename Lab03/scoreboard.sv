module scoreboard(alu_bfm bfm);
import alu_pkg::*;

string test_result = "PASSED";

	function bit IsOverflow;
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

    task generate_parity_bit(output bit parity_bit, input logic [6:0] data);
		begin
			automatic logic [2:0] sum = 3'b0;
			for(int bit_nr = 0; bit_nr < 7; bit_nr++) begin
				sum = (data[bit_nr]) ? sum++ : sum;
			end
			parity_bit = !(sum % 2);
		end
	endtask

// polynomial: x^3 + x^1 + 1
// data width: 37
// convention: the first serial bit is D[36]
	function [2:0] CRC3_D37;

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

    task get_expected_result ( output logic [31:0] result_data, logic [7:0] result_ctl, input bit  [31:0] A, bit  [31:0] B, operation_t op_set);
		begin

			logic  [32:0] result_data_33b;

			case(op_set)
				AND_OP: begin
					result_data = A & B;
					result_data_33b = A & B;
					result_ctl[7] = 1'b0;
					result_ctl[6:3] = {result_data_33b[32], IsOverflow(A, B, result_data, op_set), (result_data == 0), result_data[31]};        /*Carry, Overflow, Zero, Negative*/
					result_ctl[2:0] = CRC3_D37({result_data, 1'b0, result_ctl[6:3]}, 3'b0);
				end
				ADD_OP: begin
					result_data = A + B;
					result_data_33b = A + B;
					result_ctl[7] = 1'b0;
					result_ctl[6:3] = {result_data_33b[32], IsOverflow(A, B, result_data, op_set), (result_data == 0), result_data[31]};
					result_ctl[2:0] = CRC3_D37({result_data, 1'b0, result_ctl[6:3]}, 3'b0);
				end
				OR_OP : begin
					result_data = A | B;
					result_data_33b = A | B;
					result_ctl[7] = 1'b0;
					result_ctl[6:3] = {result_data_33b[32], IsOverflow(A, B, result_data, op_set), (result_data == 0), result_data[31]};
					result_ctl[2:0] = CRC3_D37({result_data, 1'b0, result_ctl[6:3]}, 3'b0);
				end
				SUB_OP: begin
					result_data = B - A;
					result_data_33b = B - A;
					result_ctl[7] = 1'b0;
					result_ctl[6:3] = {result_data_33b[32], IsOverflow(A, B, result_data, op_set), (result_data == 0), result_data[31]};
					result_ctl[2:0] = CRC3_D37({result_data, 1'b0, result_ctl[6:3]}, 3'b0);
				end
				INVALID_OP  : begin
					result_ctl[7] = 1'b1;
					result_ctl[6:1] = {2{ERR_OP}};
					generate_parity_bit(result_ctl[0], result_ctl[7:1]);
				end
				RST_OP: begin end
				default: begin
					$display("%0t INTERNAL ERROR. get_expected_result_data: unexpected case argument: %s", $time, op_set);
					test_result = "FAILED";
				end
			endcase
		end
	endtask

	task get_expected_error_packet (output logic [7:0] exp_error_packet, input processing_error_t error_type);
		begin
			bit parity_bit;
			automatic logic [5:0] err_flags = {2{error_type}};

			generate_parity_bit(parity_bit, {1'b1,err_flags});
			exp_error_packet = {1'b1, err_flags, parity_bit};
		end
	endtask

/*
always @(negedge bfm.clk) begin
    if(bfm.done)begin
        automatic bit [15:0] expected = get_expected(bfm.A, bfm.B, bfm.op_set);
        assert(bfm.result === expected) begin
                        `ifdef DEBUG
            $display("Test passed for A=%0d B=%0d op_set=%0d", bfm.A, bfm.B, bfm.op);
                        `endif
        end
        else begin
            $display("Test FAILED for A=%0d B=%0d op_set=%0d", bfm.A, bfm.B, bfm.op);
            $display("Expected: %d  received: %d", expected, bfm.result);
            test_result = "FAILED";
        end;
    end
end*/

initial 
	forever begin : scoreboard 
		@(negedge bfm.clk)  
		if(bfm.done) begin : verify_result
			logic [31:0] expected_data;
			logic [7:0]  expected_ctl_packet, exp_error_response;

			get_expected_result(expected_data, expected_ctl_packet, bfm.A, bfm.B, bfm.op_set);
			get_expected_error_packet(exp_error_response, bfm.error_code);

			@(posedge bfm.clk) ;
			case (bfm.error_state)
				1'b0: begin 
					assert(bfm.rcv_data === expected_data) begin : CHK_RESULT
		   `ifdef DEBUG
						$display("%0t Test passed for A=%08x B=%08x op_set=%s (data)", $time, A, B, op_set.name);
		   `endif
					end
					else begin
						$warning("%0t Test FAILED for A=%08x B=%08x op_set=%s (data)\nexp: %08x  rcv: %08x",
							$time, bfm.A, bfm.B, bfm.op_set.name, expected_data, bfm.rcv_data);
						test_result = "FAILED";
					end;

					assert(bfm.rcv_control_packet === expected_ctl_packet) begin : CHK_CTL
		   `ifdef DEBUG
						$display("%0t Test passed for A=%08x B=%08x op_set=%s (ctl)", $time, A, B, op_set.name);
		   `endif
					end
					else begin
						$warning("%0t Test FAILED for A=%08x B=%08x op_set=%s (ctl)\nexp: %08x  rcv: %08x",
							$time, bfm.A, bfm.B, bfm.op_set.name, expected_ctl_packet, bfm.rcv_control_packet);
						test_result = "FAILED";
					end;
				end

				1'b1: begin : CHK_ERR
					assert(exp_error_response === bfm.error_response) begin
		   `ifdef DEBUG
						$display("%0t Test passed for A=%08x B=%08x op_set=%s (%s)", $time, A, B, op_set.name, error_code.name);
		   `endif
					end
					else begin
						$warning("%0t Test FAILED for A=%08x B=%08x op_set=%s (%s)\nexp: %08b  rcv: %08b",
							$time, bfm.A, bfm.B, bfm.op_set.name, bfm.error_code.name, exp_error_response, bfm.error_response);
						test_result = "FAILED";
					end;
				end
			endcase
		end
	end : scoreboard

	final begin : finish_of_the_test
		$display("Test %s.",test_result);
	end

endmodule : scoreboard
