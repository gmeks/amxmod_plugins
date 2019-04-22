/* Reset Control
This plugin allows the admin on the server to control weather or not players should be able to reset there car while driving or not. It can also control how many times
during 1 race a player is allowed reset ( controled by the amx_maxresets cvar )

Credits:
OPS in #AMXmod @ Quaknet for alot of help

Changelog
 0.9.0
	- First release
*/

#include <amxmodx>
#include <engine>

new g_RestCount[33]
new g_MaxResets

public plugin_init()
	{
	register_plugin("Reset control","0.9.0","EKS")
	register_cvar("amx_maxresets","2")

	g_MaxResets = get_cvar_num("amx_maxresets")
	register_event("RaceEnd","Echo_ResetResets","a")
	}

public client_kill(id)
	{
	if(g_MaxResets == 0)
		{
		client_print(id,3,"This server does not allow you to reset your car")
		return PLUGIN_HANDLED
		}
	if(g_RestCount[id] >= g_MaxResets)
		{
		client_print(id,3,"You have used all your car resets (%d)",g_MaxResets)
		return PLUGIN_HANDLED
		}
	g_RestCount[id]++
	client_print(id,3,"You have used %d of %d resets this race",g_RestCount[id],g_MaxResets)
	
	return PLUGIN_CONTINUE
	}

public Echo_ResetResets()
	{
	for (new i=1;i<=get_maxplayers();i++)
		{
		g_RestCount[i]=0
		}
	}
