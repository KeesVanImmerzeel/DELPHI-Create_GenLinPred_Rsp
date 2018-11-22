program Create_GenLinPred_Rsp;

uses
  Vcl.Forms,
  uError,
  System.SysUtils,
  System.Classes,
  Vcl.Dialogs,
  opWString,
  uCreate_GenLinPred_Rsp in 'uCreate_GenLinPred_Rsp.pas' {Form3};
{$R *.res}

var
  BluePrintRSP, pstFl, obsv_names, RSP, par_grp_names, obs_grp_names: TStringList;
  i, j, indx, Len, outputFile_LineNr, nameofprediction_LineNr,
  nr_param_groups, nr_obs_groups: Integer;
  pstFileName, s: String;
  f: TextFile;
const
  WordDelims: CharSet = [' '];

Procedure ShowArgumentsAndTerminate;
begin
  ShowMessage( 'Create_GenLinPred_Rsp svdaPESTrec BluePrintRSPfile RunGENLINPREDbatch RunOBS2OBSbatch' );
  // for example %DelphiDebug%\Create_GenLinPred_Rsp
  //   precal2b_soln.rec blueprintIN.rsp run_genlinpred.bat run_OBS2OBS.bat
  //  svdaPESTrec: *.rec file with result of calibration
  //  BluePrintRSPfile: GENLINPRED response file, refers to version of PEST file
  //  (of calibrated model) BUT WITHOUT REGULARISATION (subreg1)

  Application.Terminate;
end;

// Make *.rsp files for GENLINPRED

// Example of a RSP file voor GENLINPRED on the basis of an example *.RSP file
// and a PEST control file.

//! GENLINPRED response file. Beware of altering single letter responses as ensuing GENLINPRED prompts may be different
//f                       ! abbreviated or full input?
//precal3.pst             ! PEST control file without regularisation
//u                       ! bounds or uncertainty file for parameter uncertainties?
//param.unc               ! parameter uncertainty file
//y                       ! are weights the inverse of measurement uncertainty?
//mk01_1.out              ! GENLINPRED output file
//y                       ! perform global parameter estimability analysis?
//y                       ! compute parameter identifiabilities?
//n                       ! compute relative parameter error reduction?
//y                       ! use SUPCALC to estimate solution space dimensionality?
//y                       ! compute relative parameter uncertainty reduction?
//y                       ! perform comprehensive analysis of prediction or parameter?
//mk01_1                  ! name of prediction or parameter to analyze
//precal3.jco             ! file to read predictive sensitivities or "p" for parameter
//y                       ! compute solution/null space contributions to predictive error?
//y                       ! compute predictive uncertainty?
//n                       ! compute parameter contributions to parameter or predictive error?
//y                       ! compute parameter contributions to uncertainty?
//g                       ! for individual parameters or parameter groups?
//n                       ! compute observation worth with respect to error?
//y                       ! compute observation worth with respect to uncertainty?
//g                       ! for individual observations or for observation groups?
//n                       ! over-ride SUPCALC calculation of solution space dimensions?

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm3, Form3);

  if not (ParamCount() = 4)   then
     ShowArgumentsAndTerminate;

  BluePrintRSP := TStringList.Create;
  BluePrintRSP.LoadFromFile( ParamStr(2) );

  // Haal pst-filename uit BluePrintRSPfile
  i := -1;
  repeat
    i := i+1;
    indx := pos( '! PEST CONTROL FILE', UpperCase(BluePrintRSP[i]) );
  until (indx > 0) or (i = BluePrintRSP.Count-1 );
  if indx = 0 then begin
    ShowMessage('1: Not a valid BluePrintRSPfile.');
    ShowArgumentsAndTerminate;
  end;
  pstFileName := ExtractWord(1,  BluePrintRSP[i], WordDelims, Len );
  //ShowMessage(pstFileName);

  //Bepaal outputFile_LineNr in BluePrintSRPfile
  i := -1;
  repeat
    i := i+1;
    indx := pos( '! GENLINPRED OUTPUT FILE', UpperCase(BluePrintRSP[i]) );
  until (indx > 0) or (i = BluePrintRSP.Count-1 );
  if indx = 0 then begin
    ShowMessage('2: Not a valid BluePrintRSPfile.');
    ShowArgumentsAndTerminate;
  end;
  outputFile_LineNr := i;

  // Bepaal nameofprediction_LineNr in BluePrintSRPfile
  i := -1;
  repeat
    i := i+1;
    indx := pos( '! name of prediction or parameter to analyze', LowerCase(BluePrintRSP[i]) );
  until (indx > 0) or (i = BluePrintRSP.Count-1 );
  if indx = 0 then begin
    ShowMessage('3: Not a valid BluePrintRSPfile.');
    ShowArgumentsAndTerminate;
  end;
  nameofprediction_LineNr := i;

  //Dispose of BluePrintRSP
  BluePrintRSP.free;

  //Read pest file and extract observation names
  pstFl := TStringList.Create;
  pstFl.LoadFromFile( pstFileName );
  i := -1;
  repeat
    i := i+1;
    indx := pos( '* observation data', LowerCase(pstFl[i]) );
  until (indx > 0) or (i = pstFl.Count-1 );
  if indx = 0 then begin
    ShowMessage('4: Not a valid PEST file.');
    ShowArgumentsAndTerminate;
  end;
  obsv_names := TStringList.Create;
  repeat
    i := i+1;
    indx := pos( '* model command line', LowerCase(pstFl[i]) );
    if indx = 0 then
      obsv_names.Add( ExtractWord(1, pstFl[i], WordDelims, Len )   );
  until (indx > 0) or (i = pstFl.Count-1 );
  // pstFl.free;
  // Showmessage( IntToStr( obsv_names.count ));

  // For all observations: make RSP-file for GENLINPRED on the basis of the
  // blueprint --> RSP
  RSP := TStringList.Create;
  for i:=0 to obsv_names.Count-1 do begin
    RSP.LoadFromFile( ParamStr(2) );
    // Replace outputFileName and NameOfPrediction
    s := RSP[outputFile_LineNr];
    RSP[outputFile_LineNr] := stringreplace( s, ExtractWord(1, s, WordDelims, Len ),
      obsv_names[i]+'.out', [rfReplaceAll, rfIgnoreCase]);
    s := RSP[nameofprediction_LineNr];
    RSP[nameofprediction_LineNr] := stringreplace( s, ExtractWord(1, s, WordDelims, Len ),
      obsv_names[i], [rfReplaceAll, rfIgnoreCase]);
    RSP.SaveToFile( obsv_names[i]+'.rsp'  );
    RSP.Clear;
  end;
  RSP.Free;

  // Make batch file to run GENLINPRED for all observations
  AssignFile( f , ParamStr(3) ); Rewrite( f );
  for i:=0 to obsv_names.Count-1 do
    Writeln( f, 'genlinpred < ' + obsv_names[i] + '.rsp' );
  Writeln( f, 'Pause' );
  CloseFile( f );

//**************************************************************************
// With OBS2OBS some relevant information is extracted from the output of
// GENLINPRED.
// Make OBS2OBS input files for all observations (*.inp)
// and instruction file for OBS2OBS ('OBS2OBS.ins')

// Determine number of parameter groups and observation groups
  nr_param_groups := 0;
  nr_obs_groups := 0;
  Try
    nr_param_groups := StrToInt( ExtractWord(3, pstFl[3], WordDelims, Len ) );
    nr_obs_groups := StrToInt( ExtractWord(5, pstFl[3], WordDelims, Len ) );
  Except
    ShowMessage('5: Not a valid PEST file.');
    ShowArgumentsAndTerminate;
  End;

// Create instruction file for OBS2OBS
  AssignFile( f, 'OBS2OBS.ins' ); Rewrite( f );
  Writeln( f, 'pif @' );
  Writeln( f , '@Total uncertainty standard deviation =@(nr1)44:58' );
  Writeln( f , '@Total uncertainty standard deviation =@(nr2)44:58' );
  Writeln( f, '@PREDUNC4@ ' );
  Writeln( f, 'l7 (nr3)40:54' );
  for i := 1 to nr_param_groups-1 do
    Writeln( f, Format( 'l1 (nr%d)40:54' , [ i+3 ] ) );
  Writeln( f, '@PREDUNC5@' );
  Writeln( f, Format( 'l6 (nr%d)30:44' , [ nr_param_groups+3 ] ) );
  for i := 1 to nr_obs_groups-1 do
    Writeln( f, Format( 'l1 (nr%d)30:44' , [ nr_param_groups+3 + i ] ) );
  Closefile( f );

// Read par_grp_names
  i := -1;
  repeat
    i := i+1;
    indx := pos( '* parameter groups', LowerCase(pstFl[i]) );
  until (indx > 0) or (i = pstFl.Count-1 );
  if indx = 0 then begin
    ShowMessage('6: Not a valid PEST file.');
    ShowArgumentsAndTerminate;
  end;
  par_grp_names := TStringList.Create;
  repeat
    i := i+1;
    indx := pos( '* parameter data', LowerCase(pstFl[i]) );
    if indx = 0 then
      par_grp_names.Add( ExtractWord(1, pstFl[i], WordDelims, Len )   );
  until (indx > 0) or (i = pstFl.Count-1 );

// Read obs_grp_names
  i := -1;
  repeat
    i := i+1;
    indx := pos( '* observation groups', LowerCase(pstFl[i]) );
  until (indx > 0) or (i = pstFl.Count-1 );
  if indx = 0 then begin
    ShowMessage('7: Not a valid PEST file.');
    ShowArgumentsAndTerminate;
  end;
  obs_grp_names := TStringList.Create;
  repeat
    i := i+1;
    indx := pos( '* observation data', LowerCase(pstFl[i]) );
    if indx = 0 then
      obs_grp_names.Add( ExtractWord(1, pstFl[i], WordDelims, Len )   );
  until (indx > 0) or (i = pstFl.Count-1 );

// Free pstFl (PEST file, no longer needed)
  pstFl.Free;

// For all observations: make OBS2OBS input file (*.inp)

  for i:=0 to obsv_names.Count-1 do begin
    AssignFile( f, obsv_names[i]+'.inp' ); Rewrite( f );
    Writeln( f, '* model output' );
    Writeln( f, 'OBS2OBS.ins ' + obsv_names[i]+'.out' );
    Writeln( f, 'OBS2OBS2.ins ' + ParamStr( 1 ) );
    Writeln( f, '* equations' );
    Writeln( f, '# Calculated value' );
    Writeln( f, format('calc_value=%s', [obsv_names[i]] ) );
    Writeln( f, '# Pre-calibration total uncertainty standard deviation' );
    Writeln( f, 'precal_tunc_sd=nr1' );
    Writeln( f, '# Post-calibration total uncertainty standard deviation' );
    Writeln( f, 'postcal_tunc_sd=nr2' );
    Writeln( f, '# Lower and upper 95% confidence intervals pre- and post calibration' );
    Writeln( f, 'precal_lo95=calc_value-2*precal_tunc_sd' );
    Writeln( f, 'precal_up95=calc_value+2*precal_tunc_sd' );
    Writeln( f, 'postcal_lo95=calc_value-2*postcal_tunc_sd' );
    Writeln( f, 'postcal_up95=calc_value+2*postcal_tunc_sd' );
    Writeln( f, '# Difference between upper- and lower 95% confidence interval pre- and post calibration' );
    Writeln( f, 'precal_dif95=precal_up95-precal_lo95' );
    Writeln( f, 'postcal_dif95=postcal_up95-postcal_lo95' );


    Writeln( f, '# Contributions to predictive uncertainty standard deviation of a parameter group' );
    for j := 0 to par_grp_names.Count-1 do
      Writeln( f, Format( 'cpusd_%s=sqrt(nr%d)', [par_grp_names[j], j+3] ) );
    // Increases in predictive uncertainty standard deviation incurred through loss of an observation group
    Writeln( f, '# Increases in predictive uncertainty standard deviation incurred through loss of an observation group' );
    for j := 0 to obs_grp_names.count-1 do
      Writeln( f, Format( 'ipusd_%s=sqrt(nr%d)', [obs_grp_names[j], par_grp_names.Count+3+j] ) );
    Writeln( f, '* output' );
    Writeln( f, 'calc_value' );
    Writeln( f, 'precal_tunc_sd' );
    Writeln( f, 'precal_lo95' );
    Writeln( f, 'precal_up95' );
    Writeln( f, 'precal_dif95' );
    Writeln( f, 'postcal_tunc_sd' );
    Writeln( f, 'postcal_lo95' );
    Writeln( f, 'postcal_up95' );
    Writeln( f, 'postcal_dif95' );
    for j := 0 to par_grp_names.Count-1 do
      Writeln( f, Format( 'cpusd_%s', [par_grp_names[j]] ) );
    for j := 0 to obs_grp_names.count-1 do
      Writeln( f, Format( 'ipusd_%s', [obs_grp_names[j]] ) );
    CloseFile( f );
  end;

// Write batch file for OBS2OBS runs
  AssignFile( f, ParamStr( 4 ) ); Rewrite( f );
  // For all observations: write a call to OBS2OBS
  for i:=0 to obsv_names.Count-1 do begin
    Writeln( f, 'OBS2OBS ' + obsv_names[i]+'.inp ' + obsv_names[i]+'.rs' );
  end;
  CloseFile( f );

// ***********************************************************************
// Create instruction file OBS2OBS2.ins
// To read calculated values from PEST *.rec output file (calibrated model result)
  AssignFile( f, 'OBS2OBS2.ins' ); Rewrite( f );
  Writeln( f, 'pif @' );
  Writeln( f, '@OPTIMISATION RESULTS@' );
  Writeln( f, '@Observations ----->@' );
  Writeln( f, Format( 'l4 (%s)36:50', [obsv_names[0]] ) );
  for i:=1 to obsv_names.Count-1 do begin
    Writeln( f, Format( 'l1 (%s)36:50', [obsv_names[i]] ) );
  end;
  CloseFile( f );

// Free obsv_names, par_grp_names, obs_grp_names.
  obsv_names.Free;
  par_grp_names.Free;
  obs_grp_names.Free;

  //Application.Run;
end.
