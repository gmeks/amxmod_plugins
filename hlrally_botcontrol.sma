/* HLRally Bot control
This plugin auto adds bots to a HLRally server when there is to few human players

Usage:
amx_botautoadd <num>Whats the minimum amount of players that can be on the server. ( If it gets bellow this number a bot is added )
amx_changebotname <1/0> Changes the name of bots to BOT1

Forum topic: http://www.amxmodx.org/forums/viewtopic.php?p=12962

Credits:
Ops in #AMXmod @ Quakenet for alot of help ( + AssKicker & CheesyPeteza )

Changelog
 1.0.1 ( 11.05.2004 )
	- ChangeBotName() no longer public

 1.0.0 ( 11.05.2004 )
	- First public release

*/

#include <amxmodx>

#define WaitUntilAddBots 1.0

new g_BotCount

public plugin_init()
	{
	register_plugin("HLRally Bot control","1.0.0","EKS")
	register_cvar("amx_botautoadd","6")
	register_cvar("amx_changebotname","1")
	set_task(WaitUntilAddBots,"CheckPlayerNumbers")
	}
public client_disconnect(id) 
	{
	if(is_user_bot(id))
		{
		g_BotCount--
		}
	}
public client_connect(id)
	{
	if(is_user_bot(id))
		{
		g_BotCount++
		if(get_cvar_num("amx_changebotname"))
			ChangeBotName(id)
		}
	CheckPlayerNumbers()
	if(g_BotCount == get_playersnum() && !is_user_bot(id))
		set_task(15.0,"EndRace")
	return PLUGIN_HANDLED
	}

ChangeBotName(id)
	{
	new BotName[8]
	format(BotName,7,"BOT%d",g_BotCount)
	set_user_info(id,"name",BotName)
	}
public CheckPlayerNumbers()
	{
	new Players = get_playersnum(1)
	if(Players < get_cvar_num("amx_botautoadd")) // If the server is bellow the max players, add some bots
		{
		server_cmd("addbot")
		return PLUGIN_HANDLED
		}
/*	if(Players > get_cvar_num("amx_botautoadd") && g_BotCount)
		{
		if(get_cvar_num("amx_changebotname"))
			server_cmd("kick BOT%d",g_BotCount)
		if(!get_cvar_num("amx_changebotname"))
			{
			new i = 1
			while(i != 0)
				{
				if(is_user_bot(i))
					{
					new temp[32]
					get_user_name(i,temp,31)
					server_cmd("kick %s",temp)
					i=-1		// Sets to -1 So its 0 when the while check comes.
					}
				i++
				}
			}
		}*/
	return PLUGIN_CONTINUE
	}
public EndRace() server_cmd("race_restart")