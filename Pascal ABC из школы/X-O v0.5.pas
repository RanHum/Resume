uses graphabc,events;
type field=array[1..3,1..3]of integer;
type pline=array[1..3]of ^integer;
type line=array[1..3]of integer;
var
  game,steps,comp,human:integer;
  i,j:integer;
  seq:boolean;
  f:field;

////////////AI//////////////

function max(a,b:integer):integer;begin result:=a;if b>a then result:=b;end;

function getl(n:integer):pline;
procedure fill(var a:pline;p1,p2,p3:^integer);begin
  a[1]:=p1;a[2]:=p2;a[3]:=p3;
end;
begin case n of
    1:fill(result,@f[1,1],@f[1,2],@f[1,3]);
    2:fill(result,@f[2,1],@f[2,2],@f[2,3]);
    3:fill(result,@f[3,1],@f[3,2],@f[3,3]);
    4:fill(result,@f[1,1],@f[2,1],@f[3,1]);
    5:fill(result,@f[1,2],@f[2,2],@f[3,2]);
    6:fill(result,@f[1,3],@f[2,3],@f[3,3]);
    7:fill(result,@f[1,1],@f[2,2],@f[3,3]);
    8:fill(result,@f[1,3],@f[2,2],@f[3,1]);
end;end;

function seel(a:pline):line;begin
  result[1]:=a[1]^;result[2]:=a[2]^;result[3]:=a[3]^;
end;

function seefirstbl(l:line;k:integer):integer;
var
  i:integer;
begin
  result:=0;
  for i:=1 to 3 do
    if(l[i]=k)and(result=0)then
      result:=i;
end;
function seefirstbpl(l:pline;k:integer):integer;begin result:=seefirstbl(seel(l),k);end;
function seefirstbn(n,k:integer):integer;begin result:=seefirstbl(seel(getl(n)),k);end;

function seefirstx(n,k:integer):integer;var i:integer;begin
  i:=seefirstbn(n,k);
  if i>0 then
    if(n<=3)then
      result:=n
    else
      result:=i;
end;
function seefirsty(n,k:integer):integer;var i:integer;begin
  i:=seefirstbn(n,k);
  if i>0 then
       if n<=3 then result:=i
  else if n<=6 then result:=n-3
  else if n =7 then result:=i
  else result:=4-i;
end;

function gicbl(l:line;i:integer):integer;begin
  result:=0;
  if(l[1]=i)then inc(result);
  if(l[2]=i)then inc(result);
  if(l[3]=i)then inc(result);
end;
function gicbpl(l:pline;i:integer):integer;begin result:=gicbl(seel(l),i);end;
function gicbn(n:integer;i:integer):integer;begin result:=gicbl(seel(getl(n)),i);end;

function gscbl(l:line):integer;begin result:=max(gicbl(l,1),gicbl(l,2));end;
function gscbpl(l:pline):integer;begin result:=gscbl(seel(l));end;
function gscbn(n:integer):integer;begin result:=gscbl(seel(getl(n)));end;

procedure genstep(var i,j:integer);
var
  k:integer;
  info:array[1..2,1..8]of integer;
procedure fil(n:integer);begin
  if i=0 then begin
    i:=seefirstx(n,0);
    j:=seefirsty(n,0);
  end;
end;
begin
  if f[2,2]=0 then begin
    i:=2;
    j:=2;
  end else begin
    i:=0;
    for k:=1 to 8 do
      info[1,k]:=gicbn(k,1);
    for k:=1 to 8 do
      info[2,k]:=gicbn(k,2);
      
    for k:=8 downto 1 do
      if(info[comp,k]=2)and(info[human,k]=0)then // возможность победить,завершив комбинацию
        fil(k);
    if i=0 then for k:=8 downto 1 do
      if(info[human,k]=2)and(info[comp,k]=0)then // возможность прервать комбинацию врага
        fil(k);
    if i=0 then for k:=8 downto 1 do
      if(info[comp,k]=1)and(info[human,k]=0)then // возможность установить вторую фишку в своей линии
        fil(k);
    if i=0 then for k:=8 downto 1 do
      if(info[human,k]=1)and(info[comp,k]=0)then // возможность обезвредить начатую линию врага
        fil(k);
    if i=0 then begin
    fil(7);                                   // если
    fil(8);                                   // совсем
    fil(2);                                   // нечего
    fil(5);                                   // делать
    end;
  end;
end;

////////////////////////////
procedure checkline(n:integer);var l:pline;begin
  l:=getl(n);
  if(gscbpl(l)=3)then begin
    game:=l[1]^;
  end;
end;

procedure check;
var i:integer;
begin;
  for i:=1 to 8 do if game=0 then
    checkline(i);
end;
  
procedure draw;
var
  i,j,x,y:integer;
  c:string;
begin
  clearwindow(clblue);
  setpencolor(clmaroon);
  setbrushcolor(clyellow);
  fillrect(0,0,340,50);
  setbrushcolor(clblack);
  setfontsize(60);
  setfontcolor(clmaroon);
  setfontstyle(fsbold);
  setfontname('arial');
  x:=10;
  y:=60;
  for i:=1 to 3 do begin
    for j:=1 to 3 do begin
      fillrect(x,y,x+100,y+100);
      case f[i,j] of
        0:c:='';
        1:c:='X';
        2:c:='O';
      end;
      textout(x+50-textwidth(c) div 2,y+50-textheight(c) div 2,c);
      inc(x,110);
      if x>230 then x:=10;
    end;
    inc(y,110);
  end;
  setfontsize(25);
  setbrushcolor(clyellow);
  setfontcolor(clblack);
  if game>0 then c:='Player '+inttostr(game)+' Win!' else if steps=9 then c:='Draw!' else c:='Step: '+inttostr(steps+1);
  textout(170-textwidth(c)div 2,25-textheight(c)div 2,c);
end;

procedure makestep;var s:integer;begin
  i:=0;
  if seq then begin
    while i=0 do sleep(10);
    s:=human;
  end else begin
    genstep(i,j);
    s:=comp;
  end;
  if f[i,j]=0 then begin
    f[i,j]:=s;
    inc(steps);
    seq:=not seq;
  end else makestep;
end;

procedure mousedown(x,y,button:integer);begin
  if seq then begin
    i:=trunc((y-50)*3/340)+1;
    j:=trunc(x*3/340)+1;
  end;
end;

begin
  seq:=true;
  if seq then
    comp:=2
  else
    comp:=1;
  human:=3-comp;
  steps:=0;
  setwindowwidth(340);
  setwindowheight(390);
  centerwindow;
  setwindowtitle('Крестики-нолики');
  draw;
  onmousedown:=mousedown;
  while(game=0)and(steps<9)do begin
    makestep;
    check;
    draw;
  end;
end.