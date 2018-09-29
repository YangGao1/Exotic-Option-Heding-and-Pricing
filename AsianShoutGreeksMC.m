function [CallDelta,PutDelta]=AsianShoutGreeksMC(S0,Save,Strike,T,t,r,Sigma,ShoutPrice)%% 亚式期权的MCMC计算方法
n=10000;  
steps=500;
if ShoutPrice == 0
    [S12,S22] = AsianShoutMC(S0,Save,Strike,T,t,r,Sigma,ShoutPrice);
    [S11,S21] = AsianShoutMC(S0+S0*0.01,Save,Strike,T,t,r,Sigma,ShoutPrice);
    CallDelta = (S11-S12)/(S0*0.01);
%   PutDelta=CallDelta - (1-exp(-r*t))/(r*T);
    PutDelta = (S21-S22)/(S0*0.01);
elseif ShoutPrice-Strike>0
    [~,~,CallDelta,~] = AsianOption(S0,Save,ShoutPrice,T,t,r,Sigma);
    [~,~,~,PutDelta] = AsianOption(S0,Save,Strike,T,t,r,Sigma);
else
    [~,~,~,PutDelta] = AsianOption(S0,Save,ShoutPrice,T,t,r,Sigma);
    [~,~,CallDelta,~] = AsianOption(S0,Save,Strike,T,t,r,Sigma);
end
