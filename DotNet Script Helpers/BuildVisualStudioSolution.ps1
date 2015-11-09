#Requires -Version 2.0
<#
    .SYNOPSIS
    Executes the VS2015\MSBuild.exe tool against the specified Visual Studio
    solution file.

    .Description

    .PARAMETER BaseDirectory
    The source code root directory. $SolutionFile can be relative to this
    directory.

    .PARAMETER SolutionFile
    The relative path and filename of the Visual Studio solution file.

    .PARAMETER CleanFirst
    If set, this switch will cause the function to first run MsBuild as a
    "clean" operation, before executing the build.

    .PARAMETER Configuration
    The project configuration to build within the solution file. Default is
    "Debug".

    .PARAMETER LangVersion
    Defines the version of the language that your project is build to run on.

    .PARAMETER PlatformTarget
    Defines the particular platform that your project is built to run on.

    .PARAMETER TargetFrameworkVersion
    Defines the particular version of the .NET Framework that your project is built
    to run on.

    .PARAMETER ToolsVersion
    Defines the tool set used to build your project.

    .PARAMETER MSBuildPath
    The path to the MSBuild assembly.
        
    .EXAMPLE
    & .\BuildVisualStudioSolution.ps1
        -SolutionFile MySolution.sln

    Simply builds the solution using the default parameters.

    .NOTES
    Name:   BuildVisualStudioSolution
    Author: Marco Antonio Orestes Teixeira
#>

Param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String] $BaseDirectory = ".",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()] 
    [String] $SolutionFile,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [Switch] $CleanFirst,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String] $Configuration = "Debug",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String] $LangVersion = "6",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String] $PlatformTarget = "x86",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String] $TargetFrameworkVersion = "v4.6",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String] $ToolsVersion = "14.0",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String] $MSBuildPath = "${env:ProgramFiles(x86)}\MSBuild\14.0\Bin\MSBuild.exe"
)

Process {
    # Local Variables
    $solutionFilePath = "$BaseDirectory\$SolutionFile";

    Try {
        # Clear first?
        If ($CleanFirst) {
            # Start clean process
            & $MSBuildPath $solutionFilePath /t:clean /p:Configuration=$Configuration /v:normal
        }

        # Start the build
        & $MSBuildPath $solutionFilePath /t:rebuild /p:Configuration=$Configuration /p:PlatformTarget=$PlatformTarget /p:toolsVersion=$ToolsVersion /p:TargetFrameworkVersion=$TargetFrameworkVersion /p:LangVersion=$LangVersion /v:normal
    } Catch {
        Write-Error ("Unexpect error occured while building $SolutionFile : $_.Message");
    }
}