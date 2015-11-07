unit USound;

interface

type
  TSoundEffect = (sePlayerHurt, sePlayerDeath, seMonsterHurt, seClick, sePickup,
    seBossDeath, seCraft);

  TAudioStream = record
    Name: String;
    Handle: Cardinal;
    IsSample: Boolean;
  end;

  TSound = class
  private
    FStreams: Array of TAudioStream;

    procedure AddSample(const AName: String; const AFilename: String;
      const AIsSample: Boolean = True);
    function GetStream(const AName: String; const AIsSample: Boolean = True)
      : Cardinal;
    procedure ClearStreams;
  public
    constructor create;
    destructor Destroy; override;

    procedure Play(const AEffect: TSoundEffect); overload;
    procedure Play(const AEffect: String); overload;
    procedure PlayMusic(const Effect: String);
  end;

function Sound: TSound;

implementation

uses SysUtils, Classes, Types, Bass;

var
  FSound: TSound;

function Sound: TSound;
begin
  if not assigned(FSound) then
    FSound := TSound.create;
  result := FSound;
end;

{ TSound }
constructor TSound.create;
var
  b: Boolean;
begin
{$IFDEF MSWINDOWS}
  b := BASS_Init(-1, 44100, 0, 0, nil);
{$ELSE}
  b := BASS_Init(-1, 44100, 0, nil, nil);
{$ENDIF}
  if b then
  begin
    BASS_SetConfig(BASS_CONFIG_NET_PLAYLIST, 1); // enable playlist processing
    BASS_SetConfig(BASS_CONFIG_NET_READTIMEOUT, 2000);
    BASS_SetConfig(BASS_CONFIG_IOS_SPEAKER, 1);
    BASS_SetConfig(BASS_CONFIG_NET_PREBUF, 0);
  end;

  AddSample('bossdeath', '');
  AddSample('craft', '');
  AddSample('death', '');
  AddSample('monsterhurt', '');
  AddSample('pickup', '');
  AddSample('playerhurt', '');
  AddSample('test', '');

  // Music
  // AddSample('forest1', '', false);
end;

destructor TSound.Destroy;
begin
  ClearStreams;
  inherited;
end;

procedure TSound.AddSample(const AName: String; const AFilename: String;
  const AIsSample: Boolean = True);
var
  Sample: Cardinal;
  res: TResourceStream;
begin
  if AFilename = '' then
  begin
    res := TResourceStream.create(Hinstance, AName, RT_RCDATA);
    if AIsSample then
      Sample := BASS_SampleLoad(True, res.Memory, 0, res.Size, 3,
        BASS_SAMPLE_OVER_POS {$IFDEF UNICODE} or BASS_UNICODE
{$ENDIF})
    else
     Sample := BASS_MusicLoad(true, res.Memory, 0, res.Size,
      BASS_STREAM_AUTOFREE {$IFDEF UNICODE} or BASS_UNICODE {$ENDIF} , 44100);
    res.Free;
  end
  else if AIsSample then
    Sample := BASS_SampleLoad(false, PChar(AFilename), 0, 0, 3,
      BASS_SAMPLE_OVER_POS
{$IFDEF UNICODE} or BASS_UNICODE {$ENDIF})
  else
     Sample := BASS_MusicLoad(false, PChar(AFilename), 0, 0,
      BASS_STREAM_AUTOFREE {$IFDEF UNICODE} or BASS_UNICODE {$ENDIF} , 44100);

  if (AName <> '') and (Sample <> 0) then
  begin
    SetLength(FStreams, length(FStreams) + 1);
    with FStreams[high(FStreams)] do
    begin
      Name := AName;
      IsSample := AIsSample;
      Handle := Sample;
    end;
  end;
end;

procedure TSound.ClearStreams;
var
  i: Integer;
begin
  for i := 0 to high(FStreams) do
    if FStreams[i].IsSample then
      BASS_SampleFree(FStreams[i].Handle)
    else
      BASS_MusicFree(FStreams[i].Handle);
  SetLength(FStreams, 0);
end;

function TSound.GetStream(const AName: string; const AIsSample: Boolean = True)
  : Cardinal;
var
  i: Integer;
begin
  result := 0;
  for i := 0 to high(FStreams) do
    with FStreams[i] do
      if (Name = AName) and (IsSample = AIsSample) then
      begin
        result := Handle;
        exit;
      end;
end;

procedure TSound.Play(const AEffect: String);
var
  ch: Cardinal;
begin
  ch := BASS_SampleGetChannel(GetStream(AEffect, True), false);
  if ch <> 0 then
    BASS_ChannelPlay(ch, false);
end;

procedure TSound.Play(const AEffect: TSoundEffect);
begin
  case AEffect of
    sePlayerHurt:
      Play('playerhurt');
    sePlayerDeath:
      Play('playerdeath');
    seMonsterHurt:
      Play('monsterhurt');
    seClick:
      Play('test');
    sePickup:
      Play('pickup');
    seBossDeath:
      Play('bossdeath');
    seCraft:
      Play('craft');
  end;
end;

procedure TSound.PlayMusic(const Effect: string);
begin
  BASS_ChannelPlay(GetStream(Effect, false), true);
end;

initialization

finalization

FreeAndNil(FSound);

end.
