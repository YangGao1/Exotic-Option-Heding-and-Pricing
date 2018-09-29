function [CallDelta,PutDelta]= shoutgreeksCRR(S0,ShoutPrice,Strike,Sigma,t,rate)
steps=50;
DeltaT = t/(steps-1);
a =exp(rate*DeltaT);
u = exp(Sigma*DeltaT^0.5);
d=1/u;
%% DeltaµÄ¼ÆËã
if ShoutPrice == 0
[f11,f12]= ShoutOptionCRR(S0*u,ShoutPrice,Strike,Sigma,t,rate);
[f01,f02] = ShoutOptionCRR(S0*d,ShoutPrice,Strike,Sigma,t,rate);
CallDelta = (f11-f01)/(S0*(u-d));
PutDelta = (f12-f02)/(S0*(u-d));
elseif ShoutPrice - Strike>0
[CallDelta,~] = blsdelta(S0,ShoutPrice,rate,t,Sigma);
[~,PutDelta] = blsdelta(S0,Strike,rate,t,Sigma,0);
else
[CallDelta,~]=blsdelta(S0,Strike,rate,t,Sigma,0);
[~,PutDelta] = blsdelta(S0,ShoutPrice,rate,t,Sigma);
end
end
