unit UAbout;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TfmAbout = class(TForm)
    lblAppName: TLabel;
    btnOK: TButton;
    Label1: TLabel;
    LinkLabel1: TLinkLabel;
    procedure FormCreate(Sender: TObject);
    procedure LinkLabel1LinkClick(Sender: TObject; const Link: string; LinkType:
        TSysLinkType);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmAbout: TfmAbout;

implementation

uses
  ShellApi,
  UFileVersion;

{$R *.dfm}

procedure ShellOpen(const Url: string; const Params: string = '');
begin
  ShellExecute(0, 'Open', PChar(Url), PChar(Params), nil, SW_SHOWNORMAL);
end;

procedure TfmAbout.FormCreate(Sender: TObject);
begin
  lblAppName.Caption := lblAppName.Caption + VersionInformation(true);
end;

procedure TfmAbout.LinkLabel1LinkClick(Sender: TObject; const Link: string;
    LinkType: TSysLinkType);
begin
  ShellOpen(Link);
end;

end.
