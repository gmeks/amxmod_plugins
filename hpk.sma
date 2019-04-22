/* Yet another High Ping Kicker
About:
This plugin kick players that have to high a ping, or too low a cl_updaterate/rate setting. It also has a 
option to adds X amount to the max ping when the clock is goes over 24.
The plugin can also automaticly update client settings ( Showing a menu to the client ) or just update his setinfo field ( this will cause the settings lost once he closes HL1)

Forum Thread: http://www.amxmodx.org/forums/viewtopic.php?t=7865

Credits:
Ops in #AMXmod @ Quakenet for alot of help ( + AssKicR  & CheesyPeteza ) 

Install:
Install the plugin like any other
Put these into your amxx.cfg with the correct vaules
amx_maxping 125
amx_minrate 10000
amx_minupdaterate 40
amx_maxping_add 50

Changelog:
 1.1.4
 	- Added: Define UseSetInfo so you can change if you want to use client_cmd() instead of setinfo
 
 1.1.2
 	- Fixed: Typo in log_amx()
	- Added: #define To disable cl_updaterate on the client.
	- Added: Automaticly changeing client settings without chaning the cvar ( Just changeing the setinfo field instead )
	- Added: Also checks the clients Rate setting ( cvar: amx_minrate )
	- Added: amx_minupdaterate The lowest accetable client updaterate
	
 1.1.1
 	- Fixed: Task not being removed when player left.
 1.1.0
 	- Added: Shows a menu to ppl with too low a cl_updaterate settings
 	 
 1.0.0
 	- First released version
*/

#include <amxmodx>

#define TaskTime 15.0
#define HowManyChecks 10
#define ExtraPing 150		// ExtraPing + g_MaxPing : If a user has a ping above this, his ping Offense counter goes up 5 instead of 1

#define MAXPLAYERS 32
#define CheckUpdateRate 1	// 1 = Uses menu  | 2 = auto changes settings
#define UseSetInfo  1

new g_PingOffence[MAXPLAYERS+1]
new g_CheckPlayer[MAXPLAYERS+1]		// To save the poor cpu having to keep track of the connected players
new g_MaxPing

#if CheckUpdateRate != 0
new g_MinUpdateRate
new g_MinRate
#endif
new g_MaxPlayers

#define PluginVersion "1.1.4"

public plugin_init() 
{
	register_plugin("Yet Another High Ping Kicker",PluginVersion,"EKS")
#if CheckUpdateRate == 1
	register_menucmd(register_menuid("\yToo low cl_updaterate:"),1023,"MenuCheckSelection")
#endif
  	
#if CheckUpdateRate != 0
   	register_cvar("amx_minupdaterate","40")
	register_cvar("amx_minrate","10000")
#endif
	register_cvar("amx_maxping","200")
	register_cvar("amx_maxping_add","50")
	
	register_cvar("yhpk_version",PluginVersion,FCVAR_SERVER)
	set_task(TaskTime,"Task_CheckPlayers",64,_,_,"b")
	return PLUGIN_CONTINUE
}
public plugin_cfg()
{
	g_MaxPlayers = get_maxplayers()
	g_MaxPing = get_cvar_num("amx_maxping")
	
#if CheckUpdateRate != 0
	g_MinUpdateRate = get_cvar_num("amx_minupdaterate")
	g_MinRate = get_cvar_num("amx_minrate")
#endif

	new sTimeH[4] // Contains the hour in a sting
	get_time("%H",sTimeH,3) 
	new TimeH = str_to_num(sTimeH)
	if (TimeH < 14)
	{
		g_MaxPing = g_MaxPing + get_cvar_num("amx_maxping_add")
		server_print("[HPK] Time is %d, added +%d to maxping(%d)",TimeH,get_cvar_num("amx_maxping_add"),g_MaxPing)
	}
	else
		server_print("[HPK] Time is %d, maxping(%d)",TimeH,g_MaxPing)
}
public client_putinserver(id) 
{
	if(is_user_connected(id) && !is_user_bot(id) && !is_user_hltv(id))
		set_task(20.0,"Task_ActivatePingCheck",id,_,_,"a",1)		// Since when the user "just" connected, his ping is high, we dont want to get a false detection
}
public Task_ActivatePingCheck(id) 
{
	g_PingOffence[id] = 0
	g_CheckPlayer[id] = 1
#if CheckUpdateRate != 0	
	client_print(id,print_chat,"[HPK] The max ping is %d, and lowest acceptable cl_updaterate is %d",g_MaxPing,g_MinUpdateRate)
#else
	client_print(id,print_chat,"[HPK] The max ping is %d",g_MaxPing)
#endif
}

public client_disconnect(id) 
{
	g_CheckPlayer[id] = 0
	remove_task(id)
}
public Task_CheckPlayers()
{
	for(new i=1;i<=g_MaxPlayers;i++) if(g_CheckPlayer[i])
		CheckPing(i)
}

stock CheckPing(id)
{
#if CheckUpdateRate != 0
	new TempString[10]
	get_user_info(id,"cl_updaterate",TempString,9)
	new clrate = str_to_num(TempString)
	get_user_info(id,"rate",TempString,9)
	new rate = str_to_num(TempString) 
#endif

	new ping,loss
	get_user_ping(id,ping,loss)

	if(ping > g_MaxPing)
	{
		if(ping >= ExtraPing+g_MaxPing) g_PingOffence[id] = g_PingOffence[id] + 5		// If the user has a ping ExtraPing + g_MaxPing, he gets +5 instead of +1 in his ping offence counter
		else g_PingOffence[id]++
		
		if(g_PingOffence[id] >= HowManyChecks)
		{
			new Name[32],Auth[35]
			get_user_name(id,Name,31)
			get_user_authid(id,Auth,34)
			client_print(0,print_chat,"[HPK] %s was kicked for having a ping above %d",Name,g_MaxPing)
			server_cmd("kick #%d Ping too high",get_user_userid(id))
			log_amx("%s<%s> was kicked for having to high a ping (was %d)",Name,Auth,ping)
			return PLUGIN_CONTINUE
		}
		client_print(id,print_chat,"[HPK] You ping is above %d, either fix your ping or leave",g_MaxPing)
	}
#if CheckUpdateRate == 1
	if(clrate < g_MinUpdateRate || rate < g_MinRate)
	{
		if(g_CheckPlayer[id] == 1 || g_CheckPlayer[id] == 3)
		{
		    ShowMenu(id)
		    
		    if(g_CheckPlayer[id] == 3)
			    g_CheckPlayer[id] = 2
		    else
		    {
			    g_CheckPlayer[id] = 2
		    }
		}
	}
	else if(clrate < g_MinUpdateRate && g_CheckPlayer[id] == 2)
	{
		new Name[32],Auth[35]
		get_user_name(id,Name,31)
		get_user_authid(id,Auth,34)
		client_print(0,print_chat,"[HPK] %s was kicked for having a too low cl_updaterate(%d)/rate(%d)",Name,clrate,rate)
		server_cmd("kick #%d Too low a cl_updaterate",get_user_userid(id))	
		log_amx("%s<%s> was kicked for having too low a cl_updaterate(%d)/rate(%d)",Name,Auth,clrate,rate)
		return PLUGIN_CONTINUE
	}
#endif
#if CheckUpdateRate == 2
	if(clrate < g_MinUpdateRate)
	{
#if UseSetInfo == 1
		format(TempString,9,"%d",g_MinUpdateRate)
		set_user_info(id,"cl_updaterate",TempString)
#else
	        client_cmd(id,"cl_updaterate %d",g_MinUpdateRate)
#endif
		client_print(id,print_chat,"[HPK] Your updaterate was increased to %d",g_MinUpdateRate)
	}
	if(rate < g_MinRate)
	{
#if UseSetInfo == 1
		format(TempString,9,"%d",g_MinRate)
		set_user_info(id,"rate",TempString)
#else
	        client_cmd(id,"rate %d",g_MinRate)
#endif
		client_print(id,print_chat,"[HPK] Your rate was increased to %d",g_MinRate)		
	}
#endif

	//client_print(id,3,"%d had ping: %d(%d) loss %d clrate %d(%d) Rate: %d (%d)",id,ping,g_MaxPing,loss,clrate,g_MinUpdateRate,rate,g_MinRate)
	return PLUGIN_CONTINUE
}

#if CheckUpdateRate == 1
public ShowMenu(id)
{ 
	new szMenuBody[151] 
	new len,keys 
	len = format(szMenuBody,255,"\yToo low cl_updaterate/rate:^n Increase the cl_updaterate/rate or leave the server")
	len += format(szMenuBody[len],150 - len,"^n\w 1. Increase to %d",g_MinUpdateRate) 
	len += format(szMenuBody[len],150 - len,"^n\w 2. Leave server") 


	keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9) 
	show_menu( id, keys, szMenuBody, -1 ) 
	return PLUGIN_CONTINUE 
}
public MenuCheckSelection(id,key) // Called by ShowReadyMenu
{ 
	new Name[32],Auth[35]
	get_user_name(id,Name,31)
	get_user_authid(id,Auth,34)
	
	if(key == 0) 
	{
		client_print(0,print_chat,"[HPK] %s choose to update his cl_updaterate/rate",Name)
		log_amx("%s<%s> choose to update his cl_updaterate/rate",Name,Auth)		
		client_cmd(id,"cl_updaterate %d",g_MinUpdateRate)
		client_cmd(id,"rate %d",g_MinRate)
	}
	else if(key == 1)
	{
		client_print(0,print_chat,"[HPK] %s choose not to update his cl_updaterate/rate",Name)
		server_cmd("kick #%d Too low cl_updaterate/rate",get_user_userid(id))	
		log_amx("%s<%s> choose to NOT update his cl_updaterate/rate",Name,Auth)
	}
	else	// Made a wrong selection
		ShowMenu(id)

	return PLUGIN_CONTINUE
}
#endif