unit unitformnewtask;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, ceostypes, base64;

type

  { TFormNewTask }

  TFormNewTask = class(TForm)
    btnStart: TButton;
    btnCancel: TButton;
    btnBrowseTorrent: TButton;
    edtDownloadURL: TLabeledEdit;
    edtTorrentPath: TLabeledEdit;
    OpenDialog1: TOpenDialog;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure btnBrowseTorrentClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
  private

  public

  end;

var
  FormNewTask: TFormNewTask;

implementation

uses unitformmain, unitcommon;

{$R *.lfm}

{ TFormNewTask }

procedure TFormNewTask.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TFormNewTask.btnBrowseTorrentClick(Sender: TObject);
begin
  if OpenDialog1.Execute then edtTorrentPath.Text:=OpenDialog1.FileName;
end;

procedure TFormNewTask.btnStartClick(Sender: TObject);
var
  req: TCeosRequestContent;
  RawString: TStringStream;
  EncodedString: string;
  resp: string;
begin
  req:=TCeosRequestContent.create;

  req.Args.Add(AriaParamToken);


  if PageControl1.ActivePageIndex = 0 then begin
    req.Method:='aria2.addUri';
    req.Args.Add(GetJSONArray([edtDownloadURL.Text]));
  end;


  if PageControl1.ActivePageIndex = 1 then begin
    req.Method:='aria2.addTorrent';


    RawString:=TStringStream.Create('');
    RawString.LoadFromFile(edtTorrentPath.Text);
    EncodedString:=EncodeStringBase64(RawString.DataString);

    req.Args.Add(EncodedString);

    RawString.Free;

  end;


  resp:=FormMain.client.call(req);
  req.Free;
  ShowMessage(resp);
  Close;
end;

end.

