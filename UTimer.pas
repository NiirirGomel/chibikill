unit UTimer;

interface

uses Windows;

type
  cTimer = class
private
  QPF,
  pause,
  realTime,
  QPC: Int64;
public
  constructor Create(fps: integer);
  procedure SetPause(fps: integer);
  function Run: Boolean;
end;

implementation

constructor cTimer.Create(fps: integer);
begin
  QueryPerformanceFrequency(QPF);
  pause:=qpf div fps;
  QPC:=0;
end;

procedure cTimer.SetPause(fps: integer);
begin
  pause:=qpf div fps;
end;

function cTimer.Run: Boolean;
begin
  QueryPerformanceCounter(realTime);
  if realTime > QPC then
  begin
    QueryPerformanceCounter(QPC);
    QPC := QPC + pause;
    Result := True;
  end else
    Result := False;
end;

end.
 