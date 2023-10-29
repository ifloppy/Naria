unit unitformsettings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  ComCtrls, ExtCtrls, LazFileUtils;

type

  { TFormSettings }

  TFormSettings = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    btnDownloadPathBrowse: TButton;
    ckbListenAll: TCheckBox;
    cbxUAPresets: TComboBox;
    edtRPCPassword: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    edtDownloadPath: TLabeledEdit;
    edtDownloadUA: TLabeledEdit;
    Label3: TLabel;
    PageControl1: TPageControl;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    speRPCPort: TSpinEdit;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure btnCancelClick(Sender: TObject);
    procedure btnDownloadPathBrowseClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure cbxUAPresetsChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public
    FirstUse: Boolean;
  end;

var
  FormSettings: TFormSettings;


implementation

uses unitcommon;

{$R *.lfm}

{ TFormSettings }

procedure TFormSettings.btnOKClick(Sender: TObject);
begin
  GlobalConfig.WriteBool('RPC', 'ListenAll', ckbListenAll.Checked);
  GlobalConfig.WriteInt64('RPC', 'Port', speRPCPort.Value);
  GlobalConfig.WriteString('RPC', 'Secret', edtRPCPassword.Text);
  GlobalConfig.WriteString('Download', 'Path', edtDownloadPath.Text);
  GlobalConfig.WriteString('DOwnload', 'User-Agent', edtDownloadUA.Text);
  Close;
end;

procedure TFormSettings.cbxUAPresetsChange(Sender: TObject);
begin
  edtDownloadUA.Text:=cbxUAPresets.Text;
  cbxUAPresets.Text:='';
end;

procedure TFormSettings.btnCancelClick(Sender: TObject);
begin
  if FirstUse then btnOKClick(nil) else Close;

end;

procedure TFormSettings.btnDownloadPathBrowseClick(Sender: TObject);
begin
  if SelectDirectoryDialog1.Execute then edtDownloadPath.Text:=SelectDirectoryDialog1.FileName;
end;

procedure TFormSettings.FormCreate(Sender: TObject);
begin

  ckbListenAll.Checked:=GlobalConfig.ReadBool('RPC', 'ListenAll', false);
  speRPCPort.Value:=GlobalConfig.ReadInt64('RPC', 'Port', 6800);
  edtRPCPassword.Text:=GlobalConfig.ReadString('RPC', 'Secret', '');
  edtDownloadPath.Text:=GlobalConfig.ReadString('Download', 'Path', '');
  edtDownloadUA.Text:=GlobalConfig.ReadString('Download', 'User-Agent', '');
end;

end.

