unit Main;

interface

uses
  Dialogs, XPMan, ComCtrls, StdCtrls, Controls, ExtCtrls, Classes,
  Forms, Windows, SysUtils, Graphics, 
  Parser2, Buttons, Menus, AppEvnts;

type
  TMainForm = class(TForm)
    LoadButton: TButton;
    FileNameBox: TEdit;
    TranslateButton: TButton;
    XPManifest: TXPManifest;
    Panel1: TPanel;
    HTMLSource: TMemo;
    TreeView: TTreeView;
    Splitter: TSplitter;
    BrowseBtn: TButton;
    OpenDialog: TOpenDialog;
    SelectTag: TRadioButton;
    SelectBlock: TRadioButton;
    StatusBar: TStatusBar;
    StatusTimer: TTimer;
    HorVertButton: TSpeedButton;
    ColorMenu: TPopupMenu;
    Standard1: TMenuItem;
    Green1: TMenuItem;
    GreenBlue21: TMenuItem;
    N1: TMenuItem;
    Smoothanimation1: TMenuItem;
    Address: TEdit;
    GoButton: TButton;
    QSearch: TEdit;
    FindNext: TButton;
    ApplicationEvents: TApplicationEvents;
    SourceMenu: TPopupMenu;
    SourceMenuCopy: TMenuItem;
    N2: TMenuItem;
    SourceMenuWordWrap: TMenuItem;
    SourceMenuAlignSource: TMenuItem;
    SourceMenuSelectAll: TMenuItem;
    procedure LoadButtonClick(Sender: TObject);
    procedure TranslateButtonClick(Sender: TObject);
    procedure TreeViewDblClick(Sender: TObject);
    procedure SplitterMoved(Sender: TObject);
    procedure BrowseBtnClick(Sender: TObject);
    procedure TreeViewChange(Sender: TObject; Node: TTreeNode);
    procedure TreeViewClick(Sender: TObject);
    procedure HTMLSourceClick(Sender: TObject);
    procedure HTMLSourceKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure HTMLSourceKeyPress(Sender: TObject; var Key: Char);
    procedure HTMLSourceMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure HTMLSourceMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure StatusTimerTimer(Sender: TObject);
    procedure SplitterCanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
    procedure HorVertButtonClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure ColorSelect(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TreeViewAnimStart(Sender: TObject; Node: TTreeNode;
      var AllowExpansion: Boolean);
    procedure TreeViewAnimEnd(Sender: TObject; Node: TTreeNode);
    procedure Smoothanimation1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure GoButtonClick(Sender: TObject);
    procedure AddressExit(Sender: TObject);
    procedure AddressEnter(Sender: TObject);
    procedure QSearchChange(Sender: TObject);
    procedure QSearchEnter(Sender: TObject);
    procedure FindNextClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ApplicationEventsHint(Sender: TObject);
    procedure SourceMenuSelectAllClick(Sender: TObject);
    procedure SourceMenuCopyClick(Sender: TObject);
    procedure SourceMenuWordWrapClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

var
  HTML:TNode;
  FileName:string;
  InternalUpdate: boolean;

procedure SyncTreeView;
var
  E,E2:TNode;
  I:Integer;
begin
  with MainForm do
    begin
    if(HTML=nil)or
      (HTML.Data=nil) then Exit;
    E:=HTML;
    repeat
      E2:=nil;
      for I:=0 to E.Count-1 do
        if (TNode(E.Items[I]).Position-1 <= HTMLSource.SelStart) and
           (TNode(E.Items[I]).Position-1+TNode(E.Items[I]).BlockLength > HTMLSource.SelStart)and
           TTreeNode(TNode(E.Items[I]).Data).IsVisible then
             E2:=TNode(E.Items[I]);
      if E2<>nil then
        E:=E2;
    until E2=nil;
    if TreeView.Selected<>TTreeNode(E.Data) then
      begin
      InternalUpdate:=True;
      TreeView.Selected:=TTreeNode(E.Data);
      TTreeNode(E.Data).MakeVisible;
      InternalUpdate:=False;
      end;
    end;
end;

procedure UpdatePanel;
begin
with MainForm do
  begin
  StatusBar.Panels[0].Text:='Row: '+IntToStr(HTMLSource.CaretPos.Y);
  StatusBar.Panels[1].Text:='Col: '+IntToStr(HTMLSource.CaretPos.X);
  StatusBar.Panels[2].Text:='SelStart: '+IntToStr(HTMLSource.SelStart);
  StatusBar.Panels[3].Text:='SelLength: '+IntToStr(HTMLSource.SelLength);
  //StatusBar.Panels[4].Text:='Total nodes: '+IntToStr(TotalNodes);
  if FileName='' then
    StatusBar.Panels[5].Text:='No file loaded'
  else
    StatusBar.Panels[5].Text:=FileName;
  if(HTMLSource.Focused)or(QSearch.Focused) then
    SyncTreeView;
  end;
end;

procedure TMainForm.LoadButtonClick(Sender: TObject);
var f:file;s,fn:string;i:integer;
begin
  fn:=FileNameBox.Text;
  for i:=1 to length(fn) do
    if fn[i]='/' then fn[i]:='\';
  if copy(fn,1,17)='file:\\localhost\' then
    Delete(fn,1,17);
  if not FileExists(fn) then
    begin MessageBox(Handle,PChar('Cannot find file: '+fn),nil,0);exit end;
  FileNameBox.Text:=fn;
  assignfile(f,fn);
  reset(f,1);
  SetLength(s,FileSize(f));
  BlockRead(f,s[1],FileSize(f));
  closefile(f);
  i:=2;
  while i<length(s) do
    if (s[i]=#13)and(s[i+1]<>#10) then
      insert(#10,s,i+1)
    else
    if (s[i]<>#13)and(s[i+1]=#10) then
      insert(#13,s,i+1)
    else
      inc(i);
  HTMLSource.Alignment:=taLeftJustify;
  HTMLSource.Enabled:=True;
  HTMLSource.Text:=s;
  try MainForm.FocusControl(TranslateButton) except end;
  FileName:=FileNameBox.Text;
end;

procedure AddElem(Parent: TTreeNode; El: TNode);
var 
  I: Integer;
  MyNode: TTreeNode;
  S: string;
begin
  with MainForm.TreeView.Items do
    begin
    if El.NodeType=ntRoot then
      S:='<Root node>'
    else
    if El.NodeType=ntEnd then
      S:='<End of data>'
    else
    if El.NodeType=ntError then
      S:='Error: '+El.Tag
    else
    if El.NodeType=ntCloseTag then
      S:='Unmatched tag close: </'+El.Tag+'>'
    else
    if El.NodeType=ntMissedCloseTag then
      S:='Missing tag close: </'+El.Parent.Tag+'> (found </'+El.Tag+'> instead)'
    else
    if El.NodeType=ntComment then
      S:='Comment: '+El.Tag
    else
    if El.NodeType=ntXML then
      S:='XML: '+El.Tag
    else
    if El.NodeType=ntText then
      S:=El.AsText
    else
      S:=El.Tag;
      
    for I := 1 to Length(S) do
      if S[I]=#9 then
        S[I]:=' ';

    //El.Properties.Sort;

    for I:=0 to El.Properties.Count-1 do
     if Pos(' ', El.Properties.ValueFromIndex[I])<>0 then
      S := S + ' ' + El.Properties.Names[I] + '="' + ConvertEntities(El.Properties.ValueFromIndex[I]) + '"'
     else
      S := S + ' ' + ConvertEntities(El.Properties[I]);
    MyNode := AddChild(Parent, S);
    MyNode.Data := El;
    El.Data := MyNode;
    for I := 0 to El.Count-1 do
      AddElem(MyNode, TNode(El.Items[I]));
    end;
end;

procedure TMainForm.TranslateButtonClick(Sender: TObject);
begin
  TranslateButton.Enabled:=False;
  if HTML<>nil then
    HTML.Free;
  HTML := TNode.Create;
  HTML.Parse(HTMLSource.Text);
  LockWindowUpdate(TreeView.Handle);
  TreeView.Items.Clear;
  AddElem(nil,HTML);
  LockWindowUpdate(0);
  HTMLSource.SelLength:=0;
  if TreeView.Items.Count>0 then
    begin
    TreeView.Items.Item[0].Expand(True);
    TreeView.Select(TreeView.Items.Item[0]);
    end;
  if MainForm.Visible then
    MainForm.FocusControl(TreeView);
  TranslateButton.Enabled:=True;
end;

procedure TMainForm.TreeViewDblClick(Sender: TObject);
begin
  if TreeView.Selected<>nil then
    begin
    HTMLSource.SelStart:=TNode(TreeView.Selected.Data).Position;
    MainForm.FocusControl(HTMLSource);
    end;
end;

procedure TMainForm.SplitterMoved(Sender: TObject);
var X:Integer;
begin
  X:=TreeView.Left;
  if X>MainForm.ClientWidth-(168+HorVertButton.Width+5) then X:=MainForm.ClientWidth-(168+HorVertButton.Width+5);
  if X<304 then X:=304;
  LoadButton.Left:=X-78;
  TranslateButton.Left:=X;
  //Button4.Left:=X+208;
  SelectTag.Left:=X+80;
  SelectBlock.Left:=X+80;
  HorVertButton.Left:=X+168;
end;

procedure TMainForm.BrowseBtnClick(Sender: TObject);
begin
  OpenDialog.InitialDir:=ExtractFileDir(FileNameBox.Text);
  if OpenDialog.Execute then
    begin
    FileNameBox.Text:=OpenDialog.FileName;
    LoadButton.Click;
    end;
end;

procedure TMainForm.TreeViewChange(Sender: TObject; Node: TTreeNode);
begin
  if InternalUpdate then Exit;
  if TreeView.Selected<>nil then
   with TNode(TreeView.Selected.Data) do
    begin
    if SelectTag.Checked then
      begin
      HTMLSource.SelStart:=Position-1;
      HTMLSource.SelLength:=TagLength;
      end
    else
      begin
      HTMLSource.SelStart:=Position-1;
      HTMLSource.SelLength:=BlockLength;
      end;
    Address.Text:=Path;
    end;
  UpdatePanel;
  if not Smoothanimation1.Checked then
    LockWindowUpdate(0);
end;

procedure TMainForm.TreeViewClick(Sender: TObject);
begin TreeViewChange(nil,nil) end;

procedure TMainForm.HTMLSourceClick(Sender: TObject);begin UpdatePanel end;
procedure TMainForm.HTMLSourceKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);begin UpdatePanel end;
procedure TMainForm.HTMLSourceKeyPress(Sender: TObject; var Key: Char);begin UpdatePanel end;
procedure TMainForm.HTMLSourceMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);begin UpdatePanel end;
procedure TMainForm.HTMLSourceMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);begin UpdatePanel end;
procedure TMainForm.StatusTimerTimer(Sender: TObject);begin UpdatePanel end;

procedure TMainForm.SplitterCanResize(Sender: TObject; var NewSize: Integer;
  var Accept: Boolean);
begin
//  Accept:=(NewSize>=300)or(NewSize<=1);
end;

procedure TMainForm.HorVertButtonClick(Sender: TObject);
var o:word;
begin
  if HorVertButton.Down then
    begin
    HorVertButton.Caption:='&Hor';
    o:=HTMLSource.Width;
    HTMLSource.Align:=alTop;
    Splitter.Align:=alTop;
    if o<5 then
      HTMLSource.Height:=o
    else
      HTMLSource.Height:=Panel1.Height div 2-2;
    end
  else
    begin
    o:=HTMLSource.Height;
    HorVertButton.Caption:='&Vert';
    Splitter.Align:=alLeft;
    HTMLSource.Align:=alLeft;
    if o<5 then
      HTMLSource.Width:=o
    else
      HTMLSource.Width:=381;
    end;
end;

var 
  OldHeight:word;

procedure TMainForm.FormResize(Sender: TObject);
begin
  SplitterMoved(nil);
  if HorVertButton.Down and (HTMLSource.Height=OldHeight div 2-2) then
    HTMLSource.Height:=Panel1.Height div 2-2;
  OldHeight:=Panel1.Height;
end;

const
  Schemes:array[1..3]of record
                        Bg1,Fg1,Bg2,Fg2:TColor
                        end=(
  (Bg1:clWindow    ;Fg1:clWindowText;Bg2:clWindow    ;Fg2:clWindowText),
  (Bg1:$00F4FFF4   ;Fg1:clWindowText;Bg2:$00FFF4F4   ;Fg2:clWindowText),
  (Bg1:clBlack     ;Fg1:clLime      ;Bg2:clBlack     ;Fg2:clAqua      ));

procedure TMainForm.ColorSelect(Sender: TObject);
begin
  with Sender as TMenuItem do
    begin
    HTMLSource.Color:=Schemes[Tag].Bg1;
    HTMLSource.Font.Color:=Schemes[Tag].Fg1;
    TreeView.Color:=Schemes[Tag].Bg2;
    TreeView.Font.Color:=Schemes[Tag].Fg2;
    end;
end;

procedure TMainForm.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbRight then
   with TControl(Sender).ClientToScreen(Point(X,Y)) do
    ColorMenu.Popup(X,Y);
end;

procedure TMainForm.TreeViewAnimStart(Sender: TObject; Node: TTreeNode;
  var AllowExpansion: Boolean);
begin
  LockWindowUpdate(TreeView.Handle);
end;

procedure TMainForm.TreeViewAnimEnd(Sender: TObject; Node: TTreeNode);
begin
  LockWindowUpdate(0);
end;

procedure TMainForm.Smoothanimation1Click(Sender: TObject);
begin
  if Smoothanimation1.Checked then
    begin
    TreeView.OnExpanding:=nil;
    TreeView.OnExpanded:=nil;
    TreeView.OnCollapsing:=nil;
    TreeView.OnCollapsed:=nil;
    TreeView.OnChanging:=nil;
    end
  else
    begin
    TreeView.OnExpanding:=TreeViewAnimStart;
    TreeView.OnExpanded:=TreeViewAnimEnd;
    TreeView.OnCollapsing:=TreeViewAnimStart;
    TreeView.OnCollapsed:=TreeViewAnimEnd;
    TreeView.OnChanging:=TreeViewAnimStart;
    end
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Green1.Checked:=True;
  Smoothanimation1.Checked:=True;
  if ParamCount=1 then
    begin
    FileNameBox.Text:=ParamStr(1);
    LoadButton.Click;
    TranslateButton.Click;
    end;
end;

procedure TMainForm.GoButtonClick(Sender: TObject);
begin
  try
    TreeView.Selected:=TTreeNode(HTML.FindByPath(Address.Text).Data);
  except
    MessageBeep(0);
    end;
end;

procedure TMainForm.AddressExit(Sender: TObject);
begin
  GoButton.Default:=False;
  LoadButton.Default:=True;
end;

procedure TMainForm.AddressEnter(Sender: TObject);
begin
  GoButton.Default:=True;
  LoadButton.Default:=False;
end;

procedure TMainForm.QSearchChange(Sender: TObject);
var
  I: Integer;
begin
  if QSearch.Text<>'' then
    begin
    i:=pos(UpperCase(QSearch.Text),UpperCase(HTMLSource.Text));
    if i<>0 then
      begin
      HTMLSource.SelStart:=i-1;
      HTMLSource.SelLength:=length(QSearch.Text);
      //QSearch.Font.Color:=clLime;
      end
    else
      begin
      HTMLSource.SelLength:=0;
      //QSearch.Font.Color:=clRed;
      end;
    end
  else
    HTMLSource.SelLength:=0;
  UpdatePanel;
  SyncTreeView;
end;

procedure TMainForm.QSearchEnter(Sender: TObject);
begin
  LoadButton.Default:=False;
  TranslateButton.Default:=False;
  FindNext.Default:=True;
end;

procedure TMainForm.FindNextClick(Sender: TObject);
var i,b:integer;
begin
  if QSearch.Text<>'' then
    begin
    b:=HTMLSource.SelStart+1;
    i:=pos(UpperCase(QSearch.Text),UpperCase(Copy(HTMLSource.Text,b+1,1000000)));
    if i<>0 then
      begin
      HTMLSource.SelStart:=b+i-1;
      HTMLSource.SelLength:=length(QSearch.Text);
      //QSearch.Font.Color:=clLime;
      end
    else
      QSearchChange(nil);
    end
  else
    HTMLSource.SelLength:=0;
  QSearch.SelectAll;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  HorVertButton.Down:=True;
  HorVertButton.Click;
end;

procedure TMainForm.ApplicationEventsHint(Sender: TObject);
begin
  if Application.Hint='' then
    if FileName='' then
      StatusBar.Panels[5].Text:='No file loaded'
    else
      StatusBar.Panels[5].Text:=FileName
  else
    StatusBar.Panels[5].Text:=Application.Hint;
end;

procedure TMainForm.SourceMenuSelectAllClick(Sender: TObject);
begin
  HTMLSource.SelectAll;
end;

procedure TMainForm.SourceMenuCopyClick(Sender: TObject);
begin
  HTMLSource.CopyToClipboard;
end;

procedure TMainForm.SourceMenuWordWrapClick(Sender: TObject);
var 
  N: TTreeNode;
  S: string;
begin
  N:=TreeView.Selected;
  HTMLSource.WordWrap:=SourceMenuWordWrap.Checked;
  if SourceMenuWordWrap.Checked then
    HTMLSource.ScrollBars := ssVertical
  else
    HTMLSource.ScrollBars := ssBoth;
  S:=HTMLSource.Text;
  HTMLSource.Text:='';
  HTMLSource.Text:=S;
  TreeView.Selected:=N;
  TreeViewChange(nil,N);
end;

end.
