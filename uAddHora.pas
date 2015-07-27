unit uAddHora;

interface

uses SysUtils, DateUtils;

type
  TTipoCalculo = (tcSoma, tcSubtrai, tcSomaHoraUtil);

  TInterlado = record
    HoraIni: TTime;
    HoraFim: TTime;
  end;

  TIntervalos = Array of TInterlado;
  TDiasSemana = set of AnsiChar;

  THoraUtil = class
  private
    FIntervalo: TIntervalos;
    FDiasSemana: TDiasSemana;
  public
    constructor Create(atHoraIni, atHoraFim: TTime; aiDiasSemana: TDiasSemana); overload;
    procedure AddIntervalo(atHoraIni, atHoraFim: TTime);
    property GetIntervalo: TIntervalos read FIntervalo;
    function GetMaxHora: TTime;
    function GetMinHora: TTime;
    function GetProximatHora(adData: TDateTime): TTime;
    property DiasSemana: TDiasSemana read FDiasSemana;
  end;

  TDateUtils = class
  public
    class function AddHora(adDataHoraInicio: TDateTime; aiHH, aiMM: Word; atTipoCalculo: TTipoCalculo; aoHoraUtil: THoraUtil = nil)
      : TDateTime;
  end;

implementation

{ THoraUtil }

constructor THoraUtil.Create(atHoraIni, atHoraFim: TTime; aiDiasSemana: TDiasSemana);
begin
  inherited Create;
  AddIntervalo(atHoraIni, atHoraFim);
  FDiasSemana := aiDiasSemana;
end;

procedure THoraUtil.AddIntervalo(atHoraIni, atHoraFim: TTime);
var
  i: Integer;
  // vloListOrder : TList;
begin
  if atHoraIni > atHoraFim then
    raise Exception.Create('A Hora inicial não pode ser maior que a Hora Final. O Intervalo não foi Criado.')
  else
  begin
    for i := Low(Self.GetIntervalo) to High(Self.GetIntervalo) do
      if ((Self.GetIntervalo[i].HoraIni >= atHoraIni) and (Self.GetIntervalo[i].HoraFim <= atHoraIni)) or
        ((Self.GetIntervalo[i].HoraIni >= atHoraFim) and (Self.GetIntervalo[i].HoraFim <= atHoraFim)) or
        ((Self.GetIntervalo[i].HoraIni >= atHoraIni) and (Self.GetIntervalo[i].HoraFim <= atHoraFim)) then
        raise Exception.Create('Intervalo com Horários concorrentes. O Intervalo não foi Criado.');
    //
    SetLength(FIntervalo, High(FIntervalo) + 2);
    FIntervalo[ High(FIntervalo)].HoraIni := atHoraIni;
    FIntervalo[ High(FIntervalo)].HoraFim := atHoraFim;
  end;
end;

function THoraUtil.GetMaxHora: TTime;
var
  i: Integer;
begin
  Result := StrToTime('00:00');
  for i := Low(Self.GetIntervalo) to High(Self.GetIntervalo) do
  begin
    if Self.GetIntervalo[i].HoraFim > Result then
      Result := Self.GetIntervalo[i].HoraFim;
  end;
end;

function THoraUtil.GetMinHora: TTime;
var
  i: Integer;
begin
  Result := Self.GetIntervalo[0].HoraIni;
  for i := Low(Self.GetIntervalo) to High(Self.GetIntervalo) do
  begin
    if Self.GetIntervalo[i].HoraIni < Result then
      Result := Self.GetIntervalo[i].HoraIni;
  end;
end;

function THoraUtil.GetProximatHora(adData: TDateTime): TTime;
var
  i: Integer;
  vlbPegaMinHora : Boolean;
  vlbHoraAux : TTime;
begin
  Result := StrToTime('23:59');
  vlbPegaMinHora := True;
  if TimeOf(adData) = Self.GetMaxHora then
    vlbHoraAux := StrToTime('00:00')
  else
    vlbHoraAux := TimeOf(adData);
  for i := Low(Self.GetIntervalo) to High(Self.GetIntervalo) do
  begin
    if (Self.GetIntervalo[i].HoraIni > vlbHoraAux) and (Self.GetIntervalo[i].HoraIni < Result) then
      begin
      Result := Self.GetIntervalo[i].HoraIni;
      vlbPegaMinHora := False;
      end;
  end;
  if vlbPegaMinHora then
    Result := Self.GetMinHora;
end;

{ TDateUtils }

class function TDateUtils.AddHora(adDataHoraInicio: TDateTime; aiHH, aiMM: Word; atTipoCalculo: TTipoCalculo; aoHoraUtil: THoraUtil)
  : TDateTime;
var
  vldDataHoraFim: TDateTime;
  vldSaldoMinuto, vliMinuto: Word;
  vliIncDay : Integer;
  i: Integer;
begin
  // -> Converte Horas para Minutos
  vldSaldoMinuto := aiMM + (aiHH * 60);
  // -> Segundos serão desconsiderados
  vldDataHoraFim := DateOf(adDataHoraInicio) + StrToTime(FormatDateTime('hh:mm', adDataHoraInicio));
  //
  if atTipoCalculo = tcSoma then
    vldDataHoraFim := IncMinute(vldDataHoraFim, vldSaldoMinuto)
  else if atTipoCalculo = tcSubtrai then
    vldDataHoraFim := IncMinute(vldDataHoraFim, vldSaldoMinuto * -1)
  else if atTipoCalculo = tcSomaHoraUtil then
  begin
    if not Assigned(aoHoraUtil) then
      aoHoraUtil := THoraUtil.Create(StrToTime('08:00'), StrToTime('18:00'), ['2' .. '6']);
    if TimeOf(adDataHoraInicio) < aoHoraUtil.GetProximatHora(adDataHoraInicio) then
      vldDataHoraFim := TDate(adDataHoraInicio) + aoHoraUtil.GetProximatHora(vldDataHoraFim)
    else if TimeOf(adDataHoraInicio) >= aoHoraUtil.GetMaxHora then
      vldDataHoraFim := IncDay(DateOf(adDataHoraInicio), 1) + aoHoraUtil.GetMinHora;
    while vldSaldoMinuto > 0 do
    begin
      for i := Low(aoHoraUtil.GetIntervalo) to High(aoHoraUtil.GetIntervalo) do
      begin
        if TimeOf(vldDataHoraFim) < aoHoraUtil.GetIntervalo[i].HoraFim then
        begin
          if (vldSaldoMinuto <= MinutesBetween(vldDataHoraFim, DateOf(vldDataHoraFim) + aoHoraUtil.GetIntervalo[i].HoraFim)) then
          begin
            vldDataHoraFim := IncMinute(vldDataHoraFim, vldSaldoMinuto);
            vldSaldoMinuto := 0;
          end
          else
          begin
            vliMinuto := MinutesBetween(vldDataHoraFim, DateOf(vldDataHoraFim) + aoHoraUtil.GetIntervalo[i].HoraFim);
            vldDataHoraFim := IncMinute(vldDataHoraFim, vliMinuto);
            vldSaldoMinuto := vldSaldoMinuto - vliMinuto;
            if (DateOf(vldDataHoraFim) + aoHoraUtil.GetProximatHora(vldDataHoraFim) > vldDataHoraFim) and (vldSaldoMinuto > 0) then
              vldDataHoraFim := DateOf(vldDataHoraFim) + aoHoraUtil.GetProximatHora(vldDataHoraFim)
            else if (vldDataHoraFim >= DateOf(vldDataHoraFim) + aoHoraUtil.GetMaxHora) and (vldSaldoMinuto > 0) then
            begin
              vliIncDay := 1;
              while not (IntToStr(DayOfWeek(IncDay(vldDataHoraFim, vliIncDay)))[1] in aoHoraUtil.DiasSemana) do
                Inc(vliIncDay);
              vldDataHoraFim := IncDay(DateOf(vldDataHoraFim), vliIncDay) + aoHoraUtil.GetMinHora;
            end;
          end;
        end;
      end;
    end;
  end;
  Result := vldDataHoraFim;
end;

end.
