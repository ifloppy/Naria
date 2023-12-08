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
  unitresourcestring, ceosmw, unitformnewtask, opensslsockets, DefaultTranslator,
  LazFileUtils, unitformtrackersource, UniqueInstanceRaw, Dialogs
  { you can add units after this }, ceosclient, process;

{$R *.res}
var
  rpcClient: TCeosClient;
  S: String;
begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  if InstanceRunning then begin
    ShowMessage(AnotherInstance);
    Application.Terminate;
  end;
  GlobalConfig:=TIniFile.Create('config.ini');
  if not FileExistsUTF8('download.session') then begin
    FileCreateUTF8('download.session');
  end;

  if not GlobalConfig.SectionExists('RPC') then begin
    FormSettings:=TFormSettings.Create(nil);
    FormSettings.FirstUse:=true;
    FormSettings.ShowModal;
    FormSettings.Free;
  end;
  {$IfDef WINDOWS}
  //若Aria2已运行，则温柔地退出，然后再启动
  if processExists(ariaExecutable) then begin
    rpcClient:=TCeosClient.Create(nil);
    rpcClient.Host:='http://127.0.0.1:'+GlobalConfig.ReadString('RPC', 'port', '6800')+'/jsonrpc';
    rpcClient.Call('aria2.shutdown', [AriaParamToken], 0);
    rpcClient.Call('aria2.saveSession', [AriaParamToken], 0);
    rpcClient.Free;
    RunCommand('taskkill /f /im '+ariaExecutable, S);
  end;
  {$EndIf}
  AriaProcessManager:=TAriaProcessManager.Create;
  AriaProcessManager.Execute();
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;

  GlobalConfig.Free;
end.

