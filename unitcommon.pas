unit unitcommon;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, AsyncProcess, process{$IfDef Windows}, JwaWindows{$EndIf};

const
  {$IfDef Windows}
  ariaExecutable = 'aria2c.exe';
  {$Else}
  ariaExecutable = 'aria2c';
  {$EndIf}

  GB = 1073741824; // 1024 * 1024 * 1024
  MB = 1048576; // 1024 * 1024
  KB = 1024;

type
  TAriaProcessManager = class
  private

  public
    ProcessInstance: TAsyncProcess;
    procedure Execute();
    procedure LoadConfig();
    function isRunning(): boolean;
    constructor Create;
    destructor Destroy; override;
  end;

function FileSizeToHumanReadableString(FileSize: int64): string;
function processExists(exeFileName: string): Boolean;

var
  GlobalConfig: TIniFile;
  AriaProcessManager: TAriaProcessManager;
  AriaParamToken: string;

implementation

constructor TAriaProcessManager.Create;
begin
  Self.ProcessInstance := TAsyncProcess.Create(nil);
  ProcessInstance.Executable := GetCurrentDir + PathDelim + ariaExecutable;
  ProcessInstance.Options := [poNoConsole];
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
  if GlobalConfig.ReadBool('RPC', 'ListenAll', False) then
    ProcessInstance.Parameters.Add('--rpc-listen-all=true');
  ProcessInstance.Parameters.Add('--rpc-listen-port=' + IntToStr(
    GlobalConfig.ReadInt64('RPC', 'Port', 6800)));
  tmp := GlobalConfig.ReadString('RPC', 'Secret', '');
  if tmp <> '' then
    ProcessInstance.Parameters.Add('--rpc-secret=' + tmp);

  tmp := GlobalConfig.ReadString('Download', 'Path', '');
  if tmp <> '' then
    ProcessInstance.Parameters.Add('--dir=' + tmp);

  tmp := GlobalConfig.ReadString('Download', 'User-Agent', '');
  if tmp <> '' then
    ProcessInstance.Parameters.Add('--user-agent=' + tmp);

  ProcessInstance.Parameters.Add('--input-file=' + GetCurrentDir + '/download.session');
  ProcessInstance.Parameters.Add('--save-session=' + GetCurrentDir + '/download.session');
  ProcessInstance.Parameters.Add('--rpc-allow-origin-all=true');
  ProcessInstance.Parameters.Add('--max-concurrent-downloads='+GlobalConfig.ReadString('Download', 'MaxTasks', '64'));
  ProcessInstance.Parameters.Add('--max-connection-per-server=64'+GlobalConfig.ReadString('Download', 'MaxConnections', '64'));
  ProcessInstance.Parameters.Add('--min-split-size=1M');
  ProcessInstance.Parameters.Add('--split=64');
  ProcessInstance.Parameters.Add('--check-certificate=false');

  tmp := GlobalConfig.ReadString('BT', 'Tracker', '');
  if tmp <> '' then
  begin
    ProcessInstance.Parameters.Add('--bt-tracker=' + tmp);
  end;

  tmp:=GlobalConfig.ReadString('Download', 'Proxy', '');
  if tmp <> '' then begin
    ProcessInstance.Parameters.Add('--all-proxy=' + tmp);
  end;

  AriaParamToken := 'token:' + GlobalConfig.ReadString('RPC', 'Secret', '');
end;

function TAriaProcessManager.isRunning(): boolean;
begin
  Result := ProcessInstance.Running;
end;

function FileSizeToHumanReadableString(FileSize: int64): string;
var
  Size: double;
  SizeUnit: string;
begin
  if FileSize >= GB then // 如果文件大小大于等于1GB
  begin
    Size := FileSize / GB; // 用GB为单位
    SizeUnit := 'GB';
  end
  else if FileSize >= MB then // 如果文件大小大于等于1MB
  begin
    Size := FileSize / MB; // 用MB为单位
    SizeUnit := 'MB';
  end
  else if FileSize >= KB then begin
    Size := FileSize / KB; // 用KB为单位
    SizeUnit := 'KB';
  end
  else // 如果文件大小小于1MB
  begin
    Size := FileSize; // 用字节为单位
    SizeUnit := 'bytes';
  end;
  Result:= Format('%.2f %s', [Size, SizeUnit]);// 格式化输出，保留整数部分
end;

{
function FileSizeToHumanReadableString(FileSize: int64): string;
begin
  Result:=IntToStr(FileSize);
end;
}

{$IfDef WINDOWS}
function processExists(exeFileName: string): Boolean;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  Result := False;
  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
    begin
      Result := True;
    end;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;
{$EndIf}

end.
