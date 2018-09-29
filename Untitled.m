Price=1;
Strike=1;
Rate=0.04;
Time=1;
Volatility=1;
Yield=0;
Step=10;
[ AmeCallPrice,AmePutPrice,ErouCallPrice,ErouPutPrice,Prob ] = CRRPrice( Price,Strike,Rate,Time,Volatility,Yield,Step )