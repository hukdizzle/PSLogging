﻿function Add-Log
{
    <#
    .NOTES
	    Title:			Add-Log.ps1
	    Author:			Curtis Jones
	    Date:			March 10th, 2017
	    Version:		1.0.0
	    Requirements:		Powershell 3.0
	
    .SYNOPSIS
        Provides code execution string logging into $env:LOCALAPPDATA\PowerShellLogging along with the ability to output to all valid PowerShell streams simultaneously.
    .DESCRIPTION
        Add-Log provides a simple but effective way to simultaneously log all desired information to a standardized logging location within $env:LOCALAPPDATA\PowerShellLogging while also allowing simultaneous output to all valid PowerShell streams. This function works in conjunction with the Set-LogFile function to generate and maintain a healthy log file structure. This function is all that needs to be called to automatically generate a valid logging file and start using it.
    .PARAMETER Message

        The message that will be logged to the local log file and also output to PowerShell stream if the Out switch is used.
    .PARAMETER Type

        Used to indicate the type of log message and also used to correlate the type of stream to be utilized if the Out switch is used.
    .PARAMETER Out

        Used to output the log message to the corresponding message stream and also output to console.
    .PARAMETER LogFileSizeThreshold

        Provide a valid size for a log file threshold such as 1GB, 500MB, 1024KB, etc.
    .EXAMPLE
        Add-Log -Message "The reactor core has reached critical mass" -Type Warning -Out

        The above example would write the message string to the log file indicated by the path within the global $logFile variable generated by Set-LogFile and will also pass the message into the warning stream and output to the console.
    #>
    [CmdletBinding()]
    [Alias("Log")]
    param
    (
        [parameter(Mandatory=$true,Position=0,HelpMessage="The message that will be logged and also output to PowerShell stream if the Out switch is used.")]
        [string]$Message,
        [parameter(Mandatory=$true,Position=1,HelpMessage="Used to indicate the type of log message and also used to correlate the type of stream to be utilized if the Out switch is used.")]
        [ValidateSet("Normal","Error","Warning","Debug","Verbose")]
        [string]$Type,
        [parameter(Mandatory=$false,Position=2,HelpMessage="Use switch to output the log message to the corresponding stream and also output it to the console.")]
        [switch]$Out,
        [parameter(Mandatory=$false,Position=3,HelpMessage="Provide a valid size for a log file threshold such as 1GB, 500MB, 1024KB, etc. The default parameter value is 100MB.")]
        [int]$LogFileSizeThreshold=3KB
    )
    process
    {
        
        #If no logFile variable is present in the current PSSession the Set-LogFile function will be called to generate a logFile variable pointing to a new or existing log file based on the name of the invocation script.

        if((-not $logFile) -or ([IO.Path]::GetFileNameWithoutExtension($logFile) -ne [IO.Path]::GetFileNameWithoutExtension($MyInvocation.PSCommandPath)))
        {
            try
            {
                $script:logFile = Set-LogFile -LogFileName $MyInvocation.PSCommandPath -ShowLocation -ErrorAction Stop
            }
            catch
            {
                throw
            }
        }
        
        #A string is constructed including the datetime, current PowerShell process ID, executing windows username, log type param, and message string param. The full string is output to the logFile variable with the append switch utilized as to not overwrite any existing entries.

        "[$(Get-Date -format 'G') | $($pid) | $($env:username) | $($Type.ToUpper())] $message" | Out-File -FilePath $logFile -Append

        #If the out switch is called the following block will be entered. The type param input will determine the switch block to enter which will call the correlating stream cmdlet to add the message string to the corresponding stream but also output it to the console.

        if($out)
        {
            switch ($type)
            {
                Normal { Write-Output $message }
                Error { Write-Error -Message $message }
                Warning { Write-Warning -Message $message }
                Debug { Write-Debug -Message $message -Debug }
                Verbose { Write-Verbose -Message $message -Verbose }
            }
        }

        $log = Get-Item $logFile

        if(($log.Length / $logFileSizeThreshold) -ge '1')
        {
            try
            {
                Rename-Item -Path $log.FullName -NewName "$($log.BaseName)_$(Get-Date -Format ddMMyyThhmmss).old" -ErrorAction Stop
                $script:logFile = Set-LogFile -LogFileName $MyInvocation.PSCommandPath -ErrorAction Stop
                "Log file $($log.Name) was found to be at $($log.length) Bytes size which is larger than the allowed size threshold of $($logFileSizeThreshold) Bytes, prior log file has been renamed to $($log.BaseName)_$(Get-Date -Format ddMMyyThhmmss).old." | Out-File -FilePath $logFile -Append
            }
            catch
            {
                throw
            }
        }
    }
}