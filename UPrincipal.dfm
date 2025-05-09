object SubirSetupServ: TSubirSetupServ
  OldCreateOrder = False
  DisplayName = 'SubirSetupServ'
  OnExecute = ServiceExecute
  Height = 150
  Width = 215
  object Timer1: TTimer
    Interval = 30000
    OnTimer = Timer1Timer
    Left = 94
    Top = 23
  end
end
