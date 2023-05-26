# 0 is empty
# 1 is player 1 (X)
# 2 is player 2 (O), the raspberry pi




import re

from scapy.all import *

class tictactoe(Packet):
	name = "tictactoe"
	fields_desc = [ StrFixedLenField("P", "P", length=1),
			StrFixedLenField("Four", "4", length=1),
			XByteField("version", 0x01),
			StrFixedLenField("s1","0",length=1),
			StrFixedLenField("s2","0",length=1),
			StrFixedLenField("s3","0",length=1),
			StrFixedLenField("s4","0",length=1),
			StrFixedLenField("s5","0",length=1),
			StrFixedLenField("s6","0",length=1),
			StrFixedLenField("s7","0",length=1),
			StrFixedLenField("s8","0",length=1),
			IntField("responselocation",0)]

bind_layers(Ether,tictactoe,type=0x1234)

			
			

def location_parser(location,state):
    match = True
# Checking if input is between 1 to 9.in a valid square
    if (location < 1 or location > 9):
    	match = False
    
    print(match)
    if match:
    	index = location - 1
    	if state[index] == '0':
    		state[index] = '1' 
    		return state
    	
    	else:
    		print('This is not an empty square')
    
    else:
    	print('Location needs to be a number from 1 to 9.')
    	
    	

 

    
def main():
	state=[0, 0, 0, 0, 0, 0, 0, 0, 0]
	iface = "enx0c37965f8a24"
	
	while True:
		location = int(input('enter your location >'))
		if location == "quit":
			break
		print(location)
		state = location_parser(location, state)
		print(state)
		try:
# destination correct?
			pkt = Ether(dst='00:04:00:00:00:00', type=0x1234) / tictactoe(s1=state[0],
										s2=state[1],
										s3=state[2],
										s4=state[3],
										s5=state[4],
										s6=state[5],
										s7=state[6],
										s8=state[7],
										s9=state[8])
										
			
			pkt = pkt/' '
			resp = srp1(pkt, iface=iface,timeout=5, verbose=False)
			if resp:
                		tictactoe1=resp[tictactoe]
                		if tictactoe1:
# Update the state table and print the state table                		
                			index = responselocation -1
                			state[index] = '2'
                			
                		else:
                			print("cannot find tictactoe header in the packet")
			else:
                		print("Didn't receive response")
                	
                	
		except Exception as error:
			print(error)


if __name__ == '__main__':
    main()

							
			


