*/////////////////////////////;
* LOAD DATASET
*/////////////////////////////;

/* Create a library - get access to the data;*/
libname b "C:\Users\Jose Caloca\Desktop\SGH\2 semester\Logistic Regression with SAS\project\dataset";

/* set formats;*/

PROC FORMAT lib=work;
value sex
1 = 'Male'
2 = 'Female'
9 = 'No answer' .d = 'No answer';
value sourceinc
1 = 'Wages or salaries'  
2 = 'Income from self-employment (excluding farming)'  
3 = 'Income from farming'  º
4 = 'Pensions'  
5 = 'Unemployment/redundancy benefit'  
6 = 'Any other social benefits or grants'  
7 = 'Income from investments, savings etc.'  
8 = 'Income from other sources'  
77 = 'Refusal' .b = 'Refusal'  
88 = 'Don''t know' .c = 'Don''t know'  
99 = 'No answer' .d = 'No answer' ;
value mainactivity
1 = 'Employed'
2 = 'Unemployed'
3 = 'Inactive'
4 = 'Other';
value peoplelivinghouse
77 = 'Refusal' .b = 'Refusal'  
88 = 'Don''t know' .c = 'Don''t know'  
99 = 'No answer' .d = 'No answer' ;
value yearsedu
77 = 'Refusal' .b = 'Refusal'  
88 = 'Don''t know' .c = 'Don''t know'  
99 = 'No answer' .d = 'No answer' ;
value age
999 = 'Not available' .d = 'Not available' ;
value national_income
1 = 'Labour Income'
2 = 'Capital Income'
3 = 'Grants'
4 = 'Other Income';
run;

/* load dataset;*/

data ess;
set b.ess9e03_1;
format hincsrca sourceinc. gndr sex. mnactic  hhmmb peoplelivinghouse. eduyrs yearsedu. agea age.;
keep hincsrca gndr mnactic hhmmb eduyrs agea;
where cntry = 'ES';
run;


*/////////////////////////////;
* DROPPING: not applicable, refusal, don't know
and no answer ;
*/////////////////////////////;

*Check the distribution of the response variable PRIOR MODIFYING;

proc freq data=ess;
    table hincsrca;
run;

* 'Refusal' and 'Don't know' = 2.46% of the dataset, therefore we can drop these values;

data ess_01;
set ess;
if hincsrca in (77,88,99) then delete;
if gndr = 9 then delete;
if mnactic in (66,77,88,99) then delete;
if hhmmb in (77,88,99) then delete;
if eduyrs in (77,88,99) then delete;
if agea = 999 then delete;
run;

* Check missing values;

proc means data=ess_01 n nmiss;
var hincsrca gndr mnactic hhmmb eduyrs agea;
run;

*Check the distribution of the response variable AFTER MODIFYING;

proc freq data=ess_01;
    table hincsrca;
run;


*/////////////////////////////;
* TARGET VARIABLE PREPARATION ;
*/////////////////////////////;

* GDP Income Approach = Total National Income + Sales Taxes + Depreciation + Net Foreign Factor Income
* Total National Income = Wages (labour income) + Rent (Capital Income) +  Grants + Other Income;

* Group categories in the target variable:

1 = Labour Income
2 = Capital Income
3 = Grants
4 = Other Income

mnactic
1 = 'Employed'
2 = 'Unemployed'
3 = 'Inactive'
4 = 'Other'
;

/* relabel hincsrca, mnactic*/
data ess_02 (drop=hincsrca);
set ess_01;
format y national_income. mnactic mainactivity.;
if hincsrca in (1, 3) then y=1;
else if hincsrca in (2, 7) then y=2;
else if hincsrca in (4, 5, 6) then y=3;
else if hincsrca=8 then y=4;
else y=.;
if mnactic in (1, 7) then mnactic=1;
else if mnactic in (3, 4) then mnactic=2;
else if mnactic in (5, 6) then mnactic=3;
else mnactic=4;
run;

*Check the distribution of the response variable AFTER MODIFYING;

proc freq data=ess_02;
    table y;
run;

*/////////////////////////////;
* EXPLORATORY DATA ANALYSIS ;
*/////////////////////////////;


/*********************** DISCRIMINATORY PERFORMANCE ANALYSIS;

/*Folder to save the plots*/
%let graphs = C:\Users\Jose Caloca\Desktop\SGH\2 semester\Logistic Regression with SAS\project final\images;

/*Bar Plot of the hincsrca variable */
ods listing gpath="&graphs";
ods graphics /
imagename="hincsrca_barplot"
imagefmt=png;

proc SGPLOT data = ess_01;
vbar hincsrca / datalabel 
categoryorder=respdesc;
xaxis display=(nolabel);
yaxis grid ;
run;
quit;
ods close;

/*Bar Plot of the Target variable */
ods listing gpath="&graphs";
ods graphics /
imagename="source_of_income_barplot"
imagefmt=png;

proc SGPLOT data = ess_02;
vbar y / datalabel 
categoryorder=respdesc;
xaxis display=(nolabel);
yaxis grid ;
run;
quit;
ods close;

/* Categorical predictors;*/

%macro Frequency(Var);
	proc freq data=ess_02;
		tables &Var.*y;
		ods output CrossTabFreqs=pct01;
	run;
	ods listing gpath="&graphs";
	ods graphics /
	imagename="&Var._barplot"
	imagefmt=png;
	proc sgplot data=pct01(where=(^missing(RowPercent)));
		vbar &Var. / group=y groupdisplay=cluster response=RowPercent datalabel categoryorder=respdesc;
	run;
%mend;
%Frequency(gndr);
%Frequency(mnactic);

/* Continuous predictors;*/

%macro Continuous(Var);
	ods listing gpath="&graphs";
	ods graphics /
	imagename="&Var._barplot"
	imagefmt=png;
	proc sgplot data=ess_02; 
	vbar &Var. / group=y;
	run;
%mend;
%Continuous(hincsrca); *target variable;
%Continuous(hhmmb);
%Continuous(eduyrs);
%Continuous(agea);

/*********************** DISTRIBUTION ANALYSIS;

/* Statistical outputs for all varables */
proc univariate data=ess_02 plots;
var gndr mnactic hhmmb eduyrs agea;
histogram;
run;

*/////////////////////////////;
* COLLINEARITY ;
*/////////////////////////////;

*correlation matrix numerical variables;
proc corr data=ess_02;
 var agea hhmmb eduyrs;
run;
*chi-square test categorical variables;
proc freq data=ess_02;
tables gndr*mnactic/ chisq;
run;

*/////////////////////////////;
* MODELLING ;
*/////////////////////////////;


proc logistic data=ess_02 plots(only)=(effect oddsratio roc);
class  gndr (param=ref ref='Male') mnactic (param=ref ref='Employed');
model y (ref='Labour Income') = agea gndr mnactic hhmmb eduyrs / 
link=glogit clodds=pl lackfit rsq ctable;
output out=out predprobs=(i);
ods output Classification=c01;
run;
