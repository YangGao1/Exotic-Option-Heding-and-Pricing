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
    fprintf('��%d����Ȩ��\n',int8(i));
    for j = 1:length(Code(i,:))
    Price = w.wsq((Code(i,:)),'rt_last');   % �ڻ����¼۸�
    Rate  = w.wsq('CGB1Y.WI','rt_last')/100; % SHIBOR����
    %%
    [EstVol,GarchVol,SellVol,BuyVol] = EstVolatility(char(Code(i,j)));
    PremiumVol  = Premium(i,j)*max(GarchVol,SellVol);
    DiscountVol = (2-Premium(i,j))*min(GarchVol,BuyVol);
    fprintf('��ʷ��ֵ���ƵĲ�����Ϊ %f\n',EstVol);
    fprintf('GARCHģ�͹��ƵĲ�����Ϊ %f\n',GarchVol);
    if strcmp(Side(i),'sellcall') || strcmp(Side(i),'sellput')
        fprintf('������Ȩ�����ƵĲ�����Ϊ %f\n',SellVol);
        fprintf('������Ȩʱ������ʹ�ò�����Ϊ %f\n\n',PremiumVol);
        Volatility = [Volatility;PremiumVol];
    elseif strcmp(Side(i),'buycall') || strcmp(Side(i),'buyput')
        fprintf('������Ȩ�����ƵĲ�����Ϊ %f\n',BuyVol);
        fprintf('������Ȩʱ������ʹ�ò�����Ϊ %f\n\n',DiscountVol);
        Volatility = [Volatility;DiscountVol];
    end
    end
%% ������Ȩ�Ķ���
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
    fprintf('�ʺ������Ȩ����Ϊ %f\n ',SpreadCallPrice);
    fprintf('�ʺ������Ȩ��Ʒ1��DeltaΪ %f\n ',SpreadCallDelta(1));
    fprintf('�ʺ������Ȩ��Ʒ2��DeltaΪ %f\n ',SpreadCallDelta(2));
elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
    OptSpec = 'put';
    [SpreadPutPrice, SpreadPutDelta,SpreadPutGamma] = SpredbyEurope(Price1,Price2,num1,num2,Strike(i),Vol1,Vol2,Div1,Div2,Corr(i),Settle,Exercisedates(i),Rate,OptSpec);
    fprintf('�ʺ������Ȩ����Ϊ %f\n ',SpreadPutPrice);
    fprintf('�ʺ������Ȩ��Ʒ1��DeltaΪ %f\n ',SpreadPutDelta(1));
    fprintf('�ʺ������Ȩ��Ʒ2��DeltaΪ %f\n ',SpreadPutDelta(2));
end
else
    error('��Ȩ�����������');
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
%     error('���׷����������');
% end
%% ��ʼ�Գ�����
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
            info = ['��',num2str(i),'����Ȩ����ʼ�Գ�������',num2str(abs(num1*Volume(i)*SpreadCallDelta(1))),'�ݱ���ʲ�1 & ����',num2str(abs(num2*Volume(i)*SpreadCallDelta(2))),'�ݱ���ʲ�2'];
            msgbox(info,'INFO');
        elseif strcmp(char(Side(i)),'sellput')
            info = ['��',num2str(i),'����Ȩ����ʼ�Գ�������',num2str(abs(num1*Volume(i)*SpreadPutDelta(1))),'�ݱ���ʲ�1  & ����',num2str(abs(num2*Volume(i)*SpreadPutDelta(2))),'�ݱ���ʲ�2'];
            msgbox(info,'INFO');
        elseif strcmp(char(Side(i)),'buycall')
            info = ['��',num2str(i),'����Ȩ����ʼ�Գ�������',num2str(abs(num1*Volume(i)*SpreadCallDelta(1))),'�ݱ���ʲ�  &  ����',num2str(abs(num2*Volume(i)*SpreadCallDelta(2))),'�ݱ���ʲ�'];
            msgbox(info,'INFO');
        elseif strcmp(char(Side(i)),'buyput')
            info = ['��',num2str(i),'����Ȩ����ʼ�Գ�������',num2str(abs(num1*Volume(i)*SpreadPutDelta(1))),'�ݱ���ʲ�   &  ����',num2str(abs(num2*Volume(i)*SpreadPutDelta(2))),'�ݱ���ʲ�'];
            msgbox(info,'INFO');
            error('���������������');
        end
    else
        lastweek = 0;
        lastday  = 0;
        if (datenum(Exercisedates(i)) - datenum(today)) <= 1
            disp('����Ȩ���켴�����ڣ�\n')
            lastday = 1;
        elseif (datenum(Exercisedates(i)) - datenum(today)) <= 7
            disp('����Ȩһ��֮�ڼ������ڣ�\n')
            lastweek = 1;
        end
    %%
    switch(char(Side(i)))
        case 'sellcall'
            CallDelta1Change = SpreadCallDelta(1) - InitDelta(i,1);
            CallDelta2Change = SpreadCallDelta(2) - InitDelta(i,2);  
            fprintf('������Ȩ��Ʒ1��Delta�䶯Ϊ %f\n ',CallDelta1Change);
            if lastweek == 1 && (abs(CallDelta1Change(2)) >= ordinaryDelta(i,1) || abs(CallDeltaChange(1)) >= ordinaryDelta(i,2))
                info = ['��',num2str(i),'����Ȩ������',num2str(abs(CallDelta1Change*num1*Volume(i))),'�ݱ���ʲ�'];
                msgbox(info,'INFO');
                InitDelta(i,1) = SpreadCallDelta(1);
            else lastweek == 1 && abs(CallDelta1Change) >= ordinaryDelta(i,1)
                info = ['��',num2str(i),'����Ȩ������',num2str(abs(CallDelta1Change*num1*Volume(i))),'�ݱ���ʲ�'];
                msgbox(info,'INFO');
                InitDelta(i,1) = SpreadCallDelta(1); 
            end
    end
    end

end
end
end
