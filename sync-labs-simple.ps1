#!/usr/bin/env pwsh
# sync-labs-simple.ps1 - Robust sync for labs fork with upstream repository

Write-Host "Syncing labs fork with upstream repository..." -ForegroundColor Cyan

# Navigate to repo root
$repoRoot = "c:\Users\billn\Downloads\CHEM4800\CHEME-5800-Labs-Fall-2025"
Set-Location $repoRoot

# Fix git ownership issue
Write-Host "Fixing git ownership issue..." -ForegroundColor Yellow
git config --global --add safe.directory $repoRoot

# Check if upstream remote exists, if not add it
$upstreamExists = git remote | Select-String "upstream"
if (-not $upstreamExists) {
    Write-Host "Adding upstream remote..." -ForegroundColor Yellow
    git remote add upstream https://github.com/varnerlab/CHEME-5800-Labs-Fall-2025.git
}

# Stash any local changes first
Write-Host "Stashing any local changes..." -ForegroundColor Yellow
git stash push -m "Auto-stash before sync"

# Fetch upstream changes
Write-Host "Fetching upstream changes..." -ForegroundColor Yellow
git fetch upstream

# Check current branch
$currentBranch = git branch --show-current
Write-Host "Current branch: $currentBranch" -ForegroundColor Blue

# Merge upstream changes
Write-Host "Merging upstream changes..." -ForegroundColor Yellow
$mergeResult = git merge upstream/main 2>&1

# Check if there are conflicts
if ($LASTEXITCODE -ne 0) {
    Write-Host "Merge conflicts detected. Using your version for ALL conflicts..." -ForegroundColor Yellow
    
    # Get list of conflicted files
    $conflictedFiles = git diff --name-only --diff-filter=U
    
    foreach ($file in $conflictedFiles) {
        Write-Host "Keeping your version of: $file" -ForegroundColor Yellow
        git checkout --ours $file
        git add $file
    }
    
    # Complete the merge
    git commit -m "Auto-merge upstream updates (kept local versions)"
}

# Push to your fork
Write-Host "Pushing to your fork..." -ForegroundColor Yellow
$pushResult = git push origin $currentBranch 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Push failed, trying to pull first..." -ForegroundColor Yellow
    git pull origin $currentBranch
    git push origin $currentBranch
}

# Restore stashed changes if any
$stashList = git stash list
if ($stashList) {
    Write-Host "Restoring your stashed changes..." -ForegroundColor Yellow
    $stashResult = git stash pop 2>&1
    
    # Check if there are conflicts when restoring stash
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Conflicts detected when restoring your changes. Using your version..." -ForegroundColor Yellow
        
        # Get list of conflicted files from stash pop
        $conflictedFiles = git diff --name-only --diff-filter=U
        
        foreach ($file in $conflictedFiles) {
            Write-Host "Keeping your version of: $file" -ForegroundColor Yellow
            git checkout --ours $file
            git add $file
        }
        
        Write-Host "Your changes have been merged successfully!" -ForegroundColor Green
    } else {
        Write-Host "Your changes restored without conflicts!" -ForegroundColor Green
    }
} else {
    Write-Host "No stashed changes to restore." -ForegroundColor Blue
}

Write-Host "Labs fork sync complete!" -ForegroundColor Green
Write-Host "Latest labs are now available in your repository." -ForegroundColor Green

# Show summary of changes
Write-Host "Recent commits from upstream:" -ForegroundColor Blue
git log --oneline -5 upstream/main
