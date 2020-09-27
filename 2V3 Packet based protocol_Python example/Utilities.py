

def Hex2Temperature(THexString):    #Temperature information is delivered in HEX, 2's complement

    # Ensure that we have a 2 digit HEX number
    if (len(THexString) > 2):
        THexString = THexString[0:2]
    elif (len(THexString) < 2):
        THexString = '0'+ THexString
        
    # Convert the number from hex to dec
    Temperature = int(THexString,16)

    # Adjust for negative result
    if (Temperature > 127):
        Temperature = Temperature - 256

    return Temperature
