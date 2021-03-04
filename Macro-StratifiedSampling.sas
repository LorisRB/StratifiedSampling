
/******************************/
/*   PARTIE II : SAS MACRO     /
/******************************/

/* A - Sondage al�atoire simple (AS) */

/**************/
/* Question 1 */
/**************/

/* Ici, l'usager choisit un pourcentage d'observation � extraire */

%let tab_entree = client_macro;
%let tab_sortie = client_macro1;
%let part_obs = %sysevalf(10);

data projet.&tab_sortie;
	set projet.&tab_entree;
		 alea = ranuni(0);
run;

proc sort data=projet.&tab_sortie out=projet.&tab_sortie;
   by alea ;
run;

/* On r�cup�re le nombre de lignes de la table client_macro pour pouvoir ensuite 
  en retirer le pourcentage souhait� d'observations */

data _null_;
	set projet.&tab_sortie end = last;
	If last then call symput("n_obs", _N_);
run;

data projet.&tab_sortie;
    set projet.&tab_sortie(obs = %sysfunc(round(%sysevalf((&part_obs/100) * &n_obs),1)));
run;

/**************/
/* Question 2 */
/**************/

/* Cr�ation d'une macro fonction permettant de pr�lever un �chantillon al�atoire sur une table de donn�es */

%macro AS(tab_entree, tab_sortie, part_obs);

	data projet.&tab_sortie;
		set projet.&tab_entree;
			 alea = ranuni(0);
	run;

	proc sort data=projet.&tab_sortie out=projet.&tab_sortie;
	   by alea ;
	run;

	data _null_;
		set projet.&tab_sortie end = last;
		If last then call symput("n_obs", _N_);
	run;

	data projet.&tab_sortie;
	    set projet.&tab_sortie(obs = %sysfunc(round(%sysevalf((&part_obs/100) * &n_obs),1)));
	run;

%mend;

%AS(client_macro, client_macro1, 20)


/* B - Sondage al�atoire stratifi� */


/**************/
/* Question 1 */
/**************/

%macro ASTR(lib, tab, var_strat);

	/* Le proc sort permet d'isoler dans un tableau les modalit�s cl�s non dupliqu�es */
	
/*1*/

	proc sort data = &lib..&tab(keep = &var_strat) out = &lib..stratif nodupkeys;
		by &var_strat;
	run;

	data &lib..stratif;
		set &lib..stratif;
		where &var_strat <>"";
	run;

	/* Le data _null_ permet de cr�er des macros variables dans lesquelles sont introduites 
		le nombre de modalit�s et leur valeur */

	data _null_;
		set &lib..stratif end = last;
		call symput(compress("modalite"!!_N_), compress(&var_strat));
		If last then call symput("N_modalite", _N_);
	run;

	/* Le code ci-dessous permet d'afficher un message � l'utilisateur (nombre de modalit�s et 
	valeur des modalit�s */
	
	%put "Il y a &N_modalite modalit�s dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalit� &i est &&&modalite&i";
	%end;


%mend;

%ASTR(projet, client_macro, sex);

/**************/
/* Question 2 */
/**************/

%macro ASTR(lib, tab, var_strat);
		
	proc sort data = &lib..&tab(keep = &var_strat) out = &lib..stratif nodupkeys;
		by &var_strat;
	run;

	data &lib..stratif;
		set &lib..stratif;
		where &var_strat <>"";
	run;

	data _null_;
		set &lib..stratif end = last;
		call symput(compress("modalite"!!_N_), compress(&var_strat));
		If last then call symput("N_modalite", _N_);
	run;

	/* Cette boucle permet de  cr�er, pour chaque modalit�, un tableau ne contenant
	que les informations relatives � cette modalit�s.*/

	%do i=1 %to &N_modalite;

		data &lib..&&&modalite&i;

			set &lib..&tab;
			where compress(&var_strat)="&&&modalite&i";

		run;

	%end;

	%put "Il y a &N_modalite modalit�s dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalit� &i est &&&modalite&i";
	%end;

%mend;

%ASTR(projet, client_macro, sex);

/**************/
/* Question 3 */
/**************/

%macro ASTR(lib, tab, var_strat, pourcent_obs);
		
	proc sort data = &lib..&tab(keep = &var_strat) out = &lib..stratif nodupkeys;
		by &var_strat;
	run;

	data &lib..stratif;
		set &lib..stratif;
		where &var_strat <>"";
	run;

	data _null_;
		set &lib..stratif end = last;
		call symput(compress("modalite"!!_N_), compress(&var_strat));
		If last then call symput("N_modalite", _N_);
	run;

	%do i=1 %to &N_modalite;
		data &lib..&&&modalite&i;
			set &lib..&tab;
			where compress(&var_strat)="&&&modalite&i";
		run;

		/* Ici, nous faisons appel � la macro utilis�e dans la partie A, afin de cr�er une nouvelle
		table repr�sentant l'�chantillon pour la modalit� concern�e*/
		
		%AS(&&&modalite&i, echant&&&modalite&i, &pourcent_obs);

	%end;

	%put "Il y a &N_modalite modalit�s dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalit� &i est &&&modalite&i";
	%end;

%mend;

%ASTR(projet, client_macro, sex, 50);


/**************/
/* Question 4 */
/**************/

%macro ASTR(lib, tab, var_strat, pourcent_obs);
		
	proc sort data = &lib..&tab(keep = &var_strat) out = &lib..stratif nodupkeys;
		by &var_strat;
	run;

	data &lib..stratif;
		set &lib..stratif;
		where &var_strat <>"";
	run;

	data _null_;
		set &lib..stratif end = last;
		call symput(compress("modalite"!!_N_), compress(&var_strat));
		If last then call symput("N_modalite", _N_);
	run;

	%do i=1 %to &N_modalite;
		data &lib..&&&modalite&i;
			set &lib..&tab;
			where compress(&var_strat)="&&&modalite&i";
		run;
		
		%AS(&&&modalite&i, echant&&&modalite&i, &pourcent_obs);
		
	%end;

	/* La commande ci-dessous permet de concatener l'ensemble des �chantillons en une seule table */

	data &lib..echantillon_final;
	  set
		%do i=1 %to &N_modalite ;
		   &lib..echant&&&modalite&i
		%end;
		;
	run;
	
	%put "Il y a &N_modalite modalit�s dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalit� &i est &&&modalite&i";
	%end;


%mend;

%ASTR(projet, client_macro, sex, 50);

%ASTR(projet, client_macro, type_card, 50);

/**************/
/* Question 5 */
/**************/

%macro ASTR(lib, tab, var_strat, format, pourcent_obs);
		
	proc sort data = &lib..&tab(keep = &var_strat) out = &lib..stratif nodupkeys;
		by &var_strat;
	run;
	
	%if &format = "character" %then
		%do;
			data &lib..stratif;
				set &lib..stratif;
				where &var_strat <> "";
			run;
		%end;

	data _null_;
		set &lib..stratif end = last;
		call symput(compress("modalite"!!_N_), compress(&var_strat));
		If last then call symput("N_modalite", _N_);
	run;

	/* C'est au niveau du where que la condition change lorsque la variable stratifi�e est sous
	format num�rique. Ainsi, nous prenons en compte cette diff�rence en rajoutant un IF, qui ex�cute
	un certain code en fonction du format de notre variable stratifi�e*/

	%if &format = "numeric" %then

		%do i=1 %to &N_modalite;

			data &lib..data&&&modalite&i;
				set &lib..&tab;
				where &var_strat=&&&modalite&i;
			run;
			
			%AS(data&&&modalite&i, echant&&&modalite&i, &pourcent_obs);
			
		%end;

	%else

		%do i=1 %to &N_modalite;
			data &lib..&&&modalite&i;
				set &lib..&tab;
				where compress(&var_strat)="&&&modalite&i";
			run;
			
			%AS(&&&modalite&i, echant&&&modalite&i, &pourcent_obs);
			
		%end;
			
	data &lib..echantillon_final;
	  set
		%do i=1 %to &N_modalite ;
		   &lib..echant&&&modalite&i
		%end;
		;
	run;
	
	%put "Il y a &N_modalite modalit�s dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalit� &i est &&&modalite&i";
	%end;


%mend;


%ASTR(projet, client_macro, sex, "character", 50);

%ASTR(projet, client_macro, district_id, "numeric", 50);


/**************/
/* Question 6 */
/**************/

%macro ASTR(lib, tab, var_strat, format, pourcent_obs);
		
	proc sort data = &lib..&tab(keep = &var_strat) out = &lib..stratif nodupkeys;
		by &var_strat;
	run;

	%if &format = "character" %then
		%do;
			data &lib..stratif;
				set &lib..stratif;
				where &var_strat <> "";
			run;
		%end;

	%global N_modalite;

	data _null_;
		set &lib..stratif end = last;
		call symput(compress("modalite"!!_N_), compress(&var_strat));
		If last then call symput("N_modalite", _N_);
	run;

	/* Dans la boucle de cr�ation des �chantillons, nous cr�ons, � chaque it�ration, une macro-variable 
	prenant la valeur du nombre d'observations dans chaque �chantillon.*/
	
	%if &format = "numeric" %then

		%do i=1 %to &N_modalite;

			data &lib..data&&&modalite&i;
				set &lib..&tab;
				where &var_strat=&&&modalite&i;
			run;
			
			%AS(data&&&modalite&i, echant&&&modalite&i, &pourcent_obs);

			%global taille_sample&i;

			data _null_;
				set &lib..echant&&&modalite&i end = last;
				If last then call symput(compress("taille_sample"!!&i), _N_);
			run;
			
		%end;

	%else

		%do i=1 %to &N_modalite;
			data &lib..&&&modalite&i;
				set &lib..&tab;
				where compress(&var_strat)="&&&modalite&i";
			run;
			
			%AS(&&&modalite&i, echant&&&modalite&i, &pourcent_obs);

			%global taille_sample&i;

			data _null_;
				set &lib..echant&&&modalite&i end = last;
				If last then call symput(compress("taille_sample"!!&i), _N_);
			run;
			
		%end;

	data &lib..echantillon_final;
	  set
		%do i=1 %to &N_modalite ;
		   &lib..echant&&&modalite&i
		%end;
		;
	run;
	
	%global taille_final;

	data _null_;
		set &lib..echantillon_final end = last;
		If last then call symput("taille_final", _N_);
	run;

	%put "Il y a &N_modalite modalit�s dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalit� &i est &&&modalite&i";
	%end;

	/* Le code ci-dessous permet d'afficher le nombre d'observations pour chaque �chantillon et pour la 
	table finale.*/

	%do i=1 %to &N_modalite ;
		   %put "Le nombre d'observations de l'�chantillon &&&modalite&i est de &&&taille_sample&i";
	%end;

	%put "Le nombre d'observations de l'�chantillon total est de &taille_final";

	%put &modalite1;

%mend;

%ASTR(projet, client_macro, sex, "character", 10);

%ASTR(projet, client_macro, district_id, "numeric", 50);
