unit untPrincipal;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DateUtils;

type
  TForm1 = class(TForm)
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses uAddHora;

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
  vloHoraUtil : THoraUtil;
begin
  vloHoraUtil := THoraUtil.Create(StrToTime('08:00'), StrToTime('12:00'), ['2' .. '6']);
  vloHoraUtil.AddIntervalo(StrToTime('14:00'), StrToTime('17:00'));
  ShowMessage(FormatDateTime('dd/mm/yyyy hh:mm:ss', TDateUtils.AddHora(Now, StrToInt(Edit1.Text), 0, tcSomaHoraUtil, vloHoraUtil)));
//  ShowMessage(FormatDateTime('dd/mm/yyyy hh:mm:ss', TDateUtils.AddHora(Now, 2, 0, tcSomaHoraUtil, vloHoraUtil)));
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  ShowMessage(IntToStr(WeekOf(Now)));
end;

end.
