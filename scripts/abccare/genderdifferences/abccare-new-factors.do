# delimit ;
global earlyhome		home0y6m home1y6m home2y6m;
global laterhome		home3y6m home4y6m home8y;
global homeabs			home_abspun2y6m home_abspun1y6m home_abspun0y6m
						home_abspun4y6m home_abspun3y6m;
global homephy			home_orgenv2y6m home_orgenv1y6m home_orgenv0y6m 
						home_toys2y6m home_toys1y6m home_toys0y6m
						home_orgenv8y home_phyenv8y home_toys8y;
global homemom			home_minvol2y6m home_minvol1y6m home_minvol0y6m;
global pari				new_pari_auth1y6m new_pari_demo1y6m 
						new_pari_hostl1y6m;
global parenting		earlyhome laterhome homeabs homephy homemom;


global earlyiq			iq2y iq2y6m iq3y iq3y6m iq4y iq4y6m iq5y;
global earlyverbaliq	;
global earlyperfiq		;
global mediq			iq6y iq6y6m iq7y iq8y iq12y;
global medverbaliq		;
global medperfiq		;
global lateiq			iq15y iq21y;
global cog				earlyiq mediq lateiq;

global mathschool		math5y6m math6y math7y6m math8y math8y6m math9y math12y;	
global readschool		read5y6m read6y read7y6m read8y read8y6m read9y read12y;
global knowschool		know5y6m know6y know7y6m know8y know8y6m know9y know12y;
global adultach			math21y read21y;
global ach				readschool mathschool knowschool adultach;

global earlysociab		ibr_sociab0y6m ibr_sociab1y ibr_sociab1y6m;
global earlytask		ibr_task0y6m ibr_task1y ibr_task1y6m;
global schooltask		cbi_ta6y cbi_ta8y;
global schoolsociab		new_cbi_ho6y new_cbi_ho8y;
global ncog				earlysociab earlytask schoolsociab schooltask;

global varstofactor				$cog $ncog $parenting $ach;
global categories				cog ncog parenting ach;

local numcats : word count $categories ;	// number of categories
local numvars : word count $varstofactor ; 	// number of factors
# delimit cr
