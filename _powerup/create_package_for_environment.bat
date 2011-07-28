whoami

if not '%1'=='' goto RUN

:NOENVIRONMENT
	echo Deployment environment parameter is required
	echo e.g. deploy_remotely production	
	exit /B

:RUN
	xcopy /i /s /e . %CD%_%1
	cd %CD%_%1
	
	powershell -inputformat none -command "Set-ExecutionPolicy Unrestricted"
	powershell -inputformat none -command ".\_powerup\deploy_with_psake.ps1 -deploymentEnvironment %1 -onlyFinalisePackage 1";exit $LastExitCode