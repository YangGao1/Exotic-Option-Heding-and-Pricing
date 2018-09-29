%% ʵʱ������Գ���ϵͳ
clear;clc;close all;
warning off; %#ok<*WNOFF> 
%% OTC ���۲������� ����ֻ���ں����item����
ud.code    = {'M1709.DCE','C1709.DCE';'M1709.DCE', 'C1709.DCE'}; % ����ʲ����룻��ϸ�ɲο��ļ����ڻ����Wind�б�.pdf
ud.side    = {'sellcall'; 'sellcall'; };         % ���׷���sellcall, buycall, sellput, buyput
ud.strike  = [1103; 1103;];                        % ִ�м۸�
ud.exercisedates = {'2017-9-29'; '2017-9-29';}; % ��Ȩ����
ud.type    = [1 ; 1];        % ��Ȩ���ͣ�1��Spread Option
ud.premium = [1.25,1.25; 1.1,1.2;]; % ��Ȩ����ʱ�����ʵ���۷���
ud.num = [1, 1 ; 1 , 2];       % ����ʲ��ķ���
ud.Div=[0, 0; 0, 0];         % ��Ʊ��Ȩ��Ϣ����ʱ����������ʽ��Ȩ
ud.corr = [0.35;0.25;];     % ����ʲ��ļ۸����ϵ��
%% ������Ȩ�Գ��������
ud.hedge    = [1];            % �Ƿ�Գ�����: 0/1
ud.volume   = [100 ; 1000];      % ������
ud.ordinaryDelta = [0, 0.2; 0.2, 0.2]; % �ճ�Delta�䶯��ֵ
ud.lastweekDelta = [0.15, 0.25; 0.15, 0.25]; % ���һ��Delta�䶯��ֵ
ud.lastdayDelta  = [0.1, 0.3; 0.1, 0.3]; % ���һ��Delta�䶯��ֵ
%% ��ز�������
t = timer;
t.Name     = 'HedgeTimer';
t.UserData = ud;              % ��������
t.TimerFcn = @DynamicHedgeNew;
t.Period   = 180;             % ִ��������ʱ��
t.ExecutionMode = 'fixedrate';  
%t.TasksToExecute = 1;        % ������Գ壬��ֵ����һ��
global n
n=1;
%% Start/Stop
start(t);
% {
% stop(t)     % ֹͣ���
% }