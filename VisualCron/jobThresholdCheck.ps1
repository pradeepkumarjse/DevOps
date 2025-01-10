# Configuration
$baseUrl = "https://localhost:8002/VisualCron/json"
$username = "pradeep"
$password = "pradeep"
$runtimeThreshold = 300 # 5 minutes in seconds
$smtpPassword=""
$smtpUser=""
$smtpPort=587
$smtpCC = @(
    "@gmail.com",
    "@gmail.com"
  
)
$smtpFrom=""
$smtpTo=""

# Enable TLS 1.1 if needed
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls11

# Function to log in and retrieve a token
function Get-VisualCronToken {
    param (
        [string]$baseUrl,
        [string]$username,
        [string]$password
    )
    $loginUrl = "$baseUrl/logon?username=$username&password=$password&expire=1000"
   

    try {
        $response = Invoke-RestMethod -Uri $loginUrl -Method GET -UseBasicParsing
       
        if ($response -and $response.Result -and $response.Token) {
            return $response.Token
        } else {
            
            return $null
        }
    } catch {
        
        return $null
    }
}

# Function to get the list of running jobs
function Get-RunningJobs {
    param (
        [string]$baseUrl,
        [string]$token
    )
    $jobListUrl = "$baseUrl/Job/List?token=$token"  

    try {
        $response = Invoke-RestMethod -Uri $jobListUrl -Method GET -UseBasicParsing 
        $runningJobs = $response | Where-Object { $_.Stats.Status -eq 0 }        
        return $runningJobs        
    } catch {
        Write-Error "Failed to retrieve job list. Error: $_"
        return @() # Return an empty array on failure
    }
}


# Function to process running jobs and check for long-running tasks
function Monitor-Jobs {
    param (
        [array]$runningJobs,
        [int]$runtimeThreshold
    )

  foreach ($job in $runningJobs) {
        $jobName = $job.Name
          # Skip the current job
           if ("{JOB(Active|Name)}" -eq $jobName) {
                   continue
             }
        
        $dateLastExecution = [datetime]::Parse($job.Stats.DateLastExecution)
        $currentTime = Get-Date

        # Calculate how long the job has been running
        $timeRunning = ($currentTime - $dateLastExecution).TotalSeconds

        
        $subject = "Job Alert: '$($job.Name)' Exceeded Maximum Runtime Threshold"
        $body ="
                Dear Team,

                This is an automated alert regarding the job '$($job.Name)', which has exceeded the maximum allowed runtime.

                Job Name: $($job.Name)
                Time Running: $timeRunning seconds
                Threshold: $runtimeThreshold seconds
                Last Execution: $dateLastExecution

                Please investigate the status of this job to ensure it is functioning correctly. If this is an expected behavior, no action is needed.

                Kind Regards,
                "
        
        
        $securePassword = ConvertTo-SecureString $smtpPassword -AsPlainText -Force
        $credential = New-Object PSCredential($smtpUser, $securePassword)
        
        # Check if the job has been running for more than runtimeThreshold
        if ($timeRunning -gt $runtimeThreshold) {
            Write-Output "Job '$jobName' has been running for more than $runtimeThreshold seconds."  
            
            Send-MailMessage -SmtpServer smtp.gmail.com -Port $smtpPort -UseSsl -Credential $credential -From $smtpFrom -To $smtpTo -Cc $smtpCC ` -Subject $subject -Body $body
                      
            
        } 
        
    }
}

# Main Script Execution
try {
    # Step 1: Get authentication token
    
    $token = Get-VisualCronToken -baseUrl $baseUrl -username $username -password $password
    
    Write-Output "$token"
    
    if (-not $token) {
        Write-Error "Token retrieval failed. Exiting script."
        exit
    }

    # Step 2: Get the list of running jobs
    $runningJobs = Get-RunningJobs -baseUrl $baseUrl -token $token

    if ($runningJobs.Count -eq 0) {
        Write-Output "No running jobs found."
        exit
    }
   
    # Step 3: Monitor running jobs
    Monitor-Jobs -runningJobs $runningJobs -runtimeThreshold $runtimeThreshold

} catch {
    Write-Error "An unexpected error occurred: $_"
}
