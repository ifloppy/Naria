unit unitcommon;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, AsyncProcess, process;

const
  {$IfDef Windows}
  ariaExecutable = 'aria2c.exe';
  {$Else}
  ariaExecutable = 'aria2c';
  {$EndIf}

  Units: array[0..8] of string = ('B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB');

type
  TAriaProcessManager = class
  private
    ProcessInstance: TAsyncProcess;
  public
    procedure Execute();
    procedure LoadConfig();
    function isRunning(): boolean;
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
  ProcessInstance.Options:=[poNoConsole];
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
  ProcessInstance.Parameters.Add('--max-concurrent-downloads=64');
  ProcessInstance.Parameters.Add('--max-connection-per-server=64');

  tmp:=GlobalConfig.ReadString('BT', 'Tracker', '');
  if tmp <> '' then begin
    ProcessInstance.Parameters.Add('--bt-tracker='+tmp);
  end;


  AriaParamToken:='token:'+GlobalConfig.ReadString('RPC', 'Secret', '')
end;

function TAriaProcessManager.isRunning(): boolean;
begin
  Result:=ProcessInstance.Running;
end;

function FileSizeToHumanReadableString(FileSize: int64): string;
var
  i: integer; // 定义一个整数变量，用于循环遍历单位数组
  f: double; // 定义一个双精度浮点变量，用于存储转换后的文件大小
begin
  // 初始化变量
  i := 0;
  f := FileSize;

  // 循环遍历单位数组，直到找到合适的单位或达到数组的最大索引
  while (f >= 1024) and (i < High(Units)) do
  begin
    f := f / 1024; // 将文件大小除以1024，得到下一个单位的文件大小
    i := i + 1; // 将单位数组的索引加一
  end;

  // 返回转换后的文件大小和单位，保留两位小数
  Result := Format('%.2f %s', [f, Units[i]]);
end;


end.

