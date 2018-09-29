function [] = DynamicHedge2( obj,~ )
%% set user data 
w       = windmatlab;
ud      = obj.UserData;
Code    = ud.code; 
Side    = ud.side;
Strike  = ud.strike; 
Type    = ud.type; 
Yield   = ud.yield;
Premium = ud.premium;
HedgeVol = ud.hedgevol;
Settle  = ud.settle;
ExerciseDates = ud.exercisedates;
Volume  = ud.volume;
N = length(Type);
rtWind = zeros(1000,2);
%% hedge setting
Hedge   = ud.hedge;
ordinaryDelta = ud.ordinaryDelta;
lstweekDelta  = ud.lastweekDelta;
lstdayDelta   = ud.lastdayDelta;

%% binary option data
pCStrike    = ud.pCStrike;
pPStrike    = ud.pPStrike;
pCash       = ud.pCash;
SettlePrice = ud.settleprice;
%% Shout Option %% Asian Shout Option 
ShoutPrice = ud.ShoutPrice;
%% Adjusted Asian Option
t1=ud.t1;

 
%%
for i=1:N
    %% (加速)预加载数据 计算Sigma rate
    Time = (datenum(ExerciseDates(i))-datenum(today))/365;
    fprintf('第%d个期权：\n',int8(i));
    Price = w.wsq(char(Code(i)),'rt_last');   % 期货最新价格
    Rate  = w.wsq('CGB1Y.WI','rt_last')/100;  % 一年期国债收益率
    %% 设定文件格式
     rtWind(i,1) = Price;
     rtWind(i,2) = Rate;
    save rtWindMat rtWind;
%%  估计波动率的问题
    [EstVol,GarchVol,SellVol,BuyVol] = EstVolatility(char(Code(i)));   
    PremiumVol  = Premium(i)*max(GarchVol,SellVol);
    DiscountVol = (2-Premium(i))*min(GarchVol,BuyVol);
    fprintf('历史均值估计的波动率为 %f\n',EstVol);
    fprintf('GARCH模型估计的波动率为 %f\n',GarchVol);
    if strcmp(char(Side(i)),'sellcall') || strcmp(char(Side(i)),'sellput')
        fprintf('卖出期权所估计的波动率为 %f\n',SellVol);
        fprintf('卖出期权时定价所使用波动率为 %f\n\n',PremiumVol);
        Volatility = PremiumVol;
    elseif strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'buyput')
        fprintf('买入期权所估计的波动率为 %f\n',BuyVol);
        fprintf('买入期权时定价所使用波动率为 %f\n\n',DiscountVol);
        Volatility = DiscountVol;
    end
%% 
    %% Type1 欧式期权的定价    
    if Type(i) == 1
        [CallPrice,PutPrice] = blsprice(Price,Strike(i),Rate,Time,Volatility,Yield(i));
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            OurPrice = CallPrice;
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            OurPrice = PutPrice;
        end
        fprintf('我们对该欧式期权的定价为：%f\n',OurPrice);
        [CallDelta,PutDelta,Gamma,CallTheta,PutTheta,Vega,CallRho,PutRho] ...
        = BS_GreekLetters(Price,Strike(i),Rate,Time,HedgeVol(i),Yield(i));

    %% Type2 美式期权
    elseif Type(i) == 2
        [ AmeCallPrice,AmePutPrice,~,~,Prob] = CRRPrice(Price,Strike(i),Rate,Time,Volatility,Yield(i));
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            OurPrice = AmeCallPrice;
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            OurPrice = AmePutPrice;
        end
        fprintf('我们对该美式期权的定价为：%f，Prob = %f\n\n',OurPrice,Prob);

        [CallDelta,PutDelta,Gamma,CallTheta,PutTheta,Vega,CallRho,PutRho] ...
        = BS_GreekLetters(Price,Strike(i),Rate,Time,HedgeVol(i),Yield(i));

    %% Type3 亚式期权的定价---结果有错误
    elseif Type(i) == 3
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            [AsianPrice,Var,UP] = Asian_improve(Price,Strike(i),Rate,Time,Volatility,1);
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            [AsianPrice,Var,UP] = Asian_improve(Price,Strike(i),Rate,Time,Volatility,0);
        end
        fprintf('我们对该亚式期权的定价为：%f\n',AsianPrice);
        fprintf('亚式期权价格的方差为 %f  0.95置信区间的期权价格上下界为[%f, %f]\n\n',Var,UP);

        [CallDelta,PutDelta,Gamma,CallTheta,PutTheta,Vega,CallRho,PutRho] ...
        = AsianGreeksLevy(Price,Strike(i),HedgeVol(i),Rate,char(Settle(i)),char(ExerciseDates(i)));

    %%  Type4 二值期权
    elseif Type(i) == 4
        [ BinCall,pCall,BinPut,pPut ] = BinPrice(Price,pCStrike(i),pPStrike(i),pCash(i),Rate,Volatility,Time,Yield(i));
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            OurPrice = BinCall;
            pS = pCall;
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            OurPrice = BinPut;
            pS = pPut;
        end
        fprintf('我们对该二元期权的定价为：%f\n',OurPrice);
        fprintf('期权价格/标的价格 = %f\n',pS); 
        [CallDelta,PutDelta,CallGamma,PutGamma,CallTheta,PutTheta,CallVega,PutVega,CallRho,PutRho] = ...
         Bin_GreekLetters( Price,pCStrike(i),pPStrike(i),Rate,pCash(i),HedgeVol(i),SettlePrice(i),char(ExerciseDates(i)),Yield(i));

    %%  Type5 亚式期权正确版本 
    elseif Type(i) == 5 
        % 时间计算的交易日
        T=double(w.tdayscount(Settle(i),ExerciseDates(i)))/250; 
        Today=datestr(today,'yyyy-mm-dd');
        t=double(w.tdayscount(Today,ExerciseDates(i)))/250;
        n = length(w.wsd(char(Code(i)),'close',Settle(i),'-1td','tradingcalender'));
        if T-t == 0 Save  = Price;
        else Save =(sum(w.wsd(char(Code(i)),'close',Settle(i),'-1td','tradingcalender'))+Price)/(n+1);
        end 
       %%
        [CallPrice,PutPrice,~,~] = AsianOption(Price,Save,Strike(i),T,t,Rate,Volatility);
        [~,~,CallDelta,PutDelta] = AsianOption(Price,Save,Strike(i),T,t,Rate,HedgeVol(i));
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            OurPrice = CallPrice;Delta = CallDelta;
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            OurPrice = PutPrice;Delta = PutDelta;
        end
        hedgevolume=Delta*Volume(i);%用公式算得的对冲手数
        fprintf('商品现价、历史均价为：%.2f,%.2f\n',Price,Save);
        fprintf('我们对该亚式期权最终的定价为：%f\n',OurPrice);
        fprintf('用公式算得此刻该亚式期权的delta值为：%f\n',Delta);
        fprintf('用公式算得的对冲手数为：%f\n\n',hedgevolume);    
 %%  Type8 调整亚式期权正确版本 
    elseif Type(i) == 8 
        % 时间计算的交易日
        
        T=double(w.tdayscount(Settle(i),ExerciseDates(i)))/250; 
        Today=datestr(today,'yyyy-mm-dd');
        t=double(w.tdayscount(Today,ExerciseDates(i)))/250;
        %%
       if t >= t1(i) Save  = 0;
           
       else
         n = double((t1(i)-t)*250-1);
         n=double(n);
         m=length(w.wsd(char(Code(i)),'close',Settle(i),'-1td','tradingcalender'));
         m=double(m);
        aaa=w.wsd(char(Code(i)),'close',Settle(i),'-1td','tradingcalender');
        bbb=aaa(m-n:m);
        Save =(sum(bbb)+Price)/(n+2);
    end 
       %%
        [CallPrice,PutPrice,~,~] = AsianOption4(Price,Save,Strike(i),T,t,t1(i),Rate,Volatility);
        [~,~,CallDelta,PutDelta] = AsianOption4(Price,Save,Strike(i),T,t,t1(i),Rate,HedgeVol(i));
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            OurPrice = CallPrice;Delta = CallDelta;
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            OurPrice = PutPrice;Delta = PutDelta;
        end
        hedgevolume=Delta*Volume(i);%用公式算得的对冲手数
        fprintf('商品现价、历史均价为：%.2f,%.2f\n',Price,Save);
        fprintf('我们对该亚式调整期权最终的定价为：%f\n',OurPrice);
        fprintf('用公式算得此刻该亚式调整期权的delta值为：%f\n',Delta);
        fprintf('用公式算得的对冲手数为：%f\n\n',hedgevolume);    

 %%   Type6 呼叫期权
    elseif Type(i) == 6
      % Time = (datenum(ExerciseDates(i))-datenum(today))/365; % 此时时间的计算
      [CallPrice,PutPrice] = ShoutOptionCRR(Price,ShoutPrice(i),Strike(i),Volatility,Time,Rate);
      [CallDelta,PutDelta] = shoutgreeksCRR(Price,ShoutPrice(i),Strike(i),HedgeVol(i),Time,Rate);
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            OurPrice = CallPrice; Delta = CallDelta;
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            OurPrice = PutPrice;Delta = PutDelta;
        end
        hedgevolume=Delta*Volume(i);%用公式算得的对冲手数
        fprintf('商品现价为：%f\n',Price);
        fprintf('呼叫期权的呼叫价格为：%.2f\n',ShoutPrice(i));
        fprintf('该呼叫期权定价为：%f\n',OurPrice);
        fprintf('该呼叫期权的Delta值为：%f\n',Delta);
        fprintf('用公式算得的对冲手数为：%f\n\n',hedgevolume); 

%% Type7 亚式呼叫期权
    elseif Type(i) == 7
        % 时间计算的交易日
        T=double(w.tdayscount(Settle(i),ExerciseDates(i)))/250; 
        Today=datestr(today,'yyyy-mm-dd');
        t=double(w.tdayscount(Today,ExerciseDates(i)))/250;
        n = length(w.wsd(char(Code(i)),'close',Settle(i),'-1td','tradingcalender'));
        if T-t==0 Save = Price;
        else Save =(sum(w.wsd(char(Code(i)),'close',Settle(i),'-1td','tradingcalender'))+Price)/(n+1);
        end
        [CallPrice,PutPrice] = AsianShoutMC(Price,Save,Strike(i),T,t,Rate,Volatility,ShoutPrice(i));
        [CallDelta,PutDelta]=AsianShoutGreeksMC(Price,Save,Strike(i),T,t,Rate,HedgeVol(i),ShoutPrice(i));
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            OurPrice = CallPrice;Delta = CallDelta;
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            OurPrice = PutPrice;Delta = PutDelta;
        end
        hedgevolume=Delta*Volume(i);%用公式算得的对冲手数
        fprintf('商品现价、历史均价为：%.2f,%.2f\n',Price,Save);
        fprintf('呼叫期权的呼叫价格为：%.2f\n',ShoutPrice(i));
        fprintf('该亚式呼叫期权价格为：%f\n',OurPrice);
        fprintf('该亚式呼叫期权的Delta为：%f\n',Delta);
        fprintf('用公式算得的对冲手数为：%f\n\n',hedgevolume); 

    %% 其余类型
    else
        error('期权类型输入错误！');
    end

    
 %% 对冲系列的问题
    if Type(i) < 4  
        if strcmp(char(Side(i)),'sellput') 
            fprintf('\nPutDelta: %f\n',-PutDelta);
            fprintf('Gamma: %f\n',-Gamma);
            fprintf('PutTheta: %f\n',-PutTheta);
            fprintf('Vega: %f\n',-Vega);
            fprintf('PutRho: %f\n',-PutRho);
        elseif strcmp(char(Side(i)),'buycall') 
            fprintf('\nCallDelta: %f\n',CallDelta);
            fprintf('Gamma: %f\n',Gamma);
            fprintf('CallTheta: %f\n',CallTheta);
            fprintf('Vega: %f\n',Vega);
            fprintf('CallRho: %f\n',CallRho);
        elseif strcmp(char(Side(i)),'buyput')
            fprintf('\nPutDelta: %f\n',PutDelta);
            fprintf('Gamma: %f\n',Gamma);
            fprintf('PutTheta: %f\n',PutTheta);
            fprintf('Vega: %f\n',Vega);
            fprintf('PutRho: %f\n',PutRho);
        elseif strcmp(char(Side(i)),'sellcall')
            fprintf('\nCallDelta: %f\n',-CallDelta);
            fprintf('Gamma: %f\n',-Gamma);
            fprintf('CallTheta: %f\n',-CallTheta);
            fprintf('Vega: %f\n',-Vega);
            fprintf('CallRho: %f\n',-CallRho);
        else
            error('交易方向输入错误！');
        end
    elseif  Type(i) == 4
        if strcmp(char(Side(i)),'sellput') 
            fprintf('\nPutDelta: %f\n',-PutDelta);
            fprintf('PutGamma: %f\n',-PutGamma);
            fprintf('PutTheta: %f\n',-PutTheta);
            fprintf('PutVega: %f\n',-PutVega);
            fprintf('PutRho: %f\n',-PutRho);
        elseif strcmp(char(Side(i)),'buycall') 
            fprintf('\nCallDelta: %f\n',CallDelta);
            fprintf('CallGamma: %f\n',CallGamma);
            fprintf('CallTheta: %f\n',CallTheta);
            fprintf('CallVega: %f\n',CallVega);
            fprintf('CallRho: %f\n',CallRho);
        elseif strcmp(char(Side(i)),'buyput')
            fprintf('\nPutDelta: %f\n',PutDelta);
            fprintf('PutGamma: %f\n',PutGamma);
            fprintf('PutTheta: %f\n',PutTheta);
            fprintf('PutVega: %f\n',PutVega);
            fprintf('PutRho: %f\n',PutRho);
        elseif strcmp(char(Side(i)),'sellcall')
            fprintf('\nCallDelta: %f\n',-CallDelta);
            fprintf('CallGamma: %f\n',-CallGamma);
            fprintf('CallTheta: %f\n',-CallTheta);
            fprintf('CallVega: %f\n',-CallVega);
            fprintf('CallRho: %f\n',-CallRho);
        else
            error('交易方向输入错误！');
        end
    end
    fprintf('\n\n');

    %% 实时对冲
    if Hedge(i) ~= 0
        if ~exist('InitDelta.mat','file')
            InitD = zeros(1000,2);
            save InitDelta InitD;
        end
        load InitDelta;
        if InitD(i,1) == 0 && InitD(i,2) == 0
        InitD(i,1) = CallDelta;
        InitD(i,2) = PutDelta;
        save InitDelta InitD;
     %% 初始对冲
            if strcmp(char(Side(i)),'sellcall')
                info = ['第',num2str(i),'个期权：初始对冲先买入',num2str(abs(Volume(i)*CallDelta)),'份标的资产'];
                msgbox(info,'INFO');
            elseif strcmp(char(Side(i)),'sellput')
                info = ['第',num2str(i),'个期权：初始对冲先卖出',num2str(abs(Volume(i)*PutDelta)),'份标的资产'];
                msgbox(info,'INFO');
            elseif strcmp(char(Side(i)),'buyput')
                info = ['第',num2str(i),'个期权：初始对冲先买入',num2str(abs(Volume(i)*PutDelta)),'份标的资产'];
                msgbox(info,'INFO');
            elseif strcmp(char(Side(i)),'buycall')
                info = ['第',num2str(i),'个期权：初始对冲先卖出',num2str(abs(Volume(i)*CallDelta)),'份标的资产'];
                msgbox(info,'INFO');
            else
                error('买卖方向输入错误！');
            end
        else
            CallDeltaChange = abs(CallDelta) - abs(InitD(i,1));
            PutDeltaChange  = abs(PutDelta) - abs(InitD(i,2));
            lastweek = 0;
            lastday  = 0;
            if (datenum(ExerciseDates(i)) - datenum(today)) <= 1
                disp('此期权明天即将到期！\n')
                lastday = 1;
            elseif (datenum(ExerciseDates(i)) - datenum(today)) <= 7
                disp('此期权一周之内即将到期！\n')
                lastweek = 1;
            end
 %% 
            switch(char(Side(i)))
                case 'sellcall'
                    if lastweek == 1 && CallDeltaChange > lstweekDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 1 && CallDeltaChange < -lstweekDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastday == 1 && CallDeltaChange > lstdayDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastday == 1 && CallDeltaChange < -lstdayDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 0 && lastday == 0 && CallDeltaChange > ordinaryDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 0 && lastday == 0 && CallDeltaChange < -ordinaryDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    end
                case 'sellput'
                    if lastweek == 1 && PutDeltaChange > lstweekDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 1 && PutDeltaChange < -lstweekDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastday == 1 && PutDeltaChange > lstdayDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastday == 1 && PutDeltaChange < -lstdayDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 0 && lastday == 0 && PutDeltaChange > ordinaryDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 0 && lastday == 0 && PutDeltaChange < -ordinaryDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    end
                case 'buycall'
                    if lastweek == 1 && CallDeltaChange > lstweekDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 1 && CallDeltaChange < -lstweekDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastday == 1 && CallDeltaChange > lstdayDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastday == 1 && CallDeltaChange < -lstdayDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 0 && lastday == 0 && CallDeltaChange > ordinaryDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 0 && lastday == 0 && CallDeltaChange < -ordinaryDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    end
                case 'buyput'
                    if lastweek == 1 && PutDeltaChange > lstweekDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 1 && PutDeltaChange < -lstweekDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastday == 1 && PutDeltaChange > lstdayDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastday == 1 && PutDeltaChange < -lstdayDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 0 && lastday == 0 && PutDeltaChange > ordinaryDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 0 && lastday == 0 && PutDeltaChange < -ordinaryDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    end
            end
            save InitDelta InitD;
        end
    end
 %% 结束
end
%% 期权数目循环
end