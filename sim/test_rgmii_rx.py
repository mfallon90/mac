
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

DEST    = b'\x00\x1E\xC0\x90\xA0\x37'
SRC     = b'\x38\x87\xD5\xD6\xE4\x08'
TYPE    = b'\x08\x00'
HELLO   = b'\x48\x65\x6C\x6C\x6F'
WORLD   = b'\x20\x57\x6F\xF2\x6C\x64'
CRC     = b'\x5A\x60\x29\x1A'

test_frame = b'\xaa\xaa\xaa\xaa\xaa\xaa\x55\x55\x55\x55\x55\x55\x00\x04\xbe\xef'
dest = b'\xaa\xaa\xaa\xaa\xaa\xaa'
src = b'\x55\x55\x55\x55\x55\x55'
ethertype = b'\x00\x04'
data = b'\xbe\xef'

# DEST    = b'\x01\x00\x5E\x28\x64\x01'
# SRC     = b'\x2C\xFA\xA2\xA7\x4F\x81'
# TYPE    = b'\x08\x00'
# DATA1   = b'\x46\xC0\x00\x20\xC6\xC9\x00\x00'
# DATA2   = b'\x01\x02\xF4\xE6\x82\xBF\xA0\xFE'
# DATA3   = b'\xE0\xA8\x64\x01\x94\x04\x00\x00'
# DATA4   = b'\x11\x0A\xAA\x4B\xE0\xA8\x64\x01'
# DATA5   = b'\x00\x00\x00\x00\x00\x00\x00\x00'
# DATA6   = b'\x00\x00\x00\x00\x00\x00'
# CRC     = b'\xD0\x1D\x41\x1B'
# dest = b'\x33\x33\xff\x8d\xdf\x89'
# src =  b'\x04\x7b\xcf\xe6\xbf\x3e'
# ethertype = b'\x86\xdd'
# data = b'\x60\x00\x00\x00\x00\x20\x3b\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\xff\x8d\xdf\x89\x87\x00\x34\x95\x00\x00\x00\x00\xfe\x88\x00\x00\x00\x00\x00\x80\x1d\x3c\x17\xa8\xdc\x8d\xdf\x89\x0e\x01\x6c\xee\x22\xff\xff\x9d'
# crc = b'\x78\x4e\x34\x22'


# frame = DEST+SRC+TYPE+DATA1+DATA2+DATA3+DATA4+DATA5+DATA6

# frame = dest+src+ethertype+data

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

    num_frames = 1
    # frame = tb.ether.gen_frame(dst=DEST, src=SRC, type=TYPE, data=HELLO+WORLD)
    # test_frame = tb.ether.gen_frame(dst=dest, src=src, type=ethertype, data=data)

    new_frame = b'\xaa\xaa\xaa\xaa\xaa\xaa\x55\x55\x55\x55\x55\x55\x88\xb5\xde\xad\xbe\xef'
    new_frame = tb.ether.gen_frame(dst=b'\xaa\xaa\xaa\xaa\xaa\xaa',src=b'\x55\x55\x55\x55\x55\x55', type=b'\x88\xb5', data=b'\xde\xad\xbe\xef')
    new_crc = tb.ether.get_crc32(new_frame)
    print(hex(int.from_bytes(new_crc)))
    

    for _ in range(num_frames):
        # crc = tb.ether.get_crc32(test_frame)
        # print(hex(int.from_bytes(crc)))
        tb.expected.append(new_frame)
        await tb.rgmii_driver.send_frame(tb.ether.preamble + new_frame + new_crc)
        await ClockCycles(tb.rx_rgmii_clk, random.randint(tb.ether.ifg,200))

    await ClockCycles(tb.mac_clk, 20)
    dut._log.info('Test done')

