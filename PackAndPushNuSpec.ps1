[CmdletBinding()]
Param (
    [Parameter(Position = 0, Mandatory = $false, ParameterSetName = "Default", HelpMessage = "The directory to look for nuspec files.")]
    [Parameter(Position = 0, Mandatory = $false, ParameterSetName = "PushNuGetPackages")]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [String]$SearchDirectory = $null,

    [Parameter(Position = 1, Mandatory = $true, ParameterSetName = "Default", HelpMessage = "After pack the nuspec file, where to put the nupkg file.")]
    [Parameter(Position = 1, Mandatory = $true, ParameterSetName = "PushNuGetPackages")]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [Alias("OutputDirectory")]
    [String]$NuPkgOutputDirectory = $null,

    [Parameter(Mandatory = $false, HelpMessage = "The new version number to use for the NuGet Packages, if not specified for the nuspec file.")]
    # This regex does not represent Sematic Versioning, but the versioning that NuGet.exe allows.    
    [ValidatePattern('(?i)(^(\d+(\.\d+){1,3})$)|(^(\d+\.\d+\.\d+-[a-zA-Z0-9\-\.\+]+)$)|(^(\$version\$)$)|(^$)')]
    [Alias("V")]
    [String]$Version = $null,

    [Parameter(ParameterSetName = "PushNuGetPackages", Mandatory = $false, HelpMessage = "Whether the nupkg files will be pushed to the NuGet Gallery.")]
    [Alias("Push")]
    [Switch]$PushNuPkgsToNuGetGallery = $false,

    [Parameter(ParameterSetName = "PushNuGetPackages", Mandatory = $true, HelpMessage = "The NuGet gallery address.")]
    [Alias("NGS")]
    [String]$NuGetSource = "https://www.nuget.org",

    [Parameter(ParameterSetName = "PushNuGetPackages", Mandatory = $true, HelpMessage = "The NuGet gallery API key.")]
    [Alias("NGAK")]
    [String]$NuGetApiKey = $null,

    [Parameter(Mandatory = $false, HelpMessage = "Whether should delete the nupkg files after push.")]
    [Alias("DPAP")]
    [Switch]$DeletePackagesAfterPush = $false,

    [Parameter(Mandatory = $false, HelpMessage = "Whether should show prompt window on errors.")]
    [Alias("POE")]
    [Switch]$PromptOnError = $true,
    
    [Parameter(Mandatory = $false, HelpMessage = "Specifies the NuGet executable file path.")]
    [Alias("NuGetExe")]
    [String]$NuGetExecutableFilePath = $null,
    
    [Parameter(Mandatory = $false, HelpMessage = "Whether should update the NuGet executable.")]
    [Alias("UNE")]
    [Switch]$UpdateNuGetExecutable = $false,

    [Parameter(Mandatory = $false, HelpMessage = "Specifies the culture used to get the prompt messages.")]
    [Alias("C")]
    [String]$Culture = "pt-BR"
)

# Turn on Strict Mode to help catch syntax-related errors.
#   This must come after a script's/function's param section.
#   Forces a Function to be the first non-comment code to appear in a PowerShell Module.
Set-StrictMode -Version Latest

# Default the ParameterSet variables that may not have been set depending on which parameter set is being used. This is required for PowerShell v2.0 compatibility.
If (!(Test-Path Variable:Private:PushNuPkgsToNuGetGallery)) { $PushNuPkgsToNuGetGallery = $false }
If (!(Test-Path Variable:Private:DeletePackagesAfterPush)) { $DeletePackagesAfterPush = $false }
If (!(Test-Path Variable:Private:PromptOnError)) { $PromptOnError = $true }
If (!(Test-Path Variable:Private:UpdateNuGetExecutable)) { $UpdateNuGetExecutable = $false }

#==========================================================
# Define any necessary global variables, such as file paths.
#==========================================================

# Gets the script file name, without extension.
$SCRIPT_FILE_NAME = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Definition)

# Get the directory that this script is in.
$CURRENT_SCRIPTS_DIRECTORY_PATH = Split-Path $script:MyInvocation.MyCommand.Path

#==========================================================
# Strings to look for in console app output.
# If running in a non-english language, these strings will
# need to be changed to the strings returned by the console
# apps when running in the non-english language.
#==========================================================

# NuGet.exe output strings.
$NUGET_EXE_SUCCESSFULLY_PUSHED_PACKAGE_MESSAGE = $null
$NUGET_EXE_SUCCESSFULLY_CREATED_PACKAGE_MESSAGE_REGEX = $null

#==========================================================
# Define console output string localization
#==========================================================
Switch ($Culture) {
    "pt-BR" {
        $NUGET_EXE_SUCCESSFULLY_PUSHED_PACKAGE_MESSAGE = 'Seu pacote foi enviado.'
        $NUGET_EXE_SUCCESSFULLY_CREATED_PACKAGE_MESSAGE_REGEX = [Regex]"(?i)(Pacote '(?<FilePath>.*?)' criado com êxito.)"
    }
    default {
        $NUGET_EXE_SUCCESSFULLY_PUSHED_PACKAGE_MESSAGE = 'Your package was pushed.'
        $NUGET_EXE_SUCCESSFULLY_CREATED_PACKAGE_MESSAGE_REGEX = [Regex]"(?i)(Successfully created package '(?<FilePath>.*?)'.)"
    }
}

#==========================================================
# Define functions used by the script.
#==========================================================

# Catch any exceptions Thrown, display the error message, wait for input if appropriate, and then stop the script.
Trap [Exception] {
    $errorMessage = $_
    Write-Host "An error occurred while running $($SCRIPT_FILE_NAME) script:`n$errorMessage`n" -Foreground Red
    
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

# Pack the nuspec file and returns the location of the nupkg file.
Function Pack-NuSpecFile([String]$filePath, [String]$outputDirectory) {
    # Create the command to use to create the package.
    $versionNumber = $null
    If (!(Test-StringIsNullOrWhitespace $Version)) {
        $versionNumber = "-Version $Version"
    }

    $packCommand = "& `"$NuGetExecutableFilePath`" pack `"$filePath`" -OutputDirectory `"$outputDirectory`" $versionNumber"
    $packCommand = $packCommand -ireplace ';', '`;' # Escape any semicolons so they are not interpreted as the start of a new command.

    # Create the package.
    Write-Verbose "About to run Pack command '$packCommand'."
    $packOutput = Start-Job {
        Param($location, $command)
        
        Set-Location $location
        $result = (Invoke-Expression -Command $command | Out-String).Trim()

        Return $result
    } -ArgumentList $CURRENT_SCRIPTS_DIRECTORY_PATH, $packCommand | Wait-Job | Receive-Job

    # Get the path the NuGet Package was created to, and write it to the output stream.
    $match = $NUGET_EXE_SUCCESSFULLY_CREATED_PACKAGE_MESSAGE_REGEX.Match($packOutput)
    If ($match.Success) {
        $nuPkgFilePath = $match.Groups["FilePath"].Value
    } Else {
        Throw "Could not determine where NuGet Package was created to. This typically means that an error occurred while NuGet.exe was packing it. Look for errors from NuGet.exe above (in the console window), or in the following NuGet.exe output. You can also try running this command with the -Verbose switch for more information:{0}{1}" -f [Environment]::NewLine, $packOutput
    }

    Return $nuPkgFilePath
}

# Push the nupkg file to the NuGet Gallery
Function Push-NuPkgFile([String]$filePath) {
    # Create the command to use to push the package to the gallery.
    $pushCommand = "& `"$NuGetExecutableFilePath`" push `"$filePath`" -Source `"$NuGetSource`" -ApiKey `"$NuGetApiKey`""
    $pushCommand = $pushCommand -ireplace ';', '`;' # Escape any semicolons so they are not interpreted as the start of a new command.

    # Push the package to the gallery.
    Write-Verbose "About to run Push command '$pushCommand'."
    $pushOutput = Start-Job {
        Param($location, $command)
        
        Set-Location $location
        $result = (Invoke-Expression -Command $command | Out-String).Trim()

        Return $result
    } -ArgumentList $CURRENT_SCRIPTS_DIRECTORY_PATH, $pushCommand | Wait-Job | Receive-Job

    # If an error occurred while pushing the package, Throw and error. Else it was pushed successfully.
    If (!$pushOutput.EndsWith($NUGET_EXE_SUCCESSFULLY_PUSHED_PACKAGE_MESSAGE.Trim())) {
        Throw "Could not determine if package was pushed to gallery successfully. Perhaps an error occurred while pushing it. Look for errors from NuGet.exe above (in the console window), or in the following NuGet.exe output. You can also try running this command with the -Verbose switch for more information:{0}{1}" -f [Environment]::NewLine, $pushOutput
    }
}

#==========================================================
# Perform the script tasks.
#==========================================================

# Display the time that this script started running.
$scriptStartTime = Get-Date
Write-Verbose "$($SCRIPT_FILE_NAME) script started running at $($scriptStartTime.TimeOfDay.ToString())."

# Display the version of PowerShell being used to run the script, as this can help solve some problems that are hard to reproduce on other machines.
Write-Verbose "Using PowerShell Version: $($PSVersionTable.PSVersion.ToString())."

Try {
    # If search directory was not provided, uses the current script directory to start search.
    If (Test-StringIsNullOrWhitespace $SearchDirectory) {
        $SearchDirectory = $CURRENT_SCRIPTS_DIRECTORY_PATH
    }

    Write-Verbose "Looking for .nuspec files in directory (recursive): $SearchDirectory"
    # Get all of the .nuspec files in the specified search directory.
    $nuSpecFileCollection = Get-ChildItem "$SearchDirectory" -Recurse -Include "*.nuspec" -Name

    # Get the number of files found.
    $numberOfNuSpecFilesFound = @($nuSpecFileCollection).Length
    Write-Verbose "Total .nuspec files found: $numberOfNuSpecFilesFound"

    # If no file was found, throw exception.
    If ($numberOfNuSpecFilesFound -eq 0) { Throw "Could not find any .nuspec file." }

    Write-Verbose "List of .nuspec files found:"
    $nuSpecFileCollection | ForEach-Object { Write-Verbose "`t - $([System.IO.Path]::GetFileName($_))" }

    # If a path to the NuGet executable was not provided, try and find it.
    If (Test-StringIsNullOrWhitespace $NuGetExecutableFilePath) {
        # If the NuGet executable is in the same directory as this script, use it.
        $nuGetExecutablePathInThisDirectory = Join-Path $CURRENT_SCRIPTS_DIRECTORY_PATH "NuGet.exe"
        If (Test-Path $nuGetExecutablePathInThisDirectory) {
            $NuGetExecutableFilePath = $nuGetExecutablePathInThisDirectory
        } Else { # Else we don't know where the executable is, so assume it has been added to the PATH.
            $NuGetExecutableFilePath = "NuGet.exe"
        }
    }

    # If we should try and update the NuGet executable.
    If ($UpdateNuGetExecutable) {
        # Create the command to use to update NuGet.exe.
        $updateCommand = "& `"$NuGetExecutableFilePath`" update -Self"

        # Have the NuGet executable try and auto-update itself.
        Write-Verbose "About to run Update command `"$updateCommand`"."
        $updateOutput = (Invoke-Expression -Command $updateCommand | Out-String).Trim()
        
        # Write the output of the above command to the Verbose stream.
        Write-Verbose $updateOutput
    }

    # Get and display the version of NuGet.exe that will be used. If NuGet.exe is not found an exception will be thrown automatically.
    # Create the command to use to get the Nuget Help info.
    $helpCommand = "& `"$NuGetExecutableFilePath`""

    # Get the NuGet.exe Help output.
    Write-Verbose "About to run Help command `"$helpCommand`"."
    $helpOutput = (Invoke-Expression -Command $helpCommand | Out-String).Trim()
    
    # If no help output was retrieved, the NuGet.exe likely returned an error.
    If (Test-StringIsNullOrWhitespace $helpOutput) {
        # Get the error information returned by NuGet.exe, and throw an error that we could not run NuGet.exe as expected.
        $helpError = (Invoke-Expression -Command $helpCommand 2>&1 | Out-String).Trim()
        Throw "NuGet information could not be retrieved by running `"$NuGetExecutableFilePath`".`r`n`r`nRunning `"$NuGetExecutableFilePath`" returns the following information:`r`n`r`n$helpError"
    }

    # Display the version of the NuGet.exe. This information is the first line of the NuGet help output.
    $nuGetVersionString = ($helpOutput -split "`r`n")[0]
    Write-Verbose "Using $($nuGetVersionString)."

    $directoryPathToPutNuPkgIn = $NuPkgOutputDirectory
    # Make sure our backup output directory is an absolute path.
    If (![System.IO.Path]::IsPathRooted($directoryPathToPutNuPkgIn)) {
        $directoryPathToPutNuPkgIn = Resolve-Path $directoryPathToPutNuPkgIn
        Write-Verbose "Resolving nupkg output directory path from `"$NuPkgOutputDirectory`" to `"$directoryPathToPutNuPkgIn`""
    }

    $nuPkgFileCollection = New-Object System.Collections.Generic.HashSet[String]
    Try {
        $nuSpecFileCollection | ForEach-Object {
            # Create the package.
            $nuPkgFilePath = Pack-NuSpecFile $_ $directoryPathToPutNuPkgIn

            # If we should push the Nuget package to the gallery.
            If ($PushNuPkgsToNuGetGallery) { Push-NuPkgFile $nuPkgFilePath }

            $nuPkgFileCollection.Add($nuPkgFilePath) | Out-Null
        }
    } Catch { Write-Error $_.Exception.Message }

    # If the package should be deleted.
    If ($DeletePackagesAfterPush) {
        Write-Verbose "Deleting .nupkg files and output directory `"$directoryPathToPutNuPkgIn`"."
        Get-ChildItem $directoryPathToPutNuPkgIn -Include *.* -Recurse | Remove-Item
        Remove-Item -Path $directoryPathToPutNuPkgIn -Force
    }

    Write-Verbose "List of all .nupkg files (packed and, if specified, pushed):"
    $nuPkgFileCollection | ForEach-Object { Write-Verbose "`t - $([System.IO.Path]::GetFileName($_))" }
} Finally {
    Write-Verbose "Performing any required $($SCRIPT_FILE_NAME) script cleanup..."
}

# Display the time that this script finished running, and how long it took to run.
$scriptFinishTime = Get-Date
$scriptElapsedTimeInSeconds = ($scriptFinishTime - $scriptStartTime).TotalSeconds.ToString()
Write-Verbose "$($SCRIPT_FILE_NAME) script finished running at $($scriptFinishTime.TimeOfDay.ToString()). Completed in $scriptElapsedTimeInSeconds seconds."