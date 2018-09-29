
function [CallPrice,PutPrice,CallDelta,PutDelta] = AsianOption4(S,Save,Strike,T,t,t1,r,Sigma) %t1��ʾ�����t1���ƽ������Ϊ�����
if t>=t1
T=t;
else if t<t1
        T=t1;
    end
end
 if t>10/250
     a =0.005;
 else
     a = 0.0006;
 end
%% �ܱ�֤׼ȷ
for i=1:100
  G = (Strike*T-Save*(T-t))/S;
  X(i)=G+a*(i-1);
%%
n=10000;
steps=300;
d=t/steps;
B=zeros(steps,n);
B(1,:)=1;%��ʼ����һ�о�Ϊ1
for j=2:steps
     for k=1:n
      B(j,k)=B(j-1,k)*exp((r-0.5*(Sigma^2))*d+sqrt(d)*Sigma*randn(1,1));
     end
end
m=0;
for l=1:n
    if t>=t1
    y(l)=mean(B(fix(300-300*t1/t)+1:300,l));
    else if t<t1
           y(l)=mean(B(:,l));
        end
    end
    if t*y(l)>X(i)
    m=m+1;
    end
end
Y(i)=m/n;
if Y(i)<0.001
    break
end
end
f=@(t)interp1(X,Y,t,'pchip','extrap');%�ò�ֵ����ϻ��ֺ���
integral=quadl(f,G,X(i));
CallPrice=integral*exp(-r*t)*S/T;

Put = CallPrice-(((T-t)*Save/T-S/(r*T)-Strike)*exp(-r*t)+S/(r*T));
if Put <=0
    PutPrice = 0;
else
   PutPrice = Put;
end
CallDelta = CallPrice/S+G*Y(1)*exp(-r*t)/T;
if PutPrice ~=0
    PutDelta =  CallDelta - (1-exp(-r*t))/(r*T);
else 
    PutDelta = 0
end

end