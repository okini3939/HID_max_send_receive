object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 491
  ClientWidth = 643
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 431
    Width = 31
    Height = 13
    Caption = 'Label1'
  end
  object Label2: TLabel
    Left = 8
    Top = 450
    Width = 31
    Height = 13
    Caption = 'Label2'
  end
  object Label3: TLabel
    Left = 8
    Top = 469
    Width = 31
    Height = 13
    Caption = 'Label3'
  end
  object Button1: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'HID'#19968#35239
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 288
    Top = 8
    Width = 75
    Height = 25
    Caption = #25509#32154
    TabOrder = 1
    OnClick = Button2Click
  end
  object Memo1: TMemo
    Left = 288
    Top = 39
    Width = 329
    Height = 386
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object ListBox1: TListBox
    Left = 8
    Top = 40
    Width = 265
    Height = 385
    ItemHeight = 13
    TabOrder = 3
  end
  object Edit1: TEdit
    Left = 289
    Top = 431
    Width = 248
    Height = 21
    TabOrder = 4
  end
  object Button4: TButton
    Left = 543
    Top = 431
    Width = 75
    Height = 25
    Caption = #36865#20449
    TabOrder = 5
    OnClick = Button4Click
  end
end
