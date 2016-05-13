#Requires -Version 2.0
<#
	.SYNOPSIS
	Updates the AssemblyVersion annotation from the assembly version (.cs) file
	
	.DESCRIPTION
	Updates the AssemblyVersion annotation from the assembly version (.cs) file
	Additional parameters may be provided to also specify which block of number
    need to be incremented.

    .PARAMETER AssemblyInfoFilePath
    Path to the assembly info file.

	.PARAMETER IncrementMajor
	Increment, by 1, the actual major version number

    .PARAMETER IncrementMinor
	Increment, by 1, the actual minor version number

    .PARAMETER IncrementRevision
	Increment, by 1, the actual revision version number

    .PARAMETER IncrementBuild
	Increment, by 1, the actual build version number

    .PARAMETER ForceFourDigitBlocks
	Forces use version number of four digit blocks
    (e.g.: [MAJOR].[MINOR].[REVISION].[BUILD])

	.EXAMPLE
	& .\IncrementAssemblyVersion.ps1

	Run the script without any parameters.
	This will update only the build block.

	.EXAMPLE
	& .\IncrementAssemblyVersion.ps1 -ForceFourDigitBlocks

	If the AssemblyVersionAttribute is setted to use the pattern
    [MAJOR].[MINOR].[*] or [MAJOR].[MINOR].[REVISION].[*], this call
    will force the pattern [MAJOR].[MINOR].[REVISION].[BUILD], increment
    only the build number. If the build number is "*", will increment to "1".
	
	.EXAMPLE
	& .\IncrementAssemblyVersion.ps1 -Major

	Will increment only the major digit block, by 1.
    Other switchs will do the same to the specific block.
	
	.LINK
	Project home: https://github.com/marcoaoteixeira/PowerShell-Scripts/tree/master/IncrementAssemblyVersion.ps1

	.NOTES
	Author: Marco Antonio Orestes Teixeira
	Version: 1.0
	
	This script is designed to be called from PowerShell.
#>
[CmdletBinding()]
Param (
    [Parameter(Position = 0, Mandatory = $true, HelpMessage = "Path to the assembly info file.")]
    [ValidateScript({ Test-Path $_ -PathType Leaf -Include "AssemblyInfo.cs" })]
    [Alias("AssemblyInfo")]
    [String] $AssemblyInfoFilePath,

    [Parameter(Position = 1, Mandatory = $false, HelpMessage = "Increment major version")]
    [Alias("Major")]
    [Switch]$IncrementMajor = $false,

    [Parameter(Position = 2, Mandatory = $false, HelpMessage = "Increment minor version")]
    [Alias("Minor")]
    [Switch]$IncrementMinor = $false,

    [Parameter(Position = 3, Mandatory = $false, HelpMessage = "Increment revision version")]
    [Alias("Revision")]
    [Switch]$IncrementRevision = $false,

    [Parameter(Position = 4, Mandatory = $false, HelpMessage = "Increment build version")]
    [Alias("Build")]
    [Switch]$IncrementBuild = $false,

    [Parameter(Position = 5, Mandatory = $false, HelpMessage = "Forces use of 4 digit blocks version.")]
    [Alias("F4")]
    [Switch]$Force4DigitBlocks = $false,

    [Parameter(Position = 6, Mandatory = $false, HelpMessage = "Whether should show prompt for errors")]
    [Switch]$PromptOnError = $false
)

# Turn on Strict Mode to help catch syntax-related errors.
#   This must come after a script's/function's param section.
#   Forces a Function to be the first non-comment code to appear in a PowerShell Module.
Set-StrictMode -Version Latest

#==========================================================
# Define any necessary global variables, such as file paths.
#==========================================================

# Gets the script file name, without extension.
$THIS_SCRIPT_NAME = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Definition)

# Get the directory that this script is in.
$CURRENT_SCRIPTS_DIRECTORY_PATH = Split-Path $script:MyInvocation.MyCommand.Path

# Regex to get the assembly version number.
$ASSEMBLY_VERSION_ATTRIBUTE_REGEX = [Regex]"^\[assembly: AssemblyVersion\(`"(.*)`"\)\]$"

# Regex to use when replacing the version number.
$ASSEMBLY_VERSION_ATTRIBUTE_REPLACE_REGEX = [Regex]"^\[assembly: AssemblyVersion\(`".*`"\)\]$"

# Major block index
$MAJOR = 0

# Minor block index
$MINOR = 1

# Revision block index
$REVISION = 2

# Build block index
$BUILD = 3

#==========================================================
# Define functions used by the script.
#==========================================================

# Catch any exceptions Thrown, display the error message, wait for input if appropriate, and then stop the script.
Trap [Exception] {
    $errorMessage = $_
    Write-Host "An error occurred while running $($THIS_SCRIPT_NAME) script:`n$errorMessage`n" -Foreground Red
    
    If ($PromptOnError) {
        Write-Host "Press any key to continue ..."
        $userInput = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp")
    }

    Break;
}

# PowerShell v2.0 compatible version of [String]::IsNullOrWhitespace.
Function Test-StringIsNullOrWhitespace([String]$string) {
    Return [String]::IsNullOrWhiteSpace($string)
}

#==========================================================
# Perform the script tasks.
#==========================================================

# Display the time that this script started running.
$scriptStartTime = Get-Date
Write-Verbose "$($THIS_SCRIPT_NAME) script started running at $($scriptStartTime.TimeOfDay.ToString())."

# Display the version of PowerShell being used to run the script, as this can help solve some problems that are hard to reproduce on other machines.
Write-Verbose "Using PowerShell Version: $($PSVersionTable.PSVersion.ToString())."

Try {
    If (!$IncrementMajor -and !$IncrementMinor -and !$IncrementRevision -and !$Force4DigitBlocks) {
        $Force4DigitBlocks = $true
        $IncrementBuild = $true
    }

    $content = Get-Content $AssemblyInfoFilePath
    $content | ForEach-Object {
        If (!($_ -match $ASSEMBLY_VERSION_ATTRIBUTE_REGEX)) {
            Return
        }

        $currentVersion = $matches[1]
        $rawVersion = New-Object System.Collections.Generic.List[String]
        $rawVersion.AddRange($currentVersion.Split(".")) | Out-Null
        # If force 4 digit blocks and version has only 3 digit blocks
        # Adds the last one
        If ($Force4DigitBlocks -and $rawVersion.Count -eq 3) {
            $rawVersion.Add("") | Out-Null
        }

        # MAJOR
        If ($IncrementMajor) {
            $rawVersion[$MAJOR] = (($rawVersion[$MAJOR] -as [int]) + 1).ToString()
        }

        # MINOR
        If ($IncrementMinor) {
            $rawVersion[$MINOR] = (($rawVersion[$MINOR] -as [int]) + 1).ToString()
        }

        # REVISION
        # If increment revision and revision number not equals to "*"
        If ($IncrementRevision -and ($rawVersion[$REVISION] -ne "*")) {
            $rawVersion[$REVISION] = (($rawVersion[$REVISION] -as [int]) + 1).ToString()
        }
        # If increment revision and force 4 digit blocks
        If ($IncrementRevision -and ($rawVersion[$REVISION] -eq "*") -and $Force4DigitBlocks) {
            $rawVersion[$REVISION] = (($rawVersion[$REVISION] -as [int]) + 1).ToString()
        }
        # If revision number not equals to "*" and force 4 digit blocks
        If (($rawVersion[$REVISION] -eq "*") -and $Force4DigitBlocks) {
            $rawVersion[$REVISION] = "0"
        }
            
        # BUILD
        # If increment build and build number not equals to "*"
        If ($IncrementBuild -and ($rawVersion[$BUILD] -ne "*")) {
            $rawVersion[$BUILD] = (($rawVersion[$BUILD] -as [int]) + 1).ToString()
        }
        # If increment revision and force 4 digit blocks
        If ($IncrementBuild -and ($rawVersion[$BUILD] -eq "*") -and $Force4DigitBlocks) {
            $rawVersion[$BUILD] = (($rawVersion[$BUILD] -as [int]) + 1).ToString()
        }
        # If revision number not equals to "*" and force 4 digit blocks
        If (($rawVersion[$BUILD] -eq "*") -and $Force4DigitBlocks) {
            $rawVersion[$BUILD] = "0"
        }
            
        $newVersion = $rawVersion -join "."

        Write-Verbose "Changing assembly version attribute value, in file `"$AssemblyInfoFilePath`", from $currentVersion to $newVersion"

        $content = $content -replace $ASSEMBLY_VERSION_ATTRIBUTE_REGEX, "[assembly: AssemblyVersion(`"$newVersion`")]"
    }

    Write-Verbose "Writing file $AssemblyInfoFilePath..."
    Set-Content -Path $AssemblyInfoFilePath -Value $content -Encoding UTF8
} Finally {
    Write-Verbose "Performing any required $($THIS_SCRIPT_NAME) script cleanup..."
}

# Display the time that this script finished running, and how long it took to run.
$scriptFinishTime = Get-Date
$scriptElapsedTimeInSeconds = ($scriptFinishTime - $scriptStartTime).TotalSeconds.ToString()
Write-Verbose "$($THIS_SCRIPT_NAME) script finished running at $($scriptFinishTime.TimeOfDay.ToString()). Completed in $scriptElapsedTimeInSeconds seconds."