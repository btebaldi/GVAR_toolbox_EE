% Limpeza
clc, clearvars -except MdiaVarPimAno SomaEmpLiqNoAno Ano

% definindo variaveis
Y=SomaEmpLiqNoAno;
X0=MdiaVarPimAno;

c = 6

idx_1 = [1:c];
idx_2 = [(c+1):22];
idx_3 = [1:22];
Ano(idx_1)
Ano(idx_2)
Ano(idx_3);

% Mdl_Fgls_1 = fgls(X0(idx_1), Y(idx_1), 'arLags', 5, 'display', 'final');
% Mdl_Fgls_2 = fgls(X0(idx_2), Y(idx_2), 'arLags', 5, 'display', 'final');
% Mdl_Fgls_3 = fgls(X0(idx_3), Y(idx_3), 'arLags', 5, 'display', 'final');

Mdl_Ols_1 = fitlm(X0(idx_1), Y(idx_1), 'VarNames', {'IPGR', 'NE'})
Mdl_Ols_2 = fitlm(X0(idx_2), Y(idx_2), 'VarNames', {'IPGR', 'NE'})
Mdl_Ols_3 = fitlm(X0(idx_3), Y(idx_3), 'VarNames', {'IPGR', 'NE'})

scatter(X0,Y)
hline = refline(Mdl_Ols_1.Coefficients.Estimate(2,1), Mdl_Ols_1.Coefficients.Estimate(1,1))
hline.Color = 'r';

hline = refline(Mdl_Ols_2.Coefficients.Estimate(2,1), Mdl_Ols_2.Coefficients.Estimate(1,1))
hline.Color = 'b';

hline = refline(Mdl_Ols_3.Coefficients.Estimate(2,1), Mdl_Ols_3.Coefficients.Estimate(1,1))
hline.Color = 'g';

% GVAR ESTIMATIVAS
hline = refline( 257535, 693936)
hline.Color = 'black';

ax = gca
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';

Mdl_Ols_1.Coefficients.Estimate
mdl_arima = arima(0,0,0)

Mdl_ARIMA_1 = estimate(mdl_arima, Y(idx_1), 'X', X0(idx_1));
Mdl_ARIMA_2 = estimate(mdl_arima, Y(idx_2), 'X', X0(idx_2));
Mdl_ARIMA_3 = estimate(mdl_arima, Y(idx_3), 'X', X0(idx_3));
