interface alu_bfm;
	import alu_pkg::*;

	/**
	 * Signals
	 */

	bit clk, rst_n, sin, sout;

	logic  [31:0]  A, B, rcv_data;
	logic  [7:0]   rcv_control_packet, error_response;
	bit done, error_state;
	operation_t op_set;
	processing_error_t error_code;
	

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

		  `ifdef DEBUG
		$display("*** ALU RESET ***");
		   `endif

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

	task process_instruction (input logic  [31:0] A, input logic  [31:0] B, input operation_t opcode);
		begin
			logic [3:0] crc;

			for (int i = 3; i >= 0; i--) begin
				send_packet(DATA, B [8*i +: 8]);
			end

			for (int i = 3; i >= 0; i--) begin
				send_packet(DATA, A [8*i +: 8]);
			end

			crc = CRC4_D68({B, A, 1'b1, opcode}, 4'b0);
			send_packet(CMD, {1'b0, opcode, crc});
		end
	endtask

	task process_ALU_response (output logic  [31:0] data, logic [7:0] ctl);
		begin
			logic [39:0] maximum_response;
			automatic logic [2:0] i = 3'd4;
			packet_type_t packet;

			do begin
				receive_packet(maximum_response [8*i +: 8], packet);
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

		set_done();

	endtask

	task test_alu_processing_error (output logic [7:0] ctl, input processing_error_t Alu_error);
		begin
			automatic logic [31:0] A = $urandom, B = $urandom;
			operation_t  operation;
			packet_type_t ALU_reponse_type;
			logic [31:0] ALU_data;
			logic [5:0] err_flags;
			logic [3:0] crc;
			logic [2:0] nr_of_packets;
			bit parity_bit;

			case(Alu_error)
				ERR_DATA:
				begin
					nr_of_packets = 2'($urandom_range(3,0));
					operation = operation_t'(3'($urandom_range(7,0)));

					for (int i = nr_of_packets; i >= 0; i--) begin
						send_packet(DATA, B [8*i +: 8]);
					end
					nr_of_packets = 2'($urandom_range(2,0));
					for (int i = nr_of_packets; i >= 0; i--) begin
						send_packet(DATA, A [8*i +: 8]);
					end
					crc = CRC4_D68({B, A, 1'b1, operation}, 4'b0);
					send_packet(CMD, {1'b0, operation, crc});
				end

				ERR_OP:
				begin
					operation = operation_t'(3'($urandom_range(7,6)));
					process_instruction(A,B,operation);
				end

				ERR_CRC:
				begin
					operation = operation_t'(3'($urandom_range(7,0)));

					for (int i = 3; i >= 0; i--) begin
						send_packet(DATA, B [8*i +: 8]);
					end
					for (int i = 3; i >= 0; i--) begin
						send_packet(DATA, A [8*i +: 8]);
					end

					crc = CRC4_D68({B, A, 1'b1, operation}, 4'b0);
					send_packet(CMD, {1'b0, operation, ~crc});
				end
			endcase

			process_ALU_response(ALU_data,ctl);

		end
	endtask

command_monitor command_monitor_h;

always @(posedge clk) begin : op_monitor
    static bit in_command = 0;
    alu_data_in_t alu_data_in;
    if (done) begin : start_high			//TODO change condition
        if (!in_command) begin : new_command
            alu_data_in.A  <= A;
            alu_data_in.B  <= B;
            alu_data_in.op_set <= op_set;
            command_monitor_h.write_to_monitor(alu_data_in);
        end : new_command
    end : start_high
    else // start low
        in_command = 0;
end : op_monitor

/*always @(negedge rst_n) begin : rst_monitor
    alu_data_s alu_data;
    alu_data.op_set <= RST_OP;
    if (command_monitor_h != null) //guard against VCS time 0 negedge
        command_monitor_h.write_to_monitor(alu_data);
end : rst_monitor*/

result_monitor result_monitor_h;

initial begin : result_monitor_thread
    forever begin
        @(posedge clk) ;
        if (done)
            result_monitor_h.write_to_monitor(rcv_data);
    end
end : result_monitor_thread

endinterface : alu_bfm
