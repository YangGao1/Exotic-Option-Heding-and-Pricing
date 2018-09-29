%% 实时定价与对冲监控系统
clear;clc;close all;
warning off; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 注意：修改参数需删除InitDelta.mat文件，添加参数时不必删除！
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 注意：修改任何有关已经设定过的亚视期权的参数时需删除hedgevolumeseries.mat文件！
%% 若不修改已经运行过的亚式期权的参数，仅在不同时间运行不需要删除。
%% OTC 定价参数设置 定价只需在后面加item即可
ud.code    = {'JD1801.DCE'; 'JD1801.DCE'; 'JD1801.DCE'}; % 标的资产代码；详细可参考文件：期货标的Wind列表.pdf
ud.side    = {'sellcall'; 'sellcall'; 'sellcall'};         % 交易方向：sellcall, buycall, sellput, buyput
ud.strike  = [ 4100; 4200; 4200];                        % 执行价格
ud.settle = {'2017-8-28'; '2017-9-20'; '2017-9-1',}; % 签约日期
ud.exercisedates = {'2017-9-28'; '2017-10-25'; '2017-10-1'}; % 行权日期
ud.type    = [8; 5; 8];        % 期权类型：European:1  American:2  Asian:3  Binary:4  Asian Option:5; Shout Option 6: Asian Shout Option 7; Adjusted Asian OPtion 8
ud.premium = [1.33; 1.33; 1.33]; % 期权定价时波动率的溢价幅度
ud.hedgevol = [0.34;0.34;0.34];   %%    对冲时自定义的波动率
ud.yield   = [0; 0; 0];        % 股票期权股息
%% 对冲参数设置
ud.hedge    = [1; 1; 1];            % 是否对冲设置: 0/1
ud.volume   = [20; 6; 50];         % 交易量
ud.ordinaryDelta = [0.2; 0.15; 0.15]; % 日常Delta变动阈值
ud.lastweekDelta = [0.15; 0.2; 0.2]; % 最后一周Delta变动阈值
ud.lastdayDelta  = [0.1; 0.25; 0.25]; % 最后一天Delta变动阈值
%% 亚视期权参数设置：
ud.firstDelta = [0.1; 0.1; 0.1];%仅适用于亚式期权，后面仅亚式期权会提取该处数据，表示在前四分之一的交易日内设置的比例
ud.middleDelta = [0.05; 0.05; 0.05];%表示在前四分之一到前二分之一的交易日内设置的比例
ud.lastDelta = [0.03; 0.03; 0.03];%表示在后面二分之一的交易日内设置的比例
%% 二元期权参数设置：不是二元期权则设为0
ud.pCStrike = [1.05; 1; 1];    % Call Strike变动幅度
ud.pPStrike = [ 0.95; 1; 1];    % Put Strike变动幅度
ud.pCash    = [0.05; 1; 1];    % 支付额占现价的比率
ud.settleprice = [4388; 3150; 3000]; % 二元期权签约时的标的价格
%% (亚式）呼叫期权的参数设置：不是呼叫期权则设为0

ud.ShoutPrice = [4000;0;0];

%% 调整的亚式期权参数设置
ud.t1=[0.02;0.02;0.02];

%% 监控参数设置
t = timer;
t.Name     = 'HedgeTimer';
t.UserData = ud;              % 传入数据
t.TimerFcn = @DynamicHedge2;
t.Period   = 360;             % 执行任务间隔时间
t.ExecutionMode = 'fixedrate';  
%t.TasksToExecute = 1;        % 如果不对冲，则值运行一次
%% Start/Stop
start(t);
%pause(3600*3);
%{
stop(t)     % 停止监控
%}