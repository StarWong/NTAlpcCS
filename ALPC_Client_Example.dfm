object Client: TClient
  Left = 0
  Top = 0
  Caption = 'LPC_kernel_Client'
  ClientHeight = 346
  ClientWidth = 643
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 208
    Top = 128
    Width = 161
    Height = 25
    Caption = 'Sum'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Edit1: TEdit
    Left = 152
    Top = 56
    Width = 121
    Height = 21
    TabOrder = 1
  end
  object Edit2: TEdit
    Left = 344
    Top = 56
    Width = 121
    Height = 21
    TabOrder = 2
  end
end
