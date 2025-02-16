unit FPlaybackMode;

interface

uses
  GameControl,
  LemStrings,
  LemTypes,
  LemNeoLevelPack,
  LemmixHotkeys,
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, FileCtrl, ExtCtrls,
  SharedGlobals;

type
  TFPlaybackMode = class(TForm)
    btnBrowse: TButton;
    stSelectedFolder: TStaticText;
    lblSelectedFolder: TLabel;
    rgPlaybackOrder: TRadioGroup;
    cbAutoskip: TCheckBox;
    lblPlaybackCancelHotkey: TLabel;
    stPlaybackCancelHotkey: TStaticText;
    btnBeginPlayback: TButton;
    btnCancel: TButton;
    stPackName: TStaticText;
    lblWelcome: TLabel;
    procedure btnBrowseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBeginPlaybackClick(Sender: TObject);

  private
    fSelectedFolder: string;
    fCurrentlySelectedPack: string;
    function GetPlaybackModeHotkey: String;

  public
    procedure UpdatePackNameText;
    procedure SetGameParams;
    property SelectedFolder: string read fSelectedFolder write fSelectedFolder;
    property CurrentlySelectedPack: string read fCurrentlySelectedPack write fCurrentlySelectedPack;

  end;

implementation

  uses
    FSuperLemmixLevelSelect;

{$R *.dfm}

procedure TFPlaybackMode.btnBrowseClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
  InitialDir: String;
begin
  OpenDlg := TOpenDialog.Create(Self);
  try
    OpenDlg.Title := 'Select any file in the folder containing replays';

    InitialDir := AppPath + SFReplays + MakeSafeForFilename(GameParams.CurrentLevel.Group.ParentBasePack.Name);

    if not SysUtils.DirectoryExists(InitialDir) then
      InitialDir := AppPath + SFReplays;

    OpenDlg.InitialDir := InitialDir;
    OpenDlg.Filter := 'SuperLemmix Replay (*.nxrp)|*.nxrp';
    OpenDlg.Options := [ofFileMustExist, ofHideReadOnly, ofEnableSizing, ofPathMustExist];

    if OpenDlg.Execute then
    begin
      fSelectedFolder := ExtractFilePath(OpenDlg.FileName);

      if SysUtils.DirectoryExists(fSelectedFolder) then
      begin
        SetCurrentDir(fSelectedFolder);
        stSelectedFolder.Caption := ExtractFileName(ExcludeTrailingPathDelimiter(fSelectedFolder));
      end else
        ShowMessage('The selected folder path is invalid.');
    end;
  finally
    OpenDlg.Free;
  end;
end;

procedure TFPlaybackMode.UpdatePackNameText;
var
  Pack: String;
begin
  Pack := CurrentlySelectedPack;

  if Pack <> '' then
    stPackName.Caption := Pack
  else
    stPackName.Caption := 'Playback Mode';
end;

function TFPlaybackMode.GetPlaybackModeHotkey: String;
var
  Key: TLemmixHotkeyAction;
  ThisKey: TLemmixHotkey;
  KeyNames: TKeyNameArray;

  n: Integer;
begin
  Result := '';

  Key := lka_CancelPlayback;
  KeyNames := TLemmixHotkeyManager.GetKeyNames(True);

  for n := 0 to MAX_KEY do
  begin
    ThisKey := GameParams.Hotkeys.CheckKeyEffect(n);
    if ThisKey.Action <> Key then Continue;

    Result := KeyNames[n];
  end;
end;

procedure TFPlaybackMode.SetGameParams;
begin
  GameParams.AutoSkipPreviewPostview := cbAutoSkip.Checked;

  if (rgPlaybackOrder.ItemIndex >= Ord(Low(TPlaybackOrder)))
    and (rgPlaybackOrder.ItemIndex <= Ord(High(TPlaybackOrder))) then
      GameParams.PlaybackOrder := TPlaybackOrder(rgPlaybackOrder.ItemIndex);
end;

procedure TFPlaybackMode.btnBeginPlaybackClick(Sender: TObject);
begin
  if fSelectedFolder = '' then
  begin
    ShowMessage('No replays selected. Please choose a folder of replays to begin Playback Mode.');
    ModalResult := mrNone;
  end;
end;

procedure TFPlaybackMode.FormCreate(Sender: TObject);
begin
  // Set options and clear lists
  rgPlaybackOrder.ItemIndex := Ord(GameParams.PlaybackOrder);
  cbAutoSkip.Checked := GameParams.AutoSkipPreviewPostview;
  GameParams.PlaybackList.Clear;
  GameParams.UnmatchedList.Clear;
  GameParams.ReplayVerifyList.Clear;

  // Show currently-assigned Playback Mode hotkey
  stPlaybackCancelHotkey.Caption := GetPlaybackModeHotkey;
end;

procedure TFPlaybackMode.FormDestroy(Sender: TObject);
begin
  SetGameParams;
end;

end.
