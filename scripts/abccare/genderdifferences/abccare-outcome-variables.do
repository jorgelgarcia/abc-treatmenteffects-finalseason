// macros
global projects		: env projects

global scripts    			= "$projects/abccare-cba/scripts/"
global output      			= "$projects/abccare-cba/output/"

// variables
cd $scripts/abccare/genderdifferences
include abccare-outcomes

global iq	`iq'

global ach	`ach'

global parenting	`parenting'

global se	`se'

global ed	`ed'

global emp `emp'

global parent	`parent'	

global health	`health'

global crime	`crime'

global categories iq ach parenting se ed emp parent health crime
