#Requires -Version 2.0
<#
	.SYNOPSIS
	Creates a NuGet Package (.nupkg) file from the given NuSpec file, and
    optionally uploads it to a NuGet Gallery.
	
	.DESCRIPTION
	Creates a NuGet Package (.nupkg) file from the given NuSpec file.
	Additional parameters may be provided to also upload the new NuGet package
    to a NuGet Gallery. If an "-OutputDirectory" is not provided via the
    PackOptions parameter, the default is to place the .nupkg file in a
    "nuget_packages" directory in the same directory as the .nuspec file being
    packed.
	
	.PARAMETER NuSpecFilePath
	The path to the .nuspec file to pack.

	.PARAMETER VersionNumber
	The version number to use for the NuGet package.
	The version element in the .nuspec file (if available) will be updated with
    the given value unless the DoNotUpdateNuSpecFile switch is provided.
	If this parameter is not provided then you will be prompted for the version
    number to use (unless the NoPrompt or PromptForVersionNumber switch is
    provided). If the "-Version" parameter is provided in the PackOptions, that
    version will be used for the NuGet package, but this version will be used
    to update the .nuspec file (if available).

	.PARAMETER ReleaseNotes
	The release notes to use for the NuGet package.
	The release notes element in the .nuspec file (if available) will be updated
    with the given value.
	
	.PARAMETER PackOptions
	The arguments to pass to NuGet's Pack command. These will be passed to the
    NuGet executable as-is, so be sure to follow the NuGet's required syntax.
    See http://docs.nuget.org/docs/reference/command-line-reference for valid parameters.

	.PARAMETER PushPackageToNuGetGallery
	If this switch is provided the NuGet package will be pushed to the NuGet
    gallery.Use the PushOptions to specify a custom gallery to push to, or
    an API key if required.

	.PARAMETER PushOptions
	The arguments to pass to NuGet's Push command. These will be passed to the
    NuGet executable as-is, so be sure to follow the NuGet's required syntax.
	See http://docs.nuget.org/docs/reference/command-line-reference for valid parameters.

    .PARAMETER DeletePackageAfterPush
    If this switch is provided and the package is successfully pushed to a
    NuGet gallery, the NuGet package file will then be deleted.
	
	.PARAMETER Prompt
	If this switch is provided the user will be prompted for the version number
    or release notes; otherwise the current ones in the .nuspec file will be
    used (if available). The user will be prompted for other forms of input,
    such as if they want to push the package to a gallery, or to give input
    before the script exits when an error occurs. This parameter should not be
    provided when an automated mechanism is running this script
    (e.g. an automated build system).
	
	.PARAMETER NoPromptExceptOnError
	The same as NoPrompt except if an error occurs the user will be prompted for input before the script exists, making sure they are notified that an error occurred.
	If both this and the NoPrompt switch are provided, the NoPrompt switch will be used.
	If both this and the NoPromptForInputOnError switch are provided, it is the same as providing the NoPrompt switch.
	
	.PARAMETER PromptForVersionNumber
	If this switch is provided the user will not be prompted for the version number; the one in the .nuspec file will be used (if available).
	
	.PARAMETER PromptForReleaseNotes
	If this switch is provided the user will not be prompted for the release notes; the ones in the .nuspec file will be used (if available).
	
	.PARAMETER NoPromptForPushPackageToNuGetGallery
	If this switch is provided the user will not be asked if they want to push the new package to the NuGet Gallery when the PushPackageToNuGetGallery switch is not provided.	
	
	.PARAMETER NoPromptForInputOnError
	If this switch is provided the user will not be prompted for input before the script exits when an error occurs, so they may not notice than an error occurred.	
	
	.PARAMETER UsePowerShellPrompt
	If this switch is provided any prompts for user input will be made via the PowerShell console, rather than the regular GUI components.
	This may be preferable when attempting to pipe input into the cmdlet.
	
	.PARAMETER DoNotUpdateNuSpecFile
	If this switch is provided a backup of the .nuspec file (if available) will be made, changes will be made to the original .nuspec file in order to 
	properly perform the pack, and then the original file will be restored once the pack is complete.

	.PARAMETER NuGetExecutableFilePath
	The full path to NuGet.exe.
	If not provided it is assumed that NuGet.exe is in the same directory as this script, or that NuGet.exe has been added to your PATH and can be called directly from the command prompt.

	.PARAMETER UpdateNuGetExecutable
	If this switch is provided "NuGet.exe update -self" will be performed before packing or pushing anything.
	Provide this switch to ensure your NuGet executable is always up-to-date on the latest version.

	.EXAMPLE
	& .\New-NuGetPackage.ps1

	Run the script without any parameters (e.g. as if it was ran directly from Windows Explorer).
	This will prompt the user for a .nuspec, project, or .nupkg file if one is not found in the same directory as the script, as well as for any other input that is required.
	This assumes that you are currently in the same directory as the New-NuGetPackage.ps1 script, since a relative path is supplied.

	.EXAMPLE
	& "C:\Some Folder\New-NuGetPackage.ps1" -NuSpecFilePath ".\Some Folder\SomeNuSpecFile.nuspec" -Verbose

	Create a new package from the SomeNuSpecFile.nuspec file.
	This can be ran from any directory since an absolute path to the New-NuGetPackage.ps1 script is supplied.
	Additional information will be displayed about the operations being performed because the -Verbose switch was supplied.
	
	.EXAMPLE
	& .\New-NuGetPackage.ps1 -ProjectFilePath "C:\Some Folder\TestProject.csproj" -VersionNumber "1.1" -ReleaseNotes "Version 1.1 contains many bug fixes."

	Create a new package from the TestProject.csproj file.
	Because the VersionNumber and ReleaseNotes parameters are provided, the user will not be prompted for them.
	If "C:\Some Folder\TestProject.nuspec" exists, it will automatically be picked up and used when creating the package; if it contained a version number or release notes, they will be overwritten with the ones provided.

	.EXAMPLE
	& .\New-NuGetPackage.ps1 -ProjectFilePath "C:\Some Folder\TestProject.csproj" -PackOptions "-Build -OutputDirectory ""C:\Output""" -UsePowerShellPrompt

	Create a new package from the TestProject.csproj file, building the project before packing it and saving the  package in "C:\Output".
	Because the UsePowerShellPrompt parameter was provided, all prompts will be made via the PowerShell console instead of GUI popups.
	
	.EXAMPLE
	& .\New-NuGetPackage.ps1 -NuSpecFilePath "C:\Some Folder\SomeNuSpecFile.nuspec" -NoPrompt
	
	Create a new package from SomeNuSpecFile.nuspec without prompting the user for anything, so the existing version number and release notes in the .nuspec file will be used.
	
	.EXAMPLE	
	& .\New-NuGetPackage.ps1 -NuSpecFilePath ".\Some Folder\SomeNuSpecFile.nuspec" -VersionNumber "9.9.9.9" -DoNotUpdateNuSpecFile
	
	Create a new package with version number "9.9.9.9" from SomeNuSpecFile.nuspec without saving the changes to the file.
	
	.EXAMPLE
	& .\New-NuGetPackage.ps1 -NuSpecFilePath "C:\Some Folder\SomeNuSpecFile.nuspec" -PushPackageToNuGetGallery -PushOptions "-Source ""http://my.server.com/MyNuGetGallery"" -ApiKey ""EAE1E980-5ECB-4453-9623-F0A0250E3A57"""
	
	Create a new package from SomeNuSpecFile.nuspec and push it to a custom NuGet gallery using the user's unique Api Key.
	
	.EXAMPLE
	& .\New-NuGetPackage.ps1 -NuSpecFilePath "C:\Some Folder\SomeNuSpecFile.nuspec" -NuGetExecutableFilePath "C:\Utils\NuGet.exe"

	Create a new package from SomeNuSpecFile.nuspec by specifying the path to the NuGet executable (required when NuGet.exe is not in the user's PATH).

    .EXAMPLE
    & New-NuGetPackage.ps1 -PackageFilePath "C:\Some Folder\MyPackage.nupkg"

    Push the existing "MyPackage.nupkg" file to the NuGet gallery.
    User will be prompted to confirm that they want to push the package; to avoid this prompt supply the -PushPackageToNuGetGallery switch.

	.EXAMPLE
	& .\New-NuGetPackage.ps1 -NoPromptForInputOnError -UpdateNuGetExecutable

	Create a new package or push an existing package by auto-finding the .nuspec, project, or .nupkg file to use, and prompting for one if none are found.
	Will not prompt the user for input before exitting the script when an error occurs.

	.OUTPUTS
	Returns the full path to the NuGet package that was created.
	If a NuGet package was not required to be created (e.g. you were just pushing an existing package), then nothing is returned.
	Use the -Verbose switch to see more detailed information about the operations performed.
	
	.LINK
	Project home: https://newnugetpackage.codeplex.com

	.NOTES
	Author: Daniel Schroeder
	Version: 1.5.6
	
	This script is designed to be called from PowerShell or ran directly from Windows Explorer.
	If this script is ran without the $NuSpecFilePath, $ProjectFilePath, and $PackageFilePath parameters, it will automatically search for a .nuspec, project, or package file in the 
	same directory as the script and use it if one is found. If none or more than one are found, the user will be prompted to specify the file to use.
#>
[CmdletBinding(DefaultParameterSetName = "PackUsingNuSpec")]
Param(
	[Parameter(Position = 1, Mandatory = $false, ParameterSetName = "PackUsingNuSpec")]
	[ValidateScript({Test-Path $_ -PathType Leaf})]
    [String] $NuSpecFilePath,

	[Parameter(Position = 2, Mandatory=$false, ParameterSetName = "PackUsingNuSpec", HelpMessage = "The new version number to use for the NuGet Package.")]
	[ValidatePattern('(?i)(^(\d+(\.\d+){1,3})$)|(^(\d+\.\d+\.\d+-[a-zA-Z0-9\-\.\+]+)$)|(^(\$version\$)$)|(^$)')]	# This validation is duplicated in the Update-NuSpecFile function, so update it in both places. This regex does not represent Sematic Versioning, but the versioning that NuGet.exe allows.
	[Alias("Version")]
	[Alias("V")]
	[String] $VersionNumber,

    [Parameter(ParameterSetName = "PackUsingNuSpec")]
	[Alias("Notes")]
	[String] $ReleaseNotes,

	[Alias("Push")]
	[Switch] $PushPackageToNuGetGallery,

	[String] $PushOptions,

    [Alias("DPAP")]
    [Switch] $DeletePackageAfterPush,
	
	[Alias("NP")]
	[Switch] $Prompt,
	
	[Alias("NPEOE")]
	[Switch] $NoPromptExceptOnError,

    [Parameter(ParameterSetName = "PackUsingNuSpec")]
	[Alias("NPFVN")]
	[Switch] $PromptForVersionNumber,
	
    [Parameter(ParameterSetName = "PackUsingNuSpec")]
	[Alias("NPFRN")]
	[Switch] $PromptForReleaseNotes,
	
	[Alias("NPFPPTNG")]
	[Switch] $PromptForPushPackageToNuGetGallery,
	
	[Alias("NPFIOE")]
	[Switch] $NoPromptForInputOnError,
	
	[Alias("UPSP")]
	[Switch] $UsePowerShellPrompt,
	
	[Alias("NuGet")]
	[String] $NuGetExecutableFilePath,
	
	[Alias("UNE")]
	[Switch] $UpdateNuGetExecutable,

	[String] $Culture = "pt-BR"
)

# Turn on Strict Mode to help catch syntax-related errors.
#   This must come after a script's/function's Param section.
#   Forces a Function to be the first non-comment code to appear in a PowerShell Module.
Set-StrictMode -Version Latest

# Default the ParameterSet variables that may not have been set depending on which parameter set is being used. This is required for PowerShell v2.0 compatibility.
If (!(Test-Path Variable:Private:NuSpecFilePath)) { $NuSpecFilePath = $null }
If (!(Test-Path Variable:Private:VersionNumber)) { $VersionNumber = $null }
If (!(Test-Path Variable:Private:ReleaseNotes)) { $ReleaseNotes = $null }
If (!(Test-Path Variable:Private:PackOptions)) { $PackOptions = $null }
If (!(Test-Path Variable:Private:PromptForVersionNumber)) { $PromptForVersionNumber = $false }
If (!(Test-Path Variable:Private:PromptForReleaseNotes)) { $PromptForReleaseNotes = $false }

#==========================================================
# Define any necessary global variables, such as file paths.
#==========================================================

# Import any necessary assemblies.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

# New line
$CRLF = [environment]::newline

# Get the script name
$THIS_SCRIPT_NAME = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Definition)

# Get the directory that this script is in.
$THIS_SCRIPT_DIRECTORY_PATH = Split-Path $script:MyInvocation.MyCommand.Path

# The directory to put the NuGet package into if one is not supplied.
$DEFAULT_DIRECTORY_TO_PUT_NUGET_PACKAGES_IN = "nuget_packages"

# The file path where the API keys are saved.
$NUGET_CONFIG_FILE_PATH = Join-Path $env:APPDATA "NuGet\NuGet.config"

# The default NuGet source to push to when one is not explicitly provided.
$DEFAULT_NUGET_SOURCE_TO_PUSH_TO = "https://www.nuget.org"

#==========================================================
# Strings to look for in console app output.
# If running in a non-english language, these strings will need to be changed to the strings returned by the console apps when running in the non-english language.
#==========================================================

# NuGet.exe output strings.
$NUGET_EXE_SUCCESSFULLY_CREATED_PACKAGE_MESSAGE_REGEX = $null
$NUGET_EXE_SUCCESSFULLY_PUSHED_PACKAGE_MESSAGE = $null
$NUGET_EXE_SUCCESSFULLY_SAVED_API_KEY_MESSAGE = $null
$NUGET_EXE_SUCCESSFULLY_UPDATED_TO_NEW_VERSION = $null

# Translate strings using the Culture parameter
Switch ($Culture) {
	"pt-BR" {
		$NUGET_EXE_SUCCESSFULLY_CREATED_PACKAGE_MESSAGE_REGEX = [regex] "(?i)(Successfully created package '(?<FilePath>.*?)'.)"
		$NUGET_EXE_SUCCESSFULLY_PUSHED_PACKAGE_MESSAGE = 'Your package was pushed.'
		$NUGET_EXE_SUCCESSFULLY_SAVED_API_KEY_MESSAGE = "The API Key '{0}' was saved for '{1}'."
		$NUGET_EXE_SUCCESSFULLY_UPDATED_TO_NEW_VERSION = 'Update successful.'
	}
	default {
		$NUGET_EXE_SUCCESSFULLY_CREATED_PACKAGE_MESSAGE_REGEX = [regex] "(?i)(Successfully created package '(?<FilePath>.*?)'.)"
		$NUGET_EXE_SUCCESSFULLY_PUSHED_PACKAGE_MESSAGE = 'Your package was pushed.'
		$NUGET_EXE_SUCCESSFULLY_SAVED_API_KEY_MESSAGE = "The API Key '{0}' was saved for '{1}'."
		$NUGET_EXE_SUCCESSFULLY_UPDATED_TO_NEW_VERSION = 'Update successful.'
	}
}

#==========================================================
# Define functions used by the script.
#==========================================================

# Catch any exceptions thrown, display the error message, wait for input if appropriate, and then stop the script.
Trap [Exception] {
	$errorMessage = $_
	Write-Host ("An error occurred while running New-NuGetPackage script:{1}{0}{1}" -f $errorMessage, $CRLF)  -Foreground Red
	
	If (!$NoPromptForInputOnError) {
		# If we should prompt directly from PowerShell.
		If ($UsePowerShellPrompt) {
			Write-Host "Press any key to continue ..."
			$userInput = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp")
		} Else { # Else use a nice GUI prompt.
			$VersionNumber = Read-messageBoxDialog -message $errorMessage -windowTitle "Error Occurred Running New-NuGetPackage Script" -buttons OK -icon Error
		}
	}
	Break
}

# Function to return the path to backup the NuSpec file to if needed.
Function Get-NuSpecBackupFilePath { return "$NuSpecFilePath.bkp" }

# PowerShell v2.0 compatible version of [String]::IsNullOrWhitespace.
Function Test-StringIsNullOrWhitespace([String] $value) {
    return [String]::IsNullOrWhitespace($value)
}

# Function to update the $NuSpecFilePath (.nuspec file) with the appropriate
#   information before using it to create the NuGet package.
Function Update-NuSpecFile {
	Write-Verbose "Starting process to update the .nuspec file '$NuSpecFilePath'..."

    # If we don't have a NuSpec file to update, throw an error that something went wrong.
    If (!(Test-Path $NuSpecFilePath)) {
        Throw "The Update-NuSpecFile Function was called with an invalid NuSpecFilePath parameter value; this should not happen. There must be a bug in this script."
    }

    # First, let's create a backup file
    Copy-Item -Path $NuSpecFilePath -Destination (Get-NuSpecBackupFilePath) -Force

	# Validate that the NuSpec file is a valid xml file.
	Try {
		$nuSpecXml = New-Object System.Xml.xmlDocument
		$nuSpecXml.Load($NuSpecFilePath)	# Will throw an exception if it is unable to load the xml properly.
		$nuSpecXml = $null					# Release the memory.
	} Catch {
		Throw ("An error occurred loading the nuspec xml file '{0}': {1}" -f $NuSpecFilePath, $_.Exception.Message)
	}

	# Get the current version number from the .nuspec file.
	$currentVersionNumber = Get-NuSpecVersionNumber -NuSpecFilePath $NuSpecFilePath

	# If an explicit Version Number was not provided, prompt for it.
	If (Test-StringIsNullOrWhitespace $VersionNumber) {
		# If we should prompt for a version number.
		If ($PromptForVersionNumber) {
            $promptMessage = 'Enter the NuGet package version number to use (x.x[.x.x] or $version$ if packing a project file)'
			
			# If we should prompt directly from PowerShell.
			If ($UsePowerShellPrompt) {
				$VersionNumber = Read-Host ("{0}. Current value in the .nuspec file is:{2}{1}{2}" -f $promptMessage, $currentVersionNumber, $CRLF)
			} Else { # Else use a nice GUI prompt.
				$VersionNumber = Read-InputBoxDialog -message "$promptMessage`:" -windowTitle "NuGet Package Version Number" -defaultText $currentVersionNumber
			}
		} Else { # Otherwise just use the existing one from the NuSpec file (if it exists).
			$VersionNumber = $currentVersionNumber
		}
		
		# The script's parameter validation does not seem to be enforced (probably because this is inside a function), so re-enforce it here.
		$regexVersionNumberValidation = [regex] '(?i)(^(\d+(\.\d+){1,3})$)|(^(\d+\.\d+\.\d+-[a-zA-Z0-9\-\.\+]+)$)|(^(\$version\$)$)|(^$)'	# This validation is duplicated in the Update-NuSpecFile function, so update it in both places. This regex does not represent Sematic Versioning, but the versioning that NuGet.exe allows.

		# If the user cancelled the prompt or did not provide a valid version number, exit the script.
		If ((Test-StringIsNullOrWhitespace $VersionNumber) -or !$regexVersionNumberValidation.IsMatch($VersionNumber)) {
			Throw "A valid version number to use for the NuGet package was not provided, so exiting script. The version number provided was '$VersionNumber', which does not conform to the Semantic Versioning guidelines specified at http://semver.org."
		}
	}
	
	# Insert the given version number into the .nuspec file, if it is different.
	If ($currentVersionNumber -ne $VersionNumber) {
		Set-NuSpecVersionNumber -NuSpecFilePath $NuSpecFilePath -NewVersionNumber $VersionNumber
	}
	
	# Get the current release notes from the .nuspec file.
	$currentReleaseNotes = Get-NuSpecReleaseNotes -NuSpecFilePath $NuSpecFilePath
	
	# If the Release Notes were not provided, prompt for them.
	If (Test-StringIsNullOrWhitespace $ReleaseNotes) {		
		# If we should prompt the user for the Release Notes to add to the .nuspec file.
		If ($PromptForReleaseNotes) {
			$promptMessage = "Please enter the release notes to include in the new NuGet package"
			
			# If we should prompt directly from PowerShell.
			If ($UsePowerShellPrompt) {
				$ReleaseNotes = Read-Host "$promptMessage. Current value in the .nuspec file is:`n$currentReleaseNotes`n"
			} Else { # Else use a nice GUI prompt.
				$ReleaseNotes = Read-MultiLineInputBoxDialog -message "$promptMessage`:" -windowTitle "Enter Release Notes For New Package" -defaultText $currentReleaseNotes
			}
			
			# If the user cancelled the release notes prompt, exit the script.
			If ($ReleaseNotes -eq $null) { 
				Throw "User cancelled the Release Notes prompt, so exiting script."
			}
		} Else { # Otherwise, just use the existing ones from the NuSpec file (if it exists).
            $ReleaseNotes = $currentReleaseNotes
		}		
	}

	# Insert the given Release Notes into the .nuspec file if some were provided, and they are different than the current ones.
	If ($currentReleaseNotes -ne $ReleaseNotes) {
		Set-NuSpecReleaseNotes -NuSpecFilePath $NuSpecFilePath -NewReleaseNotes $ReleaseNotes
	}
	
	Write-Verbose "Finished process to update the nuspec file '$NuSpecFilePath'."
}

Function Get-NuSpecVersionNumber(
    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [String] $nuSpecFilePath
) {	
	# Read in the file contents and return the version element's value.
    $fileContents = New-Object System.Xml.XmlDocument
    $fileContents.Load($nuSpecFilePath)
	return Get-XmlElementsTextValue -xmlDocument $fileContents -elementPath "package.metadata.version"
}

Function Set-NuSpecVersionNumber(
    [Parameter(Position = 1,Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [String] $nuSpecFilePath,
    
    [Parameter(Position = 2, Mandatory = $true)]
    [String] $newVersionNumber
) {	
	# Read in the file contents, update the version element's value, and save the file.
	$fileContents = New-Object System.Xml.XmlDocument
    $fileContents.Load($nuSpecFilePath)
	Set-XmlElementsTextValue -xmlDocument $fileContents -elementPath "package.metadata.version" -textValue $newVersionNumber
	$fileContents.Save($nuSpecFilePath)
}

Function Get-NuSpecReleaseNotes(
    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [String] $nuSpecFilePath
) {	
	# Read in the file contents and return the version element's value.
	$fileContents = New-Object System.Xml.XmlDocument
    $fileContents.Load($nuSpecFilePath)
	return Get-XmlElementsTextValue -xmlDocument $fileContents -elementPath "package.metadata.releaseNotes"
}

Function Set-NuSpecReleaseNotes(
    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [String] $nuSpecFilePath,
    [Parameter(Position = 2)]
    [String] $newReleaseNotes
) {
	# Read in the file contents, update the version element's value, and save the file.
	$fileContents = New-Object System.Xml.XmlDocument
    $fileContents.Load($nuSpecFilePath)
	Set-XmlElementsTextValue -xmlDocument $fileContents -elementPath "package.metadata.releaseNotes" -textValue $newReleaseNotes
	$fileContents.Save($nuSpecFilePath)
}

Function Get-XmlNamespaceManager([xml]$xmlDocument, [String]$namespaceURI = "") {
    # If a Namespace URI was not given, use the Xml document's default namespace.
	If (Test-StringIsNullOrWhitespace $namespaceURI) { $namespaceURI = $xmlDocument.DocumentElement.NamespaceURI }
	
	# In order for SelectSingleNode() to actually work, we need to use the fully qualified node path along with an Xml Namespace Manager, so set them up.
	[System.Xml.XmlNamespaceManager]$xmlNsManager = New-Object System.Xml.XmlNamespaceManager($xmlDocument.NameTable)
	$xmlNsManager.AddNamespace("ns", $namespaceURI)
    return ,$xmlNsManager		# Need to put the comma before the variable name so that PowerShell doesn't convert it into an Object[].
}

Function Get-FullyQualifiedXmlNodePath([String]$nodePath, [String]$nodeSeparatorCharacter = '.') {
    return "/ns:$($nodePath.Replace($($nodeSeparatorCharacter), '/ns:'))"
}

Function Get-XmlNode([xml]$xmlDocument, [String]$nodePath, [String]$namespaceURI = "", [String]$nodeSeparatorCharacter = '.') {
	$xmlNsManager = Get-XmlNamespaceManager -xmlDocument $xmlDocument -namespaceURI $namespaceURI
	[String]$fullyQualifiedNodePath = Get-FullyQualifiedXmlNodePath -nodePath $nodePath -nodeSeparatorCharacter $nodeSeparatorCharacter
	
	# Try and get the node, then return it. Returns $null if the node was not found.
	$node = $xmlDocument.SelectSingleNode($fullyQualifiedNodePath, $xmlNsManager)
	return $node
}

Function Get-XmlNodes([xml]$xmlDocument, [String]$nodePath, [String]$namespaceURI = "", [String]$nodeSeparatorCharacter = '.') {
	$xmlNsManager = Get-XmlNamespaceManager -xmlDocument $xmlDocument -namespaceURI $namespaceURI
	[String]$fullyQualifiedNodePath = Get-FullyQualifiedXmlNodePath -nodePath $nodePath -nodeSeparatorCharacter $nodeSeparatorCharacter

	# Try and get the nodes, then return them. Returns $null if no nodes were found.
	$nodes = $xmlDocument.SelectNodes($fullyQualifiedNodePath, $xmlNsManager)
	return $nodes
}

Function Get-XmlElementsTextValue([xml]$xmlDocument, [String]$elementPath, [String]$namespaceURI = "", [String]$nodeSeparatorCharacter = '.') {
	# Try and get the node.	
	$node = Get-XmlNode -xmlDocument $xmlDocument -nodePath $elementPath -namespaceURI $namespaceURI -nodeSeparatorCharacter $nodeSeparatorCharacter
	
	# If the node already exists, return its value, otherwise return null.
	If ($node) { return $node.InnerText } else { return $null }
}

Function Set-XmlElementsTextValue([xml]$xmlDocument, [String]$elementPath, [String]$textValue, [String]$namespaceURI = "", [String]$nodeSeparatorCharacter = '.') {
	# Try and get the node.	
	$node = Get-XmlNode -xmlDocument $xmlDocument -NodePath $elementPath -NamespaceURI $namespaceURI -NodeSeparatorCharacter $nodeSeparatorCharacter
	
	# If the node doesn't exist yet, so create it with the given value.
	If ($node -eq $null) { 
		# Create the new element with the given value.
		$elementName = $elementPath.Substring($elementPath.LastIndexOf($nodeSeparatorCharacter) + 1)
 		$element = $xmlDocument.CreateElement($elementName, $xmlDocument.DocumentElement.NamespaceURI)
		$textNode = $xmlDocument.CreateTextNode($textValue)
		$element.AppendChild($textNode) > $null
		
		# Try and get the parent node.
		$parentNodePath = $elementPath.Substring(0, $elementPath.LastIndexOf($nodeSeparatorCharacter))
		$parentNode = Get-XmlNode -xmlDocument $xmlDocument -nodePath $parentNodePath -namespaceURI $namespaceURI -nodeSeparatorCharacter $nodeSeparatorCharacter
		
		If ($parentNode) {
			$parentNode.AppendChild($element) > $null
		} Else {
			throw "$parentNodePath does not exist in the xml."
		}
	} Else { # else, if the node already exists, update its value.
        $node.InnerText = $textValue
	}
}

# Show an Open File Dialog and return the file selected by the user.
Function Read-OpenFileDialog([String]$windowTitle, [String]$initialDirectory, [String]$filter = "All files (*.*)|*.*", [Switch]$allowMultiSelect) {  
	Add-Type -AssemblyName System.Windows.Forms
	$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$openFileDialog.Title = $windowTitle
	If (!(Test-StringIsNullOrWhitespace $initialDirectory)) { $openFileDialog.InitialDirectory = $initialDirectory }
	$openFileDialog.Filter = $filter
	If ($allowMultiSelect) { $openFileDialog.MultiSelect = $true }
	$openFileDialog.ShowHelp = $true	# Without this line the ShowDialog() Function may hang depending on system configuration and running from console vs. ISE.
	$openFileDialog.ShowDialog() > $null
	If ($allowMultiSelect) { return $openFileDialog.Filenames } else { return $openFileDialog.Filename }
}

# Show message box popup and return the button clicked by the user.
Function Read-messageBoxDialog([String]$message, [String]$windowTitle, [System.Windows.Forms.MessageBoxButtons]$buttons = [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]$icon = [System.Windows.Forms.MessageBoxIcon]::None) {
	Add-Type -AssemblyName System.Windows.Forms
	return [System.Windows.Forms.MessageBox]::Show($message, $windowTitle, $buttons, $icon)
}

# Show input box popup and return the value entered by the user.
Function Read-InputBoxDialog([String]$message, [String]$windowTitle, [String]$defaultText) {
	Add-Type -AssemblyName Microsoft.VisualBasic
	return [Microsoft.VisualBasic.Interaction]::InputBox($message, $windowTitle, $defaultText)
}

Function Read-MultiLineInputBoxDialog([String]$message, [String]$windowTitle, [String]$defaultText) {
<#
    .SYNOPSIS
    Prompts the user with a multi-line input box and returns the text they enter, or null if they cancelled the prompt.
     
    .DESCRIPTION
    Prompts the user with a multi-line input box and returns the text they enter, or null if they cancelled the prompt.
     
    .PARAMETER Message
    The message to display to the user explaining what text we are asking them to enter.
     
    .PARAMETER WindowTitle
    The text to display on the prompt window's title.
     
    .PARAMETER DefaultText
    The default text to show in the input box.
     
    .EXAMPLE
    $userText = Read-MultiLineInputDialog "Input some text please:" "Get User's Input"
     
    Shows how to create a simple prompt to get mutli-line input from a user.
     
    .EXAMPLE
    # Setup the default multi-line address to fill the input box with.
    $defaultAddress = @'
    John Doe
    123 St.
    Some Town, SK, Canada
    A1B 2C3
    '@
     
    $address = Read-MultiLineInputDialog "Please enter your full address, including name, street, city, and postal code:" "Get User's Address" $defaultAddress
    If ($address -eq $null)
    {
        Write-Error "You pressed the Cancel button on the multi-line input box."
    }
     
    Prompts the user for their address and stores it in a variable, pre-filling the input box with a default multi-line address.
    If the user pressed the Cancel button an error is written to the console.
     
    .EXAMPLE
    $inputText = Read-MultiLineInputDialog -message "If you have a really long message you can break it apart`nover two lines with the powershell newline character:" -windowTitle "Window Title" -defaultText "Default text for the input box."
     
    Shows how to break the second parameter (Message) up onto two lines using the powershell newline character (`n).
    If you break the message up into more than two lines the extra lines will be hidden behind or show ontop of the TextBox.
     
    .NOTES
    Name: Show-MultiLineInputDialog
    Author: Daniel Schroeder (originally based on the code shown at http://technet.microsoft.com/en-us/library/ff730941.aspx)
    Version: 1.0
#>
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms
     
    # Create the Label.
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Size(10,10)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.AutoSize = $true
    $label.Text = $message
     
    # Create the TextBox used to capture the user's text.
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Size(10,40)
    $textBox.Size = New-Object System.Drawing.Size(575,200)
    $textBox.AcceptsReturn = $true
    $textBox.AcceptsTab = $false
    $textBox.Multiline = $true
    $textBox.ScrollBars = 'Both'
    $textBox.Text = $defaultText
     
    # Create the OK button.
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Size(415,250)
    $okButton.Size = New-Object System.Drawing.Size(75,25)
    $okButton.Text = "OK"
    $okButton.Add_Click({ $form.Tag = $textBox.Text; $form.Close() })
     
    # Create the Cancel button.
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Size(510,250)
    $cancelButton.Size = New-Object System.Drawing.Size(75,25)
    $cancelButton.Text = "Cancel"
    $cancelButton.Add_Click({ $form.Tag = $null; $form.Close() })
     
    # Create the form.
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $windowTitle
    $form.Size = New-Object System.Drawing.Size(610,320)
    $form.FormBorderStyle = 'FixedSingle'
    $form.StartPosition = "CenterScreen"
    $form.AutoSizeMode = 'GrowAndShrink'
    $form.Topmost = $True
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton
    $form.ShowInTaskbar = $true
     
    # Add all of the controls to the form.
    $form.Controls.Add($label)
    $form.Controls.Add($textBox)
    $form.Controls.Add($okButton)
    $form.Controls.Add($cancelButton)
     
    # Initialize and show the form.
    $form.Add_Shown({$form.Activate()})
    $form.ShowDialog() > $null   # Trash the text of the button that was clicked.
     
    # Return the text that the user entered.
    return $form.Tag
}

#==========================================================
# Perform the script tasks.
#==========================================================

# Display the time that this script started running.
$scriptStartTime = Get-Date
Write-Verbose "$THIS_SCRIPT_NAME script started running at $($scriptStartTime.TimeOfDay.ToString())."

# Display the version of PowerShell being used to run the script, as this can help solve some problems that are hard to reproduce on other machines.
Write-Verbose "Using PowerShell Version: $($PSVersionTable.PSVersion.ToString())."

Try {
	# If we should not show any prompts, disable them all.
	If ($NoPrompt -or $NoPromptExceptOnError) {
		If ($NoPrompt) { $NoPromptForInputOnError = $true }
		$PromptForPushPackageToNuGetGallery = $true
		$PromptForReleaseNotes = $true
		$PromptForVersionNumber = $true
	}
	
	# If a path to a NuSpec, Project, or Package file to use was not provided, look for one in the same directory as this script or prompt for one.
	If (Test-StringIsNullOrWhitespace $NuSpecFilePath) {
		# Get all of the .nuspec files in the script's directory.
		$nuSpecFiles = Get-ChildItem "$THIS_SCRIPT_DIRECTORY_PATH\*" -Include "*.nuspec" -Name
	
		# Get the number of files found.
		$numberOfNuSpecFilesFound = @($nuSpecFiles).Length
	
        # If we found zero or more than one .nuspec file, we should ask to specify what file.
		If ($numberOfNuSpecFilesFound -ne 1) {
			# If we should prompt directly from PowerShell.
			If ($UsePowerShellPrompt) {
				# Construct the prompt message with all of the supported project extensions.
				# $promptmessage should end up looking like: "Enter the path to the .nuspec or project file (.csproj, .vbproj, .fsproj) to pack, or the package file (.nupkg) to push"
				$promptMessage = "Enter the path to the .nuspec file to pack"
				$filePathToUse = Read-Host $promptMessage
				$filePathToUse = $filePathToUse.Trim('"')
			} Else { # Else use a nice GUI prompt.
				# Construct the strings to use in the OpenFileDialog filter to allow all of the supported project file types.
				# $filter should end up looking like: "NuSpec, package, and project files (*.nuspec, *.nupkg, *.csproj, *.vbproj, *.fsproj)|*.nuspec;*.nupkg;*.csproj;*.vbproj;*.fsproj"
				$filterMessage = "NuSpec files (*.nuspec)"
				$filterTypes = "*.nuspec"
				$filter = "$filterMessage|$filterTypes"
				$filePathToUse = Read-OpenFileDialog -windowTitle "Select the .nuspec file to pack..." -initialDirectory $THIS_SCRIPT_DIRECTORY_PATH -filter $filter
			}
			
			# If the user cancelled the file dialog, throw an error since we don't have a .nuspec file to use.
			If (Test-StringIsNullOrWhitespace $filePathToUse) {
				throw "No .nuspec file was specified. You must specify a valid file to use."
			}

            $NuSpecFilePath = $filePathToUse
		} Else { #If we only found one .nuspec file, use the .nuspec file
            $NuSpecFilePath = Join-Path $THIS_SCRIPT_DIRECTORY_PATH ($nuSpecFiles | Select-Object -First 1)
        }
	}
	
	# Make sure we have the absolute file paths.
    If ([System.IO.Path]::IsPathRooted($NuSpecFilePath)) {
	    $NuSpecFilePath = Resolve-Path $NuSpecFilePath
    }

    # If a path to the NuGet executable was not provided, try and find it.
    If (Test-StringIsNullOrWhitespace $NuGetExecutableFilePath) {
        # If the NuGet executable is in the same directory as this script, use it.
        $nuGetExecutablePathInThisDirectory = Join-Path $THIS_SCRIPT_DIRECTORY_PATH "NuGet.exe"
        If (Test-Path $nuGetExecutablePathInThisDirectory) {
            $NuGetExecutableFilePath = $nuGetExecutablePathInThisDirectory
        } Else { # Else we don't know where the executable is, so assume it has been added to the PATH.
            $NuGetExecutableFilePath = "NuGet.exe"
        }
    }
	
	# If we should try and update the NuGet executable.
    If ($UpdateNuGetExecutable) {
		# Create the command to use to update NuGet.exe.
	    $updateCommand = "& ""$NuGetExecutableFilePath"" update -self"

		# Have the NuGet executable try and auto-update itself.
	    Write-Verbose "About to run Update command '$updateCommand'."
	    $updateOutput = (Invoke-Expression -Command $updateCommand | Out-String).Trim()
		
		# Write the output of the above command to the Verbose stream.
		Write-Verbose $updateOutput
    }
	
	# Get and display the version of NuGet.exe that will be used. If NuGet.exe is not found an exception will be thrown automatically.
	# Create the command to use to get the Nuget Help info.
    $helpCommand = "& ""$NuGetExecutableFilePath"""

	# Get the NuGet.exe Help output.
    Write-Verbose "About to run Help command '$helpCommand'."
    $helpOutput = (Invoke-Expression -Command $helpCommand | Out-String).Trim()	
	
	# If no Help output was retrieved, the NuGet.exe likely returned an error.
	If (Test-StringIsNullOrWhitespace $helpOutput) {
		# Get the error information returned by NuGet.exe, and throw an error that we could not run NuGet.exe as expected.
		$helpError = (Invoke-Expression -Command $helpCommand 2>&1 | Out-String).Trim()	
		throw "NuGet information could not be retrieved by running '$NuGetExecutableFilePath'.`r`n`r`nRunning '$NuGetExecutableFilePath' returns the following information:`r`n`r`n$helpError"
	}
	
	# Display the version of the NuGet.exe. This information is the first line of the NuGet Help output.
	$nuGetVersionString = ($helpOutput -split "`r`n")[0]
	Write-Verbose "Using $($nuGetVersionString)."

    # Update .nuspec file based on user input.
	Update-NuSpecFile
	
	# Declare the backup directory to create the NuGet Package in, as not all code paths will set it (i.e. when pushing an existing package), but we check it later.
	$defaultDirectoryPathToPutNuGetPackageIn = $null
	
	# Save the directory that the .nuspec file is in as the directory to create the package in.
	$defaultDirectoryPathToPutNuGetPackageIn = Join-Path [System.IO.Path]::GetDirectoryName($NuSpecFilePath) $DEFAULT_DIRECTORY_TO_PUT_NUGET_PACKAGES_IN

	# If the user did not specify an Output Directory.
	If ($PackOptions -notmatch '-OutputDirectory') {
        # Insert our default Output Directory into the Additional Pack Options.
        Write-Verbose "Specifying to use the default Output Directory '$defaultDirectoryPathToPutNuGetPackageIn'."
		$PackOptions += " -OutputDirectory ""$defaultDirectoryPathToPutNuGetPackageIn"""

        # Make sure the Output Directory we are adding exists.
        If (!(Test-Path -Path $defaultDirectoryPathToPutNuGetPackageIn)) {
            New-Item -Path $defaultDirectoryPathToPutNuGetPackageIn -ItemType Directory > $null
        }
	}

    # If a Version Number was given in the script parameters but not the pack parameters, add it to the pack parameters.
	If (!(Test-StringIsNullOrWhitespace $VersionNumber) -and $PackOptions -notmatch '-Version') {
		$PackOptions += " -Version ""$VersionNumber"""
	}

    # Create the command to use to create the package.
	$packCommand = "& ""$NuGetExecutableFilePath"" pack ""$NuSpecFilePath"" $PackOptions"
	$packCommand = $packCommand -ireplace ';', '`;'		# Escape any semicolons so they are not interpreted as the start of a new command.

	# Create the package.
	Write-Verbose "About to run Pack command '$packCommand'."
	$packOutput = (Invoke-Expression -Command $packCommand | Out-String).Trim()
	
	# Write the output of the above command to the Verbose stream.
	Write-Verbose $packOutput
	
	# Get the path the NuGet Package was created to, and write it to the output stream.
	$match = $NUGET_EXE_SUCCESSFULLY_CREATED_PACKAGE_MESSAGE_REGEX.Match($packOutput)
	If ($match.Success) {
		$nuGetPackageFilePath = $match.Groups["FilePath"].Value
			
		# Have this cmdlet return the path that the new NuGet Package was created to.
		# This should be the only code that uses Write-Output, as it is the only thing that should be returned by the cmdlet.
		Write-Output $nuGetPackageFilePath
	} Else {
		throw "Could not determine where NuGet Package was created to. This typically means that an error occurred while NuGet.exe was packing it. Look for errors from NuGet.exe above (in the console window), or in the following NuGet.exe output. You can also try running this command with the -Verbose switch for more information:{0}{1}" -f [Environment]::NewLine, $packOutput
	}

    # Get the Source to push the package to.
    # If the user explicitly provided the Source to push the package to, get it.
	$regexSourceToPushPackageTo = [Regex]"(?i)((-Source|-src)\s+(?<Source>.*?)(\s+|$))"
	$match = $regexSourceToPushPackageTo.Match($PushOptions)
	If ($match.Success) {
        $sourceToPushPackageTo = $match.Groups["Source"].Value
            
        # Strip off any quotes around the address.
        $sourceToPushPackageTo = $sourceToPushPackageTo.Trim([char[]]@("'", '"'))
	} Else { # Else they did not provide an explicit source to push to.
		# So assume they are pushing to the typical default source.
        $sourceToPushPackageTo = $DEFAULT_NUGET_SOURCE_TO_PUSH_TO
	}

	# If the switch to push the package to the gallery was not provided and we are allowed to prompt, prompt the user if they want to push the package.
	If (!$PushPackageToNuGetGallery -and $PromptForPushPackageToNuGetGallery) {
		$promptMessage = "Do you want to push this package:`n'$nuGetPackageFilePath'`nto the NuGet Gallery '$sourceToPushPackageTo'?"
		
		# If we should prompt directly from PowerShell.
		If ($UsePowerShellPrompt) {
			$promptMessage += " (Yes|No)"
			$answer = Read-Host $promptMessage
		} Else { # Else use a nice GUI prompt.
			$answer = Read-messageBoxDialog -message $promptMessage -windowTitle "Push Package To Gallery?" -buttons YesNo -icon Question
		}
		
		# If the user wants to push the new package, record it.
		If (($answer -is [String] -and $answer.StartsWith("Y", [System.StringComparison]::InvariantCultureIgnoreCase)) -or $answer -eq [System.Windows.Forms.DialogResult]::Yes) {
			$PushPackageToNuGetGallery = $true
		}
	}
	
	# If we should push the Nuget package to the gallery.
	If ($PushPackageToNuGetGallery) {
        # If the user has not provided an API key.
        $userProvidedApiKeyUsingPrompt = $false
        If ($PushOptions -notmatch '-ApiKey') {
            # Get the NuGet.config file contents as Xml.
            $nuGetConfigXml = New-Object System.Xml.XmlDocument
            $nuGetConfigXml.Load($NUGET_CONFIG_FILE_PATH)

            # If the user does not have an API key saved on this PC for the Source to push to, and prompts are allowed, prompt them for one.
            If (((Get-XmlNodes -xmlDocument $nuGetConfigXml -nodePath "configuration.apikeys.add" | Where-Object { $_.key -eq $sourceToPushPackageTo }) -eq $null) -and $Prompt) {
                $promptMessage = "It appears that you do not have an API key saved on this PC for the source to push the package to '$sourceToPushPackageTo'.`n`nYou must provide an API key to push this package to the NuGet Gallery.`n`nPlease enter your API key"
		
		        # If we should prompt directly from PowerShell.
		        If ($UsePowerShellPrompt) {
			        $apiKey = Read-Host $promptMessage
		        } Else { # Else use a nice GUI prompt.
			        $apiKey = Read-InputBoxDialog -message "$promptMessage`:" -windowTitle "Enter Your API Key"
		        }
		
		        # If the user supplied an Api Key.
                If (!(Test-StringIsNullOrWhitespace $apiKey)) {
                    # Add the given Api Key to the Push Options.
                    $PushOptions += " -ApiKey $apiKey"

                    # Record that the user provided the Api Key via a prompt.
                    $userProvidedApiKeyUsingPrompt = $true
                }
            }
        }

		# Create the command to use to push the package to the gallery.
	    $pushCommand = "& ""$NuGetExecutableFilePath"" push ""$nuGetPackageFilePath"" $PushOptions"
		$pushCommand = $pushCommand -ireplace ';', '`;'		# Escape any semicolons so they are not interpreted as the start of a new command.

        # Push the package to the gallery.
		Write-Verbose "About to run Push command '$pushCommand'."
		$pushOutput = (Invoke-Expression -Command $pushCommand | Out-String).Trim()
		
		# Write the output of the above command to the Verbose stream.
		Write-Verbose $pushOutput

		# If an error occurred while pushing the package, throw and error. Else it was pushed successfully.
		If (!$pushOutput.EndsWith($NUGET_EXE_SUCCESSFULLY_PUSHED_PACKAGE_MESSAGE.Trim())) {
            throw "Could not determine if package was pushed to gallery successfully. Perhaps an error occurred while pushing it. Look for errors from NuGet.exe above (in the console window), or in the following NuGet.exe output. You can also try running this command with the -Verbose switch for more information:{0}{1}" -f [Environment]::NewLine, $pushOutput
        }

        # If the package should be deleted.
        If ($DeletePackageAfterPush -and (Test-Path $nuGetPackageFilePath)) {
            # Delete the package.
            Write-Verbose "Deleting NuGet Package '$nuGetPackageFilePath'."
            Remove-Item -Path $nuGetPackageFilePath -Force

            # If the package was output to the default directory, and the directory is now empty, delete the default directory too since we would have created it above.
            If (!(Test-StringIsNullOrWhitespace $defaultDirectoryPathToPutNuGetPackageIn) -and (Test-Path -Path $defaultDirectoryPathToPutNuGetPackageIn)) {
                [int]$numberOfFilesInDefaultOutputDirectory = ((Get-ChildItem -Path $defaultDirectoryPathToPutNuGetPackageIn -Force) | Measure-Object).Count
                If ((Split-Path -Path $nuGetPackageFilePath -Parent) -eq $defaultDirectoryPathToPutNuGetPackageIn -and $numberOfFilesInDefaultOutputDirectory -eq 0) {
                    Write-Verbose "Deleting empty default NuGet package directory '$defaultDirectoryPathToPutNuGetPackageIn'."
                    Remove-Item -Path $defaultDirectoryPathToPutNuGetPackageIn -Force
                }
            }
        }

        # If the user provided the Api Key via a prompt from this script, prompt them for if they want to save the given API key on this PC.
        If ($userProvidedApiKeyUsingPrompt) {
	        # If we are allowed prompt the user, ask if they want to save the given API key on this PC.
            If ($Prompt) {
                $promptMessage = "Do you want to save the API key you provided on this PC so that you don't have to enter it again next time?"
			
				# If we should prompt directly from PowerShell.
				If ($UsePowerShellPrompt) {
					$promptMessage += " (Yes|No)"
					$answer = Read-Host $promptMessage
				} Else { # Else use a nice GUI prompt.
					$answer = Read-messageBoxDialog -message $promptMessage -windowTitle "Save API Key On This PC?" -buttons YesNo -icon Question
				}
            } Else { # If not, just assume they don't want to save the key on this PC.
                $answer = "No"
            }
			
			# If the user wants to save the API key.
			If (($answer -is [String] -and $answer.StartsWith("Y", [System.StringComparison]::InvariantCultureIgnoreCase)) -or $answer -eq [System.Windows.Forms.DialogResult]::Yes) {
				# Create the command to use to save the Api key on this PC.
	            $setApiKeyCommand = "& ""$NuGetExecutableFilePath"" setApiKey ""$apiKey"" -Source ""$sourceToPushPackageTo"""
				$setApiKeyCommand = $setApiKeyCommand -ireplace ';', '`;'		# Escape any semicolons so they are not interpreted as the start of a new command.

				# Save the Api key on this PC.
	            Write-Verbose "About to run command '$setApiKeyCommand'."
	            $setApiKeyOutput = (Invoke-Expression -Command $setApiKeyCommand | Out-String).Trim()
				
				# Write the output of the above command to the Verbose stream.
				Write-Verbose $setApiKeyOutput
				
				# Determine if the API Key was saved successfully, and throw an error if it wasn't.
                $expectedSuccessfulNuGetSetApiKeyOutput = ($NUGET_EXE_SUCCESSFULLY_SAVED_API_KEY_MESSAGE -f $apiKey, $sourceToPushPackageTo)	# "The API Key '$apiKey' was saved for '$sourceToPushPackageTo'."
                If ($setApiKeyOutput -ne $expectedSuccessfulNuGetSetApiKeyOutput.Trim()) {
                    throw "Could not determine if the API key was saved successfully. Perhaps an error occurred while saving it. Look for errors from NuGet.exe above (in the console window), or in the following NuGet.exe output. You can also try running this command with the -Verbose switch for more information:{0}{1}" -f [Environment]::NewLine, $packOutput
                }
			}
        }
	}
} Finally { Write-Verbose "Performing any required $THIS_SCRIPT_NAME script cleanup..." }

# Display the time that this script finished running, and how long it took to run.
$scriptFinishTime = Get-Date
$scriptElapsedTimeInSeconds = ($scriptFinishTime - $scriptStartTime).TotalSeconds.ToString()
Write-Verbose "$THIS_SCRIPT_NAME script finished running at $($scriptFinishTime.TimeOfDay.ToString()). Completed in $scriptElapsedTimeInSeconds seconds."