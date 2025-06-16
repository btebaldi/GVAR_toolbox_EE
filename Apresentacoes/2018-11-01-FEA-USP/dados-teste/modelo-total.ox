#include <oxstd.oxh>
#import <packages/PcGive/pcgive>

Rest(const varia, const passado, const equacao, const Defas,const nt)
{
// varia - lista de equacoes dos modelos
// passado - Variável para procurar as defasagens
// equacao - Equação do VAR
// Defas - Número de defasagens máxima
// Retorna vetor com a lista de variáveis a serem excluidas para realizar o teste F
decl i, j, k, tt=0, indice;
decl rr=rows(varia);
decl Rvar=zeros(rr,1);
	for (i=0; i<Defas+1; i++)
		{
				indice=strfind(varia,sprint(passado,"_",i,"@",equacao));
					if (indice>0)
						{
						Rvar[indice][0]=1;
						}
		}
return Rvar;
}

modelos(const set1, const Defas, const set1a, const title, const title1, const nt)
{
// This program requires a licenced version of PcGive Professional.
	//--- Ox code for SYS( 2)
	decl rr=rows(set1);
	decl r;
	decl model = new PcGive();
//	model.Load("C:\\Users\\emerson.marcal\\Dropbox\\FGV\\CEMAP\\pesquisas\\FEBRABAN\\FEBRABAN-2015\\Atualizacao\\dados-hp.in7");
	model.Load("dados-hp.in7");

	model.Deterministic(3);
	// Allow for lagged seasonals
	model.Grow(-model.GetFrequency());
//	model.CreateInterventions({"DI:2002(11)","DI:2002(12)","DI:2003(1)","DI:2005(5)","I:2005(5)","S1:2003(10)","S1:2003(12)","S1:2008(3)","S1:2008(10)","S1:2009(10)","S1:2018(4)","S1:2018(5)","S1:2018(6)"});
	model.SetModelClass("SYSTEM");
	// Formulation of the GUM (commented out)
	model.DeSelect();
		for (r=0;r<rr;r++)
			{
				model.Select("Y", {set1[r], 0, 12});
			}
	model.Select("X", {"CSeasonal", 0, 10});
	model.Select("U", {"Constant", 0, 0});
	model.Autometrics(0.001, "IIS+SIS+DIIS", 1); // 1 no presearch
	model.AutometricsSet("block_fraction", 0.3);
	model.AutometricsSet("block_max", 20);
	model.AutometricsSet("block_method", 1);
//	model.AutometricsSet("print", 0);
	model.SetSelSample(2001, 3, 2018, 8);
	model.SetMethod("OLS");
	model.Estimate();
	model.TestSummary();
	model.GetCovarRobust();
	decl ARt=model.ArTest(1, 7);
	decl AR3=model.HeteroTest(2, 0);
	decl AR4=model.NormalityTest();
	println(ARt,AR3, AR4);
//	decl varia=model.GetMaxSelLag();
	decl varia=model.GetParNames();
	decl ParValor=model.GetPar();
	decl ParStdValor=model.GetStdErr();
// ########################################################
	decl resultados={"Null of no effect reject for: "};
	decl resultados1={"Null of no effect not reject for: "};
	decl resultadosa={"\multicolumn{6}{|c|}{\\tiny{} Null Hypothesis of no effect is rejected for:} \\tabularnewline \hline"};
	decl resultados1a={"\multicolumn{6}{|c|}{\\tiny{} Null of Hypothesis of no effect is not reject for:} \\tabularnewline \hline"};
	decl j,i, m,n, RR, vv , t1=0, t2=0,dd;
	for (i=0;i<rows(set1);i++)
	{
		for (j=0;j<rows(set1);j++)
		{
			RR=Rest(varia,set1[j],set1[i],12,nt);
			decl rr=rows(varia);
//			println(RR~varia);
			vv=model.TestRestrictions(RR);
			dd=sumc(RR);
//			println("Estatística: ",vv);
				if(vv[1]<=0.01)
				{
					resultados=resultados~sprint(set1[j]," -> ",set1[i]);
					resultadosa=resultadosa~sprint("\\tiny{} { X\\textsubscript{",j+1,"}} &\\tiny{} {->}&\\tiny{} { X\\textsubscript{",i+1,"}} & \\tiny{} {","%8.4g",vv[0],"} & \\tiny{} {$\chi^{2}$(",dd[0],")} & \\tiny{} {[","%4.4f",vv[1],"]} \\tabularnewline \hline");
					t1=t1+1;
				}				  
				else
				{	resultados1=resultados1~sprint(set1[j]," NC->-> ",set1[i]);
					resultados1a=resultados1a~sprint("\\tiny{} { X\\textsubscript{",j+1,"}} &\\tiny{} {->}&\\tiny{} { X\\textsubscript{",i+1,"}} & \\tiny{} {","%8.4g",vv[0],"} & \\tiny{} {$\chi^{2}$(",dd[0],")} & \\tiny{} {[","%4.4f",vv[1],"]} \\tabularnewline \hline");
					t2=t2+1;
				}
		}
	}
// ########################################################
// ########################################################
	decl RR1;
	for (i=0;i<rows(set1);i++)
	{
		RR=zeros(rows(varia),1);
		for (j=0;j<rows(set1)-1;j++)
		{
		RR=Rest(varia,set1[j],set1[i],12,nt);
			for(m=j+1;m<rows(set1);m++)
				{
				RR1=Rest(varia,set1[m],set1[i],12,nt);
				RR1=RR+RR1;
				vv=model.TestRestrictions(RR1);
				dd=sumc(RR1);
					if(vv[1]<=0.05)
					{
						resultados=resultados~sprint(set1[j]," and ",set1[m]," -> ",set1[i]);
						resultadosa=resultadosa~sprint("\\tiny{} { X\\textsubscript{",j+1,"} ","and X\\textsubscript{",m+1,"} }&\\tiny{} {->}&\\tiny{} {X\\textsubscript{",i+1,"} } & \\tiny{} {","%8.4g",vv[0],"} & \\tiny{} {$\chi^{2}$(",dd[0],")} & \\tiny{} {[","%4.4f",vv[1],"]} \\tabularnewline \hline");
						t1=t1+1;
					}
					else
					{	resultados1=resultados1~sprint(set1[j]," and ",set1[m]," NC-> ",set1[i]);
						resultados1a=resultados1a~sprint("\\tiny{} { X\\textsubscript{",j+1,"} ","and X\\textsubscript{",m+1,"} }&\\tiny{} {->}&\\tiny{} {X\\textsubscript{",i+1,"} } & \\tiny{} {","%8.4g",vv[0],"} & \\tiny{} {$\chi^{2}$(",dd[0],")} & \\tiny{} {[","%4.4f",vv[1],"]} \\tabularnewline \hline");
						t2=t2+1;
					}
				}
		}
	}	
// ££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££
	println("#############################################################################");
	println("Results: Granger Causality Tests");
	println("#############################################################################");
	println(resultados);
	println("#############################################################################");
	println(resultados1);
	println("#############################################################################");
// ##################################################################
	println("\\begin{center}");
	println("\\begin{table}[h]");
	println(sprint("\\caption {", title[0], "}"));
	println(sprint("\label{tab:title",nt,"}"));
 	println("\centering");
	println("\\begin{tabular}{|l|l|l|l|l|l|}");
	println("\hline");
	println("\multicolumn{6}{|c|}{ \\tiny{} Summary of the results} \\tabularnewline \hline");
	println("\\tiny{} {Past}  & \\tiny{} {->} & \\tiny{} {Present} &  \\tiny{} {Statistics}  &  \\tiny{} {Distribution}  &  \\tiny{} {p-value}\\tabularnewline \hline");
	if (t1>0){
	println(resultadosa);}
	else{("\multicolumn{6}{|c|}{\tiny{} None } \\tabularnewline \hline");}
	if (t2>0){
	println(resultados1a);}
	else{("\multicolumn{6}{|c|}{ \\tiny{} None } \\tabularnewline \hline");}
	println("\multicolumn{6}{l}{ \\tiny{} Definition of the Variables: } \\tabularnewline ");
	for (i=0;i<rr;i++){
	println(sprint("\multicolumn{6}{l}{ \\tiny{} X\\textsubscript{",i+1,"} - ",set1a[i],"} \\tabularnewline "));};
	println("\\end {tabular}");
	println("\end{table}");
	println("\end{center}");
	delete model;


	decl tabela1;
	decl a0,a1;

	tabela1={"\\begin{center}"};
	tabela1=tabela1~sprint("\\begin{table}[h]");
	tabela1=tabela1~sprint("\\caption {", title1[0], "}");
	tabela1=tabela1~sprint("\label{tab:parameters",nt,"}");
	tabela1=tabela1~sprint("\centering");
	tabela1=tabela1~sprint("\\begin{tabular}{|l|*{",rr,"}}");
	tabela1=tabela1~sprint("\hline");

	a0={"0","2"};
	a0[0]=a0[0]~"3";


	println(tabela1);
	println(a0);

	
	return {resultados, resultados1};

}

main()
{
decl set1={"Saldo","DDemissoes","DLpigeralenc","DLselic"}	;
decl set1a={"Saldo","Demissões-Var","\\Delta ln Industrial Production", "Selic"}	;
decl title1={"Test of the Relevance of the Lags of Variables on Each Equation - Model 1"};
decl title1a={"Parameters, Standard Errrors and Specification - Model 1"};

decl set2={"defaultprivadototal","HPdetrend0","DLselic"}	;
decl set2a={"Private Sector Default","Output Gap","$\\Delta$ Ln Nominal interest rate"}	;
decl title2={"Test of the Relevance of the Lags of Variables on Each Equation - Model 2"};
decl title2a={"Parameters, Standard Errrors and Specification - Model 2"};

decl set3={"defaultprivadototal","HPdetrend0","lnjurosreal","DLselic"}	;
decl set3a={"Private Sector Default","Output Gap","Ln Real interest rate","$\\Delta$ Ln Nominal interest rate"}	;
decl title3={"Test of the Relevance of the Lags of Variables on Each Equation - Model 3"};
decl title3a={"Parameters, Standard Errrors and Specification - Model 3"};

modelos(set1,12,set1a,title1,title1a,1);
//modelos(set2,12,set2a,title2,title2a,2);
//modelos(set3,12,set3a,title3,title3a,3);

}
