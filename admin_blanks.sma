/* Admin blanks
About:
This plugin allows admins with kick access to give players blanks for a persiod of time. ( Players firing blanks dont do any dmg ). This plugin will both echo/log admin actions

Usage:
amx_blank <nick or #userid> <time>
amx_blank <nick or #userid>
amx_unblank <nick or #userid>

This plugin requires AMXX Fun module
Forum topic: http://www.amxmodx.org/forums/viewtopic.php?t=807

Credits:
OP`s in #amxmod @ Quakenet, for helping me alot with my endless questions.
Based on idea from the original amx_blank plugin. ( http://djeyl.net/forum/index.php?showtopic=19498 | Freecode )

Changelog: 
 1.0.3 ( 06.07.2004 )
	- Fixed: Fixed possible issue with steamids being to long (Would just be text cut on in logs/text)

 1.0.2 ( 25.04.2004 )
	- Fixed oversight that would allow none admins to use the plugin
 1.0.1
	- Change to log_amx loggin.
	- Now uses AMXX mod include file

 1.0
	- Logs admin actions
	- Admin with immunity can preform actions on himself.
	- Players are blanked for a persiod of time. ( Seconds )
	- No longer posible to blank a entire team.
	- No longer posible to save blanks.
	
*/

#include <amxmodx>
#include <amxmisc>
#include <fun>

new gBlankPlayers[33]		// This arrays has the info if the player is firing blanks or not. (0 = normal, 1= firing blanks)

public plugin_init() { 
	register_plugin("Admin blanks","1.0.3","EKS") 
	register_concmd("amx_blank","BlankPlayer",ADMIN_KICK,"<nick or #userid> <time>") 
	register_concmd("amx_unblank","unBlankPlayer",ADMIN_KICK,"<nick or #userid>") 
	return PLUGIN_CONTINUE 
	} 

public BlankPlayer(id,level,cid) { 
	if(!cmd_access (id,level,cid,2)) return PLUGIN_HANDLED
	new arg[32],AdminName[32],AdminAuth[35],VictimID,VictimName[32],VictimAuth[35]
	new BlankRounds[8] = 0
	read_argv(1,arg,31)  			// Arg contains Targets nick or Userid
	VictimID = cmd_target(id,arg,8)
	if ((get_user_flags(VictimID) & ADMIN_IMMUNITY) && VictimID != id) { return PLUGIN_HANDLED; } // Checks admin immunity, but will execute on if the admin tried to execute on self.
	if (!VictimID) return PLUGIN_HANDLED // Checks if target is anything else then a "human" player

	read_argv(2,BlankRounds,7) 
	if (strlen(BlankRounds) == 0 )
		format(BlankRounds,7,"240")

	new Float:BlankTime = floatstr(BlankRounds)	
	
	get_user_name(id,AdminName,31)
	get_user_name(VictimID,VictimName,31)
	get_user_authid(id,AdminAuth,34)
	get_user_authid(VictimID,VictimAuth,34)

	set_user_hitzones(VictimID, 0, 0) // Code that changes the user can hit.
	gBlankPlayers[id] = 1
	new param[2]
	param[0] = VictimID
	set_task( BlankTime,"unBlankPlayerTask",VictimID*15,param,1) 
   	switch(get_cvar_num("amx_show_activity"))   { 
   		case 2:   client_print(id,print_chat,"ADMIN %s: has gives %s blanks for %s seconds",AdminName,VictimName,BlankRounds) 
   		case 1:   client_print(id,print_chat,"ADMIN: %s has been given blanks for %s seconds",VictimName,BlankRounds) 
  	 	}	
	log_amx("Blank: ^"%s<%s>^" has given blanks to  ^"%s^" <^"%s^">  for %s seconds",AdminName,AdminAuth,VictimName,VictimAuth,BlankRounds)
	return PLUGIN_HANDLED 
	} 


public unBlankPlayerTask(param[]) // Removes gag when the time is passed ( via the task) ( param[0] contains VictimID )
	{ 
	new VictimName[32]
	get_user_name(param[0],VictimName,31)
	gBlankPlayers[param[0]] = 0
	set_user_hitzones(param[0], 0, 255)
	client_print(0,print_chat,"ADMIN: %s now has real bullets",VictimName)
	return PLUGIN_HANDLED 
	} 

public unBlankPlayer(id,level,cid) {  /// Removed gaged player ( done via console command )
	if(!cmd_access (id,level,cid,2)) return PLUGIN_HANDLED
	new arg[32],AdminName[32],VictimID 
	read_argv(1,arg,31)  			// Arg contains Targets/Authid nick
	VictimID = cmd_target(id,arg,8) 	// Finds VictimID based on whats in arg
	get_user_name(id,AdminName,31)		// Gets Admin name
	gBlankPlayers[id] = 0

	set_user_hitzones(VictimID, 0, 255)
	remove_task(VictimID*15)
	switch(get_cvar_num("amx_show_activity"))   { 
   		case 2:   client_print(0,print_chat,"ADMIN %s: gives %s real bullets again",AdminName,arg)
   		case 1:   client_print(0,print_chat,"ADMIN: %s was given real bullets again",arg)
  	 	}
	return PLUGIN_HANDLED
	}

public client_disconnect(id)
	{ 
	if(gBlankPlayers[id]) // Checks if disconnected player is gaged, and removes flags from his id.
		{
		new nick[32],authid[35]
		get_user_name(id,nick,31)
		get_user_authid(id,authid,34)
		gBlankPlayers[id] = 0
		set_user_hitzones(id, 0, 255)
		client_print(0,print_chat,"[AMX]Blanked player disconnected ( %s / %s )",nick,authid)
		}
	return PLUGIN_HANDLED 
	}