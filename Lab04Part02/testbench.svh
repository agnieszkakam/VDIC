class testbench;

    virtual alu_bfm bfm;
    tester tester_h;
    coverage coverage_h;
    scoreboard scoreboard_h;

    function new (virtual alu_bfm b);
        bfm = b;
    endfunction : new

    task execute();
        tester_h     = new(bfm);
        coverage_h   = new(bfm);
        scoreboard_h = new(bfm);

        fork
            coverage_h.execute();
            scoreboard_h.execute();
            tester_h.execute();
        join_none
    endtask : execute
    
endclass : testbench


