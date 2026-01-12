Запускать от имени администратора.

Должно быть разрешено подключаться без запроса пользователя политикой или в реестре:

*Политика*

Computer Configuration
 └ Policies
   └ Administrative Templates
     └ Windows Components
       └ Remote Desktop Services
         └ Remote Desktop Session Host
           └ Connections


*В реестре*

HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services

Shadow REG_DWORD 0x2
