interface alu_bfm;
	import alu_pkg::*;


	/**
	 * Signals
	 */

	bit clk, rst_n = 1'b1, sin, sout;

	logic  [31:0]  A, B, rcv_data;
	logic  [7:0]   rcv_control_packet, error_response;
	bit done, error_state;
	operation_t op_set;
	processing_error_t error_code;
	alu_data_out_s alu_out;


	/**
	 * Local parameters
	 */

	localparam start_bit = 1'b0;
	localparam stop_bit  = 1'b1;


	/**
	 * Clock generator
	 */

	initial begin : clk_gen
		clk = 0;
		forever begin : clk_frv
			#10;
			clk = ~clk;
		end
	end


	/**
	 * Tasks and functions
	 */

	task reset_alu();

		//`ifdef DEBUG
		$display("*** ALU RESET ***");
		//`endif         //todo delete comments, leave ifdef

		@(negedge clk) ;
		rst_n = 1'b0;
		@(negedge clk) ;
		rst_n = 1'b1;
		sin = 1'b1;
		done = 1'b0;
		error_state = 1'b0;
	endtask : reset_alu

	task send_packet (input packet_type_t packet_type, byte data_byte);
		begin
			automatic logic [10:0] packet = {start_bit, packet_type, data_byte, stop_bit};

			for (int i = 0; i < 11; i++) begin
				@(negedge clk) ;
				sin = packet[10 - i];
			end
		end
	endtask : send_packet

	task receive_packet (output byte rcv_byte, output packet_type_t packet_type);
		begin
			@(negedge sout) ;

			for (int i = 0; i < 2; i++)
				@(negedge clk) ;

			packet_type = (sout == 1'b1) ? CMD : DATA;

			for (int i = 7; i >= 0; i--) begin
				@(negedge clk) ;
				rcv_byte[i] = sout;
			end

			@(negedge clk) ;
		end
	endtask : receive_packet

	task set_done ();
		@(negedge clk) ;
		done = 1'b1;
		@(negedge clk) ;
		done = 1'b0;
	endtask : set_done

//   - polynomial: x^4 + x^1 + 1
	function [3:0] CRC4_D68;
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

	task process_instruction (input alu_data_in_s command);
		begin
			logic [3:0] crc;
			alu_data_out_s alu_data_out;

			A = command.A;
			B = command.B;
			op_set = command.op_set;
			error_code = command.error_code;
			error_state = command.error_state;

			for (int i = 3; i >= 0; i--) begin
				send_packet(DATA, command.B [8*i +: 8]);
			end
			for (int i = 3; i >= 0; i--) begin
				send_packet(DATA, command.A [8*i +: 8]);
			end

			crc = CRC4_D68({command.B, command.A, 1'b1, command.op_set}, 4'b0);
			send_packet(CMD, {1'b0, command.op_set, crc});
			
			//process_ALU_response(alu_data_out);
			//alu_out = alu_data_out;
		end
	endtask

	task process_ALU_response (output alu_data_out_s alu_data_out);
		begin
			logic [39:0] maximum_response;
			automatic logic [2:0] i = 3'd4;
			packet_type_t packet;

			do begin
				receive_packet(maximum_response [8*i +: 8], packet);
				i--;
			end while (packet == DATA);

			if (i == 3'b111) begin                      //i - roll over
				alu_data_out.rcv_data = maximum_response[39:8];
				alu_data_out.rcv_control_packet = maximum_response[7:0];
			end
			else begin
				alu_data_out.rcv_control_packet = maximum_response[39:32];
			end
		end
		alu_out = alu_data_out;
		set_done();

	endtask

	task test_alu_processing_error (/*output alu_data_out_s alu_out,*/ input alu_data_in_s alu_in);
		begin
			packet_type_t   ALU_reponse_type;
			logic [31:0]    ALU_data;
			logic [5:0]     err_flags;
			logic [3:0]     crc;
			logic [2:0]     nr_of_packets;
			bit             parity_bit;

			case(alu_in.error_code)
				ERR_DATA:
				begin
					nr_of_packets = 2'($urandom_range(3,0));

					for (int i = nr_of_packets; i >= 0; i--) begin
						send_packet(DATA, alu_in.B [8*i +: 8]);
					end
					nr_of_packets = 2'($urandom_range(2,0));
					for (int i = nr_of_packets; i >= 0; i--) begin
						send_packet(DATA, alu_in.A [8*i +: 8]);
					end
					crc = CRC4_D68({alu_in.B, alu_in.A, 1'b1, alu_in.op_set}, 4'b0);
					send_packet(CMD, {1'b0, op_set, crc});
				end

				ERR_OP:
				begin
					alu_in.op_set = INVALID_OP;
					process_instruction(alu_in);
				end

				ERR_CRC:
				begin
					for (int i = 3; i >= 0; i--) begin
						send_packet(DATA, alu_in.B [8*i +: 8]);
					end
					for (int i = 3; i >= 0; i--) begin
						send_packet(DATA, alu_in.A [8*i +: 8]);
					end

					crc = CRC4_D68({alu_in.B, alu_in.A, 1'b1, alu_in.op_set}, 4'b0);
					send_packet(CMD, {1'b0, alu_in.op_set, ~crc});

				end
			endcase
			process_ALU_response(alu_out);
			alu_out.error_response = alu_out.rcv_control_packet;
		end
	endtask

	command_monitor command_monitor_h;

	always @(posedge clk) begin : op_monitor
		static bit in_command = 0;
		alu_data_in_s alu_data_in;
		if (done /*&& command_monitor_h != null*/) begin : start_high
//        if (!in_command) begin : new_command
			alu_data_in.A  = A;
			alu_data_in.B  = B;
			alu_data_in.op_set = op_set;
			alu_data_in.error_state = error_state;
			alu_data_in.error_code = error_code;
			command_monitor_h.write_to_monitor(alu_data_in);
			$display("OP_MONITOR TO CMD_MONITOR: %h, %h, %s, ERR=%d(%s)", alu_data_in.A, alu_data_in.B, alu_data_in.op_set.name(), alu_data_in.error_state, alu_data_in.error_code.name() );
//        end : new_command
		end : start_high
//    else // start low
//        in_command = 0;
	end : op_monitor

	always @(negedge rst_n) begin : rst_monitor
		alu_data_in_s alu_data;
		alu_data.op_set = RST_OP;
		if (command_monitor_h != null) //guard against VCS time 0 negedge
			command_monitor_h.write_to_monitor(alu_data);
	end : rst_monitor

	result_monitor result_monitor_h;

	initial begin : result_monitor_thread
		forever begin
			@(posedge clk) ;
			if (done) begin
				result_monitor_h.write_to_monitor(alu_out);
				$display("RESULT_MONITOR_THREAD: %h, %h, %h", alu_out.rcv_data, alu_out.rcv_control_packet, alu_out.error_response);
			end
		end
	end : result_monitor_thread

endinterface : alu_bfm
