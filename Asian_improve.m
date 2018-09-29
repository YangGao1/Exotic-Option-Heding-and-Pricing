function [Price,Var,UP]=Asian_improve(S0,K,r,T,sigma,type,divide,road,control)
% Asian_improve     ��ʽ��Ȩ���ؿ��嶨�۸Ľ�ģ�͡������ÿ��Ʊ�������
% S0                ����ʲ��۸�                 
% K                 ִ�м۸�
% r                 �޷���������
% T                 ʣ�����ޣ��껯��
% sigma             ��Ʊ�����ı�׼��
% type              ������Ȩ�����ͣ�1��ʾ������Ȩ���ۣ�0��ʾ������Ȩ����
% divide            ÿ��·���Ĳ����㣬ʱ����ɢ�Ĳ���
% road              ģ���·��������
% control           ���Ʊ����������������ʲ��۸�·������

% Price             ��Ȩ���ۼ۸�                         
% Var               ��Ȩ���ۼ۸�ķ���
% UP                95%�����������Ȩ�۸����½� 

if nargin == 6
    divide  = 2500;
    road    = 5000;
    control = 3000;
elseif nargin == 7
    road    = 5000;
    control = 5000;
elseif nargin == 8
    control = 5000;
end


%% ���Ʊ�����������
controlpath  = AssetPaths(S0,r,sigma,T,divide,control);
sumroad      = sum(controlpath,2);
avg_randroad = mean(controlpath(:,2:(divide+1)),2);
clear controlpath;   % �ͷ��ڴ�
if type == 0
    control_profit = exp(-r*T)*max(0,K-avg_randroad);
elseif type == 1
    control_profit = exp(-r*T)*max(0,avg_randroad-K);
else 
    error('�������˴����type,������0��1');
end

MatCov = cov(sumroad,control_profit);      % ��Э����
bb = var(sumroad);
c  = -MatCov(1,2)/bb;
Eall = S0*((1-exp(r*T))/(1-exp(r*T/(divide+1))));   % ����ʱ���ʲ��۸���͵�����ֵ

%% ��Ľ�����Ȩ�۸���ֵ
control_payoff=zeros(road,1);
for i=1:road
    stock_path = AssetPaths(S0,r,sigma,T,divide,1);
    if type == 0
        payoff = exp(-r*T)*max(0,K-mean(stock_path(2:(divide+1))));
    elseif type == 1
        payoff = exp(-r*T)*max(0,mean(stock_path(2:(divide+1)))-K);
    end
    control_payoff(i) = payoff+c*(sum(stock_path)-Eall);
end
[Price,Var,UP] = normfit(control_payoff);     

end
