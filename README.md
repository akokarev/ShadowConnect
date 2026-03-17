# ShadowConnect – RDS User Session Manager
ShadowConnect позволяет управлять сеансами пользователей на сервере Windows Remote Desktop (RDS):

- Просмотр всех текущих сеансов (активных и неактивных, кроме системных и консоли).
- Теневой доступ к сессии:
  - Только просмотр
  - Просмотр и управление
  - Перевод сессии на консоль (даёт возможность подключиться к отключенному пользователю)
- Отправка сообщений пользователям или всем сразу.
- Отключение или принудительное завершение сеанса.
- Проверка и настройка политики Shadow (теневой доступ с запросом пользователя или без него).

## Требования
- Windows Server с ролью Remote Desktop Services
- Запуск скрипта **от имени администратора**
- Для перевода на консоль: PsExec.exe и PsExec64.exe должны находиться в папке скрипта
- Настройки Shadow должны быть разрешены в реестре или через политику:
  - `HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Shadow` (DWord)
  - Значения:
    - `0x00` – отключено
    - `0x01` – с запросом пользователя
    - `0x02` – без запроса

## Запуск скрипта

#### Стандартный интерактивный запуск
```powershell
.\ShadowMenu.ps1
```
#### Включить Shadow без запроса пользователя
```powershell
.\ShadowMenu.ps1 -SetNoAnswer
```
#### Включить Shadow с запросом пользователя
```powershell
.\ShadowMenu.ps1 -SetNeedAnswer
```
#### Полное отключение Shadow
```powershell
.\ShadowMenu.ps1 -Disable
```

## Возможные проблемы
#### Кодировка
Файл скрипта должен быть сохранен в кодировке UTF-8 with BOM
#### Не удается загрузить файл ShadowConnect\ShadowMenu.ps1. Файл ShadowConnect\ShadowMenu.ps1 не имеет цифровой подписи. Невозможно выполнить сценарий в указанной системе. CategoryInfo : Ошибка безопасности: (:) [], PSSecurityException FullyQualifiedErrorId : UnauthorizedAccess
Проблема в политике запуска неподписанных скриптов. Разрешим запуск для одной сессии консоли
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```
