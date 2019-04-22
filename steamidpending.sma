/* Anti STEAM_ID_PENDING
About:
This plugin automaticly kicks players that have STEAM_ID_PENDING to long ( default time is 20 sec after their fully connected )

Plugin forum thread: http://www.amxmodx.org/forums/viewtopic.php?p=94121

Credits:
Ops in #AMXmodx @ Quakenet for alot of help ( + AssKicR  & CheesyPeteza ) 
Gonzo for idea of plugin
*/
#include <amxmodx>
#include <engine>

#define TIME_BEFORE_KICK 20.0
#define MAXPLAYERS 32

#define PLAYER_ATTACK 1			// Player is holding down the attack button
#define PLAYER_ATTACK2 2048		// Player is holdign down the attack2 button

new g_BlockPlayer[MAXPLAYERS+1]

public plugin_init()
{
	register_plugin("Anti STEAM_ID_PENDING", "1.1.0" ,"EKS")
	
	register_clcmd("say","block_gagged") 
	register_clcmd("say_team","block_gagged") 
}


public client_putinserver(id)
{
	new Authid[35]
	get_user_authid(id,Authid,34)
	if(task_exists(id))
		remove_task(id)

	if(equal(Authid,"STEAM_ID_PENDING"))
	{
		set_task(TIME_BEFORE_KICK,"Task_CheckAuthId",id,_,_,"a",1)
		g_BlockPlayer[id] = 1
		client_print(id,print_chat,"Welcome to our server, for some reason your steamid has not been authenticaded, and you cannot attack/chat untill it is")
		
		new Name[32]
		get_user_name(id,Name,31)
		client_print(0,print_chat,"%s is not allowed to speak or attack untill his steamid is authenticated",Name)
	}
}

public Task_CheckAuthId(id)
{
	new Authid[35]
	get_user_authid(id,Authid,34)	
	if(equal(Authid,"STEAM_ID_PENDING"))
	{
		g_BlockPlayer[id] = 0
		new Name[32],IP[40]
		get_user_name(id,Name,31)
		get_user_ip(id,IP,39)
		
		client_print(0,print_chat,"%s was kicked for having STEAM_ID_PENDING",Name)
		log_amx("%s (IP: %s ) was kicked for having STEAM_ID_PENDING",Name,IP)
		server_cmd("kick #%d because of STEAM_ID_PENDING",get_user_userid(id))
	}
}
new g_Flags // we make it here, as its faster.
public client_PreThink(id)
{
	if(g_BlockPlayer[id] == 0)
		return PLUGIN_CONTINUE
		
	g_Flags = entity_get_int(id,EV_INT_flags)
	if(g_Flags & PLAYER_ATTACK || g_Flags & PLAYER_ATTACK2 )
		entity_set_int(id,EV_INT_flags,0)
	return PLUGIN_CONTINUE
}
public block_gagged(id)
{
	if(g_BlockPlayer[id] == 0)
		return PLUGIN_CONTINUE
	
	client_print(id,print_chat,"You cannot speak or attack untill your Steamid is authenticated")
	return PLUGIN_HANDLED
}
