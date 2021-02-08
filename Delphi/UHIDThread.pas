// https://mam-mam.net/delphi/hid.html

unit UHIDThread;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms;

type
  THIDdeviceInfo = Record
    SymLink            : String;
    BufferSize         : Word;
    BufferSizeIn       : Word;
    Handle             : THandle;
    VID                : Word;
    PID                : Word;
    VersionNumber      : Word;
    ManufacturerString : String;
    ProductString      : String;
    SerialNumberString : String;
  end;

  THIDDeviceList = Array of THIDdeviceInfo;
  THIDbuffer     = Array[0..63] of Byte;
  THIDcallBack      = Procedure(Data:THIDbuffer);stdcall;

  THIDreport = Packed Record
    ReportID:Byte;
    Data    :THIDbuffer;
  end;

  THIDthread = class(TThread)
  private
    FActiveDevice:THIDdeviceInfo;
    procedure setActiveDevice(ADevice:THIDdeviceInfo);
    procedure HIDCloseDevice();
    function HIDReadDevice(var Data:THIDbuffer): Boolean;
  public
    HIDcallback: THIDcallBack;
    Constructor Create;
    destructor Destroy; override;
    procedure Execute; override;
    procedure HIDOpenDevice();
    property ActiveDevice:THIDdeviceInfo read FActiveDevice write setActiveDevice;
    function send(data: string): integer;
  end;


function GetHidDeviceList():THIDDeviceList;
function findHidDeviceList(vid, pid: DWORD): string;


implementation

uses Hid, SetupApi, main;

function GetHidDeviceInfo(Symlink:PChar):THIDdeviceInfo;
var
  pStr         :pWideChar;
  PreparsedData:PHIDPPreparsedData;
  HidCaps      :THIDPCaps;
  DevHandle    :THandle;
  HidAttrs     :THIDDAttributes;
  ret:LongBool;
const
  HIDUSB_COUNTOFINTERRUPTBUFFERS = 64;
begin
  ZeroMemory(@Result,SizeOf(THIDdeviceInfo));
  Result.SymLink := SymLink ;
  GetMem(pStr, 1024);
  DevHandle := CreateFileW(
    Symlink, GENERIC_READ or GENERIC_WRITE,
    FILE_SHARE_READ OR FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
  If (DevHandle <> INVALID_HANDLE_VALUE) then
  begin
    If HidD_GetAttributes(DevHandle, HidAttrs) then
    begin
        Result.VID          :=HidAttrs.VendorID;
        Result.PID          :=HidAttrs.ProductID;
        Result.VersionNumber:=HidAttrs.VersionNumber;
    end;
    If HidD_GetManufacturerString(DevHandle, pStr, 1024) then
      Result.ManufacturerString := String(pStr)
    else
      Result.ManufacturerString := '';
    If HidD_GetProductString(DevHandle, pStr, 1024) then
      Result.ProductString := String(pStr)
    else
      Result.ProductString := '';
    If HidD_GetSerialNumberString(DevHandle, pStr, 1024) then
      Result.SerialNumberString := String(pStr)
    else Result.SerialNumberString := '';
    HidD_SetNumInputBuffers(DevHandle, HIDUSB_COUNTOFINTERRUPTBUFFERS);
    ret:=HidD_GetPreparsedData(DevHandle, PreparsedData);
    If ret and (PreparsedData<>nil) then
    begin
      HidP_GetCaps(PreparsedData, HidCaps);
      Result.BufferSize := HidCaps.OutputReportByteLength;
      Result.BufferSizeIn := HidCaps.InputReportByteLength;
      HidD_FreePreparsedData(PreparsedData);
    end
    else Result.BufferSize := 0;
    CloseHandle(DevHandle);
  end;
  FreeMem(pStr);
end;

function GetHidDeviceList():THIDDeviceList;
var
  HID_GUID   :TGUID;
  spdid      :TSPDeviceInterfaceData;
  pSpDidd    :PSPDeviceInterfaceDetailDataW;
  spddd      :TSPDevInfoData;
  HidInfo    :HDEVINFO;
  DevCnt     :Integer;
  dwSize     :DWord;
  Info       :THIDdeviceInfo;
  DeviceList :THIDDeviceList;
  dummy: DWord;
begin

  HidD_GetHidGuid(HID_GUID);
  HIDinfo := SetupDiGetClassDevsW(
    @HID_GUID, nil, {self.handle} 0, DIGCF_DEVICEINTERFACE or DIGCF_PRESENT);
  if (THandle(HIDinfo)<>INVALID_HANDLE_VALUE) then
  begin
    DevCnt := 0;
    spdid.cbSize := SizeOf(spdid);
    while SetupDiEnumDeviceInterfaces(
      HidInfo, nil, HID_GUID, DevCnt, spdid) do
    begin
      setlength(DeviceList,DevCnt+1);
      //ClearDeviceInfo(DeviceList[DevID]);
      ZeroMemory(@DeviceList[DevCnt],SizeOf(THIDdeviceInfo));
      dwSize := 0;
      SetupDiGetDeviceInterfaceDetailW(
        HIDinfo, @spdid, nil, 0, dwSize, nil);

      If (dwSize > 0) then
      begin
        GetMem(pSpDidd, dwSize);
        pSpDidd.cbSize := SizeOf(TSPDeviceInterfaceDetailDataW);
        spddd.cbSize    := SizeOf(spddd);
        If SetupDiGetDeviceInterfaceDetailW(
            HIDinfo, @spdid, pSpDidd, dwSize, dummy, @spddd) then
        begin
          ZeroMemory(@Info,SizeOf(THIDdeviceInfo));
          Info := GetHidDeviceInfo(@(pSpDidd^.DevicePath));
          Info.Handle := INVALID_HANDLE_VALUE;
          DeviceList[DevCnt]:=Info;
        end;
        FreeMem(pSpDidd);
      end;
      inc(DevCnt);
    end;
    SetupDiDestroyDeviceInfoList(HidInfo);
  end;
  Result:=DeviceList;
end;

function findHidDeviceList(vid, pid: DWORD): string;
var
  HID_GUID   :TGUID;
  spdid      :TSPDeviceInterfaceData;
  pSpDidd    :PSPDeviceInterfaceDetailDataW;
  spddd      :TSPDevInfoData;
  HidInfo    :HDEVINFO;
  DevCnt     :Integer;
  dwSize     :DWord;
  Info       :THIDdeviceInfo;
  dummy: DWord;
begin
  result := '';
  HidD_GetHidGuid(HID_GUID);
  HIDinfo := SetupDiGetClassDevsW(
    @HID_GUID, nil, {self.handle} 0, DIGCF_DEVICEINTERFACE or DIGCF_PRESENT);
  if (THandle(HIDinfo)<>INVALID_HANDLE_VALUE) then
  begin
    DevCnt := 0;
    spdid.cbSize := SizeOf(spdid);
    while SetupDiEnumDeviceInterfaces(HidInfo, nil, HID_GUID, DevCnt, spdid) do
    begin
      dwSize := 0;
      SetupDiGetDeviceInterfaceDetailW(HIDinfo, @spdid, nil, 0, dwSize, nil);

      If (dwSize > 0) then
      begin
        GetMem(pSpDidd, dwSize);
        pSpDidd.cbSize := SizeOf(TSPDeviceInterfaceDetailDataW);
        spddd.cbSize    := SizeOf(spddd);
        If SetupDiGetDeviceInterfaceDetailW(HIDinfo, @spdid, pSpDidd, dwSize, dummy, @spddd) then
        begin
          ZeroMemory(@Info,SizeOf(THIDdeviceInfo));
          Info := GetHidDeviceInfo(@(pSpDidd^.DevicePath));
          Info.Handle := INVALID_HANDLE_VALUE;
          //Result := Info.SymLink;
          if (Info.VID = vid) and (Info.PID = pid) then
            Result := string(PChar(@(pSpDidd^.DevicePath)));
        end;
        FreeMem(pSpDidd);
      end;
      inc(DevCnt);
    end;
    SetupDiDestroyDeviceInfoList(HidInfo);
  end;
end;


Constructor THIDthread.Create;
begin
  inherited Create(False);
  //プライオリティは適宜調整
  Priority        := tpTimeCritical;
  FreeOnTerminate := True;
  FActiveDevice.Handle:=INVALID_HANDLE_VALUE;
end;

procedure THIDthread.HIDCloseDevice;
begin
  if FActiveDevice.Handle<>INVALID_HANDLE_VALUE then
  begin
    CloseHandle(ActiveDevice.Handle);
    FActiveDevice.Handle:=INVALID_HANDLE_VALUE;
  end;
end;

procedure THIDthread.HIDOpenDevice();
begin
  HIDCloseDevice;
  FActiveDevice.Handle := CreateFileW(
        PChar(ActiveDevice.SymLink),
        GENERIC_READ or GENERIC_WRITE or winapi.windows.SYNCHRONIZE,
        FILE_SHARE_READ or FILE_SHARE_WRITE,
        nil, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0
  );

  Synchronize(
  procedure
  begin
    if (FActiveDevice.Handle <> INVALID_HANDLE_VALUE) then
      Form1.memo1.lines.add(ActiveDevice.SymLink);
  end);
end;

function THIDthread.HIDReadDevice(var Data: THIDbuffer): Boolean;
var
  hEv   :THandle;
  HidOverlapped :TOverlapped;
  bResult       :DWord;
  BytesRead     :DWord;
  ReadBuf       :THIDreport;
begin
  Result := False;
  if (FActiveDevice.Handle <> INVALID_HANDLE_VALUE) then
  begin
    hEv := CreateEvent(nil, true, false, nil);
    HidOverlapped.hEvent    := hEv;
    HidOverlapped.Offset    := 0;
    HidOverlapped.OffsetHigh:= 0;
    ZeroMemory(@(ReadBuf.Data[0]),length(ReadBuf.Data));
    ReadFile(FActiveDevice.Handle, ReadBuf,
              FActiveDevice.BufferSize, BytesRead, @HidOverlapped);
    sleep(10);
    bResult:=WaitForSingleObject(hEv, 0);
    if (bResult = WAIT_TIMEOUT) or (bResult = WAIT_ABANDONED) then
    begin
      CancelIo(ActiveDevice.Handle);
      Result := False;
    end
    else
    begin
      GetOverlappedResult(FActiveDevice.Handle, HidOverlapped, BytesRead, False);
      Data := ReadBuf.Data;
      Result := True;
    end;
    CloseHandle(hEv);
  end;
{
  Synchronize(
  procedure
  begin
    if (bResult = WAIT_TIMEOUT) then
      Form1.memo1.lines.add('WAIT_TIMEOUT');
    if (bResult = WAIT_ABANDONED) then
      Form1.memo1.lines.add('WAIT_ABANDONED');
    Form1.memo1.lines.add(inttostr(BytesRead));
  end);
}
end;

procedure THIDthread.setActiveDevice(ADevice: THIDdeviceInfo);
begin
  HIDCloseDevice;
  FActiveDevice:=ADevice;
end;

destructor THIDthread.Destroy;
begin
  HIDCloseDevice;
  inherited;
end;

function THIDthread.send(data: string): integer;
var
  hEv   :THandle;
  HidOverlapped :TOverlapped;
  bResult       :DWord;
  BytesWrite :DWord;
  WriteBuf :THIDreport;
  BufferSize: word;
  i: integer;
begin
  result := -1;

  if (ActiveDevice.Handle <> INVALID_HANDLE_VALUE) then
  begin
    hEv := CreateEvent(nil, true, false, nil);
    HidOverlapped.hEvent    := hEv;
    HidOverlapped.Offset    := 0;
    HidOverlapped.OffsetHigh:= 0;
    ZeroMemory(@(WriteBuf.Data[0]),length(WriteBuf.Data));
    BufferSize := sizeof(THIDreport); // 65
    WriteBuf.ReportID := 0;
    for i := 0 to length(data) - 1 do
      WriteBuf.Data[i] := ord(data[i + 1]);
    WriteFile(ActiveDevice.Handle, WriteBuf, BufferSize, BytesWrite, @HidOverlapped);

    sleep(10);
    bResult:=WaitForSingleObject(hEv, 0);
    if (bResult = WAIT_TIMEOUT) or (bResult = WAIT_ABANDONED) then
    begin
      CancelIo(ActiveDevice.Handle);
      result := 0;
    end
    else
    begin
      GetOverlappedResult(ActiveDevice.Handle, HidOverlapped, BytesWrite, False);
      result := BytesWrite;
    end;
    CloseHandle(hEv);
  end;
end;

Procedure THIDthread.Execute;
var buf: THIDbuffer;
begin
  while not Terminated do
  begin
    If (FActiveDevice.Handle <> INVALID_HANDLE_VALUE) then
    begin
      If Assigned(HIDcallback) then
      begin
        ZeroMemory(@buf[0],SizeOf(buf));
        if HIDReadDevice(buf) then HIDcallback(buf) else
        Sleep(1);

      end
      else Sleep(10);
    end
    else Sleep(10);
  end;
  HIDCloseDevice;
end;

initialization
begin
  LoadHid();
  LoadSetupApi();
end;

finalization
begin
  UnloadHid;
  UnloadSetupApi;
end;

end.

