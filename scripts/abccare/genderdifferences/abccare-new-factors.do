# delimit ;
global hometot			home0y6m home1y6m home2y6m home8y;
global homeabs			home_abspun2y6m home_abspun1y6m home_abspun0y6m
						home_abspun4y6m home_abspun3y6m;
global homeenv			home_orgenv2y6m home_orgenv1y6m home_orgenv0y6m 
						home_toys2y6m home_toys1y6m home_toys0y6m
						home_orgenv8y home_phyenv8y home_toys8y;
global homemom			home_minvol2y6m home_minvol1y6m home_minvol0y6m
						home_affect2y6m home_affect1y6m home_affect0y6m;
global homevar			home_oppvar2y6m home_oppvar1y6m home_oppvar0y6m;
global latehome			home_leng8y home_absrst8y home_orgenv8y home_phyenv8y home_toys8y
						home_oppvar8y home_devstm8y home_emotin8y home_indep8y home8y;
global pari				new_pari_auth0y6m new_pari_demo0y6m new_pari_hostl0y6m
						new_pari_auth1y6m new_pari_demo1y6m new_pari_hostl1y6m;
global parenting		hometot homeabs homeenv homemom homevar latehome pari;


global earlyiq			iq2y iq2y6m iq3y iq3y6m iq4y iq4y6m iq5y;
global earlyverbaliq	vrb2y vrb3y6m vrb4y vrb4y6m;
global earlyperfiq		prf2y prf3y6m prf4y prf4y6m;
global mediq			iq6y iq6y6m iq7y iq8y iq12y;
global medverbaliq		vrb8y vrb12y vrb15y;
global medperfiq		prf8y prf12y prf15y;
global lateiq			iq15y iq21y;
global cog				earlyiq earlyverbaliq earlyperfiq mediq medverbaliq medperfiq lateiq;

global mathschool		math5y6m math6y math7y6m math8y math8y6m math9y math12y;	
global readschool		read5y6m read6y read7y6m read8y read8y6m read9y read12y;
global knowschool		know5y6m know6y know7y6m know8y know8y6m know9y know12y;
global adultach			math21y read21y;
global ach				readschool mathschool knowschool adultach;

global earlysociab		ibr_sociab0y6m ibr_sociab1y ibr_sociab1y6m;
global earlytask		ibr_task0y6m ibr_task1y ibr_task1y6m;
global earlyatt			new_kr_dst2y kr_att2y;
global earlyconf		new_kr_withd2y kr_conf2y;
global schooltask		cbi_ta6y cbi_ta8y cbi_ho12y;
global schoolsociab		new_cbi_ho6y new_cbi_ho8y new_cbi_ho12y;
global schoolhostile	new_wlkr_act8y new_wlkr_withd8y new_wlkr_dst8y new_wlkr_peer8y;
global ncog				earlysociab earlytask earlyatt earlyconf schooltask schoolsociab schoolhostile;

global varstofactor				$cog $ncog $parenting $ach;
global categories				cog ncog parenting ach;

local numcats : word count $categories ;	// number of categories
local numvars : word count $varstofactor ; 	// number of factors
# delimit cr
