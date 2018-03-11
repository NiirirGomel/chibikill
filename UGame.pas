unit UGame;

interface

uses
  Windows,
  Messages,
  MMSystem,
  SysUtils,
  UTex,  
  UTimer,
  OpenGL;

const
  cLeft = 0;
  cRight = 1;
  cUp = 2;
  cDown = 3;
  format = '.jpg';

  CurrentFrame = 1;

type

  TglVertex = record
    x,y,z: GLfloat;
    end;

  TglFace = array [0..2] of GLint;

  TglRect = array [0..3] of GLfloat;

  PglVertexAr = ^TglVertexAr;
  TglVertexAr = array [Word] of TglVertex;

  PglFaceAr = ^TglFaceAr;
  TglFaceAr = array [Word] of TglFace;

  TglMesh = record
    Verteces: PglVertexAr;
    Faces: PglFaceAr;
    Rect: TglRect;
    end;

  TglMeshAr = array of TglMesh;

  TTexture = record
    Image : Cardinal;
    FaceCount: Word;
    Verteces : PglVertexAr;
    Faces : PglFaceAr;
    end;

  TChar_id = (Hero_id,Shtain_id,Bat_id);
  TStatus = (stand,walk,strike,hit,parry,wait,dead,hide);

  PModel = ^TModel;

  TModel = record
    FaceCount: Word;
    Meshes: TglMeshAr;
    Size: GLfloat;
    Center: Cardinal;
    Texture: TTexture;
  end;

    // Существа
  PPlayer = ^TPlayer;
{}  PPlayers = ^TPlayers;
  PMonsters = ^TMonsters;
  TChar = class
    Name: string[16];
    Kills: Cardinal;
    Model: PModel;
    Status: TStatus;
    Direct: Boolean;
    fly: GLfloat;
    PrevDirect: Boolean;  // Для приятного управления(запом. пред. напр.)
    MusicEnabled: Boolean;  // Пришлось дублировать в Unit

    Health,
    Damage: Byte;
    Step,
    StepHit,
    Weight: GLfloat;
    Speed: Integer;
    Wait_time : Integer;
    Timer: cTimer;
    GameTimer: cTimer;

    PosX,                       // Основные переменные для перемещения
    PosY,
    PosZ,
    ShiftX,
    ShiftY,
    ShiftZ: GLfloat;

    Stand_sf, Stand_ef,
    Walk_sf, Walk_ef,
    Hit_sf, Hit_ef,
    Parry_sf, Parry_ef,
    Dead_sf, Dead_ef: Cardinal;
    Hit_track : string;
    Dead_track : string;
    Strike_sf, Strike_ef: array of Cardinal;
    Strike_hf: array of array of Cardinal;
    Strike_track : array of string;
    //Strike_Rect: array of array of TglRect;
    cStrike: Byte;
    StrikeDist: Single;

    sFrame,cFrame,eFrame: Cardinal;

  public
    procedure ShiftCalc;
    procedure Draw();
    procedure SetStatus(NewStatus: TStatus);
    procedure SetDirect(Turn: Boolean);
    procedure SetSpeed(NewSpeed: Integer);

    procedure StartStand;
    procedure StartWalk;
    procedure StartStrike(n: byte = 0);
    function  StartHit(dam : Byte) : Boolean;
    procedure StartParry;
    procedure StartWait(fps : integer);
    procedure StartDead;

    procedure pStand;
    procedure pWalk;
    procedure pStrike(Player: PPlayer; Monsters: PMonsters = nil; Monster: PPlayer = nil);
    procedure pHit;
    procedure pParry;
    procedure pWait;
    procedure pDead;

    constructor Create(link: PModel; Char_id: TChar_id);
    destructor Destroy();
    end;

    // Персонаж
  TPlayer = TChar;
  TPlayers = array of TChar;

    // Монстры
  TMonsters = array of TChar;

    // Локация
  TLocation = class
    Name: string[16];
    FaceCount: Word;
    Mesh: TglMesh;
    Size: GLfloat;
    Texture: TTexture;

  public
    procedure Load(Patch: string);
    procedure Draw{(Frame: longint)};
    constructor Create;
    destructor Destroy;
    end;

  function LoadModel(Patch: string) : TModel;
  procedure DestroyModel(Model: TModel);

  function Intersection(Char1, Char2: PPlayer; atk: Byte = 255; hit: Byte = 0): Boolean;
  function MyMedia(Comand: string; Path: string; Param: string = '') : string;

var
  sbReturn : array [1..64] of Char;

implementation

procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;
procedure glDeleteTextures (n: GLsizei; const textureNames: GLuint); stdcall; external opengl32;


{------------------------------------------------------------}
{  Исполнение медиафайлов средствами MCI в упрощённой форме  }
{------------------------------------------------------------}
function GetShortName(sLongName: string): string;
var
  sShortName:    string;
  nShortNameLen: Integer;
begin
  SetLength(sShortName, MAX_PATH);
  nShortNameLen := GetShortPathName(PChar(sLongName), PChar(sShortName), MAX_PATH - 1);
  if (0 = nShortNameLen) then
  begin
    // handle errors...
  end;
  SetLength(sShortName, nShortNameLen);
  Result := sShortName;
end;

function MyMedia(Comand: string; Path: string; Param: string = '') : string;
begin
  MCISendString(PChar(Comand+' '+GetShortName(Path)+Param),@sbReturn,64,0);
  result := trim(sbReturn);
end;

function Intersection(Char1, Char2: PPlayer; atk: Byte = 255; hit: Byte = 0): Boolean;
begin
  {if atk = 255 then}

  
    if (Char1.Model.Meshes[Char1.cFrame].Rect[cUP]*Char1.Model.Size+Char1.PosY >= Char2.Model.Meshes[Char2.cFrame].Rect[cDOWN]*Char2.Model.Size+Char2.PosY)    and
       (Char1.Model.Meshes[Char1.cFrame].Rect[cDOWN]*Char1.Model.Size+Char1.PosY <= Char2.Model.Meshes[Char2.cFrame].Rect[cUP]*Char2.Model.Size+Char2.PosY)    then
      if char1.Direct and Char2.Direct then
      begin
        if (Char1.Model.Meshes[Char1.cFrame].Rect[cRIGHT]*Char1.Model.Size+Char1.PosX - Char1.ShiftX <= Char2.Model.Meshes[Char2.cFrame].Rect[cLEFT]*Char2.Model.Size+Char2.PosX - Char2.ShiftX) and
           (Char1.Model.Meshes[Char1.cFrame].Rect[cLEFT]*Char1.Model.Size+Char1.PosX - Char1.ShiftX >= Char2.Model.Meshes[Char2.cFrame].Rect[cRIGHT]*Char2.Model.Size+Char2.PosX - Char2.ShiftX) then
           Result := True
        else
           Result := False;
      end else
      if Char1.Direct then
      begin
        if (Char1.Model.Meshes[Char1.cFrame].Rect[cRIGHT]*Char1.Model.Size+Char1.PosX - Char1.ShiftX <= Char2.Model.Meshes[Char2.cFrame].Rect[cLEFT]*Char2.Model.Size+Char2.PosX + Char1.ShiftX) and
           (Char1.Model.Meshes[Char1.cFrame].Rect[cLEFT]*Char1.Model.Size+Char1.PosX - Char1.ShiftX >= Char2.Model.Meshes[Char2.cFrame].Rect[cRIGHT]*Char2.Model.Size+Char2.PosX + Char1.ShiftX) then
           Result := True
        else
           Result := False;
      end else
      if Char2.Direct then
      begin
        if (Char1.Model.Meshes[Char1.cFrame].Rect[cRIGHT]*Char1.Model.Size+Char1.PosX + Char1.ShiftX <= Char2.Model.Meshes[Char2.cFrame].Rect[cLEFT]*Char2.Model.Size+Char2.PosX - Char1.ShiftX) and
           (Char1.Model.Meshes[Char1.cFrame].Rect[cLEFT]*Char1.Model.Size+Char1.PosX + Char1.ShiftX >= Char2.Model.Meshes[Char2.cFrame].Rect[cRIGHT]*Char2.Model.Size+Char2.PosX - Char1.ShiftX) then
           Result := True
        else
           Result := False;
      end else
      begin
        if (Char1.Model.Meshes[Char1.cFrame].Rect[cRIGHT]*Char1.Model.Size+Char1.PosX + Char1.ShiftX <= Char2.Model.Meshes[Char2.cFrame].Rect[cLEFT]*Char2.Model.Size+Char2.PosX + Char1.ShiftX) and
           (Char1.Model.Meshes[Char1.cFrame].Rect[cLEFT]*Char1.Model.Size+Char1.PosX + Char1.ShiftX >= Char2.Model.Meshes[Char2.cFrame].Rect[cRIGHT]*Char2.Model.Size+Char2.PosX + Char1.ShiftX) then
           Result := True
        else
           Result := False;
      end;


  {else
  begin
    if (P1.AtackArea[tkUP]+P1.PosY+P1.ShiftY >= P2.Meshes[P2.CurrentFrame].Rect[tkDOWN]*P2.fExtend+P2.PosY+P2.ShiftY)    and
       (P1.AtackArea[tkDOWN]+P1.PosY+P1.ShiftY <= P2.Meshes[P2.CurrentFrame].Rect[tkUP]*P2.fExtend+P2.PosY+P2.ShiftY)    and
       (P1.AtackArea[tkRIGHT]+P1.PosX+P1.ShiftX <= P2.Meshes[P2.CurrentFrame].Rect[tkLEFT]*P2.fExtend+P2.PosX+P2.ShiftX) and
       (P1.AtackArea[tkLEFT]+P1.PosX+P1.ShiftX >= P2.Meshes[P2.CurrentFrame].Rect[tkRIGHT]*P2.fExtend+P2.PosX+P2.ShiftX)
    then
      Result := True
    else
      Result := False;
  end; }
end;

{ TChar }

constructor TChar.Create(link: PModel; Char_id: TChar_id);
begin
  Randomize; // Что бы было веселей

//~Установка параметров на начальные~
  Kills := 0;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Model := link;
  case Char_id of
  Hero_id:
    begin
      Health := 10;
      Speed := 1;
      Damage := 2;
      Weight := 1;
      Model.Center := 479;
      Step := 0.04;
      Wait_time := 7;

      Stand_sf:=1; Stand_ef:=80;
      Walk_sf:=164; Walk_ef:=225;

      SetLength(Strike_sf,2);
        Strike_sf[0]:=81;
        Strike_sf[1]:=105;
      SetLength(Strike_ef,2);
        Strike_ef[0]:=140;   
        Strike_ef[1]:=140;
      SetLength(Strike_hf,2,1);
        Strike_hf[0][0]:=106;
        Strike_hf[1][0]:=106;    
      SetLength(Strike_track,2);
        Strike_track[0]:='data/music/Sword Whip.mp3';
        Strike_track[1]:='data/music/Sword Whip.mp3';

      Hit_sf:=226; Hit_ef:=226;
      Hit_track:='data/music/jab.mp3';
      Parry_sf:=227; Parry_ef:=227;
      Dead_sf:=228; Dead_ef:=244;

      Timer := cTimer.Create(1);
      GameTimer := cTimer.Create(60);
    end;
  Shtain_id:
    begin
      Health := 4 + Random(3);
      Speed := 1;
      Damage := 1 + Random(1);
      Weight := 1.5 + Random(5)/10;
      Model.Center := 411;
      Step := 0.02 + Random(10)/1000;
      Wait_time := 2;

      Stand_sf:=1; Stand_ef:=80;
      Walk_sf:=81; Walk_ef:=160;

      SetLength(Strike_sf,1);
        Strike_sf[0]:=161;
      SetLength(Strike_ef,1);
        Strike_ef[0]:=200;
      SetLength(Strike_hf,1,1);
        Strike_hf[0][0]:=190;
      StrikeDist:=1;

      Hit_sf:=201; Hit_ef:=201;
      Parry_sf:=0; Parry_ef:=0;
      Dead_sf:=202; Dead_ef:=230;
      Dead_track:='data/music/velociraptor.mp3';

      Timer := cTimer.Create(1);
      GameTimer := cTimer.Create(60);
    end;
  Bat_id:
    begin
      Health := 2 + Random(3);
      Speed := 1;
      Damage := 2 + Random(2);
      Weight := 3 + Random(10)/10;
      Model.Center := 57;
      Step := 0.03 + Random(10)/1000;
      fly := 1.0 + Random(50)/100;
      Wait_time := 3;

      Stand_sf:=1; Stand_ef:=40;
      Walk_sf:=1; Walk_ef:=40;

      SetLength(Strike_sf,1);
        Strike_sf[0]:=41;
      SetLength(Strike_ef,1);
        Strike_ef[0]:=85;
      SetLength(Strike_hf,1,1);
        Strike_hf[0][0]:=50;
      StrikeDist:=0.7;

      Hit_sf:=86; Hit_ef:=86;
      Parry_sf:=0; Parry_ef:=0; 
      Dead_sf:=87; Dead_ef:=100;
      Dead_track:='data/music/bone_crush.mp3';

      Timer := cTimer.Create(1);    
      GameTimer := cTimer.Create(60);

    end;
  end;
  
  StartStand;

end;

procedure DestroyModel(Model: TModel);
begin
  Model.FaceCount:=0;
  SetLength(Model.Meshes,0);
  Model.Size:=0;
  glDeleteTextures(1, Model.Texture.Image);
end;
    
function LoadModel(Patch: string) : TModel;

  function Max(v1,v2:GLfloat): GLfloat;
  begin
    if v1 >= v2 then Result := v1
    else Result := v2;
  end;

var
  F : TextFile;
  S : string;
  i, j : Word;
  M_num,
  VertexCount : Word;
  Vertex : TglVertex;
  Face : TglFace;
  MaxVertex: GLfloat; // Для масщтаба
  Model: TModel;
begin

  AssignFile(F,Patch + '.gms');
  Reset(F);

  Readln(f,S);  // Пропускаем New object:

with Model do
begin

  M_num := 0;
  repeat
    Readln(f,S); // Пропускаем TriMesh()
    Readln(f,S); // Пропускаем numverts numfaces

    Readln(f,VertexCount,FaceCount);
    SetLength(Meshes,M_num + 1);
    GetMem(Meshes[M_num].Verteces,VertexCount*SizeOf(TglVertex));
    GetMem(Meshes[M_num].Faces,FaceCount*SizeOf(TglFace));

    Readln(f,S); // Пропускаем Mesh vertices:
    for i := 0 to VertexCount - 1 do
    begin
      Readln(f,Vertex.z,Vertex.x,Vertex.y);
      Meshes[M_num].Verteces[i] := Vertex;
    end;
    Readln(f,S); // Пропускаем end vertices

    Readln(f,S); // Пропускаем Mesh faces:
    for i := 0 to FaceCount - 1 do
    begin
      Readln(f,Face[0],Face[1],Face[2]);
      Face[0] := Face[0] - 1;
      Face[1] := Face[1] - 1;
      Face[2] := Face[2] - 1;
      Meshes[M_num].Faces[i] := Face;
    end;

    Readln(f,S); // Пропускаем end faces
    Readln(f,S); // Пропускаем end mesh
    Readln(f,S); // Тут либо New obgect или New Texture:
    M_num := M_num + 1; // Следующая сетка.
  until S = 'New Texture:'; // Начинаем считывать текстуру.

//Масштабирование
  begin
    MaxVertex := 0;
    for i:=0 to VertexCount - 1 do
    begin
      MaxVertex := Max(MaxVertex,Meshes[0].Verteces[i].x);
      MaxVertex := Max(MaxVertex,Meshes[0].Verteces[i].y);
      MaxVertex := Max(MaxVertex,Meshes[0].Verteces[i].z);
    end;
    Size := 1 / MaxVertex{ * Масштаб к одному};
  end;

//Находим размеры
  begin
    for j:=0 to M_num - 1 do
    begin
      Meshes[j].Rect[cDown] := Meshes[0].Verteces[0].y;
      Meshes[j].Rect[cUp] := Meshes[0].Verteces[0].y;
      Meshes[j].Rect[cLeft] := Meshes[0].Verteces[0].x;
      Meshes[j].Rect[cRight] := Meshes[0].Verteces[0].x;
        for i:=0 to VertexCount do
        begin
          if Meshes[j].Rect[cDown] > Meshes[j].Verteces[i].y then Meshes[j].Rect[cDown] := Meshes[j].Verteces[i].y;
          if Meshes[j].Rect[cUp] < Meshes[j].Verteces[i].y then Meshes[j].Rect[cUp] := Meshes[j].Verteces[i].y;
          if Meshes[j].Rect[cLeft] < Meshes[j].Verteces[i].x then Meshes[j].Rect[cLeft] := Meshes[j].Verteces[i].x;
          if Meshes[j].Rect[cRight] > Meshes[j].Verteces[i].x then Meshes[j].Rect[cRight] := Meshes[j].Verteces[i].x;
        end;
    end;
  end;

//Теперь грузим координаты текстур
  Readln(f,S); //Пропускаем numtverts numtvfaces

  Readln(f,VertexCount,Texture.FaceCount);
  GetMem(Texture.Verteces,VertexCount*SizeOf(TglVertex));
  GetMem(Texture.Faces,Texture.FaceCount*SizeOf(TglFace));

  Readln(f,S); // Пропускаем Texture vertices:
  for i := 0 to VertexCount - 1 do
  begin
    Readln(f,Vertex.x,Vertex.y,Vertex.z);
    Vertex.y := 1 - Vertex.y;
    Texture.Verteces[i] := Vertex;
  end;
  Readln(f,S); // Пропускаем end texture vertices

  Readln(f,S); // Пропускаем Texture faces:
  for i := 0 to Texture.FaceCount - 1 do
  begin
    Readln(f,Face[0],Face[1],Face[2]);
    Face[0] := Face[0] - 1;
    Face[1] := Face[1] - 1;
    Face[2] := Face[2] - 1;
    Texture.Faces[i] := Face;
  end;

  CloseFile(f);

//Грузим картинку
  LoadTexture(Patch + format,Texture.Image,False);
end;
  Result := Model;
end;

procedure TChar.SetStatus(NewStatus: TStatus);
begin
  Status := NewStatus;
end;

procedure TChar.SetDirect(Turn: Boolean);
begin
  Direct := Turn;
end;

procedure TChar.ShiftCalc;
begin
  if Model.Center <> 0 then
  begin
    ShiftX := (-Model.meshes[cFrame].Verteces[Model.Center].x*Model.Size);
    ShiftZ := (-Model.meshes[cFrame].Verteces[Model.Center].z*Model.Size);
  end;
  ShiftY := (-Model.meshes[cFrame].Rect[cDown]*Model.Size);
  if fly > 0 then
  begin   
    ShiftY := (-Model.meshes[cFrame].Verteces[Model.Center].y*Model.Size);
    ShiftY := ShiftY + fly;
  end;
end;

procedure TChar.Draw;
var
  i : Word;
begin
  glBindTexture(GL_TEXTURE_2D,Model.Texture.Image);
  glBegin(GL_TRIANGLES);
  for i:=0 to Model.FaceCount - 1 do
  begin
    glTexCoord2fv(@Model.Texture.Verteces[Model.Texture.Faces[i][0]]);  glVertex3fv(@Model.Meshes[cFrame].Verteces[Model.Meshes[cFrame].Faces[i][0]]);
    glTexCoord2fv(@Model.Texture.Verteces[Model.Texture.Faces[i][1]]);  glVertex3fv(@Model.Meshes[cFrame].Verteces[Model.Meshes[cFrame].Faces[i][1]]);
    glTexCoord2fv(@Model.Texture.Verteces[Model.Texture.Faces[i][2]]);  glVertex3fv(@Model.Meshes[cFrame].Verteces[Model.Meshes[cFrame].Faces[i][2]]);
  end;
  glEnd;
end;

destructor TChar.Destroy;
begin
  Timer.Free;
end;

procedure TChar.pHit;
begin
  if cFrame < eFrame then Inc(cFrame);
  if Direct then
    PosX := PosX - StepHit
  else             
    PosX := PosX + StepHit;
  if Timer.Run or (StepHit <= 0) then
    if Wait_time <> 0 then
      StartWait(Wait_time)
    else
      StartStand;
end;

procedure TChar.pParry;
begin
  if cFrame < eFrame then Inc(cFrame);
  if Timer.Run then StartWait(3);
end;

procedure TChar.pStand;
begin
  Inc(cFrame);
  if cFrame > eFrame then cFrame := sFrame + (cFrame-1 - eFrame);
end;

function TChar.StartHit(dam: Byte) : Boolean;
begin
  if Status = parry then
  begin
    StartStrike(1);
  end else
  begin
    if (Health - dam) > 0 then Health := Health - dam
    else
    begin
      Health := 0;
      StartDead;
      Result := True;
      Exit;
    end;
    if MusicEnabled and (Length(Hit_track) > 0) then
    begin
      MyMedia('Stop',Hit_track);
      MyMedia('Play',Hit_track);
    end;
    if Status = hit then
    begin
      StepHit := StepHit + Weight/100;
      cFrame := Hit_sf;
    end else
    begin
      StepHit := Weight/100;
      sFrame := Hit_sf; cFrame := Hit_sf; eFrame := Hit_ef;
      Status := hit;
    end;
    Timer.SetPause(Wait_time);
    Timer.Run;
  end;
  Result := False;
end;

procedure TChar.StartParry;
begin
  sFrame := Parry_sf; cFrame := Parry_sf; eFrame := Parry_ef;
  Status := parry;
  Timer.SetPause(3);
  Timer.Run;
end;

procedure TChar.StartStand;
begin
  sFrame := Stand_sf; cFrame := Stand_sf; eFrame := Stand_ef;
  Status := stand;
end;

procedure TChar.StartStrike(n: byte = 0);
begin
  if MusicEnabled and (Length(Strike_track)-1 >= n) then
  begin
    MyMedia('Stop',Strike_track[n]);
    MyMedia('Play',Strike_track[n]);
  end;
  sFrame := Strike_sf[n]; cFrame := Strike_sf[n]; eFrame := Strike_ef[n];
  cStrike := n;
  Status := strike;
end;

procedure TChar.StartWait(fps: Integer);
begin
  Timer.SetPause(fps);
  Timer.Run;
  Status := wait;
end;

procedure TChar.StartWalk;
begin
  sFrame := Walk_sf; cFrame := Walk_sf; eFrame := Walk_ef;
  Status := walk;
end;

procedure TChar.pStrike(Player: PPlayer; Monsters: PMonsters = nil; Monster: PPlayer = nil);
var
  i,j: Integer;
begin

  for i:=0 to Length(Strike_hf[cStrike]) - 1 do // Повторять количество хитов в ударе
    if cFrame = Strike_hf[cStrike][i] then      // Если наступил момент хита
      if Monsters <> nil then                   // И бьёт человек то
      begin
        for j:=0 to (Length(Monsters^)-1) do     // Всех монстров 
        if (Monsters^[j].Status <> hide) and (Monsters^[j].Status <> dead) then
          if Intersection(@Player^,@Monsters^[j],cStrike,i) then // Если попадают под отаку
            if Monsters^[j].Status <> dead then                   // И он не трупак
            begin
              Monsters^[j].Direct := not Player^.Direct;
              if Monsters^[j].StartHit(Damage) then Inc(Player^.Kills);      // Бить
            end;
   (*     for j:=0 to (0{Length(Players)-1}) do     // И всех играков
          if Intersection(@Player^,@Player^,cStrike,i) then // Если попадают под отаку
            {Players^[j]}Player^.StartHit(Damage);       // Бить    
   *)   end else                                  // А если бьёт монстр то
        for j:=0 to 0 do     // Всех играков
        if (Player^.Status <> hide) and (Player^.Status <> dead) then
          if Intersection(@Monster^,@Player^,cStrike,i) then // Если попадают под отаку
            if Player^.Status <> dead then                   // И он не трупак
            begin
              Player^.Direct := not Monster^.Direct;
              Player^.StartHit(Damage);       // Бить
            end;

  Inc(cFrame);
  if cFrame >= eFrame then
  begin
    cFrame := eFrame;
    if Wait_time <> 0 then
      StartWait(Wait_time)
    else
      StartStand;

  end;
end;

procedure TChar.pWait;
begin
  if Timer.Run then StartStand;
end;

procedure TChar.pWalk;
begin
  if Direct then
    PosX := PosX + Step
  else
    PosX := PosX - Step;
  Inc(cFrame);
  if cFrame > eFrame then cFrame := sFrame + (cFrame-1 - eFrame);
end;

procedure TChar.SetSpeed(NewSpeed: Integer);
begin
  GameTimer.SetPause(NewSpeed*Speed);
end;

procedure TChar.pDead;
begin
  if fly > 0 then fly := fly - 0.1;
  if cFrame < eFrame then Inc(cFrame);
  if Timer.Run then SetStatus(hide);
end;

procedure TChar.StartDead;
begin
  sFrame := Dead_sf; cFrame := Dead_sf; eFrame := Dead_ef;
  SetStatus(dead);
  if MusicEnabled and (Length(Dead_track) > 0) then
  begin
    MyMedia('Stop',Dead_track);
    MyMedia('Play',Dead_track);
  end;
  Timer.SetPause(1);
  Timer.Run;
end;

{ TLocation }

constructor TLocation.Create;
begin

end;

destructor TLocation.Destroy;
begin
  glDeleteTextures(1, Texture.Image);
end;
         
procedure TLocation.Load(Patch: string);

  function Max(v1,v2:GLfloat): GLfloat;
  begin
    if v1 >= v2 then Result := v1
    else Result := v2;
  end;

var
  F : TextFile;
  S : string;
  i : Word;
  VertexCount : Word;
  Vertex : TglVertex;
  Face : TglFace;
  MaxVertex: GLfloat; // Для масщтаба
begin

//Загружаем сетку.
  AssignFile(f,Patch + '.gms');
  Reset(f);
  Readln(f,S);  // Пропускаем New object:
  Readln(f,S); // Пропускаем TriMesh()
  Readln(f,S); // Пропускаем numverts numfaces

  Readln(f,VertexCount,FaceCount);
  GetMem(Mesh.Verteces,VertexCount*SizeOf(TglVertex));
  GetMem(Mesh.Faces,FaceCount*SizeOf(TglFace));

  Readln(f,S); // Пропускаем Mesh vertices:
  for i := 0 to VertexCount - 1 do
  begin
    Readln(f,Vertex.x,Vertex.y,Vertex.z);
    Mesh.Verteces[i] := Vertex;
  end;
  Readln(f,S); // Пропускаем end vertices

  Readln(f,S); // Пропускаем Mesh faces:
  for i := 0 to FaceCount - 1 do
  begin
    Readln(f,Face[0],Face[1],Face[2]);
    Face[0] := Face[0] - 1;
    Face[1] := Face[1] - 1;
    Face[2] := Face[2] - 1;
    Mesh.Faces[i] := Face;
  end;

//Масштабирование
  begin
    MaxVertex := 0;
    for i:=0 to VertexCount - 1 do
    begin
      MaxVertex := Max(MaxVertex,Mesh.Verteces[i].x);
      MaxVertex := Max(MaxVertex,Mesh.Verteces[i].y);
      MaxVertex := Max(MaxVertex,Mesh.Verteces[i].z);
    end;
    Size := 1 / MaxVertex{ * Масштаб к одному};
  end;

  Readln(f,S); // Пропускаем end faces
  Readln(f,S); // Пропускаем end mesh
  Readln(f,S); // Тут New Texture:

  Readln(f,S); //Пропскаем numtverts numtvfaces
 // Readln(f,S); // Моя первая Фича!!!

  Readln(f,VertexCount,Texture.FaceCount);
  GetMem(Texture.Verteces,VertexCount*SizeOf(TglVertex));
  GetMem(Texture.Faces,Texture.FaceCount*SizeOf(TglFace));

  Readln(f,S); // Пропускаем Texture vertices:
  for i := 0 to VertexCount - 1 do
  begin
    Readln(f,Vertex.x,Vertex.y,Vertex.z);
    Vertex.y := 1 - Vertex.y;
    Texture.Verteces[i] := Vertex;
  end;
  Readln(f,S); // Пропускаем end texture vertices

  Readln(f,S); // Пропускаем Texture faces:
  for i := 0 to Texture.FaceCount - 1 do
  begin
    Readln(f,Face[0],Face[1],Face[2]);
    Face[0] := Face[0] - 1;
    Face[1] := Face[1] - 1;
    Face[2] := Face[2] - 1;
    Texture.Faces[i] := Face;
  end;

  CloseFile(f);

//Загружаем текстуру
  LoadTexture(Patch + format, Texture.Image, False);

end;

procedure TLocation.Draw;
var
  i : Word;
begin

  glBindTexture(GL_TEXTURE_2D,Texture.Image);
  glBegin(GL_TRIANGLES);
  for i:=0 to FaceCount - 1 do
  begin
    glTexCoord2fv(@Texture.Verteces[Texture.Faces[i][0]]);  glVertex3fv(@Mesh.Verteces[Mesh.Faces[i][0]]);
    glTexCoord2fv(@Texture.Verteces[Texture.Faces[i][1]]);  glVertex3fv(@Mesh.Verteces[Mesh.Faces[i][1]]);
    glTexCoord2fv(@Texture.Verteces[Texture.Faces[i][2]]);  glVertex3fv(@Mesh.Verteces[Mesh.Faces[i][2]]);
  end;
  glEnd;

end;

end.
 