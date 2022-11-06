% Таймер симуляции
function simulation()
    clear timers;
    
    % Переменные симуляции
    global y_target y_current t_current offset note lines;
    t_current = 0; % Текущее время
    y_target = 0; % Текущий целевой уровень
    y_current = 0; % Текущий уровень
    offset = 0; % Текущее смещение относительно предыдущего шага
    
    % Сброс подписи перехода
    delete(note);
    delete(lines);
    note = text(); % Пишет время перехода в инфополе на графике

    % Чтение FIS
    global fis;
    fis = readfis('var10_7-5.fis'); % Задано редактором нечеткой логики

    % Таблицы данных симуляции для динамических графиков
    global table_y_target table_y_current table_y_zero table_y_current_zero table_t_current;
    table_y_target = [y_target];
    table_y_current = [y_current];
    table_t_current = [0];
    table_y_zero = [0];
    table_y_current_zero = [y_current - y_target];

    global t_step t_target;
    t = timer;
    t.TimerFcn = @sim_step; % Ф-я шага симуляции
    t.Period = t_step;
    t.StartDelay = t_step;
    t.TasksToExecute = ceil(t_target/t.Period); % Округляет действительное число в большую сторону
    t.ExecutionMode = 'fixedDelay'; % Режим специально для такой симуляции реального времени
    t.BusyMode = 'queue'; % И дополнение к нему, чтобы задачи не сбрасывались на слабых конфигурациях оборудования
    start(t);
end
% Шаг симуляции
function sim_step(~,~)
    global y_target y_current t_current t_step t0 fis y0 offset note lines; % Переменные симуляции
    global axes1 axes2 plot1_target plot1_current plot2_target plot2_current; % Графики на осях
    global table_y_target table_y_current table_t_current table_y_zero table_y_current_zero; % Таблицы для графиков
    
    % Делаем шаг во времени
    t_current = t_current + t_step;
    
    % Дополняем таблицы
    table_t_current(end + 1) = t_current;  
    table_y_target(end + 1) = y_target;
    table_y_current(end + 1) = y_current;
    table_y_zero(end + 1) = 0;
    table_y_current_zero(end + 1) = y_current - y_target;

    % Если пришло время поменять целевой уровень и сделать дальнейшие
    % операции
    if t_current >= t0
        % Переводим целевой уровень
        if y_target ~= y0
            y_target = y0;
            % И на графике - тоже, с разрывом
            table_y_target(end) = NaN; % Not a number - не число, самый простой способ сделать разрыв на графике
            table_y_current_zero(end) = y_current - y_target;
        end
        % Если мы уже выполнили задачу и вошли в зону уставки
        if abs(y_current - y_target) < y_target*0.05 && isempty(get(note,'String')) % abs - модуль числа
            % Выведем результат текстом
            note = text(t_current, y_current-1, char(sprintf(' Переход за %g с', t_current-t0)));
            % И линиями отсечем для наглядности
            lines = [...
                line(axes1,[t_current t_current],get(axes1,'YLim'),'Color',[0 1 0]),...
                line(axes2,[t_current t_current],get(axes2,'YLim'),'Color',[0 1 0])];
        end
    end
    
    % Влияем на точку
    offset = evalfis([y_current-y_target, offset/t_step], fis); % Так-то эта скорость в фис вообще не понадобилась, но пусть будет
    y_current = y_current + offset;
    sum(abs(table_y_current_zero)) % Считаем показатель качества
    
    % Рисуем новые точки на графиках
    set(plot1_target, 'xdata',table_t_current,'ydata',table_y_target);
    set(plot1_current,'xdata',table_t_current,'ydata',table_y_current);
    set(plot2_target, 'xdata',table_t_current,'ydata',table_y_zero);
    set(plot2_current,'xdata',table_t_current,'ydata',table_y_current_zero);
    drawnow; % Строим график!
end