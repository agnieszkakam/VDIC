virtual class shape;
	protected real width;
	protected real height;

	function new(real w, real h);
		width = w;
		height = h;
	endfunction : new

	pure virtual function real get_area();
	pure virtual function void print();

endclass : shape

class rectangle extends shape;

	function new(real w, real h);
		super.new(w, h);
	endfunction : new

	function real get_area();
		return (height * width);
	endfunction : get_area

	function void print();
		$display ("Rectangle. Width: %g, height: %g. Area: %g.", width, height, get_area());
	endfunction : print

endclass : rectangle

class square extends rectangle;

	function new(real side);
		super.new(side, side);
	endfunction : new

	function void print();
		$display ("Square. Width: %g. Area: %g.", width, get_area());
	endfunction : print

endclass : square

class triangle extends shape;

	function new(real base, real h);
		super.new(base, h);
	endfunction : new

	function real get_area();
		return (height * width * 0.5);
	endfunction : get_area

	function void print();
		$display ("Triangle. Base: %g, height: %g. Area: %g.", width, height, get_area());
	endfunction : print

endclass : triangle


class shape_reporter #(type T=shape);

	protected static T shape_storage[$];

	static function void capture_shape(T l);
		shape_storage.push_back(l);
	endfunction : capture_shape

	static function void report_shapes();
		real TotalArea = 0;
		foreach (shape_storage[i]) begin
			shape_storage[i].print();
			TotalArea = TotalArea + shape_storage[i].get_area();
		end
		$display("Total Area: %g\n", TotalArea);
	endfunction : report_shapes

endclass : shape_reporter

class shape_factory;

	static function shape make_shape(string figure,
			real width, real height = 0);

		case (figure)
			"rectangle" : begin
				rectangle rect_h;
				rect_h = new(.w(width), .h(height));
				shape_reporter #(rectangle)::capture_shape(rect_h);
				return rect_h;
			end

			"square" : begin
				square sq_h;
				sq_h = new(.side(width));
				shape_reporter #(square)::capture_shape(sq_h);
				return sq_h;
			end

			"triangle" : begin
				triangle tr_h;
				tr_h = new(.base(width), .h(height));
				shape_reporter #(triangle)::capture_shape(tr_h);
				return tr_h;
			end

			default :
				$fatal (1, {"Undefined geometric figure: ", figure});

		endcase // case (figure)

	endfunction : make_shape

endclass : shape_factory


module top;

	initial begin

		int fd;
		string f_name;
		real f_w, f_h;
		shape shape_h;

		fd = $fopen("./lab04part1_shapes.txt", "r");
		
		if (fd) $display("File opened SUCESSFULLY\n");
		else 	$display("File opening FAILED\n");
		
		while ($fscanf(fd, "%s %f %f", f_name, f_w, f_h) == 3) begin
			shape_h = shape_factory::make_shape(f_name, f_w, f_h);
		end
		
		$fclose(fd);

		$display("Reported shapes:\n");
		shape_reporter #(rectangle)::report_shapes();
		shape_reporter #(square)::report_shapes();
		shape_reporter #(triangle)::report_shapes();
		
	end

endmodule : top

