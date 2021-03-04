
/******************************/
/*     PARTIE I : SAS SQL      /
/******************************/

/**************/
/* Question 1 */
/**************/

/* Création d'une macro fonction permettant d'importer les différentes tables.*/

libname projet "C:\Users\SAS\Projet";

%macro importer_data(tab_name, file_name, add_date, variab1, variab2, variab3, variab4, variab5, variab6, variab7, variab8, variab9, variab10, variab11, variab12, variab13, variab14, variab15, variab16 );  

	data projet.&tab_name;
		infile "C:\SAS\Projet\Fichiers de données\&file_name"
			 dlm = ";"
	         firstobs=2
	         DSD;

 
     	input
	         &variab1 
	         &variab2 
	         &variab3 
	         &variab4 
			 &variab5 
			 &variab6
			 &variab7
			 &variab8
			 &variab9
			 &variab10
			 &variab11
			 &variab12
			 &variab13
			 &variab14
			 &variab15
			 &variab16

     ;
 	run;

	/* Certaines tables contiennent des dates qui doivent être formatées. Ainsi, nous posons une condition dans la fonction,
	celle-ci peut être validée ou non par l'usagé, en fonction de la présence d'une variable "date" dans les données. */

%IF &add_date = "yes" %THEN 
%do;

	data projet.&tab_name;

		
		set projet.&tab_name;

		 date = input(put(date,10.), yymmdd10.);


		 format date yymmdd10. ;
 
run;

%end;


%mend;

/* Option yearcutoff = 1900 prend 1900 comme année de référence lorsque l'on rencontre une valeur annuelle à deux chiffres,  
ce qui nous permet une cohérence dans de futurs résultats.
 Sans cette commande, nous obtenons des âges négatifs. */

option yearcutoff = 1900;

%importer_data(account,account.txt, "yes", account_id, district_id, frequency :$30. , date);
%importer_data(card1,card.txt, "no", card_id, disp_id, type $, issued :$30.) ;
%importer_data(client1,client.txt, "no", client_id, birth_number, district_id);
%importer_data(disp,disp.txt, "no", disp_id, client_id, account_id, type :$30.);
%importer_data(district,district.txt, "no", district_id, district_name :$30., region :$30., A4, A5, A6, A8, A9, A10, A11, A12, A13, A14, A15, A16);
%importer_data(loan,loan.txt, "yes", loan_id, account_id, date, amount, duration, payments, status $);
%importer_data(order,order.txt, "no", order_id, account_id, bank_to $, account_to, amount, k_symbol $);
%importer_data(trans,trans.txt, "yes", trans_id, account_id, date, type $, operation $, amount, balance, k_symbol $, bank $, account);

/* La table Client contient une spécialité : la colonne "birth_corr" contient l'information du sexe de l'individu. 
En effet, si l'individu est une femme, alors birth_corr = birth_number - 5000. */

data projet.client;
	set projet.client1;
	
  	birth_corr = input(put(birth_number,10.), yymmdd10.);
  	format birth_corr yymmdd10. ;
	if (birth_corr = .) then sex = "F" ; else sex = "H";
	if (sex = "F") then birth_corr = input(put(birth_number - 5000, 10.), yymmdd10.);

 
run;

/* Création d'une variable permettant de recoder la date */

data projet.card;

	set projet.card1;
  	issued_corr = input(issued,ANYDTDTE19.);
  	format issued_corr yymmdd10. ;
	
run;

/* Nous supprimons les tables superflues */

proc datasets library = projet ;
    delete Client1 Card1;
run;

/**************/
/* Question 3 */
/**************/

/* Nombre de clients par sexe en fonction du district */

proc sql ;

	select district_id label = "Identifiant district", 
		   sex label = "Sexe",
		   count(distinct client_id) as nb_client label = "Nombre de clients"
	from projet.client
	group by district_id, sex
	order by district_id asc
	;

quit ;

/**************/
/* Question 4 */
/**************/

/* Nombre de clients par sexe en fonction du district et de la région */

proc sql ;

	select A.district_id label = "Identifiant du district", 
		   B.district_name label = "Nom du district",
		   B.region lavel = "Region",
		   A.sex label = "Sexe du client", 
		   count(distinct A.client_id) as nb_client label = "Nombre de clients"
			
			
	from projet.client as A, projet.district as B
	where A.district_id = B.district_id
	group by A.district_id, A.sex, B.district_name, B.region
	order by A.district_id asc
	;

quit ;

/**************/
/* Question 5 */
/**************/

/* Nombre de clients homme et femme en fonction du discrict, pour les districts contenant plus de 100 clients */

proc sql ;

	select A.district_id label = "Identifiant district",
		   B.district_name label = "Nom du district",
		   B.region lavel = "Région",
		   count(distinct A.client_id) as nb_client label = "Nombre de clients",
		   sum(A.sex = "H") as clients_hommes,
		   sum(A.sex = "F") as clients_femmes

	from projet.client as A, projet.district as B
	where A.district_id = B.district_id 
	group by A.district_id, B.district_name , B.region
	having nb_client > 100
	;

quit ;

/**************/
/* Question 6 */
/**************/

/* Nombre d'ordres pour les clients possédant au moins un compte, en fonction de l'âge */

proc sql ;

	select  2010 - YEAR(birth_corr) as age label = "Age des clients",
			count(distinct A.client_id) as nb_clients label = "Nombre de clients",
			count( C.account_id) as nb_ordres label = "Nombre d'ordres"	

	from projet.client as A, projet.disp as B , projet.order as C
	where A.client_id = B.client_id and B.account_id = C.account_id  
	group by age
	;

quit ;


/**************/
/* Question 7 */
/**************/

/* Informations concernant les prêts telles que leur nombre ou leur durée en fonction du type de carte */

proc sql ;

	select A.type, 
			count(distinct C.account_id) as nb_account label = "Nombre de comptes avec un emprunt",
			min(C.amount) format=dollar16. as min_amount label = "Montant minimum des emprunts",
			avg(C.amount) format=dollar16. as mean_amount label = "Montant moyen des emprunts",
			max(C.amount) format=dollar16. as max_amount label = "Montant maximum des emprunts",
			min(C.duration) as min_duration label = "Durée minimum des emprunts",
			avg(C.duration) format = 6. as mean_duration label = "Durée minimum des emprunts",
			max(C.duration) as max_duration label = "Durée minimum des emprunts",
			sum(C.status = "A") as nb_A label = "Nombre d'emprunts catégorie A",
			sum(C.status = "B") as nb_B label = "Nombre d'emprunts catégorie B",
			sum(C.status = "C") as nb_C label = "Nombre d'emprunts catégorie C",
			sum(C.status = "D") as nb_D label = "Nombre d'emprunts catégorie D"

	from projet.card as A, projet.disp as B , projet.loan as C
	where A.disp_id = B.disp_id and B.account_id = C.account_id

	group by A.type
	;

quit ;


/**************/
/* Question 8 */
/**************/

/* Nombre de compte ayant bénéficié d'un emprunt par type de carte et catégorie d'emprunt suivi de statistiques
   quantitatives sur le montant et la durée du prêt */

proc sql ;

	select C.status,
			A.type, 
			count(distinct C.account_id) as nb_account label = "Nombre de comptes avec un emprunt",
			avg(C.amount) format=dollar16. as mean_amount label = "Montant moyen des emprunts",
			min(C.amount) format=dollar16. as min_amount label = "Montant minimum des emprunts",
			max(C.amount) format=dollar16. as max_amount label = "Montant maximum des emprunts",
			var(C.amount) as var_amount label = "Variance des montants",
			std(C.amount) as sd_amount label = "Écart moyen des montants",
			avg(C.duration) as mean_duration format = 10. label = "Durée minimum des emprunts",
			min(C.duration) as min_duration label = "Durée minimum des emprunts",
			max(C.duration) as max_duration label = "Durée minimum des emprunts",
			var(C.duration) as var_duration label = "Variance des durées",
			std(C.duration) as sd_duration label = "Écart moyen des durées"

	from projet.card as A, projet.disp as B , projet.loan as C
	where A.disp_id = B.disp_id and B.account_id = C.account_id

	group by  C.status, A.type
	;

quit ;


/**************/
/* Question 9 */
/**************/

/* Création d'une table qui regroupe les informations de chaque clients en y ajoutant leur âge.
   On fusionne les tables clients et disp avec un full join car leur relation est 1-1.
   Afin de garder toutes les lignes de la table clients, on effectue un left join lors de la fusion avec
   la table card 
*/


proc sql;
	create table projet.client_mac (drop =type) as
	select *, 
		   2010 - YEAR(birth_corr) as age, 
           type as type_account   

	from  projet.client Full join projet.disp
	on client.client_id = disp.client_id
	;
quit;

proc sql; 
	create table projet.client_macro (drop = type) as
	select *, 
		   type as type_card 

	from projet.client_mac left join projet.card
	on client_mac.disp_id = card.disp_id
	;
quit;
