/* I have provided a dataset of 9000 credit card customers. Of these credit card customers some are inactive (i.e., have never used the card) and the rest are active. We have the following variables.

1.	The mode of acquisition (whether they were acquired through direct mail (DM), direct selling (DS), telephone sales (TS) or through internet (NET)) 
2.	Whether they have a Reward card (i.e., a card that gives points for every dollar purchased) 
3.	Whether they have an affinity card and the type of affinity card they have.
4.	The type of card that they were given (that is, whether they have a standard, gold, platinum or quantum card). Note: Quantum > Platinum > Gold > Standard card in terms of credit worthiness.
5.	Note that profit = totfc + 1.6%*TotalTrans (approximately)

	HID -	ID of the account
	Active -	Whether the account is active (=1) or not (=0) 
	Rewards -	whether the customer has a reward card (=1) or not (=0)
	Limit	- credit limit of the customer
	numcard	- number of cards that the customer has from this bank
Mode of acquisition:	
  DM	whether the customer was acquired though direct mail (1=Yes, 0=No)
	DS	whether the customer was acquired though direct selling (1=Yes, 0=No)
	TS	whether the customer was acquired though telephone selling (1=Yes, 0=No)
	NET	whether the customer was acquired though internet (1=Yes, 0=No)
Type of card: 
  Gold	whether the customer has a GOLD card (1=Yes, 0=No)
	Platinum	whether the customer has a PLATINUM card (1=Yes, 0=No)
	Quantum	whether the customer has a QUANTUM card (1=Yes, 0=No)
	Standard	whether the customer has a STANDARD card (1=Yes, 0=No)
	Profit	profit generated by the customer over a 3 year period
	Totaltrans	Total transaction amount (money spent) by the customer over a 3 year period
	Totfc	Total finance charges paid by the customer over a 3 year period
	Age	Age in years
	Dur	Duration: Number of months a customer has stayed with the firm
Types of Affinity cards:	
  sectorA	No affinity – card is not associated with affinity to an organization
	SectorB	Affinity card affiliated with Professional organization (e.g. Am. Medical. Assoc) if a customer has an affinity card of this type value =1 else 0.
	SectorC	Affinity card affiliated with Sports
	SectorD	Affinity card affiliated with Financial institution
	SectorE	Affinity card affiliated with University (e.g. UTD card)
	SectorF	Affinity card affiliated with Commercial (e.g. Macy’s card)
 */

LIBNAME q 'H:\';
DATA cred;
SET q.CC10;
run;

proc print data = cred(obs=10);run;

/*calculating profit*/
data cred; 
set cred;
profit = totfc + 0.016*tottrans;
run; 

proc print data = cred;run;

proc means data = cred;var profit; run;

proc means data = cred;var profit;class rewards; run;

/*plotting profit to check distribution*/
proc sgplot data = cred noautolegend;
  histogram profit;
  density profit /type = normal lineattrs=(color=blue);
run;

/*Adding active variable to the table*/
data cred; 
set cred;
if profit = 0.00 then active = 0; else active =1;
run;  


data cred; 
set cred;
lprofit = log(profit);
run; 

proc print data = cred;run; 

/* Question1 : Run the following Tobit model (Use PROC QLIM)

Model profit = age, totaltrans, rewards, limit, numcard, modes of acquisition, type of card, types of affinity

Write a summary of the results. Focus on important effects, interpretation, model fit etc. */
 
PROC QLIM data=cred;
model profit = age tottrans rewards numcard dm ds ts net standard gold platinum quantum sectorA sectorB sectorC sectorD sectorE sectorF;
endogenous profit ~ censored (lb=0 ub=5000);
Run; 

PROC QLIM data=cred;
model profit = age tottrans rewards numcard dm ds ts net standard gold platinum quantum sectorA sectorB sectorC sectorD sectorE sectorF;
endogenous profit ~ censored (lb=0 ub=3000);
Run;

/*Question2 : Run a selection model (Use PROC QLIM)

Model active = age, rewards, limit, numcard, modes of acquition, type of card, types of affinity

Model profit = age, totaltrans, rewards, limit, numcard, modes of acquition, type of card, types of affinity

Write a summary of the resulSurvival analysis

1.	Delete all customers who are inactive.
2.	Run a proportional hazards model (PROC PHREG)

Duration = age, totaltrans, rewards, limit, numcard, modes of acquition, type of card, types of affinity 

Note that duration is censored if its value is 37 as we have only 37 months of data.
ts. Focus on important effects, interpretation, model fit etc. */

proc qlim data=cred; model active = age rewards limit numcard dm ds ts net standard gold platinum quantum sectorA sectorB sectorC sectorD sectorE sectorF /discrete; 
model lprofit = age tottrans rewards limit numcard dm ds ts net standard gold platinum quantum sectorA sectorB sectorC sectorD sectorE sectorF / select(active=1); 
run; 

/*Question3 : Survival analysis

1.	Delete all customers who are inactive.
2.	Run a proportional hazards model (PROC PHREG)

Duration = age, totaltrans, rewards, limit, numcard, modes of acquition, type of card, types of affinity 

Note that duration is censored if its value is 37 as we have only 37 months of data. */

data cred_active; set cred; 
if active = 1;
run;

proc means data = cred_active; var dur;run;

proc phreg data=cred_active;
model dur= age tottrans rewards limit numcard dm ds ts net standard gold platinum quantum sectorA sectorB sectorC sectorD sectorE sectorF;
run;

/*Question4 : Run a model using PROC LIFEREG with Weibull distribution. 	

Write a summary of the results. Focus on important effects, interpretation, model fit etc. */

PROC LIFEREG data =cred_active outest=a;
model dur= age tottrans rewards limit numcard dm ds ts net standard gold platinum quantum sectorA sectorB sectorC sectorD sectorE sectorF / dist=weibull;
output out=b xbeta=lp;
run;

/*Question5 : Use PROC LIFETEST to test whether survivor function of affinity groups are significantly different from that of non-affinity groups.
What do you conclude? */

proc lifetest data=cred plots=(s) graphics outsurv=a;
time dur*active(0);
strata sectorA;
symbol1 v=none color=black line=1;
symbol2 v=none color=black line=2;
run;




