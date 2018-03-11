program Chibikill;

uses
  Windows,
  Messages,
  OpenGL,
  UTex,
  UTimer,
  UGame;

const
  WND_TITLE = 'Chibikill_v1.0_r';
  wndWidth = 940;
  wndHeight = 560;

type

  TRecords = record
    Name : array [1..10] of string [15];
    point: array [1..10] of Word;
  end;

  Choice_ai = (left_ai,right_ai,strike_ai,stand_ai);

      // Игра
  TGame = class
    Location: TLocation;
    Hero: TModel;
    Shtain: TModel;
    Bat: TModel;
    Player: TPlayer;
    Monsters: TMonsters;

    Map, Dificulty : Byte;
    GameSpeed : Integer;
    Border: array [0..1] of GLfloat;
    MaxMonster, MinMonster: Byte;
  private
    procedure Display;
    procedure Calculate;

  public
    function Run(): Cardinal;  
    function MobsDead() : Boolean;
    function mobAI(Mob: PPlayer) : Choice_ai;
    procedure SpawnMobs();
    procedure WriteHealth(Player: PPlayer);

    constructor Create(iMap, iDificulty : Byte);
    destructor Destroy;
  end;

var
  h_Wnd  : HWND;                     // Global window handle
  h_DC   : HDC;                      // Global device context
  h_RC   : HGLRC;                    // OpenGL rendering context
  keys: array[1..255] of Boolean;

  Records: TRecords;

  MusicEnabled : Boolean = True;
  Menu_them : string = 'data\music\Basement_Skylights_-_KillingFields.mp3';
  Menu_click : string = 'data\music\CLICK.wav';
  Game_them : array [0..4] of string =
    ('data\music\03.Spindiehaze - Str8 Zero.mp3',
    'data\music\11.Spindiehaze - Outro.mp3',
    'data\music\06.Spindiehaze - Furious Nation.mp3',
    'data\music\09.Spindiehaze - Doomed.mp3',
    'data\music\10.Spindiehaze - Haze.mp3');
  CurentTrack : Byte;

procedure glDeleteTextures (n: GLsizei; const textureNames: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

 
{------------------------------------------------------------------}
{  Function to convert int to string. (No sysutils = smaller EXE)  }
{------------------------------------------------------------------}
function IntToStr(Num : Integer) : String;  // using SysUtils increase file size by 100K
begin
  Str(Num, result);
end;

{------------------------------------------------------------------}
{  Handle window resize                                            }
{------------------------------------------------------------------}
procedure glSetSizeWnd(Width, Height : Integer);
begin
  if (Height = 0) then                // prevent divide by zero exception
    Height := 1;
  glViewport(0, 0, Width, Height);    // Set the viewport for the OpenGL window
end;
 
procedure glSet2D;
begin
  glMatrixMode(GL_PROJECTION);        // Change Matrix Mode to Projection
  glLoadIdentity();                   // Reset View
  gluPerspective(0, wndWidth/wndHeight, 0, 0);  // Do the perspective calculations. Last value = max clipping depth

  glMatrixMode(GL_MODELVIEW);         // Return to the modelview matrix
  glLoadIdentity();                   // Reset View
end;

procedure glSet3D;
begin
  glMatrixMode(GL_PROJECTION);        // Change Matrix Mode to Projection
  glLoadIdentity();                   // Reset View
  gluPerspective(45.0, wndWidth/wndHeight, 1.0, 100.0);  // Do the perspective calculations. Last value = max clipping depth

  glMatrixMode(GL_MODELVIEW);         // Return to the modelview matrix
  glLoadIdentity();                   // Reset View
end;

{TRecords}

procedure pRecordsWrite();
var
  f : file of TRecords;
begin
  AssignFile(f,'records');

  {$I-}  // Если нет файла то содаёт пустышку
  Reset(f);
  if IOResult <> 0 then
  begin
    Records.Name[1] := 'Chuck Noris';
    Records.point[1] := 5000;
    Records.Name[2] := 'God';
    Records.point[2] := 2400;
    Records.Name[3] := 'Imposibul';
    Records.point[3] := 1200;
    Records.Name[4] := 'Lucky';
    Records.point[4] := 500;
    Records.Name[5] := 'Hard';
    Records.point[5] := 300;
    Records.Name[6] := 'Normal';
    Records.point[6] := 130;
    Records.Name[7] := 'Easy';
    Records.point[7] := 60;
    Records.Name[8] := 'Cube\/';
    Records.point[8] := 30;
    Records.Name[9] := 'Lol';
    Records.point[9] := 10;
    Records.Name[10] := 'No coment';
    Records.point[10] := 5;
  end;

  Rewrite(f);
  Write(f,Records);
  CloseFile(f);
end;

function fRecordsRead() : TRecords;
var
  f : file of TRecords;
begin
  AssignFile(f,'records');
  {$I-}
  Reset(f);
  if IOResult <> 0 then
  begin
    pRecordsWrite();
    Result := Records;
    Exit;
  end;
  if not Eof(f) then
    Read(f,Result)
  else
  begin
    pRecordsWrite();
    Result := Records;
  end;         
  CloseFile(f);
end;
            
{  Вывод Текста  }

procedure glTextWrite(Text: string; z: GLfloat = 0.0);
var
  h,w,l: GLfloat;
  i,n: Byte;
begin
  l:=0; // Длинна строки

  glEnable(GL_ALPHA_TEST);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  for i:=1 to Length(Text) do   
  if Text[i] <> ''then
  begin
    case Text[i] of
    '0': n := 0; '1': n := 1; '2': n := 2; '3': n := 3; '4': n := 4; '5': n := 5;
    '6': n := 6; '7': n := 7; '8': n := 8; '9': n := 9;
    'q': n := 10; 'w': n := 11; 'e': n := 12; 'r': n := 13; 't': n := 14;
    'y': n := 15; 'u': n := 16; 'i': n := 17; 'o': n := 18; 'p': n := 19;
    'a': n := 20; 's': n := 21; 'd': n := 22; 'f': n := 23; 'g': n := 24;
    'h': n := 25; 'j': n := 26; 'k': n := 27; 'l': n := 28; 'z': n := 29;
    'x': n := 30; 'c': n := 31; 'v': n := 32; 'b': n := 33; 'n': n := 34;
    'm': n := 35;
    'Q': n := 36; 'W': n := 37; 'E': n := 38; 'R': n := 39; 'T': n := 40;
    'Y': n := 41; 'U': n := 42; 'I': n := 43; 'O': n := 44; 'P': n := 45;
    'A': n := 46; 'S': n := 47; 'D': n := 48; 'F': n := 49; 'G': n := 50;
    'H': n := 51; 'J': n := 52; 'K': n := 53; 'L': n := 54; 'Z': n := 55;
    'X': n := 56; 'C': n := 57; 'V': n := 58; 'B': n := 59; 'N': n := 60;
    'M': n := 61; ' ': n := 62; '\': n := 63; '/': n := 64; '[': n := 65;
    ']': n := 66; '*': n := 67; '#': n := 68;
    end;

    if n < 10 then
    begin
      w := 10;
      h := 0;
      n := n + 27;
    end else
    if n < 36 then
    begin
      w := 10;
      h := 0;
      n := n - 9;
    end else
    if n < 62 then
    begin
      w := 12;
      h := 0.5;
      n := n - 35;
    end else
    if n < 61 then
    begin
      w := 10;
      h := 0;
      n := n - 25;
    end else
    begin
      w := 11;
      h := 0;
      n := n - 25;
    end;

    glPushMatrix;
      //  Задаём и сохраняем размер отступа данного символа в строке
    glTranslatef(l,0,0);
    l := l + w/470;
      //  Изменяем размер символов на реальный
    glScalef(w/940,32/560,1);
    w := w / 512;

    glBindTexture(GL_TEXTURE_2D,TexChar);
    glBegin(GL_QUADS);
      glTexCoord2f(w*n-w,0.5-h); glVertex3f(-1,-1,z);
      glTexCoord2f(w*n,0.5-h); glVertex3f(1,-1,z);
      glTexCoord2f(w*n,1-h); glVertex3f(1,1,z);
      glTexCoord2f(w*n-w,1-h); glVertex3f(-1,1,z);
    glEnd;
    glPopMatrix;

  end;
  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);
end;

{ TGame }

constructor TGame.Create(iMap, iDificulty: Byte);
begin
  Map := iMap;
  Dificulty := iDificulty;
  Border[0] := -17;
  Border[1] := 17;

  Location := TLocation.Create;
  Location.Load('data/game/street');

  Hero := LoadModel('data/game/hero');
  Shtain := LoadModel('data/game/zombie');
  Bat := LoadModel('data/game/bat');

  Player := TPlayer.Create(@Hero,Hero_id);
  Player.MusicEnabled := MusicEnabled;

  GameSpeed := 60;

end;

destructor TGame.Destroy;
var
  i: Word;
begin
  Player.Free;
  if Length(Monsters) <> 0 then
    for i:=0 to Length(Monsters) - 1 do
      Monsters[i].Free;
  SetLength(Monsters,0);

  Location.Free;
end;

procedure TGame.SpawnMobs();
var
  i: Byte;
begin
  Randomize;
  if Length(Monsters) > 0 then
  for i:=0 to Length(Monsters) - 1 do
    Monsters[i].Free;

  SetLength(Monsters,(2+random(5)));
  for i:=0 to Length(Monsters) - 1 do
  begin
    case random(3) of
      0..1: Monsters[i] := TChar.Create(@Shtain,Shtain_id);
      2: Monsters[i] := TChar.Create(@Bat,Bat_id);
    end;
    if Random(3)>1 then
    begin
      Monsters[i].PosX := Player.PosX + 10;
      if Monsters[i].PosX-Monsters[i].Model.Meshes[Monsters[i].cFrame].Rect[cRight]*Monsters[i].Model.Size > Border[1] then
        Monsters[i].PosX := Player.PosX - 10;
    end
    else
    begin
      Monsters[i].PosX := Player.PosX - 10;
      if Monsters[i].PosX-Monsters[i].Model.Meshes[Monsters[i].cFrame].Rect[cLeft]*Monsters[i].Model.Size < Border[0] then
        Monsters[i].PosX := Player.PosX + 10;
    end;
    
    Monsters[i].MusicEnabled := MusicEnabled;

  end;
end;

function TGame.MobsDead() : Boolean;
var
  i: byte;
begin
  Result := True;
  if Length(Monsters) <> 0 then
    for i:=0 to Length(Monsters) - 1 do
      if Monsters[i].Status <> hide then Result := False;
end;
                               
function TGame.mobAI(Mob: PPlayer) : Choice_ai;
begin
  if Mob^.PosX > Player.PosX then
    if (Mob^.PosX - Player.PosX) > Mob^.StrikeDist then
      Result := left_ai
    else
      Result := strike_ai
  else
    if (Player.PosX - Mob^.PosX) > Mob^.StrikeDist then
      Result := right_ai
    else
      Result := strike_ai;
end;

procedure TGame.Calculate;
var
  i: Integer;
  Ai: Choice_ai;
begin
  with Player do
  begin
    if GameTimer.Run then
    begin
      if (Status <> hide) and (Status <> dead) and (Status <> wait) and (Status <> hit) then
        if ((Status = strike) or keys[65{a}]) and (Status <> parry) then
        begin
          if Status <> strike then StartStrike();
        end
        else
          if (Status = parry) or keys[83{s}] then
          begin
            if Status <> parry then StartParry;
          end
          else
            if (Status = walk) or keys[VK_Left] or keys[VK_Right] then
              if keys[VK_Left] then
                if not keys[VK_Right] then
                begin
                  SetDirect(False);
                  PrevDirect := False;
                  if Status <> walk then StartWalk;
                end
                else
                  if not PrevDirect then
                    SetDirect(True)
                  else
                    SetDirect(False)
              else
                if keys[VK_Right] then
                begin
                  SetDirect(True);
                  PrevDirect := True;
                  if Status <> walk then StartWalk;
                end
                else
                StartStand;
      // Нехило, правда? =)

      case Status of
        stand: pStand;
        walk:  pWalk;
        strike:pStrike(@Player,@Monsters);
        hit:   pHit;
        parry: pParry;
        wait:  pWait;
        dead:  pDead;
      end;
    end;
  end;

  //if Length(Monsters) > 0 then
  for i:=0 to Length(Monsters) - 1 do
  with Monsters[i] do
  begin
    if GameTimer.Run then
    begin
      Ai:= mobAI(@Monsters[i]);
      //if Ai = Strike_ai then Ai := stand_ai;
      if (Status <> hide) and (Status <> dead) and (Status <> wait) and (Status <> hit) then
        if ((Status = strike) or (Ai = strike_ai)) and (Status <> parry) then
        begin
          if Status <> strike then StartStrike();
        end
        else
          if (Status = parry) then
          begin
            if Status <> parry then StartParry;
          end
          else
            if (Status = walk) or (Ai = left_ai) or (Ai = right_ai) then
              if (Ai = left_ai) then
              begin
                SetDirect(False);
                PrevDirect := False;
                if Status <> walk then StartWalk;
              end
              else
                if (Ai = right_ai) then
                begin
                  SetDirect(True);
                  PrevDirect := True;
                  if Status <> walk then StartWalk;
                end
                else
                StartStand;

      case Status of
        stand: pStand;
        walk:  pWalk;
        strike:pStrike(@Player,nil,@Monsters[i]);
        hit:   pHit;
        parry: pParry;
        wait:  pWait;
        dead:  pDead;
      end;
    end;

  end;

end;

procedure TGame.WriteHealth(Player: PPlayer);
var
  Health: string;
begin
  Health := '\/\/\/\/\/\/\/\/\/\/';
  SetLength(Health,Player^.Health);
  glTextWrite(Health);
end;

procedure TGame.Display;
var
  i: integer;
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  // Рендеринг в 3Д
  glSet3D;

  glTranslatef(0,-1,-10);  // Камера удалена от сцены
  glTranslatef(-Player.PosX,-Player.PosY,-Player.PosZ);  // И следит за персонажем
  glRotatef(15,1,0,0);  // Под углом 15

  glPushMatrix;
  glTranslatef(0,3.2,-3);
  glScalef(Location.Size*17,Location.Size*17,Location.Size*17);
  glRotatef(-90,1,0,0);
  glRotatef(90,0,0,1);
  Location.Draw;
  glPopMatrix;

  glPushMatrix;
  with Player do
  begin
  glTranslatef(PosX,PosY,PosZ);
  if Direct then glRotatef(180,0,1,0);
  ShiftCalc;

  if PosX-Model.Meshes[cFrame].Rect[cLeft]*Model.Size < Border[0] then
    PosX := Border[0] + Model.Meshes[cFrame].Rect[cLeft]*Model.Size;
  if PosX-Model.Meshes[cFrame].Rect[cRight]*Model.Size > Border[1] then
    PosX := Border[1] + Model.Meshes[cFrame].Rect[cRight]*Model.Size;

  glTranslatef(ShiftX,ShiftY,ShiftZ);
  glScalef(Model.Size,Model.Size,Model.Size);
  Draw;
  end;
  glPopMatrix;

  for i:=0 to Length(Monsters) - 1 do
  if Monsters[i].Status <> hide then
  with Monsters[i] do
  begin
  glPushMatrix;
  glTranslatef(PosX,PosY,PosZ);
  if Direct then glRotatef(180,0,1,0);
  ShiftCalc;

  if PosX+Model.Meshes[cFrame].Rect[cLeft]*Model.Size < Border[0] then
    PosX := Border[0] - Model.Meshes[cFrame].Rect[cLeft]*Model.Size;
  if PosX+Model.Meshes[cFrame].Rect[cRight]*Model.Size > Border[1] then
    PosX := Border[1] + Model.Meshes[cFrame].Rect[cRight]*Model.Size;

  glTranslatef(ShiftX,ShiftY,ShiftZ);
  glScalef(Model.Size,Model.Size,Model.Size);
  Draw;
  glPopMatrix;
  end;
    // Линейка
  {for i:=-20 to 20 do
  begin
    glPushMatrix;
    glTranslatef(i,1,0);
    glScalef(6,6,6);
    glTextWrite(inttostr(i));
    glPopMatrix;
  end; }

  // Рендеринг в 2Д
  glSet2D;

  glPushMatrix;
  glScalef(1.5,1.5,0);
  glTranslatef(-0.05,0.5,0);
  glTextWrite('Coins');
  glTranslatef(-0.004,-0.1,0);
  glTranslatef(-0.01 * (Length(inttostr(Player.Kills))-1),0,0);
  glTextWrite('*#'+inttostr(Player.Kills)+'*#');
  glPopMatrix;

  glPushMatrix;
  glScalef(2,2,0);
  glTranslatef(0.2,0.35,0);
  WriteHealth(@Player);
  glPopMatrix;

  if Player.Status = dead then
  begin
    glPushMatrix;
    glScalef(4,4,0);
    glTranslatef(-0.11,0,0);
    glTextWrite('[Game Over]');
    glPopMatrix;
  end;

end;

function TGame.Run(): Cardinal;
var
  msg : TMsg;
  FPSTimer: cTimer;
  FPSCount: Integer;
  GameOver : Boolean;
begin
  Randomize;
  GameOver := False;
  FPSTimer := cTimer.Create(10);

  while not GameOver do
  begin
    if (PeekMessage(msg, 0, 0, 0, PM_REMOVE)) then // Check if there is a message for this window
    begin
      if (msg.message = WM_QUIT) then     // If WM_QUIT message received then we are done
        GameOver := True
      else
      begin                               // Else translate and dispatch the message to this window
  	    TranslateMessage(msg);
        DispatchMessage(msg);
      end;
    end
    else
    begin
      inc(FPSCount);
      if FPSTimer.Run then
      begin
        FPSCount :=Round(FPSCount * 1);   // calculate to get per Second incase intercal is less or greater than 1 second
        SetWindowText(h_Wnd, PChar(WND_TITLE + '   [' + intToStr(FPSCount) + ' FPS]'));
        FPSCount := 0;
      end;

      if Player.Status <> hide then
      begin
        if MusicEnabled then
          if MyMedia('Status',Game_them[CurentTrack],' mode wait') = 'stopped' then
          begin
            CurentTrack := Random(Length(Game_them)-1);
            MyMedia('Play',Game_them[CurentTrack]);
          end;
        if MobsDead() then SpawnMobs();
        Calculate;
        Display;
      end else
        GameOver := True;


      SwapBuffers(h_DC);

    end;
  end;
  
  Result := Player.Kills;
  FPSTimer.free;
end;

{------------------------------------------------------------------}
{  Initialise OpenGL                                               }
{------------------------------------------------------------------}
procedure glInit();
begin
  glClearColor(0.0, 0.0, 0.9, 0.0); 	   // Black Background
  glShadeModel(GL_SMOOTH);                 // Enables Smooth Color Shading
  glClearDepth(1.0);                       // Depth Buffer Setup
  glEnable(GL_DEPTH_TEST);                 // Enable Depth Buffer
  glDepthFunc(GL_LESS);		           // The Type Of Depth Test To Do

  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);   //Realy Nice perspective calculations
end;

{------------------------------------------------------------------}
{  Determines the application’s response to the messages received  }
{------------------------------------------------------------------}
function WndProc(hWnd: HWND; Msg: UINT;  wParam: WPARAM;  lParam: LPARAM): LRESULT; stdcall;
begin
  case (Msg) of
    WM_CREATE:
      begin
        // Insert stuff you want executed when the program starts
      end;
    WM_CLOSE:
      begin
        PostQuitMessage(0);
        Result := 0
      end;
    WM_KEYDOWN:       // Set the pressed key (wparam) to equal true so we can check if its pressed
      begin
        keys[wParam] := True;
        Result := 0;
      end;
    WM_KEYUP:         // Set the released key (wparam) to equal false so we can check if its pressed
      begin
        keys[wParam] := False;
        Result := 0;
      end;

  else
    Result := DefWindowProc(hWnd, Msg, wParam, lParam);    // Default result if nothing happens
  end;
end;

{---------------------------------------------------------------------}
{  Properly destroys the window created at startup (no memory leaks)  }
{---------------------------------------------------------------------}
procedure glKillWnd();
begin
  // Makes current rendering context not current, and releases the device
  // context that is used by the rendering context.
  wglMakeCurrent(h_DC, 0);

  wglDeleteContext(h_RC);

  DestroyWindow(h_Wnd);

  UnRegisterClass('OpenGL', hInstance);
end;

{---------------------------------------------------------------------}
{  glLoadScreen - Экран загрузки                                      }
{---------------------------------------------------------------------}
procedure glLoadScreen_DrAW;
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glSetSizeWnd(wndWidth,wndHeight);
  glSet2D;

  glBindTexture(GL_TEXTURE_2D,TexLoadScreen[0]);
  glBegin(GL_QUADS);
    glTexCoord2f(0,0); glVertex2f(-1,-1);
    glTexCoord2f(1,0); glVertex2f(1,-1);
    glTexCoord2f(1,1); glVertex2f(1,1);
    glTexCoord2f(0,1); glVertex2f(-1,1);
  glEnd;

  glEnable(GL_ALPHA_TEST);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  glBindTexture(GL_TEXTURE_2D,TexLoadScreen[1]);
  glBegin(GL_QUADS);
    glTexCoord2f(0,0); glVertex3f(-1,-1,-0.1);
    glTexCoord2f(1,0); glVertex3f(1,-1,-0.1);
    glTexCoord2f(1,1); glVertex3f(1,1,-0.1);
    glTexCoord2f(0,1); glVertex3f(-1,1,-0.1);
  glEnd;

  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);

  SwapBuffers(h_DC);
end;

function fMenu(): byte;

procedure glMenu_DrAW(n: byte);
begin
    // Очистка буфера цвета и буфера глубины
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  glBindTexture(GL_TEXTURE_2D,TexMenu[0]);
  glBegin(GL_QUADS);
    glTexCoord2f(0,0); glVertex2f(-1,-1);
    glTexCoord2f(1,0); glVertex2f(1,-1);
    glTexCoord2f(1,1); glVertex2f(1,1);
    glTexCoord2f(0,1); glVertex2f(-1,1);
  glEnd;

  glEnable(GL_ALPHA_TEST);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  case n of
    1 :
    begin
      glBindTexture(GL_TEXTURE_2D,TexMenu[1]);
      glBegin(GL_QUADS);
        glTexCoord2f(0,0); glVertex3f(-1,-1,-0.1);
        glTexCoord2f(1,0); glVertex3f(1,-1,-0.1);
        glTexCoord2f(1,1); glVertex3f(1,1,-0.1);
        glTexCoord2f(0,1); glVertex3f(-1,1,-0.1);
      glEnd;
    end;
    2 :
    begin
      glBindTexture(GL_TEXTURE_2D,TexMenu[2]);
      glBegin(GL_QUADS);
        glTexCoord2f(0,0); glVertex3f(-1,-1,-0.1);
        glTexCoord2f(1,0); glVertex3f(1,-1,-0.1);
        glTexCoord2f(1,1); glVertex3f(1,1,-0.1);
        glTexCoord2f(0,1); glVertex3f(-1,1,-0.1);
      glEnd;
    end;
    3:
    begin
      glBindTexture(GL_TEXTURE_2D,TexMenu[3]);
      glBegin(GL_QUADS);
        glTexCoord2f(0,0); glVertex3f(-1,-1,-0.1);
        glTexCoord2f(1,0); glVertex3f(1,-1,-0.1);
        glTexCoord2f(1,1); glVertex3f(1,1,-0.1);
        glTexCoord2f(0,1); glVertex3f(-1,1,-0.1);
      glEnd;
    end;
    4:
    begin
      glBindTexture(GL_TEXTURE_2D,TexMenu[4]);
      glBegin(GL_QUADS);
        glTexCoord2f(0,0); glVertex3f(-1,-1,-0.1);
        glTexCoord2f(1,0); glVertex3f(1,-1,-0.1);
        glTexCoord2f(1,1); glVertex3f(1,1,-0.1);
        glTexCoord2f(0,1); glVertex3f(-1,1,-0.1);
      glEnd;
    end;
    5:
    begin
      glBindTexture(GL_TEXTURE_2D,TexMenu[5]);
      glBegin(GL_QUADS);
        glTexCoord2f(0,0); glVertex3f(-1,-1,-0.1);
        glTexCoord2f(1,0); glVertex3f(1,-1,-0.1);
        glTexCoord2f(1,1); glVertex3f(1,1,-0.1);
        glTexCoord2f(0,1); glVertex3f(-1,1,-0.1);
      glEnd;
    end;
  end;
             
  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);

  SwapBuffers(h_DC);
end;

var
  msg : TMsg;
  n: Byte;
begin
  n:=1;
  glMenu_DrAW(n);
   // Main message loop:
while True do
  begin
    if (PeekMessage(msg, 0, 0, 0, PM_REMOVE)) then // Check if there is a message for this window
    begin
      if (msg.message = WM_QUIT) then     // If WM_QUIT message received then we are done
      begin
        Result := 4;
        Exit;
      end else
      begin                               // Else translate and dispatch the message to this window
  	    TranslateMessage(msg);
        DispatchMessage(msg);
      end;
    end else
    begin
      if (keys[VK_ESCAPE]) then           // If user pressed ESC then set finised TRUE
      begin
        Result := 4;
        Exit;
      end;
      if (keys[VK_UP]) and (n > 1) then
      begin
        dec(n);
        keys[VK_UP] := false;
        if MusicEnabled then
        begin
          MyMedia('Stop',Menu_click);
          MyMedia('Play',Menu_click);
        end;
        glMenu_DrAW(n);
      end;
      if (keys[VK_DOWN]) and (n < 5) then
      begin
        inc(n);
        keys[VK_DOWN] := false;
        if MusicEnabled then
        begin
          MyMedia('Stop',Menu_click);
          MyMedia('Play',Menu_click);
        end;
        glMenu_DrAW(n);
      end;
      if (keys[13]) then
      begin
        keys[13] := false;
        Result := n;
        Exit;
      end;
    end;
  end;
end;

function fSeting() : Boolean;

  procedure Seting_DrAW;
  begin
       // Очистка буфера цвета и буфера глубины
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  glBindTexture(GL_TEXTURE_2D,TexMenu[10]);
  glBegin(GL_QUADS);
    glTexCoord2f(0,0); glVertex2f(-1,-1);
    glTexCoord2f(1,0); glVertex2f(1,-1);
    glTexCoord2f(1,1); glVertex2f(1,1);
    glTexCoord2f(0,1); glVertex2f(-1,1);
  glEnd;

  glEnable(GL_ALPHA_TEST);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  if MusicEnabled then
  begin
    glBindTexture(GL_TEXTURE_2D,TexMenu[11]);
      glBegin(GL_QUADS);
        glTexCoord2f(0,0); glVertex3f(-1,-1,-0.1);
        glTexCoord2f(1,0); glVertex3f(1,-1,-0.1);
        glTexCoord2f(1,1); glVertex3f(1,1,-0.1);
        glTexCoord2f(0,1); glVertex3f(-1,1,-0.1);
      glEnd;
  end else
  begin
    glBindTexture(GL_TEXTURE_2D,TexMenu[12]);
    glBegin(GL_QUADS);
      glTexCoord2f(0,0); glVertex3f(-1,-1,-0.2);
      glTexCoord2f(1,0); glVertex3f(1,-1,-0.2);
      glTexCoord2f(1,1); glVertex3f(1,1,-0.2);
      glTexCoord2f(0,1); glVertex3f(-1,1,-0.2);
    glEnd;
  end;
  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);

  SwapBuffers(h_DC);
  end;

var
  msg : TMsg;
begin
   Seting_DrAW;
   // Main message loop:
while True do
  begin
    if (PeekMessage(msg, 0, 0, 0, PM_REMOVE)) then // Check if there is a message for this window
    begin
      if (msg.message = WM_QUIT) then     // If WM_QUIT message received then we are done
      begin
        Result := True;
        Exit;
      end else
      begin                               // Else translate and dispatch the message to this window
  	    TranslateMessage(msg);
        DispatchMessage(msg);
      end;
    end
    else
      if (keys[VK_ESCAPE]) then           // If user pressed ESC then set finised TRUE
      begin
        keys[VK_ESCAPE] := False;
        Result := False;
        Exit;
      end;
      if (keys[13]) then
      begin
        keys[13] := False;
        if MusicEnabled then
        begin
          MusicEnabled := False;
          MyMedia('Stop',Menu_them);
        end
        else
        begin
          MyMedia('Play',Menu_them);
          MyMedia('Stop',Menu_click);
          MyMedia('Play',Menu_click);
          MusicEnabled := True;
        end;
        Seting_DrAW;
      end;
  end;
end;

function fSaveRecord(r: Cardinal): Boolean;
var
  i: Byte;
  msg: TMsg;
  NewName: string[15];

  procedure pNewRecord_DrAW;
  begin
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

    glBindTexture(GL_TEXTURE_2D,TexMenu[8]); // Bg
    glBegin(GL_QUADS);
      glTexCoord2f(0,0); glVertex2f(-1,-1);
      glTexCoord2f(1,0); glVertex2f(1,-1);
      glTexCoord2f(1,1); glVertex2f(1,1);
      glTexCoord2f(0,1); glVertex2f(-1,1);
    glEnd;

    glPushMatrix;
    glTranslatef(-0.44,0.055,0);
    glTextWrite(NewName,-0.1);
    glPopMatrix;

    SwapBuffers(h_DC);
  end;

begin
  i:=1;
  while not ((i = 11) or (Records.point[i] < r)) do inc(i);
  if i < 11 then
  begin
    NewName := '';
    pNewRecord_DrAW;
  while True do
  begin
    if (PeekMessage(msg, 0, 0, 0, PM_REMOVE)) then // Check if there is a message for this window
    begin
      case msg.message of     // If WM_QUIT message received then we are done
      WM_QUIT:
        begin
          Result := True;
          Exit;
        end;
      WM_CHAR:       // Set the pressed key (wparam) to equal true so we can check if its pressed
        begin
          case msg.wParam of
          VK_ESCAPE:           // If user pressed ESC then set finised TRUE
            begin
              keys[VK_ESCAPE] := False;
              Result := False;
              Exit;
            end;
          13:
            if NewName <> '' then
            begin
              keys[13] := False;
              Records.Name[i] := NewName;
              Records.point[i] := r;
              pRecordsWrite;
              Result := False;
              Exit;
            end;
          8:
            begin
              Delete(NewName,Length(NewName),1);
              pNewRecord_DrAW;
            end;
          48..57,65..90,97..122:
            begin
              NewName := NewName+char(msg.wParam);
              pNewRecord_DrAW;
            end;
          end;
        end;
      else                            // Else translate and dispatch the message to this window
  	    TranslateMessage(msg);
        DispatchMessage(msg);
      end;
    end;

  end;
  end else
    Result := False;
end;

function fViewRecords() : Boolean;
var
  i: Byte;
  msg: TMsg;
  fin: Boolean;
begin

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  glBindTexture(GL_TEXTURE_2D,TexMenu[7]);
  glBegin(GL_QUADS);
    glTexCoord2f(0,0); glVertex2f(-1,-1);
    glTexCoord2f(1,0); glVertex2f(1,-1);
    glTexCoord2f(1,1); glVertex2f(1,1);
    glTexCoord2f(0,1); glVertex2f(-1,1);
  glEnd;

  for i:=1 to 10 do
  begin
    glPushMatrix;
    if i < 6 then
      glTranslatef(-0.6,0.6 - (i*0.15),0)
    else
      glTranslatef(0.1,0.6 - ((i-5)*0.15),0);
    glScalef(1,1,1);
    glTextWrite(IntToStr(i)+' ['+Records.Name[i]+']',-i/10);
    glTranslatef(0.45,0,0);
    glTextWrite(IntToStr(Records.point[i])+'*#',-i/10);
    glPopMatrix;
  end;

  SwapBuffers(h_DC);

  fin := False;
  while not fin do
  begin
    if (PeekMessage(msg, 0, 0, 0, PM_REMOVE)) then // Check if there is a message for this window
    begin
      if (msg.message = WM_QUIT) then     // If WM_QUIT message received then we are done
      begin
        Result := True;
        fin := True;
      end else
      begin                               // Else translate and dispatch the message to this window
  	    TranslateMessage(msg);
        DispatchMessage(msg);
      end;
    end else
    begin
      if (keys[VK_ESCAPE]) then           // If user pressed ESC then set finised TRUE
      begin
        keys[VK_ESCAPE] := False;
        Result := False;
        fin := True;
      end;
    end;
  end;

end;
   
function fHelp() : Boolean;
var
  msg : TMsg;
begin
    // Очистка буфера цвета и буфера глубины
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  glBindTexture(GL_TEXTURE_2D,TexMenu[9]);
  glBegin(GL_QUADS);
    glTexCoord2f(0,0); glVertex2f(-1,-1);
    glTexCoord2f(1,0); glVertex2f(1,-1);
    glTexCoord2f(1,1); glVertex2f(1,1);
    glTexCoord2f(0,1); glVertex2f(-1,1);
  glEnd;

  SwapBuffers(h_DC);
   // Main message loop:
while True do
  begin
    if (PeekMessage(msg, 0, 0, 0, PM_REMOVE)) then // Check if there is a message for this window
    begin
      if (msg.message = WM_QUIT) then     // If WM_QUIT message received then we are done
      begin
        Result := True;
        Exit;
      end else
      begin                               // Else translate and dispatch the message to this window
  	    TranslateMessage(msg);
        DispatchMessage(msg);
      end;
    end
    else
      if (keys[VK_ESCAPE]) then           // If user pressed ESC then set finised TRUE
      begin
        keys[VK_ESCAPE] := False;
        Result := False;
        Exit;
      end;
  end;
end;

{--------------------------------------------------------------------}
{  Creates the window and attaches a OpenGL rendering context to it  }
{--------------------------------------------------------------------}
procedure glCreateWnd(Width, Height : Integer; PixelDepth : Integer);
var
  wndClass : TWndClass;         // Window class
  dwStyle : DWORD;              // Window styles
  dwExStyle : DWORD;            // Extended window styles
  PixelFormat : GLuint;         // Settings for the OpenGL rendering
  h_Instance : HINST;           // Current instance
  pfd : TPIXELFORMATDESCRIPTOR;  // Settings for the OpenGL window
begin
  h_Instance := GetModuleHandle(nil);       //Grab An Instance For Our Window
  ZeroMemory(@wndClass, SizeOf(wndClass));  // Clear the window class structure

  with wndClass do                    // Set up the window class
  begin
    style         := CS_HREDRAW or    // Redraws entire window if length changes
                     CS_VREDRAW or    // Redraws entire window if height changes
                     CS_OWNDC;        // Unique device context for the window
    lpfnWndProc   := @WndProc;        // Set the window procedure to our func WndProc
    hInstance     := h_Instance;
    hCursor       := LoadCursor(0, IDC_ARROW);
    lpszClassName := 'OpenGL';
  end;

  RegisterClass(wndClass);

  dwStyle := (WS_OVERLAPPED or
               WS_CAPTION or
               WS_SYSMENU) or           // Creates an overlapping window, no resize
             WS_CLIPCHILDREN or         // Doesn't draw within child windows
             WS_CLIPSIBLINGS;           // Doesn't draw within sibling windows
  dwExStyle := WS_EX_APPWINDOW or       // Top level window
               WS_EX_WINDOWEDGE;        // Border with a raised edge

  // Attempt to create the actual window
  h_Wnd := CreateWindowEx(dwExStyle,      // Extended window styles
                          'OpenGL',       // Class name
                          WND_TITLE,      // Window title (caption)
                          dwStyle,        // Window styles
                          0, 0,           // Window position
                          Width, Height,  // Size of window
                          0,              // No parent window
                          0,              // No menu
                          h_Instance,     // Instance
                          nil);           // Pass nothing to WM_CREATE

  // Try to get a device context
  h_DC := GetDC(h_Wnd);

  // Settings for the OpenGL window
  with pfd do
  begin
    nSize           := SizeOf(TPIXELFORMATDESCRIPTOR); // Size Of This Pixel Format Descriptor
    nVersion        := 1;                    // The version of this data structure
    dwFlags         := PFD_DRAW_TO_WINDOW    // Buffer supports drawing to window
                       or PFD_SUPPORT_OPENGL // Buffer supports OpenGL drawing
                       or PFD_DOUBLEBUFFER;  // Supports double buffering
    iPixelType      := PFD_TYPE_RGBA;        // RGBA color format
    cColorBits      := PixelDepth;           // OpenGL color depth
    cRedBits        := 0;                    // Number of red bitplanes
    cRedShift       := 0;                    // Shift count for red bitplanes
    cGreenBits      := 0;                    // Number of green bitplanes
    cGreenShift     := 0;                    // Shift count for green bitplanes
    cBlueBits       := 0;                    // Number of blue bitplanes
    cBlueShift      := 0;                    // Shift count for blue bitplanes
    cAlphaBits      := 0;                    // Not supported
    cAlphaShift     := 0;                    // Not supported
    cAccumBits      := 0;                    // No accumulation buffer
    cAccumRedBits   := 0;                    // Number of red bits in a-buffer
    cAccumGreenBits := 0;                    // Number of green bits in a-buffer
    cAccumBlueBits  := 0;                    // Number of blue bits in a-buffer
    cAccumAlphaBits := 0;                    // Number of alpha bits in a-buffer
    cDepthBits      := 16;                   // Specifies the depth of the depth buffer
    cStencilBits    := 0;                    // Turn off stencil buffer
    cAuxBuffers     := 0;                    // Not supported
    iLayerType      := PFD_MAIN_PLANE;       // Ignored
    bReserved       := 0;                    // Number of overlay and underlay planes
    dwLayerMask     := 0;                    // Ignored
    dwVisibleMask   := 0;                    // Transparent color of underlay plane
    dwDamageMask    := 0;                     // Ignored
  end;

  // Attempts to find the pixel format supported by a device context that is the best match to a given pixel format specification.
  PixelFormat := ChoosePixelFormat(h_DC, @pfd);

  // Sets the specified device context's pixel format to the format specified by the PixelFormat.
  SetPixelFormat(h_DC, PixelFormat, @pfd);

  // Create a OpenGL rendering context
  h_RC := wglCreateContext(h_DC);

  // Makes the specified OpenGL rendering context the calling thread's current rendering context
  wglMakeCurrent(h_DC, h_RC);

  glPreTex_LoAD;

  // Settings to ensure that the window is the topmost window
  ShowWindow(h_Wnd, SW_SHOW);
  SetForegroundWindow(h_Wnd);
  SetFocus(h_Wnd);

  // Start Setings
  if (Height = 0) then                // prevent divide by zero exception
    Height := 1;
  glViewport(0, 0, Width, Height);    // Set the viewport for the OpenGL window
  glMatrixMode(GL_PROJECTION);        // Change Matrix Mode to Projection
  glLoadIdentity();                   // Reset View
  gluPerspective(45.0, Width/Height, 1.0, 100.0);  // Do the perspective calculations. Last value = max clipping depth

  glMatrixMode(GL_MODELVIEW);         // Return to the modelview matrix
  glLoadIdentity();                   // Reset View

  glInit();
end;

{--------------------------------------------------------------------}
{  Main message loop for the application                             }
{--------------------------------------------------------------------}
Procedure WinMain(); stdcall;
var
  Game : TGame;
  finished: Boolean;
  Rezultat : Cardinal;
begin
  Randomize;
  finished := False;

  // Perform application initialization:
  glCreateWnd(wndWidth, wndHeight, 32);
  glEnable(GL_TEXTURE_2D);

    //  Загрузка
  glLoadScreen_DrAW;
  glMenu_LoAD;
  Records := fRecordsRead();

    //  Меню
  repeat
    if MusicEnabled then
      MyMedia('Play',Menu_them);
    case fMenu of
      1: begin
           MyMedia('Stop',Menu_them);
           glLoadScreen_DrAW;
           Game := TGame.Create(0,0);
           if MusicEnabled then
           begin
             CurentTrack := Random(Length(Game_them)-1);
             MyMedia('Play',Game_them[CurentTrack]);
           end;
           finished := fSaveRecord(Game.Run()); 
           if MusicEnabled then
            MyMedia('Stop',Game_them[CurentTrack]);
           glLoadScreen_DrAW;
           Game.Free;
         end;
      2: finished := fSeting;
      3: finished := fViewRecords;
      4: finished := True;           //fExit - Выход из программы
      5: finished := fHelp;
    end;
  until finished;
  glKillWnd();
end;

begin
  WinMain();
  glMenu_Free;
  glPreTex_Free;
end.
