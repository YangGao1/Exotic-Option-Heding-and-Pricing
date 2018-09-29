function [] = DynamicHedgeNew(obj,~ )
%% set user data
w       = windmatlab;
ud      = obj.UserData;
Code    = ud.code;
Side    = ud.side;       %%
Strike  = ud.strike;     %%
Type    = ud.type;       %%
Premium = ud.premium;    %%
Corr = ud.corr;
Volatility=[];
Settle = datestr(datestr(today(),'yyyy-mm-dd')); %%
Exercisedates = ud.exercisedates;
%% hedge setting
Hedge   = ud.hedge;
Volume  = ud.volume;
ordinaryDelta = ud.ordinaryDelta;
lstweekDelta  = ud.lastweekDelta;
lstdayDelta   = ud.lastdayDelta;
global n 
%%
for i = 1:length(Type)
    Div1 = ud.Div(i,1);
    Div2 = ud.Div(i,2);
    num1 = ud.num(i,1);
    num2 = ud.num(i,2);
    %%
    fprintf('第%d个期权：\n',int8(i));
    for j = 1:length(Code(i,:))
    Price = w.wsq((Code(i,:)),'rt_last');   % 期货最新价格
    Rate  = w.wsq('CGB1Y.WI','rt_last')/100; % SHIBOR利率
    %%
    [EstVol,GarchVol,SellVol,BuyVol] = EstVolatility(char(Code(i,j)));
    PremiumVol  = Premium(i,j)*max(GarchVol,SellVol);
    DiscountVol = (2-Premium(i,j))*min(GarchVol,BuyVol);
    fprintf('历史均值估计的波动率为 %f\n',EstVol);
    fprintf('GARCH模型估计的波动率为 %f\n',GarchVol);
    if strcmp(Side(i),'sellcall') || strcmp(Side(i),'sellput')
        fprintf('卖出期权所估计的波动率为 %f\n',SellVol);
        fprintf('卖出期权时定价所使用波动率为 %f\n\n',PremiumVol);
        Volatility = [Volatility;PremiumVol];
    elseif strcmp(Side(i),'buycall') || strcmp(Side(i),'buyput')
        fprintf('买入期权所估计的波动率为 %f\n',BuyVol);
        fprintf('买入期权时定价所使用波动率为 %f\n\n',DiscountVol);
        Volatility = [Volatility;DiscountVol];
    end
    end
%% 基差期权的定价
if Type(i) == 1
Price1 = Price(1);Price2 = Price(2);
Vol1 = Volatility(1);Vol2 = Volatility(2);
if ~exist('IDelta.mat','file')
    InitDelta = zeros(2,2);
    save IDelta InitDelta;
end
load IDelta
if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
    OptSpec = 'call';
    [SpreadCallPrice, SpreadCallDelta,SpreadCallGamma] = SpredbyEurope(Price1,Price2,num1,num2,Strike(i),Vol1,Vol2,Div1,Div2,Corr(i),Settle,Exercisedates(i),Rate,OptSpec);
    fprintf('彩虹基差期权定价为 %f\n ',SpreadCallPrice);
    fprintf('彩虹基差期权商品1的Delta为 %f\n ',SpreadCallDelta(1));
    fprintf('彩虹基差期权商品2的Delta为 %f\n ',SpreadCallDelta(2));
elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
    OptSpec = 'put';
    [SpreadPutPrice, SpreadPutDelta,SpreadPutGamma] = SpredbyEurope(Price1,Price2,num1,num2,Strike(i),Vol1,Vol2,Div1,Div2,Corr(i),Settle,Exercisedates(i),Rate,OptSpec);
    fprintf('彩虹基差期权定价为 %f\n ',SpreadPutPrice);
    fprintf('彩虹基差期权商品1的Delta为 %f\n ',SpreadPutDelta(1));
    fprintf('彩虹基差期权商品2的Delta为 %f\n ',SpreadPutDelta(2));
end
else
    error('期权类型输入错误！');
end
% %% 
% if strcmp(char(Side(i)),'sellcall')
%     fprintf('\nCallDelta: %f\n',-SpreadCallDelta);
% elseif strcmp(char(Side(i)),'sellput')
%     fprintf('\nPutDelta: %f\n',-SpreadPutDelta);
% elseif strcmp(char(Side(i)),'buycall') 
%     fprintf('\nCallDelta: %f\n', SpreadCallDelta);
% elseif strcmp(char(Side(i)),'buyput')
%     fprintf('\nPutDelta: %f\n',SpreadPutDelta);
% else
%     error('交易方向输入错误！');
% end
%% 初始对冲设置
if Hedge(i) ~= 0
    if ~exist('IDelta.mat','file')
        InitDelta = zeros(10,2);
        save IDelta InitDelta;
    end
    load IDelta;
    if InitDelta(i,1) == 0 && InitDelta(i,2) == 0
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
             InitDelta(i,1) = SpreadCallDelta(1);
             InitDelta(i,2) = SpreadCallDelta(2);
        else
            InitDelta(i,1) = SpreadCallDelta(1);
            InitDelta(i,2) = SpreadCallDelta(2);
        end
        save IDelta InitDelta;
        if strcmp(char(Side(i)),'sellcall')
            info = ['第',num2str(i),'个期权：初始对冲先买入',num2str(abs(num1*Volume(i)*SpreadCallDelta(1))),'份标的资产1 & 卖出',num2str(abs(num2*Volume(i)*SpreadCallDelta(2))),'份标的资产2'];
            msgbox(info,'INFO');
        elseif strcmp(char(Side(i)),'sellput')
            info = ['第',num2str(i),'个期权：初始对冲先卖出',num2str(abs(num1*Volume(i)*SpreadPutDelta(1))),'份标的资产1  & 买入',num2str(abs(num2*Volume(i)*SpreadPutDelta(2))),'份标的资产2'];
            msgbox(info,'INFO');
        elseif strcmp(char(Side(i)),'buycall')
            info = ['第',num2str(i),'个期权：初始对冲先卖出',num2str(abs(num1*Volume(i)*SpreadCallDelta(1))),'份标的资产  &  买入',num2str(abs(num2*Volume(i)*SpreadCallDelta(2))),'份标的资产'];
            msgbox(info,'INFO');
        elseif strcmp(char(Side(i)),'buyput')
            info = ['第',num2str(i),'个期权：初始对冲先买入',num2str(abs(num1*Volume(i)*SpreadPutDelta(1))),'份标的资产   &  卖出',num2str(abs(num2*Volume(i)*SpreadPutDelta(2))),'份标的资产'];
            msgbox(info,'INFO');
            error('买卖方向输入错误！');
        end
    else
        lastweek = 0;
        lastday  = 0;
        if (datenum(Exercisedates(i)) - datenum(today)) <= 1
            disp('此期权明天即将到期！\n')
            lastday = 1;
        elseif (datenum(Exercisedates(i)) - datenum(today)) <= 7
            disp('此期权一周之内即将到期！\n')
            lastweek = 1;
        end
    %%
    switch(char(Side(i)))
        case 'sellcall'
            CallDelta1Change = SpreadCallDelta(1) - InitDelta(i,1);
            CallDelta2Change = SpreadCallDelta(2) - InitDelta(i,2);  
            fprintf('基差期权商品1的Delta变动为 %f\n ',CallDelta1Change);
            if lastweek == 1 && (abs(CallDelta1Change(2)) >= ordinaryDelta(i,1) || abs(CallDeltaChange(1)) >= ordinaryDelta(i,2))
                info = ['第',num2str(i),'个期权：买入',num2str(abs(CallDelta1Change*num1*Volume(i))),'份标的资产'];
                msgbox(info,'INFO');
                InitDelta(i,1) = SpreadCallDelta(1);
            else lastweek == 1 && abs(CallDelta1Change) >= ordinaryDelta(i,1)
                info = ['第',num2str(i),'个期权：买入',num2str(abs(CallDelta1Change*num1*Volume(i))),'份标的资产'];
                msgbox(info,'INFO');
                InitDelta(i,1) = SpreadCallDelta(1); 
            end
    end
    end

end
end
end
