function Show-Sessions {
    $raw = query session 2>&1 | Where-Object { $_ -match '\d+\s+(Активно|Active)' }
    $parsed = @()

    foreach ($line in $raw) {
        $clean = $line -replace "^\s+", ""
        $parts = $clean -split "\s{2,}"  # разделение по двойным пробелам

        if ($parts.Count -ge 3) {
            $username = $parts[1]
            $id       = $parts[2]
            $state    = $parts[3]

            $parsed += [pscustomobject]@{
                ID       = $id
                Username = $username
                State    = $state
                RawLine  = $line.Trim()
            }
        }
    }

    return $parsed
}



function Connect-Shadow {
    param(
        [string]$SessionId,
        [switch]$Control
    )
    $args = "/shadow:$SessionId"
    if ($Control) { $args += " /control" }
    $args += " /noConsentPrompt"

    Start-Process -FilePath "mstsc.exe" -ArgumentList $args
}

function Send-MSG {
    param (
        [string]$User,
        [string]$Text
    )

    Start-Process powershell -ArgumentList @(
        '-Command',
        "msg /TIME:3600 /V $User `"$Text`""
    )
}


function SubMenu {
    param (
        [string]$SessionId,
        [string]$Username
    )
    do {
        Clear-Host
        Write-Host "Выбрана сессия $SessionId ($Username)" -ForegroundColor Yellow
        Write-Host "1 - Подключиться для просмотра"
        Write-Host "2 - Подключиться для управления"
        Write-Host "3 - Сообщение: ПК будет перезагружен через 5 мин!"
		Write-Host "4 - Сообщение: <свой текст>"
        Write-Host "0 - Вернуться назад"
        $action = Read-Host "Ваш выбор"

        switch ($action) {
            '1' { Connect-Shadow -SessionId $SessionId }
            '2' { Connect-Shadow -SessionId $SessionId -Control }
			'3' { Send-MSG $Username "ПК будет перезагружен через 5 мин!"}
            '4' { $text = Read-Host "Введите текст сообщения";
				  Send-MSG $Username $text}
			'0' { return }
            default { Write-Host "Неверный ввод"; Start-Sleep -Seconds 1 }
        }
    } while ($true)
}

function Main-Menu {
    do {
        Clear-Host
        Write-Host "==== Активные сеансы пользователей ====" -ForegroundColor Cyan
        $sessions = Show-Sessions
        foreach ($s in $sessions) {
            Write-Host "$($s.ID): $($s.Username) [$($s.State)]"
        }

        Write-Host "`n0 - Обновить список"
        Write-Host "N - Подключиться к пользователю с ID N"
		Write-Host "A - Сообщение всем: ПК будет перезагружен через 5 мин!"
		Write-Host "M - Сообщение всем: <свой текст>"
        $choice = Read-Host "`nВаш выбор"
	
		switch ($choice) {
			'0' { break }  # выход из switch 
			'A' { Send-MSG * "ПК будет перезагружен через 5 мин!"}
			'M' { $text = Read-Host "Введите текст сообщения";
				  Send-MSG * $text}
			default {
				if ($choice -match '^\d+$') {
					$selected = $sessions | Where-Object { $_.ID -eq $choice }
					if (-not $selected) {
						Write-Warning "Сессия с ID $choice не найдена или неактивна"
						Start-Sleep -Seconds 2
						break
					}
					SubMenu $selected.ID $selected.Username
				} #if
			} #default
		} #switch
    } while ($true)
}

# Запуск главного меню
Main-Menu
