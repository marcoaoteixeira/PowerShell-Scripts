#Requires -Version 2.0
<#
	.SYNOPSIS
	Updates the version tag of the specified .nuspec file with the assembly
    version of the specifed assembly file.
	
	.DESCRIPTION
	Updates the version tag of the specified .nuspec file with the assembly
    version of the specifed assembly file.

	.PARAMETER NuSpecFilePath
	The file path to the .nuspec file.

    .PARAMETER AssemblyFilePath
	The assembly file path.

	.EXAMPLE
	& .\UpdateNuSpecVersionTag.ps1 -NuSpecFilePath [NUSPEC_FILE_PATH]
        -AssemblyFilePath [ASSEMBLY_FILE_PATH]

	This will update only the .nuspec version tag with the assembly version
    number.
	
	.LINK
	Project home: https://github.com/marcoaoteixeira/PowerShell-Scripts/tree/master/UpdateNuSpecVersionTag.ps1

	.NOTES
	Author: Marco Antonio Orestes Teixeira
	Version: 1.0
	
	This script is designed to be called from PowerShell.
#>
[CmdletBinding()]
Param (
    [Parameter(Position = 0, Mandatory = $true, HelpMessage = "The .nuspec file path.")]
    [ValidateScript({ Test-Path $_ -PathType Leaf -Include "*.nuspec" })]
    [Alias("NuSpec")]
    [String]$NuSpecFilePath = $null,

    [Parameter(Position = 1, Mandatory = $true, HelpMessage = "The assembly file path.")]
    [ValidateScript({ Test-Path $_ -PathType Leaf -Include ("*.exe", "*.dll") })]
    [Alias("Assembly")]
    [String]$AssemblyFilePath = $null,

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

Function Get-XmlNamespaceManager([Xml]$xmlDocument, [String]$namespaceURI = "") {
    # If a Namespace URI was not given, use the Xml document's default namespace.
	If (Test-StringIsNullOrWhitespace $namespaceURI) { $namespaceURI = $xmlDocument.DocumentElement.NamespaceURI }
	
	# In order for SelectSingleNode() to actually work, we need to use the fully qualified node path along with an Xml Namespace Manager, so set them up.
	[System.Xml.XmlNamespaceManager]$xmlNsManager = New-Object System.Xml.XmlNamespaceManager($xmlDocument.NameTable)
	$xmlNsManager.AddNamespace("ns", $namespaceURI)
    Return ,$xmlNsManager		# Need to put the comma before the variable name so that PowerShell doesn't convert it into an Object[].
}

Function Get-FullyQualifiedXmlNodePath([String]$nodePath, [String]$nodeSeparatorCharacter = ".") {
    Return "/ns:$($nodePath.Replace($($nodeSeparatorCharacter), "/ns:"))"
}

Function Get-XmlNode([Xml]$xmlDocument, [String]$nodePath, [String]$namespaceURI = "", [String]$nodeSeparatorCharacter = ".") {
	$xmlNsManager = Get-XmlNamespaceManager -xmlDocument $xmlDocument -namespaceURI $namespaceURI
	[String]$fullyQualifiedNodePath = Get-FullyQualifiedXmlNodePath -nodePath $nodePath -nodeSeparatorCharacter $nodeSeparatorCharacter
	
	# Try and get the node, then Return it. Returns $null if the node was not found.
	$node = $xmlDocument.SelectSingleNode($fullyQualifiedNodePath, $xmlNsManager)
	Return $node
}

Function Set-XmlElementTextValue([Xml]$xmlDocument, [String]$elementPath, [String]$textValue, [String]$namespaceURI = "", [String]$nodeSeparatorCharacter = '.') {
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

Function Set-NuSpecVersionNumber([String] $nuSpecFilePath, [String] $newVersionNumber) {	
	# Read in the file contents, update the version element's value, and save the file.
	$fileContents = New-Object System.Xml.XmlDocument
    $fileContents.Load($nuSpecFilePath)
	Set-XmlElementTextValue -xmlDocument $fileContents -elementPath "package.metadata.version" -textValue $newVersionNumber
	$fileContents.Save($nuSpecFilePath)
}

Function Read-AssemblyVersionNumber([String] $assemblyFilePath) {
    Return ,(Get-ChildItem -File $assemblyFilePath | Select-Object -ExpandProperty VersionInfo | Select-Object -Property ProductVersion).ProductVersion
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
    $productVersion = Read-AssemblyVersionNumber -assemblyFilePath $AssemblyFilePath
    Write-Verbose "Assembly product version is: $productVersion"
    Set-NuSpecVersionNumber -nuSpecFilePath $NuSpecFilePath -newVersionNumber $productVersion
} Finally {
    Write-Verbose "Performing any required $($THIS_SCRIPT_NAME) script cleanup..."
}

# Display the time that this script finished running, and how long it took to run.
$scriptFinishTime = Get-Date
$scriptElapsedTimeInSeconds = ($scriptFinishTime - $scriptStartTime).TotalSeconds.ToString()
Write-Verbose "$($THIS_SCRIPT_NAME) script finished running at $($scriptFinishTime.TimeOfDay.ToString()). Completed in $scriptElapsedTimeInSeconds seconds."