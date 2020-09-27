SetupSettings = {}                      #SetupSettings is the dictionary that will hold all the settings for the requested Group within the Setup.ini file
Setting = ()

def GetSettings(Group):  #Locate the required Group of settings and load them into the SetupSettings dictionary

    SetupFile = open('Setup.ini','r')       #Open the Setup.ini file in read mode

#    print('Looking for settings group: ',Group)
    SettingsLine = ()

    #Locate the group of settings that interest the caller
    while SettingsLine := SetupFile.readline(): #Keep reading lines until the end of file is reached (assignment possible from Py3.8 on)
        if (Group in SettingsLine):             #String comparison:check whether Groups is found within the line read
            break

    #Let the user know of the news 
    if (SettingsLine != ''):                    #Test the result for an empty string
        print('Found settings group')           #Not empty string, the required settings Group was found
        while True:                             #Keep reading lines from the Setup.ini file until an empty line is reached
            SettingsLine = SetupFile.readline().rstrip("\n\t\r") #Remove end of line characters from the input line
            if (SettingsLine == ''):            #The fetched settings line is empty: this is the end of the required settings group
                break

            if (SettingsLine[0] != ';'):
                Setting = SettingsLine.split('=') #Split the setting identifier from the setting value

                SetupSettings[Setting[0]] = Setting[1] #Add the setting to the dictionary
            
    else:
        print('Settings group not found')       #Empty string, the required settings group was not found

    return SetupSettings                        #Return the dictionary containing the settings of the required settings group
        
        
    



#print(GetSettings('[Terminal_Comms]'))




