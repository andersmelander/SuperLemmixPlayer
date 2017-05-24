unit LemNeoLevelPack;

// Replaces LemDosStyle, LemDosLevelSystem etc. Those are messy. This should be tidier.

// NOTE TO NEPSTER: This is a work-in-progress file that I haven't integrated yet, not an unused one. Do not remove.

interface

uses
  Dialogs,
  GR32, CRC32, PngInterface,
  Classes, SysUtils, StrUtils, Contnrs,
  LemStrings, LemTypes, LemNeoParser;

type
  TNeoLevelEntry = class;
  TNeoLevelEntries = class;
  TNeoLevelGroup = class;
  TNeoLevelGroups = class;

  TNeoLevelStatus = (lst_None, lst_Attempted, lst_Completed_Outdated, lst_Completed);
  TPostviewCondition = (pvc_Zero, pvc_Absolute, pvc_Relative, pvc_Percent, pvc_RelativePercent);

  TPostviewText = class // class rather than record so it plays nicely with a TObjectList and can create / destroy a TStringList
    private
      fText: TStringList;
      procedure LoadLine(aLine: TParserLine; const aIteration: Integer);
      procedure InterpretCondition(aConditionString: String);
    public
      ConditionType: TPostviewCondition;
      ConditionValue: Integer;
      property Text: TStringList read fText;
      constructor Create;
      destructor Destroy; override;
  end;

  TPostviewTexts = class(TObjectList)
    private
      function GetItem(Index: Integer): TPostviewText;
    public
      constructor Create;
      function Add: TPostviewText;
      property Items[Index: Integer]: TPostviewText read GetItem; default;
      property List;
  end;

  TNeoLevelEntry = class  // This is an entry in a level pack's list, and does NOT contain the level itself
    private
      fGroup: TNeoLevelGroup;

      fTitle: String;
      fFilename: String;

      fLevelID: Cardinal;

      fStatus: TNeoLevelStatus;

      fLastCRC32: Cardinal;

      procedure Wipe;
      procedure SetFilename(aValue: String);
      function GetFullPath: String;
      function GetTitle: String;
      function GetLevelID: Cardinal;
    public
      constructor Create(aGroup: TNeoLevelGroup);
      destructor Destroy; override;

      procedure EnsureUpdated;

      property Group: TNeoLevelGroup read fGroup;
      property Title: String read GetTitle;
      property Filename: String read fFilename write SetFilename;
      property LevelID: Cardinal read GetLevelID;
      property Path: String read GetFullPath;
      property Status: TNeoLevelStatus read fStatus write fStatus;
  end;

  TNeoLevelGroup = class
    private
      fParentGroup: TNeoLevelGroup;
      fChildGroups: TNeoLevelGroups;
      fLevels: TNeoLevelEntries;

      fName: String;
      fFolder: String;
      fPanelStyle: String;

      fMusicList: TStringList;
      fHasOwnMusicList: Boolean;

      fPostviewTexts: TPostviewTexts;
      fHasOwnPostviewTexts: Boolean;

      procedure SetFolderName(aValue: String);
      function GetFullPath: String;

      procedure LoadFromMetaInfo(aPath: String = '');
      procedure LoadFromSearchRec;

      procedure LoadLevel(aLine: TParserLine; const aIteration: Integer);
      procedure LoadSubGroup(aSection: TParserSection; const aIteration: Integer);

      procedure Load;

      procedure SetDefaultData;
      procedure LoadMusicData;
      procedure LoadMusicLine(aLine: TParserLine; const aIteration: Integer);
      procedure LoadPostviewData;
      procedure LoadPostviewSection(aSection: TParserSection; const aIteration: Integer);

      function GetRecursiveLevelCount: Integer;
    public
      constructor Create(aParentGroup: TNeoLevelGroup; aPath: String);
      destructor Destroy; override;

      procedure EnsureUpdated;

      property Children: TNeoLevelGroups read fChildGroups;
      property Levels: TNeoLevelEntries read fLevels;
      property LevelCount: Integer read GetRecursiveLevelCount;
      property Name: String read fName write fName;
      property Folder: String read fFolder write SetFolderName;
      property Path: String read GetFullPath;
      property PanelStyle: String read fPanelStyle;
      property MusicList: TStringList read fMusicList;
      property PostviewTexts: TPostviewTexts read fPostviewTexts;
  end;


  // Lists //

  TNeoLevelEntries = class(TObjectList)
    private
      fOwner: TNeoLevelGroup;
      function GetItem(Index: Integer): TNeoLevelEntry;
    public
      constructor Create(aOwner: TNeoLevelGroup);
      function Add: TNeoLevelEntry;
      property Items[Index: Integer]: TNeoLevelEntry read GetItem; default;
      property List;
  end;

  TNeoLevelGroups = class(TObjectList)
    private
      fOwner: TNeoLevelGroup;
      function GetItem(Index: Integer): TNeoLevelGroup;
    public
      constructor Create(aOwner: TNeoLevelGroup);
      function Add(aFolder: String): TNeoLevelGroup;
      property Items[Index: Integer]: TNeoLevelGroup read GetItem; default;
      property List;
  end;

  function SortAlphabetical(Item1, Item2: Pointer): Integer;

implementation

function SortAlphabetical(Item1, Item2: Pointer): Integer;
var
  G1: TNeoLevelGroup;
  G2: TNeoLevelGroup;
  L1: TNeoLevelEntry;
  L2: TNeoLevelEntry;
begin
  Result := 0;

  if (TObject(Item1^) is TNeoLevelGroup) and (TObject(Item2^) is TNeoLevelGroup) then
  begin
    G1 := TNeoLevelGroup(Item1^);
    G2 := TNeoLevelGroup(Item2^);
    Result := CompareStr(G1.Name, G2.Name);
  end;

  if (TObject(Item1^) is TNeoLevelEntry) and (TObject(Item2^) is TNeoLevelEntry) then
  begin
    L1 := TNeoLevelEntry(Item1^);
    L2 := TNeoLevelEntry(Item2^);
    Result := CompareStr(L1.Title, L2.Title);
  end;
end;

{ TPostviewText }

constructor TPostviewText.Create;
begin
  inherited;
  fText := TStringList.Create;
end;

destructor TPostviewText.Destroy;
begin
  fText.Free;
  inherited;
end;

procedure TPostviewText.LoadLine(aLine: TParserLine; const aIteration: Integer);
begin
  Text.Add(aLine.ValueTrimmed);
end;

procedure TPostviewText.InterpretCondition(aConditionString: String);
var
  IsRelative: Boolean;
  IsPercent: Boolean;
begin
  IsRelative := false;
  IsPercent := false;
  if (LeftStr(aConditionString, 1) = '+') or (LeftStr(aConditionString, 1) = '-') then
    IsRelative := true;

  if RightStr(aConditionString, 1) = '%' then
  begin
    aConditionString := LeftStr(aConditionString, Length(aConditionString)-1);
    IsPercent := true;
  end;

  ConditionValue := StrToIntDef(aConditionString, 0);
  if IsRelative then
  begin
    if IsPercent then
      ConditionType := pvc_RelativePercent
    else
      ConditionType := pvc_Relative;
  end else begin
    if IsPercent then
      ConditionType := pvc_Percent
    else
      ConditionType := pvc_Absolute;
  end;
end;

{ TNeoLevelEntry }

constructor TNeoLevelEntry.Create(aGroup: TNeoLevelGroup);
begin
  inherited Create;
  fGroup := aGroup;
end;

destructor TNeoLevelEntry.Destroy;
begin
  // Did have stuff here but it's no longer used. But left this here because stuff that needs it
  // will probably be added later.
  inherited;
end;

procedure TNeoLevelEntry.Wipe;
begin
  fTitle := '';
end;

function TNeoLevelEntry.GetTitle: String;
var
  Parser: TParser;
begin
  if fTitle = '' then
  begin
    Parser := TParser.Create;
    try
      Parser.LoadFromFile(Path);
      fTitle := Parser.MainSection.LineTrimString['title'];
    finally
      Parser.Free;
    end;
  end;

  Result := fTitle;
end;

function TNeoLevelEntry.GetLevelID: Cardinal;
var
  Parser: TParser;
begin
  if fLevelID = 0 then
  begin
    Parser := TParser.Create;
    try
      Parser.LoadFromFile(Path);
      fLevelID := Parser.MainSection.LineNumeric['id'];
    finally
      Parser.Free;
    end;
  end;

  Result := fLevelID;
end;

procedure TNeoLevelEntry.EnsureUpdated;
var
  CRC: Cardinal;
begin
  CRC := CalculateCRC32(Path);
  if CRC <> fLastCRC32 then Wipe;
  fLastCRC32 := CRC;
end;

procedure TNeoLevelEntry.SetFilename(aValue: String);
begin
  if fFilename = aValue then Exit;
  fFilename := aValue;
  EnsureUpdated;
end;

function TNeoLevelEntry.GetFullPath: String;
begin
  if fGroup = nil then
    Result := ''
  else
    Result := fGroup.Path;

  Result := Result + fFilename;
end;

{ TNeoLevelGroup }

constructor TNeoLevelGroup.Create(aParentGroup: TNeoLevelGroup; aPath: String);
begin
  inherited Create;

  fFolder := aPath;

  fChildGroups := TNeoLevelGroups.Create(self);
  fLevels := TNeoLevelEntries.Create(self);
  fParentGroup := aParentGroup;

  SetDefaultData;
  Load;
end;

procedure TNeoLevelGroup.SetDefaultData;
begin
  if fParentGroup = nil then
  begin
    fPanelStyle := SFDefaultStyle;
  end else begin
    fPanelStyle := fParentGroup.PanelStyle;
  end;

  LoadMusicData;
  LoadPostviewData;
end;

procedure TNeoLevelGroup.LoadMusicData;
var
  Parser: TParser;
  MainSec: TParserSection;
begin
  if (fParentGroup <> nil) and not FileExists(Path + 'music.nxmi') then
  begin
    fMusicList := fParentGroup.MusicList;
    fHasOwnMusicList := false;
    Exit;
  end;

  fMusicList := TStringList.Create;
  fHasOwnMusicList := true;
  Parser := TParser.Create;
  try
    if FileExists(Path + 'music.nxmi') then
      Parser.LoadFromFile(Path + 'music.nxmi')
    else
      Parser.LoadFromFile(AppPath + SFData + 'music.nxmi');

    MainSec := Parser.MainSection;
    MainSec.DoForEachLine('track', LoadMusicLine);
  finally
    Parser.Free;
  end;
end;

procedure TNeoLevelGroup.LoadPostviewData;
var
  Parser: TParser;
  MainSec: TParserSection;
begin
  if (fParentGroup <> nil) and not FileExists(Path + 'postview.nxmi') then
  begin
    fPostviewTexts := fParentGroup.PostviewTexts;
    fHasOwnPostviewTexts := false;
    Exit;
  end;

  fPostviewTexts := TPostviewTexts.Create;
  fHasOwnPostviewTexts := true;
  Parser := TParser.Create;
  try
    if FileExists(Path + 'postview.nxmi') then
      Parser.LoadFromFile(Path + 'postview.nxmi')
    else
      Parser.LoadFromFile(AppPath + SFData + 'postview.nxmi');

    MainSec := Parser.MainSection;
    MainSec.DoForEachSection('result', LoadPostviewSection);
  finally
    Parser.Free;
  end;
end;

procedure TNeoLevelGroup.LoadMusicLine(aLine: TParserLine; const aIteration: Integer);
begin
  fMusicList.Add(aLine.ValueTrimmed);
end;

procedure TNeoLevelGroup.LoadPostviewSection(aSection: TParserSection; const aIteration: Integer);
var
  NewText: TPostviewText;
begin
  NewText := fPostviewTexts.Add;
  NewText.InterpretCondition(aSection.LineTrimString['condition']);
  aSection.DoForEachLine('line', NewText.LoadLine);
end;

destructor TNeoLevelGroup.Destroy;
begin
  fChildGroups.Free;
  fLevels.Free;
  if fParentGroup = nil then
    fMusicList.Free;
  inherited;
end;

procedure TNeoLevelGroup.Load;
begin
  if FileExists(Path + 'levels.nxmi') then
    LoadFromMetaInfo
  else
    LoadFromSearchRec;
end;

procedure TNeoLevelGroup.LoadLevel(aLine: TParserLine; const aIteration: Integer);
var
  L: TNeoLevelEntry;
begin
  L := fLevels.Add;
  L.Filename := aLine.ValueTrimmed;
end;

procedure TNeoLevelGroup.LoadSubGroup(aSection: TParserSection; const aIteration: Integer);
var
  G: TNeoLevelGroup;
begin
  G := fChildGroups.Add(aSection.LineTrimString['folder']);
  G.Name := aSection.LineTrimString['name'];
end;

procedure TNeoLevelGroup.LoadFromMetaInfo;
var
  Parser: TParser;
  MainSec: TParserSection;
begin
  Parser := TParser.Create;
  try
    Parser.LoadFromFile(Path + 'levels.nxmi');
    MainSec := Parser.MainSection;
    MainSec.DoForEachSection('rank', LoadSubGroup);
    MainSec.DoForEachLine('level', LoadLevel);
    if MainSec.LineTrimString['name'] <> '' then
      fName := MainSec.LineTrimString['name'];
    fPanelStyle := MainSec.LineTrimString['panel'];

    // we do NOT want to sort alphabetically here, we want them to stay in the order
    // the metainfo file lists them in!
  finally
    Parser.Free;
  end;
end;

procedure TNeoLevelGroup.LoadFromSearchRec;
var
  SearchRec: TSearchRec;
  G: TNeoLevelGroup;
  L: TNeoLevelEntry;
begin
  if FindFirst(Path + '*', faDirectory, SearchRec) = 0 then
  begin
    repeat
      G := fChildGroups.Add(SearchRec.Name);
      G.Name := SearchRec.Name;
      G.Load;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
    fChildGroups.Sort(SortAlphabetical);
  end;

  if FindFirst(Path + '*.nxlv', 0, SearchRec) = 0 then
  begin
    repeat
      L := fLevels.Add;
      L.Filename := SearchRec.Name;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
    fLevels.Sort(SortAlphabetical);
  end;
end;

procedure TNeoLevelGroup.SetFolderName(aValue: String);
begin
  if fFolder = aValue then Exit;
  fFolder := aValue;
  EnsureUpdated;
end;

procedure TNeoLevelGroup.EnsureUpdated;
var
  i: Integer;
begin
  for i := 0 to fChildGroups.Count-1 do
    fChildGroups[i].EnsureUpdated;

  for i := 0 to fLevels.Count-1 do
    fLevels[i].EnsureUpdated;
end;

function TNeoLevelGroup.GetFullPath: String;
begin
  if Pos(':', fFolder) <> 0 then
    Result := ''
  else if fParentGroup = nil then
    Result := AppPath + SFLevels
  else
    Result := fParentGroup.Path;

  Result := Result + fFolder + '\';
end;

function TNeoLevelGroup.GetRecursiveLevelCount: Integer;
var
  i: Integer;
begin
  Result := fLevels.Count;
  for i := 0 to fChildGroups.Count-1 do
    Result := Result + fChildGroups[i].LevelCount;
end;



// --------- LISTS --------- //

{ TNeoLevelEntries }

constructor TNeoLevelEntries.Create(aOwner: TNeoLevelGroup);
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := true;
  inherited Create(aOwnsObjects);
  fOwner := aOwner;
end;

function TNeoLevelEntries.Add: TNeoLevelEntry;
begin
  Result := TNeoLevelEntry.Create(fOwner);
  inherited Add(Result);
end;

function TNeoLevelEntries.GetItem(Index: Integer): TNeoLevelEntry;
begin
  Result := inherited Get(Index);
end;

{ TNeoLevelGroups }

constructor TNeoLevelGroups.Create(aOwner: TNeoLevelGroup);
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := true;
  inherited Create(aOwnsObjects);
  fOwner := aOwner;
end;

function TNeoLevelGroups.Add(aFolder: String): TNeoLevelGroup;
begin
  Result := TNeoLevelGroup.Create(fOwner, aFolder);
  inherited Add(Result);
end;

function TNeoLevelGroups.GetItem(Index: Integer): TNeoLevelGroup;
begin
  Result := inherited Get(Index);
end;

{ TPostviewTexts }

constructor TPostviewTexts.Create;
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := true;
  inherited Create(aOwnsObjects);
end;

function TPostviewTexts.Add: TPostviewText;
begin
  Result := TPostviewText.Create;
  inherited Add(Result);
end;

function TPostviewTexts.GetItem(Index: Integer): TPostviewText;
begin
  Result := inherited Get(Index);
end;


end.