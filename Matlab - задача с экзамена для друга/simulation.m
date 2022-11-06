% ������ ���������
function simulation()
    clear timers;
    
    % ���������� ���������
    global y_target y_current t_current offset note lines;
    t_current = 0; % ������� �����
    y_target = 0; % ������� ������� �������
    y_current = 0; % ������� �������
    offset = 0; % ������� �������� ������������ ����������� ����
    
    % ����� ������� ��������
    delete(note);
    delete(lines);
    note = text(); % ����� ����� �������� � �������� �� �������

    % ������ FIS
    global fis;
    fis = readfis('var10_7-5.fis'); % ������ ���������� �������� ������

    % ������� ������ ��������� ��� ������������ ��������
    global table_y_target table_y_current table_y_zero table_y_current_zero table_t_current;
    table_y_target = [y_target];
    table_y_current = [y_current];
    table_t_current = [0];
    table_y_zero = [0];
    table_y_current_zero = [y_current - y_target];

    global t_step t_target;
    t = timer;
    t.TimerFcn = @sim_step; % �-� ���� ���������
    t.Period = t_step;
    t.StartDelay = t_step;
    t.TasksToExecute = ceil(t_target/t.Period); % ��������� �������������� ����� � ������� �������
    t.ExecutionMode = 'fixedDelay'; % ����� ���������� ��� ����� ��������� ��������� �������
    t.BusyMode = 'queue'; % � ���������� � ����, ����� ������ �� ������������ �� ������ ������������� ������������
    start(t);
end
% ��� ���������
function sim_step(~,~)
    global y_target y_current t_current t_step t0 fis y0 offset note lines; % ���������� ���������
    global axes1 axes2 plot1_target plot1_current plot2_target plot2_current; % ������� �� ����
    global table_y_target table_y_current table_t_current table_y_zero table_y_current_zero; % ������� ��� ��������
    
    % ������ ��� �� �������
    t_current = t_current + t_step;
    
    % ��������� �������
    table_t_current(end + 1) = t_current;  
    table_y_target(end + 1) = y_target;
    table_y_current(end + 1) = y_current;
    table_y_zero(end + 1) = 0;
    table_y_current_zero(end + 1) = y_current - y_target;

    % ���� ������ ����� �������� ������� ������� � ������� ����������
    % ��������
    if t_current >= t0
        % ��������� ������� �������
        if y_target ~= y0
            y_target = y0;
            % � �� ������� - ����, � ��������
            table_y_target(end) = NaN; % Not a number - �� �����, ����� ������� ������ ������� ������ �� �������
            table_y_current_zero(end) = y_current - y_target;
        end
        % ���� �� ��� ��������� ������ � ����� � ���� �������
        if abs(y_current - y_target) < y_target*0.05 && isempty(get(note,'String')) % abs - ������ �����
            % ������� ��������� �������
            note = text(t_current, y_current-1, char(sprintf(' ������� �� %g �', t_current-t0)));
            % � ������� ������� ��� �����������
            lines = [...
                line(axes1,[t_current t_current],get(axes1,'YLim'),'Color',[0 1 0]),...
                line(axes2,[t_current t_current],get(axes2,'YLim'),'Color',[0 1 0])];
        end
    end
    
    % ������ �� �����
    offset = evalfis([y_current-y_target, offset/t_step], fis); % ���-�� ��� �������� � ��� ������ �� ������������, �� ����� �����
    y_current = y_current + offset;
    sum(abs(table_y_current_zero)) % ������� ���������� ��������
    
    % ������ ����� ����� �� ��������
    set(plot1_target, 'xdata',table_t_current,'ydata',table_y_target);
    set(plot1_current,'xdata',table_t_current,'ydata',table_y_current);
    set(plot2_target, 'xdata',table_t_current,'ydata',table_y_zero);
    set(plot2_current,'xdata',table_t_current,'ydata',table_y_current_zero);
    drawnow; % ������ ������!
end