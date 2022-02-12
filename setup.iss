; -- 64Bit.iss --
; Demonstrates installation of a program built for the x64 (a.k.a. AMD64)
; architecture.
; To successfully run this installation and the program it installs,
; you must have a "x64" edition of Windows.

; SEE THE DOCUMENTATION FOR DETAILS ON CREATING .ISS SCRIPT FILES!

[Setup]
SignTool=signtool
OutputBaseFilename=anime_season
AppName=Anime Seasons
AppVersion=1.0.2
VersionInfoVersion=1.0.2.0
WizardStyle=modern
DefaultDirName={autopf}\Anime Seasons
DefaultGroupName=Anime Seasons
UninstallDisplayIcon={app}\AnimeSeasons.exe
Compression=lzma2
SolidCompression=yes
OutputDir=userdocs:Inno Setup Files
; "ArchitecturesAllowed=x64" specifies that Setup cannot run on
; anything but x64.
ArchitecturesAllowed=x64
; "ArchitecturesInstallIn64BitMode=x64" requests that the install be
; done in "64-bit mode" on x64, meaning it should use the native
; 64-bit Program Files directory and the 64-bit view of the registry.
ArchitecturesInstallIn64BitMode=x64
SetupIconFile=windows\runner\resources\app_icon.ico

[Files]
Source: "build\windows\runner\Release\AnimeSeasons.exe"; DestDir: "{app}"; Flags: signonce;
Source: "build\windows\runner\Release\auto_update_plugin.dll"; DestDir: "{app}";
Source: "build\windows\runner\Release\dart_vlc_plugin.dll"; DestDir: "{app}";
Source: "build\windows\runner\Release\flutter_windows.dll"; DestDir: "{app}";
Source: "build\windows\runner\Release\libvlc.dll"; DestDir: "{app}";
Source: "build\windows\runner\Release\libvlccore.dll"; DestDir: "{app}"; 
Source: "build\windows\runner\Release\sqlite3.dll"; DestDir: "{app}";
Source: "build\windows\runner\Release\data\*"; DestDir: "{app}\data"; Flags: recursesubdirs;
Source: "build\windows\runner\Release\plugins\*"; DestDir: "{app}\plugins"; Flags: recursesubdirs;
Source: "windows\runner\resources\app_icon.ico"; DestDir: "{app}";


[Icons]
Name: "{group}\Anime Seasons"; Filename: "{app}\AnimeSeasons.exe"

[Run]
Filename: "{app}\AnimeSeasons.exe"; Description: "Launch application"; Flags: postinstall;