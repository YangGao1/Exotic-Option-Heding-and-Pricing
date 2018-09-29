%% ʵʱ������Գ���ϵͳ
clear;clc;close all;
warning off; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ע�⣺�޸Ĳ�����ɾ��InitDelta.mat�ļ�����Ӳ���ʱ����ɾ����
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ע�⣺�޸��κ��й��Ѿ��趨����������Ȩ�Ĳ���ʱ��ɾ��hedgevolumeseries.mat�ļ���
%% �����޸��Ѿ����й�����ʽ��Ȩ�Ĳ��������ڲ�ͬʱ�����в���Ҫɾ����
%% OTC ���۲������� ����ֻ���ں����item����
ud.code    = {'JD1801.DCE'; 'JD1801.DCE'; 'JD1801.DCE'}; % ����ʲ����룻��ϸ�ɲο��ļ����ڻ����Wind�б�.pdf
ud.side    = {'sellcall'; 'sellcall'; 'sellcall'};         % ���׷���sellcall, buycall, sellput, buyput
ud.strike  = [ 4100; 4200; 4200];                        % ִ�м۸�
ud.settle = {'2017-8-28'; '2017-9-20'; '2017-9-1',}; % ǩԼ����
ud.exercisedates = {'2017-9-28'; '2017-10-25'; '2017-10-1'}; % ��Ȩ����
ud.type    = [8; 5; 8];        % ��Ȩ���ͣ�European:1  American:2  Asian:3  Binary:4  Asian Option:5; Shout Option 6: Asian Shout Option 7; Adjusted Asian OPtion 8
ud.premium = [1.33; 1.33; 1.33]; % ��Ȩ����ʱ�����ʵ���۷���
ud.hedgevol = [0.34;0.34;0.34];   %%    �Գ�ʱ�Զ���Ĳ�����
ud.yield   = [0; 0; 0];        % ��Ʊ��Ȩ��Ϣ
%% �Գ��������
ud.hedge    = [1; 1; 1];            % �Ƿ�Գ�����: 0/1
ud.volume   = [20; 6; 50];         % ������
ud.ordinaryDelta = [0.2; 0.15; 0.15]; % �ճ�Delta�䶯��ֵ
ud.lastweekDelta = [0.15; 0.2; 0.2]; % ���һ��Delta�䶯��ֵ
ud.lastdayDelta  = [0.1; 0.25; 0.25]; % ���һ��Delta�䶯��ֵ
%% ������Ȩ�������ã�
ud.firstDelta = [0.1; 0.1; 0.1];%����������ʽ��Ȩ���������ʽ��Ȩ����ȡ�ô����ݣ���ʾ��ǰ�ķ�֮һ�Ľ����������õı���
ud.middleDelta = [0.05; 0.05; 0.05];%��ʾ��ǰ�ķ�֮һ��ǰ����֮һ�Ľ����������õı���
ud.lastDelta = [0.03; 0.03; 0.03];%��ʾ�ں������֮һ�Ľ����������õı���
%% ��Ԫ��Ȩ�������ã����Ƕ�Ԫ��Ȩ����Ϊ0
ud.pCStrike = [1.05; 1; 1];    % Call Strike�䶯����
ud.pPStrike = [ 0.95; 1; 1];    % Put Strike�䶯����
ud.pCash    = [0.05; 1; 1];    % ֧����ռ�ּ۵ı���
ud.settleprice = [4388; 3150; 3000]; % ��Ԫ��ȨǩԼʱ�ı�ļ۸�
%% (��ʽ��������Ȩ�Ĳ������ã����Ǻ�����Ȩ����Ϊ0

ud.ShoutPrice = [4000;0;0];

%% ��������ʽ��Ȩ��������
ud.t1=[0.02;0.02;0.02];

%% ��ز�������
t = timer;
t.Name     = 'HedgeTimer';
t.UserData = ud;              % ��������
t.TimerFcn = @DynamicHedge2;
t.Period   = 360;             % ִ��������ʱ��
t.ExecutionMode = 'fixedrate';  
%t.TasksToExecute = 1;        % ������Գ壬��ֵ����һ��
%% Start/Stop
start(t);
%pause(3600*3);
%{
stop(t)     % ֹͣ���
%}