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

	function new(real w);
		super.new(w, w);
	endfunction : new

	function real get_area();
		return (height * width);
	endfunction : get_area

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


class shape_factory;

	static function shape make_shape(string figure,
			real width, real height = 0);

		case (figure)
			"rectangle" : begin
				rectangle rect_h;
				rect_h = new(width, height);
				return rect_h;
			end

			"square" : begin
				square sq_h;
				sq_h = new(width);
				return sq_h;
			end

			"triangle" : begin
				triangle tr_h;
				tr_h = new(width, height);
				return tr_h;
			end

			default :
				$fatal (1, {"Undefined geometric figure: ", figure});

		endcase // case (figure)

	endfunction : make_shape

endclass : shape_factory

/*class shape_reporter #(type T=shape);

 protected static T queues shape_storage[$];

 static function void cage_shape(T l);
 shape_storage.push_back(l);
 endfunction : cage_animal

 static function void report_shapes();
 $display("Reported shapes:");
 foreach (shape_storage[i])
 $display(shape_storage[i].get_name());
 endfunction : report_shapes

 endclass : animal_cage
 */

module top;

	initial begin

		int fd;
		string f_name;
		real f_w, f_h;
		shape shape_h1,shape_h2,shape_h3,shape_h4, fileshape;
		rectangle   rect_h;
		square  sq_h;
		triangle  tr_h;

		rect_h = new(2.5,3);
		sq_h = new(1.5);
		tr_h = new(2,3);

		rect_h.print();
		sq_h.print();
		tr_h.print();

		shape_h1 = shape_factory::make_shape("rectangle", 15, 2);
		shape_h1.print();
		shape_h2 = shape_factory::make_shape("square", 15);
		shape_h2.print();
		shape_h3 = shape_factory::make_shape("triangle", 3.333,2);
		shape_h3.print();
		//shape_h4 = shape_factory::make_shape("trapez", 3.333,2);
		//shape_h4.print();

		fd = $fopen("/student/akamien/Pobrane/lab04part1_shapes.txt", "r");
		if (fd) $display("File opened SUCESSFULLY");
		else $display("File opening FAILED");
		while ($fscanf(fd, "%s %f %f", f_name, f_w, f_h) == 3) begin
			fileshape = shape_factory::make_shape(f_name, f_w, f_h);
			fileshape.print();
		end
		$fclose(fd);
		
	/*
	 animal animal_h;
	 lion   lion_h;
	 chicken  chicken_h;
	 bit cast_ok;

	 animal_h = animal_factory::make_animal("lion", 15, "Mustafa");
	 animal_h.make_sound();

	 cast_ok = $cast(lion_h, animal_h);
	 if ( ! cast_ok)
	 $fatal(1, "Failed to cast animal_h to lion_h");

	 if (lion_h.thorn_in_paw) $display("He looks angry!");
	 animal_cage#(lion)::cage_animal(lion_h);

	 if (!$cast(lion_h, animal_factory::make_animal("lion", 2, "Simba")))
	 $fatal(1, "Failed to cast animal from factory to lion_h");

	 animal_cage#(lion)::cage_animal(lion_h);

	 if(!$cast(chicken_h ,animal_factory::make_animal("chicken", 1, "Clucker")))
	 $fatal(1, "Failed to cast animal factory result to chicken_h");

	 animal_cage #(chicken)::cage_animal(chicken_h);

	 if(!$cast(chicken_h, animal_factory::make_animal("chicken", 1, "Boomer")))
	 $fatal(1, "Failed to cast animal factory result to chicken_h");

	 animal_cage #(chicken)::cage_animal(chicken_h);

	 $display("-- Lions --");
	 animal_cage #(lion)::list_animals();
	 $display("-- Chickens --");
	 animal_cage #(chicken)::list_animals();
	 */
	end

endmodule : top

