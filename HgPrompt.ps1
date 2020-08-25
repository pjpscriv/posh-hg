# For backwards compatibility
$global:HgPromptSettings = $global:PoshHgSettings

# State Variables
$global:HgState = $null;
$global:IsLoading = $true;
$global:LastId = 0;
$global:Branch = "loading";

function Write-Prompt($Object, $ForegroundColor, $BackgroundColor = -1) {
    if ($BackgroundColor -lt 0) {
        Write-Host $Object -NoNewLine -ForegroundColor $ForegroundColor
    } else {
        Write-Host $Object -NoNewLine -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
    }
}

function Write-HgStatus($status = (get-hgStatus $global:PoshHgSettings.GetFileStatus $global:PoshHgSettings.GetBookmarkStatus)) {
    if ($status) {
        $s = $global:PoshHgSettings
       
        $branchFg = $s.BranchForegroundColor
        $branchBg = $s.BranchBackgroundColor
        
        if($status.Behind) {
          $branchFg = $s.Branch2ForegroundColor
          $branchBg = $s.Branch2BackgroundColor
        }

        if ($status.MultipleHeads) {
          $branchFg = $s.Branch3ForegroundColor
          $branchBg = $s.Branch3BackgroundColor
        }
       
        Write-Prompt $s.BeforeText -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor
        Write-Prompt $status.Branch -BackgroundColor $branchBg -ForegroundColor $branchFg
        
        if($status.Added) {
          Write-Prompt "$($s.AddedStatusPrefix)$($status.Added)" -BackgroundColor $s.AddedBackgroundColor -ForegroundColor $s.AddedForegroundColor
        }
        if($status.Modified) {
          Write-Prompt "$($s.ModifiedStatusPrefix)$($status.Modified)" -BackgroundColor $s.ModifiedBackgroundColor -ForegroundColor $s.ModifiedForegroundColor
        }
        if($status.Deleted) {
          Write-Prompt "$($s.DeletedStatusPrefix)$($status.Deleted)" -BackgroundColor $s.DeletedBackgroundColor -ForegroundColor $s.DeletedForegroundColor
        }
        
        if ($status.Untracked) {
          Write-Prompt "$($s.UntrackedStatusPrefix)$($status.Untracked)" -BackgroundColor $s.UntrackedBackgroundColor -ForegroundColor $s.UntrackedForegroundColor
        }
        
        if($status.Missing) {
           Write-Prompt "$($s.MissingStatusPrefix)$($status.Missing)" -BackgroundColor $s.MissingBackgroundColor -ForegroundColor $s.MissingForegroundColor
        }

        if($status.Renamed) {
           Write-Prompt "$($s.RenamedStatusPrefix)$($status.Renamed)" -BackgroundColor $s.RenamedBackgroundColor -ForegroundColor $s.RenamedForegroundColor
        }

        if($s.ShowTags -and ($status.Tags.Length -or $status.ActiveBookmark.Length)) {
          write-host $s.BeforeTagText -NoNewLine
            
          if($status.ActiveBookmark.Length) {
              Write-Prompt $status.ActiveBookmark -ForegroundColor $s.BranchForegroundColor -BackgroundColor $s.TagBackgroundColor 
              if($status.Tags.Length) {
                Write-Prompt " " -ForegroundColor $s.TagSeparatorColor -BackgroundColor $s.TagBackgroundColor
              }
          }
         
          $tagCounter=0
          $status.Tags | % {
            $color = $s.TagForegroundColor
                
              Write-Prompt $_ -ForegroundColor $color -BackgroundColor $s.TagBackgroundColor 
          
              if($tagCounter -lt ($status.Tags.Length -1)) {
                Write-Prompt ", " -ForegroundColor $s.TagSeparatorColor -BackgroundColor $s.TagBackgroundColor
              }
              $tagCounter++;
          }        
        }
        
        if($s.ShowPatches) {
          $patches = Get-MqPatches
          if($patches.All.Length) {
            write-host $s.BeforePatchText -NoNewLine
  
            $patchCounter = 0
            
            $patches.Applied | % {
              Write-Prompt $_ -ForegroundColor $s.AppliedPatchForegroundColor -BackgroundColor $s.AppliedPatchBackgroundColor
              if($patchCounter -lt ($patches.All.Length -1)) {
                Write-Prompt $s.PatchSeparator -ForegroundColor $s.PatchSeparatorColor
              }
              $patchCounter++;
            }
            
            $patches.Unapplied | % {
               Write-Prompt $_ -ForegroundColor $s.UnappliedPatchForegroundColor -BackgroundColor $s.UnappliedPatchBackgroundColor
               if($patchCounter -lt ($patches.All.Length -1)) {
                  Write-Prompt $s.PatchSeparator -ForegroundColor $s.PatchSeparatorColor
               }
               $patchCounter++;
            }
          }
        }

        if($s.ShowRevision -and $status.Revision) {
           Write-Prompt " <" -BackgroundColor $s.TagBackgroundColor -ForegroundColor $s.TagForegroundColor
           Write-Prompt $status.Revision -BackgroundColor $s.TagBackgroundColor -ForegroundColor $s.TagForegroundColor
           Write-Prompt ">" -BackgroundColor $s.TagBackgroundColor -ForegroundColor $s.TagForegroundColor
        }

        
       Write-Prompt $s.AfterText -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor
    }
}

# Function in same file to speed up check
function isHgDirectoryCheck() {
  if(test-path ".git") {
    return $false; #short circuit if git repo
  }
  if(test-path ".hg") {
    return $true;
  }
}

function stateUpdated() {
  $command = Get-History | Select-Object -last 1
  if ($command."Id" -eq $global:LastId) {
    return $false # No new command
  }
  $global:LastId = $command."Id"

  # Update hg status if these commands are made
  if ($command."CommandLine" -like "hg*") {
    return $true
  } elseif ($command."CommandLine" -like "yarn*") {
    return $true
  } elseif ($command."CommandLine" -like "npm*") {
    return $true
  } elseif ($command."CommandLine" -like "node*") {
    return $true
  } elseif ($command."CommandLine" -like "cd*") {
    return $true
  } else {
    return $false
  }
}

function Write-HgLoading($branch) {
  $loadingFg = [ConsoleColor]::Gray
  $loadingBg = $Host.UI.RawUI.BackgroundColor
  $s = $global:PoshHgSettings
  Write-Prompt $s.BeforeText -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor
  Write-Prompt $branch -BackgroundColor $loadingBg -ForegroundColor $loadingFg
  Write-Prompt $s.AfterText -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor
}

function Get-HgStatus-Async() {
  $global:IsLoading = $true
  $global:Branch = hg branch

  # Get hg status in the background
  $job = Start-Job { 
    Set-Location $using:PWD;
    Get-HgStatus $global:PoshHgSettings.GetFileStatus $global:PoshHgSettings.GetBookmarkStatus
  }

  # When hg status returned
  $jobEvent = Register-ObjectEvent $job StateChanged -Action { 
    if($sender.State -eq 'Completed') {
        $result = Receive-Job -Name $sender.Name
        # Write-Host $result.PSBase.Keys # Debug
        $global:HgState = $result
        $global:IsLoading = $false

        # Write Loaded
        # FIX: Gets overwritten too easily
        $loadedFg = [ConsoleColor]::White
        $path = Get-Location
        $pathLength = ('' + $path).Length
        $cursorPos = $host.UI.RawUI.CursorPosition
        $tempCursorPos = $cursorPos
        $tempCursorPos.X = $pathLength + 2;
        $host.UI.RawUI.CursorPosition = $tempCursorPos
        Write-Host $global:Branch -NoNewLine -ForegroundColor $loadedFg
        $host.UI.RawUI.CursorPosition = $cursorPos
      } 
    $jobEvent | Unregister-Event
  }
}

# TODO: Automatically update every minute?
function Write-HgStatus-Async() {
  if (isHgDirectoryCheck) {
    if($global:IsLoading) {
      if ($global:LastId -eq 0) {
        $command = Get-History | Select-Object -last 1
        $global:LastId = $command."Id"
        Get-HgStatus-Async
      }
      Write-HgLoading $global:Branch
    } else {
      if (stateUpdated) {
        Get-Job | Stop-Job
        Get-HgStatus-Async
        Write-HgLoading $global:Branch
      } else {
        Write-HgStatus $global:HgState
      }
    }
  }
}

# Should match https://github.com/dahlbyk/posh-git/blob/master/GitPrompt.ps1
if(!(Test-Path Variable:Global:VcsPromptStatuses)) {
     $Global:VcsPromptStatuses = @()
 }
function Global:Write-VcsStatus { $Global:VcsPromptStatuses | foreach { & $_ } }

# Add scriptblock that will execute for Write-VcsStatus
$Global:VcsPromptStatuses += {
  Write-HgStatus-Async
}
