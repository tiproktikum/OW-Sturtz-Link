object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'OW'#8211'Sturtz Link'
  ClientHeight = 801
  ClientWidth = 738
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
  object pConnect: TPanel
    Left = 0
    Top = 83
    Width = 738
    Height = 182
    Align = alTop
    TabOrder = 0
    object lblCharset: TLabel
      Left = 392
      Top = 57
      Width = 58
      Height = 13
      Caption = #1050#1086#1076#1080#1088#1086#1074#1082#1072
    end
    object lblDbPath: TLabel
      Left = 8
      Top = 9
      Width = 50
      Height = 13
      Caption = #1055#1091#1090#1100' '#1082' '#1041#1044
    end
    object lblExportDir: TLabel
      Left = 8
      Top = 105
      Width = 85
      Height = 13
      Caption = #1055#1072#1087#1082#1072' '#1074#1099#1075#1088#1091#1079#1082#1080
    end
    object lblPassword: TLabel
      Left = 136
      Top = 57
      Width = 40
      Height = 13
      Caption = #1055#1072#1088#1086#1083#1100
    end
    object lblRole: TLabel
      Left = 264
      Top = 57
      Width = 25
      Height = 13
      Caption = #1056#1086#1083#1100
    end
    object lblUser: TLabel
      Left = 8
      Top = 57
      Width = 74
      Height = 13
      Caption = #1055#1086#1083#1100#1079#1086#1074#1072#1090#1077#1083#1100
    end
    object btnBrowseDb: TButton
      Left = 656
      Top = 26
      Width = 73
      Height = 23
      Caption = #1054#1073#1079#1086#1088'...'
      TabOrder = 0
      OnClick = btnBrowseDbClick
    end
    object btnBrowseExportDir: TButton
      Left = 654
      Top = 122
      Width = 75
      Height = 23
      Caption = #1054#1073#1079#1086#1088'...'
      TabOrder = 1
      OnClick = btnBrowseExportDirClick
    end
    object btnConnect: TButton
      Left = 8
      Top = 151
      Width = 110
      Height = 23
      Caption = #1055#1086#1076#1082#1083#1102#1095#1080#1090#1100#1089#1103
      TabOrder = 2
      OnClick = btnConnectClick
    end
    object btnDisconnect: TButton
      Left = 124
      Top = 151
      Width = 110
      Height = 23
      Caption = #1054#1090#1082#1083#1102#1095#1080#1090#1100#1089#1103
      TabOrder = 3
      OnClick = btnDisconnectClick
    end
    object btnSaveConfig: TButton
      Left = 511
      Top = 151
      Width = 218
      Height = 23
      Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100' '#1085#1072#1089#1090#1088#1086#1081#1082#1080' '#1087#1086#1076#1082#1083#1102#1095#1077#1085#1080#1103
      TabOrder = 4
      OnClick = btnSaveConfigClick
    end
    object edtCharset: TEdit
      Left = 392
      Top = 76
      Width = 120
      Height = 21
      TabOrder = 5
    end
    object edtDbPath: TEdit
      Left = 8
      Top = 28
      Width = 640
      Height = 21
      TabOrder = 6
    end
    object edtExportDir: TEdit
      Left = 8
      Top = 124
      Width = 640
      Height = 21
      TabOrder = 7
    end
    object edtPassword: TEdit
      Left = 136
      Top = 76
      Width = 120
      Height = 21
      PasswordChar = '*'
      TabOrder = 8
    end
    object edtRole: TEdit
      Left = 264
      Top = 76
      Width = 120
      Height = 21
      TabOrder = 9
    end
    object edtUser: TEdit
      Left = 8
      Top = 76
      Width = 120
      Height = 21
      TabOrder = 10
    end
  end
  object pBottom: TPanel
    Left = 0
    Top = 656
    Width = 738
    Height = 145
    Align = alBottom
    TabOrder = 1
    object lblLog: TLabel
      Left = 5
      Top = 6
      Width = 85
      Height = 13
      Caption = #1051#1086#1075' '#1087#1088#1086#1075#1088#1072#1084#1084#1099
    end
    object memoLog: TMemo
      Left = 1
      Top = 25
      Width = 736
      Height = 119
      Align = alBottom
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object pTop: TPanel
    Left = 0
    Top = 0
    Width = 738
    Height = 83
    Align = alTop
    Caption = 'pTop'
    TabOrder = 3
    ExplicitWidth = 766
    object Image1: TImage
      Left = 1
      Top = 1
      Width = 736
      Height = 81
      Align = alClient
      ExplicitWidth = 764
      ExplicitHeight = 82
    end
  end
  object pMain: TPanel
    Left = 0
    Top = 265
    Width = 738
    Height = 391
    Align = alClient
    TabOrder = 2
    ExplicitLeft = 8
    ExplicitTop = 332
    ExplicitWidth = 624
    ExplicitHeight = 329
    object btnExport: TButton
      Left = 551
      Top = 342
      Width = 178
      Height = 32
      Caption = #1042#1099#1075#1088#1091#1079#1080#1090#1100' '#1092#1072#1081#1083#1099' '#1076#1083#1103' Sturtz'
      TabOrder = 0
      OnClick = btnExportClick
    end
    object listGroups: TListBox
      Left = 1
      Top = 1
      Width = 736
      Height = 335
      Align = alTop
      ItemHeight = 13
      TabOrder = 1
      ExplicitWidth = 764
    end
  end
  object OpenDialogDb: TOpenDialog
    Left = 688
    Top = 152
  end
end
