%clc;clear;
% Spreadprice Parameter
%Price1 = input('������Ʒ1�ļ۸�');
%Vol1 = input('������Ʒ1�Ĳ����ԣ�');
%Price2 = input('������Ʒ2�ļ۸�');
%Vol2 = input('������Ʒ2�Ĳ����ԣ�');
%num1 = input('������Ʒ1����Ŀ��');
%num2 = input('������Ʒ2����Ŀ��');
%Corr = input('���������ϵ����');
%RiskFreeRate = input('�����޷������ʣ�');
%Strike = input('������ִ�м۸�');
Div1 = 0;Div2 = 0;
Settle = datestr(today());
Maturity = datestr(today()+30); 
Price1 = 4500; Price2 = 4000;      
Vol1 = 0.01;Vol2 = 0.01;
num1=1;num2=1;Corr = 1; 
Strike = num1*Price1-num2*Price2;
%Strike = 200;
RiskFreeRate = 0.03;
%% ���뽻�׷���
% Type 1; ��ʾŷʽ��Ȩ��2 ��ʾ��ʽ��Ȩ
%Type =input('��ѡ����ѡ�����Ȩ����:');
Type = 1;
OptSpec = 'call';
%%
% Spec 1; ��ʾ������Ȩ��2 ��ʾ������Ȩ
%if Spec ==1
    %OptSpec = 'call';
%elseif Spec ==2
    %OptSpec = 'put';
%else
    %msgbox('��Ȩ���׷����������');
%end
%% ����ŷʽ��Ȩ�۸�
if Type == 1
    [ESpreadPrice, ESpreadDelta,ASpreadGamma] = SpredbyEurope(Price1,Price2,num1,num2,Strike,Vol1,Vol2,Div1,Div2,Corr,Settle,Maturity,RiskFreeRate,OptSpec);
    fprintf('�ʺ������Ȩ����Ϊ %f\n ',ESpreadPrice);
    fprintf('�ʺ������Ȩ��Ʒ1��DeltaΪ %f\n ',ESpreadDelta(1));
    fprintf('�ʺ������Ȩ��Ʒ2��DeltaΪ %f\n ',ESpreadDelta(2));
%% ������ʽ��Ȩ�۸�
elseif Type == 2
[ASpreadPrice, ASpreadDelta,ASpreadGamma] = SpredbyAmerican(Price1,Price2,num1,num2,Strike,Vol1,Vol2,Div1,Div2,Corr,Settle,Maturity,RiskFreeRate,OptSpec);
    fprintf('�ʺ������Ȩ����Ϊ %f\n ',ASpreadPrice);
    fprintf('�ʺ������Ȩ��Ʒ1��DeltaΪ %f\n ',ASpreadDelta(1));
    fprintf('�ʺ������Ȩ��Ʒ2��DeltaΪ %f\n ',ASpreadDelta(2));
else
    msgbox('��Ȩ�����������');
end

