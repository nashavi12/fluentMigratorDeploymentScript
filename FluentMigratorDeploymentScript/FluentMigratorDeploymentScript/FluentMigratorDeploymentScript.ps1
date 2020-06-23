<#
    Description: Use FluentMigrator to deploy the DB changes using the release pipeline.
#>

param(
    [string] $ReviewDbConnectionString
)

$defaultErrorExitCode = -1
$executingDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "[INFORMATION]: Executing from '$executingDirectory'"

try
{
    Write-Host "[INFORMATION]: Starting deploying the SQL scripts at $($(Get-Date).ToUniversalTime()) UTC.";

    if (-not $ReviewDbConnectionString) 
    {
    	$ReviewDbConnectionString = $env:reviewDbConnectionString
    }
    
    if (-not $ReviewDbConnectionString) 
    {
      Write-Error "[ERROR]: No valid connection string for review DB is provided in the input param and none was specified using environment variables."
      exit $defaultErrorExitCode
    }

    $command = "dotnet"
    $migrationAssemblyPath = "$executingDirectory/migrator/Microsoft.CM.ReviewDB.Migrator.dll"
    
    if (Test-Path $migrationAssemblyPath -PathType Leaf)
    {
      Write-Host "[INFORMATION]: Migration runner exists at '$migrationAssemblyPath', ready to execute migration."
    }
    else
    {
      Write-Error "[ERROR]: Migration runner does not exist at '$migrationAssemblyPath'."
      exit $defaultErrorExitCode
    }

    Write-Host "[INFORMATION]: Running command '$command' with assembly '$migrationAssemblyPath'"
    & "$command" "$migrationAssemblyPath" "--connectionString" $ReviewDbConnectionString
    
    if ($?)
    {
        Write-Host "[INFORMATION]: Completed migration of SQL database at $((Get-Date).ToUniversalTime()) UTC."
    }
    else
    {
        Write-Error "[ERROR]: Migration failed. Check preceding output for details."
        exit $defaultErrorExitCode
    }
}
catch
{
    Write-Error $_.Exception.Message
    Write-Output $_.Exception | Format-List -Force
    exit $defaultErrorExitCode
}