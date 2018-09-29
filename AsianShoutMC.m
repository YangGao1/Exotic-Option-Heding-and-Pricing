function [CallPrice,PutPrice]=AsianShoutMC(S0,Save,Strike,T,t,r,Sigma,ShoutPrice)%% 亚式期权的MCMC计算方法
%%
n=10000;  
steps=500;
d=t/steps; 
step= (T-t)/d;
S=zeros(steps,n);
Sav=zeros(steps,n);
opt1 = zeros(steps,n);
opt2 = zeros(steps,n);
S(1,:)=S0;%初始化第一行均为50
if (T-t==0)
    Sav(1,:)=S0; %% 包含当天
else
    Sav(1,:)=Save; %% 包含当天
    %% Sav(1,:)=(Save*step+S0)/(step+1); %% 不包含当天
end
%%
for k=1:n
    m=step+1;
for j=2:steps  
     m=m+1;
     S(j,k)=S(j-1,k)*exp((r-0.5*(Sigma^2))*d+sqrt(d)*Sigma*randn(1,1));
     Sav(j,k)=(Sav(j-1,k)*(m-1)+S(j,k))/m; %% 求均值
end
end
%
if ShoutPrice == 0
for k=1:n
    for j=2:steps
        S11 =  max(Sav(j,k)-Strike,0);
%       S12 = mean(Sav(Sav(:,k)>Strike));
        S12 =  max(max(Sav(1:j-1,k)-Strike,0));
%       S13 =  max(min(Sav(1:j-1,k)-Strike,0));
         opt1(j,k)=max(S11,S12/2);
%         opt1(j,k)=max(S11,S12);
        S21 =  max(Strike-Sav(j,k),0);
%       S22 = mean(Sav(Sav(:,k)<Strike));
        S22 = max(max(Strike-Sav(1:j-1,k),0));
%       S23 = max(min(Strike-Sav(1:j-1,k),0));
%         opt2(j,k)=max(S21,S22);
          opt2(j,k)=max(S21,S22/2);
    end
end
%%
CallPrice = mean(opt1(end,:))*exp(-r*t);
PutPrice = mean(opt2(end,:))*exp(-r*t);
%%
elseif ShoutPrice-Strike>0
    CallLowest = max(0,ShoutPrice - Strike);
    [CallPrice ,~] = AsianOption(S0,Save,ShoutPrice,T,t,r,Sigma);
    CallPrice = CallLowest*exp(-r*t)+CallPrice;
    [~,PutPrice] = AsianOption(S0,Save,Strike,T,t,r,Sigma);
else
    PutLowest = max(Strike - ShoutPrice,0);
    [~ ,PutPrice ] = AsianOption(S0,Save,ShoutPrice,T,t,r,Sigma);
    PutPrice =  PutLowest*exp(-r*t)+PutPrice;
    [CallPrice,~] = AsianOption(S0,Save,Strike,T,t,r,Sigma);
end
end

