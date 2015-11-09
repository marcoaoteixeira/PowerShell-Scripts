Param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]$SolutionFilePath = "",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]$NuGetFilePath = ".\Tools\NuGet\NuGet.exe",
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String[]]$Sources = { https://api.nuget.org/v3/index.json },
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [Switch]$NoCache = $true,
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]$ConfigFilePath = "$env:APPDATA\NuGet\nuget.config",
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [Switch]$RequireConsent = $false,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]$PackagesDirectory = ".\packages"
)

Process {
    # Install or restore packages
    If (-not (Test-Path $NuGetFilePath)) {
        Write-Error "NuGet.exe not found."
        Exit
    }

    $noCacheParameter = ""
    If ($NoCache) {
        $noCacheParameter = "-NoCache"
    }

    $requireConsentParameter = ""
    If ($RequireConsent) {
        $requireConsentParameter = "-RequireConsent"
    }

    & $NuGetFilePath Restore $SolutionFilePath -Source $Sources $noCacheParameter -ConfigFile $ConfigFilePath $requireConsentParameter -PackagesDirectory $PackagesDirectory
}