unit main;

//  https://mam-mam.net/delphi/hid.html

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, UHIDThread;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Memo1: TMemo;
    ListBox1: TListBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Edit1: TEdit;
    Button4: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    { Private éŒ¾ }
    DeviceList : THIDDeviceList;
    HIDthread : THIDthread;
  public
    { Public éŒ¾ }
  end;

var
  Form1: TForm1;

procedure HIDDataRead(Data:THIDbuffer); stdcall;

implementation

{$R *.dfm}

uses WinAPI.MMSystem;

procedure HIDDataRead(Data:THIDbuffer); stdcall;
var st:String;
    i:Integer;
begin
  st:='> ';
  for i := 0 to Length(Data)-1 do
    st := st + chr(Data[i]);
  Form1.Memo1.Lines.Add(st);
end;


procedure TForm1.Button1Click(Sender: TObject);
var i:integer;
begin
  DeviceList := GetHidDeviceList();
  ListBox1.Clear;
  for i := 0 to Length(DeviceList)-1 do
  begin
      ListBox1.AddItem(
        Format('%2d [%.4x/%.4x]',[i,DeviceList[i].VID,DeviceList[i].PID])+':'+
        DeviceList[i].ProductString+'('+
        DeviceList[i].ManufacturerString+')'
        , nil
      );
  end;

  Label1.Caption := findHidDeviceList($04D8, $EA65);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if ListBox1.ItemIndex < 0 then exit;

  Label1.Caption := DeviceList[ListBox1.ItemIndex].ProductString;
  Label2.Caption := DeviceList[ListBox1.ItemIndex].ManufacturerString;
  Label3.Caption := DeviceList[ListBox1.ItemIndex].SymLink;

  HIDthread.ActiveDevice := DeviceList[ListBox1.ItemIndex];
  HIDthread.HIDOpenDevice;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  memo1.Lines.Add('< ' + Edit1.text);
  memo1.Lines.Add('ret=' + inttostr( HIDthread.send(Edit1.text) ));
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  HIDthread := THIDthread.Create;
  HIDthread.HIDcallback := HIDDataRead;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  HIDthread.Terminate;
end;

end.
