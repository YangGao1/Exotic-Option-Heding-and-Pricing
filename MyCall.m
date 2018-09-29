function [call,put] = MyCall(S0,Strike,Sigma,rate,t,steps)
%% 为一个看涨call shout option 进行定价
steps = 100;
DeltaT = t/(steps-1);
a =exp(rate*DeltaT);
u = exp(Sigma*DeltaT^0.5);
d=1/u;
p= (a-d)/(u-d);
q= 1-p;
S = zeros(steps,steps);
opt = zeros(steps,steps);
opt1 = zeros(steps,steps);
for i =1:steps
    for j=1:i
        S(j,i)=S0*u^(i-1)*d^(2*(j-1));
    end;
end
opt(:,end)=max(S(:,end)-Strike,0);
opt1(:,end)=max(Strike-S(:,end),0);
for i = (steps-1):-1:1
    for j =1:i
        opt(j,i)=exp(-rate*DeltaT)*(p*opt(j,i+1)+q*opt(j+1,i+1));
        opt1(j,i)=exp(-rate*DeltaT)*(p*opt1(j,i+1)+q*opt1(j+1,i+1));
    end
end
call =opt(1,1);
put = opt1(1,1);
end