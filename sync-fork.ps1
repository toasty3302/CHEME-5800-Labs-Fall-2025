#!/usr/bin/env pwsh
# sync-fork.ps1 - Sync fork with upstream while preserving student notebook

Write-Host "🔄 Syncing fork with upstream repository..." -ForegroundColor Cyan

# Navigate to repo root
$repoRoot = "c:\Users\billn\Downloads\CHEM4800\CHEME-5800-Labs-Fall-2025"
Set-Location $repoRoot

# Fetch upstream changes
Write-Host "📥 Fetching upstream changes..." -ForegroundColor Yellow
git fetch upstream

# Merge upstream changes
Write-Host "🔄 Merging upstream changes..." -ForegroundColor Yellow
$mergeResult = git merge upstream/main 2>&1

# Check if there are conflicts
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Merge conflicts detected. Resolving..." -ForegroundColor Yellow
    
    # Get list of conflicted files
    $conflictedFiles = git diff --name-only --diff-filter=U
    
    foreach ($file in $conflictedFiles) {
        if ($file -like "*Student*TestNotebook*") {
            Write-Host "� Keeping your version of: $file" -ForegroundColor Yellow
            git checkout --ours $file
            git add $file
        } else {
            Write-Host "⚡ Taking upstream version of: $file" -ForegroundColor Yellow
            git checkout --theirs $file
            git add $file
        }
    }
    
    # Complete the merge
    git commit -m "Merge upstream updates, preserving student notebook work"
}

# Push to your fork
Write-Host "📤 Pushing to your fork..." -ForegroundColor Yellow
git push origin main

Write-Host "✅ Fork sync complete!" -ForegroundColor Green
Write-Host "Your student notebook work is preserved and tracked in git." -ForegroundColor Green
