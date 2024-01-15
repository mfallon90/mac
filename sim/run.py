import os
import cocotb_test.simulator
import sys


##########################################
##           TEST SETUP                 ##
##########################################

root = os.path.abspath('.')
hdl_dir = os.path.join(root, 'hdl')
sim_dir = os.path.join(root, 'sim')
dep_dir = os.path.join(root, 'deps')
sys.path.extend([sim_dir, dep_dir])

top = "rgmii"
modules = ["test_rgmii_rx"]

def test(top, test):
    os.chdir(sim_dir)
    cocotb_test.simulator.run(
        verilog_sources=[
            os.path.join(hdl_dir,"rgmii.sv"),
            os.path.join(hdl_dir,"rgmii_rx.sv"),
            os.path.join(hdl_dir,"crc32.sv"),
            os.path.join(dep_dir,"primitives/async_fifo/hdl/async_fifo.v"),
            os.path.join(dep_dir,"primitives/async_fifo/hdl/bin_gry_ctr.v"),
            os.path.join(dep_dir,"primitives/async_fifo/hdl/fifo_bram.v"),
            os.path.join(dep_dir,"primitives/delay/hdl/delay.sv"),
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
