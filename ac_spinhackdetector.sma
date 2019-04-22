/* Spin hack Detector

About:
This plugin automaticly bans players who use spin hacks, after a short period of time.

Usage:
Automatic

Forum topic: http://www.amxmodx.org/forums/viewtopic.php?t=11614

Modules required:
Engine

Credits:
Ops in #AMXmod @ Quakenet for alot of help ( + AssKicker & CheesyPeteza ) 

FAQ)
Q) Can it produce fals detections?
A) If a person manges to move his mouse fast enough for X sec yes ( I have not be able to do this myself )

Q) If i do +left will that get me banned?
A) No.

Q) Can i ban via amx bans? 
A) Yes, edit sma and #define UseAMXBANS 0 to #define UseAMXBANS 1 


Changelog:
 1.0.4 ( 3.04-05 )
 	- Fixed: Bans via amxbans correctly now (Thx to: knocker )
 	
 1.0.3 ( 18.03-05 )
 	- Fixed: Typo in loggin code

 1.0.2 ( 13.03-05 )
 	- Fixed: Runetime error inside client_PostThink()

 1.0.1 ( 12.03-05 )
	- Added: #define UseAMXBANS if you want to ban via amxbans ( change "#define UseAMXBANS 0" to "#define UseAMXBANS 1" )
	
 1.0.0 ( 06.03-05 )
	- First release

*/
#include <amxmodx>
#include <engine>

#define MAXPLAYERS 32
#define MaxAngelChange 1500
#define MAX_DETECTIONS 25

#define PLAYER_LEFT 128			// Player is holdign down the left  button
#define PLAYER_RIGHT 256		// Player is holdign down the right button

#define UseAMXBANS 0

new Float:gf_LastAng[MAXPLAYERS+1][3]
new Float:gf_TotalAng[MAXPLAYERS+1]
new g_Detections[MAXPLAYERS+1] 

new g_MaxPlayers

public plugin_init()
{
	register_plugin("Spin hack Detector", "1.0.4" ,"EKS")
	g_MaxPlayers = get_maxplayers()
	set_task(1.0,"Task_CheckSpinTotal",128,_,_,"b")
}
public client_connect(id)
{
	g_Detections[id] = 0
}
public Task_CheckSpinTotal()
{
	for(new i=1;i<=g_MaxPlayers;i++)
	{
		if(is_user_alive(i))
		{
			if(gf_TotalAng[i] >= MaxAngelChange)
			{
				if(g_Detections[i] >= MAX_DETECTIONS)
				{
					RegisterOffense(i)
				}
				g_Detections[i]++
			}
			else
				g_Detections[i] = 0
	
			gf_TotalAng[i] = 0.0
		}
	}
}
public client_PostThink(id)
{
	if(is_user_alive(id))
	{
		new Float:Angel[3]
		entity_get_vector(id,EV_VEC_angles,Angel)
				
		gf_TotalAng[id] += vector_distance(gf_LastAng[id],Angel)
		
		CopyVector(Angel,gf_LastAng[id])
		
		new flags = entity_get_int(id,EV_INT_button)
		if(flags & PLAYER_LEFT || flags & PLAYER_RIGHT)
		{
			g_Detections[id] = 0
		}
	}
}
stock RegisterOffense(id)
{
	new Authid[35],Name[32],Message[256],CurrentTime[29],Map[32],ping,loss
	get_user_name(id,Name,31)
	get_user_authid(id,Authid,34)
	get_time("%d/%m-%Y - %H:%M:%S",CurrentTime,29)
	get_mapname(Map,31)
	get_user_ping(id,ping,loss)

	g_Detections[id]++

	format(Message,255,"[Spin hack Detector %s - %s] %s<%s> has changed his view to fast constantly to fast for the last %d sec ( Ping: %d )",CurrentTime,Map,Name,Authid,g_Detections[id],ping)
	log_amx(Message)
#if UseAMXBANS == 0
	server_cmd("kick #%d Banned becuse of cheats",get_user_userid(id))
	server_cmd("banid 0.0 %s",Authid)
	server_cmd("writeid")
#else
	server_cmd("amx_ban 0 %s Spin hack detected",Authid)
#endif
	client_print(0,print_chat,"%s<%s> was banned because he is using a spinhack",Name,Authid)
}
stock CopyVector(Float:Vec1[3],Float:Vec2[3])
{
	Vec2[0] = Vec1[0]
	Vec2[1] = Vec1[1]
	Vec2[2] = Vec1[2]
}