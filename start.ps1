# start.ps1
Clear-Host

# --- FUNCIÓN DE COMPROBACIÓN ---
function Test-Docker {
    Write-Host "Verifying Docker Engine..." -ForegroundColor DarkGray
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[CRITICAL ERROR] Docker is not running." -ForegroundColor Red
        Write-Host "> Please open 'Docker Desktop' and wait for it to start." -ForegroundColor Yellow
        Write-Host "> Press Enter to exit..."
        Read-Host
        exit
    }
}

Test-Docker

Write-Host "Flutter Frontend Docker Manager" -ForegroundColor Cyan

$ComposeDev = "docker-compose-dev.yml"
$ComposeProd = "docker-compose.yml"

while ($true) {
    Write-Host "`n----------------------------------------" -ForegroundColor Green
    Write-Host "CONTROL MENU" -ForegroundColor Green
    Write-Host "----------------------------------------"
    Write-Host "1. Run DEV Mode (Interactive - Press 'R' to reload)"
    Write-Host "2. Run PROD Mode (Nginx Preview)"
    Write-Host "3. View Live Logs (Auto-detect)"
    Write-Host "4. Stop ALL Containers"
    Write-Host "5. Run Tests"
    Write-Host "6. Exit"
    Write-Host "----------------------------------------"
    
    $selection = Read-Host "Select option"

    if ($selection -eq "1") {
        Write-Host "Switching to DEV Mode..." -ForegroundColor Yellow
        docker-compose -f $ComposeProd down 2>$null

        Write-Host "Building DockerfileDev..." -ForegroundColor Cyan
        # 1. Levantamos en background primero para asegurar arranque limpio
        docker-compose -f $ComposeDev up -d --build
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n[SUCCESS] Dev Server started." -ForegroundColor Green
            try { Start-Process "http://localhost:8080" } catch {}
            
            Write-Host "---------------------------------------------------------------" -ForegroundColor Yellow
            Write-Host "ENTERING INTERACTIVE MODE" -ForegroundColor Yellow
            Write-Host "Press 'R' (Shift+r) to Hot Restart." -ForegroundColor Cyan
            Write-Host "Press 'Ctrl + C' to stop the container and return to menu." -ForegroundColor Red
            Write-Host "---------------------------------------------------------------" -ForegroundColor Yellow
            
            # 2. Nos 'enganchamos' al contenedor para tomar el control del teclado
            # Esperamos 2 segundos para dar tiempo al proceso a iniciarse
            Start-Sleep -Seconds 2
            docker attach flutter_hot_reload
        } else {
            Write-Host "`n[ERROR] Failed to start Dev Server." -ForegroundColor Red
        }
    }
    elseif ($selection -eq "2") {
        Write-Host "Switching to PROD Mode..." -ForegroundColor Yellow
        docker-compose -f $ComposeDev down 2>$null

        Write-Host "Building DockerfileProd & Nginx..." -ForegroundColor Cyan
        docker-compose -f $ComposeProd up -d --build
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n[SUCCESS] Production Preview running at http://localhost:8080" -ForegroundColor Green
            try { Start-Process "http://localhost:8080" } catch {}
        } else {
            Write-Host "`n[ERROR] Failed to start Prod Server." -ForegroundColor Red
        }
    }
    elseif ($selection -eq "3") {
        Write-Host "Detecting active containers..." -ForegroundColor Yellow
        
        # En opción 3, si es DEV, hacemos attach en lugar de logs para permitir input
        $devRunning = (docker-compose -f $ComposeDev ps -q)
        if ($devRunning) {
            Write-Host "Attaching to DEV container... (Press Ctrl+C to detach/stop)" -ForegroundColor Cyan
            docker attach flutter_hot_reload
        }
        else {
            $prodRunning = (docker-compose -f $ComposeProd ps -q)
            if ($prodRunning) {
                Write-Host "Streaming PROD logs... (Ctrl+C to exit)" -ForegroundColor Cyan
                docker-compose -f $ComposeProd logs -f
            } else {
                Write-Host "[ERROR] No active containers found." -ForegroundColor Red
            }
        }
    }
    elseif ($selection -eq "4") {
        Write-Host "Stopping EVERYTHING..." -ForegroundColor Magenta
        docker-compose -f $ComposeDev down
        docker-compose -f $ComposeProd down
        Write-Host "All clean." -ForegroundColor Green
    }
    elseif ($selection -eq "5") {
        $workdir = (Get-Location).Path
        Write-Host "Running flutter tests inside container..." -ForegroundColor Cyan
        docker run --rm -v "${workdir}:/app" -w /app ghcr.io/cirruslabs/flutter:3.27.1 bash -lc "flutter pub get && flutter test"
    }
    elseif ($selection -eq "6") {
        Write-Host "Stopping and Exiting..."
        docker-compose -f $ComposeDev down 2>$null
        docker-compose -f $ComposeProd down 2>$null
        exit
    }
    else {
        Write-Host "Invalid option." -ForegroundColor Red
    }
}