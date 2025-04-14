%% IMPORT RAW DATA
clear all;

load('matlab.mat')

clc
%% Define Sample size, and out of sample data
fprintf('\n--- Defining Sample size, and out of sample data ---\n');

T = size(DataPIM_BR,1);     % Total sample size
psT = 3;                    % Pre-sample size
oosT = 0;                   % Out-of-sample size
estT = T -oosT -psT;        % Estimation sample size
pstIdx = 1:psT;             % Pre-Sample indices
exogenousIdx = 1:(T -oosT); % Exogenous data indices
estIdx = (psT+1):(T-oosT);  % Estimation sample indices
oosIdx = (T - oosT + 1):T;  % Out-of-sample indices
fprintf('Total Sample size: %d\n', T);
fprintf('Pre sample size: %d\n', psT);
fprintf('Estimation sample size: %d\n', estT);
fprintf('Out-of-sample size: %d\n', oosT);


%% Preparing the data
fprintf('\n--- Preparing the data ---\n');

% get first and last date of the sample
firstPeriod = Data(1);
lastPeriod = Data(max(estIdx));

fprintf('First Period: %s\n', firstPeriod);
fprintf('Last Period: %s\n', lastPeriod);

% create seasonal dummies
SDummies = dummyvar(month(Data(exogenousIdx)));

PIM_BR = DataPIM_BR(estIdx);
PIM_US = DataPIM_US(estIdx);

% Create Diff, Log and Diff-Log
DPIM_BR = diff(PIM_BR);
DPIM_US = diff(PIM_US);

LPIM_BR = log(PIM_BR);
LPIM_US = log(PIM_US);

DLPIM_BR = diff(LPIM_BR);
DLPIM_US = diff(LPIM_US);

%% Define Y vector and X enxogenous data
fprintf('\n--- Define Y vector and X enxogenous data ---\n');

Y = LPIM_BR;
DY = DLPIM_BR;
DDY = diff(LPIM_BR);

% number of series
n = size(Y,2);

fprintf('Number of series: %d\n', n);

fprintf('\nDescriptive statistics\n');
for ncont = 1:n
    fprintf('\nSeries: Y(%d)\n', ncont);
    fprintf('Mean: %f\n', mean(Y(:,ncont)));
    fprintf('Max: %f\n', max(Y(:,ncont)));
    fprintf('Min: %f\n', min(Y(:,ncont)));
    fprintf('Std Dev: %f\n', std(Y(:,ncont)));
    fprintf('Total: %d\n', size(Y(:,ncont)));
end

% XVAR  = Seasonal Dummies for VAR 
% XVEC = Seasonal Dummies for VECM
Trend = exogenousIdx';
X = [Trend SDummies(:,1:end-1)];


%% DEFINING ARIMA MODEL
fprintf('\n--- DEFINING ARIMA MODEL ---\n');

ToEstMdl = arima(2,0,0);
[EstMdl,EstParamCov,logL,info] = estimate(ToEstMdl, Y, 'X', X);

print(EstMdl,EstParamCov)

[E,V] = infer(EstMdl,Y, 'x', X);

% plot(E);

% [Y2,E2,V2] = filter(EstMdl,E)

% DE = diff(E);
% abs(DE)
joe= find(abs(E) > 3*sqrt(0.0014052) );

Data(joe+2)
% ADF Tests

% [DF_PIM_BR, pval_DF_BR] = adftest(PIM_BR, 'model', 'AR', 'lags', 0:8)
% [DF_PIM_US, pval_DF_US] = adftest(PIM_US, 'model', 'AR', 'lags', 0:8)
    
% fprintf('ADF Result:\n');
% fprintf('      PIM_BR: %d (pval=%d)\n',DF_PIM_BR, pval_DF_BR);
% fprintf('      PIM_US: %d (pval=%d)\n',DF_PIM_US, pval_DF_US);
% fprintf('(diff)PIM_US: %d (pval=%d)\n',DDF_PIM_BR, pval_DDF_BR);
% fprintf('(diff)PIM_US: %d (pval=%d)\n',DDF_PIM_US, pval_DDF_US);



%% SAVE VARIABLES TO EXCEL

% fprintf('\n--- SAVING VARIABLES ---\n');
% 
% filename = 'PIM_GVAR_Output.xlsx';
% fprintf('Output File name: %s\n', filename);
% 
% fprintf('Saving forecasst information\n');
% xlswrite(filename, RelDiff, 'Point Estimates')
% 
% fprintf('Saving impulse information\n');
% xlswrite(filename, Yimpulse, 'Impulse VECM')
% 
% fprintf('Saving dummies information\n');
% xlswrite(filename, Ynoimp, 'No Impulse VECM')
% 

%% END
fprintf('\n--- END OF SCRIPT ---\n');
