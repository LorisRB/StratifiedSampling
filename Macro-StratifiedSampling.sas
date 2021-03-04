
/******************************/
/*   PARTIE II : SAS MACRO     /
/******************************/

/* A - Sondage aléatoire simple (AS) */

/**************/
/* Question 1 */
/**************/

/* Ici, l'usager choisit un pourcentage d'observation à extraire */

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

/* On récupère le nombre de lignes de la table client_macro pour pouvoir ensuite 
  en retirer le pourcentage souhaité d'observations */

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

/* Création d'une macro fonction permettant de prélever un échantillon aléatoire sur une table de données */

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


/* B - Sondage aléatoire stratifié */


/**************/
/* Question 1 */
/**************/

%macro ASTR(lib, tab, var_strat);

	/* Le proc sort permet d'isoler dans un tableau les modalités clés non dupliquées */
	
/*1*/

	proc sort data = &lib..&tab(keep = &var_strat) out = &lib..stratif nodupkeys;
		by &var_strat;
	run;

	data &lib..stratif;
		set &lib..stratif;
		where &var_strat <>"";
	run;

	/* Le data _null_ permet de créer des macros variables dans lesquelles sont introduites 
		le nombre de modalités et leur valeur */

	data _null_;
		set &lib..stratif end = last;
		call symput(compress("modalite"!!_N_), compress(&var_strat));
		If last then call symput("N_modalite", _N_);
	run;

	/* Le code ci-dessous permet d'afficher un message à l'utilisateur (nombre de modalités et 
	valeur des modalités */
	
	%put "Il y a &N_modalite modalités dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalité &i est &&&modalite&i";
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

	/* Cette boucle permet de  créer, pour chaque modalité, un tableau ne contenant
	que les informations relatives à cette modalités.*/

	%do i=1 %to &N_modalite;

		data &lib..&&&modalite&i;

			set &lib..&tab;
			where compress(&var_strat)="&&&modalite&i";

		run;

	%end;

	%put "Il y a &N_modalite modalités dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalité &i est &&&modalite&i";
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

		/* Ici, nous faisons appel à la macro utilisée dans la partie A, afin de créer une nouvelle
		table représentant l'échantillon pour la modalité concernée*/
		
		%AS(&&&modalite&i, echant&&&modalite&i, &pourcent_obs);

	%end;

	%put "Il y a &N_modalite modalités dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalité &i est &&&modalite&i";
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

	/* La commande ci-dessous permet de concatener l'ensemble des échantillons en une seule table */

	data &lib..echantillon_final;
	  set
		%do i=1 %to &N_modalite ;
		   &lib..echant&&&modalite&i
		%end;
		;
	run;
	
	%put "Il y a &N_modalite modalités dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalité &i est &&&modalite&i";
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

	/* C'est au niveau du where que la condition change lorsque la variable stratifiée est sous
	format numérique. Ainsi, nous prenons en compte cette différence en rajoutant un IF, qui exécute
	un certain code en fonction du format de notre variable stratifiée*/

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
	
	%put "Il y a &N_modalite modalités dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalité &i est &&&modalite&i";
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

	/* Dans la boucle de création des échantillons, nous créons, à chaque itération, une macro-variable 
	prenant la valeur du nombre d'observations dans chaque échantillon.*/
	
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

	%put "Il y a &N_modalite modalités dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalité &i est &&&modalite&i";
	%end;

	/* Le code ci-dessous permet d'afficher le nombre d'observations pour chaque échantillon et pour la 
	table finale.*/

	%do i=1 %to &N_modalite ;
		   %put "Le nombre d'observations de l'échantillon &&&modalite&i est de &&&taille_sample&i";
	%end;

	%put "Le nombre d'observations de l'échantillon total est de &taille_final";

	%put &modalite1;

%mend;

%ASTR(projet, client_macro, sex, "character", 10);

%ASTR(projet, client_macro, district_id, "numeric", 50);
