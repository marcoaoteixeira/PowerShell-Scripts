Param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$NUnitTestRunnerFilePath = ".\Tools\NUnit\nunit-console.exe",

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$TestAssembliesDirectory = ".\build\test",

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$TestAssemblyFileNamePattern = "*UnitTest.dll",

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$TargetFramework = "net-4.0"
)

Process {
    # Find tests in output directory
    $testAssemblies = (Get-ChildItem $TestAssembliesDirectory -Recurse -Include $TestAssemblyFileNamePattern)

    # Run tests
    & $NUnitTestRunnerFilePath /noshadow /framework:"$TargetFramework" /xml:"$TestAssembliesDirectory\nunit.tests.report.xml" $testAssemblies
}