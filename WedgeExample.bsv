import Clocks::*;
import StmtFSM::*;
import BlueCheck::*;

module [BlueCheck] checkWedge#(Reset soft_rst, Bool stmtWithGuard)(Empty);
    Reg#(Bit#(8)) r <- mkReg(0, reset_by soft_rst);

    function Action doStuff(Bit#(8) x);
        return (action
            r <= x;
        endaction);
    endfunction

    Stmt preStmt = (seq
        doStuff(0);
        delay(10);
    endseq);

    Stmt wedgeStmt = (seq
        delay(10);
        when( r != 'hFF, r._write(0) );
    endseq);

    Stmt postStmt = (seq
        delay(10);
    endseq);

    prop("doStuff", doStuff);
    if (stmtWithGuard)
      prop("wedgeStmt", stmtWhen(r != 'hFF, wedgeStmt));
    else
      prop("wedgeStmt", wedgeStmt);
    pre("doPre", preStmt);
    post("checkPost", postStmt);
endmodule

(* synthesize *)
module [Module] mkWedgeExample(Empty);
    Clock clk <- exposeCurrentClock;
    MakeResetIfc my_rst <- mkReset(0, True, clk);
    Reset soft_rst = my_rst.new_rst;

    // Iterative Deepening
    BlueCheck_Params my_params = bcParams;
    ID_Params my_id_params = ID_Params {rst: my_rst, initialDepth: 10, testsPerDepth: 100, incDepth: ( ( \+ )(10) )};
    my_params.verbose = True;
    my_params.showTime = True;
    // my_params.showNoOp = True;
    my_params.wedgeDetect = True;
    my_params.useIterativeDeepening = True;
    my_params.id = my_id_params;
    my_params.useShrinking = True;

    // BlueCheck_Params my_params = bcParams;
    // my_params.verbose = True;
    // my_params.showTime = True;
    // my_params.showNoOp = True;
    // my_params.wedgeDetect = True;
    // my_params.numIterations = 10;

    Stmt s <- mkModelChecker(checkWedge(soft_rst, False), my_params);
    mkAutoFSM(s);
endmodule

(* synthesize *)
module [Module] mkWedgeExampleWithGuardedStmt(Empty);
    Clock clk <- exposeCurrentClock;
    MakeResetIfc my_rst <- mkReset(0, True, clk);
    Reset soft_rst = my_rst.new_rst;

    // Iterative Deepening
    BlueCheck_Params my_params = bcParams;
    ID_Params my_id_params = ID_Params {rst: my_rst, initialDepth: 10, testsPerDepth: 100, incDepth: ( ( \+ )(10) )};
    my_params.verbose = True;
    my_params.showTime = True;
    // my_params.showNoOp = True;
    my_params.wedgeDetect = True;
    my_params.useIterativeDeepening = True;
    my_params.id = my_id_params;
    my_params.useShrinking = True;

    // BlueCheck_Params my_params = bcParams;
    // my_params.verbose = True;
    // my_params.showTime = True;
    // my_params.showNoOp = True;
    // my_params.wedgeDetect = True;
    // my_params.numIterations = 10;

    Stmt s <- mkModelChecker(checkWedge(soft_rst, True), my_params);
    mkAutoFSM(s);
endmodule


module [BlueCheck] checkWedge2#(Reset soft_rst)(Empty);
    Reg#(Bool) deadlock <- mkReg(False, reset_by soft_rst);
    Reg#(Bit#(8)) r <- mkReg(0, reset_by soft_rst);

    // Secret code for deadlock:
    //   action1(0xde)
    //   action2(0xad)

    function Action action1(Bit#(8) x);
        return when(!deadlock, action
            r <= x;
        endaction);
    endfunction

    function Action action2(Bit#(8) x);
        return when(!deadlock, action
            if (r == 'hde && x == 'had)
              deadlock <= True;
            else
              r <= 0;
        endaction);
    endfunction

    prop("action1", action1);
    prop("action2", action2);
endmodule

(* synthesize *)
module [Module] mkWedgeExample2(Empty);
    Clock clk <- exposeCurrentClock;
    MakeResetIfc my_rst <- mkReset(0, True, clk);
    Reset soft_rst = my_rst.new_rst;

    // Iterative Deepening
    BlueCheck_Params my_params = bcParams;
    ID_Params my_id_params = ID_Params {rst: my_rst, initialDepth: 10, testsPerDepth: 100, incDepth: ( ( \+ )(10) )};
    my_params.verbose = True;
    my_params.showTime = True;
    // my_params.showNoOp = True;
    my_params.wedgeDetect = True;
    my_params.useIterativeDeepening = True;
    my_params.id = my_id_params;
    my_params.useShrinking = True;

    // BlueCheck_Params my_params = bcParams;
    // my_params.verbose = True;
    // my_params.showTime = True;
    // my_params.showNoOp = True;
    // my_params.wedgeDetect = True;
    // my_params.numIterations = 10;

    Stmt s <- mkModelChecker(checkWedge2(soft_rst), my_params);
    mkAutoFSM(s);
endmodule
