/* Server preformance monitor

About:
This plugin is made to help admin track down problems on the server making it lag, you can have the plugin display realtime ( via hudmessages ) the server fps current
entitys and so on. Its also capeble of logging this information to a file for later viewing pleasure.

Usage:
say /showstats <on/off>
amx_showstats <on/off>

Forum topic: http://www.amxmodx.org/forums/viewtopic.php?t=2290

Modules required:
Engine

Credits:
Ops in #AMXmod @ Quakenet for alot of help ( + AssKicker & CheesyPeteza ) 
This plugin is kind of a ripof from prodigys metamod plugin ( www.modns.org )

FAQ)
Q) When i installed this plugin my server starts to lag!
A) If your server is allready having FPS issues installing another plugin is never gonna help

Q) When i show stats to myself i no longer see color messages!
A) when showing stats this plugin will use hudchannel 1 ( change in define section ) and no other plugin will mange to use it.

Todo:
Figure out how to get CPU usage on win/linux

Changelog:
 1.0.2 (19.12-2004)
	- Changed: Plugin now uses log dir to write logs
	- Changed: Optimised parts of the plugin

 1.0.1 ( 28.05.2004 ) 
	- Changed: Logging format its now: <time data was gotten> <fps> <enitity count> <player count> 
	- Removed: When the log is written from the buffer it no longer writes the time it starts to write the log 
	- Fixed: A bug where g_ShowStats[0] would not get updated if the client disconnected & had showstats enabled 


 1.0.0
	- First release

*/

#include <amxmodx> 
#include <engine>
#include <amxmisc>


#define Checksb4Log 80		// How many times its logged before average is made out
#define Checksb4Average 5	// How many times its logged before a log writen
#define MaxPlayers 32
#define ShowTime 1		// If showing stats should include the clock
#define WriteLog 1		// If a log should be writen
#define HudChannel2Use 2	// Hudchannel to use when displaying stats 

new FPS = 0		// Contains the FPS
new Float:NC = 0.0	// Contains the Float HL time.

new g_MaxPlayers
new g_MaxEnts
new g_PlayerNum
new g_ShowStats[MaxPlayers+1]
new g_PrefLog[Checksb4Log+1][4]
/*
g_PrefLog[0][0] The amont of checks have been done, when it equals Checksb4Log avrage gets calculated
g_PrefLog[0][1] Last avarage FPS
g_PrefLog[0][2] Last avarage Entity count

g_PrefLog[X][1] Last FPS
g_PrefLog[X][2] Enity number
g_PrefLog[X][3] Player count
*/
#if WriteLog == 1 
new g_Log[Checksb4Log+1][4]
new gs_Log[Checksb4Log+1][9]
new g_LogFile[48] = "preformancelog_"
#endif

public plugin_init()
{ 
	register_plugin("Server preformance monitor","1.0.2","EKS")
	register_clcmd("amx_showstats","cmd_ShowStats",ADMIN_KICK,"amx_showstats on/off - Will display realtime stats on this admin")
	register_clcmd("say /showstats","cmd_ShowStats",ADMIN_KICK,"amx_showstats on/off - Will display realtime stats on this admin")
	g_MaxPlayers = get_maxplayers()
	g_MaxEnts = get_global_int(GL_maxEntities)

#if WriteLog == 1 
	new Temp[32],Temp2[3]
	get_basedir(Temp,31)
	get_time("%d",Temp2,2)
	format(g_LogFile,47,"%s/logs/%s%s.log",Temp,g_LogFile,Temp2)
#endif	
}
stock FindEntNum()
{
	new CurEnt=0
	for(new i=1;i<=g_MaxEnts;i++) if(is_valid_ent(i))
		CurEnt++
	return CurEnt
}
public cmd_ShowStats(id,level,cid)
{
	if(!cmd_access (id,level,cid,2)) return PLUGIN_HANDLED
	
	new arg[16]
	read_argv(1,arg,15)     
	if(containi(arg,"/showstats")!=-1) // A simple fix if the function was triggered via say
		read_argv(2,arg,15)
	
	if(containi(arg,"on")!=-1 || containi(arg,"1")!=-1)
	{
		g_ShowStats[id] = 1
		g_ShowStats[0]++
		client_print(id,3,"[AMXX]Stats showing is now enabled")
	}
	if(containi(arg,"off")!=-1 || containi(arg,"0")!=-1)
	{
		g_ShowStats[id] = 0
		g_ShowStats[0]--
		client_print(id,3,"[AMXX]Stats showing is now disabled")
	}
	return PLUGIN_HANDLED
}


public server_frame() 
	{
	new Float:HLT = get_gametime()
	if(NC >= HLT)
		{
		FPS++
		}
	else
		{
		NC = NC + 1
		log_fps()
		if(g_ShowStats[0]) 
			show_stats()
		FPS = 0
		}
	}

stock log_fps()
	{
	if(g_PrefLog[0][0] == Checksb4Average)
		update_average()
	g_PrefLog[0][0]++

	g_PrefLog[g_PrefLog[0][0]][1] = FPS
	g_PrefLog[g_PrefLog[0][0]][2] = FindEntNum()
	g_PrefLog[g_PrefLog[0][0]][3] = g_PlayerNum
	}

stock update_average()
	{
	g_PrefLog[0][1] = 0
	g_PrefLog[0][2] = 0
	g_PrefLog[0][3] = 0
	for(new c=1;c<=Checksb4Average;c++) {g_PrefLog[0][3] = g_PrefLog[0][3] + g_PrefLog[c][3];} // Calculates the avarage players
	for(new b=1;b<=Checksb4Average;b++) {g_PrefLog[0][2] = g_PrefLog[0][2] + g_PrefLog[b][2];} // Calculates the avarage Ent count
	for(new a=1;a<=Checksb4Average;a++) {g_PrefLog[0][1] = g_PrefLog[0][1] + g_PrefLog[a][1];} // Calculates the avarage FPS

	g_PrefLog[0][1] = g_PrefLog[0][1] / g_PrefLog[0][0]
	g_PrefLog[0][2] = g_PrefLog[0][2] / g_PrefLog[0][0]
	g_PrefLog[0][3] = g_PrefLog[0][3] / g_PrefLog[0][0]
	g_PrefLog[0][0] = 0
	
	
#if WriteLog == 1
	get_time("%H:%M:%S",gs_Log[g_Log[0][0]],8)
	g_Log[g_Log[0][0]][1] = g_PrefLog[0][1]
	g_Log[g_Log[0][0]][2] = g_PrefLog[0][2]
	g_Log[g_Log[0][0]][3] = g_PrefLog[0][3]
	if(g_Log[0][0]==Checksb4Log)
		write_logs()
	g_Log[0][0]++
#endif
	}

stock show_stats()
{
	new Message[256]
	set_hudmessage(0, 225, 0, 0.75, 0.12, 0, 6.0, 6.0, 0.5, 0.15,HudChannel2Use)
#if ShowTime == 0
	format(Message,255,"Server Stats: ^n Current FPS: %d (%d) ^n Current Entity: %d (%d) ^n Players %d/%d",g_PrefLog[g_PrefLog[0][0]][1],g_PrefLog[0][1],g_PrefLog[g_PrefLog[0][0]][2],g_PrefLog[0][2],g_PrefLog[g_PrefLog[0][0]][3],g_MaxPlayers)
#else
	new CurrentTime[9]
	get_time("%H:%M:%S",CurrentTime,8)
	format(Message,255,"Server Stats: (%s) ^n Current FPS: %d (%d) ^n Current Entity: %d (%d) ^n Players %d/%d",CurrentTime,g_PrefLog[g_PrefLog[0][0]][1],g_PrefLog[0][1],g_PrefLog[g_PrefLog[0][0]][2],g_PrefLog[0][2],g_PrefLog[g_PrefLog[0][0]][3],g_MaxPlayers)
#endif
	for(new i=1;i<=g_MaxPlayers;i++) 
		if(g_ShowStats[i]) show_hudmessage(i, Message)
}
#if WriteLog == 1
stock write_logs()
{
	new Temp[256]
	
	for(new i=0;i<=Checksb4Log && g_Log[i][1] != 0;i++)
	{
		format(Temp,255,"%s %d %d %d/%d",gs_Log[i],g_Log[i][1],g_Log[i][2],g_Log[i][3],g_MaxPlayers)
		write_file(g_LogFile,Temp,-1)
	}
	g_Log[0][0] = 0
}
public plugin_end()
		write_logs()
#endif
public client_disconnect(id)
{
	if(g_ShowStats[id])
	{
		g_ShowStats[id]=0
		g_ShowStats[0]--
	}
	g_PlayerNum--
}
public client_connect(id)
{
	g_ShowStats[id]=0
	g_PlayerNum++
}