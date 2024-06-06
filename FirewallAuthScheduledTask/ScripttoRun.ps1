# The aim of this script is to de-auth the device against the firewall as shared devices might have multiple users.
# The script opens edge to the firewall logout page and then sends a ctrl+w keyboard input which should close the current edge tab.
# The page doesn't always close if the user clicks off the microsoft edge page before the sleep timer ends.
# I tried other possible methods such as the powerhell window hide/minimize options but they didn't seem to work with Edge.
# There is a possible alternative method in the if statement that might work better but needs testing.


# This will run at new login and device unlock triggers.

# ---------------------------------- Hide Powershell Console ---------------------------------- #

# .Net methods for hiding/showing the console in the background
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
function Hide-Console
{
    $consolePtr = [Console.Window]::GetConsoleWindow()
    #0 hide
    [Console.Window]::ShowWindow($consolePtr, 0)
}
Hide-Console

#Get current public IP address as we only want to run this if the device is on our network.

$ip = (Invoke-WebRequest ifconfig.me/ip).Content

if($ip -eq "Your Public IP Address")
    {
        Write-Host "Matches"
        #Opens edge to the SAML logout url.
        Start-Process -FilePath msedge -ArgumentList '--new-window https://firewall.IP.or.FQDN:1003/remote/saml/logout?'
        

        $wshell = New-Object -ComObject wscript.shell;
        Sleep 2 # sleep to give the page time to load
        $wshell.AppActivate('Firewall') #Attempts to make the task bar window named like firewall the main app
        $wshell.SendKeys("^(w)") # sends a ctrl+w to the device (this should be close tab/window)


        #Possible alternative method that I need to test more. This should log the user out without opening edge.
        #Invoke-WebRequest -uri "https://firewall.IP.or.FQDN:1003/remote/saml/logout?" -UseBasicParsing
    }
else
    {
        Write-Host "Doesn't Match"
    }

