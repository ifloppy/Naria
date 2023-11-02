unit unitcommon;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, AsyncProcess;

const
  {$IfDef Windows}
  ariaExecutable = 'aria2c.exe';
  {$ElseIf}
  ariaExecutable = 'aria2c';
  {$EndIf}

type
  TAriaProcessManager = class
  private
    ProcessInstance: TAsyncProcess;
  public
    procedure Execute();
    procedure LoadConfig();
    constructor Create;
    destructor Destroy; override;
  end;

function FileSizeToHumanReadableString(FileSize: int64): string;

var
  GlobalConfig: TIniFile;
  AriaProcessManager: TAriaProcessManager;
  AriaParamToken: string;

implementation

constructor TAriaProcessManager.Create;

begin
  Self.ProcessInstance:=TAsyncProcess.Create(nil);
  ProcessInstance.Executable:=GetCurrentDir+'/'+ariaExecutable;

  LoadConfig();
end;

destructor TAriaProcessManager.Destroy;
begin
  ProcessInstance.Terminate(0);
  ProcessInstance.Free;
end;

procedure TAriaProcessManager.Execute();
begin
  ProcessInstance.Execute;
end;

procedure TAriaProcessManager.LoadConfig();
var
  tmp: string;
begin
  ProcessInstance.Parameters.Clear;
  ProcessInstance.Parameters.Add('--enable-rpc');
  if GlobalConfig.ReadBool('RPC', 'ListenAll', false) then
     ProcessInstance.Parameters.Add('--rpc-listen-all=true');
  ProcessInstance.Parameters.Add('--rpc-listen-port='+IntToStr(GlobalConfig.ReadInt64('RPC', 'Port', 6800)));
  tmp:= GlobalConfig.ReadString('RPC', 'Secret', '');
  if tmp <> '' then
     ProcessInstance.Parameters.Add('--rpc-secret='+tmp);

  tmp:= GlobalConfig.ReadString('Download', 'Path', '');
  if tmp <> '' then
     ProcessInstance.Parameters.Add('--dir='+tmp);

  tmp:= GlobalConfig.ReadString('Download', 'User-Agent', '');
  if tmp <> '' then
     ProcessInstance.Parameters.Add('--user-agent='+tmp);

  ProcessInstance.Parameters.Add('--input-file='+GetCurrentDir+'/download.session');
  ProcessInstance.Parameters.Add('--save-session='+GetCurrentDir+'/download.session');
  ProcessInstance.Parameters.Add('--rpc-allow-origin-all=true');
  ProcessInstance.Parameters.Add('--max-concurrent-downloads=16');

  tmp:=GlobalConfig.ReadString('BT', 'Tracker', '');
  if tmp <> '' then begin
    ProcessInstance.Parameters.Add('--bt-tracker='+tmp);
  end;


  AriaParamToken:='token:'+GlobalConfig.ReadString('RPC', 'Secret', '')
end;

function FileSizeToHumanReadableString(FileSize: int64): string;
begin
  if FileSize >= 1024*1024*1024 then
    Result := FloatToStrF(FileSize/(1024*1024*1024), ffFixed, 15, 2) + ' GB'
  else if FileSize >= 1024*1024 then
    Result := FloatToStrF(FileSize/(1024*1024), ffFixed, 15, 2) + ' MB'
  else
    Result := IntToStr(FileSize) + ' bytes';
end;


end.

