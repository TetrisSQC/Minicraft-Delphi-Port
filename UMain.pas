unit UMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Platform,
  UGame, USound, UJoystick, FMX.Objects;

type
  TfrmMain = class(TForm)
    imgSprites: TImage;
    tmrTick: TTimer;
    procedure FormPaint(Sender: TObject; Canvas: TCanvas;
      const [Ref] ARect: TRectF);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormGesture(Sender: TObject;
      const [Ref] EventInfo: TGestureEventInfo; var Handled: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure tmrTickTimer(Sender: TObject);
  private
    { Private-Deklarationen }
    FGame: TGame;
    FJoystick: TJoystick;
    FLastJoystickPos: TJoystickPosition;
    FBackBuffer: TBitmap;

    procedure UpdateButtons;
    function AppEvent(AAppEvent: TApplicationEvent; AContext: TObject): Boolean;
    procedure RenderTo(const Canvas: TCanvas);
  public
    { Public-Deklarationen }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

function FitRect(var R: TRectF; const BoundsRect: TRectF): Single; inline;
var
  ratio: Single;
begin
  Result := 1;
  if RectWidth(BoundsRect) * RectHeight(BoundsRect) = 0 then
    exit;
  if (RectWidth(R) / RectWidth(BoundsRect)) >
    (RectHeight(R) / RectHeight(BoundsRect)) then
    ratio := RectWidth(R) / RectWidth(BoundsRect)
  else
    ratio := RectHeight(R) / RectHeight(BoundsRect);

  R := RectF(0, 0, round(RectWidth(R) / ratio), round(RectHeight(R) / ratio));

  Result := ratio;
  RectCenter(R, BoundsRect);
end;

function TfrmMain.AppEvent(AAppEvent: TApplicationEvent;
  AContext: TObject): Boolean;
begin
  case AAppEvent of
    TApplicationEvent.EnteredBackground:
      FGame.hasFocus := false;
    TApplicationEvent.WillBecomeForeground:
      FGame.hasFocus := true;
  end;
  Result := true;
end;

procedure TfrmMain.UpdateButtons;
var
  pos: TJoystickPosition;
begin
  pos := FJoystick.Position;

  if (jaLeft in FLastJoystickPos) and (not(jaLeft in pos)) then
    FGame.input.left.Toggle(false);
  if (jaUp in FLastJoystickPos) and (not(jaUp in pos)) then
    FGame.input.up.Toggle(false);
  if (jaDown in FLastJoystickPos) and (not(jaDown in pos)) then
    FGame.input.down.Toggle(false);
  if (jaRight in FLastJoystickPos) and (not(jaRight in pos)) then
    FGame.input.right.Toggle(false);

  if (jaLeft in pos) then
    FGame.input.left.Toggle(true);
  if (jaUp in pos) then
    FGame.input.up.Toggle(true);
  if (jaDown in pos) then
    FGame.input.down.Toggle(true);
  if (jaRight in pos) then
    FGame.input.right.Toggle(true);

  FLastJoystickPos := pos;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  i, X, Y, w, h: integer;
  pixels: TGamePixelBuffer;
  Data: TBitmapData;
  radius: integer;
  AppEventSvc: IFMXApplicationEventService;
  GameWidth, GameHeight: integer;
begin
  if TPlatformServices.Current.SupportsPlatformService
    (IFMXApplicationEventService, IInterface(AppEventSvc)) then
    AppEventSvc.SetApplicationEventHandler(AppEvent);

{$IF Defined(IOS) OR Defined(ANDROID)}
  BorderStyle := TFMXFormBorderStyle.None;
{$ENDIF}
{$IFDEF MSWINDOWS}
  // System.ReportMemoryLeaksOnShutdown := true;
  // 960 x 640 3 inch
  // 1136 x 640 4 inch
  // 1334 x 750 4.7 inch
  // 2208 x 1242 5.5 inch
  // 1536 x 2048 ipad
{$ENDIF}
  w := ClientWidth;
  h := ClientHeight;
  if h > w then
  begin
    w := ClientHeight;
    h := ClientWidth;
  end;

  GameWidth := 8 * 28;
  GameHeight := trunc(GameWidth * h / w);

  FBackBuffer := TBitmap.create(GameWidth, GameHeight);

  w := imgSprites.Bitmap.Width;
  h := imgSprites.Bitmap.Height;
  setlength(pixels, w * h);
  imgSprites.Bitmap.Map(TMapAccess.Read, Data);
  i := 0;
  for Y := 0 to h - 1 do
    for X := 0 to w - 1 do
    begin
      pixels[i] := Data.GetPixel(X, Y);
      inc(i);
    end;
  imgSprites.Bitmap.Unmap(Data);

  FGame := TGame.create(w, h, pixels, GameWidth, GameHeight);

  Quality := TCanvasQuality.HighPerformance;
  setlength(pixels, 0);

  // -- Create Virtual Joystick --------------------------------------------------
  w := ClientWidth;
  if w < ClientHeight then
    w := ClientHeight;

  FJoystick := TJoystick.create;
  FLastJoystickPos := [];

  FJoystick.CenterRadius := trunc(w / 16);
  FJoystick.StickRadius := round(FJoystick.CenterRadius * 0.45);

  radius := trunc(w / 20);
  FJoystick.Add(-3 * radius, trunc(-1.3 * radius) - 80, $50FF0000, radius);
  FJoystick.Add(-trunc(1.3 * radius), (-3 * radius) - 80, $5000FF00, radius);

  FJoystick.Show(100, ClientHeight - 150, true);
  FJoystick.ShowButtons(true);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FJoystick.Free;
  FGame.Free;
  FBackBuffer.Free;
end;

procedure TfrmMain.FormGesture(Sender: TObject;
  const [Ref] EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
  if EventInfo.GestureID = igiDoubleTap then
    FGame.input.attack.Toggle(true);
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
{$IFDEF MSWINDOWS}
const
  Sizes: Array [0 .. 5] of TSize = ((cx: 960; cy: 640), // 3 inch
    (cx: 1136; cy: 640), // 4 inch
    (cx: 1334; cy: 750), // 4.7 inch
    (cx: 2208; cy: 1242), // 5.5 inch
    (cx: 2048; cy: 1536), // IPad
    (cx: 2732; cy: 2048)); // IPad Pro

var
  k: Word;
  bmp: TBitmap;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  if Key = 123 then // F12
  begin
    bmp := TBitmap.create;
    for k := 0 to high(Sizes) do
    begin
      with Sizes[k] do
        bmp.SetSize(cx, cy);
      RenderTo(bmp.Canvas);
      bmp.SaveToFile(format('%dx%d_%d.png', [bmp.Width, bmp.Height,
        TThread.GetTickCount]));
    end;
    bmp.Free;
    exit;
  end;

  if Key <> 0 then
    k := Key
  else
    k := ord(KeyChar);
  FGame.input.Toggle(k, true);
{$ENDIF}
end;

procedure TfrmMain.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
{$IFDEF MSWINDOWS}
var
  k: Word;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  if Key <> 0 then
    k := Key
  else
    k := ord(KeyChar);

  FGame.input.Toggle(k, false);
{$ENDIF}
end;

procedure TfrmMain.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if (FJoystick.Passive) and (FJoystick.Visible) then
    FJoystick.Hide;

  if FGame.MouseClick(trunc(X / ClientWidth * FBackBuffer.Width),
    trunc(Y / ClientHeight * FBackBuffer.Height)) then
    exit;

  if X < ClientWidth * 2 / 3 then
    FJoystick.Show(X, Y);

  if FJoystick.CheckClicked(X - ClientWidth, Y - ClientHeight) then
    case FJoystick.LastButtonClicked of
      0:
        FGame.input.attack.Toggle(true);
      1:
        FGame.input.menu.Toggle(true);
    end;
end;

procedure TfrmMain.FormMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single);
begin
  if FJoystick.MoveAxis(X, Y) then
    UpdateButtons;
end;

procedure TfrmMain.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  FJoystick.Hide;
  case FJoystick.LastButtonClicked of
    0:
      FGame.input.attack.Toggle(false);
    1:
      FGame.input.menu.Toggle(false);
  end;
  FGame.input.ReleaseAll;
end;

procedure TfrmMain.FormPaint(Sender: TObject; Canvas: TCanvas;
  const [Ref] ARect: TRectF);
begin
  RenderTo(Canvas);
end;

procedure TfrmMain.RenderTo(const Canvas: TCanvas);
var
  RenderTarget: TRectF;
begin
  Canvas.BeginScene(nil);
  try
    Canvas.Clear(TAlphacolors.Black);

    RenderTarget := RectF(0, 0, FBackBuffer.Width, FBackBuffer.Height);
    FitRect(RenderTarget, RectF(0, 0, Canvas.Width, Canvas.Height));

    FGame.RenderBitmap(FBackBuffer);
    Canvas.DrawBitmap(FBackBuffer, RectF(0, 0, FBackBuffer.Width,
      FBackBuffer.Height), RenderTarget, 1, true);

    FJoystick.Update(Canvas, Canvas.Width, Canvas.Height);
  finally
    Canvas.EndScene;
  end;
end;

procedure TfrmMain.tmrTickTimer(Sender: TObject);
begin
  if (Visible) and (not FGame.suspended) then
    Invalidate;
end;

end.
