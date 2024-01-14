
import random
import cocotb
import logging
import sys
sys.path.append("../../../..")
import test_classes
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

        self.dut.rx_data.value = 0
        self.dut.rx_dv.value = 0
        self.dut.rx_er.value = 0
        self.dut.crs.value = 0
        self.dut.col.value = 0

        self.clk = self.dut.rx_clk

        self.rmii_driver = test_classes.RmiiDriver(self.clk, self.dut.rx_data, self.dut.rx_dv)

        cocotb.start_soon(Clock(self.clk, 10, units='ns').start())


    async def uart_check(self):
        '''
        Method to check data against scoreboard
        '''
        await RisingEdge(self.dut.uart_word_vld)
        uart_word = self.dut.uart_word
        sb_word = await self.sb.get()
        self.log.info(f'Sent {int(sb_word)}, Received {int(uart_word)}')
        assert (uart_word == sb_word)


async def cycle_rst_n(rst_n, clk):
    rst_n.setimmediatevalue(0)
    await RisingEdge(clk)
    await RisingEdge(clk)
    rst_n.value = 1
    await RisingEdge(clk)
    await RisingEdge(clk)

 
@cocotb.test()
async def test_rmii_rx(dut):
    '''Test for rmii receiver'''

    tb = TB(dut)

    cocotb.start_soon(cycle_rst_n(tb.dut.rx_rst_n, tb.clk))

    await ClockCycles(tb.clk, 99)

    message = [0x5,0x5,0x5,0x5,0x5,0xd]

    await tb.rmii_driver.send(message)

    for _ in range(NUM_WORDS):
        await tb.rmii_driver.send()

    await ClockCycles(tb.clk, 100)
    dut._log.info('Test done')

