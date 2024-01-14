
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
        self.clk = self.dut.rx_rgmii_clk

        self.rgmii_driver = RgmiiDriver(self.clk, self.dut.rx_rgmii_data, self.dut.rx_rgmii_ctl)
        self.monitor = DataValidMonitor(self.clk, self.dut.rx_data_out, self.dut.rx_data_valid, self.dut.rx_data_error)

        cocotb.start_soon(Clock(self.clk, 10, units='ns').start())

    def start(self):
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


@cocotb.test()
async def test_rgmii_rx(dut):
    '''Test for rmii receiver'''

    tb = TB(dut)
    tb.start()

    await ClockCycles(tb.clk, 20)

    num_bytes = 20000

    for _ in range(num_bytes):
        rand_byte = random.randint(0,255)
        valid = percent_generator(85)
        error = percent_generator(15)
        if valid and not error:
            tb.sb.put_nowait(rand_byte)
        await tb.rgmii_driver.send_byte(rand_byte, valid, error)

    await ClockCycles(tb.clk, 20)
    dut._log.info('Test done')

