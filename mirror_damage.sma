/* Mirror damage
About:
This plugin mirrors damage on friendly fire servers.

Modules required: fun

FAQ)
Q) Can i use this plugin on a lan server?
A) No.

Plugin forum thread: http://www.amxmodx.org/forums/viewtopic.php?p=80463

Credits:
Ops in #AMXmodx @ Quakenet for alot of help ( + AssKicker & CheesyPeteza ) 
*/

#include <amxmodx>
#include <fun>

public plugin_init()
{
   register_plugin("Mirror Damage","1.0.0","EKS")
   register_event("Damage", "Event_Damage", "b", "2!0", "3=0", "4!0" );
   return PLUGIN_CONTINUE
}
public Event_Damage()
{
	new damage = read_data(2);
	new victim = read_data(0);
	new attacker = get_user_attacker(victim)
	if(get_user_team(victim) == get_user_team(attacker) && victim != attacker)
	{
		new HP = get_user_health(attacker) - damage
		if(HP > 0)	set_user_health(attacker,(get_user_health(attacker)-damage))
		else user_kill(attacker)
		
		new VictimN[32]
		get_user_name(victim,VictimN,31)
		client_print(attacker,print_chat,"[AMXX] You team attacked %s and lost %d hp",VictimN,damage)
	}
}