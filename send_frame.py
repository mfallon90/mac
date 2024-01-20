from scapy.all import *

# p = Ether()/IP()/TCP()/UDP()/Raw("does this work \r\n")
p = Ether()/Raw("Hello, this is a message from the other side...\r\nDo you know how cool this is?!?!?!?!\r\n")

p.dst = '00:1E:C0:90:A0:37'

for _ in range(10):
    sendp(p, iface="enp82s0u2u1u2")

# p.show()
