# start.ps1
Clear-Host
Write-Host "Flutter Frontend Docker Manager" -ForegroundColor Cyan

while ($true) {
    Write-Host "`n----------------------------------------" -ForegroundColor Green
    Write-Host "CONTROL MENU" -ForegroundColor Green
    Write-Host "----------------------------------------"
    Write-Host "1. Build and Run Preview"
    Write-Host "2. View Live Logs (Ctrl+C to exit logs)"
    Write-Host "3. Stop Preview"
    Write-Host "4. Run Tests"
    Write-Host "5. Exit"
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
        Write-Host "Streaming logs... (Press Ctrl+C to return to menu/exit)" -ForegroundColor Yellow
        # El flag -f (follow) mantiene la conexión abierta para ver logs en tiempo real
        try {
            docker-compose logs -f
        } catch {
            Write-Host "Error: Containers might not be running." -ForegroundColor Red
        }
    }
    elseif ($selection -eq "3") {
        Write-Host "Stopping..." -ForegroundColor Magenta
        docker-compose down
    }
    elseif ($selection -eq "4") {
        $workdir = (Get-Location).Path
        Write-Host "Running flutter tests inside container..." -ForegroundColor Cyan
        # Usamos la imagen oficial para correr los tests sin necesidad de levantar Nginx
        docker run --rm -v "${workdir}:/app" -w /app ghcr.io/cirruslabs/flutter:3.27.1 bash -lc "flutter pub get && flutter test"
    }
    elseif ($selection -eq "5") {
        docker-compose down
        exit
    }
    else {
        Write-Host "Invalid option." -ForegroundColor Red
    }
}