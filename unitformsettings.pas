unit unitformsettings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  ComCtrls, ExtCtrls, LazFileUtils, Types, fphttpclient, unitresourcestring;

type

  { TFormSettings }

  TFormSettings = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    btnDownloadPathBrowse: TButton;
    btnUpdateTrackersFromURL: TButton;
    ckbListenAll: TCheckBox;
    cbxUAPresets: TComboBox;
    edtUpdateTrackersURL: TEdit;
    edtRPCPassword: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    edtDownloadPath: TLabeledEdit;
    edtDownloadUA: TLabeledEdit;
    Label3: TLabel;
    Label4: TLabel;
    memoTracker: TMemo;
    PageControl1: TPageControl;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    speRPCPort: TSpinEdit;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    procedure btnCancelClick(Sender: TObject);
    procedure btnDownloadPathBrowseClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnUpdateTrackersFromURLClick(Sender: TObject);
    procedure cbxUAPresetsChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private

  public
    FirstUse: boolean;
  end;

var
  FormSettings: TFormSettings;


implementation

uses unitcommon;

  {$R *.lfm}

  { TFormSettings }

procedure TFormSettings.btnOKClick(Sender: TObject);
var
  tmp: string;
begin
  if not DirectoryExists(edtDownloadPath.Text) then begin
    ShowMessage(RequireDefaultDownloadPath);
    exit;
  end;


  GlobalConfig.WriteBool('RPC', 'ListenAll', ckbListenAll.Checked);
  GlobalConfig.WriteInt64('RPC', 'Port', speRPCPort.Value);
  GlobalConfig.WriteString('RPC', 'Secret', edtRPCPassword.Text);
  GlobalConfig.WriteString('Download', 'Path', edtDownloadPath.Text);
  GlobalConfig.WriteString('DOwnload', 'User-Agent', edtDownloadUA.Text);

  if memoTracker.Lines.Text <> '' then
  begin
    tmp := StringReplace(memoTracker.Lines.Text, LineEnding, ',', [rfReplaceAll]);
    if tmp[High(tmp)] = ',' then Delete(tmp, High(tmp), 1);
    GlobalConfig.WriteString('BT', 'Tracker', tmp);
  end;


  GlobalConfig.WriteString('BT', 'TrackerSyncServer', edtUpdateTrackersURL.Text);
  Close;
end;

procedure TFormSettings.btnUpdateTrackersFromURLClick(Sender: TObject);
var
  httpclient: TFPHTTPClient;
  r: string;
begin
  if edtUpdateTrackersURL.Text = '' then exit;
  httpclient := TFPHTTPClient.Create(nil);
  try
    r := httpclient.Get(edtUpdateTrackersURL.Text);

  finally
    memoTracker.Lines.Text := r;
    memoTracker.Text := StringReplace(memoTracker.Lines.Text,
      LineEnding + LineEnding, LineEnding, [rfReplaceAll]);
  end;
  httpclient.Free;
end;

procedure TFormSettings.cbxUAPresetsChange(Sender: TObject);
begin
  edtDownloadUA.Text := cbxUAPresets.Text;
  cbxUAPresets.Text := '';
end;

procedure TFormSettings.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if FirstUse then Application.Terminate;
end;

procedure TFormSettings.btnCancelClick(Sender: TObject);
begin
  if FirstUse then btnOKClick(nil)
  else
    Close;

end;

procedure TFormSettings.btnDownloadPathBrowseClick(Sender: TObject);
begin
  if SelectDirectoryDialog1.Execute then
    edtDownloadPath.Text := SelectDirectoryDialog1.FileName;
end;

procedure TFormSettings.FormCreate(Sender: TObject);
begin

  ckbListenAll.Checked := GlobalConfig.ReadBool('RPC', 'ListenAll', False);
  speRPCPort.Value := GlobalConfig.ReadInt64('RPC', 'Port', 6800);
  edtRPCPassword.Text := GlobalConfig.ReadString('RPC', 'Secret', '');
  edtDownloadPath.Text := GlobalConfig.ReadString('Download', 'Path', '');
  edtDownloadUA.Text := GlobalConfig.ReadString('Download', 'User-Agent', '');
  memoTracker.Lines.Text := StringReplace(GlobalConfig.ReadString('BT', 'Tracker', ''),
    ',', LineEnding, [rfReplaceAll]);
  edtUpdateTrackersURL.Text := GlobalConfig.ReadString('BT', 'TrackerSyncServer',
    'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt');

end;


end.
