Mdl = arima('AR',{0.5,-0.3},'MA',0.2,'D',1,...
    'Constant',0,'Variance',0.1,'Beta',[1.5 2.6 -0.3]);
T = 500;

numObs = Mdl.P + T;
MdlX1 = arima('AR',0.1,'Constant',0,'Variance',0.01);
MdlX2 = arima('AR',0.2,'Constant',0,'Variance',0.01);
MdlX3 = arima('AR',0.3,'Constant',0,'Variance',0.01);
X1 = simulate(MdlX1,numObs);
X2 = simulate(MdlX2,numObs);
X3 = simulate(MdlX3,numObs);
Xmat = [X1 X2 X3];

y = simulate(Mdl,T,'X',Xmat);

ToEstMdl = arima(2,1,1);
ToEstMdl.Constant = 0

EstMdl = estimate(ToEstMdl,y,'X',Xmat);