program Terraformer;

{$R *.dres}

uses
  System.StartUpCopy,
  FMX.Forms,
  UMain in 'UMain.pas' {frmMain},
  UJoystick in 'Units\UJoystick.pas',
  UGame in 'Units\UGame.pas',
  USound in 'Units\USound.pas',
  Bass in 'Units\Bass.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
