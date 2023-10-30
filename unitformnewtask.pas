unit unitformnewtask;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, ceostypes;

type

  { TFormNewTask }

  TFormNewTask = class(TForm)
    btnStart: TButton;
    btnCancel: TButton;
    edtDownloadURL: TLabeledEdit;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
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

procedure TFormNewTask.btnStartClick(Sender: TObject);
var
  req: TCeosRequestContent;
begin
  req:=TCeosRequestContent.create;
  req.Method:='aria2.addUri';
  req.Args.Add(AriaParamToken);
  req.Args.Add(GetJSONArray([edtDownloadURL.Text]));
  FormMain.client.call(req);
  req.Free;
  Close;
end;

end.

