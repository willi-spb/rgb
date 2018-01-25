unit u_ExtFilesProcs;
/// модуль для работы с файлами - поиск и пр.
interface

uses  System.Classes, System.Types, System.UITypes, FMX.Types, System.SysUtils, System.Generics.Collections;


/// <summary>
///    find files and Return number
/// </summary>
function FindFilesInPlaces(const APlaces,AFiles:TStrings; const aExtDivText:string):Integer;

type
   TFilePostEvent=procedure(aRg,aItemNum,aPathNum:Integer; aSuccessFlag:Boolean;
                          const aPath:string; const ASRec:TSearchRec; var aBreakSign:integer) of object;
   TFileStateEvent=procedure(aResultSign:integer) of object;

   TFindFilesEventRec=record
     ffPostEvent,ffErrorEvent:TFilePostEvent;
     ffBeforeEvent,ffAfterEvent:TFileStateEvent;
    // ffOnTerminate:TNotifyEvent;
   end;

TFileDataRec=record
  SearchRec:TSearchRec;
  num,PathNum,fdType:Integer;
  filePath:string;
end;

TFileDataList=class(TList<TFileDataRec>)
  public
   Names:TStrings;
   constructor Create;
   procedure SaveNamesToFile(const AFileName:string; aFillNamesFlag:Boolean=true);
   function LoadNamesFromFile(const AFileName:string):Boolean;
   destructor Destroy; override;
   procedure ClearAll;
   procedure AddData(aDtType,aNum,aPathNum:Integer; const aPath:string; const ASRec:TSearchRec);
end;

procedure trFindFilesInPlaces(const APlaces:TStrings; const aExtDivText:string; const aEventRec:TFindFilesEventRec);


implementation

uses System.IOUtils;

type

   TfindFilesThread=Class(TThread)
    private
      F_Dirs,F_ExtList:TStrings;
      F_EventRec:TFindFilesEventRec;
    protected
      procedure Execute; override;
    public
      constructor Create(const ADirs:TStrings; const aExtDivText:string; const aEventRec:TFindFilesEventRec);
      destructor Destroy; override;
  end;

function FindFilesInPlaces(const APlaces,AFiles:TStrings; const aExtDivText:string):Integer;
var i,j:Integer;
    LExtList:TStrings;
    sdaFiles: TStringDynArray;
    //
 begin
   Result:=0;
   AFiles.Clear;
   LExtList:=TStringList.Create;
   try
    LExtList.Delimiter:=';';
    LExtList.DelimitedText:=aExtDivText;
    if LExtList.Count=0 then Exit;
    i:=0;
    while i<APlaces.Count do
     begin
       SetLength(sdaFiles,0);
       sdaFiles:=TDirectory.GetFiles(IncludeTrailingPathDelimiter(APlaces.Strings[i]),
                             TSearchOption.soAllDirectories,
                             function(const Path: string; const SearchRec: TSearchRec):boolean
                               begin
                                Result:=(LExtList.IndexOf(Lowercase(StringReplace(ExtractFileExt(SearchRec.Name),'.','',[])))>=0);
                               end
                             );
     for j:=Low(sdaFiles) to High(sdaFiles) do
        begin
          AFiles.Add(sdaFiles[j]);
        end;
       Inc(i);
     end;
    SetLength(sdaFiles,0);
    Result:=AFiles.Count;
   finally
     LExtList.Free;
   end;
 end;

{ TfindFilesThread }

constructor TfindFilesThread.Create(const ADirs: TStrings;
  const aExtDivText: string; const aEventRec:TFindFilesEventRec);
begin
  inherited Create(True);
  F_Dirs:=TStringList.Create;
  F_ExtList:=TStringList.Create;
  F_Dirs.Assign(ADirs);
  F_ExtList.Delimiter:=';';
  F_ExtList.DelimitedText:=aExtDivText;
  F_EventRec:=aEventRec;
 // OnTerminate:=F_EventRec.ffOnTerminate;
  FreeOnTerminate :=true;
  Priority:=tpNormal; // !~
  Resume;
end;

destructor TfindFilesThread.Destroy;
begin
  FreeAndNil(F_Dirs);
  FreeAndNil(F_ExtList);
  inherited;
end;

procedure TfindFilesThread.Execute;
var i,j:Integer;
    sdaFiles: TStringDynArray;
    L_ErrFlag:Boolean;
    L_BreakSign:Integer;
    L_SearchRec:TSearchRec;
begin
  i:=0; j:=0;
  if (Assigned(F_EventRec.ffBeforeEvent)) then
    Self.Synchronize(procedure
      begin
       F_EventRec.ffBeforeEvent(0);
      end);
   if (Terminated=true) then Exit;
   while (Terminated=false) and (i<F_Dirs.Count) do
     begin
       SetLength(sdaFiles,0);
       L_BreakSign:=0;
       try
        sdaFiles:=TDirectory.GetFiles(IncludeTrailingPathDelimiter(F_Dirs.Strings[i]),
                             TSearchOption.soAllDirectories,
                             function(const Path: string; const SearchRec: TSearchRec):boolean
                               var LRes:Boolean;
                               begin
                                L_BreakSign:=0;
                                L_SearchRec:=SearchRec;
                                LRes:=(f_ExtList.IndexOf(Lowercase(StringReplace(ExtractFileExt(L_SearchRec.Name),'.','',[])))>=0);
                                if (Terminated=false) and (Assigned(F_EventRec.ffPostEvent)) then
                                   Self.Synchronize(procedure
                                                 begin
                                                  F_EventRec.ffPostEvent(1,
                                                  j,
                                                  i,
                                                  LRes,
                                                  IncludeTrailingPathDelimiter(Path),
                                                  L_SearchRec,
                                                  L_BreakSign);
                                                  Inc(j);
                                                 end);
                                if (Terminated=true) or (L_BreakSign<>0) then
                                    Result:=false
                                else Result:=LRes;
                                if L_BreakSign>1 then
                                 begin
                                    SetLength(sdaFiles,0);
                                   Self.Terminate;  // странно - но работает без ошибок...
                                 end;
                               end
                             );
        L_ErrFlag:=false;
       except
        if (L_BreakSign=0) and (Terminated=false) and (Assigned(F_EventRec.ffErrorEvent)) then
                Self.Synchronize(procedure
                   begin
                    F_EventRec.ffErrorEvent(2,0,i,False,IncludeTrailingPathDelimiter(F_Dirs.Strings[i]),
                                              L_SearchRec,
                                              L_BreakSign);
                   end);
         L_ErrFlag:=true;
       end;
      Inc(i);
     end;
     if (Terminated=false) and (Assigned(F_EventRec.ffAfterEvent)) then
        Self.Synchronize(procedure
          begin
            F_EventRec.ffAfterEvent(3);
          end);
    SetLength(sdaFiles,0);
end;

procedure trFindFilesInPlaces(const APlaces:TStrings; const aExtDivText:string; const aEventRec:TFindFilesEventRec);
var L_TR:TfindFilesThread;
 begin
   L_TR:=TfindFilesThread.Create(APlaces,aExtDivText,aEventRec);
 end;

{ TFileDataList }


procedure TFileDataList.AddData(aDtType, aNum, aPathNum: Integer; const aPath: string;
  const ASRec: TSearchRec);
 var LS:string;
     LRec:TFileDataRec;
begin
  LS:=IncludeTrailingPathDelimiter(aPath)+ASRec.Name;
  if Names.IndexOf(LS)<0 then
       Names.Add(LS);
  ///
  Lrec.SearchRec:=ASRec;
  Lrec.num:=aNum;
  Lrec.fdType:=aDtType;
  Lrec.filePath:=IncludeTrailingPathDelimiter(aPath);
  Self.Add(LRec);
end;

procedure TFileDataList.ClearAll;
begin
 Names.Clear;
 self.Clear;
end;

constructor TFileDataList.Create;
begin
  inherited;
  Names:=TStringList.Create;
end;

destructor TFileDataList.Destroy;
begin
  names.Free;
  inherited;
end;

function TFileDataList.LoadNamesFromFile(const AFileName: string): Boolean;
begin
  Result:=false;
 if FileExists(AFileName) then
  begin
    Names.LoadFromFile(AFileName);
    Result:=(names.Count>0);
  end;
end;

procedure TFileDataList.SaveNamesToFile(const AFileName: string; aFillNamesFlag:Boolean=true);
var i:Integer;
begin
 if aFillNamesFlag then
  begin
     Names.Clear;
     i:=0;
     while i<self.Count do
      begin
        if aFillNamesFlag then
           Names.Add(IncludeTrailingPathDelimiter(Items[i].filePath)+Items[i].SearchRec.Name);
        Inc(i);
      end;
  end;
 Names.SaveToFile(AFileName);
end;

end.
