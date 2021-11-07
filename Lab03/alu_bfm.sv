interface alu_bfm;
	import alu_pkg::*;

	/**
	 * Signals
	 */

	bit clk, rst_n, sin, sout;

	logic  [31:0]  A, B, rcv_data;
	logic  [7:0]   rcv_control_packet, error_response;
	bit done, error_state;
	wire [2:0] op;
	operation_t op_set;
	processing_error_t error_code;
	
	assign op = op_set;


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
	endtask

	task send_packet (input packet_t packet_type, byte data_byte);
		begin
			automatic logic [10:0] packet = {start_bit, packet_type, data_byte, stop_bit};

			for (int i = 0; i < 11; i++) begin
				@(negedge clk) ;
				sin = packet[10 - i];
			end
		end
	endtask

	task receive_packet (output byte rcv_byte, output packet_t packet_type);
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
	endtask

	task set_done ();
		done = 1'b1;
		@(negedge clk) ;
		done = 1'b0;
	endtask

endinterface : alu_bfm
