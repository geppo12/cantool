object fmMain: TfmMain
  Left = 0
  Top = 0
  Caption = 'Ninjeppo Can Tool v 0.1'
  ClientHeight = 467
  ClientWidth = 766
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    766
    467)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 444
    Width = 32
    Height = 13
    Anchors = [akLeft, akBottom]
    Caption = 'Device'
  end
  object Memo1: TMemo
    Left = 16
    Top = 8
    Width = 737
    Height = 417
    Anchors = [akLeft, akTop, akRight, akBottom]
    Lines.Strings = (
      'Memo1')
    TabOrder = 0
  end
  object eName: TEdit
    Left = 64
    Top = 440
    Width = 81
    Height = 21
    Anchors = [akLeft, akBottom]
    TabOrder = 1
  end
  object cbOpen: TCheckBox
    Left = 167
    Top = 442
    Width = 58
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Open'
    TabOrder = 2
    OnClick = cbOpenClick
  end
end
