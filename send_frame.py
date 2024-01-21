from scapy.all import *
import random
import string

# p = Ether()/IP()/TCP()/UDP()/Raw("does this work \r\n")
# p = Ether()/Raw("Hello World, I don't think this is working, but just in case, I'll give it a try")

# p.dst = '00:1E:C0:90:A0:37'


# length = random.randint(500, 1000)
# random_string = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(length))



# # p = Ether()/b'\xde\xad\xbe\xef'
# p = Ether()/Raw(random_string)
# p.dst = 'aa:aa:aa:aa:aa:aa'
# p.src = '55:55:55:55:55:55'
# p.type = 0x88b5

for _ in range(1000):
    length = random.randint(100, 400)
    random_string = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(length))



    # p = Ether()/b'\xde\xad\xbe\xef'
    p = Ether()/Raw(random_string)
    p.dst = 'aa:aa:aa:aa:aa:aa'
    p.src = '55:55:55:55:55:55'
    p.type = 0x88b5
    # Ethernet from hub
    # sendp(p, iface="enp82s0u2u1u2")

    # Ethernet from dongle
    sendp(p, iface="enp0s20f0u1")
# p.show()
