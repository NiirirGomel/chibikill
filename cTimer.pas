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
  constructor cTimer.Create(fps: integer);
  procedure cTimer.SetPause(fps: integer);
  function cTimer.Run: Boolean;
end;

implementation

constructor cTimer.Create(fps: integer);
begin
  QueryPerformanceFrequenc(QPF);
  pause:=qpf div fps;
  QPC:=0;
end;

procedure cTimer.SetPause(fps: Integer);
begin
  pause:=qpf div fps;
end;

function cTimer.Run: Boolean;
begin
  QueryPerformanceCounter(realTime);
  if realTime > QPS then
  begin
    QueryPerformanceCounter(t1);
    t1 := t1 + pause;
  end;
end;

end.
 