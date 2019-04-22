/* Show teammate name
About:
This plugin allows ppl on the same team to see the name of dead team mates, if they press a button while looking at their body

Credits: 
Ops in #AMXmod @ Quakenet for alot of help ( + AssKicR & CheesyPeteza ) 

Forum Topic: http://www.amxmodx.org/forums/viewtopic.php?t=4320

Usage: 
bind X amx_checkbody

Changelog:
  1.1.0
 	- Added: Its now ALOT simpler to "hit" the body as it allos you to miss some.
 	- Added: If alot of bodys are on 1 possion, you get all their names
 	- Added: Option to allow the plugin to automaticly display the name of dead players
 	- Chagned: Plugin no longer requires the engine module
  	- Changed: Plugin should be more robust now. ( Fixed possible index out of bounds erros )
 	- Changed: How far you could be from the body ( Tweaked should be better now )
 	
  1.0.0
 	- First release version

*/ 

#include <amxmodx>
#define MAXPLAYERS 32				// The maxplayers on your server

#define MAX_DISTANCEFROMBODY 60		// How far away from the body a user can be checked from
#define MAX_DISTACE 20				// This is how much the user can "miss" from the orignal death point

#define AutoCheck 1


new g_DeadOrigin1[MAXPLAYERS/2+2][3]
new g_DeadName1[MAXPLAYERS/2+2][32]

new g_DeadOrigin2[MAXPLAYERS/2+2][3]
new g_DeadName2[MAXPLAYERS/2+2][32]

#if AutoCheck == 1
new g_Maxplayers
new AimOrigin[3],UserOrigin[3],DeadNames[32]
#endif

public plugin_init()
{
	register_plugin("Show teammate name","1.1.0","EKS") 
	register_event("DeathMsg","event_death","b");

	register_event("TeamInfo","event_ResetArray","a");
	register_clcmd("amx_checkbody","CheckBody",0,"- Check the body of teammates")
#if AutoCheck == 1
	set_task(2.0,"Task_CheckIfLookingAtBody",128,_,_,"b")
	g_Maxplayers = get_maxplayers()
#endif
}

#if AutoCheck == 1
public Task_CheckIfLookingAtBody()
{
	if(!g_DeadOrigin1[0][0])
		return PLUGIN_HANDLED
		
	for(new i=1;i<=g_Maxplayers;i++) if(is_user_connected(i))	CheckBody(i)
	return PLUGIN_CONTINUE
}
#endif


public event_death()
{
	new id = read_data(2);

	new team = get_team_int(id)
   	new Origin[3]
	
   	if(!team)	// If the user has no team, no point in saving where he died ( Your gonna get index out of bounds anyways )
		return PLUGIN_HANDLED
   	
   	get_user_origin(id,Origin,0)
	
	if(team == 1)
	{
		g_DeadOrigin1[0][0]++		// This increases the count of players bodeyes on the spesfic team thats remembered
		g_DeadOrigin1[g_DeadOrigin1[0][0]][0] = Origin[0]
		g_DeadOrigin1[g_DeadOrigin1[0][0]][1] = Origin[1]
		g_DeadOrigin1[g_DeadOrigin1[0][0]][2] = Origin[2]
		get_user_name(id,g_DeadName1[g_DeadOrigin1[0][0]],31)
	}
	else if(team == 2)
	{
		g_DeadOrigin1[0][0]++		// This increases the count of players bodeyes on the spesfic team thats remembered
		g_DeadOrigin2[g_DeadOrigin1[0][0]][0] = Origin[0]
		g_DeadOrigin2[g_DeadOrigin1[0][0]][1] = Origin[1]
		g_DeadOrigin2[g_DeadOrigin1[0][0]][2] = Origin[2]
		get_user_name(id,g_DeadName2[g_DeadOrigin1[0][0]],31)
	}
	return PLUGIN_CONTINUE
}

public CheckBody(id)
{
	new team = get_team_int(id)

	if(!g_DeadOrigin1[0][0] || !team || !is_user_alive(id))
		return PLUGIN_HANDLED
#if AutoCheck == 0
	new AimOrigin[3],UserOrigin[3],DeadNames[32]
#else
	setc(DeadNames,31,0)
#endif
	get_user_origin(id,UserOrigin,0)
	get_user_origin(id,AimOrigin,3)
	
	if(team == 1)
	{
		for(new i=1;i<=g_DeadOrigin1[0][0];i++) 
		{
			if (get_distance(UserOrigin,g_DeadOrigin1[i]) <= MAX_DISTANCEFROMBODY && get_distance(AimOrigin,g_DeadOrigin1[i]) <= 200) //  
			{
				format(DeadNames,31,"%s %s",DeadNames,g_DeadName1[i])
			}
		}
	}
	else if(team == 2)
	{
		for(new i=1;i<=g_DeadOrigin1[0][0];i++) 
		{
			if (get_distance(UserOrigin,g_DeadOrigin2[i]) <= MAX_DISTANCEFROMBODY && get_distance(AimOrigin,g_DeadOrigin2[i]) <= MAX_DISTACE) //  
			{
				format(DeadNames,31,"%s %s",DeadNames,g_DeadName2[i])
			}
		}
	}
	if(DeadNames[0]) client_print(id,print_center,"Its %s laying dead there",DeadNames)
	return PLUGIN_CONTINUE
}
public event_ResetArray()
{
	g_DeadOrigin1[0][0] = 0
	//client_print(0,3,"[AMX] A new round has started")
}
stock get_team_int(id)
{
	new TeamInt
	new TeamString[32]
	get_user_team(id,TeamString,31)
	if(equali(TeamString,"Nato"))
		TeamInt = 1
	if(equali(TeamString,"Tango"))
		TeamInt = 2
	return TeamInt
}