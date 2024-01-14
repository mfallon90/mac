
import random
import cocotb
import logging
import sys
from cocotb_helpers import RgmiiDriver, DataValidMonitor
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

        self.dut.rx_rgmii_data.value = 0
        self.dut.rx_rgmii_ctl.value = 0
        self.rx_rgmii_clk = self.dut.rx_rgmii_clk
        self.sys_clk = self.dut.sys_clk

        self.rgmii_driver = RgmiiDriver(self.rx_rgmii_clk, self.dut.rx_rgmii_data, self.dut.rx_rgmii_ctl)
        self.monitor = DataValidMonitor(self.sys_clk, self.dut.rx_data, self.dut.rx_data_valid)

        cocotb.start_soon(Clock(self.rx_rgmii_clk, 10, units='ns').start())
        cocotb.start_soon(Clock(self.sys_clk, 10, units='ns').start())
        cocotb.start_soon(cycle_rst_n(self.dut.sys_rst_n, self.sys_clk))

    async def start(self):
        if self._checker is not None:
            raise RuntimeError("Monitor already started")
        self.monitor.start()
        self._checker = cocotb.start_soon(self._check())

    async def _check(self):
        while True:
            actual = await self.monitor.values.get()
            expected = await self.sb.get()
            if actual != expected:
                self.log.info("Actual:   {}".format(hex(int(actual))))
                self.log.info("Expected: {}".format(hex(int(expected))))
            assert actual == expected
        
def percent_generator(x):
    return random.randint(1,100) < x

async def cycle_rst_n(rst_n, clk):
    rst_n.setimmediatevalue(0)
    await ClockCycles(clk, 10)
    rst_n.value = 1
    await ClockCycles(clk, 10)

@cocotb.test()
async def test_rgmii_rx(dut):
    '''Test for rgmii receiver'''

    tb = TB(dut)
    await tb.start()

    await ClockCycles(tb.sys_clk, 100)

    num_bytes = 2000

    for _ in range(num_bytes):
        rand_byte = random.randint(0,255)
        valid = percent_generator(85)
        error = percent_generator(15)
        if valid:
            await tb.sb.put(rand_byte)
        await tb.rgmii_driver.send_byte(rand_byte, valid, error)

    await ClockCycles(tb.sys_clk, 20)
    dut._log.info('Test done')

