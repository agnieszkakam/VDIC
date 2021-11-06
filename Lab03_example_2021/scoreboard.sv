/*
 Copyright 2013 Ray Salemi

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */
module scoreboard(tinyalu_bfm bfm);
import tinyalu_pkg::*;

string test_result = "PASSED";
//------------------------------------------------------------------------------
// calculate expected result
//------------------------------------------------------------------------------
function logic [15:0] get_expected(
        bit [7:0] A,
        bit [7:0] B,
        operation_t op_set
    );
    bit [15:0] ret;
    `ifdef DEBUG
    $display("%0t DEBUG: get_expected(%0d,%0d,%0d)",$time, A, B, op_set);
    `endif
    case(op_set)
        and_op : ret    = A & B;
        add_op : ret    = A + B;
        mul_op : ret    = A * B;
        xor_op : ret    = A ^ B;
        default: begin
            $display("%0t INTERNAL ERROR. get_expected: unexpected case argument: %s", $time, op_set);
            test_result = "FAILED";
            return -1;
        end
    endcase
    return(ret);
endfunction


always @(negedge bfm.clk) begin
    if(bfm.done)begin
        automatic bit [15:0] expected = get_expected(bfm.A, bfm.B, bfm.op_set);
        assert(bfm.result === expected) begin
                        `ifdef DEBUG
            $display("Test passed for A=%0d B=%0d op_set=%0d", bfm.A, bfm.B, bfm.op);
                        `endif
        end
        else begin
            $display("Test FAILED for A=%0d B=%0d op_set=%0d", bfm.A, bfm.B, bfm.op);
            $display("Expected: %d  received: %d", expected, bfm.result);
            test_result = "FAILED";
        end;
    end
end

//------------------------------------------------------------------------------
final begin : finish_of_the_test
    $display("Test %s.",test_result);
end

endmodule : scoreboard






