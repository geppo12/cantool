object fmMain: TfmMain
  Left = 0
  Top = 0
  Caption = 'Ninjeppo Can Tool v '
  ClientHeight = 467
  ClientWidth = 774
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    774
    467)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 442
    Width = 32
    Height = 13
    Anchors = [akLeft, akBottom]
    Caption = 'Device'
  end
  object lblValue: TLabel
    Left = 609
    Top = 442
    Width = 26
    Height = 13
    Caption = 'Value'
  end
  object lblMask: TLabel
    Left = 426
    Top = 442
    Width = 24
    Height = 13
    Caption = 'Mask'
  end
  object eName: TEdit
    Left = 64
    Top = 438
    Width = 81
    Height = 21
    Anchors = [akLeft, akBottom]
    TabOrder = 0
  end
  object cbOpen: TCheckBox
    Left = 167
    Top = 440
    Width = 58
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Open'
    TabOrder = 1
    OnClick = cbOpenClick
  end
  object pgControl: TPageControl
    Left = 8
    Top = 8
    Width = 758
    Height = 424
    ActivePage = CanLog
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 2
    OnChange = pgControlChange
    OnResize = pgControlResize
    object Debug: TTabSheet
      Caption = 'Debug'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object lbLogEntry: TListBox
        Left = 0
        Top = 0
        Width = 750
        Height = 396
        Align = alClient
        ItemHeight = 13
        TabOrder = 0
      end
    end
    object CanLog: TTabSheet
      Caption = 'CanLog'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object sgRawLog: TStringGrid
        Left = 0
        Top = 0
        Width = 736
        Height = 396
        Align = alClient
        ColCount = 3
        DefaultRowHeight = 15
        DefaultDrawing = False
        FixedCols = 0
        RowCount = 1
        FixedRows = 0
        GridLineWidth = 0
        Options = []
        ScrollBars = ssNone
        TabOrder = 0
        OnDrawCell = sgRawLogDrawCell
        ColWidths = (
          93
          30
          332)
      end
      object vScrollBar: TScrollBar
        Left = 736
        Top = 0
        Width = 14
        Height = 396
        Align = alRight
        Kind = sbVertical
        PageSize = 0
        TabOrder = 1
        OnChange = vScrollBarChange
      end
    end
    object Options: TTabSheet
      Caption = 'Options'
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Label2: TLabel
        Left = 5
        Top = 19
        Width = 75
        Height = 13
        Caption = 'Squeeze Log ID'
      end
      object Label3: TLabel
        Left = 5
        Top = 107
        Width = 52
        Height = 13
        Caption = 'Node Mask'
      end
      object Label4: TLabel
        Left = 5
        Top = 63
        Width = 88
        Height = 13
        Caption = 'Squeeze Log Mask'
      end
      object eSqzLogID: TEdit
        Left = 108
        Top = 16
        Width = 121
        Height = 21
        TabOrder = 0
      end
      object eNodeMask: TEdit
        Left = 108
        Top = 104
        Width = 121
        Height = 21
        TabOrder = 2
      end
      object eSqzLogMask: TEdit
        Left = 108
        Top = 60
        Width = 121
        Height = 21
        TabOrder = 1
      end
    end
  end
  object eMask: TEdit
    Left = 456
    Top = 438
    Width = 120
    Height = 21
    TabOrder = 3
  end
  object eValue: TEdit
    Left = 641
    Top = 438
    Width = 120
    Height = 21
    TabOrder = 4
  end
  object cbFilter: TCheckBox
    Left = 400
    Top = 440
    Width = 20
    Height = 17
    TabOrder = 5
    OnClick = cbFilterClick
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 264
    Top = 424
  end
end
