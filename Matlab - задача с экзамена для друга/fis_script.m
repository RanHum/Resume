clear variables;

% Параметры симуляции
global t0 t_step y0 t_target; % Позволяет использовать одни и те же переменные в функции и скрипте
t0 = 2.6; % Время переключения
t_step = 0.1; % Шаг времени симуляции
y0 = 2.1; % Целевой уровень после переключения
t_target = 5; % Длительность симуляции

% Окно
scrsz = get(0,'ScreenSize');
figure('Position',[0 100 scrsz(3) scrsz(4)-150],...
    'name','Нечеткий регулятор движения точки',...
    'IntegerHandle','off','menubar','none');

% Инфо-поля
uicontrol('Style','text','Position',[scrsz(3)-400 scrsz(4)-240 400 40],...
    'FontSize',16, 'FontName','Times','String','Параметры для вар. №10:');
uicontrol('Style','text','Position',[scrsz(3)-400 scrsz(4)-280 400 40],...
    'FontSize',16,'HorizontalAlignment','left',...
    'FontName','Times','String',char(sprintf('Требуемый уровень (y0) = %g', y0)));
uicontrol('Style','text','Position',[scrsz(3)-400 scrsz(4)-320 400 40],...
    'FontSize',16,'HorizontalAlignment','left',...
    'FontName','Times','String',char(sprintf('Время переключения (t0) = %g с', t0)));
uicontrol('Style','text','Position',[scrsz(3)-400 scrsz(4)-360 400 40],...
    'FontSize',16,'HorizontalAlignment','left',...
    'FontName','Times','String',char(sprintf('Шаг времени симуляции (t_step) = %g c', t_step)));

% Кнопки
uicontrol('Style','pushbutton','String','Моделирование процесса',...
'Position',[scrsz(3)-380 scrsz(4)-450 340 40],'FontName','Times','FontSize',14,'Callback','simulation');
uicontrol('Style','pushbutton','String','Выход из программы',...
'Position',[scrsz(3)-380 scrsz(4)-500 340 40],'FontName','Times','FontSize',14,'Callback','close');

% График
global axes1 plot1_target plot1_current;
axes1 = axes('outerPosition',[0 0.5 0.7 0.5]); % Задаем позицию осей относительно размеров окна
plot1_target = plot(0,0);
hold on;
plot1_current = plot(0,0,'color','r','LineWidth',2); % Выделяем актуальный график красно-жирно
hold on;
axis([0 t_target -1 y0+1]); % Определяем, до каких пор мы будем чертить график
grid on; % Включаем сетку

global axes2 plot2_target plot2_current;
axes2 = axes('outerPosition',[0 0 0.7 0.5]);
plot2_target = plot(0,0);
hold on;
plot2_current = plot(0,0,'color','r','LineWidth',2); % Выделяем актуальный график красно-жирно
hold on;
axis([0 t_target -y0-1 1]); % Определяем, до каких пор мы будем чертить график
grid on; % Включаем сетку

simulation() % Запуск симуляции при старте