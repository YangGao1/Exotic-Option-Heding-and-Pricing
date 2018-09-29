function [CallPrice,PutPrice] = ShoutOptionCRR(S0,ShoutPrice,Strike,Sigma,t,rate)
%% 为一个call shout option 定价
steps = 50;
DeltaT = t/(steps-1);
a =exp(rate*DeltaT);
u = exp(Sigma*DeltaT^0.5);
d=1/u;
p= (a-d)/(u-d);
q= 1-p;
S = zeros(steps,steps);
opt = zeros(steps,steps);
%%
for i =1:steps
    for j=1:i
        S(j,i)=S0*u^(i-1)*d^(2*(j-1));
    end
end
opt(:,steps)=max(S(:,steps)-Strike,0);
opt1(:,steps)=max(Strike-S(:,steps),0);
%% 构造期权价格矩阵 
if  ShoutPrice == 0 
for i= (steps-1):-1:1
    for j = 1:i
        %% 没有shout的情况
        S1 = exp(-rate*DeltaT)*(p*opt(j,i+1)+q*opt(j+1,i+1));
        %% shout锁定收益的情况
        if (S(j,i)>Strike) %% 
            call = MyCall(S(j,i),S(j,i),Sigma,rate,DeltaT*(steps-i),steps-i+1);
            S2 = call+(S(j,i)-Strike)*exp(-rate*DeltaT*(steps-i));
        else
            S2 = 0;
        end
        opt(j,i)=max(S1,S2);
    end
    
        for j = 1:i
        %% 没有shout的情况
        S1 = exp(-rate*DeltaT)*(p*opt1(j,i+1)+q*opt1(j+1,i+1));
        %% shout锁定收益的情况
        if (S(j,i)<Strike) %% 
            [~,put] = MyCall(S(j,i),S(j,i),Sigma,rate,DeltaT*(steps-i),steps-i+1);
            S2 = put+(Strike-S(j,i))*exp(-rate*DeltaT*(steps-i));
        else
            S2 = 0;
        end
        opt1(j,i)=max(S1,S2);
    end
end
CallPrice = opt(1,1);
PutPrice = opt1(1,1);
elseif ShoutPrice - Strike>0
    CallLowest = max(0,ShoutPrice - Strike);
    [~,PutPrice] = blsprice(S0,Strike,rate,t,Sigma,0);
    [CallPrice,~] = blsprice(S0,ShoutPrice,rate,t,Sigma,0);
    CallPrice = CallLowest*exp(-rate*t)+CallPrice;
else
    PutLowest = max(Strike - ShoutPrice,0);
    [CallPrice,~] = blsprice(S0,Strike,rate,t,Sigma,0);
    [~,PutPrice] = blsprice(S0,ShoutPrice,rate,t,Sigma,0);
    PutPrice = PutLowest*exp(-rate*t) +PutPrice;
% else 
%     [CallPrice1,PutPrice1] = blsprice(S0,Strike,rate,t,Sigma,0);
%     [CallPrice2,PutPrice2] = blsprice(S0,ShoutPrice,rate,t,Sigma,0);
%     CallLowest = max(0,ShoutPrice - Strike);
%     PutLowest = max(Strike - ShoutPrice,0);
% if ShoutPrice - Strike>0
%     CallPrice = max(CallLowest*exp(-rate*t)+CallPrice2,CallPrice1);
%     PutPrice = max(PutLowest*exp(-rate*t) +PutPrice1,PutPrice1);
% else
%     CallPrice = max(CallLowest*exp(-rate*t)+CallPrice1,CallPrice1);
%     PutPrice = max(PutLowest*exp(-rate*t) +PutPrice2,PutPrice1);
% end
end
%% 计算Delta数值
end

