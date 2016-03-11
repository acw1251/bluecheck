// This example tests a Bool prop with a guard. This caused a compilation error
// in older versions of Bluecheck.
import Clocks::*;
import StmtFSM::*;
import BlueCheck::*;
import ClientServer::*;

// Only lets even numbers pass through
interface EvenFilter;
    method Action enq(Bit#(4) x);
    method Bit#(4) first;
    method Action deq;
endinterface

module mkEvenFilter(EvenFilter);
    Reg#(Bit#(4)) data <- mkReg(0);
    Reg#(Bool) valid <- mkReg(False);

    method Action enq(Bit#(4) x) if (!valid);
        // only enqueue if even
        if (x[0] == 0) begin
            data <= x;
            valid <= True;
        end
    endmethod

    method Bit#(4) first if (valid);
        return data;
    endmethod

    method Action deq if (valid);
        valid <= False;
    endmethod
endmodule

module [BlueCheck] checkBoolProp#(Reset soft_rst)(Empty);
    EvenFilter dut <- mkEvenFilter;

    function Bool check_output();
        return ((dut.first)[0] == 0);
    endfunction

    function Action enq(Bit#(4) x);
        return (action
                dut.enq(x);
            endaction);
    endfunction

    function Action deq;
        return (action
                dut.deq;
            endaction);
    endfunction

    prop("check_output", check_output);
    prop("enq", enq);
    prop("deq", deq);
endmodule

(* synthesize *)
module [Module] mkBoolPropExample(Empty);
    Clock clk <- exposeCurrentClock;
    MakeResetIfc my_rst <- mkReset(0, True, clk);
    Reset soft_rst = my_rst.new_rst;

    // Iterative Deepening
    BlueCheck_Params my_params = bcParams;
    ID_Params my_id_params = ID_Params {rst: my_rst, initialDepth: 10, testsPerDepth: 100, incDepth: ( ( \+ )(10) )};
    my_params.verbose = True;
    my_params.showTime = True;
    my_params.wedgeDetect = True;
    my_params.useIterativeDeepening = True;
    my_params.id = my_id_params;
    my_params.useShrinking = True;

    Stmt s <- mkModelChecker(checkBoolProp(soft_rst), my_params);
    mkAutoFSM(s);
endmodule
