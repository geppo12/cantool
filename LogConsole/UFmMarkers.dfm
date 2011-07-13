object fmMarkerEdit: TfmMarkerEdit
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'MarkerEdit'
  ClientHeight = 295
  ClientWidth = 428
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 175
    Top = 8
    Width = 27
    Height = 13
    Caption = 'Name'
  end
  object Label2: TLabel
    Left = 175
    Top = 54
    Width = 24
    Height = 13
    Caption = 'Mask'
  end
  object Label3: TLabel
    Left = 175
    Top = 100
    Width = 19
    Height = 13
    Caption = 'Low'
  end
  object Label4: TLabel
    Left = 175
    Top = 146
    Width = 21
    Height = 13
    Caption = 'High'
  end
  object Label5: TLabel
    Left = 175
    Top = 189
    Width = 25
    Height = 13
    Caption = 'Color'
  end
  object lbMarkers: TListBox
    Left = 8
    Top = 8
    Width = 161
    Height = 279
    ItemHeight = 13
    TabOrder = 0
    OnClick = lbMarkersClick
  end
  object eName: TEdit
    Left = 175
    Top = 27
    Width = 243
    Height = 21
    TabOrder = 1
  end
  object eMask: TEdit
    Left = 175
    Top = 73
    Width = 186
    Height = 21
    TabOrder = 2
  end
  object eLow: TEdit
    Left = 175
    Top = 119
    Width = 243
    Height = 21
    TabOrder = 4
  end
  object eHigh: TEdit
    Left = 175
    Top = 165
    Width = 243
    Height = 21
    TabOrder = 5
  end
  object btnAdd: TButton
    Left = 259
    Top = 262
    Width = 75
    Height = 25
    Caption = 'Add'
    TabOrder = 7
    OnClick = btnAddClick
  end
  object btnDel: TButton
    Left = 175
    Top = 262
    Width = 75
    Height = 25
    Caption = 'Del'
    TabOrder = 9
    OnClick = btnDelClick
  end
  object btnOK: TButton
    Left = 343
    Top = 262
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 8
  end
  object cbColor: TComboBox
    Left = 175
    Top = 208
    Width = 245
    Height = 22
    Style = csOwnerDrawVariable
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 6
    OnDrawItem = cbColorDrawItem
  end
  object cbExt: TCheckBox
    Left = 376
    Top = 75
    Width = 42
    Height = 17
    Caption = 'XTD'
    TabOrder = 3
  end
end
