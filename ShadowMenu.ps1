# ===============================================
# Проверка прав администратора
# ===============================================
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    
    Write-Host "Скрипт не запущен с правами администратора. Перезапуск с повышенными правами..." -ForegroundColor Yellow
    
    # Создаём процесс PowerShell с повышенными правами
    $psArguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -Verb RunAs -ArgumentList $psArguments
    
    # Завершаем текущий экземпляр
    exit
}

$Is64 = ([Environment]::Is64BitOperatingSystem)
if ($Is64) {
    $PsExecFile = "PsExec64.exe"
} else {
    $PsExecFile = "PsExec.exe"
}
$PsExecPath = Join-Path -Path $PSScriptRoot -ChildPath $PsExecFile

# ================================
# Получение списка сессий
# ================================

function Get-Sessions {

    $sessions = @()

    $raw = query session 2>$null | Select-Object -Skip 1

    foreach ($line in $raw) {

        $line = $line.TrimStart("> ").Trim()

        if ($line -match '(.+?)\s+(\d+)\s+(.+)$') {

            $left  = $matches[1]
            $id    = $matches[2]
            $state = $matches[3]

            $session = ""
            $user    = ""

            $parts = $left -split '\s+',2

            if ($parts.Count -eq 2) {
                $session = $parts[0]
                $user    = $parts[1]
            }
            else {
                $user = $parts[0]
            }

            $sessions += [pscustomobject]@{
                SessionName = $session
                Username    = $user
                ID          = [int]$id
                State       = $state
            }

        }

    }

    # фильтр системных сессий
    $sessions = $sessions | Where-Object {
        $_.ID -notin 0,65536 -and
        $_.UserName -ne "console"
    }

    return $sessions | Sort-Object ID
}
# ================================
# Красивый вывод списка
# ================================

function Show-Sessions {

    $sessions = Get-Sessions

    Write-Host ""
    Write-Host "ID   USERNAME        SESSION        STATE" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------"

    foreach ($s in $sessions) {

        Write-Host ("{0,-4} {1,-15} {2,-14} {3}" -f `
            $s.ID,$s.Username,$s.SessionName,$s.State)

    }

    return $sessions
}
# ================================
# Shadow подключение
# ================================

function Connect-Shadow {

    param(
        [string]$SessionId,
        [switch]$Control
    )

    $args = "/shadow:$SessionId"

    if ($Control) { $args += " /control" }

    $args += " /noConsentPrompt"

    Start-Process mstsc.exe -ArgumentList $args
}

# ================================
# Отправка сообщения
# ================================

function Send-MSG {

    param (
        [string]$User,
        [string]$Text
    )

    msg $User /TIME:3600 $Text
}

# ================================
# Перевод сессии на консоль
# ================================

function Move-ToConsole {

    param(
        [string]$SessionId
    )

    Write-Host ""
    Write-Host "Перевод сессии $SessionId на консоль..." -ForegroundColor Yellow

	Start-Process -FilePath $PsExecPath -ArgumentList "-s -i cmd.exe /c tscon $SessionId /dest:console" -Wait

    Start-Sleep 2

    Write-Host "Операция выполнена." -ForegroundColor Green
}

function Disconnect-Session {
    param([int]$SessionId)
    Start-Process -FilePath $PsExecPath -ArgumentList "-s cmd /c tsdiscon $SessionId" -Wait
}

function Logoff-Session {
    param([int]$SessionId)
    Start-Process -FilePath $PsExecPath -ArgumentList "-s cmd /c logoff $SessionId" -Wait
}


# ================================
# Подменю сессии
# ================================

function SubMenu {

    param($Session)

    do {

        Clear-Host

        Write-Host "Выбрана сессия $($Session.ID) ($($Session.Username)) [$($Session.State)]" -ForegroundColor Yellow
        Write-Host ""

        Write-Host "1 - Подключиться для просмотра"
        Write-Host "2 - Подключиться для управления"
        Write-Host "3 - Перевести сессию на консоль"
        Write-Host "4 - Отключить пользователя"
        Write-Host "5 - Закрыть приложения и завершить сеанс"
        Write-Host "6 - Сообщение: ПК будет перезагружен через 5 мин!"
        Write-Host "7 - Сообщение: <свой текст>"
        Write-Host "0 - Вернуться назад"

        $choice = Read-Host "Ваш выбор"

        switch ($choice) {

            '1' { Connect-Shadow $Session.ID }

            '2' { Connect-Shadow $Session.ID -Control }

            '3' { Move-ToConsole $Session.ID }
			
			'4' { Disconnect-Session $Session.ID }
			
			'5' { Logoff-Session $Session.ID }

            '6' { Send-MSG $Session.Username "ПК будет перезагружен через 5 мин!" }

            '7' {
                $text = Read-Host "Введите текст сообщения"
                Send-MSG $Session.Username $text
            }

            '0' { return }

            default {
                Write-Host "Неверный ввод"
                Start-Sleep 1
            }

        }

    } while ($true)
}

# ================================
# Главное меню
# ================================

function Main-Menu {

    do {

        Clear-Host

        Write-Host "==== Сеансы пользователей ====" -ForegroundColor Cyan

        $sessions = Show-Sessions

        Write-Host ""
        Write-Host "0 - Обновить список"
        Write-Host "N - Подключиться к пользователю с ID N"
        Write-Host "A - Сообщение всем: ПК будет перезагружен через 5 мин!"
        Write-Host "M - Сообщение всем: <свой текст>"

        $choice = Read-Host "`nВаш выбор"

        switch ($choice) {

            '0' { continue }

            'A' { Send-MSG * "ПК будет перезагружен через 5 мин!" }

            'M' {
                $text = Read-Host "Введите текст сообщения"
                Send-MSG * $text
            }

            default {

                if ($choice -match '^\d+$') {

                    $selected = $sessions | Where-Object { $_.ID -eq $choice }

                    if (-not $selected) {

                        Write-Warning "Сессия с ID $choice не найдена"
                        Start-Sleep 2
                        continue
                    }

                    SubMenu $selected

                }

            }

        }

    } while ($true)
}

# ================================
# Запуск
# ================================

Main-Menu
