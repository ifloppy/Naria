unit unitformmain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Menus, unitformsettings, ceosclient, unitcommon, unitformnewtask,
  unitresourcestring, fpjson, Types, Clipbrd;

type

  TSingleDownloadTaskItem = array[0..8] of string;

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
    procedure FormCreate(Sender: TObject);
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
  MessageDlg(PleaseRestartApplication, mtWarning, [mbOK], 0);
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

procedure TFormMain.FormCreate(Sender: TObject);
begin

end;

procedure TFormMain.ListView1ContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: boolean);
begin
  PopupMenuDownloadTask.PopUp;
  Handled := True;
end;

procedure TFormMain.mniTaskCopyURLClick(Sender: TObject);
begin
  Clipboard.AsText := ListView1.Selected.SubItems.Strings[8];
end;

procedure TFormMain.mniTaskDeleteClick(Sender: TObject);
begin
  client.Call('aria2.remove', [AriaParamToken,
    ListView1.Items[ListView1.ItemIndex].Caption], 0);
end;

procedure TFormMain.mniTaskPauseClick(Sender: TObject);
begin
  client.Call('aria2.pause', [AriaParamToken,
    ListView1.Items[ListView1.ItemIndex].Caption], 0);
end;

procedure TFormMain.mniTaskResumeClick(Sender: TObject);
begin
  client.Call('aria2.unpause', [AriaParamToken,
    ListView1.Items[ListView1.ItemIndex].Caption], 0);
end;

procedure TFormMain.PopupMenuDownloadTaskClose(Sender: TObject);
begin
  TimerRefreshTaskList.Enabled := ckbRefreshTaskList.Checked;
end;

procedure TFormMain.PopupMenuDownloadTaskPopup(Sender: TObject);
var
  selectedIndex: integer;
begin
  mniTaskResume.Enabled := False;
  mniTaskPause.Enabled := False;
  mniTaskDelete.Enabled := False;
  mniTaskCopyURL.Enabled := False;


  selectedIndex := ListView1.ItemIndex;
  if selectedIndex >= 0 then
  begin
    mniTaskCopyURL.Enabled := True;
    TimerRefreshTaskList.Enabled := False;

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
      mniTaskResume.Enabled := True;
      mniTaskDelete.Enabled := True;
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

  sb.Panels.Items[0].Text := '↓ ' + Utf8ToAnsi(Result.Strings['downloadSpeed']) +
    'byte/s';
  sb.Panels.Items[1].Text := '↑ ' + Utf8ToAnsi(Result.Strings['uploadSpeed']) +
    'byte/s';
  sb.Panels.Items[2].Text := WaitingTaskNum + Result.Strings['numWaiting'];

  Result.Free;
end;

function DownloadTaskTOVirtualItem(SingleJSONObject: TJSONObject; DownloadStatus: string): TSingleDownloadTaskItem;
var
  lengthTotal, lengthCompleted: Int64;
  tmpJSONData: TJSONData;
begin
      lengthTotal := StrToInt64(SingleJSONObject.Strings['totalLength']);
      lengthCompleted := StrToInt(SingleJSONObject.Strings['completedLength']);
      Result[0] := SingleJSONObject.Strings['gid'];

      tmpJSONData := SingleJSONObject.Arrays['files'].Objects[0].Find('url');
      if tmpJSONData<>nil then
      begin
        Result[8] := tmpJSONData.AsString;
        Result[1] := ExtractFileName(Result[8]);
      end;
      tmpJSONData:=nil;
      tmpJSONData := SingleJSONObject.Find('bittorrent');
      if tmpJSONData<>nil then
      begin
        Result[1] :=
          (tmpJSONData as TJSONObject).Objects['info'].Strings['name'];
      end;
      tmpJSONData:=nil;



      Result[2] :=
        SingleJSONObject.Strings['completedLength'];
      Result[3] :=
        SingleJSONObject.Strings['totalLength'];
      if lengthTotal = 0 then
        Result[4] := ('N/A')
      else
        Result[4] :=
          (FloatToStrF(lengthCompleted / lengthTotal * 100, ffGeneral,
          5, 2) + '%');
      Result[5] :=
        (SingleJSONObject.Strings['uploadLength']);
      Result[6] :=
        SingleJSONObject.Strings['downloadSpeed'];
      Result[7] := (DownloadStatus);
end;

procedure TFormMain.TimerRefreshTaskListTimer(Sender: TObject);
var
  r: string;
  SingleJSONObject: TJSONObject;
  SingleListItemObject: TListItem;
  i, ii, totalTaskNum, nextProcessArrayIndex: integer;
  respJSON: TJSONObject;
  VirtualListView: array of TSingleDownloadTaskItem;
begin
  r := client.Call('aria2.tellActive', [AriaParamToken], 1);
  ActiveTaskStatusList.Free;
  respJSON := GetJSON(r) as TJSONObject;
  ActiveTaskStatusList := respJSON.Arrays['result'].Clone as TJSONArray;
  respJSON.Free;


  r := client.Call('aria2.tellWaiting', [AriaParamToken, 0, 10], 1);
  WaitingTaskStatusList.Free;
  respJSON := GetJSON(r) as TJSONObject;
  WaitingTaskStatusList := respJSON.Arrays['result'].Clone as TJSONArray;
  respJSON.Free;

  r := client.Call('aria2.tellStopped', [AriaParamToken, 0, 10], 1);
  StoppedTaskStatusList.Free;
  respJSON := GetJSON(r) as TJSONObject;
  StoppedTaskStatusList := respJSON.Arrays['result'].Clone as TJSONArray;
  respJSON.Free;

  totalTaskNum := ActiveTaskStatusList.Count + WaitingTaskStatusList.Count +
    StoppedTaskStatusList.Count;
  SetLength(VirtualListView, totalTaskNum);
  nextProcessArrayIndex := 0;


  //Get task list
  if ActiveTaskStatusList.Count > 0 then for i := 0 to ActiveTaskStatusList.Count - 1 do
    begin
      SingleJSONObject := ActiveTaskStatusList.Objects[i];
      VirtualListView[nextProcessArrayIndex]:=DownloadTaskTOVirtualItem(SingleJSONObject, DownloadActive);
      nextProcessArrayIndex := nextProcessArrayIndex + 1;

    end;


  if WaitingTaskStatusList.Count > 0 then
    for i := 0 to WaitingTaskStatusList.Count - 1 do
    begin
      SingleJSONObject := WaitingTaskStatusList.Objects[i];
      VirtualListView[nextProcessArrayIndex]:=DownloadTaskTOVirtualItem(SingleJSONObject, DownloadActive);
      nextProcessArrayIndex := nextProcessArrayIndex + 1;
    end;


  if StoppedTaskStatusList.Count > 0 then
    for i := 0 to StoppedTaskStatusList.Count - 1 do
    begin
      SingleJSONObject := StoppedTaskStatusList.Objects[i];
      VirtualListView[nextProcessArrayIndex]:=DownloadTaskTOVirtualItem(SingleJSONObject, DownloadActive);
      nextProcessArrayIndex := nextProcessArrayIndex + 1;
    end;


  //Check if listview items enough
  //i: total for times
  i := totalTaskNum - ListView1.Items.Count;
  if i > 0 then
  begin
    for ii := 0 to Pred(i) do
    begin
      with ListView1.Items.Add.SubItems do
      begin
        Add(EmptyStr);
        Add(EmptyStr);
        Add(EmptyStr);
        Add(EmptyStr);
        Add(EmptyStr);
        Add(EmptyStr);
        Add(EmptyStr);
        Add(EmptyStr);
      end;
    end;
  end;


  //Compare and update items
  //Per line
  //i: line id, ii: column id
  if (ListView1.Items.Count > 0) and (Length(VirtualListView) > 0) then
    for i := 0 to pred(totalTaskNum) do
    begin
      SingleListItemObject := ListView1.Items[i];
      //per column of this line
      SingleListItemObject.Caption := VirtualListView[i][0];
      //ShowMessage('Subitems:'+IntTOsTr(SingleListItemObject.SubItems.Count)) ;
      for ii := 1 to pred(Length(VirtualListView[i])) do
      begin

        if SingleListItemObject.SubItems[pred(ii)] <> VirtualListView[i][ii] then
          SingleListItemObject.SubItems[pred(ii)] := VirtualListView[i][ii];

      end;
    end;


  //Delete useless items
  //i: total for times
  i := ListView1.Items.Count - totalTaskNum;
  if i > 0 then
  begin
    for ii := 0 to Pred(i) do
    begin
      ListView1.Items.Delete(ListView1.Items.Count - 1);
    end;
  end;

end;

end.
