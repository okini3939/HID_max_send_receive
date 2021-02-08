program HID_test;

uses
  Vcl.Forms,
  main in 'main.pas' {Form1},
  UHIDThread in 'UHIDThread.pas',
  Hid in 'Hid.pas',
  SetupApi in 'SetupApi.pas',
  ModuleLoader in 'ModuleLoader.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
