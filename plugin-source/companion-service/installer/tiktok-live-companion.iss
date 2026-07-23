#define MyAppName "TikTok LIVE Companion Sprachdienst"
#define MyAppVersion "0.7.2"
#define MyAppPublisher "KikiKari"
#define NativeHostName "de.kikikari.tiktok_live_companion"

[Setup]
AppId={{5901B82D-FC9A-47E6-AF89-C5FB8FC2D92D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\TikTokLiveCompanion\app
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=output
#ifdef SignedBuild
OutputBaseFilename=tiktok-live-companion-setup-{#MyAppVersion}
SignTool=tlcsign
#else
OutputBaseFilename=tiktok-live-companion-setup-{#MyAppVersion}-unsigned-dev
#endif
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName={#MyAppName}

[Files]
Source: "stage\node\*"; DestDir: "{app}\node"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "stage\service\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "stage\native-host-launcher.exe"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
Root: HKCU; Subkey: "Software\Google\Chrome\NativeMessagingHosts\{#NativeHostName}"; ValueType: string; ValueName: ""; ValueData: "{app}\native-host-manifest.json"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Microsoft\Edge\NativeMessagingHosts\{#NativeHostName}"; ValueType: string; ValueName: ""; ValueData: "{app}\native-host-manifest.json"; Flags: uninsdeletekey

[UninstallDelete]
Type: files; Name: "{app}\native-host-manifest.json"
Type: dirifempty; Name: "{app}"

[Code]
procedure WriteNativeHostManifest;
var
  Manifest: String;
  HostPath: String;
begin
  HostPath := ExpandConstant('{app}\native-host-launcher.exe');
  StringChangeEx(HostPath, '\', '\\', True);
  Manifest :=
    '{' + #13#10 +
    '  "name": "{#NativeHostName}",' + #13#10 +
    '  "description": "TikTok LIVE Companion Native Host 0.7.2",' + #13#10 +
    '  "path": "' + HostPath + '",' + #13#10 +
    '  "type": "stdio",' + #13#10 +
    '  "allowed_origins": ["chrome-extension://cocphppaeppkaigkdjbikfokcbniafpe/"]' + #13#10 +
    '}' + #13#10;
  SaveStringToFile(ExpandConstant('{app}\native-host-manifest.json'), Manifest, False);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    WriteNativeHostManifest;
end;
