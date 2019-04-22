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

#define UseEngineModule 0 // 0 = The plugin sends 1 extra messag after the orginal one, canceling out the effect ( Extra overhead ) | 1 = Uses engine module but edits the orginal message ( Less over overhead )

#if UseEngineModule == 0
new g_MsgNr
#endif

#include <amxmodx>
#include <engine>

public plugin_init()
{
	register_plugin("Concussion blocker","1.1.0","EKS") 
	register_event("Concuss", "event_Concussion", "b") 

	register_cvar("sv_blockconcussion","1")
#if UseEngineModule == 0
	g_MsgNr = get_user_msgid("Concuss")
#endif
}

public event_Concussion(id)
{
	if(!get_cvar_num("sv_blockconcussion"))
		return PLUGIN_CONTINUE
#if UseEngineModule == 0
	message_begin(MSG_ONE,g_MsgNr,{0,0,0},id) 
	write_byte(0) 
	message_end()
#endif
#if UseEngineModule == 1
	set_msg_arg_int(1, get_msg_argtype(1), 0) 
#endif
	return PLUGIN_CONTINUE
}
