virtual class base_tester extends uvm_component;

`uvm_component_utils(base_tester)

	virtual alu_bfm bfm;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
            $fatal(1,"Failed to get BFM");
    endfunction : build_phase

//   - polynomial: x^4 + x^1 + 1
	protected function [3:0] CRC4_D68;
		input [67:0] Data;
		input [3:0] crc;
		reg [67:0] d;
		reg [3:0] c, newcrc;
		begin
			d = Data;
			c = crc;

			newcrc[0] = d[66] ^ d[64] ^ d[63] ^ d[60] ^ d[56] ^ d[55] ^ d[54] ^ d[53] ^ d[51] ^ d[49] ^ d[48] ^ d[45] ^ d[41] ^ d[40] ^ d[39] ^ d[38] ^ d[36] ^ d[34] ^ d[33] ^ d[30] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ d[19] ^ d[18] ^ d[15] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[4] ^ d[3] ^ d[0] ^ c[0] ^ c[2];
			newcrc[1] = d[67] ^ d[66] ^ d[65] ^ d[63] ^ d[61] ^ d[60] ^ d[57] ^ d[53] ^ d[52] ^ d[51] ^ d[50] ^ d[48] ^ d[46] ^ d[45] ^ d[42] ^ d[38] ^ d[37] ^ d[36] ^ d[35] ^ d[33] ^ d[31] ^ d[30] ^ d[27] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[18] ^ d[16] ^ d[15] ^ d[12] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[1] ^ d[0] ^ c[1] ^ c[2] ^ c[3];
			newcrc[2] = d[67] ^ d[66] ^ d[64] ^ d[62] ^ d[61] ^ d[58] ^ d[54] ^ d[53] ^ d[52] ^ d[51] ^ d[49] ^ d[47] ^ d[46] ^ d[43] ^ d[39] ^ d[38] ^ d[37] ^ d[36] ^ d[34] ^ d[32] ^ d[31] ^ d[28] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[17] ^ d[16] ^ d[13] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[2] ^ d[1] ^ c[0] ^ c[2] ^ c[3];
			newcrc[3] = d[67] ^ d[65] ^ d[63] ^ d[62] ^ d[59] ^ d[55] ^ d[54] ^ d[53] ^ d[52] ^ d[50] ^ d[48] ^ d[47] ^ d[44] ^ d[40] ^ d[39] ^ d[38] ^ d[37] ^ d[35] ^ d[33] ^ d[32] ^ d[29] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[18] ^ d[17] ^ d[14] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[3] ^ d[2] ^ c[1] ^ c[3];
			CRC4_D68 = newcrc;
		end
	endfunction

	pure virtual function [31:0] get_data();

	function operation_t get_op();
		automatic bit [2:0] op_choice = $random;
		case (op_choice)
			3'b000, 3'b001, 3'b100, 3'b101, 3'b110 : return operation_t'(op_choice);
			default: return INVALID_OP;
		endcase // case (op_choice)
	endfunction : get_op

	protected task get_error_code (output processing_error_t error_code);
		begin
			error_code = processing_error_t'(3'b000);
			error_code[$urandom_range(2,0)] = 1'b1;
		end
	endtask

	protected task process_instruction (input logic  [31:0] A, input logic  [31:0] B, input operation_t opcode);
		begin
			logic [3:0] crc;

			for (int i = 3; i >= 0; i--) begin
				bfm.send_packet(DATA, B [8*i +: 8]);
			end

			for (int i = 3; i >= 0; i--) begin
				bfm.send_packet(DATA, A [8*i +: 8]);
			end

			crc = CRC4_D68({B, A, 1'b1, opcode}, 4'b0);
			bfm.send_packet(CMD, {1'b0, opcode, crc});
		end
	endtask

	protected task process_ALU_response (output logic  [31:0] data, logic [7:0] ctl);
		begin
			logic [39:0] maximum_response;
			automatic logic [2:0] i = 3'd4;
			packet_t packet;

			do begin
				bfm.receive_packet(maximum_response [8*i +: 8], packet);
				i--;
			end while (packet == DATA);

			if (i == 3'b111) begin                      //i - roll over
				data = maximum_response[39:8];
				ctl = maximum_response[7:0];
			end
			else begin
				ctl = maximum_response[39:32];
			end
		end

		bfm.set_done();

	endtask

	protected task test_alu_processing_error (output logic [7:0] ctl, input processing_error_t Alu_error);
		begin
			automatic logic [31:0] A = $urandom, B = $urandom;
			operation_t  operation;
			packet_t ALU_reponse_type;
			logic [31:0] ALU_data;
			logic [5:0] err_flags;
			logic [3:0] crc;
			logic [2:0] nr_of_packets;
			bit parity_bit;

			case(Alu_error)
				ERR_DATA:
				begin
					nr_of_packets = 2'($urandom_range(3,0));
					operation = get_op();

					for (int i = nr_of_packets; i >= 0; i--) begin
						bfm.send_packet(DATA, B [8*i +: 8]);
					end
					nr_of_packets = 2'($urandom_range(2,0));
					for (int i = nr_of_packets; i >= 0; i--) begin
						bfm.send_packet(DATA, A [8*i +: 8]);
					end
					crc = CRC4_D68({B, A, 1'b1, operation}, 4'b0);
					bfm.send_packet(CMD, {1'b0, operation, crc});
				end

				ERR_OP:
				begin
					operation = operation_t'(3'($urandom_range(7,6)));
					process_instruction(A,B,operation);
				end

				ERR_CRC:
				begin
					operation = get_op();

					for (int i = 3; i >= 0; i--) begin
						bfm.send_packet(DATA, B [8*i +: 8]);
					end
					for (int i = 3; i >= 0; i--) begin
						bfm.send_packet(DATA, A [8*i +: 8]);
					end

					crc = CRC4_D68({B, A, 1'b1, operation}, 4'b0);
					bfm.send_packet(CMD, {1'b0, operation, ~crc});
				end
			endcase

			process_ALU_response(ALU_data,ctl);

		end
	endtask

	task run_phase(uvm_phase phase);

        phase.raise_objection(this);

		bfm.reset_alu();

		repeat (5000) begin : tester_main
			bfm.op_set = get_op();
			bfm.A  = get_data();
			bfm.B  = get_data();

			case (bfm.op_set)
				RST_OP: begin : rst_op
					bfm.reset_alu();
				end
				default: begin : norm_op
					process_instruction(bfm.A, bfm.B, bfm.op_set);
					process_ALU_response(bfm.rcv_data, bfm.rcv_control_packet);
				end
			endcase
		end

		@(negedge bfm.clk) ;

		repeat(1000) begin   : tester_errors
			bfm.op_set = get_op();
			bfm.A  = get_data();
			bfm.B  = get_data();

			bfm.error_state = 1'b1;
			get_error_code(bfm.error_code);
			test_alu_processing_error(bfm.error_response, bfm.error_code);
			bfm.error_state = 1'b0;
		end

        phase.drop_objection(this);

	endtask : run_phase
	
endclass