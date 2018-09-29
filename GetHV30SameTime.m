function [ HV30 ] = GetHV30SameTime( Code )
%% ʵʱ����30������ʷǰ����ͬ��HV30����
% Code = 'SM709.CZC';
answer = who('w');
if(isempty(answer) || ~isa(w,'windMATLAB'))
    w = windmatlab;
end
if ~isconnected(w) 
    msgbox('Wind Disconnected!')
end

ActiveCode  = HandleCode(Code);
%% ���ڴ���
ADay1 = datestr(today+30-365,'yyyy-mm-dd');
ADay2 = datestr(today+30-365+30+2,'yyyy-mm-dd');
BDay1 = datestr(today+30-365*2,'yyyy-mm-dd');
BDay2 = datestr(today+30-365*2+30+2,'yyyy-mm-dd');
CDay1 = datestr(today+30-365*3,'yyyy-mm-dd');
CDay2 = datestr(today+30-365*3+30+2,'yyyy-mm-dd');
%% ��ȡ����
PriceA = w.wsd(ActiveCode,'close',ADay1,ADay2);
PriceB = w.wsd(ActiveCode,'close',BDay1,BDay2,'TradingCalendar=DCE');
PriceC = w.wsd(ActiveCode,'close',CDay1,CDay2,'TradingCalendar=DCE');
PriceA = PriceA(~isnan(PriceA));
PriceB = PriceB(~isnan(PriceB));

% HV = zeros(3,1);
if ~iscell(PriceC)
    PriceC = PriceC(~isnan(PriceC));
    dailyReturnC = zeros(length(PriceC),1);
    for i = 1:length(PriceC)-1
        dailyReturnC(i) = log(PriceC(i+1)/PriceC(i));
        HV(3) = std(dailyReturnC);
    end
end
if ~iscell(PriceB)
    PriceB = PriceB(~isnan(PriceB));
    dailyReturnB = zeros(length(PriceB),1);
    for i = 1:length(PriceB)-1
        dailyReturnB(i) = log(PriceB(i+1)/PriceB(i));
        HV(2) = std(dailyReturnB);
    end
end
if ~iscell(PriceA)
    PriceA = PriceA(~isnan(PriceA));
    dailyReturnA = zeros(length(PriceA),1);
    for i = 1:length(PriceA)-1
        dailyReturnA(i) = log(PriceA(i+1)/PriceA(i));
        HV(1) = std(dailyReturnA);
    end
end

HV30  = HV*sqrt(252);  % �껯

end
