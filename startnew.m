%% 实时定价与对冲监控系统
clear;clc;close all;
warning off; %#ok<*WNOFF> 
%% OTC 定价参数设置 定价只需在后面加item即可
ud.code    = {'M1709.DCE','C1709.DCE';'M1709.DCE', 'C1709.DCE'}; % 标的资产代码；详细可参考文件：期货标的Wind列表.pdf
ud.side    = {'sellcall'; 'sellcall'; };         % 交易方向：sellcall, buycall, sellput, buyput
ud.strike  = [1103; 1103;];                        % 执行价格
ud.exercisedates = {'2017-9-29'; '2017-9-29';}; % 行权日期
ud.type    = [1 ; 1];        % 期权类型：1：Spread Option
ud.premium = [1.25,1.25; 1.1,1.2;]; % 期权定价时波动率的溢价幅度
ud.num = [1, 1 ; 1 , 2];       % 标的资产的分数
ud.Div=[0, 0; 0, 0];         % 股票期权股息，暂时不适用于亚式期权
ud.corr = [0.35;0.25;];     % 标的资产的价格相关系数
%% 基差期权对冲参数设置
ud.hedge    = [1];            % 是否对冲设置: 0/1
ud.volume   = [100 ; 1000];      % 交易量
ud.ordinaryDelta = [0, 0.2; 0.2, 0.2]; % 日常Delta变动阈值
ud.lastweekDelta = [0.15, 0.25; 0.15, 0.25]; % 最后一周Delta变动阈值
ud.lastdayDelta  = [0.1, 0.3; 0.1, 0.3]; % 最后一天Delta变动阈值
%% 监控参数设置
t = timer;
t.Name     = 'HedgeTimer';
t.UserData = ud;              % 传入数据
t.TimerFcn = @DynamicHedgeNew;
t.Period   = 180;             % 执行任务间隔时间
t.ExecutionMode = 'fixedrate';  
%t.TasksToExecute = 1;        % 如果不对冲，则值运行一次
global n
n=1;
%% Start/Stop
start(t);
% {
% stop(t)     % 停止监控
% }