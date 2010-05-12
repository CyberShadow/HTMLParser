object MainForm: TMainForm
  Left = 215
  Top = 107
  Width = 814
  Height = 477
  Caption = 'CyberShadow'#39's HTML parser v1.3'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnMouseDown = FormMouseDown
  OnResize = FormResize
  OnShow = FormShow
  DesignSize = (
    806
    447)
  PixelsPerInch = 96
  TextHeight = 13
  object HorVertButton: TSpeedButton
    Left = 552
    Top = 4
    Width = 33
    Height = 25
    AllowAllUp = True
    GroupIndex = 1
    Caption = '&Vert'
    OnClick = HorVertButtonClick
    OnMouseDown = FormMouseDown
  end
  object LoadButton: TButton
    Left = 306
    Top = 4
    Width = 75
    Height = 25
    Caption = '&Load'
    Default = True
    TabOrder = 0
    OnClick = LoadButtonClick
    OnMouseDown = FormMouseDown
  end
  object FileNameBox: TEdit
    Left = 8
    Top = 6
    Width = 185
    Height = 21
    TabOrder = 5
  end
  object TranslateButton: TButton
    Left = 384
    Top = 4
    Width = 75
    Height = 25
    Caption = '&Translate'
    TabOrder = 1
    OnClick = TranslateButtonClick
    OnMouseDown = FormMouseDown
  end
  object Panel1: TPanel
    Left = 0
    Top = 56
    Width = 806
    Height = 367
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelOuter = bvNone
    TabOrder = 4
    object Splitter: TSplitter
      Left = 381
      Top = 0
      Height = 367
      MinSize = 60
      ResizeStyle = rsUpdate
      OnCanResize = SplitterCanResize
      OnMoved = SplitterMoved
    end
    object HTMLSource: TMemo
      Left = 0
      Top = 0
      Width = 381
      Height = 367
      Align = alLeft
      Alignment = taCenter
      Color = 16056308
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Lucida Console'
      Font.Style = []
      HideSelection = False
      Lines.Strings = (
        ''
        ''
        ''
        ''
        ''
        ''
        ''
        'No file loaded')
      ParentFont = False
      PopupMenu = SourceMenu
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 0
      WordWrap = False
      OnChange = HTMLSourceClick
      OnClick = HTMLSourceClick
      OnDblClick = HTMLSourceClick
      OnKeyDown = HTMLSourceKeyDown
      OnKeyPress = HTMLSourceKeyPress
      OnKeyUp = HTMLSourceKeyDown
      OnMouseDown = HTMLSourceMouseDown
      OnMouseMove = HTMLSourceMouseMove
      OnMouseUp = HTMLSourceMouseDown
    end
    object TreeView: TTreeView
      Left = 384
      Top = 0
      Width = 422
      Height = 367
      Align = alClient
      Color = 16774388
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Lucida Console'
      Font.Style = []
      HideSelection = False
      HotTrack = True
      Indent = 19
      ParentFont = False
      ReadOnly = True
      RightClickSelect = True
      TabOrder = 1
      OnChange = TreeViewChange
      OnClick = TreeViewClick
      OnDblClick = TreeViewDblClick
      OnMouseDown = FormMouseDown
    end
  end
  object BrowseBtn: TButton
    Left = 200
    Top = 6
    Width = 21
    Height = 21
    Caption = '.&..'
    TabOrder = 6
    OnClick = BrowseBtnClick
    OnMouseDown = FormMouseDown
  end
  object SelectTag: TRadioButton
    Left = 464
    Top = 0
    Width = 82
    Height = 16
    Caption = 'Select ta&g'
    Checked = True
    TabOrder = 2
    TabStop = True
    OnClick = TreeViewClick
    OnMouseDown = FormMouseDown
  end
  object SelectBlock: TRadioButton
    Left = 464
    Top = 16
    Width = 82
    Height = 16
    Caption = 'Select &block'
    TabOrder = 3
    OnClick = TreeViewClick
    OnMouseDown = FormMouseDown
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 428
    Width = 806
    Height = 19
    Panels = <
      item
        Text = 'Row: 0'
        Width = 60
      end
      item
        Text = 'Col: 0'
        Width = 60
      end
      item
        Text = 'SelStart: 0'
        Width = 80
      end
      item
        Text = 'SelLength: 0'
        Width = 90
      end
      item
        Text = 'Total nodes: 0'
        Width = 100
      end
      item
        Width = 50
      end>
  end
  object Address: TEdit
    Left = 8
    Top = 32
    Width = 561
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 8
    OnEnter = AddressEnter
    OnExit = AddressExit
  end
  object GoButton: TButton
    Left = 576
    Top = 32
    Width = 41
    Height = 21
    Anchors = [akTop, akRight]
    Caption = 'Go'
    TabOrder = 9
    OnClick = GoButtonClick
  end
  object QSearch: TEdit
    Left = 624
    Top = 32
    Width = 129
    Height = 21
    Hint = 'Search'
    Anchors = [akTop, akRight]
    ParentShowHint = False
    ShowHint = True
    TabOrder = 10
    OnChange = QSearchChange
    OnEnter = QSearchEnter
  end
  object FindNext: TButton
    Left = 760
    Top = 32
    Width = 41
    Height = 21
    Anchors = [akTop, akRight]
    Caption = 'Next'
    TabOrder = 11
    OnClick = FindNextClick
  end
  object XPManifest: TXPManifest
    Left = 592
    Top = 2
  end
  object OpenDialog: TOpenDialog
    Filter = 'HTML files|*.ht*|All files|*.*'
    Left = 624
    Top = 2
  end
  object StatusTimer: TTimer
    Interval = 1
    OnTimer = StatusTimerTimer
    Left = 656
    Top = 2
  end
  object ColorMenu: TPopupMenu
    Left = 688
    Top = 2
    object Standard1: TMenuItem
      Tag = 1
      AutoCheck = True
      Caption = 'Windows default'
      GroupIndex = 1
      RadioItem = True
      OnClick = ColorSelect
    end
    object Green1: TMenuItem
      Tag = 2
      AutoCheck = True
      Caption = 'Green && Blue'
      GroupIndex = 1
      RadioItem = True
      OnClick = ColorSelect
    end
    object GreenBlue21: TMenuItem
      Tag = 3
      AutoCheck = True
      Caption = 'Green && Blue 2'
      GroupIndex = 1
      RadioItem = True
      OnClick = ColorSelect
    end
    object N1: TMenuItem
      Caption = '-'
      GroupIndex = 1
    end
    object Smoothanimation1: TMenuItem
      AutoCheck = True
      Caption = 'Smooth animation'
      GroupIndex = 1
      OnClick = Smoothanimation1Click
    end
  end
  object ApplicationEvents: TApplicationEvents
    OnHint = ApplicationEventsHint
    Left = 752
    Top = 2
  end
  object SourceMenu: TPopupMenu
    Left = 720
    Top = 2
    object SourceMenuCopy: TMenuItem
      Caption = '&Copy'
      OnClick = SourceMenuCopyClick
    end
    object SourceMenuSelectAll: TMenuItem
      Caption = 'Select &all'
      OnClick = SourceMenuSelectAllClick
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object SourceMenuWordWrap: TMenuItem
      AutoCheck = True
      Caption = '&Word-wrap'
      OnClick = SourceMenuWordWrapClick
    end
    object SourceMenuAlignSource: TMenuItem
      Caption = 'Align &source'
    end
  end
end
