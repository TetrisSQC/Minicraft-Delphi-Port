unit UJoystick;

interface

uses System.Classes, System.Types, System.UITypes, FMX.Graphics;

type
  TJoystickAxis = (jaUp, jaDown, jaLeft, jaRight);
  TJoystickPosition = set of TJoystickAxis;

  TJoystickButton = record
    Pos: TPointF;
    Radius: Single;
    Color: TAlphaColor;
  end;

  TJoystickVisible = (tsNone, tsStick, tsButtons, tsPassive);
  TJoystickVisibleSet = Set of TJoystickVisible;
  TFadeState = (vsNoFade, vsFadeIn,vsFadeOut);

  TJoystick = class
  protected
    FCenter, FStick: TPointF;
    FPosition: TJoystickPosition;
    FButtons: Array of TJoystickButton;
    FLastButtonClicked: Integer;
    FVisible: TJoystickVisibleSet;
    FFadeState: TFadeState;

    function GetPassive: Boolean;
    function GetVisible: Boolean;
  public
    CenterRadius, StickRadius: Single;

    constructor Create;
    destructor Destroy; override;

    procedure Add(const X, Y: Single; const Color: TAlphaColor;
      const Radius: Single = 10);
    procedure Hide();
    procedure Show(const X, Y: Single; const Passive: Boolean = false);
    procedure ShowButtons(Visible: Boolean);

    function MoveAxis(const X, Y: Single): Boolean;

    procedure Update(const Canvas: TCanvas; const W, H: Integer);
    function CheckClicked(const X, Y: Single): Boolean;

    property Position: TJoystickPosition read FPosition;
    property Passive: Boolean read GetPassive;
    property Visible: Boolean read GetVisible;
    property LastButtonClicked: Integer read FLastButtonClicked;
  end;

implementation

uses System.Math;

{ TJoystick }
constructor TJoystick.Create;
begin
  FCenter := PointF(0, 0);
  FStick := PointF(0, 0);
  CenterRadius := 40;
  StickRadius := 15;
  FPosition := [];
  SetLength(FButtons, 0);
end;

destructor TJoystick.Destroy;
begin
  SetLength(FButtons, 0);
  inherited;
end;

function TJoystick.CheckClicked(const X: Single; const Y: Single): Boolean;
var
  i: Integer;
  rad: Single;
begin
  FLastButtonClicked := -1;
  for i := 0 to High(FButtons) do
  begin
    rad := sqrt(Power(X - FButtons[i].Pos.X, 2) +
      Power(Y - FButtons[i].Pos.Y, 2));
    if rad < FButtons[i].Radius then
    begin
      FLastButtonClicked := i;
      break;
    end;
  end;
  result := FLastButtonClicked <> -1;
end;

procedure TJoystick.Add(const X, Y: Single; const Color: TAlphaColor;
  const Radius: Single = 10);
begin
  SetLength(FButtons, Length(FButtons) + 1);
  FButtons[High(FButtons)].Pos := PointF(X, Y);
  FButtons[High(FButtons)].Radius := Radius;
  FButtons[High(FButtons)].Color := Color;
end;

procedure TJoystick.Show(const X, Y: Single; const Passive: Boolean = false);
begin
  FCenter := PointF(X, Y);
  FStick := FCenter;
  include(FVisible, tsStick);
  if Passive then
    include(FVisible, tsPassive)
  else
    Exclude(FVisible, tsPassive);

end;

procedure TJoystick.Hide();
begin
  Exclude(FVisible, tsStick);
  Exclude(FVisible, tsPassive);
end;

procedure TJoystick.ShowButtons(Visible: Boolean);
begin
  if Visible then
    include(FVisible, tsButtons)
  else
    Exclude(FVisible, tsButtons);
end;

function TJoystick.MoveAxis(const X, Y: Single): Boolean;
var
  rx, ry: Single;
  max, angle, amount: Single;
  NewPos: TJoystickPosition;
  density: Single;
begin
  result := false;

  if not(tsStick in FVisible) or (tsPassive in FVisible) then
    exit;

  rx := X - FCenter.X;
  ry := Y - FCenter.Y;
  max := (CenterRadius - StickRadius / 3);

  angle := arctan2(rx, -ry);
  amount := min(max, sqrt(rx * rx + ry * ry));

  FStick.X := FCenter.X + sin(angle) * amount;
  FStick.Y := FCenter.Y - cos(angle) * amount;

  density := max / 5;

  NewPos := [];
  if FStick.X - FCenter.X < -density then
    include(NewPos, jaLeft);
  if FStick.X - FCenter.X > density then
    include(NewPos, jaRight);
  if FStick.Y - FCenter.Y < -density then
    include(NewPos, jaUp);
  if FStick.Y - FCenter.Y > density then
    include(NewPos, jaDown);

  result := FPosition <> NewPos;
  FPosition := NewPos;
end;

procedure TJoystick.Update(const Canvas: TCanvas; const W, H: Integer);
var
  i: Integer;
  col: TAlphaColor;
  R: TRectF;
begin
  col := $50FFFFFF;
  Canvas.Stroke.Color := col;

  if tsStick in FVisible then
  begin
    Canvas.Stroke.Thickness := 2;
    Canvas.Stroke.Kind := tBrushKind.Solid;

    Canvas.DrawEllipse(RectF(FCenter.X - CenterRadius, FCenter.Y - CenterRadius,
      FCenter.X + CenterRadius, FCenter.Y + CenterRadius), 1);

    Canvas.Fill.Color := col; // $FFFF0000;
    Canvas.FillEllipse(RectF(FStick.X - StickRadius, FStick.Y - StickRadius,
      FStick.X + StickRadius, FStick.Y + StickRadius), 1);

    Canvas.Stroke.Thickness := 1;
  end;

  if tsButtons in FVisible then
    for i := 0 to high(FButtons) do
    begin
      Canvas.Fill.Color := FButtons[i].Color;
      R := RectF(W + FButtons[i].Pos.X - FButtons[i].Radius,
        H + FButtons[i].Pos.Y - FButtons[i].Radius, W + FButtons[i].Pos.X +
        FButtons[i].Radius, H + FButtons[i].Pos.Y + FButtons[i].Radius);
      Canvas.DrawEllipse(R, 1);

      R := RectF(W + FButtons[i].Pos.X - FButtons[i].Radius + 3,
        H + FButtons[i].Pos.Y - FButtons[i].Radius + 3, W + FButtons[i].Pos.X +
        FButtons[i].Radius - 3, H + FButtons[i].Pos.Y + FButtons[i].Radius - 3);

      Canvas.FillEllipse(R, 1);
    end;
end;

function TJoystick.GetPassive: Boolean;
begin
  result := tsPassive in FVisible;
end;

function TJoystick.GetVisible: Boolean;
begin
  result := tsStick in FVisible;
end;

end.
