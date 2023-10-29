unit unitformmain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Menus, unitformsettings, ceosclient, unitcommon, unitformnewtask,
  unitresourcestring, fpjson, Types, Clipbrd;

type

  { TFormMain }

  TFormMain = class(TForm)
    btnSettings: TButton;
    btnPauseAll: TButton;
    btnUnpauseAll: TButton;
    btnNewTask: TButton;
    ckbRefreshTaskList: TCheckBox;
    client: TCeosClient;
    ListView1: TListView;
    mniTaskResume: TMenuItem;
    mniTaskPause: TMenuItem;
    mniTaskDelete: TMenuItem;
    mniTaskCopyURL: TMenuItem;
    PopupMenuDownloadTask: TPopupMenu;
    sb: TStatusBar;
    TimerRefreshTaskList: TTimer;
    TimerRealtimeStats: TTimer;
    procedure btnNewTaskClick(Sender: TObject);
    procedure btnPauseAllClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnUnpauseAllClick(Sender: TObject);
    procedure ckbRefreshTaskListChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure ListView1ContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: boolean);
    procedure mniTaskCopyURLClick(Sender: TObject);
    procedure mniTaskDeleteClick(Sender: TObject);
    procedure mniTaskPauseClick(Sender: TObject);
    procedure mniTaskResumeClick(Sender: TObject);
    procedure PopupMenuDownloadTaskClose(Sender: TObject);
    procedure PopupMenuDownloadTaskPopup(Sender: TObject);
    procedure TimerRealtimeStatsTimer(Sender: TObject);
    procedure TimerRefreshTaskListTimer(Sender: TObject);
  private

  public
    ActiveTaskStatusList: TJSONArray;
    WaitingTaskStatusList: TJSONArray;
    StoppedTaskStatusList: TJSONArray;
  end;

var
  FormMain: TFormMain;

implementation



{$R *.lfm}

{ TFormMain }

procedure TFormMain.btnSettingsClick(Sender: TObject);
var
  dlg: TFormSettings;
begin
  dlg := TFormSettings.Create(nil);
  dlg.ShowModal;
  dlg.Free;
end;

procedure TFormMain.btnUnpauseAllClick(Sender: TObject);
begin
  client.Call('aria2.unpauseAll', [AriaParamToken], 0);
end;

procedure TFormMain.ckbRefreshTaskListChange(Sender: TObject);
begin
  TimerRefreshTaskList.Enabled := ckbRefreshTaskList.Checked;
end;

procedure TFormMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  client.Call('aria2.shutdown', [AriaParamToken], 0);
  AriaProcessManager.Free;

  ActiveTaskStatusList.Free;
  WaitingTaskStatusList.Free;
  StoppedTaskStatusList.Free;
end;

procedure TFormMain.ListView1ContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: boolean);
begin
  PopupMenuDownloadTask.PopUp;
  Handled := True;
end;

procedure TFormMain.mniTaskCopyURLClick(Sender: TObject);
begin
  Clipboard.AsText:=ListView1.Selected.SubItems.Strings[0];
end;

procedure TFormMain.mniTaskDeleteClick(Sender: TObject);
begin
  client.Call('aria2.remove', [AriaParamToken, ListView1.Items[ListView1.ItemIndex].Caption], 0);
end;

procedure TFormMain.mniTaskPauseClick(Sender: TObject);
begin
  client.Call('aria2.pause', [AriaParamToken, ListView1.Items[ListView1.ItemIndex].Caption], 0);
end;

procedure TFormMain.mniTaskResumeClick(Sender: TObject);
begin
  client.Call('aria2.unpause', [AriaParamToken, ListView1.Items[ListView1.ItemIndex].Caption], 0);
end;

procedure TFormMain.PopupMenuDownloadTaskClose(Sender: TObject);
begin
  TimerRefreshTaskList.Enabled:=ckbRefreshTaskList.Checked;
end;

procedure TFormMain.PopupMenuDownloadTaskPopup(Sender: TObject);
var
  selectedIndex: integer;
begin
  mniTaskResume.Enabled:=false;
  mniTaskPause.Enabled:=false;
  mniTaskDelete.Enabled:=false;
  mniTaskCopyURL.Enabled:=false;


  selectedIndex:=ListView1.ItemIndex;
  if selectedIndex >= 0 then
  begin
    mniTaskCopyURL.Enabled:=true;
    TimerRefreshTaskList.Enabled:=false;

    //ShowMessage(ListView1.Items[selectedIndex].SubItems.Text);

    if ListView1.Items[selectedIndex].SubItems[6] = DownloadStopped then
    begin
      mniTaskDelete.Enabled := True;
    end;

    if ListView1.Items[selectedIndex].SubItems[6] = DownloadWaiting then
    begin
      mniTaskResume.Enabled := True;
      mniTaskDelete.Enabled := True;
    end;

    if ListView1.Items[selectedIndex].SubItems[6] = DownloadActive then
    begin
      mniTaskPause.Enabled := True;
    end;
  end;

end;

procedure TFormMain.btnPauseAllClick(Sender: TObject);
begin
  client.Call('aria2.forcePauseAll', [AriaParamToken], 0);
end;

procedure TFormMain.btnNewTaskClick(Sender: TObject);
var
  dlg: TFormNewTask;
begin
  dlg := TFormNewTask.Create(nil);
  dlg.ShowModal;
  dlg.Free;
end;


procedure TFormMain.TimerRealtimeStatsTimer(Sender: TObject);
var
  r: string;
  resp: TJSONObject;
  Result: TJSONObject;
begin
  r := client.Call('aria2.getGlobalStat', [AriaParamToken], 1);
  resp := GetJSON(r, False) as TJSONObject;
  Result := resp.Objects['result'].Clone as TJSONObject;
  resp.Free;

  sb.Panels.Items[0].Text := '↓ ' + Utf8ToAnsi(Result.Strings['downloadSpeed']) + 'byte/s';
  sb.Panels.Items[1].Text := '↑ ' + Utf8ToAnsi(Result.Strings['uploadSpeed']) + 'byte/s';
  sb.Panels.Items[2].Text := WaitingTaskNum + Result.Strings['numWaiting'];

  Result.Free;
end;

procedure TFormMain.TimerRefreshTaskListTimer(Sender: TObject);
var
  r: string;
  SingleObject: TJSONObject;
  i: integer;
  respJSON: TJSONObject;
begin
  r := client.Call('aria2.tellActive', [AriaParamToken], 1);
  ActiveTaskStatusList.Free;
  respJSON := GetJSON(r) as TJSONObject;
  ActiveTaskStatusList := respJSON.Arrays['result'].Clone as TJSONArray;
  respJSON.Free;

  ListView1.Clear;

  if ActiveTaskStatusList.Count > 0 then for i := 0 to ActiveTaskStatusList.Count - 1 do
    begin
      SingleObject := ActiveTaskStatusList.Objects[i];
      with ListView1.Items.Add do
      begin
        Caption := SingleObject.Strings['gid'];
        SubItems.Add(SingleObject.Arrays['files'].Objects[0].Arrays[
          'uris'].Objects[0].Strings['uri']);
        SubItems.Add(SingleObject.Strings['completedLength']);
        SubItems.Add(SingleObject.Strings['totalLength']);
        if SingleObject.Integers['totalLength'] = 0 then
          SubItems.Add('N/A')
        else
          SubItems.Add(FloatToStrF(SingleObject.Integers['completedLength'] /
            SingleObject.Integers['totalLength'] * 100, ffGeneral, 5, 2) + '%');
        SubItems.Add(SingleObject.Strings['uploadLength']);
        SubItems.Add(SingleObject.Strings['downloadSpeed']);
        SubItems.Add(DownloadActive);
      end;
    end;



  r := client.Call('aria2.tellWaiting', [AriaParamToken, 0, 10], 1);
  WaitingTaskStatusList.Free;
  respJSON := GetJSON(r) as TJSONObject;
  WaitingTaskStatusList := respJSON.Arrays['result'].Clone as TJSONArray;
  respJSON.Free;

  if WaitingTaskStatusList.Count > 0 then for i := 0 to WaitingTaskStatusList.Count - 1 do
    begin
      SingleObject := WaitingTaskStatusList.Objects[i];
      with ListView1.Items.Add do
      begin
        Caption := SingleObject.Strings['gid'];
        SubItems.Add(SingleObject.Arrays['files'].Objects[0].Arrays[
          'uris'].Objects[0].Strings['uri']);
        SubItems.Add(SingleObject.Strings['completedLength']);
        SubItems.Add(SingleObject.Strings['totalLength']);
        if SingleObject.Integers['totalLength'] = 0 then
          SubItems.Add('N/A')
        else
          SubItems.Add(FloatToStrF(SingleObject.Integers['completedLength'] /
            SingleObject.Integers['totalLength'] * 100, ffGeneral, 5, 2) + '%');
        SubItems.Add(SingleObject.Strings['uploadLength']);
        SubItems.Add(SingleObject.Strings['downloadSpeed']);
        SubItems.Add(DownloadWaiting);
      end;
    end;



  r := client.Call('aria2.tellStopped', [AriaParamToken, 0, 10], 1);
  StoppedTaskStatusList.Free;
  respJSON := GetJSON(r) as TJSONObject;
  StoppedTaskStatusList := respJSON.Arrays['result'].Clone as TJSONArray;
  respJSON.Free;

  if StoppedTaskStatusList.Count > 0 then for i := 0 to StoppedTaskStatusList.Count - 1 do
    begin
      SingleObject := StoppedTaskStatusList.Objects[i];
      with ListView1.Items.Add do
      begin
        Caption := SingleObject.Strings['gid'];
        SubItems.Add(SingleObject.Arrays['files'].Objects[0].Arrays[
          'uris'].Objects[0].Strings['uri']);
        SubItems.Add(SingleObject.Strings['completedLength']);
        SubItems.Add(SingleObject.Strings['totalLength']);
        if SingleObject.Integers['totalLength'] = 0 then
          SubItems.Add('N/A')
        else
          SubItems.Add(FloatToStrF(SingleObject.Integers['completedLength'] /
            SingleObject.Integers['totalLength'] * 100, ffGeneral, 5, 2) + '%');
        SubItems.Add(SingleObject.Strings['uploadLength']);
        SubItems.Add(SingleObject.Strings['downloadSpeed']);
        SubItems.Add(DownloadStopped);
      end;
    end;
end;

end.
