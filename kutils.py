from subprocess import Popen, PIPE
import re
import random


BLANK_SPEC = """module BOUND
    imports MEV
    rule <k>
            %s
        => .
     </k>
    <S> .Map =>?S:Map </S>
    <M> .Set => .Set </M>
    <B> .List => ?A2 </B>
    ensures %s
endmodule
"""

def find_integer_bound(program, outfile, bound_clause, starting_value):
    bound = starting_value
    previous_output = ""
    output = ""
    while True:
        spec = BLANK_SPEC % (program, bound_clause % (bound))
        open("bound.k", "w").write(spec)
        print("Starting proof...")
        pipe = Popen("kprove -v --debug --default-claim-type all-path --z3-impl-timeout 500 bound.k", shell=True, stdout=PIPE, stderr=PIPE)
        output = pipe.stdout.read() + pipe.stderr.read()
        output = str(output, "utf-8")
        if "#True" in output:
            print("BOUND FOUND!", bound)
            print("Writing best configuration to", outfile, "...")
            print(previous_output)
            open(outfile, "w").write(previous_output)
            break
        output = output[output.find("<generatedTop>"):]
        output = output[:output.find("</generatedTop>")+15]
        print("Found new bound", output)
        if not "Uniswap in 0 |-> " in output and "<S>" in output:
            bound = 0
        else:
            bound = int(output.split("Uniswap in 0 |-> ")[1].split(" ")[0])
        print("-" * 15, "\nBETTER BOUND:", bound)
        previous_output = output
    print("All done :)")

