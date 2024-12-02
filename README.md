Fork from [krantic](https://github.com/krantic/IPv6Tunnel) with error fix when virtual interfaces do not have the IPv4Connectivity property.

A script for creating a tunnel IPV6 from [TunnelBroker](https://tunnelbroker.net) for Windows 10


- You must enter your data in lines 88-127

- Perhaps it will be necessary to change the registry parameter

_HKEY_LOCAL_MACHINE\System\CurrentControlset\Services\Tcpip6\Parameters_

Disabledcomponents in value 0

If there is no parameter (but by default = not), then create REG_DWORD. For disable value [255](https://learn.microsoft.com/en-en/troubleshoot/windows-server/networking/configure-ipv6-in-windows)

- It is also possible to enable PowerShell scenarios

_Win+R -> gpedit.msc_

**Computer Configuration -> Administrative Templates -> Windows Components -> Windows PowerShell -> Enable scenarios -> Enabled -> Allow ... (this line with google translate)**

PS. Work on Windows 10 22H2
--------------------------------------------------------
Форк от [krantic](https://github.com/krantic/ipv6tunnel) с исправлением ошибки, когда виртуальные интерфейсы не имеют свойства IPv4Connectivity.

Скрипт для создания тунеля IPv6 от [TunnelBroker](https://tunnelbroker.net) для Windows 10

- Вы должны внести свои данные в строках 88-127

- Возможно нужно будет изменить параметр реестра
_HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters_

DisabledComponents в значение 0

Если параметра нет (а по умолчанию нет), то создать REG_DWORD. Чтобы отключить, значение [255](https://learn.microsoft.com/ru-ru/troubleshoot/windows-server/networking/configure-ipv6-in-windows)

- Также возможно нужно включить выполнение сценариев PowerShell

_Win+R -> gpedit.msc_

**Конфигурация компьютера -> Административные шаблоны -> Компоненты Windows -> Windows PowerShell -> Включить выполнение сценариев -> Включено -> Разрешить ...**

ПС. Работает на Windows 10 22H2
--------------------------------------------------------
