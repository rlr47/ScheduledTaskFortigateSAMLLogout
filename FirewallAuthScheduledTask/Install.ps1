$Scriptname = "ScripttoRun.ps1" #name of the script to run in the scheduled task. Put in to root folder of this package.
$Foldername = "ScheduledTasks" #Foldername in C:\Program Files\
$ScheduledTaskUser = "USERS" #This is the user that is used to run the scheduled task, default set as system
$ScheduledTaskName = "Firewall User Auth Logout" #name of the scheduled task
#$ScheduledTime = "AtLogOn" #use "AtLogOn" or a time in format (example): 15:00 to run it at 3 pm

#Start Logging
Start-Transcript -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$($ScheduledTaskName)_Install.log" -Append

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

$Time = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries

#Creates trigger for any user device unlock
$stateChangeTrigger = Get-CimClass -Namespace root\Microsoft\Windows\TaskScheduler -ClassName MSFT_TaskSessionStateChangeTrigger
$onUnlockTrigger = New-CimInstance -CimClass $stateChangeTrigger -Property @{ StateChange = 8 } -ClientOnly

$ApplicationFolder = "C:\Program Files\$($Foldername)"

If (!(Test-Path $ApplicationFolder)) {
    New-Item -Path $ApplicationFolder -ItemType Directory
}
else {
    Write-host "Folder $($ApplicationFolder) already exists"

}
#Copying Items to ProgramData
Copy-Item -Path * -Destination $ApplicationFolder -Recurse -Force

$ScriptLocation = "$ApplicationFolder\$Scriptname"


try {

    Get-ScheduledTask -TaskName $ScheduledTaskName -ErrorAction SilentlyContinue -OutVariable task

    if (!$task) {

        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ex bypass -file `"$ScriptLocation`""
        $STPrin = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Users" -RunLevel Highest
        Register-ScheduledTask -TaskName $ScheduledTaskName -Trigger $Time,$onUnlockTrigger -Action $Action -Force -Principal $STPrin -Settings $settings
        #Register-ScheduledTask -TaskName $ScheduledTaskName -Trigger $Time,$onUnlockTrigger -User $ScheduledTaskUser -Action $Action -Force -Principal $STPrin

    }
    else {
        Write-Output "Scheduled Task already exists."
    }

}
catch {

    Throw "Failed to install package $($Foldername)"
}

Stop-Transcript