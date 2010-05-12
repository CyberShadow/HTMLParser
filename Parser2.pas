{
    CyberShadow's HTML parser, v2.0
    (c) 2003-2007 Vladimir Panteleev

    Modification, or usage in commercial applications 
    without the author's permission is prohibited.
}

{$IFDEF DEBUG}
{$R+,Q+}
{$ELSE}
{$R-,Q-}
{$ENDIF}

unit Parser2;

interface

uses
  Classes;

type
  TNodeList = class;

  TNodeType = (ntRoot, ntTag, ntCloseTag, ntText, ntEnd, ntError, ntMissedCloseTag, ntComment, ntMeta, ntCData, ntXML);

  TNode = class (TCollectionItem)
    public
      Tag: string;   // also text for ntText
      Properties: TStringList;
      Children: TNodeList;
      NodeType: TNodeType;
      Position, TagLength, BlockLength: Integer;
      Data: Pointer;

      constructor Create(Collection: TCollection = nil); override;
      procedure Parse(const HTML: string); overload;
      procedure Parse(Stream: TStream); overload;
      destructor Destroy; override;
      function AsText: string;
      function GetPath: string;
      function FindByPath(S:string): TNode;
      function CountNodes: Integer;
      procedure Assign(Source: TPersistent); override;
      function MoveTo(ParentNode: TNode; Position: Integer): TNode;

    private
      procedure DoParse(Stream: TStream);
      function GetParent: TNode;
      function GetItem(Index: Integer): TNode;
      procedure SetItem(Index: Integer; Value: TNode);
      function GetCount: Integer;
    
    public
      property Items[Index: Integer]: TNode read GetItem write SetItem; default;
      property Count: Integer read GetCount;
      property Parent: TNode read GetParent;
      property Path: string read GetPath;
    end;
  
  TNodeList = class (TCollection)
    protected
      function GetItem(Index: Integer): TNode;
      procedure SetItem(Index: Integer; Value: TNode);
    public
      Owner: TNode;
      constructor Create(AOwner: TNode);
      function Find(Tag:string;Count:integer=1):TNode;
      property Items[Index: Integer]: TNode read GetItem write SetItem; default;
    end;

function ConvertEntities(S: string): string; {convert &xxx; entities}
function StripTags(const S: string): string;
function TrimWhitespace(S: string): string;

implementation

uses 
  SysUtils;

/////////////// UTILITY FUNCTIONS ////////////////

const
  Whitespace = [' ',#13,#10,#9];
  WordChars = ['a'..'z', 'A'..'Z', '0'..'9', '_', '-', ':'];

const
  Entities : array[1..23] of record Name, ASCII: string; end = (
    (Name: '&quot;';  ASCII: '"'),
    (Name: '&amp;';   ASCII: '&'),
    (Name: '&lt;';    ASCII: '<'),
    (Name: '&gt;';    ASCII: '>'),
    (Name: '&circ;';  ASCII: '?'),
    (Name: '&tilde;';   ASCII: '?'),
    (Name: '&ensp;';  ASCII: ' '),
    (Name: '&emsp;';  ASCII: ' '),
    (Name: '&thinsp;';  ASCII: ' '),
    (Name: '&ndash;';   ASCII: '-'),
    (Name: '&mdash;';   ASCII: '-'),
    (Name: '&lsquo;';   ASCII: ''''),
    (Name: '&rsquo;';   ASCII: ''''),
    (Name: '&sbquo;';   ASCII: ''''),
    (Name: '&ldquo;';   ASCII: '"'),
    (Name: '&rdquo;';   ASCII: '"'),
    (Name: '&bdquo;';   ASCII: '"'),
    (Name: '&dagger;';  ASCII: '+'),
    (Name: '&Dagger;';  ASCII: '+'),
    (Name: '&permil;';  ASCII: '%'),
    (Name: '&lsaquo;';  ASCII: '<'),
    (Name: '&rsaquo;';  ASCII: '>'),
    (Name: '&euro;';  ASCII: '?')
  );

function ConvertEntities(S: string): string; {convert &xxx; entities}
var 
  I, J: Integer; 
  T, R: string;
begin
  I:=1;
  while I < Length(S) do
  begin
    if S[I]='&' then
    begin
      T := Copy(S, I, 1000);
      T := LowerCase(Copy(T, 1, Pos(';',T)));
      Delete(S, I, Length(T));
      if (Length(T)>2) and (T[2]='#') then
        if (Length(T)>3) and (T[3]='x') then
          R:=WideChar(StrToIntDef('$'+Copy(T, 4, Length(T)-4), 33))
        else
          R:=Chr(StrToIntDef(Copy(T, 3, Length(T)-3), 0))
      else
      begin
        R:='';
        for J:=1 to High(Entities) do
          if T=Entities[J].Name then
            R:=Entities[J].ASCII;
      end;
      Insert(R, S, I);
    end;
    Inc(I);
  end;
  Result:=S;
end;

function TrimWhitespace(S: string): string;
begin
  while (Length(S)>1) and (S[1] in WhiteSpace) do
    Delete(S, 1, 1);
  while (Length(S)>1) and (S[Length(S)] in WhiteSpace) do
    Delete(S, Length(S), 1);
  Result:=S;
end;

function StripTags(const S: string): string;
var
  Temp: TNode;
begin
  Temp:=TNode.Create;
  Temp.Parse(S);
  Result:=Temp.AsText;
  Temp.Free;
end;

////////////// TNodeList ////////////////

constructor TNodeList.Create(AOwner: TNode);
begin
  inherited Create(TNode);
  Owner:=AOwner;
end;

function TNodeList.Find(Tag: string; Count: Integer = 1) : TNode;
var i:integer;
begin
  for i:=0 to Self.Count-1 do
    if UpperCase(TNode(Items[i]).Tag) = UpperCase(Tag) then
    begin
      Dec(Count);
      if Count=0 then
      begin
        Result:=TNode(Items[i]);
        Exit
      end;
    end;
  Result:=nil;
end;

function TNodeList.GetItem(Index: Integer): TNode;
begin
  Result := inherited GetItem(Index) as TNode;
end;

procedure TNodeList.SetItem(Index: Integer; Value: TNode);
begin
  inherited SetItem(Index, Value);
end;

////////////// TNode ////////////////

constructor TNode.Create(Collection: TCollection = nil);
begin
  inherited Create(Collection);
  Properties:=TStringList.Create;
  Children:=TNodeList.Create(Self);
end;

destructor TNode.Destroy;
begin
  Properties.Free;
  Children.Free;
  inherited Destroy;
end;

procedure TNode.Parse(const HTML: string);
var
  MS: TMemoryStream;
  C: Char;
begin
  MS:=TMemoryStream.Create;
  C := ' ';
  MS.WriteBuffer(C, 1);
  MS.WriteBuffer(HTML[1], Length(HTML));
  MS.Position:=0;
  Parse(MS);
end;

procedure TNode.Parse(Stream: TStream); 
var
  N: TNode;
begin
  NodeType := ntRoot;
  repeat
    N := TNode(Children.Add);
    N.DoParse(Stream);
  until N.NodeType in [ntEnd, ntError];
end;

function TNode.GetItem(Index: Integer): TNode;
begin
  Result := Children.GetItem(Index);
end;

procedure TNode.SetItem(Index: Integer; Value: TNode);
begin
  Children.SetItem(Index, Value);
end;

function TNode.GetCount: Integer;
begin
  Result := Children.Count;
end;

function TNode.AsText:string;
var
  S, T: string;
  I: Integer;
begin
  if NodeType=ntText then
  begin
    Result:=ConvertEntities(Tag);
    Exit
  end;
  S:='';
  for I:=0 to Children.Count-1 do
    S := S + Children.Items[i].AsText;
  T := UpperCase(Tag);
  if T='A' then
  begin
    if (Properties.Values['HREF']<>'')and(Properties.Values['HREF']<>S) then
      Result:='<'+Properties.Values['HREF']+'> '+s
    else
      Result:=S;
  end
  else
  if T='B' then
    Result:='*'+S+'*'
  else
  if T='I' then
    Result:='/'+S+'/'
  else
  if T='U' then
    Result:='_'+S+'_'
  else
  if T='BR' then
    Result:=#13#10+S
  else
  if T='P' then
    Result:=#13#10'  '+S
  else
  {if T[1]='"' then
  begin
    t:=Copy(Tag,2,Length(Tag)-2);
    while Copy(T, 1, 1)=' ' do
      Delete(T, 1, 1);
    while Copy(T, Length(S),1)=' ' do
      Delete(T,length(s),1);
    Result:=ConvertEntities(t);
  end
  else}
    Result:=S;
end;

function TNode.GetPath: string;
var 
  S: string;
  I, N: Integer;
begin
  N := 0;
  if Collection<>nil then
  begin
    for i:=0 to Collection.Count-1 do
    begin
      if TNode(Collection.Items[i]).Tag=Tag then
        Inc(N);
      if Collection.Items[i]=Self then
        Break;
    end;
  end;
  S:=Tag;
  if N <> 1 then
    S := IntToStr(N)+' '+s;
  if Collection=nil then
    S := ''
  else
    S := TNodeList(Collection).Owner.Path+'\'+s;
  Result := S;
end;

function TNode.FindByPath(S: string) : TNode;
var
  E: TNode;
  N: Integer; 
  T: string;
begin
  if Copy(S, 1, 1)='\' then Delete(S, 1, 1);
  S:=S+'\';
  E:=Self;
  while S<>'' do
  begin
    N:=1;
    T:=Copy(S, 1, Pos('\', S)-1);
    Delete(S, 1, Pos('\', S));
    if(Pos(' ', T)<>0) and TryStrToInt(Copy(T, 1, Pos(' ', T)-1), N) then
      Delete(T, 1, Pos(' ', T));
    E:=E.Children.Find(T, N);
    if E=nil then Break;
  end;
  Result:=e;
end;

function TNode.GetParent: TNode;
begin
  if Collection=nil then
    Result:=nil
  else
    Result:=TNodeList(Collection).Owner;
end;

function TNode.CountNodes: Integer;
var
  I: Integer;
begin
  Result := Children.Count;
  for I:=0 to Children.Count-1 do
    Result := Result + Children[I].CountNodes;
end;

procedure TNode.Assign(Source: TPersistent);
begin
  if Source is TNode then
  begin
    Tag := TNode(Source).Tag;
    Properties.Assign(TNode(Source).Properties);
    Children.Assign(TNode(Source).Children);
    NodeType := TNode(Source).NodeType;
    Position := TNode(Source).Position;
    TagLength := TNode(Source).TagLength;
    BlockLength := TNode(Source).BlockLength;
    Data := TNode(Source).Data;
    Exit;
  end;
  inherited Assign(Source);
end;

// moves the contents of this instance to another parent node, deletes the current
function TNode.MoveTo(ParentNode: TNode; Position: Integer): TNode;
var
  NewNode: TNode;
begin
  NewNode := TNode(ParentNode.Children.Insert(Position));
  NewNode.Assign(Self);
  Result := NewNode;
  Free;
end;


const
  // these tags are usually empty
  EmptyTags : array[1..11] of string = (
    'BR',
    'AREA',
    'LINK',
    'IMG',
    'PARAM',
    'HR',
    'INPUT',
    'COL',
    'BASE',
    'META',
    'FRAME');
  
  // these tags aren't always closed when they follow each other
  RepeatableTags : array[1..4] of string = (
    'P',
    'TR',
    'TD',
    'LI');

procedure TNode.DoParse(Stream: TStream);
var
  C, QuoteChar: Char;
  PropertyName, PropertyValue, S: string;
  Child, N: TNode;
  ClosedTag: Boolean;
  Found: Boolean;
  I: Integer;
begin
  try
    Position := Stream.Position;
    TagLength := 0;
    BlockLength := 0;

    repeat
      Stream.ReadBuffer(C, 1);
    until not (C in Whitespace);

    if C <> '<' then
    begin     // create a text node
      S := '';
      repeat
        S := S + C;
        try
          Stream.ReadBuffer(C, 1);
        except
          Break;
        end;
      until C='<';
      if C='<' then
        Stream.Position := Stream.Position-1;

      NodeType := ntText;
      Tag := TrimWhitespace(S);
      TagLength := Stream.Position - Position;
      BlockLength := Stream.Position - Position;
    end
    else
    begin
      NodeType := ntTag;
      S := '';
      Stream.ReadBuffer(C, 1);
      if C='!' then
      begin
        Stream.ReadBuffer(C, 1);
        if C='-' then
        begin
          Stream.ReadBuffer(C, 1);
          if C='-' then      // <!--....-->
          begin
            S := '';
            repeat
              Stream.ReadBuffer(C, 1);
              S := S + C;
            until Copy(S, Length(S)-2, 3)='-->';
            Tag := Copy(S, 1, Length(S)-3);
            NodeType := ntComment;
            TagLength := Stream.Position - Position;
            BlockLength := Stream.Position - Position;
            Exit;
          end
          else
            raise Exception.Create(C+' was not expected here (expecting -).');
        end
        else
        if C='[' then
        begin              // <![CDATA[.....]]>
          S := '';
          repeat
            Stream.ReadBuffer(C, 1);
            S := S + C;
          until C='[';
          if S<>'CDATA[' then
            raise Exception.Create(S + ' was not expected here (expecting CDATA[).');
          S := '';
          repeat
            Stream.ReadBuffer(C, 1);
            S := S + C;
          until (Length(S)>=3) and (Copy(S, Length(S)-2, 3)=']]>');
          Tag := Copy(S, 1, Length(S)-3);
          NodeType := ntCData;
          TagLength := Stream.Position - Position;
          BlockLength := Stream.Position - Position;
          Exit;
        end
        else
        begin              // <!.....>
          S := '';
          repeat
            S := S + C;
            Stream.ReadBuffer(C, 1);
          until C='>';
          Tag := Copy(S, 1, Length(S)-1);
          NodeType := ntMeta;                     // what's the proper name for this entity...?
          TagLength := Stream.Position - Position;
          BlockLength := Stream.Position - Position;
          Exit;
        end;
      end
      else
      if C='?' then
      begin                // <?.....?>
        S := '';
        repeat
          Stream.ReadBuffer(C, 1);
          S := S + C;
        until Copy(S, Length(S)-1, 2)='?>';
        Tag := Copy(S, 1, Length(S)-2);
        NodeType := ntXML;    // or is it just some PHP?
        TagLength := Stream.Position - Position;
        BlockLength := Stream.Position - Position;
        Exit;
      end;

      repeat
        S := S + UpCase(C);
        Stream.ReadBuffer(C, 1);
      until not (C in WordChars);

      if S[1] = '/' then
      begin
        while C in Whitespace do
          Stream.ReadBuffer(C, 1);
        if C<>'>' then
          raise Exception.Create(C+' was not expected here (expecting >).');
        Tag := Copy(S, 2, Length(S)-1);
        NodeType := ntCloseTag;
        TagLength := Stream.Position - Position;
        BlockLength := Stream.Position - Position;
        Exit;
      end;

      Tag := S;
      ClosedTag := False;

      for I := 1 to High(EmptyTags) do
        if Tag = EmptyTags[I] then
          ClosedTag := True;
      
      repeat
        while C in Whitespace do
          Stream.ReadBuffer(C, 1);

        case C of
          '/':
          begin
            Stream.ReadBuffer(C, 1);
            if C<>'>' then
              raise Exception.Create('/'+C+' was not expected here (expecting > after /).');
            ClosedTag := True;
            Break;
          end;
          '>':
            Break;
          else
          begin
            if not (C in WordChars) then
              raise Exception.Create(C+' was not expected here.');
            PropertyName := '';
            repeat
              PropertyName := PropertyName + C;
              Stream.ReadBuffer(C, 1);
            until not (C in WordChars);

            while C in Whitespace do
              Stream.ReadBuffer(C, 1);
            
            if C = '=' then
            begin
              Stream.ReadBuffer(C, 1);
              while (C<>'>') and (C in Whitespace) do
                Stream.ReadBuffer(C, 1);
              PropertyValue := '';
              if C<>'>' then
              begin
                PropertyValue := '';
                if C in ['''', '"'] then
                begin
                  QuoteChar := C;
                  Stream.ReadBuffer(C, 1);
                  while C<>QuoteChar do
                  begin
                    PropertyValue := PropertyValue + C;
                    Stream.ReadBuffer(C, 1);
                  end;
                  Stream.ReadBuffer(C, 1);
                end
                else
                begin
                  repeat
                    PropertyValue := PropertyValue + C;
                    Stream.ReadBuffer(C, 1);
                  until C in (Whitespace + ['>']);
                  {if PropertyValue[Length(PropertyValue)]='/' then
                  begin
                    PropertyValue := Copy(PropertyValue, 1, Length(PropertyValue)-1);
                    C := '/';
                    Stream.Position := Stream.Position - 1;
                  end;}
                end;
              end;
              Properties.Add(LowerCase(PropertyName)+'='+PropertyValue);
            end
            else
            if C in (WordChars + ['/', '>']) then
            begin
              Properties.Add(LowerCase(PropertyName));
              Continue;
            end
            else
              raise Exception.Create(C+' was not expected here (property '+S+').');
          end;
        end;
      until False;
      
      TagLength := Stream.Position - Position;

      if ClosedTag then
      begin
        BlockLength := Stream.Position - Position;
        Exit;
      end;

      repeat
        Child := TNode(Children.Add);
        Child.DoParse(Stream);
        if Child.NodeType=ntCloseTag then
        begin
          if Child.Tag = Tag then  // closing our own tag
          begin
            Children.Delete(Child.Index);
            BlockLength := Stream.Position - Position;
            Exit
          end;

          Found := False;                     // in EmptyTags?
          for I := 1 to High(EmptyTags) do
            if Child.Tag = EmptyTags[I] then
              Found := True;
          if Found then                       // if so, just ignore the close (closing these tags is optional)
          begin
            Children.Delete(Child.Index);
            Continue;
          end;
          
          Found := False;
          N := Parent;
          while N<>nil do
          begin
            if N.Tag = Child.Tag then
            begin
              Found := True;
              Break
            end;
            N := N.Parent;
          end;
          if Found then
          begin
            Stream.Position := Child.Position;
            Child.NodeType := ntMissedCloseTag;
            BlockLength := Stream.Position - Position;
            Exit;
          end;
          // unmatched closing tag found, ignoring
        end;

        if (Child.NodeType = ntTag) and (Child.Tag = Tag) then
        begin
          Found := False;
          for I := 1 to High(RepeatableTags) do
            if Child.Tag = RepeatableTags[I] then
              Found := True;

          if Found then
          begin
            //Stream.Position := Child.Position;
            //Child.Free;
            BlockLength := Child.Position - Position;
            N := Self;
            while N.Parent<>nil do
            begin
              if N.Parent.Tag <> Child.Tag then
              begin
                Child.MoveTo(N.Parent, N.Index+1);
                Break
              end;
              N := N.Parent;
            end;
            Exit;
          end;
        end;
      until Stream.Position = Stream.Size;
    end;
  except
    on E: EAbort do
      NodeType := ntEnd;
    on E: EReadError do
      NodeType := ntEnd;
    on E: Exception do
    begin
      NodeType := ntError;
      Tag := E.Message;
      TagLength := Stream.Position - Position;
      BlockLength := Stream.Position - Position;
    end;
  end;
end;

end.
