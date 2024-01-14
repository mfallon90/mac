import os
from cocotb_test.simulator import run
import sys


##########################################
##           TEST SETUP                 ##
##########################################

root = os.path.abspath('.')
hdl_dir = os.path.join(root, 'hdl')
sim_dir = os.path.join(root, 'sim')
dep_dir = os.path.join(root, 'deps')
sys.path.extend([sim_dir, dep_dir])

top = "rgmii_rx"
modules = ["test_rgmii_rx"]

def test(top, test):
    os.chdir(sim_dir)
    run(
        verilog_sources=[
            os.path.join(hdl_dir,"rgmii_rx.sv"),
        ],
        toplevel=top,
        module=test
    )


##########################################
##              RUN TEST                ##
##########################################


if __name__ == "__main__":
    for module in modules:
        test(top, module)
