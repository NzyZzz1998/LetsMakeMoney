#ifndef AppVersion
  #define AppVersion "0.7-beta"
#endif
#ifndef SourceDir
  #error SourceDir must be provided by build_installer.ps1
#endif
#ifndef OutputDir
  #define OutputDir "."
#endif

[Setup]
AppId={{1BDF5D3A-9897-4E26-B868-1378CC7F31ED}
AppName=LetsMakeMoney
AppVersion={#AppVersion}
AppPublisher=NzyZzz1998
AppPublisherURL=https://github.com/NzyZzz1998/LetsMakeMoney
DefaultDirName={localappdata}\Programs\LetsMakeMoney
DefaultGroupName=LetsMakeMoney
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename=LetsMakeMoney-Setup-v{#AppVersion}-windows-x86_64
SetupIconFile={#SourceDir}\app_icon.ico
UninstallDisplayIcon={app}\app_icon.ico
LicenseFile={#SourceDir}\LICENSES\PROJECT_LICENSE.txt
InfoBeforeFile={#SourceDir}\LICENSES\THIRD_PARTY_NOTICES.md
InfoAfterFile={#SourceDir}\LICENSES\ASSETS_LICENSE.md
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
CloseApplicationsFilter=LetsMakeMoney.exe
AppMutex=LetsMakeMoneySingleton
Uninstallable=yes
ChangesAssociations=no
ChangesEnvironment=no
DisableProgramGroupPage=yes
SetupLogging=yes

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加快捷方式："; Flags: unchecked

[Files]
Source: "{#SourceDir}\LetsMakeMoney.exe"; DestDir: "{app}"; Flags: ignoreversion restartreplace
Source: "{#SourceDir}\letsmakemoney_native.dll"; DestDir: "{app}"; Flags: ignoreversion restartreplace
Source: "{#SourceDir}\app_icon.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\release-notes.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\LICENSES\*"; DestDir: "{app}\LICENSES"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\LetsMakeMoney"; Filename: "{app}\LetsMakeMoney.exe"; IconFilename: "{app}\app_icon.ico"
Name: "{autodesktop}\LetsMakeMoney"; Filename: "{app}\LetsMakeMoney.exe"; IconFilename: "{app}\app_icon.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\LetsMakeMoney.exe"; Description: "启动 LetsMakeMoney"; Flags: nowait postinstall skipifsilent

[Code]
var
  DeleteUserDataCheck: TNewCheckBox;
  DeleteUserDataOnUninstall: Boolean;

function InitializeSetup(): Boolean;
begin
  Result := True;
  Log('LetsMakeMoney installer initialization complete; user data is preserved unless deleteuserdata is explicitly selected.');
end;

function InitializeUninstall(): Boolean;
var
  ConfirmForm: TSetupForm;
  Explanation: TNewStaticText;
  ContinueButton: TNewButton;
  CancelButton: TNewButton;
begin
  DeleteUserDataOnUninstall := False;
  ConfirmForm := CreateCustomForm(ScaleX(420), ScaleY(170), False, True);
  try
    ConfirmForm.Caption := '卸载 LetsMakeMoney';
    ConfirmForm.ClientWidth := ScaleX(420);
    ConfirmForm.ClientHeight := ScaleY(170);
    ConfirmForm.Position := poScreenCenter;

    Explanation := TNewStaticText.Create(ConfirmForm);
    Explanation.Parent := ConfirmForm;
    Explanation.Left := ScaleX(20);
    Explanation.Top := ScaleY(20);
    Explanation.Width := ScaleX(380);
    Explanation.AutoSize := False;
    Explanation.WordWrap := True;
    Explanation.Caption := '卸载将删除程序文件。默认保留工资设置、桌宠偏好和日志，以便以后重新安装。';

    DeleteUserDataCheck := TNewCheckBox.Create(ConfirmForm);
    DeleteUserDataCheck.Parent := ConfirmForm;
    DeleteUserDataCheck.Left := ScaleX(20);
    DeleteUserDataCheck.Top := ScaleY(78);
    DeleteUserDataCheck.Width := ScaleX(380);
    DeleteUserDataCheck.Caption := '同时删除设置和日志（不可恢复）';
    DeleteUserDataCheck.Checked := False;

    ContinueButton := TNewButton.Create(ConfirmForm);
    ContinueButton.Parent := ConfirmForm;
    ContinueButton.Caption := '继续卸载';
    ContinueButton.ModalResult := mrOk;
    ContinueButton.Left := ScaleX(220);
    ContinueButton.Top := ScaleY(120);
    ContinueButton.Width := ScaleX(86);

    CancelButton := TNewButton.Create(ConfirmForm);
    CancelButton.Parent := ConfirmForm;
    CancelButton.Caption := '取消';
    CancelButton.ModalResult := mrCancel;
    CancelButton.Left := ScaleX(316);
    CancelButton.Top := ScaleY(120);
    CancelButton.Width := ScaleX(86);

    Result := ConfirmForm.ShowModal = mrOk;
    if Result and DeleteUserDataCheck.Checked then
    begin
      Result := MsgBox('设置和日志删除后无法恢复。确定继续吗？', mbConfirmation, MB_YESNO) = IDYES;
      DeleteUserDataOnUninstall := Result;
    end;
  finally
    ConfirmForm.Free;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if (CurUninstallStep = usPostUninstall) and DeleteUserDataOnUninstall then
  begin
    DelTree(ExpandConstant('{userappdata}\LetsMakeMoney'), True, True, True);
    Log('User explicitly confirmed removal of LetsMakeMoney settings and logs.');
  end;
end;
