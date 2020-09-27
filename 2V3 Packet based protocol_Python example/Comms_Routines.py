import serial

#global Prot2V3_PacketAvailable                  #Flags that a packet is available for use
#global Prot2V3_RemainingPacketBytesToRx         # Counter of how many bytes are expected within the payload section
#global Prot2V3_SumOfPacketBytesRxd_Actual       # Accumulated sum of the bytes Rx'd as part of the payload
#global Prot2V3_SumOfPacketBytesRxd_Expected     # Specified sum of the bytes to be Rx'd as part of the payload
#global Prot2V3_Packet                           # List of bytes that will contain the content of the payload
#global Prot2V3_RxEngineState                    # Decode engine states, reset to idle (0)
#Prot2V3_PacketAvailable = False             # Flags that a packet is available for use
#Prot2V3_RemainingPacketBytesToRx = 0        # Counter of how many bytes are expected within the payload section
#Prot2V3_SumOfPacketBytesRxd_Actual = 0      # Accumulated sum of the bytes Rx'd as part of the payload
#Prot2V3_SumOfPacketBytesRxd_Expected = 0    # Specified sum of the bytes to be Rx'd as part of the payload
#Prot2V3_Packet = bytes([])                  # List of bytes that will contain the content of the payload
#Prot2V3_RxEngineState = 0                   # Decode engine states are: 0:idle,


def OpenCommsPort(ComSettings):                 # Assign the port parameters and attempt to open it
    try:
        
        global CommsPort
        
        CommsPort = serial.Serial(port=ComSettings['Comport'],
                                  baudrate=ComSettings['ComSpeed'],
                                  timeout=1,    # do not block execution for more than 1 second
                                  # The following parameters are not alterable by the
                                  #   setup.ini file, by definition, the MCU is set to 8N1.
                                  bytesize=serial.EIGHTBITS,
                                  parity=serial.PARITY_NONE,
                                  stopbits=serial.STOPBITS_ONE,
                                  xonxoff=False)
#        CommsPort.open()                       # not needed in 3.8, port is opened by default above
 
        return True                             # Return true is all went well
    except:
        return False                            # Return false otherwise

def TestMessage(MessageToPrint):
    print(MessageToPrint)
    print('Bytes in serial buffer: '+str(CommsPort.inWaiting()))

def Encode2V3(PacketPayload):                   #Encode the PacketPaylod into Packet_EncodedAs2V3, based on the 2V3 packet structure

    try: 
        Sum = 0                                 # Initialise the packet sum variable
        Length = len(PacketPayload)             # Set the packet length variable
        Position = 0                            # Zero based incoming string for Payload
        while Position < len(PacketPayload):    # Sum the ord value of all chars contained in the Payload
            Sum = Sum + ord(PacketPayload[Position])
            if (Sum>255):Sum = Sum - 256;       # Adjust the value of the variable as if it were a byte variable
            Position = Position + 1

        # Form the encoded packet by adding the head, length, sum and tail bytes    
        Packet_EncodedAs2V3 = chr(2) + chr(Length) + chr(Sum) + PacketPayload + chr(3)

        # The encoded packet is now ready, send it through the serial port, one byte at a time
        for i in range(len(Packet_EncodedAs2V3)):
            CommsPort.write((ord(Packet_EncodedAs2V3[i])).to_bytes(1, byteorder='big'))

        return True
    except:
        return False
          
def Decode2V3_InitialiseRxEngine():             # Initialise the 2V3 protocol decoding engine

    global Prot2V3_PacketAvailable
    global Prot2V3_RemainingPacketBytesToRx
    global Prot2V3_SumOfPacketBytesRxd_Actual
    global Prot2V3_SumOfPacketBytesRxd_Expected
    global Prot2V3_Packet
    global Prot2V3_RxEngineState
    
    Prot2V3_PacketAvailable = False             # Flags that a packet is available for use
    Prot2V3_Packet = bytes([])                  # List of bytes that will contain the content of the payload
    Prot2V3_RxEngineState = 0                   # Decode engine states are: 0:idle,
                                                #   1:Rx'd header (0x02),
                                                #   2:Rx'd length,
                                                #   3:Rxing payload,
                                                #   4: Expecting tail (0x03),
                                                
def Decode2V3():                                # Process the incoming byte stream in order decode a 2V3 packet that might be sent by the MCU

    global Prot2V3_PacketAvailable
    global Prot2V3_RemainingPacketBytesToRx
    global Prot2V3_SumOfPacketBytesRxd_Actual
    global Prot2V3_SumOfPacketBytesRxd_Expected
    global Prot2V3_Packet
    global Prot2V3_RxEngineState

    while ((CommsPort.inWaiting() > 0) and not(Prot2V3_PacketAvailable)): # Only proceed if at least a byte is available in the comms buffer and a packet is not available from a previous case
        IncomingChar = CommsPort.read()         # Read one char off the serial buffer                               
#        print("Rx'd char: "+str(IncomingChar))
#        print("State: "+str(Prot2V3_RxEngineState))
        
        if ((Prot2V3_RxEngineState == 0) and (ord(IncomingChar) == 2)): # Idle state: exit to state 1 if an 0x02 byte (header) was Rx'd
            Prot2V3_RxEngineState = 1
#            print("Rx'd header")
            
        elif (Prot2V3_RxEngineState == 1): # State 1: Rx'd header, now waiting to Rx the length of the payload
            Prot2V3_RemainingPacketBytesToRx = ord(IncomingChar) # Rx'd the length of the expected payload
            Prot2V3_RxEngineState = 2
#            print("Rx'd length: "+str(Prot2V3_RemainingPacketBytesToRx))
            
        elif (Prot2V3_RxEngineState == 2): # State 2: Rx'd length, now waiting to Rx the sum of the payload
            Prot2V3_SumOfPacketBytesRxd_Expected = ord(IncomingChar) # Rx'd the sum that the payload bytes are expected to have
            Prot2V3_SumOfPacketBytesRxd_Actual = 0 # Zero the accumulated sum of the bytes Rx'd as part of the payload
            Prot2V3_RxEngineState = 3
#            print("Rx'd expected sum: "+str(Prot2V3_SumOfPacketBytesRxd_Expected))
            
        elif (Prot2V3_RxEngineState == 3): # State 3: accumulating the payload, remain within this state until all payload chars have been rx'd
            Prot2V3_SumOfPacketBytesRxd_Actual += ord(IncomingChar) # add the rx'd byte to the actual sum
            if (Prot2V3_SumOfPacketBytesRxd_Actual>255):
                Prot2V3_SumOfPacketBytesRxd_Actual = Prot2V3_SumOfPacketBytesRxd_Actual - 256; # Adjust the value of the variable as if it were a byte variable
            Prot2V3_Packet += bytearray(IncomingChar) # add the rx'd byte to the packet bytearray
            Prot2V3_RemainingPacketBytesToRx -= 1 # one less payload byte to expect
#            print("Rx'd payload: "+str(Prot2V3_Packet, 'utf-8'))
#            print("RemainingPacketBytesToRx: "+str(Prot2V3_RemainingPacketBytesToRx))
            if (Prot2V3_RemainingPacketBytesToRx == 0): # if all payload bytes have been rx'd...
                if (Prot2V3_SumOfPacketBytesRxd_Actual == Prot2V3_SumOfPacketBytesRxd_Expected): # then compare the calculated to the expected payload sum
#                    print("Sums match success")
                    Prot2V3_RxEngineState = 4 # they are equal, success, go to wait for the tail
                else:
#                    print("Sums match failure")
                    Decode2V3_InitialiseRxEngine() # they are not equal, failure, do not bother to wait for the tail byte
                                    
        elif (Prot2V3_RxEngineState == 4): # State 4: a valid payload has been rx'd.  Waiting for the tail byte to be rx'd, confirming proper packet rx
            if (ord(IncomingChar) == 3): # check whether the tail byte 0x03 has indeed been rx'd
#                print("Succeeded to rx the tail character")
#                print("A packet is available for use")
                Prot2V3_PacketAvailable = True # it has, success, a packet is available for processing
            else:
#                print("Failed to rx the tail character")
                Decode2V3_InitialiseRxEngine() # it has not, failure, reset the state machine, ready to rx another packet

        else:
            Decode2V3_InitialiseRxEngine() # no state was matched.  This is an abnormal behaviour, please reset the state machine, ready to rx another packet
                
            
            
    
