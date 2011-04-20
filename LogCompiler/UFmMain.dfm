object fmMain: TfmMain
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = 'Log Compiler'
  ClientHeight = 556
  ClientWidth = 351
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 248
    Top = 532
    Width = 38
    Height = 13
    Caption = 'Msg Set'
  end
  object lbFiles: TListBox
    Left = 8
    Top = 8
    Width = 333
    Height = 369
    ItemHeight = 13
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
    OnKeyDown = lbFilesKeyDown
    OnMouseMove = lbFilesMouseMove
  end
  object btnAddFiles: TButton
    Left = 8
    Top = 497
    Width = 75
    Height = 25
    Caption = 'Add Files'
    TabOrder = 1
    OnClick = btnAddFilesClick
  end
  object btnProcess: TButton
    Left = 268
    Top = 497
    Width = 75
    Height = 25
    Caption = 'Process'
    TabOrder = 2
    OnClick = btnProcessClick
  end
  object eMsgSet: TEdit
    Left = 301
    Top = 528
    Width = 42
    Height = 21
    TabOrder = 3
    Text = '0'
    OnChange = eMsgSetChange
    OnExit = eMsgSetExit
  end
  object mError: TMemo
    Left = 8
    Top = 383
    Width = 333
    Height = 82
    TabOrder = 4
  end
  object cbCleanOnly: TCheckBox
    Left = 8
    Top = 471
    Width = 75
    Height = 17
    Caption = 'Clean Only'
    TabOrder = 5
  end
  object btnProject: TButton
    Left = 94
    Top = 497
    Width = 75
    Height = 25
    Caption = 'Save Project'
    TabOrder = 6
    OnClick = btnProjectClick
  end
  object eSetDir: TEdit
    Left = 8
    Top = 528
    Width = 217
    Height = 21
    TabOrder = 7
  end
  object cbCRC: TCheckBox
    Left = 89
    Top = 471
    Width = 51
    Height = 17
    Caption = 'CRC'
    TabOrder = 8
    OnClick = cbCRCClick
  end
  object cbDoublePar: TCheckBox
    Left = 160
    Top = 471
    Width = 97
    Height = 17
    Caption = '(( XXX )) Form'
    TabOrder = 9
    OnClick = cbDoubleParClick
  end
  object btnClear: TButton
    Left = 175
    Top = 497
    Width = 75
    Height = 25
    Caption = 'Clear'
    TabOrder = 10
    OnClick = btnClearClick
  end
  object OpenDialog: TOpenDialog
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofEnableSizing]
    Left = 288
    Top = 24
  end
  object SaveDialog: TSaveDialog
    Filter = 'Squeeze Project (*.psz)|*.psz'
    Left = 256
    Top = 24
  end
end
