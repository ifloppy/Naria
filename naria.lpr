program naria;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, unitformmain, unitformsettings, unitcommon, IniFiles,
  unitresourcestring, ceosmw, unitformnewtask
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  GlobalConfig:=TIniFile.Create('config.ini');
  if not GlobalConfig.SectionExists('RPC') then begin
    FormSettings:=TFormSettings.Create(nil);
    FormSettings.FirstUse:=true;
    FormSettings.ShowModal;
    FormSettings.Free;
  end;
  AriaProcessManager:=TAriaProcessManager.Create;
  AriaProcessManager.Execute();
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TFormNewTask, FormNewTask);
  Application.Run;

  GlobalConfig.Free;
end.

