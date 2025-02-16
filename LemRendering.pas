{$include lem_directives.inc}

unit LemRendering;

interface

uses
  Dialogs,
  System.Types, Generics.Collections,
  Classes, Math, Windows,
  GR32, GR32_Blend,
  UMisc, SysUtils, StrUtils,
  PngInterface,
  LemRecolorSprites,
  LemRenderHelpers, LemNeoPieceManager, LemNeoTheme,
  LemTypes,
  LemTerrain, LemGadgetsModel, LemMetaTerrain,
  LemGadgets, LemGadgetsMeta, LemGadgetAnimation, LemGadgetsConstants,
  LemLemming, LemProjectile,
  LemAnimationSet, LemMetaAnimation, LemCore,
  LemLevel, LemStrings,
  SharedGlobals;

type
  TParticleRec = packed record
    DX, DY: ShortInt
  end;
  TParticleArray = packed array[0..79] of TParticleRec;
  TParticleTable = packed array[0..50] of TParticleArray;

  // Temp solution
  TRenderInfoRec = record
    TargetBitmap : TBitmap32; // The visual bitmap
    Level        : TLevel;
  end;

  TPhysicsRenderingType = (prtStandard, prtSteel, prtOneWay, prtErase);

  TRenderer = class
  private
    fGadgets            : TGadgetList;
    fDrawingHelpers     : Boolean;
    fUsefulOnly         : Boolean;

    fRenderInterface    : TRenderInterface;

    fDisableBackground  : Boolean;
    fTransparentBackground: Boolean;

    fLaserGraphic       : TBitmap32;

    fPhysicsMap         : TBitmap32;
    fLayers             : TRenderBitmaps;

    TempBitmap          : TBitmap32;
    RenderInfoRec       : TRenderInfoRec;
    fTheme              : TNeoTheme;
    fHelperImages       : THelperImages;
    fAni                : TBaseAnimationSet;
    fBgColor            : TColor32;
    fParticles          : TParticleTable; // All particle offsets
    fPreviewGadgets     : TGadgetList; // For rendering from Preview screen
    fDoneBackgroundDraw : Boolean;
    fIsFreezerExplosion : Boolean;

    fTempLemmingList: TLemmingList;

    fFixedDrawColor: TColor32; // Must use with CombineFixedColor pixel combine
    fPhysicsRenderingType: TPhysicsRenderingType;

    fHelpersAreHighRes:   Boolean;

    // Add stuff
    procedure AddTerrainPixel(X, Y: Integer; Color: TColor32);
    procedure AddFreezer(X, Y: Integer);
    procedure AddSpear(P: TProjectile);
    // Remove stuff
    procedure ApplyRemovedTerrain(X, Y, W, H: Integer);


    // Physics map preparation combines and helpers
    function CombineTerrainSolidity(F: Byte; B: Byte): Byte;
    function CombineTerrainSolidityErase(F: Byte; B: Byte): Byte;
    function CombineTerrainProperty(F: Byte; B: Byte; FIntensity: Byte): Byte;

    procedure CombineTerrainPhysicsPrep(F: TColor32; var B: TColor32; M: Cardinal);
    procedure CombineTerrainPhysicsPrepNoOverwrite(F: TColor32; var B: TColor32; M: Cardinal);
    procedure CombineTerrainPhysicsPrepInternal(F: TColor32; var B: TColor32; M: Cardinal);

    // Graphical combines
    procedure CombineTerrainDefault(F: TColor32; var B: TColor32; M: Cardinal);
    procedure CombineTerrainNoOverwrite(F: TColor32; var B: TColor32; M: Cardinal);
    procedure CombineTerrainErase(F: TColor32; var B: TColor32; M: Cardinal);
    procedure CombineGadgetsDefault(F: TColor32; var B: TColor32; M: Cardinal);

    // Clear Physics combines
    procedure CombineLasererShadowToShadowLayer(F: TColor32; var B: TColor32; M: Cardinal);
    procedure CombineFixedColor(F: TColor32; var B: TColor32; M: Cardinal); // Use with fFixedDrawColor

    procedure PrepareTerrainBitmap(Bmp: TBitmap32; DrawingFlags: Byte);
    procedure PrepareTerrainBitmapForPhysics(Bmp: TBitmap32; DrawingFlags: Byte; IsSteel: Boolean);
    procedure PrepareGadgetBitmap(Bmp: TBitmap32; IsOnlyOnTerrain: Boolean; IsZombie: Boolean = False;
                                  IsNeutral: Boolean = False; IsRival: Boolean = False);

    procedure DrawTriggerAreaRectOnLayer(TriggerRect: TRect);

    function GetTerrainLayer: TBitmap32;
    function GetParticleLayer: TBitmap32;

    // Were sub-procedures or part of DrawAllObjects
    procedure DrawGadgetsOnLayer(aLayer: TRenderLayer);
    procedure ProcessDrawFrame(Gadget: TGadget; Dst: TBitmap32);
    procedure DrawTriggerArea(Gadget: TGadget);
    procedure DrawExitMarkers(Gadget: TGadget; aMarker: TBitmap32);
    procedure DrawUserHelper;
    procedure MakeColorCycle;
    function IsUseful(Gadget: TGadget): Boolean;

    procedure InternalDrawTerrain(Dst: TBitmap32; T: TTerrain; IsPhysicsDraw: Boolean; IsHighRes: Boolean);
    procedure PrepareCompositePieceBitmap(aTerrains: TTerrains; aDst: TBitmap32; aHighResolution: Boolean);

    function GetRecolorer: TRecolorImage;
    property Recolorer: TRecolorImage read GetRecolorer;
  protected
  public
    BrickPixelColors   : array[0..11] of TColor32; // Gradient steps - callable from LemGame

    constructor Create;
    destructor Destroy; override;

    procedure SetInterface(aInterface: TRenderInterface);

    procedure DrawLevel(aDst: TBitmap32; aClearPhysics: Boolean = False); overload;
    procedure DrawLevel(aDst: TBitmap32; aRegion: TRect; aClearPhysics: Boolean = False); overload;

    procedure LoadHelperImages;

    function FindGadgetMetaInfo(O: TGadgetModel): TGadgetMetaAccessor;
    function FindMetaTerrain(T: TTerrain): TMetaTerrain;

    procedure PrepareGameRendering(aLevel: TLevel; NoOutput: Boolean = False);
    procedure InitializeBrickColors(aBrickPixelColor: TColor32);

    // Composite pieces (terrain grouping)
    procedure PrepareCompositePieceBitmaps(aTerrains: TTerrains; aLowRes: TBitmap32; aHighRes: TBitmap32);

    // Terrain rendering
    procedure DrawTerrain(Dst: TBitmap32; T: TTerrain); overload;
    procedure DrawTerrain(Dst: TBitmap32; T: TTerrain; HighRes: Boolean); overload;

    // Object rendering
    procedure DrawAllGadgets(Gadgets: TGadgetList; DrawHelper: Boolean = True; UsefulOnly: Boolean = False);
    procedure DrawObjectHelpers(Dst: TBitmap32; Gadget: TGadget);
    procedure DrawHatchSkillHelpers(Dst: TBitmap32; Gadget: TGadget; DrawOtherHelper: Boolean);
    procedure DrawLemmingHelpers(Dst: TBitmap32; L: TLemming; IsClearPhysics: Boolean = True);

    // Lemming rendering
    procedure DrawLemmings(UsefulOnly: Boolean = False);
    procedure DrawLemmingLaser(aLemming: TLemming);
    procedure DrawThisLemming(aLemming: TLemming; UsefulOnly: Boolean = False);
    procedure DrawLemmingCountdown(aLemming: TLemming);
    procedure DrawLemmingParticles(L: TLemming);
    procedure DrawFreezingOverlay(L: TLemming);
    procedure DrawUnfreezingOverlay(L: TLemming);
    procedure DrawInvinciblityOverlay(L: TLemming);
    procedure DrawBalloonPop(L: TLemming);

    procedure DrawShadows(L: TLemming; SkillButton: TSkillPanelButton; SelectedSkill: TSkillPanelButton; IsCloneShadow: Boolean);
    procedure DrawJumperShadow(L: TLemming);
    procedure DrawBalloonerShadow(L: TLemming);
    procedure DrawGliderShadow(L: TLemming);
    procedure DrawShimmierShadow(L: TLemming);
    procedure DrawBuilderShadow(L: TLemming);
    procedure DrawLaddererShadow(L: TLemming);
    procedure DrawPlatformerShadow(L: TLemming);
    procedure DrawStackerShadow(L: TLemming);
    procedure DrawLasererShadow(L: TLemming);
    procedure DrawBasherShadow(L: TLemming);
    procedure DrawFencerShadow(L: TLemming);
    procedure DrawMinerShadow(L: TLemming);
    procedure DrawDiggerShadow(L: TLemming);
    //procedure DrawPropellerShadow(L: TLemming);  // Propeller
    procedure DrawExploderShadow(L: TLemming);
    procedure DrawFreezerShadow(L: TLemming);
    procedure DrawProjectileShadow(L: TLemming);
    procedure DrawProjectionShadow(L: TLemming); // Bookmark - need to remove associated code
    procedure ClearShadows;
    procedure SetLowShadowPixel(X, Y: Integer);
    procedure SetHighShadowPixel(X, Y: Integer);

    procedure DrawProjectiles;
    procedure DrawThisProjectile(P: TProjectile);

    procedure RenderWorld(World: TBitmap32; DoBackground: Boolean);
    procedure RenderPhysicsMap(Dst: TBitmap32 = nil);

    procedure CreateGadgetList(var Gadgets: TGadgetList);

    // Minimap
    procedure RenderMinimap(Dst: TBitmap32; LemmingsOnly: Boolean);
    procedure CombineMinimapPixels(F: TColor32; var B: TColor32; M: Cardinal);

    property PhysicsMap: TBitmap32 read fPhysicsMap;
    property BackgroundColor: TColor32 read fBgColor write fBgColor;
    property Theme: TNeoTheme read fTheme;
    property LemmingAnimations: TBaseAnimationSet read fAni;
    property IsFreezerExplosion: Boolean read fIsFreezerExplosion write fIsFreezerExplosion;

    property TerrainLayer: TBitmap32 read GetTerrainLayer; // For save state purposes
    property ParticleLayer: TBitmap32 read GetParticleLayer; // Needs to be replaced with making TRenderer draw them

    property TransparentBackground: Boolean read fTransparentBackground write fTransparentBackground;
  end;

implementation

uses
  LemGame, FMain,
  GameControl;

{ TRenderer }

procedure TRenderer.SetInterface(aInterface: TRenderInterface);
begin
  fRenderInterface := aInterface;
  fRenderInterface.SetDrawRoutineBrick(AddTerrainPixel);
  fRenderInterface.SetDrawRoutineFreezer(AddFreezer);
  fRenderInterface.SetDrawRoutineSpear(AddSpear);
  fRenderInterface.SetRemoveRoutine(ApplyRemovedTerrain);
end;

// Minimap drawing

procedure TRenderer.RenderMinimap(Dst: TBitmap32; LemmingsOnly: Boolean);
var
  OldCombine: TPixelCombineEvent;
  OldMode: TDrawMode;

  i: Integer;
  L: TLemming;
begin
  if not GameParams.ShowMinimap then Exit;

  if fRenderInterface.DisableDrawing then Exit;

  if not LemmingsOnly then
  begin
    Dst.Clear(fTheme.Colors[BACKGROUND_COLOR]);
    OldCombine := fPhysicsMap.OnPixelCombine;
    OldMode := fPhysicsMap.DrawMode;

    fPhysicsMap.DrawMode := dmCustom;
    fPhysicsMap.OnPixelCombine := CombineMinimapPixels;

    fPhysicsMap.DrawTo(Dst, Dst.BoundsRect, fPhysicsMap.BoundsRect);

    fPhysicsMap.OnPixelCombine := OldCombine;
    fPhysicsMap.DrawMode := OldMode;
  end;

  if fRenderInterface = nil then Exit;
  if fRenderInterface.LemmingList = nil then Exit;

  for i := 0 to fRenderInterface.LemmingList.Count-1 do
  begin
    L := fRenderInterface.LemmingList[i];
  if L.LemRemoved then Continue;
  if L.LemIsZombie then
    begin
      Dst.PixelS[L.LemX div 4, L.LemY div 4] := $FFFF0000;
      Dst.PixelS[L.LemX div 4 + 1, L.LemY div 4] := $FFFF0000;
      Dst.PixelS[L.LemX div 4, L.LemY div 4 + 1] := $FFFF0000;
      Dst.PixelS[L.LemX div 4 + 1, L.LemY div 4 + 1] := $FFFF0000;
    end else begin
      Dst.PixelS[L.LemX div 4, L.LemY div 4] := $FF00FF00;
      Dst.PixelS[L.LemX div 4 + 1, L.LemY div 4] := $FF00FF00;
      Dst.PixelS[L.LemX div 4, L.LemY div 4 + 1] := $FF00FF00;
      Dst.PixelS[L.LemX div 4 + 1, L.LemY div 4 + 1] := $FF00FF00;
    end;
  end;
end;

procedure TRenderer.CombineMinimapPixels(F: TColor32; var B: TColor32; M: Cardinal);
begin
  if not GameParams.ShowMinimap then Exit;

  if (F and PM_SOLID) <> 0 then
  begin
    if GameParams.AmigaTheme then
      B := $FF008800
    else                                // Ensures full opacity
      B := fTheme.Colors[MINIMAP_COLOR] or $FF000000;
  end;
end;

// Lemming Drawing

procedure TRenderer.DrawLemmings(UsefulOnly: Boolean = False);
var
  i: Integer;
  SelectedLemming, HighlitLemming: TLemming;
  LemmingList: TLemmingList;
begin
  if not fLayers.fIsEmpty[rlParticles] then fLayers[rlParticles].Clear(0);
  if not fLayers.fIsEmpty[rlCountdown] then fLayers[rlCountdown].Clear(0);
  if not fLayers.fIsEmpty[rlLemmingsLow] then fLayers[rlLemmingsLow].Clear(0);
  if not fLayers.fIsEmpty[rlLemmingsHigh] then fLayers[rlLemmingsHigh].Clear(0);

  LemmingList := fTempLemmingList;
  LemmingList.Clear;

  for i := 0 to fRenderInterface.LemmingList.Count-1 do
    LemmingList.Add(fRenderInterface.LemmingList[i]);

  SelectedLemming := fRenderInterface.SelectedLemming;
  HighlitLemming := fRenderInterface.HighlitLemming;

  LemmingList.SortList(
    function (rA, rB: Pointer): Integer
    var
      A: TLemming absolute rA;
      B: TLemming absolute rB;
    const
      RIVAL_LEMMING = 512;
      SELECTED_LEMMING = 128;
      NOT_EXITER_LEMMING = 64;
      HIGHLIT_LEMMING = 32;
      NOT_ZOMBIE_LEMMING = 16;
      NOT_NEUTRAL_LEMMING = 8;
      PERMANENT_SKILL_LEMMING = 4;

      function MakePriorityValue(L: TLemming): Integer;
      begin
        Result := 0;
        if L = SelectedLemming then Result := Result + SELECTED_LEMMING;
        if not (L.LemAction = baExiting) then Result := Result + NOT_EXITER_LEMMING;
        if L = HighlitLemming then Result := Result + HIGHLIT_LEMMING;
        if (not L.LemIsNeutral) or (L.LemIsZombie) then Result := Result + NOT_NEUTRAL_LEMMING;
        if not L.LemIsZombie then Result := Result + NOT_ZOMBIE_LEMMING;
        if L.HasPermanentSkills then Result := Result + PERMANENT_SKILL_LEMMING;
      end;
    begin
      Result := MakePriorityValue(A) - MakePriorityValue(B);
    end
  );

  // Draw particles for exploding lemmings, laser for laserers
  fLayers.fIsEmpty[rlParticles] := True;
  fLayers.fIsEmpty[rlCountdown] := True;

  for i := 0 to LemmingList.Count-1 do
  begin
    if LemmingList[i].LemParticleTimer > 0 then
    begin
      DrawLemmingParticles(LemmingList[i]);
      fLayers.fIsEmpty[rlParticles] := False;
    end;

    if (((LemmingList[i].LemFreezerExplosionTimer > 0)
      or (LemmingList[i].LemExplosionTimer > 0)) and not LemmingList[i].LemHideCountdown)
      or (LemmingList[i] = fRenderInterface.HighlitLemming) then
    begin
      DrawLemmingCountdown(LemmingList[i]);
      fLayers.fIsEmpty[rlCountdown] := False;
    end;

    if LemmingList[i].LemIsInvincible then
    begin
      DrawInvinciblityOverlay(LemmingList[i]);
      fLayers.fIsEmpty[rlCountdown] := False;
    end;

   if (LemmingList[i].LemAction = baLasering) and not (LemmingList[i].LemRemoved or LemmingList[i].LemTeleporting
   // or (LemmingList[i].LemPortalWarpFrame > 0) // Portals - NOT YET IMPLEMENTED IN SLX
   ) then
      DrawLemmingLaser(LemmingList[i]);

    if LemmingList[i].LemAction = baFreezing then
      DrawFreezingOverlay(LemmingList[i]);

    if LemmingList[i].LemAction = baUnfreezing then
      DrawUnfreezingOverlay(LemmingList[i]);

    DrawBalloonPop(LemmingList[i]);
  end;

  for i := 0 to LemmingList.Count-1 do
    DrawThisLemming(LemmingList[i], UsefulOnly);
end;

procedure TRenderer.DrawThisLemming(aLemming: TLemming; UsefulOnly: Boolean = False);
var
  SrcRect, DstRect: TRect;
  SrcAnim: TBitmap32;
  SrcMetaAnim: TMetaLemmingAnimation;
  TriggerRect: TRect;
  TriggerLeft, TriggerTop: Integer;
  i: Integer;

  Selected, Highlit: Boolean;

  function GetFrameBounds: TRect;
  begin
    with Result do
    begin
      Left := 0;
      Top := aLemming.LemFrame * SrcMetaAnim.Height;
      Right := SrcMetaAnim.Width;
      Bottom := Top + SrcMetaAnim.Height;
    end;
  end;

  function GetLocationBounds: TRect;
  begin
    with Result do
    begin
      Left := (aLemming.LemX * ResMod) - SrcMetaAnim.FootX;
      Top := (aLemming.LemY * ResMod) - SrcMetaAnim.FootY;
      Right := Left + SrcMetaAnim.Width;
      Bottom := Top + SrcMetaAnim.Height;
    end;
  end;

  procedure DrawLemmingPoint;
  var
    bX, bY: Integer;
    xo, yo: Integer;
  begin
    bX := aLemming.LemX * ResMod;
    bY := aLemming.LemY * ResMod;

    for yo := 0 to ResMod-1 do
      for xo := 0 to ResMod-1 do
      begin
        fLayers[rlTriggers].PixelS[bX + xo, bY + yo] := $FFFFD700;
        fLayers[rlTriggers].PixelS[bX + xo + ResMod, bY + yo] := $FFFF4500;
        fLayers[rlTriggers].PixelS[bX + xo - ResMod, bY + yo] := $FFFF4500;
        fLayers[rlTriggers].PixelS[bX + xo, bY + yo + ResMod] := $FFFF4500;
        fLayers[rlTriggers].PixelS[bX + xo, bY + yo - ResMod] := $FFFF4500;
      end;
  end;

begin
  if aLemming.LemRemoved then Exit;
  if aLemming.LemTeleporting then Exit;

  if fRenderInterface <> nil then
  begin
    Selected := aLemming = fRenderInterface.SelectedLemming;
    Highlit := aLemming = fRenderInterface.HighlitLemming;
  end else begin
    Selected := False;
    Highlit := False;
  end;

  UsefulOnly := UsefulOnly and Selected; // Not sure why this is needed. Probably "UsefulOnly" is a bad variable name.

  Recolorer.Lemming := aLemming;
  Recolorer.DrawAsSelected := Selected or Highlit;
  Recolorer.ClearPhysics := fUsefulOnly;

  // Get the animation and meta-animation
  if aLemming.LemDX > 0 then
    i := AnimationIndices[aLemming.LemAction, False]
  else
    i := AnimationIndices[aLemming.LemAction, True];

  // Get the alternative Walker sprite for Zombies
  if aLemming.LemIsZombie and (aLemming.LemAction in [baWalking, baFalling]) then
  begin
    if aLemming.LemDX > 0 then
    i := AnimationIndices[baZombieWalking, False]
  else
    i := AnimationIndices[baZombieWalking, True];
  end;

//  // Get the alternative Jumper sprite for Ballers
//  if aLemming.LemIsBaller and (aLemming.LemAction in [baJumping]) then
//  begin
//    if aLemming.LemDX > 0 then
//    i := AnimationIndices[baBalling, False]
//  else
//    i := AnimationIndices[baBalling, True];
//  end;

  SrcAnim := fAni.LemmingAnimations[i];
  SrcMetaAnim := fAni.MetaLemmingAnimations[i];

  if aLemming.LemMaxFrame = -1 then
  begin
    aLemming.LemMaxFrame := SrcMetaAnim.FrameCount - 1;
    aLemming.LemFrameDiff := SrcMetaAnim.FrameDiff;
  end;

  if (aLemming.LemAction = baJumping) then
  begin
    case aLemming.LemJumpProgress of
      0..6: if aLemming.LemFrame >= aLemming.LemMaxFrame - aLemming.LemFrameDiff then aLemming.LemFrame := 0;
      7: aLemming.LemFrame := aLemming.LemMaxFrame - aLemming.LemFrameDiff + 1;
      8..12: if aLemming.LemFrame > aLemming.LemMaxFrame then aLemming.LemFrame := aLemming.LemMaxFrame - aLemming.LemFrameDiff + 2;
    end;
  end else
    while aLemming.LemFrame > aLemming.LemMaxFrame do
      Dec(aLemming.LemFrame, aLemming.LemFrameDiff);

  SrcRect := GetFrameBounds;
  DstRect := GetLocationBounds;
  SrcAnim.DrawMode := dmCustom;
  SrcAnim.OnPixelCombine := Recolorer.CombineLemmingPixels;

  // Swimmer-Blockers are drawn behind all objects
  if (aLemming.LemAction = baBlocking) and aLemming.LemIsWaterblocker then
  begin
    if fLayers.fIsEmpty[rlDecorations] then
      fLayers.fIsEmpty[rlDecorations] := False;

    SrcAnim.DrawTo(fLayers[rlDecorations], DstRect, SrcRect);
  end else
  // Frozen lems are drawn behind terrain
  if aLemming.LemAction = baFrozen then
  begin
    if fLayers.fIsEmpty[rlGadgetsLow] then
      fLayers.fIsEmpty[rlGadgetsLow] := False;

    SrcAnim.DrawTo(fLayers[rlGadgetsLow], DstRect, SrcRect);
  end else
  // Explosion states are drawn behind other lems
  if aLemming.LemAction in [baFreezing, baFrozen, baUnfreezing,
                            baFreezerExplosion, baOhNoing, baExploding,
                            baTimebombing, baTimebombFinish] then
    SrcAnim.DrawTo(fLayers[rlLemmingsLow], DstRect, SrcRect)
  else
    SrcAnim.DrawTo(fLayers[rlLemmingsHigh], DstRect, SrcRect);

  // Helper for selected lemming
  if (Selected and aLemming.CannotReceiveSkills) or UsefulOnly or
     ((fRenderInterface <> nil) and fRenderInterface.IsStartingSeconds) then
  begin
    if not GameParams.HideHelpers then DrawLemmingHelpers(fLayers[rlObjectHelpers], aLemming, UsefulOnly);
    fLayers.fIsEmpty[rlObjectHelpers] := False;
  end;

  // Draw blocker areas on the triggerLayer
  if (aLemming.LemAction = baBlocking) and (aLemming.LemHasBlockerField) then
  begin
    TriggerLeft := aLemming.LemX - 6;
    if (aLemming.LemDX = 1) then Inc(TriggerLeft);
    TriggerTop := aLemming.LemY - 6;
    TriggerRect := Rect(TriggerLeft, TriggerTop, TriggerLeft + 4, TriggerTop + 11);
    DrawTriggerAreaRectOnLayer(TriggerRect);
    TriggerRect := Rect(TriggerLeft + 8, TriggerTop, TriggerLeft + 12, TriggerTop + 11);
    DrawTriggerAreaRectOnLayer(TriggerRect);
  end;

  // Draw lemming
  if Selected then
  begin
    DrawLemmingPoint;
    fLayers.fIsEmpty[rlTriggers] := False;
  end;
end;

procedure TRenderer.DrawLemmingLaser(aLemming: TLemming);
var
  LaserColors: array[0..4] of TColor32;
  Origin, Target: TPoint;

  Src, Dst: TRect;
  n, CIndex: Integer;
const
  RED_COLOR = $FFF01818;
  WHITE_COLOR = $FFF0F0F0;
  YELLOW_COLOR = $FFF0F018;

  BLAST_COLORS: array[0..2] of TColor32 =
    ( $00000000, RED_COLOR, YELLOW_COLOR );
begin
  Origin := Point(aLemming.LemX + aLemming.LemDX, aLemming.LemY - 4);
  Target := aLemming.LemLaserHitPoint;

  if GameParams.HighResolution then
  begin
    Origin.X := Origin.X * 2;
    Origin.Y := Origin.Y * 2;
    Target.X := Target.X * 2;
    Target.Y := Target.Y * 2;

    if aLemming.LemDX > 0 then
    begin
      Origin.X := Origin.X - 1;
      Target.X := Target.X + 1;
    end else
      Origin.X := Origin.X + 2;

    Origin.Y := Origin.Y + 2;


    LaserColors[0] := WHITE_COLOR;

    case aLemming.LemPhysicsFrame mod 4 of
      0, 2:
        begin
          LaserColors[1] := WHITE_COLOR;
          LaserColors[2] := RED_COLOR;
          LaserColors[3] := RED_COLOR;
          LaserColors[4] := $00000000;
        end;

      1:
        begin
          LaserColors[1] := WHITE_COLOR;
          LaserColors[2] := WHITE_COLOR;
          LaserColors[3] := RED_COLOR;
          LaserColors[4] := RED_COLOR;
        end;

      3:
        begin
          LaserColors[1] := RED_COLOR;
          LaserColors[2] := RED_COLOR;
          LaserColors[3] := $00000000;
          LaserColors[4] := $00000000;
        end;
    end;

    fLayers[rlLemmingsHigh].LineS(Origin.X, Origin.Y,
      Target.X, Target.Y,
      LaserColors[0], True);
    fLayers[rlLemmingsHigh].LineS(Origin.X, Origin.Y - 1,
      Target.X - aLemming.LemDX, Target.Y,
      LaserColors[0], True);
    fLayers[rlLemmingsHigh].LineS(Origin.X + aLemming.LemDX, Origin.Y,
      Target.X, Target.Y + 1,
      LaserColors[0], True);
    fLayers[rlLemmingsHigh].LineS(Origin.X, Origin.Y - 2,
      Target.X - (aLemming.LemDX * 2), Target.Y,
      LaserColors[1], True);
    fLayers[rlLemmingsHigh].LineS(Origin.X + (aLemming.LemDX * 2), Origin.Y,
      Target.X, Target.Y + 2,
      LaserColors[1], True);
    fLayers[rlLemmingsHigh].LineS(Origin.X, Origin.Y - 3,
      Target.X - (aLemming.LemDX * 3), Target.Y,
      LaserColors[2], True);
    fLayers[rlLemmingsHigh].LineS(Origin.X + (aLemming.LemDX * 3), Origin.Y,
      Target.X, Target.Y + 3,
      LaserColors[2], True);
    fLayers[rlLemmingsHigh].LineS(Origin.X, Origin.Y - 4,
      Target.X - (aLemming.LemDX * 4), Target.Y,
      LaserColors[3], True);
    fLayers[rlLemmingsHigh].LineS(Origin.X + (aLemming.LemDX * 4), Origin.Y,
      Target.X, Target.Y + 4,
      LaserColors[3], True);
    fLayers[rlLemmingsHigh].LineS(Origin.X, Origin.Y - 5,
      Target.X - (aLemming.LemDX * 5), Target.Y,
      LaserColors[4], True);
    fLayers[rlLemmingsHigh].LineS(Origin.X + (aLemming.LemDX * 5), Origin.Y,
      Target.X, Target.Y + 5,
      LaserColors[4], True);
  end else begin

    LaserColors[0] := WHITE_COLOR;

    case aLemming.LemPhysicsFrame mod 4 of
      0, 1:
        begin
          LaserColors[1] := RED_COLOR;
          LaserColors[2] := $00000000;
        end;

      2, 3:
        begin
          LaserColors[1] := WHITE_COLOR;
          LaserColors[2] := RED_COLOR;
        end;
    end;

    // LaserColors[3] and [4] are unused in low-res

    fLayers[rlLemmingsHigh].LineS(Origin.X, Origin.Y,
      Target.X, Target.Y,
      LaserColors[0], True);
    fLayers[rlLemmingsHigh].LineS(Origin.X, Origin.Y - 1,
      Target.X - aLemming.LemDX, Target.Y,
      LaserColors[1], True);
    fLayers[rlLemmingsHigh].LineS(Origin.X + aLemming.LemDX, Origin.Y,
      Target.X, Target.Y + 1,
      LaserColors[1], True);
    fLayers[rlLemmingsHigh].LineS(Origin.X, Origin.Y - 2,
      Target.X - (aLemming.LemDX * 2), Target.Y,
      LaserColors[2], True);
    fLayers[rlLemmingsHigh].LineS(Origin.X + (aLemming.LemDX * 2), Origin.Y,
      Target.X, Target.Y + 2,
      LaserColors[2], True);
  end;

  if aLemming.LemLaserHit then
  begin
    Target := aLemming.LemLaserHitPoint; // Undo high-res modifications from above, if any

    Src := Rect(48, 0, 61, 13);
    Dst := Rect(Target.X - 6, Target.Y - 6, Target.X + 6 + 1, Target.Y + 6 + 1);

    if GameParams.HighResolution then
    begin
      Src.Left := Src.Left * 2;
      Src.Top := Src.Top * 2;
      Src.Right := Src.Right * 2;
      Src.Bottom := Src.Bottom * 2;

      Dst.Left := Dst.Left * 2;
      Dst.Top := Dst.Top * 2;
      Dst.Right := Dst.Right * 2;
      Dst.Bottom := Dst.Bottom * 2;
    end;

    CIndex := aLemming.LemPhysicsFrame mod 3;
    for n := 0 to 2 do
    begin
      if BLAST_COLORS[CIndex] <> $00000000 then
      begin
        fFixedDrawColor := BLAST_COLORS[CIndex];
        fLaserGraphic.DrawTo(fLayers[rlLemmingsHigh], Dst, Src);
      end;

      MoveRect(Src, -13 * ResMod, 0);

      repeat
        CIndex := (CIndex + 1) mod 3;
      until BLAST_COLORS[CIndex] <> $00000000;
    end;

    fFixedDrawColor := WHITE_COLOR;
    fLaserGraphic.DrawTo(fLayers[rlLemmingsHigh], Dst, Src);
  end;
end;

procedure TRenderer.DrawInvinciblityOverlay(L: TLemming);
var
  FrameIndex, TickCount, YOffset: Integer;
  FrameRect: TRect;
begin
  TickCount := GetTickCount;
  FrameIndex := (TickCount div 100) mod 8;

  FrameRect.Left := 0;
  FrameRect.Right := FrameRect.Left + 16 * ResMod;
  FrameRect.Top := FrameIndex * (16 * ResMod);
  FrameRect.Bottom := FrameRect.Top + (16 * ResMod);

  YOffset := 16;

  // Only draw half the image for swimmers
  if L.LemAction = baSwimming then
  begin
    FrameRect.Top := FrameRect.Top + (10 * ResMod);
    YOffset := 4;
  end;

  if L.LemDX < 0 then
    fAni.InvincibilityOverlay.DrawTo(fLayers[rlCountdown], (L.LemX - 8) * ResMod, (L.LemY - YOffset) * ResMod, FrameRect)
  else
    fAni.InvincibilityOverlay.DrawTo(fLayers[rlCountdown], (L.LemX - 7) * ResMod, (L.LemY - YOffset) * ResMod, FrameRect);
end;

procedure TRenderer.DrawFreezingOverlay(L: TLemming);
var
FrameIndex: Integer;
FrameRect: TRect;
begin
  FrameIndex := (8 - L.LemFreezingTimer) mod 8;

  FrameRect.Left := 0;
  FrameRect.Right := FrameRect.Left + 16 * ResMod;
  FrameRect.Top := FrameIndex * (10 * ResMod);
  FrameRect.Bottom := FrameRect.Top + (10 * ResMod);

  if L.LemDX < 0 then
    fAni.FreezingOverlay.DrawTo(fLayers[rlLemmingsHigh], (L.LemX - 8) * ResMod, (L.LemY - 10) * ResMod, FrameRect)
  else
    fAni.FreezingOverlay.DrawTo(fLayers[rlLemmingsHigh], (L.LemX - 7) * ResMod, (L.LemY - 10) * ResMod, FrameRect);
end;

procedure TRenderer.DrawUnfreezingOverlay(L: TLemming);
var
FrameIndex: Integer;
FrameRect: TRect;
begin
  FrameIndex := (12 - L.LemUnfreezingTimer) mod 12;

  FrameRect.Left := 0;
  FrameRect.Right := FrameRect.Left + 16 * ResMod;
  FrameRect.Top := FrameIndex * (10 * ResMod);
  FrameRect.Bottom := FrameRect.Top + (10 * ResMod);

  if L.LemDX < 0 then
    fAni.UnfreezingOverlay.DrawTo(fLayers[rlLemmingsHigh], (L.LemX - 8) * ResMod, (L.LemY - 10) * ResMod, FrameRect)
  else
    fAni.UnfreezingOverlay.DrawTo(fLayers[rlLemmingsHigh], (L.LemX - 7) * ResMod, (L.LemY - 10) * ResMod, FrameRect);
end;

procedure TRenderer.DrawBalloonPop(L: TLemming);
var
  FrameRect: TRect;
begin
  if L.LemBalloonPopTimer > 0 then
  begin
    FrameRect.Left := 0;
    FrameRect.Right := FrameRect.Left + (48 * ResMod);
    FrameRect.Top := 0;
    FrameRect.Bottom := FrameRect.Top + (54 * ResMod);

    if L.LemDX < 0 then      // In front of terrain, and behind all lems except Freezers
      fAni.BalloonPopBitmap.DrawTo(fLayers[rlLemmingsLow], (L.LemX - 27) * ResMod, (L.LemY - 53) * ResMod, FrameRect)
    else
      fAni.BalloonPopBitmap.DrawTo(fLayers[rlLemmingsLow], (L.LemX - 26) * ResMod, (L.LemY - 53) * ResMod, FrameRect);
  end;
end;

// Draws countdown for associated actions (Timebomber, Nuke, Slowfreeze/Radiation)
procedure TRenderer.DrawLemmingCountdown(aLemming: TLemming);
var
  Countdown: TBitmap32;
  ShowCountdown, ShowHighlight: Boolean;
  SrcRect: TRect;
  n, tensDigit, onesDigit: Integer;
  xPos: Integer;
begin
  if aLemming.LemRemoved then Exit;

  if aLemming.LemIsRadiating then
    Countdown := fAni.RadiationDigitsBitmap
  else if (aLemming.LemFreezerExplosionTimer > 0) then
    Countdown := fAni.SlowfreezeDigitsBitmap
  else
    Countdown := fAni.CountDownDigitsBitmap;

  ShowCountdown := ((aLemming.LemFreezerExplosionTimer > 0)
                 or (aLemming.LemExplosionTimer > 0))
             and not aLemming.LemHideCountdown;
  ShowHighlight := (aLemming = fRenderInterface.HighlitLemming);

  if ShowCountdown and ShowHighlight then
    ShowCountdown := (GetTickCount mod 1000 < 500);

  if ShowCountdown then
  begin
    if aLemming.LemExplosionTimer > 0 then
      n := (aLemming.LemExplosionTimer div 17) + 1
    else if aLemming.LemFreezerExplosionTimer > 0 then
      n := (aLemming.LemFreezerExplosionTimer div 17) + 1
    else
      n := 0; // Should never happen

    // Extract tens and ones digit from n
    tensDigit := n div 10;
    onesDigit := n mod 10;

    // Calculate X-coordinate for drawing
    if tensDigit = 0 then
    begin
      if aLemming.LemDX < 0 then
        xPos := (aLemming.LemX - 3) * ResMod  // Center single-digit for left-facing lem
      else
        xPos := (aLemming.LemX - 2) * ResMod; // Center single-digit
    end else if tensDigit = 1 then
    begin
      if aLemming.LemDX < 0 then
        xPos := (aLemming.LemX - 6) * ResMod  // Center "1"-leading double-digit for left-facing lem
      else
        xPos := (aLemming.LemX - 5) * ResMod; // Center "1"-leading double-digit
    end else if aLemming.LemDX < 0 then
        xPos := (aLemming.LemX - 7) * ResMod  // Center all other double-digits for left-facing lem
      else
        xPos := (aLemming.LemX - 6) * ResMod; // Center all other double-digits

    // Draw tens digit
    if tensDigit <> 0 then
    begin
      SrcRect := SizedRect(tensDigit * 6 * ResMod, 0, 6 * ResMod, 5 * ResMod);

      Countdown.DrawTo(fLayers[rlCountdown], xPos, (aLemming.LemY - 17) * ResMod, SrcRect);

      if tensDigit = 1 then
        Inc(xPos, 6 * ResMod)
      else
        Inc(xPos, 7 * ResMod); // Nudge the second digit across, add 1px space
    end;

    // Draw ones digit
    SrcRect := SizedRect(onesDigit * 6 * ResMod, 0, 6 * ResMod, 5 * ResMod);

    Countdown.DrawTo(fLayers[rlCountdown], xPos, (aLemming.LemY - 17) * ResMod, SrcRect);
  end else if ShowHighlight then
    fAni.HighlightBitmap.DrawTo(fLayers[rlCountdown], (aLemming.LemX - 2) * ResMod, (aLemming.LemY - 20) * ResMod);
end;

procedure TRenderer.DrawLemmingParticles(L: TLemming);
var
  i, X, Y: Integer;
begin

  for i := 0 to 79 do
  begin
    X := fParticles[PARTICLE_FRAMECOUNT - L.LemParticleTimer][i].DX;
    Y := fParticles[PARTICLE_FRAMECOUNT - L.LemParticleTimer][i].DY;
    if (X <> -128) and (Y <> -128) then
    begin
      X := L.LemX + X;
      Y := L.LemY + Y;
      if fIsFreezerExplosion then
        fLayers[rlParticles].PixelS[X, Y] := PARTICLE_FREEZER_COLORS[i mod 8]
      else
        fLayers[rlParticles].PixelS[X, Y] := PARTICLE_COLORS[i mod 8];
    end;
  end;

end;

function TRenderer.GetTerrainLayer: TBitmap32;
begin
  Result := fLayers[rlTerrain];
end;

function TRenderer.GetParticleLayer: TBitmap32;
begin
  Result := fLayers[rlParticles];
end;

function TRenderer.GetRecolorer: TRecolorImage;
begin
  Result := fAni.Recolorer;
end;

procedure TRenderer.DrawLevel(aDst: TBitmap32; aClearPhysics: Boolean = False);
var
  aRegionRect: TRect;
begin
  aRegionRect := fPhysicsMap.BoundsRect;

  aRegionRect := Rect(aRegionRect.Left * ResMod, aRegionRect.Top * ResMod,
                      aRegionRect.Right * ResMod, aRegionRect.Bottom * ResMod);

  DrawLevel(aDst, aRegionRect, aClearPhysics);
end;

procedure TRenderer.DrawLevel(aDst: TBitmap32; aRegion: TRect; aClearPhysics: Boolean = False);
begin
  fLayers.PhysicsMap := fPhysicsMap; // Can we assign this just once somewhere? very likely.
  if PtInRect(fPhysicsMap.BoundsRect, fRenderInterface.MousePos) then
    fLayers.OneWayHighlightBit := fPhysicsMap[fRenderInterface.MousePos.X, fRenderInterface.MousePos.Y] and PM_ONEWAYFLAGS
  else
    fLayers.OneWayHighlightBit := 0;
  fLayers.CombineTo(aDst, aRegion, aClearPhysics);
end;

procedure TRenderer.ApplyRemovedTerrain(X, Y, W, H: Integer);
var
  PhysicsArrPtr, TerrLayerArrPtr: PColor32Array;
  cx, cy: Integer;
  MapWidth: Integer; // Width of the total PhysicsMap
begin
  // This has two applications:
  // - Removing all non-solid pixels from rlTerrain (possibly created by blending)
  // - Removed pixels from PhysicsMap copied to rlTerrain (called when applying a mask from LemGame via RenderInterface)

  PhysicsArrPtr := PhysicsMap.Bits;
  TerrLayerArrPtr := fLayers[rlTerrain].Bits;

  MapWidth := PhysicsMap.Width;

  for cy := Y to (Y+H-1) do
  begin
    if cy < 0 then Continue;
    if cy >= PhysicsMap.Height then Break;
    for cx := X to (X+W-1) do
    begin
      if cx < 0 then Continue;
      if cx >= MapWidth then Break;
      
      if PhysicsArrPtr[cy * MapWidth + cx] and PM_SOLID = 0 then
      begin
        if GameParams.HighResolution then
        begin
          TerrLayerArrPtr[(cy * MapWidth * 4) + (cx * 2)] := 0;
          TerrLayerArrPtr[(cy * MapWidth * 4) + (cx * 2) + 1] := 0;
          TerrLayerArrPtr[((cy * 2) + 1) * (MapWidth * 2) + (cx * 2)] := 0;
          TerrLayerArrPtr[((cy * 2) + 1) * (MapWidth * 2) + (cx * 2) + 1] := 0;

        end else
          TerrLayerArrPtr[cy * MapWidth + cx] := 0;
      end;
    end;
  end;
end;

procedure TRenderer.DrawShadows(L: TLemming; SkillButton: TSkillPanelButton;
  SelectedSkill: TSkillPanelButton; IsCloneShadow: Boolean);
var
  CopyL: TLemming;

  DoProjection: Boolean;
const
                                                               // Propeller    // Batter
  PROJECTION_STATES = [baWalking, baAscending, baLaddering, // baPropelling, Batting is not included
                       baDigging, baClimbing, baHoisting, baBuilding, baBashing,
                       baMining, baFalling, baFloating, baShrugging, baPlatforming,
                       baStacking, baSwimming, baGliding, baFixing, baFencing,
                       baReaching, baShimmying, baTurning, baJumping, baBallooning,
                       baDehoisting, baSliding, baDangling, baLasering, baLooking];
begin
  // Copy L to simulate the path
  CopyL := TLemming.Create;
  CopyL.Assign(L);

  if (fRenderInterface.ProjectionType <> 0) and
     ((L.LemAction in PROJECTION_STATES) or
        ((L.LemAction = baDrowning) and (fRenderInterface.ProjectionType = 2) and
          (SelectedSkill = spbSwimmer))) then
  begin
    DoProjection := True;

    if IsCloneShadow and (fRenderInterface.ProjectionType = 1) then
      DoProjection := False;

    if (fRenderInterface.ProjectionType = 2) then
    begin
      case SelectedSkill of
        spbWalker: if CopyL.LemAction = baWalking then
                     CopyL.LemDX := -CopyL.LemDX
                   else
                     fRenderInterface.SimulateTransitionLem(CopyL, baToWalking);
        spbShimmier: fRenderInterface.SimulateTransitionLem(CopyL, baReaching);
        spbSlider: CopyL.LemIsSlider := True;
        spbClimber: CopyL.LemIsClimber := True;
        spbSwimmer: CopyL.LemIsSwimmer := True;
        spbFloater: CopyL.LemIsFloater := True;
        spbGlider: CopyL.LemIsGlider := True;
        spbDisarmer: CopyL.LemIsDisarmer := True;
        spbBomber: DoProjection := False;
        spbFreezer: DoProjection := False;
        spbBlocker: DoProjection := False;
        spbCloner: CopyL.LemDX := -CopyL.LemDX;
        spbNone: ; // Do nothing
        else fRenderInterface.SimulateTransitionLem(CopyL, SkillPanelButtonToAction[SelectedSkill]);
      end;
    end;

    if DoProjection then
    begin
      DrawProjectionShadow(CopyL);

      CopyL.Assign(L); // Reset to initial state
    end;
  end else
    DoProjection := False;

  if (not GameParams.HideShadows) or fUsefulOnly then
  begin
    case SkillButton of
    spbJumper:
      if not DoProjection then
      begin
        fRenderInterface.SimulateTransitionLem(CopyL, baJumping);
        DrawJumperShadow(CopyL);
      end;

    spbBallooner:
      if not DoProjection then
      begin
        fRenderInterface.SimulateTransitionLem(CopyL, baBallooning);
        DrawBalloonerShadow(CopyL);
      end;

    spbShimmier:
      if not DoProjection then
      begin
        if CopyL.LemAction in [baJumping, baDangling, baTurning] then
          fRenderInterface.SimulateTransitionLem(CopyL, baShimmying)
        else
          fRenderInterface.SimulateTransitionLem(CopyL, baReaching);
        DrawShimmierShadow(CopyL);
      end;

    spbBuilder:
      begin
        fRenderInterface.SimulateTransitionLem(CopyL, baBuilding);
        DrawBuilderShadow(CopyL);
      end;

    spbLadderer:
      begin
        fRenderInterface.SimulateTransitionLem(CopyL, baLaddering);
        DrawLaddererShadow(CopyL);
      end;

    spbPlatformer:
      begin
        fRenderInterface.SimulateTransitionLem(CopyL, baPlatforming);
        DrawPlatformerShadow(CopyL);
      end;

    spbStacker:
      begin
        fRenderInterface.SimulateTransitionLem(CopyL, baStacking);
        DrawStackerShadow(CopyL);
      end;

    spbDigger:
      begin
        fRenderInterface.SimulateTransitionLem(CopyL, baDigging);
        DrawDiggerShadow(CopyL);
      end;

    spbMiner:
      begin
        fRenderInterface.SimulateTransitionLem(CopyL, baMining);
        DrawMinerShadow(CopyL);
      end;

    spbBasher:
      begin
        fRenderInterface.SimulateTransitionLem(CopyL, baBashing);
        DrawBasherShadow(CopyL);
      end;

    spbFencer:
      begin
        fRenderInterface.SimulateTransitionLem(CopyL, baFencing);
        DrawFencerShadow(CopyL);
      end;

    spbBomber:
      begin
        DrawExploderShadow(CopyL);
      end;

    spbFreezer:
      begin
        DrawFreezerShadow(CopyL);
      end;

    spbGlider:
      if not DoProjection then
      begin
        CopyL.LemIsGlider := True;
        DrawGliderShadow(CopyL);
      end;

    spbCloner:
      begin
        CopyL.LemDX := -CopyL.LemDX;
        DrawShadows(CopyL, ActionToSkillPanelButton[CopyL.LemAction], SelectedSkill, True);
      end;

    spbSpearer:
      begin
        fRenderInterface.SimulateTransitionLem(CopyL, baSpearing);
        DrawProjectileShadow(CopyL);
      end;

    spbGrenader:
      begin
        fRenderInterface.SimulateTransitionLem(CopyL, baGrenading);
        DrawProjectileShadow(CopyL);
      end;

//    spbPropeller: // Propeller
//      begin
//        fRenderInterface.SimulateTransitionLem(CopyL, baPropelling);
//        DrawPropellerShadow(CopyL);
//      end;

    spbLaserer:
      begin
        fRenderInterface.SimulateTransitionLem(CopyL, baLasering);
        DrawLasererShadow(CopyL);
      end;
    end;
  end;

  CopyL.Free;
end;

procedure TRenderer.DrawProjectiles;
var
  i: Integer;
begin
  for i := 0 to fRenderInterface.ProjectileList.Count-1 do
    DrawThisProjectile(fRenderInterface.ProjectileList[i]);
end;

procedure TRenderer.DrawThisProjectile(P: TProjectile);
var
  //SrcRectBat: TRect;  // Batter
  SrcRectSpear: TRect;
  SrcRectGrenade: TRect;
  //BatHotspot: TPoint; // Batter
  SpearHotspot: TPoint;
  GrenadeHotspot: TPoint;
  //BatTarget: TPoint;  // Batter
  SpearTarget: TPoint;
  GrenadeTarget: TPoint;
begin
  //SrcRectBat := ?;  // Batter
  SrcRectSpear := SPEAR_GRAPHIC_RECTS[P.SpearGraphic];
  SrcRectGrenade := GRENADE_GRAPHIC_RECTS[P.GrenadeGraphic];
  //BatHotspot := P.BatHotspot; // Batter
  SpearHotspot := P.SpearHotspot;
  GrenadeHotspot := P.GrenadeHotspot;
  //BatTarget := Point(P.X, P.Y); // Batter
  SpearTarget := Point(P.X, P.Y);
  GrenadeTarget := Point(P.X, P.Y);

  if GameParams.HighResolution then
  begin
//    SrcRectBat.Left := SrcRectBat.Left * 2;   // Batter
//    SrcRectBat.Top := SrcRectBat.Top * 2;
//    SrcRectBat.Right := SrcRectBat.Right * 2;
//    SrcRectBat.Bottom := SrcRectBat.Bottom * 2;

    SrcRectSpear.Left := SrcRectSpear.Left * 2;
    SrcRectSpear.Top := SrcRectSpear.Top * 2;
    SrcRectSpear.Right := SrcRectSpear.Right * 2;
    SrcRectSpear.Bottom := SrcRectSpear.Bottom * 2;

    SrcRectGrenade.Left := SrcRectGrenade.Left * 2;
    SrcRectGrenade.Top := SrcRectGrenade.Top * 2;
    SrcRectGrenade.Right := SrcRectGrenade.Right * 2;
    SrcRectGrenade.Bottom := SrcRectGrenade.Bottom * 2;

//    BatHotspot.X := BatHotspot.X * 2; // Batter
//    BatHotspot.Y := BatHotspot.Y * 2;
//    BatTarget.X := BatTarget.X * 2;
//    BatTarget.Y := BatTarget.Y * 2;

    SpearHotspot.X := SpearHotspot.X * 2;
    SpearHotspot.Y := SpearHotspot.Y * 2;
    SpearTarget.X := SpearTarget.X * 2;
    SpearTarget.Y := SpearTarget.Y * 2;

    GrenadeHotspot.X := GrenadeHotspot.X * 2;
    GrenadeHotspot.Y := GrenadeHotspot.Y * 2;
    GrenadeTarget.X := GrenadeTarget.X * 2;
    GrenadeTarget.Y := GrenadeTarget.Y * 2;
  end;

  if P.IsGrenade then
    fAni.GrenadeBitmap.DrawTo(fLayers[rlLemmingsLow], GrenadeTarget.X - GrenadeHotspot.X, GrenadeTarget.Y - GrenadeHotspot.Y, SrcRectGrenade)
  else //if P.IsSpear then
    fAni.SpearBitmap.DrawTo(fLayers[rlLemmingsLow], SpearTarget.X - SpearHotspot.X, SpearTarget.Y - SpearHotspot.Y, SrcRectSpear);
//  else  // Batter
//    fAni.BatBitmap.DrawTo(fLayers[rlLemmingsLow], BatTarget.X - BatHotspot.X, BatTarget.Y - BatHotspot.Y, SrcRectBat);
end;

procedure TRenderer.DrawProjectionShadow(L: TLemming);
var
  FrameCount: Integer;
  LemPosArray: TArrayArrayInt;
  i: Integer;

  SavePhysicsMap: TBitmap32;
const
  MAX_FRAME_COUNT = 510; // 30 in-game seconds
begin
  fLayers.fIsEmpty[rlShadowsLow] := False;
  fLayers.fIsEmpty[rlShadowsHigh] := False;
  FrameCount := 0;
  LemPosArray := nil;

  // Make a deep copy of the PhysicsMap
  SavePhysicsMap := TBitmap32.Create;
  SavePhysicsMap.Assign(PhysicsMap);

  // We simulate as long as the lemming exists, unless we time out
  while (FrameCount < MAX_FRAME_COUNT)
    and Assigned(L)
    and (not L.LemRemoved) do
  begin
    Inc(FrameCount);

    LemPosArray := fRenderInterface.SimulateLem(L);

    if Assigned(LemPosArray) then
      for i := 0 to Length(LemPosArray[0]) do
      begin
//        if (LemPosArray[0, i] < 0) or (LemPosArray[0, i] >= RenderInfoRec.Level.Info.Width) or (LemPosArray[1, i] <= 0) then
//          Exit;

        SetLowShadowPixel(LemPosArray[0, i], LemPosArray[1, i] - 1);
        SetHighShadowPixel(LemPosArray[0, i], LemPosArray[1, i] - 1);
      end;
  end;

  PhysicsMap.Assign(SavePhysicsMap);
  SavePhysicsMap.Free;
end;

procedure TRenderer.DrawJumperShadow(L: TLemming);
var
  FrameCount: Integer;
  LemPosArray: TArrayArrayInt;
  i: Integer;
const
  MAX_FRAME_COUNT = 2000;
begin
  fLayers.fIsEmpty[rlShadowsLow] := False;
  fLayers.fIsEmpty[rlShadowsHigh] := False;
  FrameCount := 0;
  LemPosArray := nil;

  SetLowShadowPixel(L.LemX, L.LemY - 1);

  // We simulate as long as the lemming is jumping, or performing certain actions that follow from this
  while (FrameCount < MAX_FRAME_COUNT)
    and Assigned(L)
    and (L.LemAction in [baJumping, baClimbing, baHoisting, baFalling, baFloating, baGliding, baSliding]) do
  begin
    Inc(FrameCount);

    LemPosArray := fRenderInterface.SimulateLem(L);

    if Assigned(LemPosArray) then
      for i := 0 to Length(LemPosArray[0]) do
      begin
        SetLowShadowPixel(LemPosArray[0, i], LemPosArray[1, i] - 1);
        SetHighShadowPixel(LemPosArray[0, i], LemPosArray[1, i] - 1);
        if (L.LemX = LemPosArray[0, i]) and (L.LemY = LemPosArray[1, i]) then Break;
      end;
  end;
end;

procedure TRenderer.DrawBalloonerShadow(L: TLemming);
var
  FrameCount: Integer;
  LemPosArray: TArrayArrayInt;
  i: Integer;
const
  MAX_FRAME_COUNT = 2000;
begin
  fLayers.fIsEmpty[rlShadowsLow] := False;
  fLayers.fIsEmpty[rlShadowsHigh] := False;
  FrameCount := 0;
  LemPosArray := nil;

  SetLowShadowPixel(L.LemX, L.LemY - 1);

  while (FrameCount < MAX_FRAME_COUNT)
    and Assigned(L)
    // We simulate as long as the lemming is ballooning
    and (L.LemAction = baBallooning) do
  begin
    Inc(FrameCount);

    LemPosArray := fRenderInterface.SimulateLem(L);

    if Assigned(LemPosArray) then
      for i := 0 to Length(LemPosArray[0]) do
      begin
        SetLowShadowPixel(LemPosArray[0, i], LemPosArray[1, i] - 1);
        SetHighShadowPixel(LemPosArray[0, i], LemPosArray[1, i] - 1);
        if (L.LemX = LemPosArray[0, i]) and (L.LemY = LemPosArray[1, i]) then Break;
      end;
  end;
end;

procedure TRenderer.DrawGliderShadow(L: TLemming);
var
  FrameCount: Integer; // Counts number of frames we have simulated, because glider paths can be infinitely long
  LemPosArray: TArrayArrayInt;
  i: Integer;
const
  MAX_FRAME_COUNT = 2000;
begin
  // Set ShadowLayer to be drawn
  fLayers.fIsEmpty[rlShadowsLow] := False;
  // Initialize FrameCount
  FrameCount := 0;
  // Initialize LemPosArray
  LemPosArray := nil;

  // Draw first pixel at lemming position
  SetLowShadowPixel(L.LemX, L.LemY - 1);

  // We simulate as long as the lemming is gliding, but allow for a falling or jumping period at the beginning
  while     (FrameCount < MAX_FRAME_COUNT)
        and Assigned(L)
        and ((L.LemAction = baGliding) or ((FrameCount < 15) and (L.LemAction in [baFalling, baJumping]))) do
  begin
    Inc(FrameCount);

    // Print shadow pixel of previous movement
    if Assigned(LemPosArray) then
      for i := 0 to Length(LemPosArray[0]) do
      begin
        SetLowShadowPixel(LemPosArray[0, i], LemPosArray[1, i] - 1);
        if (L.LemX = LemPosArray[0, i]) and (L.LemY = LemPosArray[1, i]) then Break;
      end;

    // Simulate next frame advance for lemming
    LemPosArray := fRenderInterface.SimulateLem(L);
  end;
end;

procedure TRenderer.DrawShimmierShadow(L: TLemming);
var
  FrameCount: Integer;
  LemPosArray: TArrayArrayInt;
  i: Integer;
const
  MAX_FRAME_COUNT = 2000;
begin
  fLayers.fIsEmpty[rlShadowsLow] := False;
  FrameCount := 0;
  LemPosArray := nil;

  SetLowShadowPixel(L.LemX, L.LemY - 1);

  // We simulate as long as the lemming is reaching, shimmying, turning and climbing
  while (FrameCount < MAX_FRAME_COUNT)
    and Assigned(L)
    and (L.LemAction in [baReaching, baShimmying, baTurning, baClimbing]) do
  begin
    Inc(FrameCount);

    if Assigned(LemPosArray) then
      for i := 0 to Length(LemPosArray[0]) do
      begin
        SetLowShadowPixel(LemPosArray[0, i], LemPosArray[1, i] - 1);
        if (L.LemX = LemPosArray[0, i]) and (L.LemY = LemPosArray[1, i]) then Break;
      end;

    LemPosArray := fRenderInterface.SimulateLem(L);
  end;
end;

procedure TRenderer.DrawBuilderShadow(L: TLemming);
var
  i: Integer;
  DoneThisCycle: Boolean;
  SavePhysicsMap: TBitmap32;
begin
  fLayers.fIsEmpty[rlShadowsLow] := False;
  DoneThisCycle := False;

  // Make a deep copy of the PhysicsMap
  SavePhysicsMap := TBitmap32.Create;
  SavePhysicsMap.Assign(PhysicsMap);

  while Assigned(L) and (L.LemAction = baBuilding) do
  begin
    // Draw shadow for placed brick
    if (L.LemPhysicsFrame >= 8) and not DoneThisCycle then
    begin
      for i := 0 to 5 do
        SetLowShadowPixel(L.LemX + i*L.LemDx, L.LemY - 1);

      DoneThisCycle := True;
    end else if L.LemPhysicsFrame = 0 then
      DoneThisCycle := False;

    // Simulate next frame advance for lemming
    fRenderInterface.SimulateLem(L);
  end;

  PhysicsMap.Assign(SavePhysicsMap);
  SavePhysicsMap.Free;
end;

procedure TRenderer.DrawLaddererShadow(L: TLemming);
var
  i: Integer;
  SavePhysicsMap: TBitmap32;
  PosX, PosY: Integer;
  FrameOffset: Integer;
const
  LadderBrickShadow: array[0..8, 0..1] of Integer = (
       (0, 0), (1, 0), (2, 0),
               (1, 1), (2, 1), (3, 1),
                       (2, 2), (3, 2),(4, 2)
               );
begin
  fLayers.fIsEmpty[rlShadowsLow] := False;

  PosX := L.LemX + L.LemDX;
  PosY := L.LemY;

  // Make a deep copy of the PhysicsMap
  SavePhysicsMap := TBitmap32.Create;
  SavePhysicsMap.Assign(PhysicsMap);

  while Assigned(L) and (L.LemAction = baLaddering) do
  begin
    for i := 0 to Length(LadderBrickShadow) - 1 do
    begin
      // Skill shadow is drawn a frame early to show what will actually happen
      if L.LemPhysicsFrame in [10, 11, 13, 15, 17, 19, 21, 23] then
      begin
        case L.LemPhysicsFrame of
          10: FrameOffset := 0;
          11: FrameOffset := 3;
          13: FrameOffset := 6;
          15: FrameOffset := 9;
          17: FrameOffset := 12;
          19: FrameOffset := 15;
          21: FrameOffset := 18;
          23: FrameOffset := 21;
          else Exit;
        end;

      if L.LemDX > 0 then
        SetLowShadowPixel((PosX + FrameOffset) + LadderBrickShadow[i, 0],
                          (PosY + FrameOffset) + LadderBrickShadow[i, 1])
      else
        SetLowShadowPixel((PosX - FrameOffset) - LadderBrickShadow[i, 0],
                          (PosY + FrameOffset) + LadderBrickShadow[i, 1]);
      end;
    end;

    // Simulate next frame advance for lemming
    fRenderInterface.SimulateLem(L);
  end;

  PhysicsMap.Assign(SavePhysicsMap);
  SavePhysicsMap.Free;
end;

procedure TRenderer.DrawPlatformerShadow(L: TLemming);
var
  i: Integer;
  SavePhysicsMap: TBitmap32;
begin
  fLayers.fIsEmpty[rlShadowsLow] := False;

  // Make a deep copy of the PhysicsMap
  SavePhysicsMap := TBitmap32.Create;
  SavePhysicsMap.Assign(PhysicsMap);

  while Assigned(L) and (L.LemAction = baPlatforming) do
  begin
    // Draw shadow for placed brick
    if L.LemPhysicsFrame + 1 = 9 then
      for i := 0 to 5 do
      begin
        SetLowShadowPixel(L.LemX + i*L.LemDx, L.LemY);
        SetLowShadowPixel(L.LemX + i*L.LemDx, L.LemY + 1);
      end;

    // Simulate next frame advance for lemming
    fRenderInterface.SimulateLem(L);
  end;

  PhysicsMap.Assign(SavePhysicsMap);
  SavePhysicsMap.Free;
end;

procedure TRenderer.DrawStackerShadow(L: TLemming);
var
  BrickPosY, i: Integer;
  YOffset: Integer;
  SavePhysicsMap: TBitmap32;
begin
  fLayers.fIsEmpty[rlShadowsLow] := False;

  // Make a deep copy of the PhysicsMap
  SavePhysicsMap := TBitmap32.Create;
  SavePhysicsMap.Assign(PhysicsMap);

  // Set correct Y-position for first brick
  BrickPosY := L.LemY - 9 + L.LemNumberOfBricksLeft;
  if L.LemStackLow then Inc(BrickPosY);

  if (L.LemAction = baStacking) and (L.LemPhysicsFrame = 7) then // See TLemmingGame.Transition's const ANIM_FRAMECOUNT
    YOffset := -1
  else
    YOffset := 0;

  while Assigned(L) and (L.LemAction = baStacking) do
  begin
    // Draw shadow for placed brick
    if L.LemPhysicsFrame + 1 = 7 then
    begin
      for i := 1 to 3 do
        SetLowShadowPixel(L.LemX + i*L.LemDx, BrickPosY + YOffset);

      Dec(BrickPosY); // For the next brick
    end;

    // Simulate next frame advance for lemming
    fRenderInterface.SimulateLem(L);
  end;

  PhysicsMap.Assign(SavePhysicsMap);
  SavePhysicsMap.Free;
end;

procedure TRenderer.DrawBasherShadow(L: TLemming);
const
  BasherEnd: array[0..10, 0..1] of Integer = (
     (6, -1), (6, -2), (7, -2), (7, -3), (7, -4),
     (7, -5), (7, -6), (7, -7), (6, -7), (6, -8),
     (5, -8)
   );
  MAX_FRAME_COUNT = 10000;
var
  i: Integer;
  CurFrameCount: Integer;
  BashPosX, BashPosY, BashPosDx: Integer;
  SavePhysicsMap: TBitmap32;
begin
  fLayers.fIsEmpty[rlShadowsHigh] := False;

  // Make a deep copy of the PhysicsMap
  SavePhysicsMap := TBitmap32.Create;
  SavePhysicsMap.Assign(PhysicsMap);

  BashPosDx := L.LemDx;
  BashPosX := L.LemX;
  BashPosY := L.LemY;

  CurFrameCount := 0;

  while Assigned(L) and (L.LemAction = baBashing) and (curFrameCount < MAX_FRAME_COUNT) do
  begin
    // Draw shadow for basher tunnel
    if (L.LemPhysicsFrame + 1) mod 16 = 2 then
    begin
      BashPosX := L.LemX;
      BashPosY := L.LemY;
      BashPosDx := L.LemDx;

      for i := 0 to 5 do
      begin
        SetHighShadowPixel(L.LemX + i*L.LemDx, L.LemY - 1);
        SetHighShadowPixel(L.LemX + i*L.LemDx, L.LemY - 9);
      end;
    end;

    // Simulate next frame advance for lemming
    fRenderInterface.SimulateLem(L);
    Inc(curFrameCount);
  end;

  // Draw end of the tunnel
  for i := 0 to Length(BasherEnd) - 1 do
    SetHighShadowPixel(BashPosX + BasherEnd[i, 0] * BashPosDx, BashPosY + BasherEnd[i, 1]);

  PhysicsMap.Assign(SavePhysicsMap);
  SavePhysicsMap.Free;
end;

procedure TRenderer.DrawFencerShadow(L: TLemming);
{ Like with the Fencer code itself, this is an almost exact copy of the Basher shadow code,
  and probably needs some work. }
const
  FencerEnd: array[0..5, 0..1] of Integer = (
     (6, -4), (6, -5), (6, -6), (6, -7), (6, -8),
     (6, -9)
   );
  MAX_FRAME_COUNT = 10000;
var
  i: Integer;
  FencePosX, FencePosY, FencePosDx: Integer;
  DrawDY: Integer;
  SavePhysicsMap: TBitmap32;
  CurFrameCount: Integer;
begin
  fLayers.fIsEmpty[rlShadowsHigh] := False;

  // Make a deep copy of the PhysicsMap
  SavePhysicsMap := TBitmap32.Create;
  SavePhysicsMap.Assign(PhysicsMap);

  FencePosDx := L.LemDx;
  FencePosX := L.LemX;
  FencePosY := L.LemY;

  CurFrameCount := 0;

  while Assigned(L) and (L.LemAction = baFencing) and (CurFrameCount < MAX_FRAME_COUNT) do
  begin
    // Draw shadow for fencer tunnel
    if (L.LemPhysicsFrame + 1) mod 16 = 2 then
    begin
      FencePosX := L.LemX;
      FencePosY := L.LemY;
      FencePosDx := L.LemDx;

      DrawDY := 0;
      for i := 0 to 5 do
      begin
        if i > 0 then
          SetHighShadowPixel(L.LemX + i*L.LemDx, L.LemY - 2 - DrawDy); // Slightly more consistent graphics with this If here
        if i in [2, 4] then
          Inc(DrawDY); // Putting it between the SetHighShadowPixel's is not a mistake; it reflects the mask 100% accurately ;)
        SetHighShadowPixel(L.LemX + i*L.LemDx, L.LemY - 8 - DrawDy);
      end;
    end;

    // Simulate next frame advance for lemming
    fRenderInterface.SimulateLem(L);
    Inc(CurFrameCount);
  end;

  // Draw end of the tunnel
  for i := 0 to Length(FencerEnd) - 1 do
    SetHighShadowPixel(FencePosX + FencerEnd[i, 0] * FencePosDx, FencePosY + FencerEnd[i, 1]);

  PhysicsMap.Assign(SavePhysicsMap);
  SavePhysicsMap.Free;
end;

procedure TRenderer.DrawMinerShadow(L: TLemming);
const
  MinerTurn: array[0..11, 0..1] of Integer = (
     (1, -1), (1, 0), (2, 0), (3, 0), (3, 1), (4, 1),             // Bottom border
     (3, -12), (4, -12), (5, -12), (5, -11), (6, -11), (6, -10)   // Top border
   );

  MinerEnd: array[0..15, 0..1] of Integer = (
     (5, 1), (6, 1), (6, 0), (7, 0), (7, -1),
     (8, -1), (8, -2), (8, -3), (8, -4), (8, -5),
     (8, -6), (8, -7), (7, -7), (7, -8), (7, -9),
     (7, -10)
   );
  MAX_FRAME_COUNT = 10000;
var
  i: Integer;
  MinePosX, MinePosY, MinePosDx: Integer;
  SavePhysicsMap: TBitmap32;
  CurFrameCount: Integer;
begin
  fLayers.fIsEmpty[rlShadowsHigh] := False;

  // Make a deep copy of the PhysicsMap
  SavePhysicsMap := TBitmap32.Create;
  SavePhysicsMap.Assign(PhysicsMap);

  MinePosDx := L.LemDx;
  MinePosX := L.LemX;
  MinePosY := L.LemY;

  CurFrameCount := 0;

  while Assigned(L) and (L.LemAction = baMining) and (CurFrameCount < MAX_FRAME_COUNT) do
  begin
    // Draw shadow for miner tunnel
    if L.LemPhysicsFrame + 1 = 1 then
    begin
      MinePosX := L.LemX;
      MinePosY := L.LemY;
      MinePosDx := L.LemDx;

      for i := 0 to Length(MinerTurn) - 1 do
        SetHighShadowPixel(MinePosX + MinerTurn[i, 0] * MinePosDx, MinePosY + MinerTurn[i, 1]);
    end;

    // Simulate next frame advance for lemming
    fRenderInterface.SimulateLem(L);
    Inc(CurFrameCount);
  end;

  // Draw end of the tunnel
  for i := 0 to Length(MinerEnd) - 1 do
    SetHighShadowPixel(MinePosX + MinerEnd[i, 0] * MinePosDx, MinePosY + MinerEnd[i, 1]);

  PhysicsMap.Assign(SavePhysicsMap);
  SavePhysicsMap.Free;
end;

//procedure TRenderer.DrawPropellerShadow(L: TLemming);  // Propeller - this doesn't work yet
//const
//  MAX_FRAME_COUNT = 10000;
//var
//  i: Integer;
//  PosX, PosY: Integer;
//  SavePhysicsMap: TBitmap32;
//  CurFrameCount: Integer;
//begin
//  fLayers.fIsEmpty[rlShadowsHigh] := False;
//
//  // Make a deep copy of the PhysicsMap
//  SavePhysicsMap := TBitmap32.Create;
//  SavePhysicsMap.Assign(PhysicsMap);
//
//  PosX := L.LemX;
//  PosY := L.LemY;
//
//  CurFrameCount := 0;
//
//  while Assigned(L) and (L.LemAction = baPropelling) and (CurFrameCount < MAX_FRAME_COUNT) do
//  begin
//    // Draw shadow for dug row
//    if L.LemPhysicsFrame = 0 then
//    begin
//      SetHighShadowPixel(PosX - 4, PosY - 8);
//      SetHighShadowPixel(PosX + 4, PosY - 8);
//
//      Dec(PosY);
//    end;
//
//    // Simulate next frame advance for lemming
//    fRenderInterface.SimulateLem(L);
//    Inc(CurFrameCount);
//  end;
//
//  // Draw top line of propeller tunnel
//  SetHighShadowPixel(PosX - 4, PosY - 8);
//  SetHighShadowPixel(PosX + 4, PosY - 8);
//  for i := -4 to 4 do
//    SetHighShadowPixel(PosX + i, PosY);
//
//  PhysicsMap.Assign(SavePhysicsMap);
//  SavePhysicsMap.Free;
//end;

procedure TRenderer.DrawDiggerShadow(L: TLemming);
const
  MAX_FRAME_COUNT = 10000;
var
  i: Integer;
  DigPosX, DigPosY: Integer;
  SavePhysicsMap: TBitmap32;
  CurFrameCount: Integer;
begin
  fLayers.fIsEmpty[rlShadowsHigh] := False;

  // Make a deep copy of the PhysicsMap
  SavePhysicsMap := TBitmap32.Create;
  SavePhysicsMap.Assign(PhysicsMap);

  DigPosX := L.LemX;
  DigPosY := L.LemY;

  CurFrameCount := 0;

  while Assigned(L) and (L.LemAction = baDigging) and (CurFrameCount < MAX_FRAME_COUNT) do
  begin
    // Draw shadow for dug row
    if (L.LemPhysicsFrame + 1) mod 8 = 0 then
    begin
      SetHighShadowPixel(DigPosX - 4, DigPosY - 1);
      SetHighShadowPixel(DigPosX + 4, DigPosY - 1);

      Inc(DigPosY);
    end;

    // Simulate next frame advance for lemming
    fRenderInterface.SimulateLem(L);
    Inc(CurFrameCount);
  end;

  // Draw bottom line of digger tunnel
  SetHighShadowPixel(DigPosX - 4, DigPosY - 1);
  SetHighShadowPixel(DigPosX + 4, DigPosY - 1);
  for i := -4 to 4 do
    SetHighShadowPixel(DigPosX + i, DigPosY);

  PhysicsMap.Assign(SavePhysicsMap);
  SavePhysicsMap.Free;
end;

procedure TRenderer.DrawExploderShadow(L: TLemming);
const
  // This encodes only the right half of the bomber mask. The rest is obtained by mirroring it
  BomberShadow: array[0..35, 0..1] of Integer = (
     (0, 7), (1, 7), (2, 7), (2, 6), (3, 6),
     (4, 6), (4, 5), (5, 5), (5, 4), (6, 4),
     (6, 3), (6, 2), (6, 1), (7, 1), (7, 0),
     (7, -1), (7, -2), (7, -3), (7, -4), (6, -4),
     (6, -5), (6, -6), (6, -7), (6, -8), (5, -8),
     (5, -9), (5, -10), (5, -10), (4, -11), (4, -12),
     (3, -12), (3, -13), (2, -13), (2, -14), (1, -14),
     (0, -14)
   );
var
  PosX, i: Integer;
begin
  fLayers.fIsEmpty[rlShadowsHigh] := False;

  PosX := L.LemX;
  if L.LemDx = 1 then Inc(PosX);

  for i := 0 to Length(BomberShadow) - 1 do
  begin
    SetHighShadowPixel(PosX + BomberShadow[i, 0], L.LemY + BomberShadow[i, 1]);
    SetHighShadowPixel(PosX - BomberShadow[i, 0] - 1, L.LemY + BomberShadow[i, 1]);
  end;
end;

procedure TRenderer.DrawFreezerShadow(L: TLemming);
const
  // This encodes only the left half of the freezer mask. The rest is obtained by mirroring it
  FreezerShadow: array[0..52, 0..1] of Integer = (
     (-1, -1), (-1, -2), (-1, -3), (-1, -4), (-1, -5), (-1, -6),
     (-1, -7), (-1, -8), (-1, -9), (-1, -10), (-1, -11),
     (-2, -1), (-2, -2), (-2, -3), (-2, -4), (-2, -5), (-2, -6),
     (-2, -7), (-2, -8), (-2, -9), (-2, -10), (-2, -11),
     (-3, -1), (-3, -2), (-3, -3), (-3, -4), (-3, -5), (-3, -6),
     (-3, -7), (-3, -8), (-3, -9), (-3, -10), (-3, -11),
     (-4, -1), (-4, -2), (-4, -3), (-4, -4), (-4, -5), (-4, -6),
     (-4, -7), (-4, -8), (-4, -9), (-4, -10), (-4, -11),
     (-5, -2), (-5, -3), (-5, -4), (-5, -5), (-5, -6),
     (-5, -7), (-5, -8), (-5, -9), (-5, -10)
   );
var
  i: Integer;
  PosX: Integer;
begin
  fLayers.fIsEmpty[rlShadowsLow] := False;

  PosX := L.LemX;
  if L.LemDx = 1 then Inc(PosX);

  for i := 0 to Length(FreezerShadow) - 1 do
  begin
  if L.LemAction = baSwimming then
  begin
    SetLowShadowPixel(PosX + FreezerShadow[i, 0], (L.LemY + 3) + FreezerShadow[i, 1]);
    SetLowShadowPixel(PosX - FreezerShadow[i, 0] - 1, (L.LemY + 3) + FreezerShadow[i, 1]);
  end else begin
    SetLowShadowPixel(PosX + FreezerShadow[i, 0], L.LemY + FreezerShadow[i, 1]);
    SetLowShadowPixel(PosX - FreezerShadow[i, 0] - 1, L.LemY + FreezerShadow[i, 1]);
  end;
  end;
end;

procedure TRenderer.DrawProjectileShadow(L: TLemming);
const
  ARR_BASE_LEN = 1024;
var
  Projectile: TProjectile;
  PosArray: TProjectilePointArray;
  ActualPosCount: Integer;
  i: Integer;

  LevelWidth: Integer;
  LevelHeight: Integer;

  procedure AppendPositions(New: TProjectilePointArray);
  var
    i: Integer;
  begin
    if ActualPosCount + Length(New) > Length(PosArray) then
      SetLength(PosArray, Length(PosArray) + ARR_BASE_LEN);

    for i := 0 to Length(New)-1 do
    begin
      PosArray[ActualPosCount] := New[i];
      Inc(ActualPosCount);
    end;
  end;

  function IsOutOfBounds: Boolean;
  begin
    Result := (Projectile.X < -108) or (Projectile.X >= LevelWidth + 108) or
              (Projectile.Y < -108) or (Projectile.Y >= LevelHeight + 108);
  end;
begin
  fLayers.fIsEmpty[rlShadowsLow] := False;

  LevelWidth := GameParams.Level.Info.Width;
  LevelHeight := GameParams.Level.Info.Height;

  case L.LemAction of
    //baBatting: Projectile := TProjectile.CreateBat(fRenderInterface.PhysicsMap, L); // Batter
    baSpearing: Projectile := TProjectile.CreateSpear(fRenderInterface.PhysicsMap, L);
    baGrenading: Projectile := TProjectile.CreateGrenade(fRenderInterface.PhysicsMap, L);
    else raise Exception.Create('TRenderer.DrawProjectileShadow passed an invalid lemming');
  end;

  try
    SetLength(PosArray, ARR_BASE_LEN);
    ActualPosCount := 0;

    while not (Projectile.SilentRemove or Projectile.Hit or IsOutOfBounds) do
    begin
      if not Projectile.Fired then // We don't need the lemming anymore once the projectile leaves its hand
        fRenderInterface.SimulateLem(L);
      AppendPositions(Projectile.Update);
    end;

    for i := 0 to ActualPosCount-1 do
      SetLowShadowPixel(PosArray[i].X, PosArray[i].Y);
  finally
    Projectile.Free;
  end;
end;

procedure TRenderer.DrawLasererShadow(L: TLemming);
var
  LastHitPoint: TPoint;
  SavePhysicsMap: TBitmap32;
  x, y: Integer;
  AbsTotal: Integer;
  Targ: TPoint;
  Bounds: TRect;
  PixPtr: PColor32;

  TargetRect: TRect;
begin
  fLayers.fIsEmpty[rlShadowsHigh] := False;

  if L.LemDX = 1 then
    TargetRect := Rect(L.LemX, 0, PhysicsMap.Width, L.LemY)
  else
    TargetRect := Rect(0, 0, L.LemX + 1, L.LemY);

  // Make a deep copy of the PhysicsMap
  SavePhysicsMap := TBitmap32.Create;
  SavePhysicsMap.Assign(PhysicsMap);

  if (TempBitmap.Width <> PhysicsMap.Width) or (TempBitmap.Height <> PhysicsMap.Height) then
    TempBitmap.SetSize(PhysicsMap.Width, PhysicsMap.Height);

  TempBitmap.Clear(0);
  TempBitmap.DrawMode := dmCustom;
  TempBitmap.OnPixelCombine := CombineLasererShadowToShadowLayer;
  Bounds := TempBitmap.BoundsRect;

  LastHitPoint := Point(-1, -1); // Can't actually hit because no terrain outside borders, so guaranteed dummy

  while Assigned(L) and (L.LemAction = baLasering) do
  begin
    if L.LemLaserHit then
      for y := -4 to 4 do
        for x := -4 to 4 do
        begin
          AbsTotal := Abs(x) + Abs(y);
          if AbsTotal <= 5 then
          begin
            Targ := Point(L.LemLaserHitPoint.X + x, L.LemLaserHitPoint.Y + y);
            if not PtInRect(Bounds, Targ) then Continue;

            PixPtr := TempBitmap.PixelPtr[Targ.X, Targ.Y];

            if (AbsTotal = 5) or ((AbsTotal = 4) and ((x = 0) or (y = 0))) then
            begin
              Inc(PixPtr^, $00000100);
              if AbsTotal = 5 then
                if ((L.LemDX < 0) and ((x < 0) <> (y < 0))) or
                   ((L.LemDX > 0) and ((x < 0) = (y < 0))) then
                  Inc(PixPtr^, $00010000);
            end else
              Inc(PixPtr^, $00000001);
          end;
        end;

    fRenderInterface.SimulateLem(L);
    if (not L.LemLaserHit) or (L.LemLaserHitPoint = LastHitPoint) then break;
    LastHitPoint := L.LemLaserHitPoint;
  end;

  TempBitmap.DrawTo(fLayers[rlShadowsHigh], TargetRect, TargetRect);

  // Restore PhysicsMap
  PhysicsMap.Assign(SavePhysicsMap);
  SavePhysicsMap.Free;
end;



procedure TRenderer.ClearShadows;
begin
  if not fLayers.fIsEmpty[rlShadowsLow] then
  begin
    fLayers[rlShadowsLow].Clear(0);
    fLayers.fIsEmpty[rlShadowsLow] := True;
  end;
  if not fLayers.fIsEmpty[rlShadowsHigh] then
  begin
    fLayers[rlShadowsHigh].Clear(0);
    fLayers.fIsEmpty[rlShadowsHigh] := True;
  end;
end;

procedure TRenderer.SetLowShadowPixel(X, Y: Integer);
begin
  if (X >= 0) and (X < fPhysicsMap.Width) and (Y >= 0) and (Y < fPhysicsMap.Height) then
    fLayers[rlShadowsLow].Pixel[X, Y] := SHADOW_COLOR;
end;

procedure TRenderer.SetHighShadowPixel(X, Y: Integer);
begin
  if (X >= 0) and (X < fPhysicsMap.Width) and (Y >= 0) and (Y < fPhysicsMap.Height) then
    fLayers[rlShadowsHigh].Pixel[X, Y] := SHADOW_COLOR;
end;

procedure TRenderer.AddTerrainPixel(X, Y: Integer; Color: TColor32);
var
  P: PColor32;
  C: TColor32;

  procedure Apply(X, Y: Integer);
  begin
    P := fLayers[rlTerrain].PixelPtr[X, Y];
    if P^ and $FF000000 <> $FF000000 then
    begin
      C := Color;
      MergeMem(P^, C);
      P^ := C;
    end;
  end;
begin
  if not PtInRect(fPhysicsMap.BoundsRect, Point(X, Y)) then Exit;

  if GameParams.HighResolution then
  begin
    Apply(X * 2, Y * 2);
    Apply(X * 2 + 1, Y * 2);
    Apply(X * 2, Y * 2 + 1);
    Apply(X * 2 + 1, Y * 2 + 1);
  end else
    Apply(X, Y);
end;

procedure TRenderer.AddSpear(P: TProjectile);
var
  SrcRect: TRect;
  Hotspot: TPoint;
  Target: TPoint;
begin
  SrcRect := SPEAR_GRAPHIC_RECTS[P.SpearGraphic];
  Hotspot := P.SpearHotspot;
  Target := Point(P.X, P.Y);

  if GameParams.HighResolution then
  begin
    SrcRect.Left := SrcRect.Left * 2;
    SrcRect.Top := SrcRect.Top * 2;
    SrcRect.Right := SrcRect.Right * 2;
    SrcRect.Bottom := SrcRect.Bottom * 2;
    Hotspot.X := Hotspot.X * 2;
    Hotspot.Y := Hotspot.Y * 2;
    Target.X := Target.X * 2;
    Target.Y := Target.Y * 2;
  end;

  fAni.SpearBitmap.DrawMode := dmCustom;
  fAni.SpearBitmap.OnPixelCombine := CombineTerrainNoOverwrite;
  fAni.SpearBitmap.DrawTo(fLayers[rlTerrain], Target.X - Hotspot.X, Target.Y - Hotspot.Y, SrcRect);
end;

procedure TRenderer.AddFreezer(X, Y: Integer);
begin
  fAni.IceCubeBitmap.DrawMode := dmCustom;
  fAni.IceCubeBitmap.OnPixelCombine := CombineTerrainDefault;
  fAni.IceCubeBitmap.DrawTo(fLayers[rlTerrain], X * ResMod, Y * ResMod);
end;

function TRenderer.FindGadgetMetaInfo(O: TGadgetModel): TGadgetMetaAccessor;
var
  FindLabel: String;
  MO: TGadgetMetaInfo;
  df: Integer;
  mayFlip: Boolean;
begin
  FindLabel := O.GS + ':' + O.Piece;
  MO := PieceManager.Objects[FindLabel];
  df := O.DrawingFlags;
  // Don't flip hatches and splitters
  mayFlip := (df and odf_FlipLem <> 0) and not (MO.TriggerEffect in [DOM_WINDOW, DOM_SPLITTER]);
  Result := MO.GetInterface(mayFlip, df and odf_UpsideDown <> 0, df and odf_Rotate <> 0);
end;

function TRenderer.FindMetaTerrain(T: TTerrain): TMetaTerrain;
var
  FindLabel: String;
begin
  FindLabel := T.GS + ':' + T.Piece;
  Result := PieceManager.Terrains[FindLabel];
end;

// Graphical combines

procedure TRenderer.CombineFixedColor(F: TColor32; var B: TColor32; M: Cardinal);
begin
  if (F and $FF000000) <> 0 then
    B := fFixedDrawColor;
end;

function TRenderer.CombineTerrainSolidity(F, B: Byte): Byte;
begin
  // Custom alpha blend functions, to 100% ensure consistency.
  // This is not order-sensitive, ie: CombineTerrainSolidity(X, Y) = CombineTerrainSolidity(Y, X).
  // Thus, it can be used for No Overwrite draws too.
  if (F = 0) then
    Result := B
  else if (B = 0) then
    Result := F
  else if (F = 255) or (B = 255) then
    Result := 255
  else
    Result := Round((1 - ((1 - (F / 255)) * (1 - (B / 255)))) * 255);
end;

function TRenderer.CombineTerrainSolidityErase(F, B: Byte): Byte;
begin
  // This one, on the other hand, very much is order-sensitive.
  if (F = 0) then
    Result := B
  else if (F = 255) or (B = 0) then
    Result := 0
  else
    Result := Round(((1 - (F / 255)) * (B / 255)) * 255);
end;

procedure TRenderer.CombineTerrainDefault(F: TColor32; var B: TColor32; M: Cardinal);
begin
  if (F and $FF000000) <> 0 then
    MergeMem(F, B);
end;

procedure TRenderer.CombineTerrainNoOverwrite(F: TColor32; var B: TColor32; M: Cardinal);
begin
  if ((F and $FF000000) <> $00000000) then
  begin
    MergeMem(B, F);
    B := F;
  end;
end;

procedure TRenderer.CombineTerrainErase(F: TColor32; var B: TColor32; M: Cardinal);
begin
  B := (B and $FFFFFF) or (CombineTerrainSolidityErase(F shr 24, B shr 24) shl 24);
end;

procedure TRenderer.CombineTerrainPhysicsPrepInternal(F: TColor32; var B: TColor32;
  M: Cardinal);
var
  srcSolidity, srcSteel, srcOneWay, srcErase: Byte;
  dstSolidity, dstSteel, dstOneWay, dstErase: Byte;
begin
  // A = solidity
  // R = steel
  // G = oneway
  // B = erase (src only)
  srcSolidity := (F and $FF000000) shr 24;
  srcSteel    := (F and $00FF0000) shr 16;
  srcOneWay   := (F and $0000FF00) shr 8;
  srcErase    := (F and $000000FF) shr 0;

  dstSolidity := (B and $FF000000) shr 24;
  dstSteel    := (B and $00FF0000) shr 16;
  dstOneWay   := (B and $0000FF00) shr 8;
  dstErase    := (B and $000000FF) shr 0;

  if (srcErase > 0) then
  begin
    dstSolidity := CombineTerrainSolidityErase(srcErase, dstSolidity);
    if (dstSolidity = 0) then
    begin
      dstSteel := 0;
      dstOneWay := 0;
    end else begin
      dstSteel := CombineTerrainProperty(0, dstSteel, srcErase);
      dstOneWay := CombineTerrainProperty(0, dstOneWay, srcErase);
    end;
  end else begin
    dstSolidity := CombineTerrainSolidity(srcSolidity, dstSolidity);

    // Bookmark - for "steel is always steel", replace this line:
    dstSteel := CombineTerrainProperty(srcSteel, dstSteel, srcSolidity);

    // With this:
  { if srcSolidity > 0 then
    begin
      dstSteel := CombineTerrainProperty(srcSteel, dstSteel, srcSteel);
    end; }

    dstOneWay := CombineTerrainProperty(srcOneWay, dstOneWay, srcSolidity);
  end;

  B := (dstSolidity shl 24) or (dstSteel shl 16) or (dstOneWay shl 8) or (dstErase shl 0);
end;

procedure TRenderer.CombineTerrainPhysicsPrep(F: TColor32; var B: TColor32;
  M: Cardinal);
var
  Intensity: Byte;
begin
  Intensity := (F and $FF000000) shr 24;
  case fPhysicsRenderingType of
    prtStandard: F := (Intensity shl 24);
    prtSteel: F := (Intensity shl 24) or ($FF0000);
    prtOneWay: F := (Intensity shl 24) or ($00FF00);
    prtErase: F := (Intensity shl 0);
  end;

  CombineTerrainPhysicsPrepInternal(F, B, M);
end;

procedure TRenderer.CombineTerrainPhysicsPrepNoOverwrite(F: TColor32;
  var B: TColor32; M: Cardinal);
var
  Intensity: Byte;
begin
  Intensity := (F and $FF000000) shr 24;
  case fPhysicsRenderingType of
    prtStandard: F := (Intensity shl 24);
    prtSteel: F := (Intensity shl 24) or ($FF0000);
    prtOneWay: F := (Intensity shl 24) or ($00FF00);
    prtErase:
      begin
        CombineTerrainPhysicsPrep(F, B, M);
        Exit;
      end;
  end;

  CombineTerrainPhysicsPrepInternal(B, F, M);
  B := F;
end;

function TRenderer.CombineTerrainProperty(F, B, FIntensity: Byte): Byte;
var
  Diff: Integer;
begin
  Diff := F - B;
  Result := B + Round(Diff * (FIntensity / 255));
end;

procedure TRenderer.CombineGadgetsDefault(F: TColor32; var B: TColor32; M: Cardinal);
begin
  if (F and $FF000000) = $FF000000 then
    B := F
  else if (F and $FF000000) <> 0 then
    MergeMem(F, B);
end;

procedure TRenderer.CombineLasererShadowToShadowLayer(F: TColor32;
  var B: TColor32; M: Cardinal);
begin
  if (F and $00FF0000 <> 0) or ((F and $0000FFFF) = $00000100) then B := SHADOW_COLOR;
end;

const
  MIN_TERRAIN_GROUP_WIDTH = 1;
  MIN_TERRAIN_GROUP_HEIGHT = 1;

procedure TRenderer.PrepareCompositePieceBitmap(aTerrains: TTerrains; aDst: TBitmap32; aHighResolution: Boolean);
var
  DataBoundsRect: TRect;

  Multiplier: Integer;

  function CheckGroupIsValid: Boolean;
  var
    i: Integer;
    IsSteelGroup: Boolean;

    FirstNonErase: Integer;
  begin
    // This function should:
    //  - If group is valid, return TRUE
    //  - If group is invalid and some sane way to handle it exists, handle it as such then return FALSE
    //  - If group is invalid and no sane way to handle it exists, raise an exception

    FirstNonErase := -1;
    for i := 0 to aTerrains.Count-1 do
      if (aTerrains[i].DrawingFlags and tdf_Erase) = 0 then
      begin
        FirstNonErase := i;
        Break;
      end;

    if FirstNonErase < 0 then
    begin
      aDst.SetSize(MIN_TERRAIN_GROUP_WIDTH, MIN_TERRAIN_GROUP_HEIGHT);
      aDst.Clear(0);
      Result := False;
    end else begin
      IsSteelGroup := PieceManager.Terrains[aTerrains[FirstNonErase].Identifier].IsSteel;

      for i := FirstNonErase+1 to aTerrains.Count-1 do
        if (aTerrains[i].DrawingFlags and tdf_Erase = 0) and
           (PieceManager.Terrains[aTerrains[i].Identifier].IsSteel <> IsSteelGroup) then
          raise Exception.Create('TRenderer.PrepareCompositePieceBitmap received a group with a mix of steel and nonsteel pieces!');

      Result := True;
    end;
  end;

  procedure CalculateDataBoundsRect;
  var
    i: Integer;
    Terrain: TTerrain;
    MetaTerrain: TMetaTerrain;
    ThisTerrainRect: TRect;
    HasFoundNonEraserTerrain: Boolean;

    PieceWidth, PieceHeight: Integer;
  begin
    { Calculates the initial canvas rectangle we draw on to. If shrinking this
      is needed later, we do so, but for now we just want a size that's 100%
      for sure able to fit the composite piece. }

    HasFoundNonEraserTerrain := False;
    DataBoundsRect := Rect(0, 0, 0, 0); // In case all pieces are erasers

    for i := 0 to aTerrains.Count-1 do
    begin
      Terrain := aTerrains[i];

      if (Terrain.DrawingFlags and tdf_Erase) <> 0 then
        Continue; // We don't need to expand the canvas for erasers.

      MetaTerrain := PieceManager.Terrains[Terrain.Identifier];

      ThisTerrainRect.Left := Terrain.Left * Multiplier;
      ThisTerrainRect.Top := Terrain.Top * Multiplier;

      PieceWidth := EvaluateResizable(Terrain.Width,
                                      MetaTerrain.DefaultWidth[Terrain.Flip, Terrain.Invert, Terrain.Rotate],
                                      MetaTerrain.Width[Terrain.Flip, Terrain.Invert, Terrain.Rotate],
                                      MetaTerrain.ResizeHorizontal[Terrain.Flip, Terrain.Invert, Terrain.Rotate])
                     * Multiplier;

      PieceHeight := EvaluateResizable(Terrain.Height,
                                       MetaTerrain.DefaultHeight[Terrain.Flip, Terrain.Invert, Terrain.Rotate],
                                       MetaTerrain.Height[Terrain.Flip, Terrain.Invert, Terrain.Rotate],
                                       MetaTerrain.ResizeVertical[Terrain.Flip, Terrain.Invert, Terrain.Rotate])
                     * Multiplier;

      ThisTerrainRect.Right := ThisTerrainRect.Left + PieceWidth;
      ThisTerrainRect.Bottom := ThisTerrainRect.Top + PieceHeight;

      if HasFoundNonEraserTerrain then
        DataBoundsRect := TRect.Union(DataBoundsRect, ThisTerrainRect)
      else begin
        DataBoundsRect := ThisTerrainRect;
        HasFoundNonEraserTerrain := True;
      end;
    end;

    if DataBoundsRect.Width < Multiplier then
      DataBoundsRect.Right := DataBoundsRect.Left + Multiplier;

    if DataBoundsRect.Height < Multiplier then
      DataBoundsRect.Bottom := DataBoundsRect.Top + Multiplier;
  end;

  procedure DrawPieces;
  var
    i: Integer;
    LocalTerrain: TTerrain;
  begin
    LocalTerrain := TTerrain.Create;
    try
      for i := 0 to aTerrains.Count-1 do
      begin
        LocalTerrain.Assign(aTerrains[i]);
        LocalTerrain.Left := LocalTerrain.Left - (DataBoundsRect.Left div Multiplier);
        LocalTerrain.Top := LocalTerrain.Top - (DataBoundsRect.Top div Multiplier);
        DrawTerrain(aDst, LocalTerrain, aHighResolution);
      end;
    finally
      LocalTerrain.Free;
    end;
  end;
begin
  if aHighResolution then
    Multiplier := 2
  else
    Multiplier := 1;

  if not CheckGroupIsValid then Exit;
  CalculateDataBoundsRect;

  aDst.SetSize(DataBoundsRect.Width, DataBoundsRect.Height);
  aDst.Clear(0);
  DrawPieces;
end;

procedure TRenderer.PrepareCompositePieceBitmaps(aTerrains: TTerrains; aLowRes: TBitmap32; aHighRes: TBitmap32);
  procedure Crop;
  var
    Temp: TBitmap32;
    SrcRect: TRect;
    x, y: Integer;
  begin
    SrcRect := Rect(aLowRes.Width, aLowRes.Height, 0, 0);
    for y := 0 to (aLowRes.Height)-1 do
      for x := 0 to (aLowRes.Width)-1 do
      begin
        if (aLowRes[x, y] and $FF000000) <> 0 then
        begin
          if (x < SrcRect.Left) then srcRect.Left := x;
          if (y < SrcRect.Top) then srcRect.Top := y;
          if (x >= SrcRect.Right) then srcRect.Right := x + 1; // Careful - remember how TRect.Right / TRect.Bottom work!
          if (y >= SrcRect.Bottom) then srcRect.Bottom := y + 1;
        end;
      end;

    if SrcRect.Width < MIN_TERRAIN_GROUP_WIDTH then SrcRect.Right := SrcRect.Left + MIN_TERRAIN_GROUP_WIDTH;
    if SrcRect.Height < MIN_TERRAIN_GROUP_HEIGHT then SrcRect.Bottom := SrcRect.Top + MIN_TERRAIN_GROUP_HEIGHT;

    Temp := TBitmap32.Create;
    try
      Temp.Assign(aLowRes);
      aLowRes.SetSize(SrcRect.Width, SrcRect.Height);
      Temp.DrawMode := dmOpaque;
      Temp.DrawTo(aLowRes, 0, 0, SrcRect);

      if aHighRes <> nil then
      begin
        SrcRect.Left := SrcRect.Left * 2;
        SrcRect.Top := SrcRect.Top * 2;
        SrcRect.Right := SrcRect.Right * 2;
        SrcRect.Bottom := SrcRect.Bottom * 2;

        Temp.Assign(aHighRes);
        aHighRes.SetSize(SrcRect.Width, SrcRect.Height);
        Temp.DrawMode := dmOpaque;
        Temp.DrawTo(aHighRes, 0, 0, SrcRect);
      end;
    finally
      Temp.Free;
    end;
  end;
begin
  PrepareCompositePieceBitmap(aTerrains, aLowRes, False);
  if GameParams.HighResolution then
    PrepareCompositePieceBitmap(aTerrains, aHighRes, True);
  Crop;
end;

procedure TRenderer.PrepareGadgetBitmap(Bmp: TBitmap32; IsOnlyOnTerrain: Boolean; IsZombie: Boolean = False;
                                        IsNeutral: Boolean = False; IsRival: Boolean = False);
begin
  Bmp.DrawMode := dmCustom;

  if fUsefulOnly then
    Bmp.OnPixelCombine := CombineFixedColor
  else if IsOnlyOnTerrain then
    Bmp.OnPixelCombine := CombineGadgetsDefault
  else
    Bmp.OnPixelCombine := CombineGadgetsDefault;
end;

procedure TRenderer.DrawTerrain(Dst: TBitmap32; T: TTerrain);
begin
  DrawTerrain(Dst, T, GameParams.HighResolution);
end;

procedure TRenderer.DrawTerrain(Dst: TBitmap32; T: TTerrain; HighRes: Boolean);
begin
  InternalDrawTerrain(Dst, T, False, HighRes);
end;

procedure TRenderer.InternalDrawTerrain(Dst: TBitmap32; T: TTerrain; IsPhysicsDraw: Boolean; IsHighRes: Boolean);
var
  Src: TBitmap32;
  Flip, Invert, Rotate: Boolean;
  MT: TMetaTerrain;

  SrcRect, DstRect, Margins: TRect;
begin

  MT := FindMetaTerrain(T);
  Rotate := (T.DrawingFlags and tdf_Rotate <> 0);
  Invert := (T.DrawingFlags and tdf_Invert <> 0);
  Flip := (T.DrawingFlags and tdf_Flip <> 0);

  if IsHighRes then
    Src := MT.GraphicImageHighRes[Flip, Invert, Rotate]
  else
    Src := MT.GraphicImage[Flip, Invert, Rotate];

  SrcRect := Src.BoundsRect;

  if IsPhysicsDraw then
    PrepareTerrainBitmapForPhysics(Src, T.DrawingFlags, MT.IsSteel)
  else
    PrepareTerrainBitmap(Src, T.DrawingFlags);

  DstRect.Left := T.Left;
  DstRect.Top := T.Top;
  DstRect.Right := DstRect.Left + EvaluateResizable(T.Width,
                                                    MT.DefaultWidth[T.Flip, T.Invert, T.Rotate],
                                                    MT.Width[T.Flip, T.Invert, T.Rotate],
                                                    MT.ResizeHorizontal[T.Flip, T.Invert, T.Rotate]);
  DstRect.Bottom := DstRect.Top + EvaluateResizable(T.Height,
                                                    MT.DefaultHeight[T.Flip, T.Invert, T.Rotate],
                                                    MT.Height[T.Flip, T.Invert, T.Rotate],
                                                    MT.ResizeVertical[T.Flip, T.Invert, T.Rotate]);

  Margins.Left := MT.CutLeft[Flip, Invert, Rotate];
  Margins.Top := MT.CutTop[Flip, Invert, Rotate];
  Margins.Right := MT.CutRight[Flip, Invert, Rotate];
  Margins.Bottom := MT.CutBottom[Flip, Invert, Rotate];

  if IsHighRes then
  begin
    DstRect.Left := DstRect.Left * 2;
    DstRect.Top := DstRect.Top * 2;
    DstRect.Right := DstRect.Right * 2;
    DstRect.Bottom := DstRect.Bottom * 2;

    Margins.Left := Margins.Left * 2;
    Margins.Top := Margins.Top * 2;
    Margins.Right := Margins.Right * 2;
    Margins.Bottom := Margins.Bottom * 2;
  end;

  DrawNineSlice(Dst, DstRect, SrcRect, Margins, Src);
end;

procedure TRenderer.PrepareTerrainBitmap(Bmp: TBitmap32; DrawingFlags: Byte);
begin
  Bmp.DrawMode := dmCustom;

  if DrawingFlags and tdf_NoOverwrite <> 0 then
    Bmp.OnPixelCombine := CombineTerrainNoOverwrite
  else if DrawingFlags and tdf_Erase <> 0 then
    Bmp.OnPixelCombine := CombineTerrainErase
  else
    Bmp.OnPixelCombine := CombineTerrainDefault;
end;

procedure TRenderer.PrepareTerrainBitmapForPhysics(Bmp: TBitmap32; DrawingFlags: Byte; IsSteel: Boolean);
begin
  Bmp.DrawMode := dmCustom;

  if (DrawingFlags and tdf_NoOverwrite <> 0) and (DrawingFlags and tdf_Erase = 0) then
    Bmp.OnPixelCombine := CombineTerrainPhysicsPrepNoOverwrite
  else
    Bmp.OnPixelCombine := CombineTerrainPhysicsPrep;

  if (DrawingFlags and tdf_Erase) <> 0 then
    fPhysicsRenderingType := prtErase
  else if IsSteel then
    fPhysicsRenderingType := prtSteel
  else if (DrawingFlags and tdf_NoOneWay) = 0 then
    fPhysicsRenderingType := prtOneWay
  else
    fPhysicsRenderingType := prtStandard;
end;

procedure TRenderer.DrawObjectHelpers(Dst: TBitmap32; Gadget: TGadget);
var
  MO: TGadgetMetaAccessor;
  DoDrawBelow: Boolean;
  Helper, DigitImage: TBitmap32;
  DrawX, DrawY, HighestY, HighY, LowY, LowestY, WindowOffset: Integer;
begin
  { We don't question here whether the conditions are met to draw the helper or
    not. We assume the calling routine has already done this, and we just draw it.
    We do, however, determine which ones to draw here. }

  CustomAssert(Dst = fLayers[rlObjectHelpers], 'Object Helpers not written on their layer');

  MO := Gadget.MetaObj;

  DigitImage := fAni.NumbersBitmap; // For calculating position based on lem cap numbers

  HighY := (Gadget.Top - 9) * ResMod;
  HighestY := HighY - DigitImage.Height - (4 * ResMod);
  LowY := (Gadget.Top + Gadget.Height + 2) * ResMod;
  LowestY := LowY + DigitImage.Height + (2 * ResMod);

  DrawX := ((Gadget.TriggerRect.Left + Gadget.TriggerRect.Right) div 2) * ResMod;
  DrawY := HighY;

  if DrawY < 0 then // Send helper below gadget if it's drawn above the level
  begin
    DrawY := LowY;
    DoDrawBelow := True;
  end else
    DoDrawBelow := False;

  case MO.TriggerEffect of
    DOM_WINDOW:
      begin
        if Gadget.IsFlipPhysics then
          Helper := fHelperImages[hpi_ArrowLeft]
        else
          Helper := fHelperImages[hpi_ArrowRight];

        if Gadget.IsPreassignedZombie then DrawX := DrawX - 4 * ResMod;

        WindowOffset := Helper.Height * 3 div 2;

        if DoDrawBelow then // Adjust DrawY for above-level hatch helpers
          DrawY := LowY - WindowOffset;

        // Account for lemming cap/clear physics hatch digits
        if fUsefulOnly or Gadget.ShowRemainingLemmings then
        begin
          if DoDrawBelow then
          begin
            DrawY := LowestY - WindowOffset;
          end else begin
            DrawY := HighestY;
          end;

          if DrawY <= 0 then // Send helper below gadget if it's drawn above the level
            DrawY := LowY - WindowOffset;
        end;

        Helper.DrawTo(Dst, DrawX - Helper.Width div 2, DrawY);

        if Gadget.IsPreassignedZombie then
          fHelperImages[hpi_Exclamation].DrawTo(Dst, DrawX + 8 * ResMod, DrawY);
      end;

    DOM_TELEPORT:
      begin
        fHelperImages[THelperIcon(Gadget.PairingID + 1)].DrawTo(Dst, DrawX - 8 * ResMod, DrawY);
        fHelperImages[hpi_ArrowUp].DrawTo(Dst, DrawX, DrawY - 1 * ResMod);
      end;

    DOM_RECEIVER:
      begin
        fHelperImages[THelperIcon(Gadget.PairingID + 1)].DrawTo(Dst, DrawX - 8 * ResMod, DrawY);
        fHelperImages[hpi_ArrowDown].DrawTo(Dst, DrawX, DrawY);
      end;

    DOM_EXIT:
      begin
        if Gadget.IsRivalExit then
          Helper := fHelperImages[hpi_Exit_Rival]
        else
          Helper := fHelperImages[hpi_Exit];

        // Account for lemming cap digits
        if (Gadget.RemainingLemmingsCount > 0) then
        begin
          if DoDrawBelow then
            DrawY := LowestY
          else
            DrawY := HighestY;

          if DrawY <= 0 then // Send helper below gadget if it's drawn above the level
            DrawY := LowY;
        end;

        Helper.DrawTo(Dst, DrawX - Helper.Width div 2, DrawY);
      end;

    DOM_LOCKEXIT:
      begin
        if Gadget.IsRivalExit then
          Helper := fHelperImages[hpi_Exit_Rival]
        else
          Helper := fHelperImages[hpi_Exit];

        // Account for lemming cap digits
        if (Gadget.RemainingLemmingsCount > 0) then
        begin
          if DoDrawBelow then
            DrawY := LowestY
          else
            DrawY := HighestY;

          if DrawY <= 0 then // Send helper below gadget if it's drawn above the level
            DrawY := LowY;
        end;

        Helper.DrawTo(Dst, DrawX - Helper.Width div 2, DrawY);

        if (Gadget.CurrentFrame = 1) then
        begin
          fFixedDrawColor := fFixedDrawColor xor $FFFFFF;
          fHelperImages[hpi_Exit_Lock].DrawTo(Dst, DrawX - 3 * ResMod, (Gadget.TriggerRect.Top - 10) * ResMod);

          fFixedDrawColor := fFixedDrawColor xor $FFFFFF;
        end;
      end;

    DOM_FIRE:
      begin
        fHelperImages[hpi_Fire].DrawTo(Dst, DrawX - 13 * ResMod, DrawY);
      end;

    DOM_TRAP:
      begin
        fHelperImages[hpi_Num_Inf].DrawTo(Dst, DrawX - 17 * ResMod, DrawY);
        fHelperImages[hpi_Trap].DrawTo(Dst, DrawX - 10 * ResMod, DrawY);
      end;

    DOM_TRAPONCE:
      begin
        fHelperImages[hpi_Num_1].DrawTo(Dst, DrawX - 17 * ResMod, DrawY);
        fHelperImages[hpi_Trap].DrawTo(Dst, DrawX - 10 * ResMod, DrawY);
      end;

    DOM_UPDRAFT:
      begin
        fHelperImages[hpi_Updraft].DrawTo(Dst, DrawX - 22 * ResMod, DrawY);
      end;

    DOM_SPLITTER:
      begin
        fHelperImages[hpi_Splitter].DrawTo(Dst, DrawX - 13 * ResMod, DrawY);
      end;

    DOM_BUTTON:
      begin
        fHelperImages[hpi_Button].DrawTo(Dst, DrawX - 19 * ResMod, DrawY);
      end;

    DOM_COLLECTIBLE:
      begin
        fHelperImages[hpi_Collectible].DrawTo(Dst, DrawX - 34 * ResMod, DrawY);
      end;

    DOM_FORCELEFT:
      if Gadget.IsFlipImage then
      begin
        fHelperImages[hpi_Force].DrawTo(Dst, DrawX - 19 * ResMod, DrawY);
        fHelperImages[hpi_ArrowRight].DrawTo(Dst, DrawX + 12 * ResMod, DrawY);
      end else begin
        fHelperImages[hpi_Force].DrawTo(Dst, DrawX - 19 * ResMod, DrawY);
        fHelperImages[hpi_ArrowLeft].DrawTo(Dst, DrawX + 13 * ResMod, DrawY);
      end;

    DOM_FORCERIGHT:
      if Gadget.IsFlipImage then
      begin
        fHelperImages[hpi_Force].DrawTo(Dst, DrawX - 19 * ResMod, DrawY);
        fHelperImages[hpi_ArrowLeft].DrawTo(Dst, DrawX + 13 * ResMod, DrawY);
      end else begin
        fHelperImages[hpi_Force].DrawTo(Dst, DrawX - 19 * ResMod, DrawY);
        fHelperImages[hpi_ArrowRight].DrawTo(Dst, DrawX + 12 * ResMod, DrawY);
      end;

    DOM_NOSPLAT:
      begin
        fHelperImages[hpi_NoSplat].DrawTo(Dst, DrawX - 16 * ResMod, DrawY);
      end;

    DOM_SPLAT:
      begin
        fHelperImages[hpi_Splat].DrawTo(Dst, DrawX - 16 * ResMod, DrawY);
      end;

    DOM_WATER:
      begin
        fHelperImages[hpi_Water].DrawTo(Dst, DrawX - 16 * ResMod, DrawY);
      end;

    DOM_BLASTICINE:
      begin
        fHelperImages[hpi_Blasticine].DrawTo(Dst, DrawX - 16 * ResMod, DrawY);
      end;

    DOM_VINEWATER:
      begin
        fHelperImages[hpi_Vinewater].DrawTo(Dst, DrawX - 16 * ResMod, DrawY);
      end;

    DOM_POISON:
      begin
        fHelperImages[hpi_Poison].DrawTo(Dst, DrawX - 16 * ResMod, DrawY);
      end;

    DOM_LAVA:
      begin
        fHelperImages[hpi_Lava].DrawTo(Dst, DrawX - 16 * ResMod, DrawY);
      end;

    DOM_RADIATION:
      begin
        fHelperImages[hpi_Radiation].DrawTo(Dst, DrawX - 16 * ResMod, DrawY);
      end;

    DOM_SLOWFREEZE:
      begin
        fHelperImages[hpi_Slowfreeze].DrawTo(Dst, DrawX - 16 * ResMod, DrawY);
      end;
  end;
end;

procedure TRenderer.DrawHatchSkillHelpers(Dst: TBitmap32; Gadget: TGadget; DrawOtherHelper: Boolean);
var
  numHelpers, indexHelper: Integer;
  DrawX, DrawY: Integer;
begin
    CustomAssert(Dst = fLayers[rlObjectHelpers], 'Object Helpers not written on their layer');
    CustomAssert(Gadget.TriggerEffectBase = DOM_WINDOW, 'Hatch helper icons called for other object type');

    // Count number of helper icons to be displayed.
    numHelpers := 0;
    if Gadget.IsPreassignedSlider then Inc(numHelpers);
    if Gadget.IsPreassignedClimber then Inc(numHelpers);
    if Gadget.IsPreassignedSwimmer then Inc(numHelpers);
    if Gadget.IsPreassignedFloater then Inc(numHelpers);
    if Gadget.IsPreassignedGlider then Inc(numHelpers);
    if Gadget.IsPreassignedDisarmer then Inc(numHelpers);
    if Gadget.IsPreassignedZombie then Inc(numHelpers);
    if Gadget.IsPreassignedNeutral then Inc(numHelpers);
    if Gadget.IsPreassignedRival then Inc(numHelpers);

    if DrawOtherHelper then Inc(numHelpers);

    // Set base drawing position; helper icons will be drawn 10 pixels apart
    DrawX := (Gadget.Left + Gadget.Width div 2 - numHelpers * 5) * ResMod;
    DrawY := Gadget.Top * ResMod;

    // Draw actual helper icons
    indexHelper := 0;
    if DrawOtherHelper then
    begin
      if Gadget.IsFlipPhysics then
        fHelperImages[hpi_ArrowLeft].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY)
      else
        fHelperImages[hpi_ArrowRight].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY);
      Inc(indexHelper);
    end;
    if Gadget.IsPreassignedZombie then
    begin
      fHelperImages[hpi_Skill_Zombie].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY);
      Inc(indexHelper);
    end;
    if Gadget.IsPreassignedNeutral and not Gadget.IsPreassignedRival then
    begin
      fHelperImages[hpi_Skill_Neutral].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY);
      Inc(indexHelper);
    end;
    if Gadget.IsPreassignedRival and not Gadget.IsPreassignedZombie then
    begin
      fHelperImages[hpi_Skill_Rival].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY);
      Inc(indexHelper);
    end;
    if Gadget.IsPreassignedSlider then
    begin
      fHelperImages[hpi_Skill_Slider].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY);
      Inc(indexHelper);
    end;
    if Gadget.IsPreassignedClimber then
    begin
      fHelperImages[hpi_Skill_Climber].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY);
      Inc(indexHelper);
    end;
    if Gadget.IsPreassignedSwimmer then
    begin
      fHelperImages[hpi_Skill_Swimmer].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY);
      Inc(indexHelper);
    end;
    if Gadget.IsPreassignedFloater then
    begin
      fHelperImages[hpi_Skill_Floater].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY);
      Inc(indexHelper);
    end;
    if Gadget.IsPreassignedGlider then
    begin
      fHelperImages[hpi_Skill_Glider].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY);
      Inc(indexHelper);
    end;
    if Gadget.IsPreassignedDisarmer then
    begin
      fHelperImages[hpi_Skill_Disarmer].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY);
    end;
end;

procedure TRenderer.DrawLemmingHelpers(Dst: TBitmap32; L: TLemming; IsClearPhysics: Boolean = True);
var
  numHelpers, indexHelper: Integer;
  DrawX, DrawY, DirDrawY: Integer;
const
  DRAW_ABOVE_MIN_Y = 19;
  DRAW_ABOVE_MIN_Y_CPM = 28;
begin
    CustomAssert(Dst = fLayers[rlObjectHelpers], 'Object Helpers not written on their layer');

    // Count number of helper icons to be displayed.
    numHelpers := 0;
    if L.LemIsSlider then Inc(numHelpers);
    if L.LemIsClimber then Inc(numHelpers);
    if L.LemIsSwimmer then Inc(numHelpers);
    if L.LemIsFloater then Inc(numHelpers);
    if L.LemIsGlider then Inc(numHelpers);
    if L.LemIsDisarmer then Inc(numHelpers);

    DrawX := (L.LemX - numHelpers * 5) * ResMod;
    DrawY := 0;

    if (L.LemY < DRAW_ABOVE_MIN_Y) or ((L.LemY < DRAW_ABOVE_MIN_Y_CPM) and IsClearPhysics) then
    begin
      DrawY := (L.LemY + 1) * ResMod;
      if numHelpers > 0 then
        DirDrawY := DrawY + 9 * ResMod
      else
        DirDrawY := DrawY;
    end else if (L.LemAction = baBallooning) and (L.LemPhysicsFrame >= 3) then
    begin
      if L.LemPhysicsFrame in [3, 4] then DrawY := (L.LemY - 21 - 9) * ResMod
      else if L.LemPhysicsFrame >= 5 then DrawY := (L.LemY - 30 - 9) * ResMod;
      if numHelpers > 0 then
        DirDrawY := DrawY - 9 * ResMod
      else
        DirDrawY := DrawY;
    end else begin
      DrawY := (L.LemY - 10 - 9) * ResMod;
      if numHelpers > 0 then
        DirDrawY := DrawY - 9 * ResMod
      else
        DirDrawY := DrawY;
    end;

    // Draw actual helper icons
    if isClearPhysics then
    begin
      if (L.LemDX = 1) then fHelperImages[hpi_ArrowRight].DrawTo(Dst, (L.LemX - 4) * ResMod, DirDrawY)
      else fHelperImages[hpi_ArrowLeft].DrawTo(Dst, (L.LemX - 4) * ResMod, DirDrawY);
    end;

    indexHelper := 0;
    if L.LemIsSlider then
    begin
      fHelperImages[hpi_Skill_Slider].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY);
      Inc(indexHelper);
    end;
    if L.LemIsClimber then
    begin
      fHelperImages[hpi_Skill_Climber].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY);
      Inc(indexHelper);
    end;
    if L.LemIsSwimmer then
    begin
      fHelperImages[hpi_Skill_Swimmer].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY);
      Inc(indexHelper);
    end;
    if L.LemIsFloater then
    begin
      fHelperImages[hpi_Skill_Floater].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY);
      Inc(indexHelper);
    end;
    if L.LemIsGlider then
    begin
      fHelperImages[hpi_Skill_Glider].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY);
      Inc(indexHelper);
    end;
    if L.LemIsDisarmer then
    begin
      fHelperImages[hpi_Skill_Disarmer].DrawTo(Dst, DrawX + indexHelper * 10 * ResMod, DrawY);
    end;
end;

procedure TRenderer.DrawExitMarkers(Gadget: TGadget; aMarker: TBitmap32); // Marker
var
  FrameIndex, MarkerFrames: Integer;
  XPos, YPos: Integer;
  XOffset, YOffset: Integer;
  FrameRect: TRect;
begin
  if Theme.ExitMarkerFrames <> 0 then
    MarkerFrames := Theme.ExitMarkerFrames
  else
    MarkerFrames := 14;

  FrameIndex := GlobalGame.CurrentIteration mod MarkerFrames;

  FrameRect.Left := 0;
  FrameRect.Right := aMarker.Width;
  FrameRect.Top := FrameIndex * (aMarker.Height div MarkerFrames);
  FrameRect.Bottom := FrameRect.Top + (aMarker.Height div MarkerFrames);

  XPos := Gadget.Left + Gadget.Width div 2;
  YPos := Gadget.Top - 14;

  XOffset := Gadget.MetaObj.ExitMarkerX;
  YOffset := Gadget.MetaObj.ExitMarkerY;

  aMarker.DrawTo(fLayers[rlGadgetsLow], (XPos + XOffset) * ResMod, (YPos + YOffset) * ResMod, FrameRect);
end;

procedure TRenderer.ProcessDrawFrame(Gadget: TGadget; Dst: TBitmap32);
var
  i: Integer;
  BMP: TBitmap32;

  ThisAnim: TGadgetAnimationInstance;
  DstRect: TRect;

  function GetDigitTargetLayer: TBitmap32;
  begin
    Result := fLayers[rlObjectHelpers];
    fLayers.fIsEmpty[rlObjectHelpers] := False;
  end;

  procedure DrawNumbers(X, Y: Integer; aDigitString: String; aAlignment: Integer = -1); // Negative = left; zero = center; positive = right
  var
    DigitsWidth: Integer;

    CurX: Integer;
    n: Integer;
    Digit: Integer;

    SrcRect: TRect;

    OldDrawColor: TColor32;

    LocalDst: TBitmap32;
  begin
    OldDrawColor := fFixedDrawColor;

    LocalDst := GetDigitTargetLayer;

    Y := Y - 2; // To center

    DigitsWidth := Length(aDigitString) * 5;
    if aAlignment < 0 then
      CurX := X
    else if aAlignment > 0 then
      CurX := X - DigitsWidth + 1
    else
      CurX := X - (DigitsWidth div 2) + 1;

    for n := 1 to Length(aDigitString) do
    begin
      Digit := StrToInt(aDigitString[n]);
      SrcRect := SizedRect(Digit * 4 * ResMod, 0, 4 * ResMod, 5 * ResMod);

      fAni.NumbersBitmap.DrawMode := dmCustom;
      fAni.NumbersBitmap.OnPixelCombine := CombineFixedColor;
      fFixedDrawColor := $FF202020;
      fAni.NumbersBitmap.DrawTo(LocalDst, CurX * ResMod - 1, Y * ResMod + 1, SrcRect);
      fAni.NumbersBitmap.DrawTo(LocalDst, CurX * ResMod, Y * ResMod, SrcRect);
      fAni.NumbersBitmap.DrawTo(LocalDst, CurX * ResMod, Y * ResMod + 1, SrcRect);

      fAni.NumbersBitmap.DrawMode := dmBlend;
      fAni.NumbersBitmap.CombineMode := cmMerge;
      fAni.NumbersBitmap.DrawTo(LocalDst, CurX * ResMod - 1, Y * ResMod, SrcRect);
      CurX := CurX + 5;
    end;

    fFixedDrawColor := OldDrawColor;
  end;

  procedure DrawNumber(X, Y: Integer; aNumber: Cardinal; aMinDigits: Integer = 1; aAlignment: Integer = -1);
  var
    Digits: TGadgetAnimation;
    DigitString: String;

    CurX, TargetY: Integer;
    n: Integer;

    LocalDst: TBitmap32;
  begin
    if (aNumber = 0) and (aMinDigits <= 0) then
      Exit; // Special case - allow for "show nothing on zero"

    LocalDst := GetDigitTargetLayer;

    Digits := Gadget.MetaObj.DigitAnimation;
    DigitString := LeadZeroStr(aNumber, aMinDigits);

    if Gadget.MetaObj.DigitAnimation = nil then
    begin
      DrawNumbers(X, Y, DigitString, aAlignment);
      Exit;
    end;

    if aAlignment < 0 then
      CurX := X
    else if aAlignment > 0 then
      CurX := X - (Length(DigitString) * Digits.Width)
    else
      CurX := X - ((Length(DigitString) * Digits.Width) div 2);

    TargetY := Y - (Digits.Height div 2);

    for n := 1 to Length(DigitString) do
    begin
      Digits.Draw(LocalDst, CurX * ResMod, TargetY * ResMod, StrToInt(DigitString[n]));
      Inc(CurX, Digits.Width);
    end;
  end;

  procedure AddPickupSkillNumber;
  begin
    if ((Gadget.SkillCount > 1) or (Gadget.MetaObj.DigitMinLength >= 1))
      and not (Gadget.CurrentFrame mod 2 = 0) then
        DrawNumber(Gadget.Left + Gadget.MetaObj.DigitX, Gadget.Top + Gadget.MetaObj.DigitY,
                   Gadget.SkillCount, Gadget.MetaObj.DigitMinLength, Gadget.MetaObj.DigitAlign);
  end;

  procedure AddLemmingCountNumber;
  var
    XPos, YPos, LemCap: Integer;
    DigitImage: TBitmap32;
  begin
    DigitImage := fAni.NumbersBitmap;

    XPos := Gadget.Left + Gadget.MetaObj.DigitX;
    YPos := Gadget.Top + Gadget.MetaObj.DigitY;

    if (YPos <= 0) then // Send digit below gadget if it's drawn above the level
    begin
      if Gadget.TriggerEffect = DOM_WINDOW then
        YPos := (Gadget.Top + Gadget.Height div 2 + DigitImage.Height div ResMod)
      else
        YPos := (Gadget.Top + Gadget.Height + DigitImage.Height div ResMod);
    end;

    LemCap := Gadget.RemainingLemmingsCount;

    if (Gadget.RemainingLemmingsCount >= 0) and (Gadget.ShowRemainingLemmings or fUsefulOnly) then
      DrawNumber(XPos, YPos, LemCap, Gadget.MetaObj.DigitMinLength, Gadget.MetaObj.DigitAlign);
  end;

begin
  for i := 0 to Gadget.Animations.Count-1 do
  begin
    ThisAnim := Gadget.Animations[i];

    if (not ThisAnim.Visible) and (ThisAnim.State = gasPause) then
      Continue;

    BMP := ThisAnim.Bitmap;
    PrepareGadgetBitmap(BMP, Gadget.IsOnlyOnTerrain, Gadget.ZombieMode, Gadget.NeutralMode);
    DstRect := SizedRect((Gadget.Left + ThisAnim.MetaAnimation.OffsetX) * ResMod,
                         (Gadget.Top + ThisAnim.MetaAnimation.OffsetY) * ResMod,
                         (ThisAnim.MetaAnimation.Width + Gadget.WidthVariance) * ResMod,
                         (ThisAnim.MetaAnimation.Height + Gadget.HeightVariance) * ResMod);

    if GameParams.HighResolution then
      DrawNineSlice(Dst, DstRect, BMP.BoundsRect, ThisAnim.MetaAnimation.CutRectHighRes, BMP)
    else
      DrawNineSlice(Dst, DstRect, BMP.BoundsRect, ThisAnim.MetaAnimation.CutRect, BMP);
  end;

  if (Gadget.TriggerEffect = DOM_PICKUP) then
    AddPickupSkillNumber;

  if (Gadget.TriggerEffect in [DOM_EXIT, DOM_LOCKEXIT, DOM_WINDOW]) then
    AddLemmingCountNumber;
end;

procedure TRenderer.DrawTriggerArea(Gadget: TGadget);
const
  DO_NOT_DRAW: set of 0..255 =
        [DOM_NONE, DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_BLOCKER,
         DOM_ONEWAYDOWN, DOM_WINDOW, DOM_DECORATION, DOM_ONEWAYUP];
begin
  if (Gadget.TriggerEffect in [DOM_ANIMATION, DOM_ANIMONCE]) and GameParams.NoBackgrounds then
    Exit;

  if not (Gadget.TriggerEffect in DO_NOT_DRAW) then
    DrawTriggerAreaRectOnLayer(Gadget.TriggerRect);
end;

procedure TRenderer.DrawUserHelper;
var
  BMP: TBitmap32;
  DrawPoint: TPoint;
begin
  BMP := fHelperImages[fRenderInterface.UserHelper];
  DrawPoint := fRenderInterface.MousePos;
  DrawPoint.X := DrawPoint.X;
  DrawPoint.Y := DrawPoint.Y - (BMP.Height div 2 div ResMod);

  if GameParams.ColourCycle then
  begin
    MakeColorCycle;
    BMP.DrawMode := dmCustom;
    BMP.OnPixelCombine := CombineFixedColor;
  end;

  BMP.DrawTo(fLayers[rlObjectHelpers], DrawPoint.X * ResMod, DrawPoint.Y * ResMod);
  fLayers.fIsEmpty[rlObjectHelpers] := False;
end;

function TRenderer.IsUseful(Gadget: TGadget): Boolean;
begin
  Result := True;
  if not fUsefulOnly then Exit;
  if Gadget.TriggerEffect in [DOM_NONE, DOM_DECORATION] then
    Result := False;

  if (Gadget.TriggerEffect in [DOM_TELEPORT, DOM_RECEIVER]) and (Gadget.PairingId < 0) then
    Result := False;
end;

procedure TRenderer.LoadHelperImages;
var
  i: THelperIcon;
begin
  for i := Low(THelperIcon) to High(THelperIcon) do
  begin
    if i = hpi_None then Continue;
    if fHelperImages[i] <> nil then
      fHelperImages[i].Free;

    fHelperImages[i] := TBitmap32.Create;

    if GameParams.HighResolution and FileExists(AppPath + SFGraphicsHelpersHighRes + HelperImageFilenames[i]) then
      TPngInterface.LoadPngFile(AppPath + SFGraphicsHelpersHighRes + HelperImageFilenames[i], fHelperImages[i])
    else if FileExists(AppPath + SFGraphicsHelpers + HelperImageFilenames[i]) then
      TPngInterface.LoadPngFile(AppPath + SFGraphicsHelpers + HelperImageFilenames[i], fHelperImages[i]);

    fHelperImages[i].DrawMode := dmBlend;
    fHelperImages[i].CombineMode := cmMerge;
  end;

  fHelperImages[hpi_Exit_Lock].DrawMode := dmCustom;
  fHelperImages[hpi_Exit_Lock].OnPixelCombine := CombineFixedColor;

  // And laserer!
  if GameParams.HighResolution then
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'laser-hr.png', fLaserGraphic)
  else
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'laser.png', fLaserGraphic);

  fHelpersAreHighRes := GameParams.HighResolution;
end;

procedure TRenderer.DrawGadgetsOnLayer(aLayer: TRenderLayer);
var
  Dst: TBitmap32;

  function IsValidForLayer(Gadget: TGadget): Boolean;
  begin
    if (Gadget.TriggerEffect = DOM_DECORATION) and not Gadget.IsOnlyOnTerrain then
      Result := aLayer = rlDecorations
    else if Gadget.TriggerEffect in [DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_ONEWAYDOWN, DOM_ONEWAYUP] then
      Result := aLayer = rlOneWayArrows
    else case aLayer of
           rlGadgetsLow: Result := Gadget.IsNoOverwrite and not Gadget.IsOnlyOnTerrain;
           rlOnTerrainGadgets: Result := Gadget.IsOnlyOnTerrain and not Gadget.IsNoOverwrite;
           rlGadgetsHigh: Result := not (Gadget.IsNoOverwrite xor Gadget.IsOnlyOnTerrain);
           else Result := False;
         end;
  end;

  procedure HandleGadget(aIndex: Integer);
  var
    Gadget: TGadget;
  begin
    Gadget := fGadgets[aIndex];
    if (Gadget.TriggerEffectBase in [DOM_ANIMATION, DOM_ANIMONCE]) and GameParams.NoBackgrounds then Exit;
    if not (IsValidForLayer(Gadget) and IsUseful(Gadget)) then Exit;

    if (aLayer = rlDecorations) and (Gadget.CanDrawToBackground) then
      ProcessDrawFrame(Gadget, fLayers[rlBackground])
    else begin
      ProcessDrawFrame(Gadget, Dst);
      fLayers.fIsEmpty[aLayer] := False;
      DrawTriggerArea(Gadget);
    end;
  end;
var
  i: Integer;
begin
  fLayers[aLayer].Lock;
  fLayers[aLayer].BeginUpdate;
  Dst := fLayers[aLayer];
  try
    if not fLayers.fIsEmpty[aLayer] then Dst.Clear(0);

    // Special conditions
    if (aLayer = rlDecorations) and (fUsefulOnly or fDisableBackground) then Exit;
    if (aLayer = rlGadgetsLow) then
      for i := fGadgets.Count-1 downto 0 do
        HandleGadget(i)
    else
      for i := 0 to fGadgets.Count-1 do
        HandleGadget(i);
  finally
    fLayers[aLayer].EndUpdate;
    fLayers[aLayer].Unlock;
  end;
end;

procedure TRenderer.MakeColorCycle;
var
  H: Integer;
begin
  H := GetTickCount mod 5000;
  fFixedDrawColor := HSVToRGB(H / 5000, 1, 0.75);
end;

procedure TRenderer.DrawAllGadgets(Gadgets: TGadgetList; DrawHelper: Boolean = True; UsefulOnly: Boolean = False);
  function IsCursorOnGadget(Gadget: TGadget): Boolean;
  begin
    // Magic numbers are needed due to some offset of MousePos wrt. the center of the cursor.
    Result := PtInRect(Rect(Gadget.Left - 4, Gadget.Top + 1, Gadget.Left + Gadget.Width - 2, Gadget.Top + Gadget.Height + 3),
                      fRenderInterface.MousePos)
  end;

var
  Gadget: TGadget;
  i, i2: Integer;
  DrawOtherHatchHelper: Boolean;
  HatchPoint: TPoint;
begin
  fGadgets := Gadgets;
  fDrawingHelpers := DrawHelper;
  fUsefulOnly := UsefulOnly;

  if fUsefulOnly then
    MakeColorCycle;

  if not fLayers.fIsEmpty[rlTriggers] then fLayers[rlTriggers].Clear(0);
  if not fLayers.fIsEmpty[rlObjectHelpers] then fLayers[rlObjectHelpers].Clear(0);

  fLayers.fIsEmpty[rlTriggers] := True;
  fLayers.fIsEmpty[rlObjectHelpers] := True;

  DrawGadgetsOnLayer(rlDecorations);
  DrawGadgetsOnLayer(rlGadgetsLow);
  DrawGadgetsOnLayer(rlOnTerrainGadgets);
  DrawGadgetsOnLayer(rlOneWayArrows);
  DrawGadgetsOnLayer(rlGadgetsHigh);

  // Draw Exit Marker only if the level contains both Normal and Rival lems
  if RenderInfoRec.Level.Info.HasMixedLemTypes then
  begin
    for i := 0 to Gadgets.Count-1 do
      if Gadgets[i].TriggerEffect in [DOM_EXIT, DOM_LOCKEXIT] then
      begin
        if Gadgets[i].IsRivalExit then
          DrawExitMarkers(Gadgets[i], fAni.ExitMarkerRivalBitmap)
        else
          DrawExitMarkers(Gadgets[i], fAni.ExitMarkerNormalBitmap);
      end;
  end;

  if fRenderInterface = nil then Exit; // Otherwise, some of the remaining code may cause an exception on first rendering

  // Draw hatch helpers
  for i := 0 to Gadgets.Count-1 do
  begin
    Gadget := Gadgets[i];
    if (Gadget.TriggerEffect = DOM_WINDOW) then
    begin
      DrawOtherHatchHelper := fRenderInterface.IsStartingSeconds() or
                              (DrawHelper and UsefulOnly and IsCursorOnGadget(Gadget));

      fLayers.fIsEmpty[rlObjectHelpers] := False;

      if Gadget.HasPreassignedSkills and not GameParams.HideHelpers then
        DrawHatchSkillHelpers(fLayers[rlObjectHelpers], Gadget, False);

      if DrawOtherHatchHelper and not GameParams.HideHelpers then
        DrawObjectHelpers(fLayers[rlObjectHelpers], Gadget);

      if fUsefulOnly then
      begin
        HatchPoint := Gadget.TriggerRect.TopLeft;

        if GameParams.HighResolution then
        begin
          HatchPoint.X := HatchPoint.X * 2;
          HatchPoint.Y := HatchPoint.Y * 2;

          fLayers[rlObjectHelpers].PixelS[HatchPoint.X, HatchPoint.Y] := $FFFFD700;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X+1, HatchPoint.Y] := $FFFFD700;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X, HatchPoint.Y+1] := $FFFFD700;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X+1, HatchPoint.Y+1] := $FFFFD700;

          fLayers[rlObjectHelpers].PixelS[HatchPoint.X-2, HatchPoint.Y] := $FFFF4500;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X-2+1, HatchPoint.Y] := $FFFF4500;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X-2, HatchPoint.Y+1] := $FFFF4500;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X-2+1, HatchPoint.Y+1] := $FFFF4500;

          fLayers[rlObjectHelpers].PixelS[HatchPoint.X, HatchPoint.Y-2] := $FFFF4500;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X+1, HatchPoint.Y-2] := $FFFF4500;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X, HatchPoint.Y-2+1] := $FFFF4500;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X+1, HatchPoint.Y-2+1] := $FFFF4500;

          fLayers[rlObjectHelpers].PixelS[HatchPoint.X+2, HatchPoint.Y] := $FFFF4500;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X+2+1, HatchPoint.Y] := $FFFF4500;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X+2, HatchPoint.Y+1] := $FFFF4500;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X+2+1, HatchPoint.Y+1] := $FFFF4500;

          fLayers[rlObjectHelpers].PixelS[HatchPoint.X, HatchPoint.Y+2] := $FFFF4500;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X+1, HatchPoint.Y+2] := $FFFF4500;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X, HatchPoint.Y+2+1] := $FFFF4500;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X+1, HatchPoint.Y+2+1] := $FFFF4500;
        end else begin
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X, HatchPoint.Y] := $FFFFD700;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X-1, HatchPoint.Y] := $FFFF4500;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X, HatchPoint.Y-1] := $FFFF4500;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X+1, HatchPoint.Y] := $FFFF4500;
          fLayers[rlObjectHelpers].PixelS[HatchPoint.X, HatchPoint.Y+1] := $FFFF4500;
        end;
      end;
    end else
      Continue;
  end;

  // Draw object helpers
  if DrawHelper and UsefulOnly then
  begin
    for i := 0 to Gadgets.Count-1 do
    begin
      Gadget := Gadgets[i];

      if (Gadget.TriggerEffect = DOM_WINDOW) or (not IsCursorOnGadget(Gadget)) or (not IsUseful(Gadget)) then
        Continue;

      // Otherwise, draw its helper
      if not GameParams.HideHelpers then DrawObjectHelpers(fLayers[rlObjectHelpers], Gadget);
      fLayers.fIsEmpty[rlObjectHelpers] := False;

      // If it's a teleporter or receiver, draw all paired helpers too
      if (Gadget.TriggerEffect in [DOM_TELEPORT, DOM_RECEIVER]) and (Gadget.PairingId <> -1) then
        for i2 := 0 to Gadgets.Count-1 do
        begin
          if i = i2 then Continue;
          if (Gadgets[i2].PairingId = Gadget.PairingId) and not GameParams.HideHelpers then
            DrawObjectHelpers(fLayers[rlObjectHelpers], Gadgets[i2]);
        end;
    end;
  end;

  if fRenderInterface.UserHelper <> hpi_None then
      DrawUserHelper;
end;

procedure TRenderer.DrawTriggerAreaRectOnLayer(TriggerRect: TRect);
var
  x, y: Integer;
  PPhys: PColor32;

  PDst: PColor32;
  PDstHR0, PDstHR1, PDstHR2, PDstHR3: PColor32;

  DrawRect: TRect;

  procedure DrawTriggerPixel();
  var
    AlreadyPresent: Boolean;
  begin
    AlreadyPresent := PDst^ <> $00000000;
    if PPhys^ and PM_SOLID = 0 then
      PDst^ := $FFFF00FF
    else if PPhys^ and PM_STEEL <> 0 then
      PDst^ := $FF600060
    else
      PDst^ := $FFA000A0;

    if (x - y) mod 2 <> 0 then
      PDst^ := PDst^ - $00200020;

    if AlreadyPresent then
      PDst^ := PDst^ - $00300030;
  end;

begin
  if    (TriggerRect.Right <= 0) or (TriggerRect.Left > fPhysicsMap.Width)
     or (TriggerRect.Bottom <= 0) or (TriggerRect.Top > fPhysicsMap.Height) Then
    Exit;

  DrawRect := Rect(Max(TriggerRect.Left, 0), Max(TriggerRect.Top, 0),
                   Min(TriggerRect.Right, fPhysicsMap.Width), Min(TriggerRect.Bottom, fPhysicsMap.Height));

  if not GameParams.HighResolution then
  begin
    for y := DrawRect.Top to DrawRect.Bottom - 1 do
    begin
      PDst := fLayers[rlTriggers].PixelPtr[DrawRect.Left, y];
      PPhys := fPhysicsMap.PixelPtr[DrawRect.Left, y];

      for x := DrawRect.Left to DrawRect.Right - 1 do
      begin
        DrawTriggerPixel();

        Inc(PDst);
        Inc(PPhys);
      end;
    end;
  end else begin
    for y := DrawRect.Top to DrawRect.Bottom - 1 do
    begin
      PDstHR0 := fLayers[rlTriggers].PixelPtr[DrawRect.Left * 2, y * 2];
      PDstHR1 := fLayers[rlTriggers].PixelPtr[DrawRect.Left * 2 + 1, y * 2];
      PDstHR2 := fLayers[rlTriggers].PixelPtr[DrawRect.Left * 2, y * 2 + 1];
      PDstHR3 := fLayers[rlTriggers].PixelPtr[DrawRect.Left * 2 + 1, y * 2 + 1];

      PPhys := fPhysicsMap.PixelPtr[DrawRect.Left, y];

      for x := DrawRect.Left to DrawRect.Right - 1 do
      begin
        PDst := PDstHR0; DrawTriggerPixel();
        PDst := PDstHR1; DrawTriggerPixel();
        PDst := PDstHR2; DrawTriggerPixel();
        PDst := PDstHR3; DrawTriggerPixel();

        Inc(PDstHR0, 2);
        Inc(PDstHR1, 2);
        Inc(PDstHR2, 2);
        Inc(PDstHR3, 2);
        Inc(PPhys);
      end;
    end;
  end;

  fLayers.fIsEmpty[rlTriggers] := False;
end;


constructor TRenderer.Create;
var
  S: TResourceStream;
begin
  inherited Create;

  TempBitmap := TBitmap32.Create;
  fTheme := TNeoTheme.Create;
  fLayers := TRenderBitmaps.Create;
  fPhysicsMap := TBitmap32.Create;
  fBgColor := $00000000;
  fAni := TBaseAnimationSet.Create;
  fPreviewGadgets := TGadgetList.Create;
  fTempLemmingList := TLemmingList.Create(False);

  fLaserGraphic := TBitmap32.Create;
  fLaserGraphic.DrawMode := dmCustom;
  fLaserGraphic.OnPixelCombine := CombineFixedColor;

  if not GameParams.HideHelpers then LoadHelperImages;

  FillChar(fParticles, SizeOf(TParticleTable), $80);
  S := TResourceStream.Create(HInstance, 'particles', 'lemdata');
  try
    S.Seek(0, soFromBeginning);
    S.Read(fParticles, S.Size);
  finally
    S.Free;
  end;
end;

destructor TRenderer.Destroy;
var
  iIcon: THelperIcon;
begin
  TempBitmap.Free;
  fTheme.Free;
  fLayers.Free;
  fPhysicsMap.Free;
  fAni.Free;
  fPreviewGadgets.Free;
  fTempLemmingList.Free;
  fLaserGraphic.Free;

  for iIcon := Low(THelperIcon) to High(THelperIcon) do
    fHelperImages[iIcon].Free;

  inherited Destroy;
end;

procedure TRenderer.RenderPhysicsMap(Dst: TBitmap32 = nil);
var
  i: Integer;
  T: TTerrain;
  Gadget: TGadget;

  TempWorld: TBitmap32;

  procedure SetRegion(aRegion: TRect; C, AntiC: TColor32);
  var
    X, Y: Integer;
    P: PColor32;
  begin
    for y := aRegion.Top to aRegion.Bottom-1 do
    begin
      if (y < 0) or (y >= Dst.Height) then Continue;
      for x := aRegion.Left to aRegion.Right-1 do
      begin
        if (x < 0) or (x >= Dst.Width) then Continue;
        P := Dst.PixelPtr[x, y];
        P^ := (P^ or C) and (not AntiC);
      end;
    end;
  end;

  procedure ApplyOWW(Gadget: TGadget);
  var
    C: TColor32;

    TW, TH: Integer;

    procedure HandleRotate;
    var
      Temp: Integer;
    begin
      Temp := TW;
      TW := TH;
      TH := Temp;

      case C of
        PM_ONEWAYLEFT: C := PM_ONEWAYUP;
        PM_ONEWAYUP: C := PM_ONEWAYRIGHT;
        PM_ONEWAYRIGHT: C := PM_ONEWAYDOWN;
        PM_ONEWAYDOWN: C := PM_ONEWAYLEFT;
      end;
    end;

    procedure HandleFlip;
    begin
      case C of
        PM_ONEWAYLEFT: C := PM_ONEWAYRIGHT;
        PM_ONEWAYRIGHT: C := PM_ONEWAYLEFT;
      end;
    end;

    procedure HandleInvert;
    begin
      case C of
        PM_ONEWAYUP: C := PM_ONEWAYDOWN;
        PM_ONEWAYDOWN: C := PM_ONEWAYUP;
      end;
    end;
  begin
    case Gadget.TriggerEffect of
      DOM_ONEWAYLEFT: C := PM_ONEWAYLEFT;
      DOM_ONEWAYRIGHT: C := PM_ONEWAYRIGHT;
      DOM_ONEWAYDOWN: C := PM_ONEWAYDOWN;
      DOM_ONEWAYUP: C := PM_ONEWAYUP;
      else Exit;
    end;

    SetRegion( Gadget.TriggerRect, C, 0);
  end;

  procedure RemoveOverlappingOWWs;
  var
    P: PColor32;
    x, y: Integer;
    n: Integer;
    thisCount: Integer;
  const
    ONE_WAY_FLAGS: array[0..3] of Cardinal = (PM_ONEWAYLEFT, PM_ONEWAYRIGHT, PM_ONEWAYUP, PM_ONEWAYDOWN);
    CANCEL_FLAGS = PM_ONEWAY or PM_ONEWAYLEFT or PM_ONEWAYRIGHT or PM_ONEWAYUP or PM_ONEWAYDOWN;
  begin
    for y := 0 to dst.Height-1 do
    begin
      P := dst.PixelPtr[0, y];
      for x := 0 to dst.Width-1 do
      begin
        thisCount := 0;
        for n := 0 to 3 do
          if P^ and ONE_WAY_FLAGS[n] <> 0 then
            Inc(thisCount);

        if (thisCount <> 1) then
          P^ := P^ and not CANCEL_FLAGS;

        Inc(P);
      end;
    end;
  end;

  procedure Validate;
  var
    X, Y: Integer;
    P: PColor32;
  begin
    for y := 0 to Dst.Height-1 do
      for x := 0 to Dst.Width-1 do
      begin
        P := Dst.PixelPtr[x, y];

        // Remove all terrain markings if it's nonsolid
        if P^ and PM_SOLID = 0 then P^ := P^ and (not PM_TERRAIN);

        // Remove one-way markings if it's steel
        if P^ and PM_STEEL <> 0 then P^ := P^ and not PM_ONEWAY;

        // Remove one-way markings if it's not one-way capable
        if P^ and PM_ONEWAY = 0 then P^ := P^ and not (PM_ONEWAYLEFT or PM_ONEWAYRIGHT or PM_ONEWAYDOWN or PM_ONEWAYUP);
      end;
  end;

  procedure GeneratePhysicsMapFromInfoMap;
  var
    x, y: Integer;
    thisSolidity, thisSteel, thisOneWay: Byte;
    C: TColor32;
    SolidityMod: Single;
    Cutoff: Single;
  begin
    for y := 0 to TempWorld.Height-1 do
      for x := 0 to TempWorld.Width-1 do
      begin
        thisSolidity := (TempWorld[x, y] and $FF000000) shr 24;
        thisSteel    := (TempWorld[x, y] and $00FF0000) shr 16;
        thisOneWay   := (TempWorld[x, y] and $0000FF00) shr 8;

        if thisSolidity >= ALPHA_CUTOFF then
        begin
          C := PM_SOLID or PM_ORIGSOLID;

          SolidityMod := thisSolidity / 255;
          Cutoff := ALPHA_CUTOFF * SolidityMod;

          if thisSteel * SolidityMod >= Cutoff then
            C := C or PM_STEEL
          else if thisOneWay * SolidityMod >= Cutoff then
            C := C or PM_ONEWAY;

          Dst[x, y] := C;
        end else
          Dst[x, y] := 0;
      end;
  end;

begin
  if Dst = nil then Dst := fPhysicsMap;

  TempWorld := TBitmap32.Create;
  T := TTerrain.Create;
  try
    fPhysicsMap.Clear(0);

    with RenderInfoRec.Level do
    begin
      Dst.SetSize(Info.Width, Info.Height);
      TempWorld.SetSize(Info.Width, Info.Height);
      TempWorld.Clear(0);

      for i := 0 to Terrains.Count-1 do
      begin
        T.Assign(Terrains[i]);
        InternalDrawTerrain(TempWorld, T, True, False);
      end;

      GeneratePhysicsMapFromInfoMap;

      for i := 0 to fPreviewGadgets.Count-1 do
      begin
        Gadget := fPreviewGadgets[i];
        ApplyOWW(Gadget); // ApplyOWW takes care of ignoring non-OWW objects, no sense duplicating the check
      end;

      RemoveOverlappingOWWs;
    end;

    Validate;
  finally
    TempWorld.Free;
    T.Free;
  end;
end;

procedure TRenderer.RenderWorld(World: TBitmap32; DoBackground: Boolean); // Called only from Preview Screen
var
  i: Integer;
  x, y: Integer;

  Lem: TPreplacedLemming;
  L: TLemming;
  BgImg: TBitmap32;

  procedure CheckLockedExits;
  var
    i: Integer;
    HasButtons: Boolean;
  begin
    HasButtons := False;
    // Check whether buttons exist
    for i := 0 to fPreviewGadgets.Count - 1 do
    begin
      if fPreviewGadgets[i].TriggerEffect = DOM_BUTTON then
        HasButtons := True;
    end;
    if not HasButtons then
    begin
      // Set all exits to open exits
      for i := 0 to fPreviewGadgets.Count - 1 do
      begin
        if fPreviewGadgets[i].TriggerEffect in [DOM_EXIT, DOM_LOCKEXIT] then
          fPreviewGadgets[i].CurrentFrame := 0
      end;
    end
  end;

  procedure LoadBackgroundImage(IsFallback: Boolean = False);
  var
    Collection, Piece: String;
    SplitPos: Integer;
    NeedUpscale: Boolean;
    Info: TUpscaleInfo;
  begin
    if IsFallback then
    begin
      Collection := 'default';
      Piece := 'fallback';
    end else begin
      SplitPos := pos(':', RenderInfoRec.Level.Info.Background);
      Collection := LeftStr(RenderInfoRec.Level.Info.Background, SplitPos-1);
      Piece := RightStr(RenderInfoRec.Level.Info.Background, Length(RenderInfoRec.Level.Info.Background)-SplitPos);
    end;

    NeedUpscale := GameParams.HighResolution;
    if FileExists(AppPath + SFStyles + Collection + SFPiecesBackgroundsHighRes + Piece + '.png') then
    begin
      TPngInterface.LoadPngFile((AppPath + SFStyles + Collection + SFPiecesBackgrounds + Piece + '.png'), BgImg);
      NeedUpscale := False;
    end else if FileExists(AppPath + SFStyles + Collection + SFPiecesBackgrounds + Piece + '.png') then
      TPngInterface.LoadPngFile((AppPath + SFStyles + Collection + SFPiecesBackgrounds + Piece + '.png'), BgImg)
    else if not IsFallback then
    begin
      LoadBackgroundImage(IsFallback);
      Exit; // Don't upscale twice!
    end;

    if NeedUpscale then
    begin
      Info := PieceManager.GetUpscaleInfo(Collection + ':' + Piece, rkBackground);
      Upscale(BgImg, Info.Settings);
    end;
  end;

  function CanShimmy: Boolean;
  begin
    Result := ((fPhysicsMap.PixelS[L.LemX, L.LemY - 9] and PM_SOLID) <> 0)
           or ((fPhysicsMap.PixelS[L.LemX, L.LemY - 10] and PM_SOLID) <> 0);
  end;
begin
  if RenderInfoRec.Level = nil then Exit;

  fDisableBackground := not DoBackground;
  fDoneBackgroundDraw := False;

  // Background layer
  fBgColor := Theme.Colors[BACKGROUND_COLOR] and $FFFFFF;

  if fTransparentBackground then
    fLayers[rlBackground].Clear(0)
  else
    fLayers[rlBackground].Clear($FF000000 or fBgColor);

  if DoBackground and (RenderInfoRec.Level.Info.Background <> '') and (RenderInfoRec.Level.Info.Background <> ':') then
  begin
    BgImg := TBitmap32.Create;
    try
      LoadBackgroundImage;
      for y := 0 to RenderInfoRec.Level.Info.Height * ResMod div BgImg.Height do
        for x := 0 to RenderInfoRec.Level.Info.Width * ResMod div BgImg.Width do
          BgImg.DrawTo(fLayers[rlBackground], x * BgImg.Width, y * BgImg.Height);
    finally
      BgImg.Free;
    end;
  end;

  // Check whether there are no buttons to display open exits
  CheckLockedExits;

  // Draw all objects (except ObjectHelpers)
  DrawAllGadgets(fPreviewGadgets, False);

  // Draw preplaced lemmings
  L := TLemming.Create;
  for i := 0 to RenderInfoRec.Level.PreplacedLemmings.Count-1 do
  begin
    Lem := RenderInfoRec.Level.PreplacedLemmings[i];

    L.SetFromPreplaced(Lem);
    L.LemIsZombie := Lem.IsZombie;

    if Lem.IsShimmier then
    begin
      if CanShimmy then
        L.LemAction := baShimmying
      else
        L.LemAction := baReaching;
    end else if Lem.IsBallooner then
      L.LemAction := baBallooning
    else if (fPhysicsMap.PixelS[L.LemX, L.LemY] and PM_SOLID = 0) then
      L.LemAction := baFalling
    else if Lem.IsBlocker then
      L.LemAction := baBlocking
    else
      L.LemAction := baWalking;

    DrawThisLemming(L);
  end;
  L.Free;

  // Draw all terrain pieces
  for i := 0 to RenderInfoRec.Level.Terrains.Count-1 do
  begin
    DrawTerrain(fLayers[rlTerrain], RenderInfoRec.Level.Terrains[i], GameParams.HighResolution);
  end;

  // Remove non-solid pixels from rlTerrain (possible coming from alpha-blending)
  ApplyRemovedTerrain(0, 0, fPhysicsMap.Width, fPhysicsMap.Height);

  // Combine all layers to the WorldMap
  if World <> nil then
  begin
    World.SetSize(fLayers.Width * ResMod, fLayers.Height * ResMod);
    fLayers.PhysicsMap := fPhysicsMap;
    fLayers.CombineTo(World, World.BoundsRect, False, fTransparentBackground);
  end;
end;


procedure TRenderer.CreateGadgetList(var Gadgets: TGadgetList);
var
  i, n: Integer;
  Gadget: TGadget;
  MO: TGadgetMetaAccessor;
begin
  for i := 0 to RenderInfoRec.Level.InteractiveObjects.Count - 1 do
  begin
    MO := FindGadgetMetaInfo(RenderInfoRec.Level.InteractiveObjects[i]);
    Gadget := TGadget.Create(RenderInfoRec.Level.InteractiveObjects[i], MO);

    // Check whether trigger area intersects the level area, except for moving backgrounds
    if    (Gadget.TriggerRect.Top > RenderInfoRec.Level.Info.Height)
       or (Gadget.TriggerRect.Bottom < 0)
       or (Gadget.TriggerRect.Right < 0)
       or (Gadget.TriggerRect.Left > RenderInfoRec.Level.Info.Width) then
    begin
      if not (Gadget.TriggerEffect in [DOM_DECORATION, DOM_ANIMATION, DOM_ANIMONCE]) then
        Gadget.TriggerEffect := DOM_NONE; // Effectively disables the object
    end;

    if (MO.TriggerEffect = DOM_WINDOW) then
    begin
      Gadget.ShowRemainingLemmings := (Gadget.RemainingLemmingsCount > 0) or (Gadget.IsPreassignedZombie);
      Gadget.RemainingLemmingsCount := 0;
      for n := 0 to Length(RenderInfoRec.Level.Info.SpawnOrder)-1 do
        if RenderInfoRec.Level.Info.SpawnOrder[n] = i then
          Gadget.RemainingLemmingsCount := Gadget.RemainingLemmingsCount + 1;
    end;

    Gadgets.Add(Gadget);
  end;

  // Get ReceiverID for all Teleporters
  Gadgets.FindReceiverID;

  // Run "PrepareAnimationInstances" for all gadgets. This differs from CreateAnimationInstances which is done earlier.
  Gadgets.InitializeAnimations;
end;

procedure TRenderer.InitializeBrickColors(aBrickPixelColor: TColor32);
var
  i: Integer;
begin
  with TColor32Entry(aBrickPixelColor) do
  for i := 0 to High(BrickPixelColors) do
  begin
    TColor32Entry(BrickPixelColors[i]).A := A;
    TColor32Entry(BrickPixelColors[i]).R := Min(Max(R + (i - 6) * 4, 0), 255);
    TColor32Entry(BrickPixelColors[i]).B := Min(Max(B + (i - 6) * 4, 0), 255);
    TColor32Entry(BrickPixelColors[i]).G := Min(Max(G + (i - 6) * 4, 0), 255);
  end;
end;

procedure TRenderer.PrepareGameRendering(aLevel: TLevel; NoOutput: Boolean = False);
begin

  if GameParams.HighResolution <> fHelpersAreHighRes and not GameParams.HideHelpers then
    LoadHelperImages;

  RenderInfoRec.Level := aLevel;

  fTheme.Load(aLevel.Info.GraphicSetName);
  PieceManager.SetTheme(fTheme);
  fAni.ClearData;
  fAni.Theme := fTheme;

  try
    fAni.PrepareAnimations;

    if (aLevel.Info.ZombieCount > 0) and (not fAni.HasZombieColor) then
      raise Exception.Create('Specified lemming spriteset does not include zombie coloring.');

    if (aLevel.Info.NeutralCount > 0) and (not fAni.HasNeutralColor) then
      raise Exception.Create('Specified lemming spriteset does not include neutral coloring.');

    if (aLevel.Info.RivalCount > 0) and (not fAni.HasRivalColor) then
      raise Exception.Create('Specified lemming spriteset does not include rival coloring.');

  except
    on E: Exception do
    begin
      fTheme.Load('orig_crystal'); // We need to actually choose a theme, not just set the default sprites
      PieceManager.SetTheme(fTheme);
      fAni.ClearData;
      fAni.Theme := fTheme;

      fAni.PrepareAnimations;

      fTheme.SpriteFallbackMessage := E.Message + #13 + #13 + 'The default sprites will be loaded instead.';
    end;
  end;

  PieceManager.RegenerateAutoAnims(fTheme, fAni);

  // Prepare the bitmaps
  fLayers.Prepare(RenderInfoRec.Level.Info.Width, RenderInfoRec.Level.Info.Height);

  // Creating the list of all interactive objects.
  fPreviewGadgets.Clear;
  CreateGadgetList(fPreviewGadgets);

  if fRenderInterface <> nil then
  begin
    fRenderInterface.UserHelper := hpi_None;
    fRenderInterface.DisableDrawing := NoOutput;
  end;

  // Recolor bricks and spears
  if fTheme <> nil then
  begin
    InitializeBrickColors(fTheme.Colors['MASK']);
    DoProjectileRecolor(fAni.SpearBitmap, fTheme.Colors['MASK']);
  end;

  // Prepare any composite pieces
  PieceManager.RemoveCompositePieces;
  PieceManager.MakePiecesFromGroups(aLevel.TerrainGroups);

  RenderPhysicsMap;
end;

end.

