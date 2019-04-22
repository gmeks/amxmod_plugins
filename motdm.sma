/* 
MOTD mangement
The goal of this plugin combin all the MOTD box needs into 1 simple plugin, yet keep it easy to change. It allows: WebBrowsing,Showing rules,Show Player info (CM style) & Internal Adminnews.

Forum topic: http://www.amxmodx.org/forums/viewtopic.php?t=360

FAQ:
Q)Whats the point with the DEFINE SECTION
A)You will be able to disable sections you dont want.

Q)The URL i entered does not show on the client
A)Remember you must be able to browse the page from the client.

Q) How do i change the URL`s if i disable the cvars?
A) If you dont know, dont disable the cvars.

Credits:
Ops in #AMXmod @ Quakenet for alot of help ( + AssKicker & CheesyPeteza )
Loads ripped from: http://amxmod.net/forums/viewtopic.php?t=17812 ( ST4life )
Web browser code from: http://amxmod.net/forums/viewtopic.php?t=22159 ( f117bomb )
Playerinfo code is based from code of JohnnyGotHisGun

Known issues:
Using url`s with spaces in them in ANY of the cvars will mess things up
amx_browse "http://www.db.no" REQUIRES quotes

Changelog
1.4.0
	- Added: amx_addsayhook "helpme" "http://www.myhelppage" Or any other hook you may want allows admins to add the chat hooks they want
1.3.1 ( 12.12.2004 )
	- Changed: Plugin now defaults sets cvars to preview site
	
1.3.0 ( 11.08.2004 )
	- Added: Support for the Geoip module ( Show witch contry ppl are from). Disabled by std (Requires AMXX .20 and above)

1.2.1 ( 06.07.2004 )
	- Fixed: Fixed possible issue with steamids being to long (Would just be text cut on in logs/text)

1.2.0 ( 16.05.2004 )
	- Added: amx_playersinfo now uses proper HTML code witch means it looks alot more clean
	- Added: say /browse <url>
	- Changed: PublicBrowse() function Completly rewriten
	- Changed: Clean code some up
	- Changed: CMD_PublicBrowse() No longers tries to close the client console
	- Removed: g_default_title as its not realy needed
	- Removed: USE_CVARS #define from most of the plugin
	- Fixed: update_cvars() function not working
	- Fixed: Adminnews not working with #define USE_CVARS 0

1.1.0
	- Added: amx_adminnewsurl,amx_publicrulesurl,amx_browserhomeurl to make it easyer to change where the plugin downloads from.
	- Made a DEFINE SECTION, The plugin is now fully custumizable while compiling.

1.0.3
	- Updated to use the amxmodx include file.
	- Removed the cm_lp client cmds

1.0.2
	- Bug that would show everyone as a admin.

1.0.1
	- Fixed typo in: amx_publicrules

1.0.0
	- Now also includes playerinfo ( Playerinfo is a motd box containing info about players on the server)
	- Code cleaned up a bit, simpler to read now.

0.9.1
	- amx_browse no longer registered with concmd
	- Plugin now longer checks for immunity when showing adminnews

0.9.0
	- First release
*/ 

#include <amxmodx> 
// ******************************** DEFINE SECTION ********************************
#define AdminNews 1	// 0 = Disable the Adminnews function | 1 = Enable
#define PublicBrowse 1	// 0 = Disable the Public browse function | 1 = Enable
#define PlayerInfo 1	// 0 = Disable the Player info function  | 1 = Enable
#define PublicRules 1	// 0 = Disable the Player rules function | 1 = Enable

#define USE_HTML 1	// 0 = Disables usage of html code in MOTD boxes |  1 = Uses HTML code.
#define USE_CVARS 1	// 0 = Disables the usage of cvars in regards to the Browser urls & amx_playerinfo | 1 = Uses CVARS
#define GEO_IP 0	// 0 = Disabled the geoip usage with PlayerInfo
// ******************************** DEFINE SECTION END  ********************************
#if GEO_IP == 1
#include <geoip>
#endif

#if USE_CVARS == 1
new g_AdminNewsUrl[]="http://eks.wtfux.com/PublicSurf/AdminPage/AdminIndex.htm" // Defines where the Admin news page is, reads from amx_adminnewslink at server startup
new g_PublicRulesUrl[]="http://eks.wtfux.com/PublicSurf/PublicSurf.php?url=rules.htm" // Defines where the server rules page is.
new g_HomeWebsite[] = "http://eks.wtfux.com/PublicSurf/PublicSurf.php" 
#endif

#define MAXHOOKS 20
#define HOOK_URLLEN 256
#define HOOK_NAMELEN 48

new g_HookListUrl[MAXHOOKS+1][HOOK_URLLEN+1]
new g_HookListName[MAXHOOKS+1][HOOK_NAMELEN+1]
new g_HookListCount = 0;
new g_MaxClients;

public plugin_init() 
{ 
	register_plugin("MOTD mangement","1.4.0","EKS")
#if PublicRules == 1
	register_clcmd("amx_publicrules","CMD_PublicRules",0,"Display public rules")
#endif
#if PlayerInfo == 1
	register_clcmd("amx_playersinfo","CMD_PlayersInfo",0,"Displays info on players in a MOTD window") 
#endif
#if PublicBrowse == 1
	register_clcmd("amx_browse","CMD_PublicBrowse",0,"<url> - Opens specified website")
	register_clcmd("say /browse","CMD_PublicBrowse",0,"<url> - Opens specified website")
#endif
#if AdminNews == 1
	register_clcmd("amx_adminnews","CMD_AdminNews",ADMIN_KICK,"Opens admins news in MOTD window") 
#endif
#if USE_CVARS == 1
	register_cvar("amx_adminnewsurl",g_AdminNewsUrl)
	register_cvar("amx_publicrulesurl",g_PublicRulesUrl)
	register_cvar("amx_browserhomeurl",g_HomeWebsite)

	register_srvcmd("amx_addsayhook","CmdNewHook") 
	register_clcmd("say","Event_Say") 
	register_clcmd("say_team","Event_Say") 
	set_task(8.0,"update_cvars")
#endif
	g_MaxClients = get_maxplayers()
}
public CmdNewHook(id) 
{
	read_argv(1,g_HookListName[g_HookListCount],HOOK_NAMELEN)
	read_argv(2,g_HookListUrl[g_HookListCount],HOOK_URLLEN)
	remove_quotes(g_HookListName[g_HookListCount])
	remove_quotes(g_HookListUrl[g_HookListCount])

	server_print("Hooking say: %s and will forward to: %s",g_HookListName[g_HookListCount],g_HookListUrl[g_HookListCount])	
	g_HookListCount++;
} 

public Event_Say(id)
{
 	if(g_HookListCount == 0)
		return PLUGIN_CONTINUE
	
	new arg1[32]
	read_argv(1,arg1,31) 
	
	for(new i=0;i<g_HookListCount;i++)
	{
		if(equal(arg1,g_HookListName[i]))
		{
			show_motd(id,g_HookListUrl[i],g_HookListName[i])
			return PLUGIN_CONTINUE
		}
	}

	return PLUGIN_CONTINUE
}

#if AdminNews == 1
public CMD_AdminNews(id,level,cid) {	// Opens full Admin news MOTD window
	show_motd(id,g_AdminNewsUrl,"Admin news") 
	}
#endif

#if PublicRules == 1
public CMD_PublicRules(id) { // Opens public Default webpage, but mainframe should be rules file
	show_motd(id,g_PublicRulesUrl,"STEAM Ingame browser") 
	} 
#endif

#if PublicBrowse == 1
public CMD_PublicBrowse(id) 
	{
	new url[80]
	read_argv(1,url,79)     
	if(contain(url,"/browse")!=-1) // A simple fix if the function was triggered via say
		read_argv(2,url,79)
	if (!url[0]) // If no url was entered
		{
		show_motd(id, g_HomeWebsite, "STEAM Ingame browser") 
		return PLUGIN_CONTINUE 
		}
	if(contain(url,"://")!=-1 )  // The url contained :// no need to add it.
		{
		format(url,79,"%s?url=%s",g_HomeWebsite,url)
		show_motd(id,url,"STEAM Ingame browser") 
		return PLUGIN_CONTINUE
		}
	else		// The url did not contain :// so lets do it.
		{
		format(url,79,"%s?url=http://%s",g_HomeWebsite,url)
		show_motd(id,url,"STEAM Ingame browser") 
		return PLUGIN_CONTINUE
		}
	return PLUGIN_CONTINUE
	}
#endif
#if PlayerInfo == 1
public CMD_PlayersInfo(id) { // This code opens the player info motd box
	new pos, message[1600],name[32],AuthID[35],ContryCode[4]
#if USE_HTML == 1
	pos += format(message[pos],1599 - pos,"<html><table width=^"580^" border=^"0^">")
#endif
	if (get_user_flags(id) & ADMIN_KICK) // Checks if player is a admin, since regular players should not see other players IP and see what players are admins
	{
		new  ip[40]
		for(new i=1;i<=g_MaxClients;i++) if(is_user_connected(i))
		{				
			//log_amx("i %d - MaxClients %d - pos %d",i,g_MaxClients,pos)
			
			get_user_name(i,name,31) 
			get_user_ip(i,ip,39) 
			get_user_authid(i,AuthID,34) 
#if USE_HTML == 1
			if (get_user_flags(i) & ADMIN_KICK)
				format(name,31,"<b>@</b>%s",name)	// Add a @ to admins nick
#if GEO_IP == 1
			geoip_code3(ip,ContryCode)
			pos += format(message[pos],1599 - pos,"<div><tr><td>%s</tr></td> <td>IP: %s</td> <td>AuthID: %s</td><td>Country: %s</td></div>",name,ip,AuthID,ContryCode) 
#else
			pos += format(message[pos],1599 - pos,"<div><tr><td>%s</tr></td> <td>IP: %s</td> <td>AuthID: %s</td></div>",name,ip,AuthID) 
#endif
#else
			if (get_user_flags(i) & ADMIN_KICK)
				format(name,31,"@%s",name)
			pos += format(message[pos],1599 - pos,"%s IP: %s AuthID: %s",name,ip,AuthID) 
			//log_amx("Reached end of function")
#endif
		}
		show_motd(id,message,"Player Info Admin") 
		return PLUGIN_HANDLED 
	} else {		// This code shows the player info to none admins
		for (new i=1;i<=g_MaxClients;i++) 
			{
			if(is_user_connected(i))
				{
				get_user_name(i,name,31) 
				get_user_authid(i,AuthID,34) 
	#if USE_HTML == 1
				pos += format(message[pos],1599 - pos,"<div><tr><td>%s</tr></td> <td>AuthID: %s</td></div>",name,AuthID) 
	#else
				pos += format(message[pos],1599 - pos,"%s IP: %s AuthID: %s",name,ip,AuthID) 
#endif
				}
			} 
		show_motd(id,message,"Player Info public") 
		return PLUGIN_HANDLED 
		}
	return PLUGIN_HANDLED 
	}
#endif

#if USE_CVARS == 1
public update_cvars()
	{
	get_cvar_string("amx_adminnewsurl",g_AdminNewsUrl,127)
	get_cvar_string("amx_publicrulesurl",g_PublicRulesUrl,127)
	get_cvar_string("amx_browserhomeurl",g_HomeWebsite,127)
	}
#endif
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
