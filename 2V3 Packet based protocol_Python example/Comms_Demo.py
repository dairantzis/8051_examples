import os
import serial
import datetime
import time
import binascii
from time import sleep
import Comms_Routines   # Routines to access the serial port and Encode/Decode 2V3 packages
import Timer_Routines   # Routines handling the repetitive tasks of the programme
from Utilities import Hex2Temperature
from  SetupFile_Routines import GetSettings

# Example programme of how to decode the 2V3 packet protocol.
# Requires Python version 3.8.
# The programme changes the active directory to the one where the script is currently stored
# Then formulates the name of the log file
# Then reads the current system time, forms a timestamp and makes a log of when it started
# Then it sends the command to read the MCU s/w version and waits until it is rx'd.  Makes a note of the version.
# Then it sends the command to read the serial numbers of the four temperature sensors.  Makes a note of the numbers.
# Then makes writes the version and serial number information in the log file
# Then sends the command to measure the temperature & send the result in HEX 2's complement form.
# Once received, the measurements are translated to signed decimal and a log is stored
#
# Known issues:
#   there is no error checking on whether the logfile was opened.
#   there is no corrective action should the serial port fail to open.
#   there is no corrective action should the MCU fail to respond.
# Planned future additions:
#   Plot the incoming data.
#   Use the module wxPython to provide a GUI
#

os.chdir(os.path.dirname(__file__))         # change the current directory to the one where this script is contained
#print(os.getcwd())

CurrentDateTime = datetime.datetime.now()   # Read the current date and time information

# Form the log filename based on the date time informatioin obtained
LogFileName = CurrentDateTime.strftime("%y") + CurrentDateTime.strftime("%m") + CurrentDateTime.strftime("%d") + '.dta'
# Form the time stamp based on the date time informatioin obtained
TimeStamp = CurrentDateTime.strftime("%y") + CurrentDateTime.strftime("%m") + CurrentDateTime.strftime("%d") + '_' + CurrentDateTime.strftime("%H") + CurrentDateTime.strftime("%M") + CurrentDateTime.strftime("%S")

# Make a log of the date/time that the programme started
LogFile = open(LogFileName,'a')       #Open the log file in write mode, append the new information if the file already exists
LogFile.write('Program start at: '+TimeStamp+'\n')
LogFile.close()

print('Programme demonstrating serial comms to an MCU measuring temperature via structured packets')
print('')
print('Temperature readings will be stored at file: ',LogFileName)
print('')
print('Reading the communications parameters and loading them onto a dictionary')
ComSettings = GetSettings('[Terminal_Comms]')      # Read the settings related to communications with the MCU

print('Attempting to open comms port '+ComSettings['Comport'])

if not(Comms_Routines.OpenCommsPort(ComSettings)):  # Attempt to open the comms port to the MCU
    print('Failed to open ' + ComSettings['Comport']) # Let the user know that it failed
    print('Exiting the programme')
else:
    print('Opened comms port ' + ComSettings['Comport']) # Let the user know that it succeeded

    Comms_Routines.Decode2V3_InitialiseRxEngine()  #Initialise the packet decode engine

    Comms_Timer = Timer_Routines.RepeatedTimer(0.5, Comms_Routines.Decode2V3)  # Setup the comms timer, attempting to decode any incoming 2V3 packet

    Comms_Routines.Encode2V3('FF0') # Ask the MCU to provide the version of the software it is running
                                    # Command '0' requests the software version running on the MCU

    # Let up to 500 msec pass by, or until the MCU response is received
    CurrentTime = time.time() # Read what the current epoch time is (msec)
    ExpiryTime = CurrentTime + 500 # Get ready to wait 500 msec for a response from the MCU
    while (ExpiryTime > time.time()) and not(Comms_Routines.Prot2V3_PacketAvailable):
        sleep(0.1)
    if not(Comms_Routines.Prot2V3_PacketAvailable):
        print('No response from the MCU')
    else:
        MCU_SW_Version = str(Comms_Routines.Prot2V3_Packet[4:20],'utf-8') # Isolate the part of the string containing the MCU sw version
        print('MCU software version: ',MCU_SW_Version)
        Comms_Routines.Decode2V3_InitialiseRxEngine()  #Initialise the packet decode engine, getting it ready for the next command response
        
        Comms_Routines.Encode2V3('FF1N') # Ask the MCU to provide the serial numbers of the temperature sensors
                                         
        # Let up to 500 msec pass by, or until the MCU response is received
        CurrentTime = time.time() # Read what the current epoch time is (msec)
        ExpiryTime = CurrentTime + 500 # Get ready to wait 500 msec for a response from the MCU
        while (ExpiryTime > time.time()) and not(Comms_Routines.Prot2V3_PacketAvailable):
            sleep(0.1)
        if not(Comms_Routines.Prot2V3_PacketAvailable):
            print('No response from the MCU')
        else:
            # Isolate the part of the string containing the serial numbers of the sensors
            #   as the information is delivered in an arraybyte, it must be decoded to ascii
            Sensor_Serial_Numbers = str(Comms_Routines.Prot2V3_Packet[4:],'utf-8')
            # Isolate the part of the string containing the serial numbers of the sensors
            print('Sensor Serial Numbers: ',Sensor_Serial_Numbers)
            Comms_Routines.Decode2V3_InitialiseRxEngine()  #Initialise the packet decode engine, getting it ready for the next command response
        
            # All system information is now available, save it in the log file
            LogFile = open(LogFileName,'a')       #Open the log file in write mode, append the new information if the file already exists
            LogFile.write('MCU s/w version: '+MCU_SW_Version+'\n')
            LogFile.write('Sensor s/n: '+Sensor_Serial_Numbers+'\n')
            LogFile.close()
            

            # Keep on asking the MCU to measure the temperature from each one of the four sensors
            #   and report the results to the PC
            while True:
                Comms_Routines.Encode2V3('FF1T') # Ask the MCU to measure the temperature reported by each sensor
                CurrentTime = time.time() # Read what the current epoch time is (msec)
                ExpiryTime = CurrentTime + 1500 # Get ready to wait 1500 msec for a response from the MCU
                while (ExpiryTime > time.time()) and not(Comms_Routines.Prot2V3_PacketAvailable):
                    sleep(0.1)
                if not(Comms_Routines.Prot2V3_PacketAvailable):
                    print('No response from the MCU')
                else:
                    Reported_Temperatures = str(Comms_Routines.Prot2V3_Packet[4:],'utf-8') # Isolate the part of the string containing the temperature readings
                    TString = str(Hex2Temperature(Reported_Temperatures[0] + Reported_Temperatures[1]))+','
                    TString = TString + str(Hex2Temperature(Reported_Temperatures[2] + Reported_Temperatures[3]))+','
                    TString = TString + str(Hex2Temperature(Reported_Temperatures[4] + Reported_Temperatures[5]))+','
                    TString = TString + str(Hex2Temperature(Reported_Temperatures[6] + Reported_Temperatures[7]))

                    print('Reported temperatures:: ',TString,'\n')  # Tell the user what the temperature measurements are

                    # The measurements are now known, store them in the logfile
                    CurrentDateTime = datetime.datetime.now()   # Read the current date and time information
                    # Form the time stamp based on the date time informatioin obtained
                    TimeStamp = CurrentDateTime.strftime("%y") + CurrentDateTime.strftime("%m") + CurrentDateTime.strftime("%d") + '_' + CurrentDateTime.strftime("%H") + CurrentDateTime.strftime("%M") + CurrentDateTime.strftime("%S")

                    # Make a log of the measurements
                    LogFile = open(LogFileName,'a')       #Open the log file in write mode, append the new information if the file already exists
                    LogFile.write(TString+' '+TimeStamp+'\n')
                    LogFile.close()

                    Comms_Routines.Decode2V3_InitialiseRxEngine()  #Initialise the packet decode engine, getting it ready for the next command response


            
    Comms_Timer.stop()
    print('Exiting the programme')


    
    
