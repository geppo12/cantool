object fmFilter: TfmFilter
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Filter'
  ClientHeight = 295
  ClientWidth = 452
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object sgFilter: TStringGrid
    Left = 8
    Top = 8
    Width = 436
    Height = 241
    ColCount = 4
    DefaultColWidth = 134
    FixedCols = 0
    RowCount = 9
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goTabs]
    TabOrder = 0
    ColWidths = (
      134
      28
      131
      134)
  end
  object btnOK: TButton
    Left = 343
    Top = 262
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 262
    Top = 262
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
