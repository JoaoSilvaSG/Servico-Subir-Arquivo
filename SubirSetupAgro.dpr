program SubirSetupAgro;

uses
  Vcl.SvcMgr,
  SysUtils,
  RSLib,
  WinSvc,
  Dialogs,
  UPrincipal in 'UPrincipal.pas' {SubirSetupServ: TService};

{$R *.RES}

var
  manager, service: NativeInt;
  st: TServiceStatus;
  t: String;
begin
  // Windows 2003 Server requires StartServiceCtrlDispatcher to be
  // called before CoRegisterClassObject, which can be called indirectly
  // by Application.Initialize. TServiceApplication.DelayInitialize allows
  // Application.Initialize to be called from TService.Main (after
  // StartServiceCtrlDispatcher has been called).
  //
  // Delayed initialization of the Application object may affect
  // events which then occur prior to initialization, such as
  // TService.OnCreate. It is only recommended if the ServiceApplication
  // registers a class object with OLE and is intended for use with
  // Windows 2003 Server.
  //
  // Application.DelayInitialize := True;
  //

   if FindCmdLineSwitch('UNINSTALL', ['-', '/'], True) or FindCmdLineSwitch('INSTALL', ['-', '/'], True) then
  begin
    manager := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
    if manager <> 0 then
    begin
      t:= 'SubirSetupServ';
      service := OpenService(manager, PChar(t), SERVICE_QUERY_STATUS or SERVICE_STOP);
      try
        if FindCmdLineSwitch('UNINSTALL', ['-', '/'], True) then
        begin
          if service = 0 then
            Exit
          else
            ControlService(service, SERVICE_CONTROL_STOP, st);
        end
        else if service <> 0 then
          Exit;
      finally
        if service <> 0 then
          CloseServiceHandle(service);
        CloseServiceHandle(manager);
      end;
    end;
  end;

  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TSubirSetupServ, SubirSetupServ);
  Application.Run;
end.
