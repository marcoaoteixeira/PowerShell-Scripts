# ChangeNuSpecVersion.ps1
#
# Set the version in all the AssemblyInfo.cs or AssemblyInfo.vb files in any subdirectory.
#
# Usage:  
#  From command prompt: 
#     powershell.exe ChangeNuSpecVersion.ps1 2.8.3.0
# 
#  From PowerShell prompt: 
#     .\ChangeNuSpecVersion.ps1 2.8.3.0

Function Show-Usage {
    $usage = @'
Usage:
From Command prompt:
    powershell.exe ChangeNuSpecVersion.ps1 2.8.3.0

From PowerShell prompt:
    .\ChangeNuSpecVersion.ps1 2.8.3.0
'@
    Write-Host $usage
}

Function Update-SourceVersion {
    Param ([string]$Version)
    $newVersion = "<version>$Version</version>";

    ForEach ($file In $input) {
        Write-Output $file.FullName
        $tmpFile = $file.FullName + ".tmp"

        Get-Content $file.FullName |
            %{$_ -replace '<version>.*</version>', $newVersion } > $tmpFile

        Move-Item $tmpFile $file.FullName -Force
    }
}

Function Update-AllNuSpecFiles ($version) {
    Get-ChildItem -Recurse -Filter "*.nuspec" |? {$_.Name.EndsWith($file)} | Update-SourceVersion $version ;
}

# validate arguments 
$regex = [System.Text.RegularExpressions.Regex]::Match($args[0], "^[0-9]+(\.[0-9]+){1,3}$");

If (-not $regex.Success) {
    Show-Usage;
    Exit;
}

Update-AllNuSpecFiles $args[0];