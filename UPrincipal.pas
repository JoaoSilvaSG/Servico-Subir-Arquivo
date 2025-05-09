unit UPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs,
  Vcl.ExtCtrls, RSLib, System.IniFiles, Data.SqlExpr, Vcl.Forms, Data.DBXFirebird, Data.DB, IOUtils,
  DateUtils;

type
  TSubirSetupServ = class(TService)
    Timer1: TTimer;
    procedure ServiceExecute(Sender: TService);
    procedure Timer1Timer(Sender: TObject);
  private
    procedure LoadIni;
    function GetIniFileName: String;
    procedure getConfigMin;
    procedure ConfereSobeNovoSetup;
    function ConfereHorario: Boolean;
  public
    procedure GravaLog(texto: String);
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  SubirSetupServ: TSubirSetupServ;
  LOG_PATH, LastMin: String;
  listMinConfig: TStringList;

implementation

{$R *.dfm}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  SubirSetupServ.Controller(CtrlCode);
end;

function TSubirSetupServ.ConfereHorario: Boolean;
var
  MinutoAtual: Word;
  i: Integer;
begin
  Result := False;
  try
    MinutoAtual := MinuteOf(Now);

    if LastMin = IntToStr(MinutoAtual)[2] then
      Exit;

    i := 0;
    while i < listMinConfig.Count - 1 do
    begin
      if Trim(IntToStr(MinutoAtual)[2]) = Trim(listMinConfig[i]) then
        Result := True;
      i := i + 1;
    end;

    LastMin := IntToStr(MinutoAtual)[2];
  except
    on E: Exception do
    begin
      GravaLog('Falha ao pegar o minuto atual, mensagem original: ' + E.Message);
      Abort;
    end;
  end;
end;

procedure TSubirSetupServ.ConfereSobeNovoSetup;

  function VerificaNovaVersao(FileName: string): String;
  var
    VersionListBuild, VersionListTeste: TStringList;
    fileNameTeste: String;
  begin
    Result := '';

    if not FileExists(FileName) then
      Exit;

    VersionListBuild := TStringList.Create;
    VersionListTeste := TStringList.Create;
    try

      ExtractStrings(['.'], ['.'], PChar(String(GetFileVersion(FileName))), VersionListBuild);

      if VersionListBuild.Count <> 4 then
      begin
        GravaLog('Não foi possível identificar a versão, arquivo: ' + FileName);
        Exit;
      end;

      fileNameTeste := '\\10.1.0.1\corporativo$\QUALIDADE AGRO\Setups\Em teste\Agro\' + VersionListBuild[0] + '.' + VersionListBuild[1];

      if not DirectoryExists(fileNameTeste) then
      begin
        ForceDirectories(fileNameTeste);
        ForceDirectories(fileNameTeste + '\Anterior');
        ForceDirectories(fileNameTeste + '\Anterior\Anterior2');
        ForceDirectories(fileNameTeste + '\Anterior\Anterior2\Anterior3');
      end;

      ExtractStrings(['.'], ['.'], PChar(String(GetFileVersion(fileNameTeste + '\SetupAgro.exe'))), VersionListTeste);

      if VersionListTeste.Text <> VersionListBuild.Text then
        Result := fileNameTeste + '\';
    finally
      VersionListBuild.Free;
      if Assigned(VersionListTeste) then
        VersionListTeste.Free;
    end;
  end;

  procedure CopiarArquivo(Origem, Destino: string);
  begin
    if TFile.Exists(Destino) then
      TFile.Delete(Destino);

    if TFile.Exists(Origem) then
      TFile.Copy(Origem, Destino);
  end;

  procedure SubirSetup(fileNameTeste, caminhoBuild: String);
  begin
    if fileNameTeste = '' then
      Exit;

    try
      CopiarArquivo(fileNameTeste + 'Anterior\Anterior2\SetupAgro.exe', fileNameTeste + 'Anterior\Anterior2\Anterior3\SetupAgro.exe');
      CopiarArquivo(fileNameTeste + 'Anterior\SetupAgro.exe', fileNameTeste + 'Anterior\Anterior2\SetupAgro.exe');
      CopiarArquivo(fileNameTeste + 'SetupAgro.exe', fileNameTeste + 'Anterior\SetupAgro.exe');
      CopiarArquivo(caminhoBuild, fileNameTeste + 'SetupAgro.exe');
    except
      on E: Exception do
      begin
        GravaLog('Falha ao copiar o arquivo, mensagem original: ' + E.Message);
      end;
    end;
  end;

begin
  try
    SubirSetup(VerificaNovaVersao('\\10.1.0.1\srv-arquivos$\SDK\Build\SetupAgro.exe'), '\\10.1.0.1\srv-arquivos$\SDK\Build\SetupAgro.exe');
    SubirSetup(VerificaNovaVersao('\\10.1.0.1\srv-arquivos$\SDK\Build\Candidate Agro\SetupAgro.exe'), '\\10.1.0.1\srv-arquivos$\SDK\Build\Candidate Agro\SetupAgro.exe');
  except
    on E: Exception do
    begin
      GravaLog('Erro durante a verificação da versão, mensagem de erro: ' + E.Message);
      Abort;
    end;
  end
end;

procedure TSubirSetupServ.getConfigMin;
  var
  fPass: string;
begin
  try
    if Assigned(listMinConfig) then
      Exit;

    LastMin := '';

    listMinConfig := TStringList.Create;

    ExecuteOnIni(GetIniFileName, procedure(iniFile: TMemIniFile)
      begin
        fPass := iniFile.ReadString('Config', 'Minutos', '');
      end);

    if fPass = '' then
    begin
      GravaLog('Configuração de minutos não informado.');
      Abort;
    end;

    ExtractStrings([','], [','], PChar(fPass), listMinConfig);
  except
    on E: Exception do
    begin
      GravaLog('Erro durante a extração da configuração, mensagem de erro: ' + E.Message);
      Abort;
    end;
  end;
end;

function TSubirSetupServ.GetIniFileName: String;
var
  fFile: String;
begin
  if UpperCase(Application.Title) <> 'SUBIRSETUPAGRO' then
  begin
    Result := ChangeFilePath(Application.Title + '.ini', ExtractFilePath(Application.ExeName));
    Exit;
  end;

  if fFile = '' then
  begin
    if DirectoryExists('C:\SubirSetupServ') then
      fFile := 'C:\SubirSetupServ';
  end;

  if FileExists(fFile + '\SubirSetupServ.ini') then
    Result := fFile + '\SubirSetupServ.ini';
end;

function TSubirSetupServ.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TSubirSetupServ.GravaLog(texto: String);
var
  log, logAux: TStringList;
begin
  if LOG_PATH = '' then
    LoadIni;

  log    := TStringList.Create;
  logAux := TStringList.Create;
  try
    try
      logAux.Add(DateTimeToStr(now) + ' - ' + texto);

      if FileExists(LOG_PATH + 'LogSubirSetupAgro.txt') then
      begin
        log.LoadFromFile(LOG_PATH + 'LogSubirSetupAgro.txt');

        try
          while ((log.Count > 0) and (StrToDateDef(Copy(log[0], 1, Pos(' ', log[0])), MinDateTime) < Date - 30)) or (log.Count > 50000) do
            log.Delete(0);
        except
        end;
      end;

      log.AddStrings(logAux);
      log.SaveToFile(LOG_PATH + 'LogSubirSetupAgro.txt');
    finally
      log.Free;
      logAux.Free;
    end;
  except
  end;
end;

procedure TSubirSetupServ.LoadIni;
var
  fFile: String;
begin
  if fFile = '' then
    fFile := ExtractFilePath(Application.ExeName);

  ExecuteOnIni(GetIniFileName, procedure(iniFile: TMemIniFile)
    begin
      LOG_PATH := Trim(iniFile.ReadString('LOG', 'PATH', 'C:\SubirSetupServ\'));

      if not (LOG_PATH[High(LOG_PATH)] in ['\', '/']) then
        LOG_PATH := LOG_PATH + '\';

      LOG_PATH := LOG_PATH.Replace('/', '\');
    end);
end;

procedure TSubirSetupServ.ServiceExecute(Sender: TService);
begin
  while not self.Terminated do
    ServiceThread.ProcessRequests(True);
end;

procedure TSubirSetupServ.Timer1Timer(Sender: TObject);
begin
  try
    Timer1.Enabled := False;
    getConfigMin;

    if ConfereHorario then
      ConfereSobeNovoSetup;
  finally
    Timer1.Enabled := True;
  end;
end;

end.
