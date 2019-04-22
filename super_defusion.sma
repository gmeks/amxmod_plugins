/*
Super Defusion! v1.0.0
Copyleft jghg 2003
http://www.amxmodx.org/forums/viewtopic.php?p=128557

VERSIONS
========
0.1			First version
0.1.1			Minor tweak
1.0.0
	- Added: now logs admin action in amxmodx logs
	- Changed: Plugin converted to Amxmodx
	- Changed: Works with Steam now ( Instead of chaning the names of the spawn entity, it changes the origin/angel )

Super Defusion!
===============
Spawn points for CT and T team are switched on all de maps.
Time for mp_c4timer is set to maximum, 90 seconds.
Terrorists: Plant the bomb quickly, and guard it!
Counter-terrorists: RUUUUUUUUUUUUUUUN!!!!!!!!!!

USAGE
=====
amx_superdefusion
- Command admin uses to enable/disable Super Defusion! on
defusion type maps. Does not work on other maps, naturally.

INSTALLATION
============
1. Compile sma to super_de.amx
2. Move super_de.amxx into amxmodx/plugins
3. Add a line at the end of amxmodx/plugins/plugins.ini to say:
   super_de.amx
4. Done

	  - Johnny got his gun
*/

#include <amxmodx>
#include <amxmisc>
#include <engine>

#define TEAM_T 1
#define TEAM_CT 2

#define SUPERDEC4TIMER 90
#define HUDCHANNEL 2
#define MAXSPAWNPOINTS 64			// The maximum number of spawnpoints the plugin supports


// Global vars below
new bool:gb_IsSuperDeActive = false		// Is true, if the super defuse mode is active
new g_DefaultC4Timer		// Contains the default mp_c4timer value, when super mode is active
// Global vars above

new g_MaxEnts
new g_MaxPlayers

public plugin_init() {
	register_plugin("Super Defusion!","1.0.0","jghg")

	// Make sure this is a de type map, by looking for bomb targets.
	// It seems to exist two different target classnames...
	if (find_ent_by_class(0,"info_bomb_target") < 1 && find_ent_by_class(0,"func_bomb_target") < 1) 
	{
		pause("a")
		return
	}
	else
	{
		g_MaxEnts = get_global_int(GL_maxEntities)
		g_MaxPlayers = get_maxplayers()
		register_concmd("amx_superdefusion","Admin_Toggle",ADMIN_CFG,"- toggles map to be Super Defusion!")
	}
}

public Admin_Toggle(id,level,cid) 
{		// The function called when a admin uses the toggel command
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_CONTINUE
		
	new Name[32],Authid[35]
	get_user_name(id,Name,31)
	get_user_authid(id,Authid,34)
	if(SwitchTeams() == 0)
	{
		client_print(0,print_chat,"There was a failure in changing the spawn points, check the amxmodx logs for details")
		return PLUGIN_HANDLED
	}
		
	if (!gb_IsSuperDeActive) {
		gb_IsSuperDeActive = true
		
		g_DefaultC4Timer = get_cvar_num("mp_c4timer")
		set_cvar_num("mp_c4timer",SUPERDEC4TIMER)
	
		client_print(id,print_console,"Super Defusion! is activated for next round!^nC4 timer set to %d seconds!",SUPERDEC4TIMER)
		console_print(0,"Super Defusion! is activated for next round!^nC4 timer set to %d seconds!",SUPERDEC4TIMER)
		set_hudmessage(0, 100, 0, -1.0, 0.65, 2, 0.02, 10.0, 0.01, 0.1, HUDCHANNEL)
		show_hudmessage(0,"Super Defusion! is activated for next round!^nC4 timer set to %d seconds!",SUPERDEC4TIMER)
		log_amx("%s<%s> activated Super Defuse",Name,Authid)
	} else {
		gb_IsSuperDeActive = false
		
		set_cvar_num("mp_c4timer",g_DefaultC4Timer)
	
		client_print(id,print_console,"Disabling Super Defusion!...")
		console_print(0,"Disabling Super Defusion!...")
		set_hudmessage(0, 100, 0, -1.0, 0.65, 2, 0.02, 10.0, 0.01, 0.1, HUDCHANNEL)
		show_hudmessage(0,"Disabling Super Defusion!...")
		log_amx("%s<%s> deactivated Super Defuse",Name,Authid)
	}

	return PLUGIN_HANDLED
}

stock SwitchTeams()		// This function turns the team spawn points around, and switches the owner of the buyzone
{
	new EntNums[MAXSPAWNPOINTS+1]
	new EntCount = 0
	new Float:TSpawnsO[MAXSPAWNPOINTS/2][3]
	new Float:CTSpawnsO[MAXSPAWNPOINTS/2][3]
	new Float:TSpawnsA[MAXSPAWNPOINTS/2][3]
	new Float:CTSpawnsA[MAXSPAWNPOINTS/2][3]
	new TSpawnCount = 0
	new CTSpawnCount = 0
	
	new ClassName[32]
	for(new i=g_MaxPlayers+1;i<g_MaxEnts;i++) if(is_valid_ent(i) && entity_get_edict(i, EV_ENT_owner) == 0)
	{
		new bool:HasChanged = false
		entity_get_string(i,EV_SZ_classname,ClassName,31)
		
		if(equal(ClassName,"func_buyzone"))
		{
			new Team = entity_get_int(i,EV_INT_team)
			if(Team == TEAM_CT)
				entity_set_int(i,EV_INT_team,TEAM_T)
			else if(Team == TEAM_T)
				entity_set_int(i,EV_INT_team,TEAM_CT)
		}
		else if(equal(ClassName,"info_player_deathmatch")) // Means the team is Terror
		{
			EntNums[EntCount] = i
			EntCount++
			
			entity_get_vector(i,EV_VEC_origin,TSpawnsO[TSpawnCount])
			entity_get_vector(i,EV_VEC_angles,TSpawnsA[TSpawnCount])
			TSpawnCount++
			HasChanged = true
		}
		else if(equal(ClassName,"info_player_start"))		// Means we are talking Counter strike
		{
			EntNums[EntCount] = i
			EntCount++
			
			entity_get_vector(i,EV_VEC_origin,CTSpawnsO[CTSpawnCount])
			entity_get_vector(i,EV_VEC_angles,CTSpawnsA[CTSpawnCount])
			CTSpawnCount++
			HasChanged = true
		}
		if(HasChanged == true && ( EntCount == MAXSPAWNPOINTS || TSpawnCount == MAXSPAWNPOINTS / 2 || CTSpawnCount == MAXSPAWNPOINTS / 2) )
		{
			log_amx("This map has to many spawnpoints, Try increasing the value of: #define MAXSPAWNPOINTS in the .sma file, and recompile the plugin.")
			return 0
		}				
	}
	new CTSpawnsUsed = 0
	new TSpawnsUsed = 0
	
	for(new i=0;i<=EntCount;i++) if(EntNums[i] != 0)
	{
		entity_get_string(EntNums[i],EV_SZ_classname,ClassName,31)
		
		if(equal(ClassName,"info_player_deathmatch") && CTSpawnsUsed <= TSpawnCount ) // Means the team is Terror
		{
			entity_set_vector(EntNums[i],EV_VEC_origin,CTSpawnsO[CTSpawnsUsed])
			entity_set_vector(EntNums[i],EV_VEC_angles,CTSpawnsA[CTSpawnsUsed])
			CTSpawnsUsed++			
		}
		else if(equal(ClassName,"info_player_start") && TSpawnsUsed <= CTSpawnCount)		// Means we are talking Counter strike
		{
			entity_set_vector(EntNums[i],EV_VEC_origin,TSpawnsO[TSpawnsUsed])
			entity_set_vector(EntNums[i],EV_VEC_angles,TSpawnsA[TSpawnsUsed])
			TSpawnsUsed++
		}
	}
	return 1
}