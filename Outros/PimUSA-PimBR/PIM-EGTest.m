% clear all
clc

origDumMes = dummyvar(month(Data));

% Response data for multiple time series models must be in the form of a
% matrix. Each row of the matrix represents one time, and each column of 
% the matrix represents one time series. The earliest data is the first row,
% the latest data is the last row. The data represents yt in the notation of
% Types of VAR Models. If there are T times and n time series, put the data
% in the form of a T-by-n matrix:

n = 2; % PIM_BR e PIM_USA
% sample size

firstPeriod = Data(1);
lastPeriod = Data(end);

% Preparing the data
nanValues = sum(isnan(origPIM_BR)) % NaN values in series PIM_BR

dum_Mes = origDumMes(1+nanValues:end,:);

PIM_BR = origPIM_BR(1+nanValues:end);
PIM_US = origPIM_USA(1+nanValues:end);

LPIM_BR = log(PIM_BR);
LPIM_US = log(PIM_US);

DLPIM_BR = diff(LPIM_BR);
DLPIM_US = diff(LPIM_US);


T = size(PIM_BR,1);  % Total sample size
oosT = 0;           % Out-of-sample size
estT = T - oosT;     % Estimation sample size
estIdx = 1:estT;     % Estimation sample indices
oosIdx = (T - oosT + 1):T; % Out-of-sample indices

Y = [PIM_BR PIM_US];
LY = [LPIM_BR LPIM_US];
DLY = [DLPIM_BR DLPIM_US];

X = dum_Mes;
X2 = X(2:end,:);



[h,pValue,stat,cValue,reg] = egcitest(Y,'test','t2')
c0 = reg.coeff(1);
b = reg.coeff(2);
beta = [1; -b];
q = 2;
[numObs,numDims] = size(Y);
tBase = (q+2):numObs;                % Commensurate time base, all lags
T = length(tBase);                   % Effective sample size
DeltaYLags = zeros(T,(q+1)*numDims);
YLags = lagmatrix(Y,0:(q+1));        % Y(t-k) on observed time base
LY = YLags(tBase,(numDims+1):2*numDims);
for k = 1:(q+1)
    DeltaYLags(:,((k-1)*numDims+1):k*numDims) = ...
               YLags(tBase,((k-1)*numDims+1):k*numDims) ...
             - YLags(tBase,(k*numDims+1):(k+1)*numDims);
end
DY = DeltaYLags(:,1:numDims);        % (1-L)Y(t)
DLY = DeltaYLags(:,(numDims+1):end); % [(1-L)Y(t-1),...,(1-L)Y(t-q)]
X = [(LY*beta-c0),DLY,ones(T,1)];
P = (X\DY)';                         % [alpha,B1,...,Bq,c1]
alpha = P(:,1);
C = alpha*beta';                     % Error-correction coefficient matrix
B1 = P(:,2:4);                       % VEC(2) model coefficient
B2 = P(:,5:7);                       % VEC(2) model coefficient
c1 = P(:,end);
b = (alpha*c0 + c1)';                % VEC(2) model constant offset
res = DY-X*P';
EstCov = cov(res);