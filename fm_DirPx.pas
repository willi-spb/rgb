unit fm_DirPx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.ListBox, FMX.Controls.Presentation, FMX.StdCtrls, System.Actions,
  FMX.ActnList, u_PixelProcs, u_ExtFilesProcs, FMX.Objects;

type
  TDirPxForm = class(TForm)
    ActionList1: TActionList;
    aAddDir: TAction;
    btn1: TButton;
    lst_Dirs: TListBox;
    aFindFiles: TAction;
    btn2: TButton;
    lst_Files: TListBox;
    pnl_PFiles: TPanel;
    lbl_pFiles: TLabel;
    pbFiles: TProgressBar;
    lbl_pFilesPercent: TLabel;
    aCalc: TAction;
    btn3: TButton;
    VertScrollBox1: TVertScrollBox;
    pnl0: TPanel;
    lbl_rInfo: TLabel;
    pbR: TProgressBar;
    lbl_rPercent: TLabel;
    btn4: TButton;
    aPause: TAction;
    btn5: TButton;
    aResume: TAction;
    btn6: TButton;
    btn7: TButton;
    aStop: TAction;
    aCreateSeq: TAction;
    rectR: TRectangle;
    btn8: TButton;
    Rect_Result: TRectangle;
    Button1: TButton;
    aClearDirs: TAction;
    lbl_Res: TLabel;
    lst_Log: TListBox;
    lbl_rColor: TLabel;
    VertScrollBox_path: TVertScrollBox;
    pnlPathS: TPanel;
    lbl_pathName: TLabel;
    rct_PathColor: TRectangle;
    lbl_PathColor: TLabel;
    btn9: TCornerButton;
    actStartCycle: TAction;
    tmr1: TTimer;
    btn10: TButton;
    tmrRenew: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure aAddDirExecute(Sender: TObject);
    procedure aFindFilesExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure aCalcExecute(Sender: TObject);
    procedure btn4Click(Sender: TObject);
    procedure aPauseExecute(Sender: TObject);
    procedure aResumeExecute(Sender: TObject);
    procedure aStopExecute(Sender: TObject);
    procedure aCreateSeqExecute(Sender: TObject);
    procedure aClearDirsUpdate(Sender: TObject);
    procedure aClearDirsExecute(Sender: TObject);
    procedure btn9Click(Sender: TObject);
    procedure actStartCycleExecute(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure btn10Click(Sender: TObject);
    procedure tmrRenewTimer(Sender: TObject);
  private
    { Private declarations }
    f_CloseFlag,f_FreeFlag:Boolean;
    f_FilesExt:string;
    f_Dirs:TStrings;
    f_Files:TFileDataList;
    /// кол-во потоков
    f_ThCount:Integer;
    f_FilesTmpFileName:string;
    FRepeatFlag:Boolean;
    /// <summary>
    ///    показать - скрыть прогресс заполнени€ файлов
    /// </summary>
    procedure SetFillFilesProgressState(aState,aClearFiles:boolean);
    /// <summary>
    ///    заполнить параметры панели процесса вычислений
    /// </summary>
    procedure SetPxData(aPnl:TPanel; const pxlRec:TPxlPostRecord);
    ///

    /// <summary>
    ///    очистка всех панелей из бокса-прокрутки кроме нулевой (образца) - она в hide
    /// </summary>
    procedure ClearPxPanels(clearLogFlag:Boolean);
    /// <summary>
    ///    обновить только потоки
    /// </summary>
    function UpdatePxThreadData:Boolean;
    ///
    ///filesProcessEvents:  - событи€ по файлам
    procedure DoFP_Post(aRg,aItemNum,aPathNum:Integer; aSuccessFlag:Boolean;
                          const aPath:string; const ASRec:TSearchRec; var aBreakSign:integer);
    procedure DoFP_State(aResultSign:integer);
    ///
    /// событи€ вычислени€
    /// <summary>
    ///    после каждого прохода строки в файле - рекоменд. использовать только дл€ прерывани€ по флагу и показю прогресс
    /// </summary>
    procedure DoPX_Post(const pxlRec:TPxlPostRecord; var aContSign:integer);
    /// <summary>
    ///    по выходу из цикла расчета
    /// </summary>
    procedure DoPx_Exit(Sender: TObject);
    /// <summary>
    ///    перед началом каждого нового
    /// </summary>
    procedure DoPx_BeforeCalc(aSndr:TObject; aNum:integer; const ATh:TThread);
    procedure DoPx_AfterCalc(aSndr:TObject; aNum:integer; const ATh:TThread);

  protected
    /// показ найденных файлов и заполнение списка с прогрессом
    procedure FillFileNames;
  public
    { Public declarations }
    rgbMnr:TrgbFileManager;
  end;

var
  DirPxForm: TDirPxForm;

implementation

{$R *.fmx}

uses FMX.uBitmapData;

/// adding funcs
function GetControlInParent(aPar:TControl; aClass:TClass; aTag:integer):TControl;
 var i:Integer;
 begin
    Result:=nil;
  i:=0;
  while i<apar.ControlsCount do
    begin
      if aPar.Controls[i].ClassType=aClass then
       if (aTag=aPar.Controls[i].Tag) then
        begin
          Result:=aPar.Controls[i];
          break;
        end;
      Inc(i);
    end;
 end;

 function GetControlCountInParent(aPar:TControl; aClass:TClass; onlyNotNullTag:Boolean=false):Integer;
 var i:Integer;
 begin
  Result:=0;
  i:=0;
  while i<apar.ControlsCount do
    begin
      if (aPar.Controls[i].ClassType=aClass) then
       if (onlyNotNullTag=false) or (aPar.Controls[i].Tag>0) then
        Result:=result+1;
      Inc(i);
    end;
 end;




///  добавление панели прогресса (1) или панели отчета по папкам (2)
function AddPP_Panel(aNum:Integer; const aPanName:string; const aPnl:TPanel; const aPar:TControl; aX,aY:Single; aCl:TAlphaColor):TPanel;
var LC:TComponent;
    LPnl:TPanel;
begin
  Result:=nil;
  LPnl:=aPnl.Clone(aPnl.Owner) as TPanel;
  LPnl.Name:=aPanName+IntToStr(aNum);
  LPnl.Position.X:=aX;
  LPnl.Position.Y:=aY;
  LPnl.Parent:=aPar;
  LPnl.Tag:=aNum; // !
  for LC in LPnl do
      begin
         if (LC is TLabel) and (LC.Tag=1) then
             TLabel(LC).Text:=''
         else
          if (LC is TProgressBar) then
               TProgressBar(LC).Value:=0
          else
           if LC is TRectangle then
            begin
              TRectangle(LC).Fill.Kind:=TBrushKind.Solid;
              TRectangle(LC).Fill.Color:=aCl;
            end;
      end;
   Result:=LPnl; // !
end;


procedure TDirPxForm.aAddDirExecute(Sender: TObject);
var LS,LDS:string;
begin
{ if SelectDirectory('ƒобавить каталог к поиску',Self.Handle,LS) then
    if f_Dirs.IndexOf(LS)<0 then
       begin
        f_Dirs.Add(LS);
        lst_Dirs.Items.Insert(0,LS);
       end;
  }
  LS:='';
  LDS:=ExtractFileDir(ParamStr(0));
  if SelectDirectory('ƒобавить каталог к поиску',LDS,LS) then
   if f_Dirs.IndexOf(LS)<0 then
       begin
        f_Dirs.Add(LS);
        lst_Dirs.Items.Insert(0,LS);
       end;
end;

procedure TDirPxForm.aCalcExecute(Sender: TObject);
begin
  Rect_Result.Visible:=false;
  lbl_Res.Text:='';
  ClearPxPanels(true);
  Application.ProcessMessages;
  ///
  rgbMnr.SetItemsData(f_Dirs,f_Files.Names);
  rgbMnr.StartItems;
  tmrRenew.Enabled:=true;
  f_FreeFlag:=false; // !
  SetFillFilesProgressState(true,false);
end;

procedure TDirPxForm.aClearDirsExecute(Sender: TObject);
begin
  f_Dirs.Clear;
  lst_Dirs.Items.Clear;
end;

procedure TDirPxForm.aClearDirsUpdate(Sender: TObject);
begin
  Taction(sender).Enabled:=(lst_Dirs.Items.Count>0);
end;

procedure TDirPxForm.aCreateSeqExecute(Sender: TObject);
var LFilename,Lname,Lpath,LExt:string;
    LFS:TMemoryStream;
    i,L_Max:Integer;
begin
 // LFilename:='D:\Execute\Work_temp\rgbProj\test_images\test_red\testR.png';
  LFilename:='D:\Execute\Work_temp\rgbProj\test_images\test_blue\testB.jpg';
  L_Max:=99;
  LPath:=ExtractFilePath(LFilename);
  Lname:=ExtractFileName(LFilename);
  LExt:=ExtractFileExt(LFilename);
  Lname:=StringReplace(Lname,LExt,'',[]);
  if FileExists(LFilename) then
   begin
     LFs:=TMemoryStream.Create;
     try
       LFs.LoadFromFile(LFilename);
       for I:=0 to L_Max do
         LFs.SaveToFile(Lpath+LName+IntToStr(i)+Lext);
     finally
       LFs.Free;
     end;
   end;
end;

procedure TDirPxForm.actStartCycleExecute(Sender: TObject);
begin
 FRepeatFlag:=true;
 tmr1.Enabled:=true;
end;

{
function TDirPxForm.AddOrSetPathPxPanel(const pxlRec:TPxlPostRecord):Boolean;
 var LPnl:TPanel;
     i:Integer;
     LbInfo,LbColor:TLabel;
     LClRect:TRectangle;
     L_Color:TAlphaColorF;
begin
 Result:=false;
 LPnl:=TPanel(GetControlInParent(VertScrollBox_path.Content,TPanel,pxlRec.pathNum));
 if (LPnl=nil) then
    begin
      // i:=GetControlCountInParent(VertScrollBox_path.Content,TPanel);
      LPnl:=AddPP_Panel(pxlRec.pathNum,'pnlPath',pnlPathS,VertScrollBox_path.Content,
                                                 VertScrollBox_path.Content.Position.X,
                                                 VertScrollBox_path.Content.Position.Y+(pnlPathS.Height+2)*pxlRec.pathNum,
                                                 pxlRec.cValue.ToAlphaColor);
      LPnl.Visible:=true;
      Result:=true;
    end;
 if Assigned(LPnl) then
    begin
      ///по завершении
      if pxlRec.opSign<>1 then
       begin
         /// ошибка или прерывание
         if pxlRec.opSign=0 then
            begin
            end;
         ///
         Lbinfo:=Tlabel(GetControlInParent(LPnl,TLabel,10));
         LbColor:=Tlabel(GetControlInParent(LPnl,TLabel,20));
         LClRect:=Trectangle(GetControlInParent(LPnl,TRectangle,1));
         if (Assigned(LbInfo)) and (pxlRec.pathNum<f_Dirs.Count) then
            LbInfo.Text:=f_Dirs.Strings[pxlRec.pathNum];
         L_Color:=rgbMnr.CalcAverageColor(pxlRec.pathNum);
         if Assigned(LClRect) then
             LclRect.Fill.Color:=L_Color.ToAlphaColor;
         if Assigned(lbColor) then
            LbColor.Text:=ColorFToRGBStr(L_Color,0);
         ///
         Result:=true;
       end;
    end;
 end;
 }

procedure TDirPxForm.aFindFilesExecute(Sender: TObject);
var LRec:TFindFilesEventRec;
begin
// LRec.ffOnTerminate:=DoFP_Terminate; // !
 LRec.ffPostEvent:=DoFP_Post;
 LRec.ffErrorEvent:=DoFP_Post;
 LRec.ffBeforeEvent:=DoFP_State;
 LRec.ffAfterEvent:=DoFP_State;
 ///
 lst_Files.Items.Clear;
 f_Files.ClearAll;
 trFindFilesInPlaces(f_Dirs,f_FilesExt,LRec);
end;



procedure TDirPxForm.aPauseExecute(Sender: TObject);
begin
 rgbMnr.SetState(true);
end;

procedure TDirPxForm.aResumeExecute(Sender: TObject);
begin
 rgbMnr.SetState(false);
end;

procedure TDirPxForm.aStopExecute(Sender: TObject);
begin
 FRepeatFlag:=true;
 tmr1.Enabled:=false;
 Application.ProcessMessages;
 rgbMnr.Stop(false);
 SetFillFilesProgressState(false,false);
end;

procedure TDirPxForm.btn10Click(Sender: TObject);
var LRYData:TRyuBitmapData;
    LFileBM,LBM:TBitmap;
    LMemStream:TMemoryStream;
    LRec:TalphaColorRec;
begin
  LRYData:=TRyuBitmapData.Create;
  LFileBM:=TBitmap.CreateFromFile('D:\Execute\Work_temp\rgbProj\test_images\test_red\testR1.png');
 // LFileBM:=TBitmap.CreateFromFile('D:\Execute\Work_temp\rgbProj\test_images\test_Green\gr1.bmp');
  try
   LRYData.AssignFromBitmap(LFileBM);
  // LRYData.GetRGBA(1,1,R,G,B,A);
   LRec.Color:=LRYData.GetColor(2,2);
   LRYData.SaveToFile('testWW1.png');
//   LRYData.GetToBitmap(LBM);
 //  LBM.SaveToFile('D:\Execute\Work_temp\rgbProj\test_images\gr_RESULT.png');
  finally
    LRYData.Free;
    LFileBM.Free;
  end;
end;

procedure TDirPxForm.btn4Click(Sender: TObject);
begin
 f_Files.SaveNamesToFile(f_FilesTmpFileName);
end;

procedure TDirPxForm.btn9Click(Sender: TObject);
var i:Integer;
    LList:TList;
    LRObj:TRgbFileInfoObject;
begin
  i:=0;
  LLIst:=rgbMnr.Items.LockList;
  while i<LList.Count do
   begin
     LList.Items[i];
     LRObj:=TRgbFileInfoObject(LList.Items[i]);
     if LRObj.State<2 then
      begin
        tag:=0;
      end;
     Inc(i);
   end;
end;

procedure TDirPxForm.ClearPxPanels(clearLogFlag:Boolean);
 var i,j:Integer;
begin
 i:=0;
 while i<VertScrollBox1.Content.ControlsCount do
  begin
    j:=0;
    if VertScrollBox1.Content.Controls[i] is TPanel then
     begin
       j:=VertScrollBox1.Content.Controls[i].Tag;
       if j>0 then
         VertScrollBox1.Content.Controls[i].Free
       else
          VertScrollBox1.Content.Controls[i].Visible:=false;
     end;
    if j<=0 then
       Inc(i);
  end;
 if clearLogFlag then
     lst_Log.Items.Clear;
end;

procedure TDirPxForm.DoFP_Post(aRg,aItemNum,aPathNum: Integer; aSuccessFlag:Boolean; const aPath: string;
  const ASRec:TSearchRec; var aBreakSign:integer);
var LFileDesc:string;
    i:Integer;
    L_Pr:Double;
begin
 if f_CloseFlag=true then
   begin
    aBreakSign:=2;
    f_FreeFlag:=True;
   end
 else
  case aRg of
  1: // post
     begin
       if aSuccessFlag then
        begin
         f_Files.AddData(1,aItemNum,aPathNum, aPath,ASRec);
        end;
     end;
  2:  begin
      { if MessageDlg('ќшибка при обращении к файлу: '+#13#10+
                  LFileDesc+#13#10+'ѕродолжить?',TMsgDlgType.mtError,[TMsgDlgBtn.mbYes,TMsgDlgBtn.mbNo],0)=6 then
         begin  }
           aBreakSign:=1;
          // pnl_PFiles.Visible:=False;
       //  end;
     end;
  end;
end;

procedure TDirPxForm.DoFP_State(aResultSign: integer);
begin
  case aResultSign of
    0: begin
         f_FreeFlag:=False;
       end;
    3: begin
         f_FreeFlag:=True;
         FillFileNames;
       end;
  end;
end;

procedure TDirPxForm.DoPx_AfterCalc(aSndr: TObject; aNum: integer;
  const ATh: TThread);
var LPnl:Tpanel;
    LNum,LCount:integer;
    LP:Single;
begin
 LNum:=TrgbThread(ATh).GetInfoObjNum;
 LCount:=GetControlCountInParent(VertScrollBox1.Content,TPanel);
 LPnl:=TPanel(GetControlInParent(VertScrollBox1.Content,TPanel,LNum));
 Assert(LPnl<>nil,'GGGG='+IntToStr(LNum)+' count='+IntTostr(LCount));
 SetPxData(Lpnl,TrgbThread(ATh).InfoObj.Data);
 if rgbMnr.ItemsCount>0 then
    Lp:=rgbMnr.CalcNumber/rgbMnr.ItemsCount*100
 else LP:=0;
 if LP>100 then Lp:=100;
  pbFiles.Value:=LP;
  lbl_pFilesPercent.Text:=FloatToStrF(Lp,ffFixed,5,2)+'%';
end;

procedure TDirPxForm.DoPx_BeforeCalc(aSndr: TObject; aNum: integer;
  const ATh: TThread);
var LPnl:Tpanel;
    LNum:integer;
    i:integer;
begin
 LNum:=TrgbThread(ATh).InfoObj.Data.num;
 if LNum=0 then
    pnl0.Visible:=true
 else
  begin
     LPnl:=TPanel(GetControlInParent(VertScrollBox1.Content,TPanel,LNum));
     if (LPnl=nil) then
        begin
         // i:=GetControlCountInParent(VertScrollBox1.Content,TPanel);
          i:=LNum;
          LPnl:=AddPP_Panel(i,'pnl',pnl0,VertScrollBox1.Content,
                            pnl0.Position.X,pnl0.Position.Y+(pnl0.Height+2)*i,TAlphaColorRec.Alpha);
        end
  end;
end;

procedure TDirPxForm.DoPx_Exit(Sender: TObject);
begin
 f_FreeFlag:=true;
 SetFillFilesProgressState(false,false);
 Rect_Result.Fill.Color:=rgbMnr.ResultColor.ToAlphaColor;
 Rect_Result.Visible:=true;
 lbl_Res.Text:=ColorFToRGBStr(rgbMnr.ResultColor);
 pnl_PFiles.Visible:=false;
 Application.ProcessMessages;
// ShowMessage('All_End');
end;


procedure TDirPxForm.DoPX_Post(const pxlRec: TPxlPostRecord;
  var aContSign:integer);
  var LNum:integer;
      Lpnl:Tpanel;
begin
 if f_CloseFlag=false then
  begin
   { LNum:=pxlRec.num;
    LPnl:=TPanel(GetControlInParent(VertScrollBox1.Content,TPanel,LNum));
    Assert(LPnl<>nil,'GGGG');
    SetPxData(Lpnl,pxlRec);
    ///
    }
    if f_CloseFlag then
       aContSign:=-10;
  end
 else
    aContSign:=-10;
end;


procedure TDirPxForm.FillFileNames;
var iL,jL:Integer;
    L_SD:string;
   // LREC:TFileDataRec;
begin
 if f_Files.Names.Count>0 then
  begin
   ///  заполнить список каталогов
   f_Dirs.Clear;
   lst_Dirs.Items.Clear;
   iL:=0;
   while iL<f_Files.Names.Count do
     begin
       L_SD:=ExtractFileDir(f_Files.Names[iL]);
       jL:=f_Dirs.IndexOf(L_SD);
       if (jL<0) and (L_SD<>'') then
          begin
            jL:=f_Dirs.Add(L_SD);
            lst_Dirs.Items.Add(L_SD);
          ///  LREC:=f_Files.Items[iL];
          ///  LREC.PathNum:=jL;
         ///   f_Files.Items[iL]:=LREC;
          end;
       Inc(iL);
     end;
   ///
   SetFillFilesProgressState(true,true);
   f_FreeFlag:=false;
   ///
   TThread.CreateAnonymousThread(
   procedure
    var i,j:Integer;
        LSRec:TSearchRec;
        LPath:string;
        LFileDesc:string;
        L_pr:Single;
       // L_prev,L_curr:Cardinal;
        L_Flag:Boolean;
     begin
        L_Flag:=false;
      // L_prev:=0; L_curr:=0;
       f_Files.Clear; // !!
       try
       I:=0;
       while i<f_Files.names.Count do
        begin
         LPath:=ExtractFilePath(f_Files.Names.Strings[i]);
         if FindFirst(f_Files.Names.Strings[i], faAnyFile - faDirectory - faVolumeID,LSRec)=0 then
          begin
            j:=f_Dirs.IndexOf(ExcludeTrailingPathDelimiter(Lpath));
            if j>=0 then
             begin
                f_Files.AddData(2,i,j,LPath,LSRec);
                LFileDesc:=Concat(LPath+LSREc.Name,'(',IntToStr(LSREc.Size),')-',DateTimeToStr(LSREc.TimeStamp));
              //  L_curr:=TTHread.GetTickCount;
              //  if (L_Flag=false) or ((L_curr-L_Prev)>aRefreshMSec) then
                 TThread.Synchronize(nil,procedure
                  begin
                    L_Flag:=true;
                   lbl_pFiles.Text:=LFileDesc;
                   L_Pr:=100*i/f_Files.names.Count;
                   lbl_pFilesPercent.Text:=FloatToStrF(L_Pr,ffFixed,5,2)+'%';
                   pbFiles.Value:=L_Pr;
                   lst_Files.Items.Add(LFileDesc);
                  end);
               // L_Prev:=TTHread.GetTickCount; // !
             end;
          end;
         FindClose(LSrec);
         if f_CloseFlag then
            break;
         Inc(i);
        end;
       finally
          TThread.Synchronize(nil,procedure
             begin
               if f_CloseFlag=false then
                  SetFillFilesProgressState(false,false);
               f_FreeFlag:=true; // !
             end);
       end;
     end).Start;
  end;
end;

procedure TDirPxForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 ///
 f_CloseFlag:=True;
 rgbMnr.Stop(true);
end;

procedure TDirPxForm.FormCreate(Sender: TObject);
var i:Integer;
    LPnl:TPanel;
    LpxlEvents:TrgbEventsRec;
begin
  f_FilesExt:='jpg;png;bmp';
  f_Dirs:=TStringList.Create;
  f_Files:=TFileDataList.Create;
  f_CloseFlag:=False;
  f_FreeFlag:=True;
  pnl_PFiles.Visible:=False;
  Rect_Result.Visible:=false;
 // pnl1.
  ///
  f_ThCount:=2;
  ///
  LpxlEvents.SetNull;
  LpxlEvents.postEvent:=DoPX_Post;
  LpxlEvents.progressEvent:=nil;//DoPX_Progress;
  LpxlEvents.exitEvent:=DoPx_Exit;
  LpxlEvents.beforeCalcEvent:=DoPX_BeforeCalc;
  LpxlEvents.afterCalcEvent:=DoPX_AfterCalc;

  rgbMnr:=TrgbFileManager.Create(nil);
  rgbMnr.SetThParams(f_ThCount,LpxlEvents);
  lbl_rInfo.Text:='';
  lbl_rPercent.Text:='';
  pbR.Value:=0;
  pnl0.Visible:=false;
  pnlPathS.Visible:=false;
{  i:=1;
  while i<=f_ThCount do
   begin
     LPnl:=AddPP_Panel(i,'pnl',pnl0,pnl0.Position.X,pnl0.Position.Y+(pnl0.Height+2)*(i-1));
     Inc(i);
   end;
end;}
  ///
  f_FilesTmpFileName:=ExtractFilePath(ParamStr(0))+'filelist.dat';
  if FileExists(f_FilesTmpFileName) then
     begin
      try
       f_Files.ClearAll;
       lst_Files.Items.Clear;
       if f_Files.LoadNamesFromFile(f_FilesTmpFileName) then
         begin
          FillFileNames;
         end;
       except
        f_Files.ClearAll;
        lst_Files.Items.Clear;
      end;
     end;
end;

procedure TDirPxForm.FormDestroy(Sender: TObject);
begin
 while not(f_FreeFlag) do
  begin
   Sleep(40);
   Application.ProcessMessages;
  end;
  f_Dirs.Free;
  f_Files.Free;
  FreeAndNil(rgbMnr);
end;

procedure TDirPxForm.SetFillFilesProgressState(aState,aClearFiles:Boolean);
begin
  if aState then
    begin
         aFindFiles.Enabled:=False;
         pnl_PFiles.Visible:=True;
       if aClearFiles then
         lst_Files.Items.Clear;
         lbl_pFiles.Text:='';
         pbFiles.Value:=0;
    end
  else
   begin
      aFindFiles.Enabled:=true;
         pnl_PFiles.Visible:=False;
         lbl_pFiles.Text:='';
         pbFiles.Value:=100;
   end;
end;

procedure TDirPxForm.SetPxData(aPnl: TPanel; const pxlRec: TPxlPostRecord);
var Lb1,LbInfo,LbColor:TLabel;
    Lprogress:TProgressBar;
    LR:TRectangle;
    LTag,LOpSign,LNum:Integer;
begin
  if Assigned(aPnl) then
    begin
      aPnl.Visible:=true;
      LTag:=aPnl.Tag;
    //  перерисовка только если свойства отличаютс€ от ранее выставленных - исп. свойства SetProperties
      LOpSign:=pxlRec.opSign;
      Lnum:=pxlRec.num;
       Lb1:=Tlabel(GetControlInParent(aPnl,TLabel,1));
       LbInfo:=Tlabel(GetControlInParent(aPnl,TLabel,10));
       Lprogress:=TProgressBar(GetControlInParent(aPnl,TProgressBar,0));
       if Assigned(Lb1) then
          Lb1.Text:=FloatToStrF(pxlRec.ProgressValue*100,ffFixed,5,2)+'%';
       if Assigned(LbInfo) then
          LbInfo.Text:=IntToStr(pxlRec.num)+' '+pxlRec.FileName;
       if Assigned(Lprogress) then
          Lprogress.Value:=pxlRec.ProgressValue*100;
       LR:=TRectangle(GetControlInParent(aPnl,TRectangle,1));
       if Assigned(LR) then
        begin
          LR.Fill.Color:=pxlRec.cValue.ToAlphaColor;
        end;
       LbColor:=Tlabel(GetControlInParent(aPnl,TLabel,20));
       if Assigned(LbColor) then
          begin
            LbColor.Text:=pxlRec.ValueToStr;
          //  LbColor.FontColor:=pxlRec.
          end;
     end;
   if (LOpSign=2) and (pxlRec.ProgressValue=1) then
     begin // вычислено
       if pxlRec.cValue.R<0.97 then
          lst_Log.Items.Add(IntToStr(pxlRec.num)+':'+pxlRec.ValueToStr);
       ///
       if Assigned(LbInfo) then
         LbInfo.Text:='+'+LbInfo.Text;
       if Assigned(LR) then
        begin
          LR.Fill.Color:=pxlRec.cValue.ToAlphaColor;
        end;
     end;
 {  if (LOpSign<>2) and (pxlRec.ProgressValue=1) then
     begin
      LbInfo.Text:=Format('Thread=%d, num=%d, Op=%d, Perc=%f',[pxlRec.threadNum,pxlRec.num,pxlRec.opSign,pxlRec.ProgressValue]);
     end; }
end;

procedure TDirPxForm.tmr1Timer(Sender: TObject);
begin
  if FRepeatFlag=false then
     tmr1.Enabled:=false
  else
   if pnl_PFiles.Visible=false then
    begin
       ClearPxPanels(false);
       Application.ProcessMessages;
       rgbMnr.SetItemsData(f_Dirs,f_Files.Names);
       rgbMnr.StartItems;
       f_FreeFlag:=false; // !
       SetFillFilesProgressState(true,false);
       ///
    end;
end;

procedure TDirPxForm.tmrRenewTimer(Sender: TObject);
var i:integer;
    LRec:TPxlPostRecord; LPnl:Tpanel;
begin
  tmrRenew.Enabled:=false;
  Application.ProcessMessages;
  i:=0;
 // CSA.Enter;
  try
      while i<rgbMnr.Threads.Count do
      begin
        LRec:=rgbMnr.Threads.Items[i].GetPxlRecord;
        LPnl:=TPanel(GetControlInParent(VertScrollBox1.Content,TPanel,LRec.num));
        if Assigned(Lpnl) then
           SetPxData(LPnl,LRec);
       Inc(i);
      end;
  finally
   // CSA.Leave;
  end;
 tmrRenew.Enabled:=true;
end;

function TDirPxForm.UpdatePxThreadData: Boolean;
var i:Integer;
    LData:TPxlPostRecord;
    LPnl:TPanel;
begin
  Result:=false;
  if Assigned(rgbMnr) and (rgbMnr.IsClosed=false) and (rgbMnr.Threads.Count>0) then
    begin
      for I:=0 to rgbMnr.Threads.Count-1 do
        begin
          if (rgbMnr.Threads[i].IsCalculated) and
             (rgbMnr.Threads[i].InfoObj.Data.opSign=1) then
            begin
              LData:=rgbMnr.Threads.Items[i].InfoObj.Data;
              LPnl:=TPanel(GetControlInParent(VertScrollBox1.Content,TPanel,LData.num));
              if Assigned(LPnl) then
                begin
                 SetPxData(LPnl,LData);
                 Result:=true;
                end;
            end;
        end;
    end;
end;

end.
