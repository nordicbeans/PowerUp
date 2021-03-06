<#
	This file is incomplete as it was used to test the invalidation on CloudFront.
	It is left here in case there is a future need to continue development of this module.
#>

function Register-Environment()
{
    Write-Message "Registering environment"
    
    Add-Type -Path "AWSSDK.dll"
    [IO.Directory]::SetCurrentDirectory((Convert-Path (Get-Location -PSProvider FileSystem)))
    $env:AWS_ACCESS_KEY_ID = "AKIAJ6PTGNKYH4WJMSWQ"
    $env:AWS_SECRET_ACCESS_KEY = "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"
    $env:DISTRIBUTION_ID = "E1KR89VU1GFQA5"
    $env:POLLING_INTERVAL = 60000
    
    Write-Message "Registering environment complete"   
}

function Get-File([string]$bucket, [string]$key, [string]$destination)
{
    Write-Message "Downloading /$bucket/$key to $destination"

    $client=[Amazon.AWSClientFactory]::CreateAmazonS3Client($env:AWS_ACCESS_KEY_ID, $env:AWS_SECRET_ACCESS_KEY)

    $request = New-Object -TypeName Amazon.S3.Model.GetObjectRequest
    $request.BucketName = $bucket
    $request.Key = $key
    $response = $client.GetObject($request)

    $writer = new-object System.IO.FileStream ($destination ,[system.IO.filemode]::Create)
    [byte[]]$buffer = new-object byte[] 4096
    [int]$total = [int]$count = 0
    do
    {
        $count = $response.ResponseStream.Read($buffer, 0, $buffer.Length)    
        $writer.Write($buffer, 0, $count)
        $total += $count
    }
   while ($count -gt 0)

    $response.ResponseStream.Close()
    $writer.Close() 

    Write-Message "Downloading /$bucket/$key to $destination ($total bytes) complete"
}

function Reset-CloudFront($files, $invalidationReferenceId)
{
    Write-Message "Invalidating $($files.Count) with reference id $invalidationReferenceId"

    $client=[Amazon.AWSClientFactory]::CreateAmazonCloudFrontClient($env:AWS_ACCESS_KEY_ID, $env:AWS_SECRET_ACCESS_KEY)

    $request = New-Object -TypeName Amazon.CloudFront.Model.PostInvalidationRequest
    $batch = New-Object -TypeName Amazon.CloudFront.Model.InvalidationBatch

    $batch.Paths = $files;
    $batch.CallerReference = $invalidationReferenceId

    $request.InvalidationBatch = $batch;
    $request.DistributionId = $env:DISTRIBUTION_ID;

    $response = $client.PostInvalidation($request);
    if (![System.String]::IsNullOrEmpty($response.RequestId))
    {
    	$bInProgress = 1;
    	while ($bInProgress)
    	{
    	    $getReq = New-Object -TypeName Amazon.CloudFront.Model.GetInvalidationRequest
    	    $getReq.DistributionId = $env:DISTRIBUTION_ID
    	    $getReq.InvalidationId = $response.Id

    	    $getRes = $client.GetInvalidation($getReq);
    	    $bInProgress = $getRes.Status.Equals("InProgress");

            Write-Message "In progress $(get-date -f HHmmss)"
            
    	    if ($bInProgress)
    	    {
    		  [System.Threading.Thread]::Sleep($env:POLLING_INTERVAL);
    	    }
    	}
    }
    else
    {
	   return 0;
    }

    return 1;
}

function Write-Message($message)
{
    Write-Host "AWS: $message"
}

$list = New-Object -TypeName System.Collections.Generic.List[string]
$list.Add("/testfolder/test_text1.txt")
$list.Add("/testfolder/test_text2.txt")


Register-Environment
#Get-File "milk-dev" "crossdomain.xml" "test.txt"
Reset-CloudFront $list "test$(get-date -f yyyyMMddHHmmss)"