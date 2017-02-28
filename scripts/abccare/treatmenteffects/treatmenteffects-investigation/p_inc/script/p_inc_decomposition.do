/* ---------------------------------------------------------------------------- *
* Decomposing the Means of Parental Income 
* Author: 	Jessica Yu Kyung Koh
* Date:		02/28/2017
* Note:		This do files investigates the jumps in parental income mean of treated
			and control subjects, respectively. Specifically, we want to find out if
			the jump in the means is due to (i) increased labor income or (ii) increased
			labor force participation. 
* ---------------------------------------------------------------------------- */

* Set macro
global klmshare : env klmshare
global abc_data = "${klmshare}/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"

local incvars 		p_inc3y6m p_inc12y p_inc21 
local workvars		m_work3y6m m_work12y m_works21y


* Bring in data
cd $abc_data
use append-abccare_iv, clear

drop if RV == 1 & R == 0


* ------- *
* Treated *
* ------- *
* Summarizing the mean for whole treated subjects
summ `incvars'  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 1 

* Summarizing the mean for treated subjects whose mother works
di "Treated, mom works, p_inc3y6m"
summ p_inc3y6m  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 1 & m_work3y6m == 1

di "Treated, mom works, p_inc12y"
summ p_inc12y  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 1 & m_work12y == 1

di "Treated, mom works, p_inc21y"
summ p_inc21y  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 1 & m_work21y == 1

* Summarizing probability of working for treated
di "Probability working, 3y6m"
summ m_work3y6m  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 1

di "Probability working, 12y"
summ m_work12y  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 1

di "Probability working, 21y"
summ m_work21y  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 1

* Summarizing the mean for treated subjects whose mother does not work
di "Treated, mom works, p_inc3y6m"
summ p_inc3y6m  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 1 & m_work3y6m == 0

di "Treated, mom works, p_inc12y"
summ p_inc12y  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 1 & m_work12y == 0

di "Treated, mom works, p_inc21y"
summ p_inc21y  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 1 & m_work21y == 0















* ------- *
* Control *
* ------- *
* Summarizing the mean for whole control subjects
summ `incvars'  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 0 

* Summarizing the mean for control subjects whose mother works
di " control, mom works, p_inc3y6m"
summ p_inc3y6m  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 0 & m_work3y6m == 1

di " control, mom works, p_inc12y"
summ p_inc12y  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 0 & m_work12y == 1

di " control, mom works, p_inc21y"
summ p_inc21y  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 0 & m_work21y == 1

* Summarizing probability of working for control
di "Probability working, 3y6m"
summ m_work3y6m  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 0

di "Probability working, 12y"
summ m_work12y  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 0

di "Probability working, 21y"
summ m_work21y  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 0

* Summarizing the mean for control subjects whose mother does not work
di " control, mom works, p_inc3y6m"
summ p_inc3y6m  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 0 & m_work3y6m == 0

di " control, mom works, p_inc12y"
summ p_inc12y  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 0 & m_work12y == 0

di " control, mom works, p_inc21y"
summ p_inc21y  if apgar1 < . & apgar5 < . & hrabc_index < . & R == 0 & m_work21y == 0

