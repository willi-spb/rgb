program RGBCalc;

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  System.StartUpCopy,
  FMX.Forms,
  u_PixelProcs in 'u_PixelProcs.pas',
  u_ExtFilesProcs in 'u_ExtFilesProcs.pas',
  fm_DirPx in 'fm_DirPx.pas' {DirPxForm},
  FMX.uBitmapData in 'FMX.uBitmapData.pas';

{$R *.res}

begin
  Application.Initialize;
  ReportMemoryLeaksOnShutdown:=True;
  Application.CreateForm(TDirPxForm, DirPxForm);
  Application.Run;
end.
