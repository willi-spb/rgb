unit fm_DRT;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.TreeView,
  System.ImageList, FMX.ImgList, FMX.ScrollBox, FMX.Memo,
  System.Generics.Collections, u_ExtFilesProcs;

type
  TForm1 = class(TForm)
    btn1: TButton;
    ImageList1: TImageList;
    tvPath: TTreeView;
    TreeViewItem1: TTreeViewItem;
    trvwtm1: TTreeViewItem;
    btnSta: TButton;
    Memo1: TMemo;
    procedure btn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnStaClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    f_Dirs:TStrings;
    f_Files:TList<TFileDataRec>;
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses System.IOUtils, u_SelectDirectory;

procedure TForm1.btn1Click(Sender: TObject);
var LS:string;
    sdaDirs: TStringDynArray;
    i:Integer;
begin
  if SelectDirectory('Add Directory',Self.Handle,LS) then
    if f_Dirs.IndexOf(LS)<0 then
       begin
        f_Dirs.Add(LS);
      {  sdaDirs:=TDirectory.GetDirectories(IncludeTrailingPathDelimiter(LS),'*',TSearchOption.soAllDirectories);
        for I := Low(sdaDirs) to High(sdaDirs) do
            if f_Dirs.IndexOf(sdaDirs[i])<0 then
               f_Dirs.Add(sdaDirs[i]);
        }
        ShowMessage(f_Dirs.CommaText);
       end;
end;

procedure TForm1.btnStaClick(Sender: TObject);
var i:Integer;
begin
  i:=FindFilesInPlaces(f_Dirs,f_Files,'png;jpg;bmp');
 /////// ShowMessage(IntToStr(i)+#13#10+f_Files.Text);
  Memo1.Lines.Assign(f_Files);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  sRoot    : string;
  sdaDrives: TStringDynArray;
  sDrive   : string;
  tviDrive,tvR : TTreeViewItem;
  osv      : TOSVersion;
begin
  tvPath.Clear;
  if TOSVersion.Platform = pfMacOS then
  begin
    // Root's folders
    sRoot     := '/';
    sdaDrives := TDirectory.GetDirectories(sRoot);
    for sDrive in sdaDrives do
    begin
      tviDrive      := TTreeViewItem.Create(Self);
      tviDrive.Text := sDrive;
      tvPath.AddObject(tviDrive);
    end;
    sdaDrives := TDirectory.GetFiles(sRoot);
  end
  else
  begin
    // Root's folders
    sRoot     :=TDirectory.GetDirectoryRoot(ParamStr(0));
    tvR:=TTreeViewItem.Create(Self);
    tvR.Text:='PC';
    tvR.Font.Style := [TFontStyle.fsBold];
    tvR.ImageIndex:=0;
    tvPath.AddObject(tvR);
    //
    sdaDrives :=TDirectory.GetLogicalDrives;
 //   sdaDrives := TDirectory.GetDirectories(sRoot);
    for sDrive in sdaDrives do
    begin
      tviDrive      := TTreeViewItem.Create(Self);
      tviDrive.Text :=ExcludeTrailingPathDelimiter(sDrive);
      tviDrive.TagString:=sDrive;
      tviDrive.ImageIndex:=1;
      tvR.AddObject(tviDrive);
    end;
    tvR.Expand;
   // sdaDrives := TDirectory.GetFiles(sRoot);
   sdaDrives := TDirectory.GetDirectories(sRoot);
  end;
 { // files
  for sDrive in sdaDrives do
  begin
    tviDrive            := TTreeViewItem.Create(Self);
    tviDrive.Text       := ExtractFileName(sDrive);
    tviDrive.Font.Style := [TFontStyle.fsItalic];
    tviDrive.ImageIndex:=3;
    tvPath.AddObject(tviDrive);
  end;
  }

  f_Dirs:=TStringList.Create;
  f_Files:=TList<TFileDataRec>.Create;
end;



procedure TForm1.FormDestroy(Sender: TObject);
begin
  f_Dirs.Free;
  f_Files.Free;
end;

end.
