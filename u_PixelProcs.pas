unit u_PixelProcs;

interface

uses  System.Classes, System.UITypes, FMX.Types,FMX.Graphics, FMX.Colors,
      System.Generics.Collections,
      System.SyncObjs,
      FMX.uBitmapData;

  function ColorFToRGBStr(const aCL:TAlphaColorF; aStrFormat:Integer=0):string;
type
  /// <summary>
  ///   record for Event data -- TpsPostEvent
  /// </summary>
   TPxlPostRecord=record
     num,pathNum,threadNum:Integer;
     Sender:TObject;
     opSign:Integer;
     ProgressValue:Double;
     cValue:TAlphaColorF;
     FileName:string;
   public
     class function Create(aNum,aPathNum,aThNum:Integer; aSndr:TObject; AOperationSign:Integer;
                           aProgressVal:Double; aCurrValue:TAlphaColorF; const aFName:String): TPxlPostRecord; static; inline;
     function ValueToStr:string;
   end;
   /// <summary>
   ///      callback for one process
   /// </summary>
   TpsPostEvent=procedure(const pxlRec:TPxlPostRecord; var aContSign:integer) of object;
   TFMngrPostEvent=procedure(const aCNum,aCount:Integer) of object;
   /// <summary>
   ///      calc method
   /// </summary>
   TpxlCalcOperationProc=procedure(const aCompVal,aACL:TAlphaColorF; var aVal,aCount:TAlphaColorF);
   /// <summary>
   ///
   /// </summary>
   TpxlCalcResultProc=procedure(const aACL,aCount:TAlphaColorF; var aVal:TAlphaColorF);
   /// <summary>
   ///     calculate Image
   /// </summary>
function pxl_CalcValueFromBitmapData(aNum,aPathNum,aThNum:Integer; aSender:TObject; const aRYData:TRyuBitmapData; const aFileName:string;
                                   const aHomeVal:TAlphaColorF;
                                   ACalcProc:TpxlCalcOperationProc;
                                   AResProc:TpxlCalcResultProc;
                                 var aVal:TAlphaColorF;
                                 AEvent:TpsPostEvent;
                                 aAfterMapEvent:TNotifyEvent):Boolean;

type
  /// <summary>
  ///     событие для потока
  /// </summary>
  TpxlThreadEvent=procedure(aSndr:TObject; aNum:integer; const ATh:TThread) of object;
  /// <summary>
  ///    item for saving calc RGB data
  /// </summary>
   TRgbFileInfoObject=class(TPersistent)
    public
     Data:TPxlPostRecord;
     State:Integer;
     constructor Create(aNum,aPathNum:Integer; const aFileName:string);
     procedure Assign(Source: TPersistent); override;
     function Calc(aThNum:Integer; aSndrTh:TThread; AEvent:TpsPostEvent; AfterMapEvent:TNotifyEvent):Boolean;
   end;

 TrgbThread=Class(TThread)
    private
       FManager:TObject;
       FNum:Integer;
       Fpaused:Boolean;
       /// <summary>
       ///    флаг прерывания процесса расчета
       /// </summary>
       FBreakFlag:Boolean;
       /// <summary>
       ///    флаг выхода из потока (аналог terminat..)
       /// </summary>
       FExitFlag:Boolean;
       /// <summary>
       ///    флаг признака освобождения Execute вообще
       /// </summary>
       FFreeEnabled:Boolean;
       /// <summary>
       ///    флаг признака завершения расчета
       /// </summary>
       FCalcCompleted:Boolean;
       ///
       FPostEvent: TpsPostEvent;
       FBeforeCalcEvent,FAfterCalcEvent:TpxlThreadEvent;
       FInfoObject:TRgbFileInfoObject;
       function GetCalculated:Boolean;
       function GetEnabled:Boolean;
    protected
       procedure DoInnerPost(const pxlRec:TPxlPostRecord; var aContSign:integer);
       procedure DoAfterMapEvent(Sender:Tobject);
       procedure Execute; override;
    public
       constructor Create(aManager:TObject; aNum:Integer; const aPostEvent:TpsPostEvent; aBeforeCalcEvent,aAfterCalcEvent:TpxlThreadEvent);
       destructor Destroy; override;
       procedure StartCalculation(const aInfoObj:TRgbFileInfoObject);
       procedure ClearState;
       procedure BreakAndExit(aExitFlag:Boolean);
       function GetPxlRecord:TPxlPostRecord;
       function GetInfoObjNum:integer;
       property IsCalculated:Boolean read GetCalculated;
       property IsEnabled:boolean read GetEnabled;
       property IsPaused:Boolean read Fpaused write Fpaused;
       property CalcCompleted:Boolean read FCalcCompleted;
       property InfoObj:TRgbFileInfoObject read FInfoObject;
  end;

 TrgbEventsRec=record
    postEvent:TpsPostEvent;
    progressEvent:TFMngrPostEvent;
    exitEvent:TNotifyEvent;
    ///
    beforeCalcEvent:TpxlThreadEvent;
    afterCalcEvent:TpxlThreadEvent;
    procedure SetNull;
 end;

 TrgbFileManager=class(TComponent)
  private
    FCalcNum,FItemsCount:integer;
    FStopFlag:Boolean;
    FisExitFlag:Boolean;
    FResultColor:TAlphaColorF;
    ///
    FEvents:TrgbEventsRec;
    ///
    function GetClosed:boolean;
  protected
      /// <summary>
    ///   событие сразу перед началом расчета конкретного потока
    /// </summary>
    procedure DoBeforeCalc(aSndr:TObject; aNum:integer; const ATh:TThread);
    /// <summary>
    ///   событие сразу после завершения расчета для конкретного потока
    /// </summary>
    procedure DoAfterCalc(aSndr:TObject; aNum:integer; const ATh:TThread);
  public
    Items:TThreadList;
    Threads:TObjectList<TRgbThread>;
    /// <summary>
    ///    вычислить итоговый цвет
    /// </summary>
    function CalcAverageColor(apathNum:Integer):TAlphaColorF;
    ///
    constructor Create(AOwner:TComponent); override;
    procedure SetThParams(aCount: Integer; const aEvents:TrgbEventsRec);
    destructor Destroy; override;
    /// <summary>
    ///    функция проверки - true - если все потоки завершили вычисление
    /// </summary>
    function IsAllThreadsCalcCompleted:Boolean;
    /// <summary>
    ///    найти хотя бы 1 items - у которого вычисление НЕ проводилось в списке - иначе true
    /// </summary>
    function IsAllItemsCalculated:Boolean;
    /// <summary>
    ///    проверка освобождения потоков (при выходе из Execute) - true - только когда все выйдут
    /// </summary>
    function IsAllThreadsFreeEnabled:Boolean;
    procedure SetItemsData(const ADirs, AFiles:TStrings);
    procedure StartItems;
    procedure SetState(aPausedFlag:Boolean);
    procedure Stop(aExitThFlag:Boolean);
    property IsClosed: boolean read GetClosed;
    property ResultColor:TAlphaColorF read FResultColor;
    property CalcNumber:integer read FCalcNum;
    property ItemsCount:integer read FItemsCount;
 end;


var  CSA:TCriticalSection;

implementation

uses
 FMX.Forms,
{$IFDEF MSWINDOWS}
 Winapi.ActiveX,
{$ENDIF}
System.SysUtils;

 var ppEvent:TEvent;

function ColorFToRGBStr(const aCL:TAlphaColorF; aStrFormat:Integer=0):string;
 begin
  case aStrFormat of
    0: Result:=Format('R=%d,G=%d,B=%d,A=%d',[Round(aCL.R*255),
                                               Round(aCL.G*255),
                                               Round(aCL.B*255),
                                               Round(aCL.A*255)]);
   else Result:='';
  end;
 end;

///////////////////////////////////////////////////////////////////////////////
procedure pxl_CalcSum(const aCompVal,aACL:TAlphaColorF; var aVal,aCount:TAlphaColorF);
 begin
   aVal.R:=aACL.R+aCompVal.R;
   aVal.G:=aACL.G+aCompVal.G;
   aVal.B:=aACL.B+aCompVal.B;
   aVal.A:=aACL.A+aCompVal.A;
   aCount.R:=aCount.R+1;
 {  aCount.G:=aCount.G+1;
   aCount.B:=aCount.B+1;
   aCount.A:=aCount.A+1;
   }
 end;


procedure pxl_ResultAverage(const aACL,aCount:TAlphaColorF; var aVal:TAlphaColorF);
 begin
   aVal:=TAlphaColorF.Create(0,0,0,0);
   if aCount.R>0 then
    begin
     aVal.R:=aACL.R/aCount.R;
     aVal.G:=aACL.G/aCount.R;
     aVal.B:=aACL.B/aCount.R;
     aVal.A:=aACL.A/aCount.R;
    end;
 end;



function pxl_CalcValueFromBitmapData(aNum,aPathNum,aThNum:Integer; aSender:TObject; const aRYData:TRyuBitmapData; const aFileName:string;
                                   const aHomeVal:TAlphaColorF;
                                   ACalcProc:TpxlCalcOperationProc;
                                   AResProc:TpxlCalcResultProc;
                                 var aVal:TAlphaColorF;
                                 AEvent:TpsPostEvent;
                                 aAfterMapEvent:TNotifyEvent):Boolean;
var vPixelColor : TAlphaColorF;
    x,y,yMax,xMax:Integer;
    L_Sign,L_addingOper:Integer;
    L_Progress:Double;
    LCR,LCountCL,L_ResultCL:TAlphaColorF;
    ///
   // LRYData:TRyuBitmapData;
    ///
 begin
  Result:=false;
  aVal:=TAlphaColorF.Create(0,0,0,0);
  Assert(Assigned(ACalcProc),'pxl_CalcValueFromBitmap -> not Define Calc Proc!');
  Assert(Assigned(AResProc),'pxl_CalcValueFromBitmap -> not Define Result Proc!');
 // LRYData:=TRyuBitmapData.Create;
 // LRYData.AssignFromBitmap(ABM);
   if Assigned(aAfterMapEvent) then
      aAfterMapEvent(aSender);
   ///
   LCountCL:=TAlphaColorF.Create(0,0,0,0);
      LCR:=aHomeVal;
      yMax:=aRYData.height;
      xMax:=aRYData.width;
      y:=1;
      while y<=yMax do
       begin
        x:=1;
        while x<=xmax do
          begin
           vPixelColor:=TAlphaColorF.Create(aRYData.GetColor(x,y));
           if vPixelColor.R<1 then
              aRYData.SaveToFile('test.bmp');
           ACalcProc(vPixelColor,LCR,LCR,LCountCL);
           Inc(x);
          end;
        L_Sign:=1;
        if (Assigned(AEvent)) then
           begin
              AResProc(LCR,LCountCL,L_ResultCL);
              AEvent(TPxlPostRecord.Create(aNum,aPathNum,aThNum,aSender,1,y/yMax,L_ResultCL,aFileName),L_Sign);
           end;
        if L_Sign<0 then
           Break;
        ///
        if L_Sign>0 then
           Inc(y);
       end;
       ///
       Result:=(x=xMax+1) and (y=ymax+1) and (L_Sign>=0);
       AResProc(LCR,LCountCL,aVal);
       if (Result=true) then
         begin
           L_Sign:=1;
           L_addingOper:=2;
           L_Progress:=1.0;
         end
       else
         begin
          //L_Sign:=
          L_addingOper:=0;
          L_Progress:=0;
         end;
       /// immer
       if aVal.R<1 then
          L_Sign:=L_Sign;
       ///
       if (Assigned(AEvent)) then
          AEvent(TPxlPostRecord.Create(aNum,aPathNum,aThNum,aSender,L_addingOper,L_Progress,aVal,aFileName),L_Sign);
        ///
 end;


{ TRgbFileInfoRec }

procedure TRgbFileInfoObject.Assign(Source: TPersistent);
var LSrecRef:TRgbFileInfoObject;
begin
 // inherited;
 if Source is TRgbFileInfoObject then
  begin
    LSrecRef:=TRgbFileInfoObject(Source);
    Data:=LSrecRef.Data;
    State:=LSrecRef.State;
  end;
end;

function TRgbFileInfoObject.Calc(aThNum:Integer; aSndrTh:TThread; AEvent:TpsPostEvent; AfterMapEvent:TNotifyEvent):Boolean;
var LBM:TBitmap;
    LState:Integer;
    RBMData:TRyuBitmapData;
begin
 LState:=Self.State;
 Result:=false;
 if FileExists(Data.FileName)=true then
  begin
    try
     try
      LState:=1;
         {$IFDEF MSWINDOWS}
           // OleInitialize(nil);
           // CoInitializeEx(nil,COINIT_MULTITHREADED);
           //  CoInitialize(nil);
         {$ENDIF}
     // ppEvent.WaitFor(INFINITE);
      try
        ppEvent.WaitFor(INFINITE);
        RBMData:=TRyuBitmapData.Create;
       try
       //  CSA.Enter;
        // TThread.Synchronize(aSndrTh,procedure
        //   begin
            LBM:=TBitmap.CreateFromFile(Data.FileName);
            RBMData.AssignFromBitmap(LBM);
         // end);
       finally
         LBM.Free;
        ppEvent.SetEvent;
        // CSA.Leave;
         {$IFDEF MSWINDOWS}
         //  CoUninitialize;
          // OleUninitialize;
         {$ENDIF}
       end;
     // ppEvent.SetEvent;
      ///
        Result:=pxl_CalcValueFromBitmapData(Data.Num,Data.pathNum,aThNum,Self,
                              RBMData,
                              Data.FileName,
                              TAlphaColorF.Create(0,0,0,0),
                              pxl_CalcSum,
                              pxl_ResultAverage,
                              Data.cValue,
                              AEvent,AfterMapEvent);
       finally
        RBMData.Free;
      end;
      finally
       if Result then
          LState:=3
       else
          LState:=2;
       ///
      end;
     except
       LState:=2;
     end;
  end
 else
  begin
   LState:=2;
  end;
  Self.State:=LState;
{ if Self.State<2 then
    LState:=Self.State;
    }
end;

constructor TRgbFileInfoObject.Create(aNum,aPathNum:Integer; const aFileName: string);
begin
  inherited Create;
  State:=0;
  Data:=TPxlPostRecord.Create(aNum,aPathNum,-1,nil,0,0,TAlphaColorF.Create(0,0,0,0),aFileName);
end;

{ TPxlPostRecord }

class function TPxlPostRecord.Create(aNum,aPathNum,aThNum:Integer; aSndr:TObject; AOperationSign:Integer;
                           aProgressVal:Double; aCurrValue:TAlphaColorF; const aFName:String): TPxlPostRecord;
begin
 with Result do
  begin
    num:=aNum;
    pathNum:=aPathNum;
    threadNum:=aThNum;
    Sender:=aSndr;
    opSign:=AOperationSign;
    ProgressValue:=aProgressVal;
    cValue:=aCurrValue;
    FileName:=aFName;
  end;
end;

function TPxlPostRecord.ValueToStr: string;
begin
  Result:=ColorFToRGBStr(cValue,0);
end;

{ TrgbFilemanager }

function TrgbFileManager.IsAllThreadsFreeEnabled: Boolean;
var I:Integer;
begin
  Result:=true;
  i:=0;
  while i<Threads.Count do
    begin
      if Threads.Items[i].FFreeEnabled=false then
         begin
           Result:=false;
           break;
         end;
      Inc(i);
    end;
end;

function TrgbFileManager.IsAllItemsCalculated: Boolean;
  var LLIst:TList;
    i:Integer;
    LExistsFlag:Boolean;
    LObj:TRgbFileInfoObject;
begin
  Result:=false;
  LExistsFlag:=false;
  LLIst:=Items.LockList;
  try
   i:=0;
   while i<LLIst.Count do
     begin
       LObj:=TRgbFileInfoObject(LList.Items[i]);
       if LObj.State<=1 then // смотрим статус объекта
         begin  // объект неподготовлен
           LExistsFlag:=true;
           break;
         end;
       Inc(i);
     end;
 finally
  Items.UnlockList;
 end;
 Result:=(Not(LExistsFlag));
end;

function TrgbFileManager.IsAllThreadsCalcCompleted: Boolean;
var I:Integer;
begin
  Result:=true;
  i:=0;
  while i<Threads.Count do
    begin
      if Threads.Items[i].CalcCompleted=false then
         begin
           Result:=false;
           break;
         end;
      Inc(i);
    end;
end;

function TrgbFileManager.CalcAverageColor(apathNum:Integer): TAlphaColorF;
var LLIst:TList;
    i,j:Integer;
    LObj:TRgbFileInfoObject;
    LSum:TAlphaColorF;
    LS:string;
begin
  LSum:=TAlphaColorF.Create(0,0,0,0);
  Result:=LSum;
  LLIst:=Items.LockList;
  try
   i:=0; j:=0;
   while i<LLIst.Count do
     begin
       LObj:=TRgbFileInfoObject(LList.Items[i]);
       LS:=Lobj.Data.ValueToStr;
       if (Lobj.State>1) and
          ((apathNum=-1) or (Lobj.Data.pathNum=apathNum)) then
         begin
           LSum.R:=LSum.R+LObj.Data.cValue.R;
           LSum.G:=LSum.G+LObj.Data.cValue.G;
           LSum.B:=LSum.B+LObj.Data.cValue.B;
           LSum.A:=LSum.A+LObj.Data.cValue.A;
           Inc(j);
         end;
       Inc(i);
     end;
   if j>0 then
     begin
      Result.R:=LSum.R/j;
      Result.G:=LSum.G/j;
      Result.B:=LSum.B/j;
      Result.A:=LSum.A/j;
     end;
   ///
 finally
  Items.UnlockList;
 end;

end;

constructor TrgbFilemanager.Create(AOwner: TComponent);
begin
  inherited;
  FCalcNum:=0;
  FItemsCount:=0;
  FEvents.SetNull;
  FResultColor:=TAlphaColorF.Create(0,0,0,0);
  FisExitFlag:=false;
  FStopFlag:=false;
  Threads:=TObjectList<TRgbThread>.Create(true);
  Items:=TThreadList.Create;
end;

destructor TrgbFilemanager.Destroy;
var LLIst:TList;
    i:Integer;
    LObj:TRgbFileInfoObject;
begin
  FisExitFlag:=true;
  Threads.Free;
  LLIst:=Items.LockList;
  try
   i:=0;
   while i<LLIst.Count do
     begin
       LObj:=TRgbFileInfoObject(LList.Items[i]);
       Lobj.Free;
       Inc(i);
     end;
   LLIst.Clear;
 finally
  Items.UnlockList;
 end;
  FreeAndNil(Items);
  FEvents.SetNull;
  inherited;
end;

procedure TrgbFileManager.DoAfterCalc(aSndr:TObject; aNum:integer; const ATh:TThread);
var LLIst:TList;
    i:Integer;
    LObj,LThObjRef:TRgbFileInfoObject;
    LTh:TrgbThread;
    LFlag:Boolean;
    LS:string;
begin
  ppEvent.WaitFor(INFINITE);
  LTh:=TrgbThread(ATh);
  LThObjRef:=LTh.InfoObj;
  ///
  LLIst:=Items.LockList;
  try
   LFlag:=false;
   i:=0;
   while i<LLIst.Count do
     begin
       LObj:=TRgbFileInfoObject(LList.Items[i]);
       if Lobj.Data.num=LThObjRef.Data.num then
         begin
           LObj.Assign(LThObjRef); // !
          { Lobj.State:=LThObjRef.State;
           if Lobj.State<2 then
              LFlag:=true;
              }
          // LS:=LObj.Data.ValueToStr;
           break;
         end;
       Inc(i);
     end;
 finally
  Items.UnlockList;
 end;
 FCalcNum:=FCalcNum+1; // !
    TThread.Synchronize(nil,
     procedure
      begin
        FEvents.afterCalcEvent(Self,aNum,aTh);
      end);
 ppEvent.SetEvent;
end;

procedure TrgbFileManager.DoBeforeCalc(aSndr: TObject; aNum: integer;
  const ATh: TThread);
var LLIst:TList;
    i:Integer;
    LObj,LThObjRef:TRgbFileInfoObject;
    LTh:TrgbThread;
begin
 { LTh:=TrgbThread(ATh);
  LThObjRef:=LTh.InfoObj;
  }
 // LThObjRef.Data.threadNum:=aNum;
  ///
 if Assigned(FEvents.beforeCalcEvent) then
  try
    ppEvent.WaitFor(INFINITE);
    TThread.Synchronize(nil,
     procedure
      begin
        FEvents.beforeCalcEvent(Self,aNum,aTh);
      end);
   finally
    ppEvent.SetEvent;
  end;
 ///
end;

function TrgbFileManager.GetClosed: boolean;
var i:Integer;
begin
 Result:=false;
 if Threads.Count<=0 then Result:=true
 else
  begin
    i:=0;
    while i<Threads.Count do
     begin
       if Threads.Items[i].Terminated then
          begin
            Result:=true;
            break;
          end;
       Inc(i);
     end;
  end;
end;

procedure TrgbFileManager.SetItemsData(const ADirs, AFiles: TStrings);
var i,j:integer;
   LList:TList;
   LS:string;
   LObj:TRgbFileInfoObject;
      function L_IndexOfPath(const AFileName:string):Integer;
      var LLS:string;
        begin
          Result:=-1;
          LLS:=ExtractFileDir(AFileName);
          if (LLS<>'') and (LLS<>PathDelim) then
             Result:=ADirs.IndexOf(LLS);
        end;
begin
 LLIst:=Items.LockList;
 try
   i:=0;
   while i<LLIst.Count do
     begin
       LObj:=TRgbFileInfoObject(LList.Items[i]);
       Lobj.Free;
       Inc(i);
     end;
   LLIst.Clear;
   i:=0;
   while i<AFiles.Count do
     begin
       LS:=AFiles.Strings[i];
       j:=L_IndexOfPath(LS);
       if j>=0 then
        begin
         LObj:=TRgbFileInfoObject.Create(i,j,LS);
         LList.Add(Lobj);
        end;
       Inc(i);
     end;
  FItemsCount:=LList.Count; // !
 finally
  Items.UnlockList;
 end;
end;

procedure TrgbFileManager.SetState(aPausedFlag: Boolean);
var I:Integer;
begin
  I:=0;
  while I<Threads.Count do
    begin
      Threads.Items[i].IsPaused:=aPausedFlag;
      Inc(i);
    end;
end;

procedure TrgbFileManager.SetThParams(aCount: Integer; const aEvents:TrgbEventsRec);
var i:Integer;
    LTh:TRgbThread;
begin
  Threads.Clear;
  FEvents:=aEvents;
  for I :=0 to aCount-1 do
    begin
      LTh:=TRgbThread.Create(Self,i,FEvents.PostEvent,DoBeforeCalc,DoAfterCalc);
      Threads.Add(LTh);
    end;
end;

procedure TrgbFileManager.StartItems;
var L_List:TList;
    L_Count,iLL:Integer;
begin
  FCalcNum:=0;
  FisExitFlag:=false;
  FStopFlag:=false;
  iLL:=0;
  while iLL<Threads.Count do
   begin
     Threads.Items[iLL].ClearState;
     Inc(iLL);
   end;
  L_List:=Items.LockList;
  try
    L_Count:=L_List.Count;
    finally
    Items.UnlockList;
  end;
  iLL:=L_Count;
  ///
  TThread.CreateAnonymousThread(
   procedure
    var i,j:Integer;
    L_FullFlag,LStopFlag:Boolean;
    LInfo:TRgbFileInfoObject;
    LList:TList;
    L_IdleInterval:Integer;
     begin
        LStopFlag:=false;
        j:=0;
        while (LStopFlag=false) do
         begin
           L_FullFlag:=True;
           I:=0;
          /// только если есть свободные items - их раздать по потокам
          if (J<L_Count) then
           while (i<Threads.Count) and (j<L_Count) and (LStopFlag=false) do
            begin
             if Threads.Items[i].IsEnabled=true then
              begin
                LList:=Items.LockList;
                try
                   LInfo:=TRgbFileInfoObject(LList.Items[j]);
                   Threads.Items[i].StartCalculation(LInfo);
                  finally
                 Items.UnlockList;
                 end;
                L_FullFlag:=False;
                Inc(j);
              end;
            Inc(i);
            end;
           L_IdleInterval:=0;
           if (L_FullFlag) and (LStopFlag=false) and (Self.IsClosed=false) then
              L_IdleInterval:=90;
           if (Assigned(FEvents.progressEvent)) then
              try
               { TThread.Synchronize(Tthread.CurrentThread,procedure
                   begin
                     FEvents.progressEvent(j,L_Count);
                     i:=0;
                   end);
                   }
                if L_IdleInterval>0 then
                        TThread.Sleep(L_IdleInterval);
               finally
              end
             else
              begin
               if LStopFlag=false then
                  Sleep(L_IdleInterval);
               //нужно Application.ProcessMessages;
              end;
          LStopFlag:=FStopFlag;
         ///
         ///  условие полной отработки
         if LStopFlag=false then
            LStopFlag:=(IsAllThreadsCalcCompleted=true) and (IsAllItemsCalculated=true);
        end;
     FIsExitFlag:=true; // ! set
    // if FStopFlag=false then
     FResultColor:=CalcAverageColor(-1);
     if (Assigned(FEvents.exitEvent)) then
         try
           // CSA.Enter;
            TThread.Synchronize(Tthread.CurrentThread,procedure
                   begin
                     FEvents.exitEvent(Self);
                   end);
           finally
           // CSA.Leave;
         end;
    // i:=0;
     end).Start;
end;

procedure TrgbFileManager.Stop(aExitThFlag:Boolean);
 var I:Integer;
begin
  i:=0;
  FStopFlag:=true;
 // CSA.Enter;
  while I<Threads.Count do
    begin
      Threads.Items[i].BreakAndExit(aExitThFlag);
      Inc(i);
    end;
 // CSA.Exit;
end;

{ TrgbThread }

procedure TrgbThread.BreakAndExit(aExitFlag:Boolean);
begin
 FBreakFlag:=true;
 if aExitFlag then
    FExitFlag:=true;
end;

procedure TrgbThread.ClearState;
begin
 // FExitFlag:=false;
 FBreakFlag:=false;
 FFreeEnabled:=false;
 Fpaused:=false;
// FInfoObject.ColorData:=TAlphaColorF.Create(0,0,0);
 FInfoObject.State:=-1;
end;

constructor TrgbThread.Create(aManager:TObject; aNum:Integer; const aPostEvent:TpsPostEvent; aBeforeCalcEvent,aAfterCalcEvent:TpxlThreadEvent);
begin
  inherited Create(True);
  FManager:=aManager;
  FExitFlag:=false;
  FBreakFlag:=false;
  FFreeEnabled:=false;
  Fpaused:=false;
  FCalcCompleted:=true;
  FNum:=aNum;
  FPostEvent:=aPostEvent;
  FreeOnTerminate :=False;
  Priority:=tpNormal; // !~
  FInfoObject:=TRgbFileInfoObject.Create(-1*aNum,-1,'');
  FInfoObject.State:=-1;  // !
  FBeforeCalcEvent:=aBeforeCalcEvent;
  FAfterCalcEvent:=aAfterCalcEvent;
  Self.Resume;
end;

destructor TrgbThread.Destroy;
begin
  FInfoObject.Free;
  inherited;
end;

procedure TrgbThread.DoAfterMapEvent(Sender: Tobject);
begin
 // CoUninitialize;
end;

procedure TrgbThread.DoInnerPost(const pxlRec: TPxlPostRecord;
  var aContSign:integer);
 var L_BrSign:Integer;
     L_pxlRec:TPxlPostRecord;
begin
  if (Assigned(FPostEvent)) and (FExitFlag=false) then
   begin
    // Self.Sleep(1);
     FInfoObject.Data:=pxlRec;
     L_pxlRec:=pxlRec;
    // это внутри Calc FInfoObject.State:=pxlRec.opSign
     ///
     L_BrSign:=aContSign; // !
         if (L_BrSign=1) and (Fpaused) then
            L_BrSign:=0
         else
             if (L_BrSign=0) and (Fpaused=false) then
                 L_BrSign:=1
             else
                if FBreakFlag then
                   L_BrSign:=-1;
     ///
      if Assigned(FPostEvent) then
          try
           ppEvent.WaitFor;
         //  CSA.Acquire;
           Synchronize(procedure
            begin
             FPostEvent(L_pxlRec,L_BrSign);
            end);
          finally
          // CSA.Leave;
           ppEvent.SetEvent;
          end;
     //  ppEvent.SetEvent;
    // CSA.Release;
        // FInfoObject.Data:=L_pxlRec;
     if L_BrSign<0 then
       begin
         FInfoObject.State:=2;
         FBreakFlag:=true;
         if L_BrSign<=-10 then
            FExitFlag:=true;  // !
       end
     else
        if (L_BrSign=0) and (FBreakFlag=false) then
           Self.Sleep(70); // for pause
     aContSign:=L_BrSign;
   end;
end;

procedure TrgbThread.Execute;
var LRes:boolean;
    i:Integer;
begin
  while (Not(Terminated)) and (FExitFlag=false) do
   begin
     if (FInfoObject.State=0) and (FBreakFlag=false) then
      try
      { CoInitializeEx(nil, COINIT_MULTITHREADED);
        OleInitialize(nil);
        CoInitialize(nil);
        }
        FCalcCompleted:=false;
       if Assigned(FBeforeCalcEvent) then
             FBeforeCalcEvent(FManager,Fnum,Self);
         LRes:=FInfoObject.Calc(FNum,Self,DoInnerPost,DoAfterMapEvent); // вычисление тут
        ///
        if Assigned(FAfterCalcEvent) then
           FAfterCalcEvent(FManager,Fnum,Self);
        { Нельзя - т.к. некорректно назначается:  Self.Synchronize(procedure
          begin
            FAfterCalcEvent(Self); // TThreadList in Items
          end);
          }
      finally
       FCalcCompleted:=true; // !
      { CoUninitialize;
       OleUninitialize;
       }
      end
     else
       begin
        ///
        if (FExitFlag=false) then
         begin
            Application.ProcessMessages;
            Sleep(70);  // for break state
         end;
       end;
   end;
  FBeforeCalcEvent:=nil;
  FAfterCalcEvent:=nil;
  FFreeEnabled:=true;
end;

function TrgbThread.GetCalculated: Boolean;
begin
 Result:=(FInfoObject.State=1);
end;

function TrgbThread.GetEnabled: Boolean;
begin
 Result:=(FExitFlag=false) and (FInfoObject.State<>1) and (FInfoObject.State<>0);
end;

function TrgbThread.GetInfoObjNum: integer;
begin
 Result:=FInfoObject.Data.num;
end;

function TrgbThread.GetPxlRecord: TPxlPostRecord;
begin
 Result:=FInfoObject.Data;
end;

procedure TrgbThread.StartCalculation(const aInfoObj: TRgbFileInfoObject);
begin
 // Synchronize(Self,procedure begin
 ppEvent.waitfor(infinite);
  FInfoObject.Assign(aInfoObj);
  FInfoObject.State:=0;
 ppEvent.SetEvent;
 //             end);
end;


{ TrgbEventsRec }

procedure TrgbEventsRec.SetNull;
begin
    postEvent:=nil;
    progressEvent:=nil;
    exitEvent:=nil;
    beforeCalcEvent:=nil;
    afterCalcEvent:=nil;
end;

initialization
 //  OleInitialize(nil);
  ppEvent:=Tevent.create(nil,false,true,'');
 // CSA:=TCriticalSection.Create;
finalization
  // OleUninitialize;
  ppEvent.Free;
//  CSA.Free;
end.
