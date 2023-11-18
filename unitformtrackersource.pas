unit unitformtrackersource;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TFormTrackerSource }

  TFormTrackerSource = class(TForm)
    btnAdd: TButton;
    btnDelete: TButton;
    btnEdit: TButton;
    btnOK: TButton;
    btnCancel: TButton;
    cbxPreset: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    ListTrackerSources: TListBox;
    procedure btnAddClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure cbxPresetChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  FormTrackerSource: TFormTrackerSource;

implementation

uses unitcommon, unitresourcestring;

{$R *.lfm}

{ TFormTrackerSource }

procedure TFormTrackerSource.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TFormTrackerSource.btnDeleteClick(Sender: TObject);
begin
  ListTrackerSources.DeleteSelected;
end;

procedure TFormTrackerSource.btnEditClick(Sender: TObject);
var
  tmp: string;
begin
  if ListTrackerSources.ItemIndex = -1 then exit;
  tmp:=InputBox(EditTrackerSourceInput, EditTrackerSourceInputPrompt, ListTrackerSources.GetSelectedText);
  if tmp <> '' then ListTrackerSources.Items.Add(tmp);
end;

procedure TFormTrackerSource.btnOKClick(Sender: TObject);
var
  tmp: string;
begin
  tmp:=StringReplace(ListTrackerSources.Items.Text, LineEnding, ',', [rfReplaceAll]);
  GlobalConfig.WriteString('BT', 'Sources', tmp);
  Close;
end;

procedure TFormTrackerSource.btnAddClick(Sender: TObject);
var
  tmp: string;
begin
  tmp:=InputBox(AddTrackerSourceInput, AddTrackerSourceInputPrompt, '');
  if tmp <> '' then ListTrackerSources.Items[ListTrackerSources.ItemIndex]:=(tmp);
end;

procedure TFormTrackerSource.cbxPresetChange(Sender: TObject);
begin
  ListTrackerSources.Items.Add(cbxPreset.Text);
  ListTrackerSources.ItemIndex:=-1;
end;

procedure TFormTrackerSource.FormCreate(Sender: TObject);
var
  tmp: string;
begin
  tmp:=StringReplace(GlobalConfig.ReadString('BT', 'Sources', ''), LineEnding, ',', [rfReplaceAll]);
  ListTrackerSources.Items.Text:=tmp;
end;

end.

