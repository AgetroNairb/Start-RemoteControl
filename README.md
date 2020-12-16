# Start-RemoteControl

Provides a GUI with a list of applications that can be started and run against a remote computer chosen from a list of computer names.

## Description

This script displays a GUI to choose from a list of computers and runs a command against that remote computer.

The list of computers and commands to be run are found in the Start-RemoteControl.xml file located at the script path. Only the applications found on the local computer will be shown in the GUI.

## History

I had a long list of computers to remote control in my DameWare Mini Remote Control client and we were looking at using the remote control client that comes with the SCCM client. So the list of computers could be shared, I wrote this PowerShell script to read the list from an XML file and display them in a GUI.

This XML file also includes a list of commands that will be run with the computer name replacing DUMMYCOMPUTERNAME in the parameter. The list of available commands expanded from there once I shared it with my group and received feedback.

Multiple commands can be provided for each application to allow the PowerShell script to look in more than one location for the executable.

A generic image is be displayed in the GUI if a PNG in the images folder isn't found with the same name as the executable.

I've changed a few lines in files to make them somewhat generic and they will need to be reviewed and changed before they're used.
