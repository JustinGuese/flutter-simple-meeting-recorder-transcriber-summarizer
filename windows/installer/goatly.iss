; Inno Setup installer for GOATLY Meeting Summarizer
; Script version: 1.0
; Built for: Windows 7+

[Setup]
AppName=GOATLY Meeting Summarizer
AppVersion={#AppVersion}
AppPublisher=DataFortressCloud
AppPublisherURL=https://github.com/JustinGuese/flutter-simple-meeting-recorder-transcriber-summarizer
AppSupportURL=https://github.com/JustinGuese/flutter-simple-meeting-recorder-transcriber-summarizer/issues
AppUpdatesURL=https://github.com/JustinGuese/flutter-simple-meeting-recorder-transcriber-summarizer/releases
DefaultDirName={autopf}\GOATLY
DefaultGroupName=GOATLY
AllowNoIcons=yes
LicenseFile=..\..\LICENSE
OutputDir={#SourcePath}\..\..\
OutputBaseFilename=goatly-setup
SetupIconFile=..\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; Copy all files from Release build directory
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\GOATLY Meeting Summarizer"; Filename: "{app}\flutter_simple_meeting_recorder_transcriber_summarizer.exe"; IconFilename: "{app}\app.ico"
Name: "{commondesktop}\GOATLY Meeting Summarizer"; Filename: "{app}\flutter_simple_meeting_recorder_transcriber_summarizer.exe"; Tasks: desktopicon; IconFilename: "{app}\app.ico"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Run]
Filename: "{app}\flutter_simple_meeting_recorder_transcriber_summarizer.exe"; Description: "{cm:LaunchProgram,GOATLY Meeting Summarizer}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: dirifempty; Name: "{app}"
