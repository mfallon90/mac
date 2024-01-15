
import random
import cocotb
import cocotb_bus
import logging
import sys 
from cocotb_bus.monitors.avalon import AvalonSTPkts as AvalonStMonitor
from cocotb_bus.scoreboard import Scoreboard
from cocotb_helpers import RgmiiDriver, EtherFrame
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import Timer, RisingEdge, ClockCycles, First, Combine


NUM_WORDS   = 200

class TB():
    def __init__(self, dut):
        '''
        This function initalizes the testbench, starts the clock
        and sets all input values to their default state

        :param self: Class instance
        :param dut: Top level HDL file
        '''
        self.dut = dut
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.sb = Queue()
        self._checker = None
        self.scoreboard = Scoreboard(dut)
        self.expected = []
        self.ether = EtherFrame()

        self.dut.rx_rgmii_data.value = 0
        self.dut.rx_rgmii_ctl.value = 0
        self.rx_rgmii_clk = self.dut.rx_rgmii_clk
        self.mac_clk = self.dut.mac_clk

        self.rgmii_driver = RgmiiDriver(self.rx_rgmii_clk, self.dut.rx_rgmii_data, self.dut.rx_rgmii_ctl)
        self.monitor = AvalonStMonitor(self.dut, "mac", self.mac_clk)
        self.scoreboard.add_interface(self.monitor, self.expected)

        cocotb.start_soon(Clock(self.rx_rgmii_clk, 10, units='ns').start())
        cocotb.start_soon(Clock(self.mac_clk, 10, units='ns').start())
        cocotb.start_soon(cycle_rst_n(self.dut.mac_rst_n, self.mac_clk))

        
def percent_generator(x):
    return random.randint(1,100) <= x

async def cycle_rst_n(rst_n, clk):
    rst_n.setimmediatevalue(0)
    await ClockCycles(clk, 10)
    rst_n.value = 1
    await ClockCycles(clk, 10)

@cocotb.test()
async def test_rgmii_rx(dut):
    '''Test for rgmii receiver'''

    tb = TB(dut)

    await ClockCycles(tb.mac_clk, 100)

    num_frames = 5

    for _ in range(num_frames):
        frame = tb.ether.gen_frame()
        tb.expected.append(frame)
        await tb.rgmii_driver.send_frame(tb.ether.preamble+frame)
        await ClockCycles(tb.rx_rgmii_clk, random.randint(tb.ether.ifg,200))

    await ClockCycles(tb.mac_clk, 20)
    dut._log.info('Test done')

