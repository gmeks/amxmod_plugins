/* Concussion blocker
This plugin removes the "shaky" effect of concussion grenades.

Usage: 
sv_blockconcussion 1/0 to enable or disable the plugin

Credits: 
Ops in #AMXmod @ Quakenet for alot of help ( + AssKicR & CheesyPeteza ) 

Changelog 
 1.1.0
	- Added: Plugin can now "block" the effect without the engine module ( Thx to mahnsawce )

 1.0.0
	- First Release
*/ 

#include <amxmodx>

new cvar

public plugin_init() {
    register_plugin("Concussion blocker","1.2.0","Ramon&EKS") 
    register_message(get_user_msgid("Concuss"),"event_Concussion")
    cvar = register_cvar("sv_blockconcussion","1")
}

public event_Concussion() {
    if(get_pcvar_num(cvar)) return PLUGIN_HANDLED
    return PLUGIN_CONTINUE
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1044\\ f0\\ fs16 \n\\ par }
*/
