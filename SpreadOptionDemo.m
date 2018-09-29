%clc;clear;
% Spreadprice Parameter
%Price1 = input('输入商品1的价格：');
%Vol1 = input('输入商品1的波动性：');
%Price2 = input('输入商品2的价格：');
%Vol2 = input('输入商品2的波动性：');
%num1 = input('输入商品1的数目：');
%num2 = input('输入商品2的数目：');
%Corr = input('请输入相关系数：');
%RiskFreeRate = input('输入无风险利率：');
%Strike = input('请输入执行价格：');
Div1 = 0;Div2 = 0;
Settle = datestr(today());
Maturity = datestr(today()+30); 
Price1 = 4500; Price2 = 4000;      
Vol1 = 0.01;Vol2 = 0.01;
num1=1;num2=1;Corr = 1; 
Strike = num1*Price1-num2*Price2;
%Strike = 200;
RiskFreeRate = 0.03;
%% 输入交易方向
% Type 1; 表示欧式期权；2 表示美式期权
%Type =input('请选择你选择的期权类型:');
Type = 1;
OptSpec = 'call';
%%
% Spec 1; 表示看涨期权；2 表示看跌期权
%if Spec ==1
    %OptSpec = 'call';
%elseif Spec ==2
    %OptSpec = 'put';
%else
    %msgbox('期权交易方向输入错误！');
%end
%% 计算欧式期权价格
if Type == 1
    [ESpreadPrice, ESpreadDelta,ASpreadGamma] = SpredbyEurope(Price1,Price2,num1,num2,Strike,Vol1,Vol2,Div1,Div2,Corr,Settle,Maturity,RiskFreeRate,OptSpec);
    fprintf('彩虹基差期权定价为 %f\n ',ESpreadPrice);
    fprintf('彩虹基差期权商品1的Delta为 %f\n ',ESpreadDelta(1));
    fprintf('彩虹基差期权商品2的Delta为 %f\n ',ESpreadDelta(2));
%% 计算美式期权价格
elseif Type == 2
[ASpreadPrice, ASpreadDelta,ASpreadGamma] = SpredbyAmerican(Price1,Price2,num1,num2,Strike,Vol1,Vol2,Div1,Div2,Corr,Settle,Maturity,RiskFreeRate,OptSpec);
    fprintf('彩虹基差期权定价为 %f\n ',ASpreadPrice);
    fprintf('彩虹基差期权商品1的Delta为 %f\n ',ASpreadDelta(1));
    fprintf('彩虹基差期权商品2的Delta为 %f\n ',ASpreadDelta(2));
else
    msgbox('期权类型输入错误！');
end

