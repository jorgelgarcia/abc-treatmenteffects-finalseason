# delimit ;
global earlyhome		home0y6m home1y6m home2y6m;
global laterhome		home3y6m home4y6m home8y;
global homeabs			home_abspun2y6m home_abspun1y6m home_abspun0y6m
				home_abspun4y6m home_abspun3y6m;
global homephy			home_orgenv2y6m home_orgenv1y6m home_orgenv0y6m 
				home_toys2y6m home_toys1y6m home_toys0y6m
				home_orgenv8y home_phyenv8y home_toys8y;
global homemom			home_minvol2y6m home_minvol1y6m home_minvol0y6m;
global pari			new_pari_auth1y6m new_pari_demo1y6m 
				new_pari_hostl1y6m;
global parenting		earlyhome laterhome homeabs homephy homemom;
global parenting_labels		Early School-age Discipline Environment Warmth;

global iq3			sb2y sb3y mc3y6m;
global iq4			sb4y mc4y6m;
global iq5			sb5y wppsi5y;
global iq6			sb6y wis6y6m;
global iq8			mc7y wis8y;
global cog			iq3 iq4 iq5 iq8;
global cog_labels		3-years 4-years 5-years 8-years;

global mathschool		math6y math7y6m math8y math8y6m math9y math12y ;	
global readschool		read6y read7y6m read8y read8y6m read9y read12y;
global adultach			math21y read21y;
global ach			readschool mathschool adultach;
global ach_labels		Reading Math Adult;

global earlysociab		ibr_sociab0y6m ibr_sociab1y ibr_sociab1y6m;
global earlytask		ibr_task0y6m ibr_task1y ibr_task1y6m;
global schooltask		cbi_ta6y cbi_ta8y;
global schoolsociab		new_cbi_ho6y new_cbi_ho8y;
global ncog			earlysociab earlytask schoolsociab schooltask;
global ncog_labels		Early-sociability Early-task School-sociability School-task;

global varstofactor				$cog $ncog $parenting $ach;
global categories				cog ncog parenting ach;
global categories_labels		IQ Social-emotional Parenting Achievement;

local numcats : word count $categories ;	// number of categories
local numvars : word count $varstofactor ; 	// number of factors
# delimit cr
