function [CallDelta,PutDelta,Gamma,CallTheta,PutTheta,Vega,CallRho,PutRho] ...
    = AsianGreeksLevy(AssetPrice,Strike,Sigma,Rates,Settle,ExerciseDates)
% if nargin == 5
%     Settle = today;
% end
% Create RateSpec from the interest rate term structure
StartDates = '12-March-2016';
EndDates = '12-March-2017';
%Rates = 0.0405;   
Compounding = -1;
Basis = 1;

RateSpec = intenvset('ValuationDate', StartDates, 'StartDates', StartDates, ...
    'EndDates', EndDates, 'Rates', Rates, 'Compounding', ...
    Compounding, 'Basis', Basis);


StockSpec = stockspec(Sigma, AssetPrice);
                
                
OptSpec = 'call';                
OutSpec = {'Delta';'Gamma';'Theta';'Vega';'Rho'};
% Asian option using Levy model
[CallDelta,Gamma,CallTheta,Vega,CallRho] = asiansensbylevy(RateSpec, StockSpec, OptSpec, Strike, Settle,...
                            ExerciseDates,'OutSpec',OutSpec);

                        
% Asian option using Kemna-Vorst method
% [DeltaLKV,s] = asiansensbykv(RateSpec, StockSpec, OptSpec, Strike, Settle,...
%                         ExerciseDates,  'OutSpec', OutSpec)

OptSpec = 'put';
OutSpec = {'Delta';'Theta';'Rho'};
[PutDelta,PutTheta,PutRho] = asiansensbylevy(RateSpec, StockSpec, OptSpec, Strike, Settle,...
                            ExerciseDates,'OutSpec',OutSpec);
end