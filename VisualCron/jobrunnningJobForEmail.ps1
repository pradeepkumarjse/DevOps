# Configuration
$baseUrl = "https://localhost:8002/VisualCron/json"
$username = ""
$password = ""
$runtimeThreshold = 300 # 5 minutes in seconds

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
        
        # Check if the job has been running for more than runtimeThreshold
        if ($timeRunning -gt $runtimeThreshold) {            
            Write-Output "========================================"
            Write-Output "          Job Execution Details         "
            Write-Output "========================================"
            Write-Output "Job Name        : $($job.Name)"
            Write-Output "Time Running    : $timeRunning seconds"
            Write-Output "Threshold       : $runtimeThreshold seconds"
            Write-Output "Last Execution  : $dateLastExecution"
            Write-Output "========================================"
            Write-Output ""
            Write-Output ""            
       } 
        
    }
}

# Main Script Execution
try {
    # Step 1: Get authentication token    
    $token = Get-VisualCronToken -baseUrl $baseUrl -username $username -password $password     
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
