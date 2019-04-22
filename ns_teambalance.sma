/* NS Team balance
About:
This plugin is used to balance the teams on a NS server, once a game is in progress ppl are automaticly moved to the team with the least 
players. And forces ppl to join a random team after a game has started, so you dont get ready room campers

Modules required: engine,ns

Plugin forum thread: http://www.amxmodx.org/forums/viewtopic.php?p=80465

Credits:
Ops in #AMXmodx @ Quakenet for alot of help ( + AssKicR & CheesyPeteza ) 

changelog:
 1.0.1
	- Fixed: HLTV being autoassinged

 1.0.0
	- First public release
*/

#include <amxmodx>
#include <engine>
#include <ns>

#define TEAM_MARINE		1
#define TEAM_ALIEN 		2
#define TEAM_READYROOM	3
#define TEAM_SPECTATOR	4
#define MAXPLAYERS 32

#define JoinTeamWait 45.0

new g_MaxPlayers
new g_GameState			// 0 = No game in progress | 1 = Game has started but everyone has not been forced on a team yet | 2 = Game has started, everyone that has not selected a team, gets autoassigned
new g_UserTeam[MAXPLAYERS+1]

public plugin_init() 
{
	register_plugin("NS Team balancer","1.0.0","EKS")
	register_event("Countdown","Event_GameStarted","a")
	register_event("TeamInfo","Event_TeamInfo","a")
	
	register_logevent("Event_RoundEnd",7, "3&victory_team")
	register_clcmd("readyroom","CMD_ReadyRoom",0,"- Used to block readyroom")
	register_impulse(5,"CMD_ReadyRoom")
 
	g_MaxPlayers = get_maxplayers()
}
public CMD_ReadyRoom(id)
{
	if(g_GameState == 0) 
		return PLUGIN_CONTINUE
	else 
	{
		ns_popup(id,"You cant join the readyroom while a game is in progress")
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public Event_TeamInfo()
{
	new id = read_data(1)
	new Team[15]
	read_data(2,Team,14)
	if(equal(Team,"undefinedteam"))
	{
		if(g_GameState == 0 || g_GameState == 1)
			g_UserTeam[id] = TEAM_READYROOM
		else if(g_UserTeam[id] == TEAM_READYROOM ||g_UserTeam[id] == TEAM_SPECTATOR) return PLUGIN_CONTINUE // This means the user has not changed team, So we stop the func
		else if(g_UserTeam[id] == -1) return PLUGIN_CONTINUE
	}
	else if(equal(Team,"alien1team"))
	{
		if(g_GameState == 0 || g_GameState == 1 || g_UserTeam[id] == -1 )
			g_UserTeam[id] = TEAM_ALIEN
		else if(g_UserTeam[id] == TEAM_ALIEN ) return PLUGIN_CONTINUE // This means the user has not changed team, So we stop the func
	}
	else if(equal(Team,"marine1team"))
	{
		if(g_GameState == 0 || g_GameState == 1 || g_UserTeam[id] == -1 )
			g_UserTeam[id] = TEAM_MARINE		
		else if(g_UserTeam[id] == TEAM_MARINE ) return PLUGIN_CONTINUE // This means the user has not changed team, So we stop the func
	}	
	return PLUGIN_CONTINUE
}

public Event_GameStarted()
{
	new Text[180]
	format(Text,179,"The game has started everyone has %0.0f seconds to select a team",JoinTeamWait)
	client_print(0,print_chat,Text)
	ns_popup(0,Text)
	g_GameState = 1
	set_task(JoinTeamWait,"Task_GameStarted",1,_,_,"a",1)
}
public Task_GameStarted()
{
	for(new i=1;i<=g_MaxPlayers;i++) if(is_user_connected(i) && ns_get_team(i) == TEAM_READYROOM && !is_user_hltv(i) || is_user_connected(i) && ns_get_team(i) == TEAM_SPECTATOR && !is_user_hltv(i))
		AutoAssignPlayer(i)

	g_GameState = 2
	client_print(0,print_chat,"Everyone thats in the readyroom & spectator is now being moved to a random team")
}
public client_disconnect(id)
{
	g_UserTeam[id] = 0
}

public client_putinserver(id)
{
	if(is_user_hltv(id))
		return PLUGIN_CONTINUE

	else if(g_GameState == 1)
	{
		client_print(id,print_chat,"You only have a few seconds to select a team or you will autoassinged")
		ns_popup(id,"You only have a few seconds to select a team or you will autoassinged")
	}
	else if(g_GameState == 2)
	{
		g_UserTeam[id] = -1
		AutoAssignPlayer(id)
	}
	return PLUGIN_CONTINUE
}

stock ns_get_team(id) return entity_get_int(id,EV_INT_team)

stock AutoAssignPlayer(id)
{
	if(get_user_flags(id) & ADMIN_KICK)
		return PLUGIN_CONTINUE
		
	ns_popup(id,"You have been autoassinged as the game is in progress")
	//client_cmd(id,"autoassign")
	engclient_cmd(id,"autoassign")
	g_UserTeam[id] = -1 // This this tell this plugin that this player has been marked to be allowed to moved to a team
	
	new Name[32]
	get_user_name(id,Name,31)
	client_print(0,print_chat,"%s has been autoassigned",Name)
	return PLUGIN_CONTINUE
}
public Event_RoundEnd()
{
	g_GameState = 0
	remove_task(1)
}