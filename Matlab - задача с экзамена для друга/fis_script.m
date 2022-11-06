clear variables;

% ��������� ���������
global t0 t_step y0 t_target; % ��������� ������������ ���� � �� �� ���������� � ������� � �������
t0 = 2.6; % ����� ������������
t_step = 0.1; % ��� ������� ���������
y0 = 2.1; % ������� ������� ����� ������������
t_target = 5; % ������������ ���������

% ����
scrsz = get(0,'ScreenSize');
figure('Position',[0 100 scrsz(3) scrsz(4)-150],...
    'name','�������� ��������� �������� �����',...
    'IntegerHandle','off','menubar','none');

% ����-����
uicontrol('Style','text','Position',[scrsz(3)-400 scrsz(4)-240 400 40],...
    'FontSize',16, 'FontName','Times','String','��������� ��� ���. �10:');
uicontrol('Style','text','Position',[scrsz(3)-400 scrsz(4)-280 400 40],...
    'FontSize',16,'HorizontalAlignment','left',...
    'FontName','Times','String',char(sprintf('��������� ������� (y0) = %g', y0)));
uicontrol('Style','text','Position',[scrsz(3)-400 scrsz(4)-320 400 40],...
    'FontSize',16,'HorizontalAlignment','left',...
    'FontName','Times','String',char(sprintf('����� ������������ (t0) = %g �', t0)));
uicontrol('Style','text','Position',[scrsz(3)-400 scrsz(4)-360 400 40],...
    'FontSize',16,'HorizontalAlignment','left',...
    'FontName','Times','String',char(sprintf('��� ������� ��������� (t_step) = %g c', t_step)));

% ������
uicontrol('Style','pushbutton','String','������������� ��������',...
'Position',[scrsz(3)-380 scrsz(4)-450 340 40],'FontName','Times','FontSize',14,'Callback','simulation');
uicontrol('Style','pushbutton','String','����� �� ���������',...
'Position',[scrsz(3)-380 scrsz(4)-500 340 40],'FontName','Times','FontSize',14,'Callback','close');

% ������
global axes1 plot1_target plot1_current;
axes1 = axes('outerPosition',[0 0.5 0.7 0.5]); % ������ ������� ���� ������������ �������� ����
plot1_target = plot(0,0);
hold on;
plot1_current = plot(0,0,'color','r','LineWidth',2); % �������� ���������� ������ ������-�����
hold on;
axis([0 t_target -1 y0+1]); % ����������, �� ����� ��� �� ����� ������� ������
grid on; % �������� �����

global axes2 plot2_target plot2_current;
axes2 = axes('outerPosition',[0 0 0.7 0.5]);
plot2_target = plot(0,0);
hold on;
plot2_current = plot(0,0,'color','r','LineWidth',2); % �������� ���������� ������ ������-�����
hold on;
axis([0 t_target -y0-1 1]); % ����������, �� ����� ��� �� ����� ������� ������
grid on; % �������� �����

simulation() % ������ ��������� ��� ������