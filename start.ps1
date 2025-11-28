# start.ps1
Clear-Host
Write-Host "Flutter Frontend Docker Manager" -ForegroundColor Cyan

while ($true) {
    Write-Host "`n----------------------------------------" -ForegroundColor Green
    Write-Host "CONTROL MENU" -ForegroundColor Green
    Write-Host "----------------------------------------"
    Write-Host "1. Build and Run Preview"
    Write-Host "2. Stop Preview"
    Write-Host "3. Exit"
    Write-Host "----------------------------------------"
    
    $selection = Read-Host "Select option"

    if ($selection -eq "1") {
        Write-Host "Building Flutter Web and Starting Nginx..." -ForegroundColor Yellow
        docker-compose up -d --build
        Write-Host "Running at http://localhost:8080" -ForegroundColor Green
        try {
            Start-Process "http://localhost:8080"
        } catch {
            Write-Host "Open http://localhost:8080 in your browser."
        }
    }
    elseif ($selection -eq "2") {
        Write-Host "Stopping..." -ForegroundColor Magenta
        docker-compose down
    }
    elseif ($selection -eq "3") {
        docker-compose down
        exit
    }
    else {
        Write-Host "Invalid option." -ForegroundColor Red
    }
}