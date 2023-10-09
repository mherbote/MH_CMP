{$WARN SYMBOL_PLATFORM OFF}

unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  RegularExpressions, Vcl.ExtCtrls;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    source: TEdit;
    target: TEdit;
    Filename: TEdit;
    ErrField: TEdit;
    AnzFileOk: TEdit;
    AnzFileNotOk: TEdit;
    AnzPath: TEdit;
    FileBytes: TEdit;
    FileBytesCMP: TEdit;
    Label10: TLabel;
    empty: TEdit;
    Label11: TLabel;
    Path: TEdit;
    procedure OnActivate1(Sender: TObject);
    procedure OnClose1(Sender: TObject; var Action: TCloseAction);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

const cBufsize = 40960;

var
    TF            : TFormatSettings;
    Form1         : TForm1;
    ActualVerz,
        qVerz,
        zVerz,
        Verz      : String;
    AnzFileOk1,
    AnzFileNotOk1,
    AnzPath1,
    FileBytes1,
    FileBytesCMP1 : Int64;


implementation

procedure SetErrField(error : String; typErrField : String);
begin
      if      typErrField = 'ERROR'
      then begin
                      Form1.ErrField.Color      := clRed;
                      Form1.ErrField.Font.Color := clWhite;
           end
      else if typErrField = 'INFO'
           then begin
                      Form1.ErrField.Color      := clYellow;
                      Form1.ErrField.Font.Color := clBlue;
                end;

      Form1.ErrField.Text       := error;
      Form1.ErrField.Visible    := true;
end;

function GetFileSize(const FileName: string): Int64;
var
    FileStream : TFileStream;
begin
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      try
        Result := FileStream.Size;
      except
        Result := 0;
      end;
    finally
      FileStream.Free;
    end;
end;

function VerzErmitteln(Verz : String) : String;
  var Erg : String;
begin
      Erg := 'NOT ok';
      if TRegEx.IsMatch(Verz, '^[a-zA-Z][:][.]$')          {'lw:.'}
      then begin
                 SetCurrentDir(Verz);
                 Erg := GetCurrentDir;
           end
      else       Erg := Verz;                              { komplettes Verzeichnis }

      VerzErmitteln := Erg;
end;

procedure delVerzeichnis(Verz:String);
  var SRec   : TSearchRec;
      dd,anz : Integer;
      fa     : Integer;
begin dd:=FindFirst(Verz+'\*.*',faAnyFile,SRec); anz:=0;
      while dd=0 do
      begin if (SRec.Name<>'.') and (SRec.Name<>'..')
            then Inc(anz);
            dd:=FindNext(SRec);
      end;
      FindClose(SRec);
      if anz=0 then begin fa:=FileGetAttr(Verz);
                          fa:=fa and not faReadOnly and not faHidden and not faSysFile;
                          FileSetAttr(Verz,fa);
                          RmDir(Verz);
                          AnzPath1 := AnzPath1 + 1;
                          Form1.AnzPath.Text := System.SysUtils.IntToStr(AnzPath1);
                    end;
end;

function cmpDateien(datei1,datei2:String):Boolean;
  var dl1,dl2   : Int64;
      ende,
      gleich    : Boolean;
      fa,i,j    : Integer;
      Dat1,Dat2 : File;
      buf1,buf2 : Array[1..cBufsize] of Byte;
begin
      fa:=FileGetAttr(datei1);
      fa:=fa and not faReadOnly and not faHidden and not faSysFile;
      FileSetAttr(datei1,fa);

{      AssignFile(in1,datei1); Reset(in1); dl1:=FileSize(in1); Close(in1);}
      dl1 := GetFileSize(datei1);
      Form1.Filename.Text := ExtractFileName(datei1);
      FileBytes1    := 0; Form1.FileBytes.Text    := System.SysUtils.IntToStr(FileBytes1);
      FileBytesCMP1 := 0; Form1.FileBytesCMP.Text := System.SysUtils.IntToStr(FileBytesCMP1);
      Form1.Refresh;

      if FileExists(datei2)
      then begin {AssignFile(in2,datei2); FileMode:=0; Reset(in2); dl2:=FileSize(in2); Close(in2);}
                 dl2 := GetFileSize(datei2);
                 if dl1<>dl2
                 then gleich:=FALSE
                 else begin gleich:=TRUE;
                            FileBytes1    := dl1;
                            Form1.FileBytes.Text := System.SysUtils.FormatFloat('0,',FileBytes1);;
                            Application.ProcessMessages;

                            AssignFile(Dat1,datei1);              Reset(Dat1,SizeOf(buf1));
                            AssignFile(Dat2,datei2); FileMode:=0; Reset(Dat2,SizeOf(buf2));
                            ende:=FALSE;

                            while (dl1>0) and not ende do
                            begin if dl1>cBufsize then j:=cBufsize
                                                  else j:=dl1;

                                  {$I-}
                                         BlockRead (Dat1,buf1[1],1); if IOResult<>0 then ende:=TRUE;
                                         BlockRead (Dat2,buf2[1],1); if IOResult<>0 then ende:=TRUE;
                                  {$I+}

                                  for i:=1 to j do
                                    begin
                                          if buf1[i]<>buf2[i] then gleich:=FALSE;
                                          FileBytesCMP1 := FileBytesCMP1 + 1;
                                    end;

                                  dl1:=dl1-j; dl2:=dl2-j;
                                  TF.ThousandSeparator := '.';
                                  Form1.FileBytesCMP.Text := System.SysUtils.FormatFloat('0,',FileBytesCMP1); {IntToStr(FileBytesCMP1);}
                                  Application.ProcessMessages;

                            end;

                            Close(Dat1); Close(Dat2);
                      end;
           end
      else gleich:=FALSE;
      cmpDateien:=gleich;
end; { cmpDateien }

procedure cmpVerzeichnis(qVerz,zVerz,Verz:String);
  var SRec  : TSearchRec;
      dd    : Integer;
      in1   : File of Byte;
      Verz1 : String;
begin Verz1 := Verz;
      Form1.Path.Text := Verz;
      Form1.Repaint;
      Application.ProcessMessages;
      dd:=FindFirst(qVerz+'\*.*',faAnyFile,SRec);
      while dd=0 do
      begin
            if (SRec.Name<>'.') and (SRec.Name<>'..')
            then begin if ((SRec.Attr and faDirectory)=faDirectory)
                       then begin
                                  Verz:=Verz + '\' + SRec.Name;
                                  cmpVerzeichnis(qVerz+'\'+SRec.Name,zVerz+'\'+SRec.Name,Verz);
                                  delVerzeichnis(qVerz+'\'+SRec.Name);
                                  Verz:=Verz1;
                            end
                       else if cmpDateien(qVerz+'\'+SRec.Name,zVerz+'\'+SRec.Name)
                            then begin AssignFile(in1,qVerz+'\'+SRec.Name);
                                       Erase(in1);
                                       AnzFileOK1 := AnzFileOK1 + 1;
                                       Form1.AnzFileOK.Text := System.SysUtils.IntToStr(AnzFileOk1);
                                 end
                            else begin
                                       AnzFileNotOK1 := AnzFileNotOK1 + 1;
                                       Form1.AnzFileNotOK.Text := System.SysUtils.IntToStr(AnzFileNotOK1);
                                 end;

                 end;
            dd:=FindNext(SRec);
      end;
      FindClose(SRec);
end; { cmpVerzeichnis }

{$R *.dfm}

{ TForm1 }
procedure TForm1.OnActivate1(Sender: TObject);
begin
    Form1.Label10.Width := 995;
    AnzFileOk1   := 0;
    AnzFileNotOk1:= 0;
    AnzPath1     := 0;
    ActualVerz   := GetCurrentDir;
    ActualVerz   := 'C:\Users';
    if ParamCount<2
    then SetErrField('Call with:   MH_CMP  source  target', 'ERROR')
    else begin


               if ParamStr(1) = ParamStr(2)
                   then SetErrField('Source equal Target is not allowed!', 'ERROR')
                   else begin
                           { Parameter übernehmen und testen auf regulären Ausdruck }
                              qVerz := VerzErmitteln(ParamStr(1));
                              zVerz := VerzErmitteln(ParamStr(2));

                              Form1.source.Text := ParamStr(1);
                              Form1.target.Text := ParamStr(2);

                              if ParamStr(1).Length=3 then Form1.source.Text := Form1.source.Text + ' = ' + qVerz;
                              if ParamStr(2).Length=3 then Form1.target.Text := Form1.target.Text + ' = ' + zVerz;

                              if SetCurrentDir(qVerz) then
                              begin
                                    Form1.AnzFileOk.Text    := System.SysUtils.IntToStr(AnzFileOk1);
                                    Form1.AnzFileNotOk.Text := System.SysUtils.IntToStr(AnzFileNotOk1);
                                    Form1.AnzPath.Text      := System.SysUtils.IntToStr(AnzPath1);


                               { Source- und Target- Verzeichnisse anzeigen }
                                    Verz := '.';

                               { Log - Anzeige sichtbar machen }
                                    Form1.Label4.Visible       := true;
                                    Form1.Label5.Visible       := true;
                                    Form1.Label6.Visible       := true;
                                    Form1.Label7.Visible       := true;
                                    Form1.Label8.Visible       := true;
                                    Form1.Label9.Visible       := true;
                                    Form1.AnzFileOk.Visible    := true;
                                    Form1.AnzFileNotOk.Visible := true;
                                    Form1.AnzPath.Visible      := true;

                               { Vergleich ausführen }
                                    cmpVerzeichnis(qVerz,zVerz,Verz);

                                    SetErrField('Compare is ended.', 'INFO');
                                    Form1.empty.SetFocus;
                              end;
                        end;
         end;
end;
procedure TForm1.OnClose1(Sender: TObject; var Action: TCloseAction);
begin
    SetCurrentDir(ActualVerz);
end;

begin
end.

