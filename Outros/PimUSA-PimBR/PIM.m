%% IMPORT RAW DATA
clear all;

load('matlab.mat')

clc


%% Define Sample size, and out of sample data
fprintf('\n--- Defining Sample size, and out of sample data ---\n');

T = size(DataPIM_BR,1);     % Total sample size
psT = 0;                    % Pre-sample size
oosT = 0;                   % Out-of-sample size
estT = T -oosT -psT;        % Estimation sample size
pstIdx = 1:psT;             % Pre-Sample indices
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
SDummies = dummyvar(month(Data(estIdx)));

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

Y = [LPIM_BR LPIM_US];
DY = [DLPIM_BR DLPIM_US];

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
X = SDummies(:,1:end-1);
X_VECM = X(2:end,:);

%% Testing Data for Unit Root
fprintf('\n--- ADF Tests ---\n');

% plot(Y);

% ADF Tests
% [DF_PIM_BR, pval_DF_BR] = adftest(PIM_BR, 'model', 'AR', 'lags', 0:2)
% [DF_PIM_US, pval_DF_US] = adftest(LPIM_US, 'model', 'AR', 'lags', 0:2)

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


% Set exogenous data
EstExpandX_var = kron(X,eye(n));
EstCellX_var = mat2cell(EstExpandX_var, n*ones(estT,1), size(EstExpandX_var,2));
nX_var = size(EstExpandX_var, 2);


% Create Base VAR(12) model
Mdl_VAR12 = vgxset('n', n, 'nAR', 12, 'nX', nX_var, 'Constant', true);
[Est_VAR12_Mdl, Est_VAR12_SE, VAR12_LLF, VAR12_W] = vgxvarx(Mdl_VAR12, Y, EstCellX_var);
% vgxdisp(EstMdl_12, EstSE_Mdl_12)


% Total of restrictions per lag is n^2.
% c = the number of parameters estimated in each equation of the unrestricted system
c = 1 + 12*n + 11; % [cosnt] + [(lags)*(series)] + [dumies]

MaxLag = 12;

% Length = vector of logical lag selection
LagLengthMatrix = [0; 0; 0; 0];

i=MaxLag;
while i>0
%     fprintf('%d = %d \n', i, LagLength);
%     eval(['T' num2str(i) ' = cell2mat(Est_VECM_restrict_Mdl.AR(' num2str(i) '));'])
    
    Mdl_LagLength = vgxset('n', n, 'nAR', i, 'nX', nX_var, 'Constant', true);
    [Est_LagLength_mdl, Est_LagLength_SE,  LagLength_LLF,  LagLength_W] = vgxvarx(Mdl_LagLength, Y, EstCellX_var);
    
    DF_lag = (12-i)*n^2;
    p = chi2inv(0.95, DF_lag);
    Chi = (T-c)*(log(det(Est_LagLength_mdl.Q)) - log(det(Est_VAR12_Mdl.Q)));
    LagLengthMatrix = [LagLengthMatrix [i; p<Chi; Chi; p]];

    if (p<Chi)
        break;
    end
    
    i=i-1;
end
    
LagLengthMatrix = LagLengthMatrix(:,2:end);
fprintf('Lag matrix\n');
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


%% Cointegration test (Johansen)

disp('--- Cointegration test (Johansen) ---');

% 'H2'	AB´yt?1. There are no intercepts or trends in the cointegrating relations 
% and there are no trends in the data. This model is only appropriate if all 
% series have zero mean.
% 
% 'H1*'	A(B´yt?1+c0). There are intercepts in the cointegrating relations 
% and there are no trends in the data. This model is appropriate for nontrending 
% data with nonzero mean.
% 
% 'H1'	A(B´yt?1+c0)+c1. There are intercepts in the cointegrating relations 
% and there are linear trends in the data. This is a model of deterministic 
% cointegration, where the relations eliminate both stochastic and deterministic 
% trends in the data. This is the default value.
% 
% 'H*'	A(B´yt?1+c0+d0t)+c1. There are intercepts and linear trends in the 
% cointegrating relations and there are linear trends in the data. This is a
% model of stochastic cointegration, where the relations eliminate stochastic 
% but not deterministic trends in the data.
% 
% 'H' 	A(B´yt?1+c0+d0t)+c1+d1t. There are intercepts and linear trends in
% the cointegrating relations and there are quadratic trends in the data. 
% Unless quadratic trends are actually present in the data, this model might 
% produce good in-sample fits but poor out-of-sample forecasts.


% [h,pValue,stat,cValue,mles] = jcitest(LY, 'lags', 6, 'display', 'full', 'alpha', 0.01)
% [h_j2, pValue_j2, stat_j2, cValue_j2, mles_j2] = jcontest(Y, 1, 'ACon', [0;1], 'lags', 12)
% [h_e, pValue_e, stat_e, cValue_e, reg_c] = egcitest(Y, 'lags', 1:12)
[Johansen_h, Johansen_pValue, Johansen_stat, Johansen_cValue, Johansen_mles] = jcitest(Y, 'lags', LagLength-1);
[EG_h, EG_pValue, EG_stat, EG_cValue, EG_reg1, EG_reg2] = egcitest(Y);
disp(EG_h);

%% ESTIMANDO BETA DE COINTEGRACAO
fprintf('\n--- ESTIMANDO BETA DE COINTEGRACAO ---\n');

% ols_beta = fitlm([Y(:,2) X], Y(:,1), 'PredictorVars',{'PIM US','Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov'});
ols_beta = fitlm(Y(:,2), Y(:,1), 'PredictorVars',{'PIM US'}, 'Intercept', true);
disp(ols_beta);
beta = table2array(ols_beta.Coefficients(2,1));
intercept = table2array(ols_beta.Coefficients(1,1));

fprintf('beta de cointegracao = %f \n', beta);
fprintf('intercepto de cointegracao = %f \n', intercept);

%% Modelo VECM
fprintf('\n--- Modelo VECM ---\n');

% determinacao do Longo prazo
LP = Y(1:end-1,1) -beta*Y(1:end-1,2) + intercept;
EstExpandX_vecm = kron([LP X_VECM],eye(n));
EstCellX_vecm = mat2cell(EstExpandX_vecm, n*ones(estT-1,1), size(EstExpandX_vecm,2));
nX_vecm = size(EstExpandX_vecm, 2);

% MdlVECM = vgxset('n',n,'nAR', 12, 'nX', nX_vecm, 'Constant', true);

% Assumindo que US é Exogeno Fraco
 Mdl_VECM_restrict = vgxset('n', n, 'nAR', LagLength-1, 'nX', nX_vecm, 'Constant', true , 'bsolve', logical([1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]));
 Mdl_VECM_full = vgxset('n', n, 'nAR', LagLength-1, 'nX', nX_vecm, 'Constant', true , 'bsolve', logical([1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]));
  
% Estimo o modelo
[Est_VECM_restrict_Mdl, Est_VECM_restrict_SE, VECM_restrict_LLF, VECM_restrict_W] = vgxvarx(Mdl_VECM_restrict, DY, EstCellX_vecm);
[Est_VECM_full_Mdl, Est_VECM_full_SE, VECM_full_LLF, VECM_full_W] = vgxvarx(Mdl_VECM_full, DY, EstCellX_vecm);
vgxdisp(Est_VECM_restrict_Mdl, Est_VECM_restrict_SE, Est_VECM_full_Mdl, Est_VECM_full_SE);

% LR = 2*(VECM_full_LLF - VECM_restrict_LLF);
% p = chi2inv(0.95, 1);

alpha = [Est_VECM_restrict_Mdl.b(1); Est_VECM_restrict_Mdl.b(2)];
P = alpha*[1 -beta];

T1 = cell2mat(Est_VECM_restrict_Mdl.AR(1));
T2 = cell2mat(Est_VECM_restrict_Mdl.AR(2));
T3 = cell2mat(Est_VECM_restrict_Mdl.AR(3));
T4 = cell2mat(Est_VECM_restrict_Mdl.AR(4));
T5 = cell2mat(Est_VECM_restrict_Mdl.AR(5));
T6 = cell2mat(Est_VECM_restrict_Mdl.AR(6));
F =  Est_VECM_restrict_Mdl.b(3:24);

%% FORECASTING VECM => VAR
fprintf('\n--- FORECASTING VECM ---\n');

if (LagLength ~= 7)
    fprintf('\nlag length=%d\n', LagLength);
    error('Forecasting not suitable for lag length != 7')
end 


% Modelo VAR
% VECM => DYt = C1 + alpha([1 -b]' +c0)*LP + T1*DYt-1 + T2*DYt-2 + T3*DYt-3 + T4*DYt-4 + T5*DYt-5 + T6*DYt-6 + F*Dummies
% VECM => DYt = (C1 + alpha*c0) + (alpha*[1 -b]')*LP + T1*DYt-1 + T2*DYt-2 + T3*DYt-3 + T4*DYt-4 + T5*DYt-5 + T6*DYt-6 + F*Dummies
% VECM => DYt = (C1 + alpha*c0) + P*LP + T1*DYt-1 + T2*DYt-2 + T3*DYt-3 + T4*DYt-4 + T5*DYt-5 + T6*DYt-6 + F*Dummies
% VAR  => Yt =  A0 + A1*Yt-1 + A2*Yt-2 + A3*Yt-3 + A4*Yt-4 + A5*Yt-5 + A6*Yt-6 + A7*Yt-7 + F*Dummies 

% A0 = (C1 + alpha*c0)
% A1 = T1 + P + I
% A2 = T2-T1  ...
% A7 = -T6

I = eye(2);

A0 = vgxget(Est_VECM_restrict_Mdl, 'a')+alpha*intercept;
A1 = T1 + P + I;
A2 = T2-T1;
A3 = T3-T2;
A4 = T4-T3;
A5 = T5-T4;
A6 = T6-T5;
A7 = -1*T6;

Q0 = Est_VECM_restrict_Mdl.Q;

fprintf(' Building VAR for forecast\n');

EstExpandX_var = kron(X,eye(n));
EstCellX_var = mat2cell(EstExpandX_var, n*ones(estT,1), size(EstExpandX_var,2));
nX_var = size(EstExpandX_var, 2);

mdl_VECM_Forecast = vgxset('n', n, ...
              'a', A0, ...
              'b', F, ...
              'AR', {A1, A2, A3, A4, A5, A6, A7}, ...
              'Q', Q0, ...
              'bsolve', false(22,1), ...
              'asolve', false(2,1), ...
              'ARsolve', repmat({false(2)}, LagLength, 1), ... 
              'nX', nX_var, ...
              'Qsolve', false(2), ...
              'Constant', true, ...
              'Series',...
  {'Log_BR','Log_US'});

[W_Forecast,logL_Forecast] = vgxinfer(mdl_VECM_Forecast, Y, EstCellX_var);

RSS = W_Forecast'*W_Forecast;

% Variaveis estimadas
QtdEstimatedVariables

Omega = Rss/(size(Y,1) - ;

% FORECAST
fprintf(' Forecast variables\n');
ForecastT = 48; % Forcast time period
ForecastDummies = SDummies(end-ForecastT+1:end,:);
ForecastX = ForecastDummies(:,1:end-1);
ForecastEstExpandX_var = kron(ForecastX,eye(n));
ForecastEstCellX_var = mat2cell(ForecastEstExpandX_var, n*ones(ForecastT,1), size(ForecastEstExpandX_var,2));

fprintf(' Forecast perido: %d\n', ForecastT);

% FORECAST MODELO ORIGINAL
[Forecast_Y_VECM, Forecast_Y_Cov_VECM]  = vgxpred(mdl_VECM_Forecast, ForecastT, ForecastEstCellX_var, Y);
vgxplot(mdl_VECM_Forecast, Y, Forecast_Y_VECM, Forecast_Y_Cov_VECM);

%% IMPUSE RESPONSE

fprintf('\n--- IMPUSE RESPONSE ---\n');

% vgxdisp(VEC1);
W0 = zeros(ForecastT, 2); % Innovations without a shock
W1 = W0;
W1(1,2) = 1*sqrt(mdl_VECM_Forecast.Q(2,2)); % Innovations with a shock

Yimpulse = vgxproc(mdl_VECM_Forecast, W1, ForecastEstCellX_var, Y); % Process with shock
Ynoimp   = vgxproc(mdl_VECM_Forecast, W0, ForecastEstCellX_var, Y); % Process with no shock

PointEstimates = (Yimpulse - Ynoimp);
plot(100*PointEstimates);


%% SIMULATION BY MONTE CARLO

% Ysim = vgxsim(Est_Forecast_VECM, ForecastT, ForecastEstCellX_var, Y, [], 100);
% 
% Ymean = mean(Ysim,3); % Calculate means
% Ystd = std(Ysim,0,3); % Calculate std deviations
% 
% vgxplot(Est_Forecast_VECM, Y, Ysim);
% 
% figure
% subplot(2,1,1)
% plot(1:size(Y(:,1),1), Y(:,1), 'k')
% hold('on')
% plot(size(Y(:,1),1):size(Y(:,1),1)+48, [Y(end,1);Ymean(:,1)],'r')
% plot(size(Y(:,1),1):size(Y(:,1),1)+48, [Y(end,1);Ymean(:,1)]+[0;Ystd(:,1)],'b')
% plot(size(Y(:,1),1):size(Y(:,1),1)+48, [Y(end,1);Ymean(:,1)]-[0;Ystd(:,1)],'b')
% title('BR')
% subplot(2,1,2)
% plot(1:size(Y(:,2),1), Y(:,2), 'k')
% hold('on')
% plot(size(Y(:,2),1):size(Y(:,2),1)+48, [Y(end,2);Ymean(:,2)],'r')
% plot(size(Y(:,2),1):size(Y(:,2),1)+48, [Y(end,2);Ymean(:,2)]+[0;Ystd(:,2)],'b')
% plot(size(Y(:,2),1):size(Y(:,2),1)+48, [Y(end,2);Ymean(:,2)]-[0;Ystd(:,2)],'b')
% title('US')


%% SAVE VARIABLES TO EXCEL

fprintf('\n--- SAVING VARIABLES ---\n');

filename = 'PIM_Output.xlsx';
fprintf('Output File name: %s\n', filename);

fprintf('Saving forecasst information\n');
xlswrite(filename, Forecast_Y_VECM, 'Forecast VECM')

fprintf('Saving impulse information\n');
xlswrite(filename, Yimpulse, 'Impulse VECM')

fprintf('Saving no impulse information\n');
xlswrite(filename, Ynoimp, 'No Impulse VECM')

fprintf('Saving point estimates information\n');
xlswrite(filename, PointEstimates, 'Point Estimates VECM')

fprintf('Saving dummies information\n');
xlswrite(filename, ForecastX, 'Forecast Dummies')

%% END
fprintf('\n--- END OF SCRIPT ---\n');
