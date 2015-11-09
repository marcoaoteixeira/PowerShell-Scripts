# ChangeAssemblyInfoVersion.ps1
#
# Set the version in all the AssemblyInfo.cs or AssemblyInfo.vb files in any subdirectory.
#
# Usage:  
#  From command prompt: 
#     powershell.exe ChangeAssemblyInfoVersion.ps1 2.8.3.0
# 
#  From PowerShell prompt: 
#     .\ChangeAssemblyInfoVersion.ps1 2.8.3.0

Function Show-Usage {
    $usage = @'
Usage:
From Command prompt:
    powershell.exe ChangeAssemblyInfoVersion.ps1 2.8.3.0

From PowerShell prompt:
    .\ChangeAssemblyInfoVersion.ps1 2.8.3.0
'@
    Write-Host $usage
}

Function Update-SourceVersion {
    Param ([string]$Version)
    $newVersion = 'AssemblyVersion("' + $Version + '")';
    $newFileVersion = 'AssemblyFileVersion("' + $Version + '")';

    ForEach ($file In $input) {
        Write-Output $file.FullName
        $tmpFile = $file.FullName + ".tmp"

        Get-Content $file.FullName |
            %{$_ -replace 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', $newVersion } |
            %{$_ -replace 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', $newFileVersion } > $tmpFile

        Move-Item $tmpFile $file.FullName -Force
    }
}

Function Update-AllAssemblyInfoFiles ($version) {
    ForEach ($file In "AssemblyInfo.cs", "AssemblyInfo.vb") {
        Get-ChildItem -Recurse |? {$_.Name -eq $file} | Update-SourceVersion $version ;
    }
}

# validate arguments 
$regex = [System.Text.RegularExpressions.Regex]::Match($args[0], "^[0-9]+(\.[0-9]+){1,3}$");

If (-not $regex.Success) {
    Show-Usage;
    Exit;
}

Update-AllAssemblyInfoFiles $args[0];