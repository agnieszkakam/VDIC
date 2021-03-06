module apple_tb ();


/**
 * Local variables and signals
 */

reg a, b, clk;
wire q;


/**
 * UUT Instantiation
 */

apple u_apple (
	.a  (a),
	.b  (b),
	.clk(clk),
	.q  (q)
);


/**
 * Clock generation
 */
 
always #5 clk = ~clk;


/**
 * Test
 */

initial begin
	a = 1'b1;
	b = 1'b1;
	clk = 1'b0;
	
	@(posedge clk) ;
	for (int i=0; i<2; i++) begin
		a = i[0];
		for (int j=0; j<2; j++) begin
			b = j[0];
			
			@(negedge clk) ;
			assert (q == (a & b)) else
        		$error("configuration: rcv: %b, exp: %b", q, a & b);
		end
	end
	$stop;
end

endmodule
