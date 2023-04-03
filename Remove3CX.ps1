#
# Removes 3CX and writes to event log
#

#Set execution policy
Set-ExecutionPolicy Unrestricted

#Create new event log source for 3CX
$checklogfile = Get-EventLog -Source "3CX Removal" -LogName Application
if (! $checklogfile){
New-EventLog -LogName Application -Source "3CX Removal"
}

# Kill 3CX processes first
Get-process | Where-Object {$_.name -Like "*3CX*"} | stop-process

# Attempt #1 - via EXE uninstall method
$3cxapps = Get-WMIObject -Class Win32_product | where {$_.name -like "3CX Desktop APP"}
foreach ($app in $3cxapps) {
try {
$app.Uninstall()
Remove-Item C:\Users\$env:UserName\AppData\Roaming\3CXDesktopApp -Recurse
Remove-Item C:\Users\$env:UserName\AppData\Local\Programs\3CXDesktopApp -Recurse
Remove-Item C:\Users\$env:UserName\Desktop\3CX Desktop App.lnk -Recurse
Write-Host "Uninstalled $($app.Name)"
}
catch {
Write-Host "Error uninstalling $($app.Name): $($_.Exception.Message)"
}
}

# Attempt #2 - via MSIEXEC ~ Requires Set-ExecutionPolicy to be changed
$appInstalled = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -eq "3CX Desktop App" }
if ($appInstalled) {
try {
$uninstallString = $appInstalled.UninstallString
Start-Process msiexec.exe -ArgumentList "/x `"$uninstallString`" /qn" -Wait -NoNewWindow
Remove-Item C:\Users\$env:UserName\AppData\Roaming\3CXDesktopApp -Recurse
Remove-Item C:\Users\$env:UserName\AppData\Local\Programs\3CXDesktopApp -Recurse
Remove-Item C:\Users\$env:UserName\Desktop\3CX Desktop App.lnk -Recurse
Write-Host "Uninstalled $($appName)"
}
catch {
Write-Host "Error uninstalling $($appName): $($_.Exception.Message)"
}
}
else {
Write-Host "3CX is not installed"
}


# Checks whether the uninstall was successful and writes to the event log
#Set paths to check
$3cxpaths = @(
"C:\Users\$env:UserName\AppData\Roaming\3CXDesktopApp"
"C:\Users\$env:UserName\AppData\Local\Programs\3CXDesktopApp"
"C:\Users\$env:UserName\Desktop\3CX Desktop App.lnk"
)

#Check if file paths present and W32 app present and write to event log
$3cxfilepaths = test-path $3cxpaths
if ($3cxfilepaths -contains $false -and $3cxapps -eq $null){
    Write-Host "3CX Desktop App was removed or is not present"
    Write-EventLog -LogName Application -Source "3CX Removal" -EntryType Warning -EventId 1 "3CX Desktop App was removed or is not present"
} else {
    Write-Host "3CX Desktop App failed to remove"
    Write-EventLog -LogName Application -Source "3CX Removal" -EntryType Warning -EventId 1 "3CX Desktop App failed to remove"
}
