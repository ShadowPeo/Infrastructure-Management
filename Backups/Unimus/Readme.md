# Overview

This script downloads files from either a SCP or SFTP source parses them based upon some rules and then uploads the files to Unimus
Currently there is only one processor, that for APC network cards which drops the 5th line to remove the date generated to stop the generation date showing up as a diff in Unimus

The script checks for communication to the Unimus server (currently this is only an ICMP check, I will convert this to a check on the status function in the API at some point)
Once this is done it will check for the temporary directory and create it if missing
It will then check for PSCP and if it does not have a copy it will download the latest from the official website, the script does not check for a newer version, it either eixsts or it does not

The script then;
    Imports the devices
    Sets the address to the same as the description if no address specified
    Checks for its abillity to connect on the name and address fields
    Checks for device in Unimus, pulls it if available, if not creates it then pulls the information
    Connects to the device over the selected protocol and pulls the configuration
    Runs the processor for the type of data
    Runs the processor for Text based files if applicable
    Uploads the file to Unimus
    Cleans up after itself


## Requirements

You will need an API key from Unimus itself, the Unimus Server URL and a config file in CSV format (sample included here)

Edit the first three lines as appropriate (if using the csv in the same file as the script the script will import it based upon line 3)

The CSV requires a number of paramters
| Column | Notes |
| ----------- | ----------- |
| Name | The Name of the device, this is used for description in Unimus if needed and also address if no address is specified |
| Address | The IP or DNS address that resolves to the device |
| Username |SCP/SFTP Username for the device |
| Password |SCP/SFTP Password for the device |
| Path |The Path to the config file, no leading / |
| Protocol | SCP or SFTP |
| Type | Text or Binary - this is how to handle the data for upload to Unimus |
| Processor | Run any specific processing in the script |

There is currently only an APC NMC processor which removes the 5th line in the code and this is hard coded into the file and not modular

## Notes

SFTP and Binary support are only experimental, I have no use case for them and have not tested them personally, they should however work if I need them at some point I will test and verify them but this is not now.
