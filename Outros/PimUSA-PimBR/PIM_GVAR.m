%% IMPORT RAW DATA
clear all;

load('matlab.mat')

clc
%% Define Sample size, and out of sample data

T = size(DataPIM_BR,1);  % Total sample size
psT = 0;           % Pre-sample size
oosT = 0;            % Out-of-sample size

estT = T -oosT -psT;     % Estimation sample size

pstIdx = 1:psT;            % Pre-Sample indices
estIdx = (psT+1):(T-oosT);     % Estimation sample indices
oosIdx = (T - oosT + 1):T; % Out-of-sample indices


%% Preparing the data
fprintf('\n--- Preparing the data ---\n');

% get first and last date of the sample
firstPeriod = Data(estIdx(1));
lastPeriod = Data(max(estIdx));

fprintf('First Date: %s\n', firstPeriod);
fprintf('Last Date: %s\n', lastPeriod);

% number of series
n = 2; % PIM_BR e PIM_USA

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

fprintf('Y = [LPIM_BR LPIM_US]\n');

% Y = [PIM_BR PIM_US];
% DY = [DPIM_BR DPIM_US];
Y = [LPIM_BR LPIM_US];
DY = [DLPIM_BR DLPIM_US];


%% Testing Data for Unit Root
fprintf('\n--- ADF Tests ---\n');

% plot(Y);

% ADF Tests
[DF_PIM_BR, pval_DF_BR] = adftest(Y(:,1));
[DF_PIM_US, pval_DF_US] = adftest(Y(:,2));

[DDF_PIM_BR, pval_DDF_BR] = adftest(DY(:,1));
[DDF_PIM_US, pval_DDF_US] = adftest(DY(:,2));

% [DF_PIM_BR, pval_DF_BR] = adftest(PIM_BR, 'model', 'AR', 'lags', 0:8)
% [DF_PIM_US, pval_DF_US] = adftest(PIM_US, 'model', 'AR', 'lags', 0:8)

fprintf('ADF Result:\n');
fprintf('      PIM_BR: %d (pval=%d)\n',DF_PIM_BR, pval_DF_BR);
fprintf('      PIM_US: %d (pval=%d)\n',DF_PIM_US, pval_DF_US);
fprintf('(diff)PIM_US: %d (pval=%d)\n',DDF_PIM_BR, pval_DDF_BR);
fprintf('(diff)PIM_US: %d (pval=%d)\n',DDF_PIM_US, pval_DDF_US);


%% LAG LENGTH
fprintf('\n--- LAG LENGTH ---\n');

fprintf('obs: Lag length will be done in VAR form\n');

% Create Base VAR(12) model
Mdl_VAR12 = vgxset('n', n, 'nAR', 12);
[Est_VAR12_Mdl, Est_VAR12_SE, VAR12_LLF, VAR12_W] = vgxvarx(Mdl_VAR12, Y);

% Total of restrictions per lag is n^2.
% c = the number of parameters estimated in each equation of the unrestricted system
c = 0 + 12*n + 0; % [cosnt] + [(lags)*(series)] + [dumies]

MaxLag = 12;

% Length = vector of logical lag selection
LagLengthMatrix = [0; 0; 0; 0];

i=MaxLag;
while i>0
%     fprintf('%d = %d \n', i, LagLength);
%     eval(['T' num2str(i) ' = cell2mat(Est_VECM_restrict_Mdl.AR(' num2str(i) '));'])
    
    Mdl_LagLength = vgxset('n', n, 'nAR', i);
    [Est_LagLength_mdl, Est_LagLength_SE,  LagLength_LLF,  LagLength_W] = vgxvarx(Mdl_LagLength, Y);
    
    DF_lag = (12-i)*n^2;
    p = chi2inv(0.95, DF_lag);
    Chi = (T-c)*(log(det(Est_LagLength_mdl.Q)) - log(det(Est_VAR12_Mdl.Q)));
    LagLengthMatrix = [LagLengthMatrix [i; p<Chi; Chi; p]];

    i=i-1;    
end
    
LagLengthMatrix = trimr(LagLengthMatrix', 1, 0)';
disp(LagLengthMatrix);

LagLength = 12;
for i=2:10
%     disp(i);
    if (LagLengthMatrix(2,i) == 1)
        LagLength = LagLengthMatrix(1,i);
        break
    end
end


fprintf('LagLength = %d \n', LagLength );

LagLength = 2;
fprintf('LagLength = %d \n', LagLength );

%% Cointegration test (Johansen)

fprintf('\n--- Cointegration test (Johansen) ---\n');

% 'H2'	AB큮t?1. There are no intercepts or trends in the cointegrating relations 
% and there are no trends in the data. This model is only appropriate if all 
% series have zero mean.
% 
% 'H1*'	A(B큮t?1+c0). There are intercepts in the cointegrating relations 
% and there are no trends in the data. This model is appropriate for nontrending 
% data with nonzero mean.
% 
% 'H1'	A(B큮t?1+c0)+c1. There are intercepts in the cointegrating relations 
% and there are linear trends in the data. This is a model of deterministic 
% cointegration, where the relations eliminate both stochastic and deterministic 
% trends in the data. This is the default value.
% 
% 'H*'	A(B큮t?1+c0+d0t)+c1. There are intercepts and linear trends in the 
% cointegrating relations and there are linear trends in the data. This is a
% model of stochastic cointegration, where the relations eliminate stochastic 
% but not deterministic trends in the data.
% 
% 'H' 	A(B큮t?1+c0+d0t)+c1+d1t. There are intercepts and linear trends in
% the cointegrating relations and there are quadratic trends in the data. 
% Unless quadratic trends are actually present in the data, this model might 
% produce good in-sample fits but poor out-of-sample forecasts.


% [h,pValue,stat,cValue,mles] = jcitest(LY, 'lags', 6, 'display', 'full', 'alpha', 0.01)
% [h_j2, pValue_j2, stat_j2, cValue_j2, mles_j2] = jcontest(Y, 1, 'ACon', [0;1], 'lags', 12)
% [h_e, pValue_e, stat_e, cValue_e, reg_c] = egcitest(Y, 'lags', 1:12)
[Johansen_h, Johansen_pValue, Johansen_stat, Johansen_cValue, Johansen_mles] = jcitest(Y, 'lags', LagLength-1, 'display', 'params', 'model', 'H1');

J_A0 = Johansen_mles.r1.paramVals.c1 + Johansen_mles.r1.paramVals.A * Johansen_mles.r1.paramVals.c0;
J_PiMatrix = Johansen_mles.r1.paramVals.A * Johansen_mles.r1.paramVals.B'

J_B1 = Johansen_mles.r1.paramVals.B1;

J_Q = Johansen_mles.r1.EstCov;

%% FORECASTING VECM(5) => VAR(6)
fprintf('\n--- FORECASTING VECM ---\n');

% Modelo VAR
% VAR  => Yt =  A0 + d*Du + A1*Yt-1 + A2*Yt-2 + A3*Yt-3 + A4*Yt-4 + A5*Yt-5 + A6*Yt-6 + A7*Yt-7 
% VECM => DYt = A0 + d*Du + P*LP + T1*DYt-1 + T2*DYt-2 + T3*DYt-3 + T4*DYt-4 + T5*DYt-5 + T6*DYt-6 
% 
% A1 = T1 + P + I
% A2 = T2-T1  ... A6 = -T5

I = eye(n);
A0 = J_A0;
A1 = J_B1 + J_PiMatrix + I;
A2 = -J_B1;

Q0 = J_Q;

mdl_Forecast_VECM2 = vgxset('n', n, ...
              'a', A0, ...
              'AR', {A1, A2}, ...
              'Q', Q0, ...
              'asolve', false(2,1), ...
              'ARsolve', repmat({false(2)}, LagLength, 1), ... 
              'Qsolve', false(2), ...
              'Constant', true, ...
              'Series',...
  {'Log_BR','Log_US'});

% FORECAST
ForecastT = 48; % Forcast time period

% FORECAST MODEL
[FY_VECM, FYCov_VECM]  = vgxpred(mdl_Forecast_VECM2, ForecastT, [], Y);
vgxplot(mdl_Forecast_VECM2, Y, FY_VECM, FYCov_VECM);


%% IMPUSE RESPONSE

fprintf('\n--- IMPUSE RESPONSE ---\n');

% vgxdisp(VEC1);
W0 = zeros(ForecastT, 2); % Innovations without a shock
W1 = W0;
W1(1,2) = 1*sqrt(mdl_Forecast_VECM2.Q(2,2)); % Innovations with a shock

Yimpulse = vgxproc(mdl_Forecast_VECM2, W1,[],Y); % Process with shock
Ynoimp   = vgxproc(mdl_Forecast_VECM2, W0,[],Y); % Process with no shock

RelDiff = (Yimpulse - Ynoimp);
plot(100*RelDiff);


%% SAVE VARIABLES TO EXCEL

fprintf('\n--- SAVING VARIABLES ---\n');

filename = 'PIM_GVAR_Output.xlsx';
fprintf('Output File name: %s\n', filename);

fprintf('Saving forecasst information\n');
xlswrite(filename, RelDiff, 'Point Estimates')

fprintf('Saving impulse information\n');
xlswrite(filename, Yimpulse, 'Impulse VECM')

fprintf('Saving dummies information\n');
xlswrite(filename, Ynoimp, 'No Impulse VECM')


%% END
fprintf('\n--- END OF SCRIPT ---\n');
