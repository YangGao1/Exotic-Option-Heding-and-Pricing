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
    %% (����)Ԥ�������� ����Sigma rate
    Time = (datenum(ExerciseDates(i))-datenum(today))/365;
    fprintf('��%d����Ȩ��\n',int8(i));
    Price = w.wsq(char(Code(i)),'rt_last');   % �ڻ����¼۸�
    Rate  = w.wsq('CGB1Y.WI','rt_last')/100;  % һ���ڹ�ծ������
    %% �趨�ļ���ʽ
     rtWind(i,1) = Price;
     rtWind(i,2) = Rate;
    save rtWindMat rtWind;
%%  ���Ʋ����ʵ�����
    [EstVol,GarchVol,SellVol,BuyVol] = EstVolatility(char(Code(i)));   
    PremiumVol  = Premium(i)*max(GarchVol,SellVol);
    DiscountVol = (2-Premium(i))*min(GarchVol,BuyVol);
    fprintf('��ʷ��ֵ���ƵĲ�����Ϊ %f\n',EstVol);
    fprintf('GARCHģ�͹��ƵĲ�����Ϊ %f\n',GarchVol);
    if strcmp(char(Side(i)),'sellcall') || strcmp(char(Side(i)),'sellput')
        fprintf('������Ȩ�����ƵĲ�����Ϊ %f\n',SellVol);
        fprintf('������Ȩʱ������ʹ�ò�����Ϊ %f\n\n',PremiumVol);
        Volatility = PremiumVol;
    elseif strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'buyput')
        fprintf('������Ȩ�����ƵĲ�����Ϊ %f\n',BuyVol);
        fprintf('������Ȩʱ������ʹ�ò�����Ϊ %f\n\n',DiscountVol);
        Volatility = DiscountVol;
    end
%% 
    %% Type1 ŷʽ��Ȩ�Ķ���    
    if Type(i) == 1
        [CallPrice,PutPrice] = blsprice(Price,Strike(i),Rate,Time,Volatility,Yield(i));
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            OurPrice = CallPrice;
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            OurPrice = PutPrice;
        end
        fprintf('���ǶԸ�ŷʽ��Ȩ�Ķ���Ϊ��%f\n',OurPrice);
        [CallDelta,PutDelta,Gamma,CallTheta,PutTheta,Vega,CallRho,PutRho] ...
        = BS_GreekLetters(Price,Strike(i),Rate,Time,HedgeVol(i),Yield(i));

    %% Type2 ��ʽ��Ȩ
    elseif Type(i) == 2
        [ AmeCallPrice,AmePutPrice,~,~,Prob] = CRRPrice(Price,Strike(i),Rate,Time,Volatility,Yield(i));
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            OurPrice = AmeCallPrice;
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            OurPrice = AmePutPrice;
        end
        fprintf('���ǶԸ���ʽ��Ȩ�Ķ���Ϊ��%f��Prob = %f\n\n',OurPrice,Prob);

        [CallDelta,PutDelta,Gamma,CallTheta,PutTheta,Vega,CallRho,PutRho] ...
        = BS_GreekLetters(Price,Strike(i),Rate,Time,HedgeVol(i),Yield(i));

    %% Type3 ��ʽ��Ȩ�Ķ���---����д���
    elseif Type(i) == 3
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            [AsianPrice,Var,UP] = Asian_improve(Price,Strike(i),Rate,Time,Volatility,1);
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            [AsianPrice,Var,UP] = Asian_improve(Price,Strike(i),Rate,Time,Volatility,0);
        end
        fprintf('���ǶԸ���ʽ��Ȩ�Ķ���Ϊ��%f\n',AsianPrice);
        fprintf('��ʽ��Ȩ�۸�ķ���Ϊ %f  0.95�����������Ȩ�۸����½�Ϊ[%f, %f]\n\n',Var,UP);

        [CallDelta,PutDelta,Gamma,CallTheta,PutTheta,Vega,CallRho,PutRho] ...
        = AsianGreeksLevy(Price,Strike(i),HedgeVol(i),Rate,char(Settle(i)),char(ExerciseDates(i)));

    %%  Type4 ��ֵ��Ȩ
    elseif Type(i) == 4
        [ BinCall,pCall,BinPut,pPut ] = BinPrice(Price,pCStrike(i),pPStrike(i),pCash(i),Rate,Volatility,Time,Yield(i));
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            OurPrice = BinCall;
            pS = pCall;
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            OurPrice = BinPut;
            pS = pPut;
        end
        fprintf('���ǶԸö�Ԫ��Ȩ�Ķ���Ϊ��%f\n',OurPrice);
        fprintf('��Ȩ�۸�/��ļ۸� = %f\n',pS); 
        [CallDelta,PutDelta,CallGamma,PutGamma,CallTheta,PutTheta,CallVega,PutVega,CallRho,PutRho] = ...
         Bin_GreekLetters( Price,pCStrike(i),pPStrike(i),Rate,pCash(i),HedgeVol(i),SettlePrice(i),char(ExerciseDates(i)),Yield(i));

    %%  Type5 ��ʽ��Ȩ��ȷ�汾 
    elseif Type(i) == 5 
        % ʱ�����Ľ�����
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
        hedgevolume=Delta*Volume(i);%�ù�ʽ��õĶԳ�����
        fprintf('��Ʒ�ּۡ���ʷ����Ϊ��%.2f,%.2f\n',Price,Save);
        fprintf('���ǶԸ���ʽ��Ȩ���յĶ���Ϊ��%f\n',OurPrice);
        fprintf('�ù�ʽ��ô˿̸���ʽ��Ȩ��deltaֵΪ��%f\n',Delta);
        fprintf('�ù�ʽ��õĶԳ�����Ϊ��%f\n\n',hedgevolume);    
 %%  Type8 ������ʽ��Ȩ��ȷ�汾 
    elseif Type(i) == 8 
        % ʱ�����Ľ�����
        
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
        hedgevolume=Delta*Volume(i);%�ù�ʽ��õĶԳ�����
        fprintf('��Ʒ�ּۡ���ʷ����Ϊ��%.2f,%.2f\n',Price,Save);
        fprintf('���ǶԸ���ʽ������Ȩ���յĶ���Ϊ��%f\n',OurPrice);
        fprintf('�ù�ʽ��ô˿̸���ʽ������Ȩ��deltaֵΪ��%f\n',Delta);
        fprintf('�ù�ʽ��õĶԳ�����Ϊ��%f\n\n',hedgevolume);    

 %%   Type6 ������Ȩ
    elseif Type(i) == 6
      % Time = (datenum(ExerciseDates(i))-datenum(today))/365; % ��ʱʱ��ļ���
      [CallPrice,PutPrice] = ShoutOptionCRR(Price,ShoutPrice(i),Strike(i),Volatility,Time,Rate);
      [CallDelta,PutDelta] = shoutgreeksCRR(Price,ShoutPrice(i),Strike(i),HedgeVol(i),Time,Rate);
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            OurPrice = CallPrice; Delta = CallDelta;
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            OurPrice = PutPrice;Delta = PutDelta;
        end
        hedgevolume=Delta*Volume(i);%�ù�ʽ��õĶԳ�����
        fprintf('��Ʒ�ּ�Ϊ��%f\n',Price);
        fprintf('������Ȩ�ĺ��м۸�Ϊ��%.2f\n',ShoutPrice(i));
        fprintf('�ú�����Ȩ����Ϊ��%f\n',OurPrice);
        fprintf('�ú�����Ȩ��DeltaֵΪ��%f\n',Delta);
        fprintf('�ù�ʽ��õĶԳ�����Ϊ��%f\n\n',hedgevolume); 

%% Type7 ��ʽ������Ȩ
    elseif Type(i) == 7
        % ʱ�����Ľ�����
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
        hedgevolume=Delta*Volume(i);%�ù�ʽ��õĶԳ�����
        fprintf('��Ʒ�ּۡ���ʷ����Ϊ��%.2f,%.2f\n',Price,Save);
        fprintf('������Ȩ�ĺ��м۸�Ϊ��%.2f\n',ShoutPrice(i));
        fprintf('����ʽ������Ȩ�۸�Ϊ��%f\n',OurPrice);
        fprintf('����ʽ������Ȩ��DeltaΪ��%f\n',Delta);
        fprintf('�ù�ʽ��õĶԳ�����Ϊ��%f\n\n',hedgevolume); 

    %% ��������
    else
        error('��Ȩ�����������');
    end

    
 %% �Գ�ϵ�е�����
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
            error('���׷����������');
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
            error('���׷����������');
        end
    end
    fprintf('\n\n');

    %% ʵʱ�Գ�
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
     %% ��ʼ�Գ�
            if strcmp(char(Side(i)),'sellcall')
                info = ['��',num2str(i),'����Ȩ����ʼ�Գ�������',num2str(abs(Volume(i)*CallDelta)),'�ݱ���ʲ�'];
                msgbox(info,'INFO');
            elseif strcmp(char(Side(i)),'sellput')
                info = ['��',num2str(i),'����Ȩ����ʼ�Գ�������',num2str(abs(Volume(i)*PutDelta)),'�ݱ���ʲ�'];
                msgbox(info,'INFO');
            elseif strcmp(char(Side(i)),'buyput')
                info = ['��',num2str(i),'����Ȩ����ʼ�Գ�������',num2str(abs(Volume(i)*PutDelta)),'�ݱ���ʲ�'];
                msgbox(info,'INFO');
            elseif strcmp(char(Side(i)),'buycall')
                info = ['��',num2str(i),'����Ȩ����ʼ�Գ�������',num2str(abs(Volume(i)*CallDelta)),'�ݱ���ʲ�'];
                msgbox(info,'INFO');
            else
                error('���������������');
            end
        else
            CallDeltaChange = abs(CallDelta) - abs(InitD(i,1));
            PutDeltaChange  = abs(PutDelta) - abs(InitD(i,2));
            lastweek = 0;
            lastday  = 0;
            if (datenum(ExerciseDates(i)) - datenum(today)) <= 1
                disp('����Ȩ���켴�����ڣ�\n')
                lastday = 1;
            elseif (datenum(ExerciseDates(i)) - datenum(today)) <= 7
                disp('����Ȩһ��֮�ڼ������ڣ�\n')
                lastweek = 1;
            end
 %% 
            switch(char(Side(i)))
                case 'sellcall'
                    if lastweek == 1 && CallDeltaChange > lstweekDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(CallDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 1 && CallDeltaChange < -lstweekDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(CallDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastday == 1 && CallDeltaChange > lstdayDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(CallDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastday == 1 && CallDeltaChange < -lstdayDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(CallDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 0 && lastday == 0 && CallDeltaChange > ordinaryDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(CallDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 0 && lastday == 0 && CallDeltaChange < -ordinaryDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(CallDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    end
                case 'sellput'
                    if lastweek == 1 && PutDeltaChange > lstweekDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(PutDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 1 && PutDeltaChange < -lstweekDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(PutDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastday == 1 && PutDeltaChange > lstdayDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(PutDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastday == 1 && PutDeltaChange < -lstdayDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(PutDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 0 && lastday == 0 && PutDeltaChange > ordinaryDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(PutDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 0 && lastday == 0 && PutDeltaChange < -ordinaryDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(PutDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    end
                case 'buycall'
                    if lastweek == 1 && CallDeltaChange > lstweekDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(CallDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 1 && CallDeltaChange < -lstweekDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(CallDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastday == 1 && CallDeltaChange > lstdayDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(CallDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastday == 1 && CallDeltaChange < -lstdayDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(CallDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 0 && lastday == 0 && CallDeltaChange > ordinaryDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(CallDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 0 && lastday == 0 && CallDeltaChange < -ordinaryDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(CallDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    end
                case 'buyput'
                    if lastweek == 1 && PutDeltaChange > lstweekDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(PutDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 1 && PutDeltaChange < -lstweekDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(PutDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastday == 1 && PutDeltaChange > lstdayDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(PutDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastday == 1 && PutDeltaChange < -lstdayDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(PutDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 0 && lastday == 0 && PutDeltaChange > ordinaryDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(PutDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 0 && lastday == 0 && PutDeltaChange < -ordinaryDelta(i)
                        info = ['��',num2str(i),'����Ȩ������',num2str(abs(PutDeltaChange*Volume(i))),'�ݱ���ʲ�'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    end
            end
            save InitDelta InitD;
        end
    end
 %% ����
end
%% ��Ȩ��Ŀѭ��
end