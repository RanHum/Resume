program graphic;
uses graphABC,Events,Timers;
const
  ninf=-1e30;
  pinf=1e30;
  pzl=1/pinf;
  nzl=-pzl;
  plim=1e5;
  nlim=-1e5;
  derlim=1e3;
  invalid=ninf-1;
  argamount=5;
  type args=array[1..argamount]of string;
var
  x0,y0:real;
  mousex,mousey,mousesx,mousesy:integer;
  nppr,ppnr,moveq:real;
  ppn:integer;
  local,global,info:boolean;
  ctrl,shift,console:boolean;
  mode,timer:integer;
  gw:integer;
  lc,wc:integer;
  tss,tsm,tsl:integer;
  /////////
  intro,input:string;
  cursor:integer;
  curs:boolean;
  inarg:args;
  inargam:integer;

function evalfunc(x:real):real;
//var
  //caneval:boolean;
function ex(x,a:real):real;
var i:integer;
begin
  if (frac(a)=0) then begin
    result:=1;
    if a>0 then
      for i:=1 to trunc(a) do
        result:=result*x
    else
      for i:=1 to trunc(a) do
        result:=result/x;
  end else begin
  //if caneval then
  try
    result:=exp(a*ln(x));
  except
    //caneval:=false;
  end;
  end;
end;
function log(a,b:real):real;
begin
  //if {caneval} then
  try
    result:=ln(b)/ln(a);
  except
    //caneval:=false;
  end;
end;
begin
  //caneval:=true;
  try
    //Result:=ex(9,2*x-sqrt(x*x-1))-4*ex(3,2*x+1-sqrt(x*x-1))+27;
    //Result:=ex(4,ex(x,4)+2)+ex(7,ex(x,2))-16-ex(cos(x),2);
    result:=(3*x*x-36*x+36)*ex(10,x/ln(10));
    ////////////////////
    if result>plim then result:=plim
    else if result<nlim then result:=nlim
    else if abs(result)<pzl then result:=0;
  except
    //caneval:=false;
    Result:=invalid;
  end;
end;

function rchar(c:char;n:integer):string;
var i:integer;
begin
  result:='';
  for i:=1 to n do
    result:=result+c;
end;

procedure Display(Draw:boolean);
var
  xlr,xrr,ytr,ybr:real;
  ws,hs:integer;
  xi,y,i:integer;
  xir,nppr,yr:real;
  prev:real;
  ader:real;
  flag:boolean;
  s:string;
 function RStr(r:real;m,n:integer):string;
 var s:string;
 begin
   str(r:m:n,s);
   RStr:=s;
 end;
 function RtoSadapt(r:real):string;
 begin
   if abs(r)<plim then result:=RStr(r,5,2)
   else if r=invalid then result:='[Invalid]'
   else if r<=nlim then result:='-Infinity'
   else if r>=plim then result:='+Infinity'
   else result:='[ERROR]';
 end;
 function GetSwitch(s:boolean):string;
 begin
   result:='Disabled';
   if s then result:='Enabled '
 end;
 function RtoSx(xr:real):integer;
 begin
   Result:=round((xr-xlr)*ppnr);
 end;
 function RtoSy(yr:real):integer;
 begin
   try Result:=round((ytr-yr)*ppnr); except writeln((ytr-yr)*ppnr,' is too large to round') end
 end;
 function StoRx(xs:integer):real;
 begin
   Result:=xs/ppnr+xlr;
 end;
 function StoRy(ys:integer):real;
 begin
   Result:=ytr-ys/ppnr;
 end;
 procedure navigate;
    var
      x,y,ox,oy,ywl,xwl,ywg,xwg:integer;
      rx,ry:real;
      currnumber,step,tsgl,tsloc:integer;
      gex,lex:boolean;
    function getstep:integer;
    begin
      if ppnr>30 then result:=1
      else if ppnr>5 then result:=5
      else if ppnr>2.5 then result:=10
      else if ppnr>1 then result:=25
      else if ppnr>0.25 then result:=100
      else result:=1000;
    end;
    begin
      ox:=RtoSx(0);
      oy:=RtoSy(0);
      if ppnr>40 then
        tsgl:=tsl
      else
        tsgl:=tsm;
      tsloc:=tsm;
      step:=getstep;
      ////////////////
        rx:=-frac(xlr)*ppnr;
        y:=hs div 2;
        gex:=(ybr<0)and(ytr>0)and global;
        lex:=(abs(y-oy)>3)and local;
        if gex then begin
          SetPenColor(clMaroon);
          line(0,oy,ws,oy);
        end;
        if lex then begin
          SetPenColor(clolive);
          line(0,y,ws,y);
        end;
        currnumber:=trunc(xlr);
        ywl:=gw+2;
        ywg:=gw+2;
        while abs(currnumber) mod step<>0 do begin
          inc(currnumber);
          rx:=rx+ppnr;
        end;
        while rx<ws do begin
          x:=round(rx);
          s:=inttostr(currnumber);
          xwg:=round((tsgl/3)*length(s));
          xwl:=round((tsloc/2)*length(s));
          if (currnumber<>0) then begin
            if gex then begin
              setfontsize(tsgl);
              SetPenColor(clMaroon);
              line(x,oy+gw,x,oy-gw);
              textout(x-xwg,oy+ywg,s);
            end;
            if lex then begin
              setfontsize(tsloc);
              SetPenColor(clolive);
              line(x,y+gw,x,y-gw);
              textout(x-xwl,y+ywl,s);
            end;
          end;
          rx:=rx+ppnr*step;
          currnumber:=currnumber+step;
        end;
        //////////////////////////////////
        ry:=frac(ytr)*ppnr;
        x:=ws div 2;
        gex:=(xlr<0)and(xrr>0)and global;
        lex:=(abs(x-ox)>3)and local;
        if gex then begin
          SetPenColor(clMaroon);
          line(ox,0,ox,hs);
        end;
        if lex then begin
          SetPenColor(clolive);
          line(x,0,x,hs);
        end;
        currnumber:=trunc(ytr);
        ywl:=round(tsloc/1.25);
        ywg:=round(tsgl/1.41);
        while abs(currnumber) mod step<>0 do begin
          dec(currnumber);
          ry:=ry+ppnr;
        end;
        while ry<hs do begin
          y:=round(ry);
          s:=inttostr(currnumber);
          xwg:=round(tsgl*length(s)/1.41)+gw+2;
          xwl:=round(tsloc*length(s))+gw+2;
          if currnumber<>0 then begin
            if gex then begin
              setfontsize(tsgl);
              SetPenColor(clMaroon);
              textout(ox-xwg,y-ywg,s);
              line(ox-gw,y,ox+gw,y);
            end;
            if lex then begin
              setfontsize(tsloc);
              SetPenColor(clolive);
              textout(x-xwl,y-ywl,s);
              line(x-gw,y,x+gw,y);
            end;
          end;
          ry:=ry+ppnr*step;
          currnumber:=currnumber-step;
        end;
end;
begin
  ws:=WindowWidth;
  hs:=WindowHeight;
  nppr:=1/ppnr;
  xrr:=x0+ws*nppr/2;
  xlr:=xrr-ws*nppr;
  ytr:=y0+hs*nppr/2;
  ybr:=ytr-hs*nppr;
  if Draw then begin
  ClearWindow(wc);
  SetPenColor(lc);
  flag:=false;
  xir:=xlr;
  for xi:=0 to ws do begin
    yr:=evalfunc(xir);
    if prev<>invalid then
      ader:=abs(yr-prev)
    else
      ader:=0;
    if (yr=invalid) then
      flag:=false
    else begin
      if flag and (ader<derlim) then begin
        LineTo(xi,RtoSy(yr));
      end else begin
        y:=RtoSy(yr);
        setpixel(xi,y,lc);
        MoveTo(xi,y);
        flag:=true;
      end;
    end;
    prev:=yr;
    xir:=xir+nppr;
  end;
  navigate;
  {SetPenColor(clolive);
  line(0,mousey,ws,mousey);
  line(mousex,0,mousex,hs);//}
  end;
  if info then begin
    setfontsize(tsl);
    TextOut(5,5,'Pixels per number: '+RStr(ppnr,5,2));
    ////////////
    TextOut(5,25,'Field resolution: '+inttostr(ws)+'x'+inttostr(hs));
    TextOut(15,65,RStr(xlr,8,2));
    TextOut(95,65,RStr(xrr,8,2));
    TextOut(55,45,RStr(ytr,8,2));
    TextOut(55,85,RStr(ybr,8,2));
    TextOut(5,105,'Center X: '+RStr(x0,8,2));
    TextOut(5,125,'Center Y: '+RStr(y0,8,2));
    TextOut(5,145,'Moving speed: '+RStr(moveq,8,2));
    TextOut(5,165,'Shift: '+GetSwitch(shift));
    TextOut(5,185,'Ctrl: '+GetSwitch(ctrl));
    TextOut(ws-80,5,'X: '+RStr(StoRx(mousex),5,2)+rchar(' ',15));
    TextOut(ws-80,25,'Y: '+RStr(StoRy(mousey),5,2)+rchar(' ',15));
    TextOut(ws-80,50,'f(x)= '+RtoSadapt(evalfunc(StoRx(mousex)))+rchar(' ',15));
  end;
end;
procedure DisplayAll;begin Display(true);end;


procedure drawconsole;var s:string;c:char;begin
  s:=intro+input;
  if curs then c:='|' else c:=' ';
  insert(c,s,cursor+length(intro)+1);
  TextOut(0,WindowHeight-25,rchar(' ',200));
  TextOut(0,WindowHeight-25,s);
  curs:=not curs;
end;
procedure KeyUp(Key:integer);
begin
  case Key of
    VK_Control:ctrl:=false;
    VK_Shift:shift:=false;
  end;
  Display(false);
end;
procedure KeyDown(Key:integer);
procedure ml(n:real);begin if n=0 then x0:=x0-moveq/ppnr else x0:=x0-n; DisplayAll; end;
procedure mr(n:real);begin if n=0 then x0:=x0+moveq/ppnr else x0:=x0+n; DisplayAll; end;
procedure mu(n:real);begin if n=0 then y0:=y0+moveq/ppnr else y0:=y0+n; DisplayAll; end;
procedure md(n:real);begin if n=0 then y0:=y0-moveq/ppnr else y0:=y0-n; DisplayAll; end;
procedure smh;begin x0:=0; y0:=0; DisplayAll; end;
procedure amh;begin x0:=0; y0:=0; ppnr:=100; DisplayAll; end;
procedure szoomout;begin if ppnr>=5*ppnr/moveq then ppnr:=ppnr-5*ppnr/moveq else ppnr:=1; DisplayAll; end;
procedure szoomin;begin ppnr:=ppnr+5*ppnr/moveq; DisplayAll; end;
procedure move(x,y:real);begin x0:=x;y0:=y;DisplayAll; end;
/////////////////////////

procedure cursormove(n:integer;word:boolean);
begin
    cursor:=cursor+n;
  if cursor<0 then cursor:=0;
  if cursor>length(input) then cursor:=length(input);
  drawconsole
end;
procedure typechar(c:integer);begin
  if (length(intro+input)<200)and(c>0) then begin
    insert(chr(c),input,cursor+1);
    inc(cursor);
  end;
  drawconsole
end;
procedure delchar;begin
  if (cursor>0) then begin
    delete(input,cursor,1);
    dec(cursor);
    drawconsole
  end;
end;
procedure GetConsole(s:string);
begin
  setfontsize(tsl);
  intro:=s+'>>';
  input:='';
  cursor:=0;
  console:=true;
  drawconsole;
  StartTimer(timer);
end;
procedure GetConsole;begin GetConsole('');end;
////////////////////////////////////////////////
procedure ProcessConsole;
var
  s,fs:string;
function getelement(var s:string):string;
begin
  result:=copy(s,1,pos(' ',s)-1);
  delete(s,1,length(result)+1);
end;
function getargsam(s:string):integer;
begin
       if (fs='home')or(fs='reset') then result:=0
  else if (fs='l')or(fs='r')or(fs='u')or(fs='d')or(fs='zoom') then result:=1
  else if fs='move' then result:=2
  else result:=-1;
end;
function toint(s:string):integer;
begin
  result:=trunc(strtofloat(s));
end;
function toreal(s:string):real;
begin
  result:=strtofloat(s);
end;
begin
  console:=false;
  StopTimer(timer);
  s:=input+' ';
  fs:=getelement(s);
  fs:=lowercase(fs);
  inargam:=0;
  if (fs<>'break') then begin
    while (length(s)>0)and(inargam<getargsam(fs)) do begin
      inc(inargam);
      inarg[inargam]:=getelement(s);
    end;
    try
           if fs='l' then ml(toreal(inarg[1]))
      else if fs='r' then mr(toreal(inarg[1]))
      else if fs='u' then mu(toreal(inarg[1]))
      else if fs='d' then md(toreal(inarg[1]))
      else if fs='home' then smh
      else if fs='reset' then amh
      else if fs='zoom' then ppnr:=1/toreal(inarg[1])
      else if fs='move' then move(toreal(inarg[1]),toreal(inarg[2]));
    except end;
  end;
  displayAll;
end;
////////////
begin
  case Key of
    VK_Left:    case mode of 1:ml(0); 5:cursormove(-1,false); 6:cursormove(-1,true); end;
    VK_Right:   case mode of 1:mr(0); 5:cursormove(1,false); 6:cursormove(1,true); end;
    VK_Up:      case mode of 1:mu(0); end;
    VK_Down:    case mode of 1:md(0); end;
    VK_Back:    case mode of 5:delchar; end;
    VK_Return:  case mode of 1:GetConsole; 5:ProcessConsole; end;
    VK_PageUp:  case mode of 1:szoomin; end;
    VK_PageDown:case mode of 1:szoomout; end;
    VK_Home:    case mode of 1:smh; 2:amh; end;
    VK_End:     case mode of 1:; end;
    VK_Insert:  case mode of 1:savewindow('screen.jpg'); end;
    VK_Delete:  case mode of 1:; end;
    VK_Control: ctrl:=true;
    VK_Shift:   shift:=true;
    else if console then begin
      typechar(key);
    end;
  end;
  mode:=1;
  if ctrl then mode:=mode+1;
  if shift then mode:=mode+2;
  if console then mode:=mode+4;
  if key=VK_Escape then mode:=0;
end;

procedure MouseMove(x,y,mb:integer);
begin
  mousex:=x;
  mousey:=y;
  if mb=0 then
  Display(false)
  else begin
    x0:=x0-(mousex-mousesx)/ppnr;
    y0:=y0+(mousey-mousesy)/ppnr;
    mousesx:=mousex;
    mousesy:=mousey;
    DisplayAll;
  end;
end;
procedure MouseDown(x,y,mb:integer);
begin
  mousesx:=x;
  mousesy:=y;
end;

procedure Init;
begin
  SetWindowCaption('Graphic 0.9.6');
  SetWindowWidth(1280);
  SetWindowHeight();
  lc:=clRed;
  wc:=clLightGray;
  ppnr:=100;
  nppr:=1/ppnr;
  moveq:=50;
  tsl:=10;
  tsm:=6;
  tss:=4;
  gw:=3;
  x0:=0;
  y0:=0;
  global:=true;
  local:=true;
  info:=true;
  ctrl:=false;
  shift:=false;
  console:=false;
  mode:=1;
  centerwindow;
end;

begin
  Init;
  DisplayAll;
  OnResize:=DisplayAll;
  OnKeyDown:=KeyDown;
  OnKeyUp:=KeyUp;
  OnMouseMove:=MouseMove;
  OnMouseDown:=MouseDown;
  timer:=CreateTimer(400,drawconsole);
  StopTimer(timer);
end.