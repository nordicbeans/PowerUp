powershell -inputformat none -command "$execPolicy = Get-ExecutionPolicy; if (!($execPolicy -eq 'Unrestricted')) { Set-ExecutionPolicy Unrestricted }"
powershell -inputformat none -command ".\_powerup\set_powershell_version.ps1";exit $LastExitCode
