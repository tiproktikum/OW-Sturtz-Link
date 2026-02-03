object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'OW'#8211'Sturtz Link'
  ClientHeight = 804
  ClientWidth = 766
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object btnLoadGroups: TButton
    Left = 24
    Top = 310
    Width = 160
    Height = 25
    Caption = #1047#1072#1075#1088#1091#1079#1080#1090#1100' '#1075#1088#1091#1087#1087#1099
    TabOrder = 0
    OnClick = btnLoadGroupsClick
  end
  object listGroups: TListBox
    Left = 16
    Top = 341
    Width = 430
    Height = 320
    ItemHeight = 13
    TabOrder = 1
  end
  object btnExport: TButton
    Left = 552
    Top = 582
    Width = 150
    Height = 25
    Caption = #1042#1099#1075#1088#1091#1079#1080#1090#1100' .sob'
    TabOrder = 2
    OnClick = btnExportClick
  end
  object pConnect: TPanel
    Left = 0
    Top = 73
    Width = 766
    Height = 223
    Align = alTop
    TabOrder = 3
    ExplicitWidth = 873
    object lblCharset: TLabel
      Left = 400
      Top = 72
      Width = 58
      Height = 13
      Caption = #1050#1086#1076#1080#1088#1086#1074#1082#1072
    end
    object lblDbPath: TLabel
      Left = 16
      Top = 16
      Width = 50
      Height = 13
      Caption = #1055#1091#1090#1100' '#1082' '#1041#1044
    end
    object lblExportDir: TLabel
      Left = 16
      Top = 128
      Width = 85
      Height = 13
      Caption = #1055#1072#1087#1082#1072' '#1074#1099#1075#1088#1091#1079#1082#1080
    end
    object lblPassword: TLabel
      Left = 144
      Top = 72
      Width = 40
      Height = 13
      Caption = #1055#1072#1088#1086#1083#1100
    end
    object lblRole: TLabel
      Left = 272
      Top = 72
      Width = 25
      Height = 13
      Caption = #1056#1086#1083#1100
    end
    object lblUser: TLabel
      Left = 16
      Top = 72
      Width = 74
      Height = 13
      Caption = #1055#1086#1083#1100#1079#1086#1074#1072#1090#1077#1083#1100
    end
    object btnBrowseDb: TButton
      Left = 664
      Top = 34
      Width = 90
      Height = 23
      Caption = #1054#1073#1079#1086#1088'...'
      TabOrder = 0
      OnClick = btnBrowseDbClick
    end
    object btnBrowseExportDir: TButton
      Left = 664
      Top = 146
      Width = 90
      Height = 23
      Caption = #1054#1073#1079#1086#1088'...'
      TabOrder = 1
      OnClick = btnBrowseExportDirClick
    end
    object btnConnect: TButton
      Left = 16
      Top = 185
      Width = 110
      Height = 23
      Caption = #1055#1086#1076#1082#1083#1102#1095#1080#1090#1100#1089#1103
      TabOrder = 2
      OnClick = btnConnectClick
    end
    object btnDisconnect: TButton
      Left = 132
      Top = 185
      Width = 110
      Height = 23
      Caption = #1054#1090#1082#1083#1102#1095#1080#1090#1100#1089#1103
      TabOrder = 3
      OnClick = btnDisconnectClick
    end
    object btnSaveConfig: TButton
      Left = 536
      Top = 185
      Width = 218
      Height = 23
      Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100' '#1085#1072#1089#1090#1088#1086#1081#1082#1080' '#1087#1086#1076#1082#1083#1102#1095#1077#1085#1080#1103
      TabOrder = 4
      OnClick = btnSaveConfigClick
    end
    object edtCharset: TEdit
      Left = 400
      Top = 92
      Width = 120
      Height = 21
      TabOrder = 5
    end
    object edtDbPath: TEdit
      Left = 16
      Top = 36
      Width = 640
      Height = 21
      TabOrder = 6
    end
    object edtExportDir: TEdit
      Left = 16
      Top = 148
      Width = 640
      Height = 21
      TabOrder = 7
    end
    object edtPassword: TEdit
      Left = 144
      Top = 92
      Width = 120
      Height = 21
      PasswordChar = '*'
      TabOrder = 8
    end
    object edtRole: TEdit
      Left = 272
      Top = 92
      Width = 120
      Height = 21
      TabOrder = 9
    end
    object edtUser: TEdit
      Left = 16
      Top = 92
      Width = 120
      Height = 21
      TabOrder = 10
    end
  end
  object pBottom: TPanel
    Left = 0
    Top = 689
    Width = 766
    Height = 115
    Align = alBottom
    TabOrder = 4
    OnClick = pBottomClick
    ExplicitTop = 624
    ExplicitWidth = 1033
    object memoLog: TMemo
      Left = 1
      Top = 1
      Width = 764
      Height = 113
      Align = alClient
      ScrollBars = ssVertical
      TabOrder = 0
      ExplicitTop = 0
      ExplicitWidth = 1031
      ExplicitHeight = 110
    end
  end
  object pTop: TPanel
    Left = 0
    Top = 0
    Width = 766
    Height = 73
    Align = alTop
    Caption = 'pTop'
    TabOrder = 5
    ExplicitWidth = 1086
    object Image1: TImage
      Left = 1
      Top = 1
      Width = 764
      Height = 71
      Align = alClient
      ExplicitLeft = 168
      ExplicitTop = 7
      ExplicitWidth = 105
      ExplicitHeight = 105
    end
  end
  object OpenDialogDb: TOpenDialog
    Left = 688
    Top = 152
  end
end
