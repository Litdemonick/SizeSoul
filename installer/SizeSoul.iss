#ifndef AppVersion
  #error AppVersion is required. Use scripts/build-release.ps1.
#endif
#ifndef BuildNumber
  #define BuildNumber "0"
#endif
[Setup]
AppId={{835EA353-9E04-49B1-AD5B-702A74C26549}
AppName=SizeSoul
AppVersion={#AppVersion}
AppVerName=SizeSoul {#AppVersion}
AppPublisher=Litdemonick
AppPublisherURL=https://github.com/Litdemonick/SizeSoul
AppSupportURL=https://github.com/Litdemonick/SizeSoul/issues
AppUpdatesURL=https://github.com/Litdemonick/SizeSoul/releases
DefaultDirName={localappdata}\Programs\SizeSoul
DefaultGroupName=SizeSoul
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
UsePreviousAppDir=yes
UsePreviousTasks=yes
AppMutex=Local\SizeSoul.Desktop.1
CloseApplications=yes
RestartApplications=no
UninstallDisplayIcon={app}\sizesoul.exe
SetupIconFile=..\windows\runner\resources\app_icon.ico
LicenseFile=..\LICENSE
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
OutputDir=..\dist
OutputBaseFilename=SizeSoul-{#AppVersion}-windows-x64-setup
VersionInfoVersion={#AppVersion}.{#BuildNumber}
VersionInfoCompany=Litdemonick
VersionInfoDescription=SizeSoul installer
[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"
[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"; Flags: unchecked
[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{autoprograms}\SizeSoul"; Filename: "{app}\sizesoul.exe"; AppUserModelID: "Litdemonick.SizeSoul"
Name: "{autodesktop}\SizeSoul"; Filename: "{app}\sizesoul.exe"; Tasks: desktopicon
[Run]
Filename: "{app}\sizesoul.exe"; Description: "Abrir SizeSoul"; Flags: nowait postinstall skipifsilent
[Code]
function NextPart(var Version: String): Integer;
var Separator: Integer; Part: String;
begin
  Separator := Pos('.', Version);
  if Separator = 0 then begin Part := Version; Version := ''; end
  else begin Part := Copy(Version, 1, Separator - 1); Delete(Version, 1, Separator); end;
  Result := StrToIntDef(Part, 0);
end;
function IsNewer(Installed, Incoming: String): Boolean;
var I, A, B: Integer;
begin
  Result := False;
  for I := 1 to 3 do begin
    A := NextPart(Installed); B := NextPart(Incoming);
    if A > B then begin Result := True; Exit; end;
    if A < B then Exit;
  end;
end;
function InitializeSetup(): Boolean;
var Installed: String;
begin
  Result := True;
  if RegQueryStringValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{835EA353-9E04-49B1-AD5B-702A74C26549}_is1', 'DisplayVersion', Installed) then
    if IsNewer(Installed, '{#AppVersion}') then begin
      SuppressibleMsgBox('Ya tienes una version mas reciente de SizeSoul (' + Installed + '). No se permite instalar una anterior.', mbError, MB_OK, IDOK);
      Result := False;
    end;
end;
