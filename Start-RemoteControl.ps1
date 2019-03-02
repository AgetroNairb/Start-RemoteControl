#Requires -Version 3.0
<#
    .Synopsis
        Provides a GUI with a list of applications that can be started and run against a remote computer chosen from a list of computer names.

    .Description
        This script displays a GUI to choose from a list of computers and runs a command against that remote computer.

        The list of computers and commands to be run are found in the Start-RemoteControl.xml file located at the script path. Only the applications
        found on the local computer will be shown in the GUI.
#>



Add-Type -AssemblyName "PresentationFramework", "System.Windows.Forms", "WindowsFormsIntegration"



$PSHostName = $host.Name # to control whether or not to exit PowerShell host when closing window
$GetScript = Get-Item -Path $PSCommandPath
$ScriptPath = $GetScript.DirectoryName
$ScriptName = $GetScript.BaseName
$XmlFile = "$ScriptPath\$ScriptName.xml"

[xml]$WindowXml = @"
    <Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$ScriptName"
        WindowStartupLocation="CenterScreen"
        Width="1024"
        Height="768"
        Icon="$ScriptPath\images\Black_Wizard.ico"
    >
        <WebBrowser Name="WebBrowser"></WebBrowser>
    </Window>
"@



# Get XML content
[xml]$XmlContent = Get-Content -Path $XmlFile
$HostList = $XmlContent.StartRemoteControl.HostList.Group
$ApplicationList = $XmlContent.StartRemoteControl.ApplicationList.Application



# Build HTML for menu from XML
$HtmlMenu = "<ul id=`"Menu`" style=`"display: none;`">`n<li><div tag=`"`">&nbsp;</div><ul>"
$HostList | 
    Sort-Object { $_.DisplayName } | 
    foreach { 
        $HtmlMenu += "`t<li>`n`t`t<div>$($_.DisplayName)</div>`n`t`t<ul>`n"
        $Hosts = @()
        $_.Host | 
            foreach {
                if ($_.DisplayName) {
                    $Hosts += "$($_.DisplayName.Trim()) { $($_.HostName.Trim()) }"
                }
                else {
                    $Hosts += "$($_.HostName.Trim())"
                }
            }
        $Hosts | 
            Sort-Object | 
            foreach {
                if ($_ -like "*{*") {
                    $x = ($_ -split "{" -replace "}").Trim()[1]
                }
                else {
                    $x = $_
                }
                $HtmlMenu += "`t`t`t<li>`n`t`t`t`t<div tag=`"$x`">$_</div>`n`t`t`t</li>`n"
            }
        $HtmlMenu += "`t`t</ul>`n`t</li>`n"
    }
$HtmlMenu += "</ul></li></ul>"



# Build HTML for apps
$HtmlApps = ""
$ApplicationList | 
    foreach { 
        $Command = ""
        if ($_.Command -is [array]) {
            foreach ($y in $_.Command) {
                if (Test-Path -Path $y -ErrorAction "SilentlyContinue") {
                    $Command = $y
                    break
                }
            }
        }
        else {
            $Command = $_.Command
        }
        if (-not ([string]::IsNullOrWhiteSpace($Command))) {
            if (Test-Path -Path $Command -ErrorAction "SilentlyContinue") {
                $DisplayName = $_.DisplayName
                $ToolTip = $_.ToolTip
                if ($ToolTip) { $Title = "title=`"$ToolTip`"" } else { $Title = "" }
                $GetCommand = Get-Item -Path $Command
                $CommandBaseName = $GetCommand.BaseName
                $Parameters = $_.Parameters -replace "`"", "&quot;" # get the quotes right for HTML
                $Parameters = $Parameters -replace "\.\\", "$ScriptPath\" # get the path right for calling PowerShell from JavaScript

                $ImgSrc = "$ScriptPath/images/$CommandBaseName.png"
                if (-not (Test-Path -Path $ImgSrc -ErrorAction "SilentlyContinue")) {
                    $ImgSrc = "data:image/png;base64,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"
                }

                $HtmlApps += "
                    `t`t<div class=`"AppTile`" $Title Command=`"$Command`" Parameters=`"$Parameters`">
                        `t`t<div class=`"Centered`">
                            `t`t<div><img src=`"$ImgSrc`" /></div>
                            `t`t<div>$DisplayName</div>
                        `t`t</div>
                    `t`t</div>"
            }
        }
    }



# Build HTML
$HTML = @"
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <meta charset="utf-8">
        
        <link rel="stylesheet" href="$ScriptPath/styles/jquery-ui.css">
        <link rel="stylesheet" href="$ScriptPath/styles/Start-RemoteControl.css">
    
        <script src="$ScriptPath/scripts/jquery-3.3.1.js"></script>
        <script src="$ScriptPath/scripts/jquery-ui.js"></script>
        <script src="$ScriptPath/scripts/Start-RemoteControl.js"></script>
    </head>
    <body>
        <div id="MenuDiv">
            Enter a ComputerName in the field or hover over the menu button to choose...<br /><br />
            <input id="Host" type="text" class="ui-widget-content" />
            $HtmlMenu
        </div>
        <div id="AppsDiv">
            $HtmlApps
        </div>
    </body>
    </html>
"@



# C# class that is COMVisible for executing PowerShell in Javascript - http://tiberriver256.github.io/powershell/gui/html/PowerShell-HTML-GUI-Pt4/
if (-not ("PowerShellHelper" -as [type])) {
    Add-Type -TypeDefinition @"
        using System.Text;
        using System.Runtime.InteropServices;

        //Add For PowerShell Invocation
        using System.Collections.ObjectModel;
        using System.Management.Automation;
        using System.Management.Automation.Runspaces;

        [ComVisible(true)]
        public class PowerShellHelper
        {
            Runspace runspace;

            public PowerShellHelper()
            {
                runspace = RunspaceFactory.CreateRunspace();
                runspace.Open();
            }

            public string InvokePowerShell(string Command)
            {
                //Init stuff
                RunspaceInvoke scriptInvoker = new RunspaceInvoke(runspace);
                Pipeline pipeline;

                pipeline = runspace.CreatePipeline();

                //Add commands
                pipeline.Commands.AddScript(Command);

                Collection<PSObject> results = pipeline.Invoke();

                //Convert records to strings
                StringBuilder stringBuilder = new StringBuilder();
                foreach (PSObject obj in results)
                {
                    stringBuilder.Append(obj);
                }

                return stringBuilder.ToString();
            }
        }
"@ -ReferencedAssemblies @("System.Management.Automation","Microsoft.CSharp")
}



#Read XAML
$XmlNodeReader = New-Object System.Xml.XmlNodeReader $WindowXml
$script:XamlReader = [Windows.Markup.XamlReader]::Load($XmlNodeReader)
$WebBrowser = $XamlReader.FindName("WebBrowser")



# Add a new PowerShellHelper Object as the ObjectForScripting on the WPF browser - http://tiberriver256.github.io/powershell/gui/html/PowerShell-HTML-GUI-Pt4/
$WebBrowser.ObjectForScripting = [PowerShellHelper]::new()


    
# Exit the application when the window closes
if ($PSHostName -and $PSHostName -eq 'ConsoleHost') { # so it doesn't break when running code in ISE or VSCode
    $XamlReader.Add_Closing({
        [System.Windows.Forms.Application]::Exit()
        Stop-Process $PID
    })
}


# Navigate to HTML and show window
$WebBrowser.NavigateToString($HTML)
[void]$XamlReader.ShowDialog()