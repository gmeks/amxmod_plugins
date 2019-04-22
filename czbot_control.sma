/* CZ Bot control 
About:
This plugin allows admins to control the CZ bots, The plugin can automaticly add bots so a minimum of players is allways on the server. There is allso good menus so you can change bot settings on the fly

Credits: 
Ops in #AMXmod @ Quakenet for alot of help ( + AssKicR & CheesyPeteza ) 
Cvar info gotton from: http://www.ufo-design.co.uk/counterstrike/hockey_cz_sp_guide.html 

Forum Topic: http://www.amxmodx.org/forums/viewtopic.php?t=2612

Usage: 
You should add this to server.cfg: bot_join_after_player 0 if you dont, you might get weird errors 
amx_czbotmenu    - Opens the Bot menu 
amx_czbotmenuwr - Opens the CZ Bot menu to Weapon restrict menu 

CVARS: 
amx_czbotautoadd <number> How many bots to autoadd 
amx_czbotchangename <1/0> If the bots should be renamed 
amx_czbotautokill <3/2/1/0> If the bots should be slayin when the last human is killed 0 = disabled | 1 = Bots on the opposite team is slayin last surviving human |2 = Kills the bots on a random team   | 3 = Human player are respawned if a bot is alive( Bot is killed )
amx_czbotjoinafterplayer <2/1/0>  1) If the bots should be kicked if there are no human playres left on the server.  | 2) The bots are frozen when no human players are on the server

FAQ) 
Q) I get # on add/remove bots 
A) Its becuse you have amx_czbotautoadd higher then 0 

Q) When i add bots nothing happens 
A) Probebly become you have changed what teams the bots can join, and mp_autoteambalance & p_limitteams are enabled 

Changelog 
 1.3.2 ( 18.10.2005 )
	- Added: Forcefully sets bot_join_after_player cvar
	- Fixed: Bots not being renamed if bot count was over 10
	- Changed: Minor opimisations and fixes
 
 1.3.1 ( 11.08.2004 )
	- Changed: Some messages ( when a player is respawned ) to look less like debug messages
	- Added: Player is now teleported to the location where the bot was.
	- Added: Respawn system can now use either the Engine or fun module ( Fun module is "better", becuse it allows the HP/Armor/weapons to be transfered )

 1.3.0 ( 11.08.2004 )
	- Added: amx_czbotautokill 3 Respawns human players if bots are still alive ( Takes the place of a bot on his team)
	- Fixed: ChangeBotname giving bots unorginal nicks.
	- Changed: The code that adds the bots should be more robust now

 1.2.0 ( 15.06.2004 )
	- Added: amx_czbotjoinafterplayer 2 will freeze the bots when no players are on the server.
	- Changed: Now the plugin uses the internal CZ to control the bot amount

 1.1.0 ( 04.06.2004 ) 
	- Added: cvar: amx_czbotjoinafterplayer
	- Added: amx_czbotautokill 2
	- Changed: the kick_abot funtion now kicks bot with the CZ bot command with amx_czbotchangename 0

 1.0.0 ( 02.06.2004 ) 
	- First public release 

*/ 

#include <amxmodx> 
#include <amxmisc> 
#include <fun>
#include <engine>

#define MenuSystem 1 
#define RespawnSystem 2 // 1 = Fun module based | 2 = Engine based

new g_BotCount		// Contains the number of bots on the server 
new g_BotKicked[33]
new g_MaxPlayers


#if MenuSystem == 1 
new g_BotSkill[8]	// Contains the name/string of the current bot skill 
new g_BotChatter[8]	// Contains the string of the bot_chatter cvar. ( Exaclly the same) Does not need to be a global, but is for the reason of "logic" 
new g_BotAutoKill[8]    // If the bots bots should be killed when the last human player is dead 
new g_FreezeBots[4]	// If the bots should be frozen or not 
new g_BotsJoin[4] 
new g_Temp[4]		// User to store on /off temporary 
new g_BotAllowNada[4],g_BotAllowMGs[4],g_BotAllowPistol[4],g_BotAllowRifles[4],g_BotAllowShield[4],g_BotAllowShotguns[4],g_BotAllowSniper[4],g_BotAllowSubMG[4] 
#endif

#define Plugin_Version "1.3.4"

public plugin_init() 
{ 
	register_plugin("CZ Bot control",Plugin_Version,"EKS")
	register_cvar("amx_czbotcontrol",Plugin_Version,FCVAR_SERVER)
	
	register_cvar("amx_czbotautoadd","2")
	register_cvar("amx_czbotjoinafterplayer","2")
	register_cvar("amx_czbotchangename","1")
	register_cvar("amx_czbotautokill","3")
	register_event("DeathMsg","event_hpdeath","a") 
	
	g_MaxPlayers = get_maxplayers()

	if(get_cvar_num("amx_czbotautoadd"))
	{
		server_cmd("bot_join_after_player 0")			// Just in case we set this cvar
		server_cmd("bot_quota %d",get_cvar_num("amx_czbotautoadd"))
	}
	
#if MenuSystem == 1 
	register_clcmd("amx_czbotmenu","ShowMenuCZBot",ADMIN_KICK," - Opens the CZ Bot menu to control menu") 
	register_clcmd("amx_czbotmenuwr","ShowMenuCZBotWR",ADMIN_KICK," - Opens the CZ Bot menu to Weapon restrict menu") 
	register_menucmd(register_menuid("\yCZ Bot menu:"), 1023, "MenuCZBot" ) 
	register_menucmd(register_menuid("\yBot WR menu:"), 1023, "MenuCZBotWR" ) 

	get_botdiffstring() 
	get_autokillstring()
	get_cvar_string("bot_chatter",g_BotChatter,7) 
	get_cvar_string("bot_join_team",g_BotsJoin,7) 

	toggel_cvar("bot_stop",1);format(g_FreezeBots,3,g_Temp) 
	toggel_cvar("bot_allow_sub_machine_guns",1);format(g_BotAllowSubMG,3,g_Temp) 
	toggel_cvar("bot_allow_snipers",1);format(g_BotAllowSniper,3,g_Temp); 
	toggel_cvar("bot_allow_shotguns",1);format(g_BotAllowShotguns,3,g_Temp); 
	toggel_cvar("bot_allow_shield",1);format(g_BotAllowShield,3,g_Temp); 
	toggel_cvar("bot_allow_rifles",1);format(g_BotAllowRifles,3,g_Temp); 
	toggel_cvar("bot_allow_pistols",1);format(g_BotAllowPistol,3,g_Temp); 
	toggel_cvar("bot_allow_machine_guns",1);format(g_BotAllowMGs,3,g_Temp); 
	toggel_cvar("bot_allow_grenades",1);format(g_BotAllowNada,3,g_Temp); 
	

#endif 
}
#if MenuSystem == 1 
public ShowMenuCZBotWR(id,level,cid) 
{ 
	if(!cmd_access (id,level,cid,1)) return PLUGIN_HANDLED 
	new szMenuBody[256] 
	new len,keys 

	len = format(szMenuBody,255,"\yBot WR menu:^n Weapon restric menu") 
	len += format(szMenuBody[len],255 - len,"^n\w 1. Allow Grenades:%s",g_BotAllowNada) 
	len += format(szMenuBody[len],255 - len,"^n\w 2. Allow Machine guns:%s",g_BotAllowMGs) 
	len += format(szMenuBody[len],255 - len,"^n\w 3. Allow Pistols:%s",g_BotAllowPistol) 
	len += format(szMenuBody[len],255 - len,"^n\w 4. Allow Rifles:%s",g_BotAllowRifles) 
	len += format(szMenuBody[len],255 - len,"^n\w 5. Allow Sheilds:%s",g_BotAllowShield) 
	len += format(szMenuBody[len],255 - len,"^n\w 6. Allow Shotguns:%s",g_BotAllowShotguns) 
	len += format(szMenuBody[len],255 - len,"^n\w 7. Allow Snipers:%s",g_BotAllowSniper) 
	len += format(szMenuBody[len],255 - len,"^n\w 8. Allow Sub machine guns:%s",g_BotAllowSubMG) 

	len += format(szMenuBody[len],255 - len,"^n\w 10. Exit") 

	keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9) 
	show_menu( id, keys, szMenuBody, -1 ) 
	return PLUGIN_CONTINUE 
} 

public MenuCZBotWR(id,key) 
{ 
	switch( key ) 
	{
		case 0: {toggel_cvar("bot_allow_grenades",0);format(g_BotAllowNada,3,g_Temp);} 
		case 1: {toggel_cvar("bot_allow_machine_guns",0);format(g_BotAllowMGs,3,g_Temp);} 
		case 2: {toggel_cvar("bot_allow_pistols",0);format(g_BotAllowPistol,3,g_Temp);} 
		case 3: {toggel_cvar("bot_allow_rifles",0);format(g_BotAllowRifles,3,g_Temp);} 
		case 4: {toggel_cvar("bot_allow_shield",0);format(g_BotAllowShield,3,g_Temp);} 
		case 5: {toggel_cvar("bot_allow_shotguns",0);format(g_BotAllowShotguns,3,g_Temp);} 
		case 6: {toggel_cvar("bot_allow_snipers",0);format(g_BotAllowSniper,3,g_Temp);} 
		case 7: {toggel_cvar("bot_allow_sub_machine_guns",0);format(g_BotAllowSubMG,3,g_Temp);} 
	} 
	if(key != 9) 
		ShowMenuCZBotWR(id,4,-74) // This is a hack, You need to send "level" & cid or you get  a compiler error. Im bascily sending full access *gasp* 
} 

public ShowMenuCZBot(id,level,cid) 
{ 
	if(!cmd_access (id,level,cid,1)) return PLUGIN_HANDLED 
	new szMenuBody[256] 
	new len,keys 

	len = format(szMenuBody,255,"\yCZ Bot menu:^n Current Bot Amount: %d",g_BotCount) 
	len += format(szMenuBody[len],255 - len,"^n\w 1. Bot Skill:%s",g_BotSkill) 
	len += format(szMenuBody[len],255 - len,"^n\w 2. Bot Chatter:%s",g_BotChatter) 
	len += format(szMenuBody[len],255 - len,"^n\w 3. Auto kill bots:%s",g_BotAutoKill) 
	len += format(szMenuBody[len],255 - len,"^n\w 4. Freeze Bots:%s",g_FreezeBots) 
	len += format(szMenuBody[len],255 - len,"^n\w 5. Bots Join: %s",g_BotsJoin) 
	len += format(szMenuBody[len],255 - len,"^n\w ") 
	if(get_cvar_num("amx_czbotautoadd") != 0) // You cannot kick/ add bots if amx_czbotautoadd is "on" 
	{ 
		len += format(szMenuBody[len],255 - len,"^n\w #. Add a Bot") 
		len += format(szMenuBody[len],255 - len,"^n\w #. Remove a bot") 
	} 
	else 
	{ 
		len += format(szMenuBody[len],255 - len,"^n\w 7. Add a Bot") 
		len += format(szMenuBody[len],255 - len,"^n\w 8. Remove a bot") 
	} 
	len += format(szMenuBody[len],255 - len,"^n\w ") 
	len += format(szMenuBody[len],255 - len,"^n\w 10. Exit") 

	keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9) 
	show_menu( id, keys, szMenuBody, -1 ) 
	return PLUGIN_CONTINUE 
} 


public MenuCZBot(id,key) 
{ 
	if(get_cvar_num("amx_czbotautoadd") != 0) 
        { 
		switch(key) 
		{ 
			case 0: change_botczlevel() 
			case 1: change_botchatter() 
			case 2: change_autokill() 
			case 3: {toggel_cvar("bot_stop",0);format(g_FreezeBots,3,g_Temp);} 
			case 4: change_botjointeam() 
		} 
        } 
	else 
        { 
		switch(key) 
		{ 
			case 0: change_botczlevel() 
			case 1: change_botchatter() 
			case 2: change_autokill()
			case 3: { toggel_cvar("bot_stop",0);format(g_FreezeBots,3,g_Temp);} 
			case 4: change_botjointeam() 
			case 6: {server_cmd("bot_add");client_print(0,3,"[AMX] Adding a new bot"); } 
			case 7: {kick_abot();client_print(0,3,"[AMX] Removing a bot"); } 
		} 
	} 
	if(key != 9) 
	ShowMenuCZBot(id,4,-74) // This is a hack, You need to send "level" & cid or you get  a compiler error. Im bascily sending full access *gasp* 
} 
#endif 

public client_disconnect(id) 
{ 
	if(is_user_bot(id)) 
	{
		g_BotCount-- 
		if(get_cvar_num("amx_czbotchangename"))
		{

			new TempInt,Name[5]
			get_user_name(id,Name,4)
			replace(Name,31,"BOT","")

			TempInt = str_to_num(Name)

			g_BotKicked[0]++			
			g_BotKicked[g_BotKicked[0]] = TempInt
		}
	}
	if(get_cvar_num("amx_czbotautoadd"))
		set_task(2.0,"change_botcount")

 	if(get_playersnum(1) == 0  && get_cvar_num("amx_czbotjoinafterplayer") == 2)	// If the bots are frozen lets unfreeze them
		{
		format(g_FreezeBots,3,g_Temp)
		if(get_cvar_num("bot_stop") == 0)
			toggel_cvar("bot_stop",0)
		}
	return PLUGIN_CONTINUE 
} 
public client_connect(id) 
{ 
	if(is_user_bot(id)) 
	{ 
		g_BotCount++ 
		if(get_cvar_num("amx_czbotchangename")) 
			ChangeBotName(id) 
		return PLUGIN_HANDLED
	} 
	if(g_BotCount == get_playersnum() && !is_user_bot(id)) 
		server_cmd("sv_restart 15") 
		
	if(get_cvar_num("amx_czbotautoadd"))
		set_task(2.0,"change_botcount")

	if(get_playersnum(1) == 1 && get_cvar_num("amx_czbotjoinafterplayer") == 2)	// If the bots are frozen lets unfreeze them
		{
		format(g_FreezeBots,3,g_Temp)
		if(get_cvar_num("bot_stop") == 1)
			toggel_cvar("bot_stop",0)
		}
	return PLUGIN_HANDLED
} 
public change_botcount()
{
	server_cmd("bot_quota %d",(get_cvar_num("amx_czbotautoadd") - get_human_players()))
}

public event_hpdeath() 
{
	new id = read_data(2) // Gets Victim ID 
	if(is_user_bot(id)) 
		return PLUGIN_HANDLED 
	if(!get_human_alive())
	{
		if(get_cvar_num("amx_czbotautokill") == 1) 
		{ 
			new team = get_user_team(id) 
			kill_bots(team) 
		}
		if(get_cvar_num("amx_czbotautokill") == 2)  
		{ 
			new team = random_num(1,2)
			kill_bots(team) 
		}
		if(get_cvar_num("amx_czbotautokill") == 3)  
		{ 
			new parm[1]
			parm[0] = id
			remove_task(id)
			set_task(0.1,"respawn_player",id,parm,1,"a",1)
			//respawn_player(id)
		}
	}
	return PLUGIN_HANDLED
} 
public respawn_player(parm[])
{
	new id = parm[0]
	new Team = get_user_team(id)
	new BotId
	for(new i=1;i<=g_MaxPlayers;i++) if(is_user_bot(i) && is_user_alive(i) && get_user_team(i) == Team)	{ BotId = i; } // Finds the first alive bot thats on the players team
	if(!BotId)
	{
		client_print(id,3,"[AMX] There was no more alive bots on your team")
		return PLUGIN_CONTINUE
	}
	new PlayerName[34],BotName[34]
	get_user_name(BotId,BotName,34)
	get_user_name(id,PlayerName,34)
	client_print(0,3,"[AMX] %s has given his life so %s could live again",BotName,PlayerName)

#if RespawnSystem == 1
	new BotHP = get_user_health(BotId)
	new BotArmor = get_user_armor(BotId)
	new WeaponList[32],WeaponNum,BotOrigin[3]
	get_user_origin(BotId,BotOrigin)

	get_user_weapons(BotId,WeaponList,WeaponNum)
	user_kill(BotId)
	spawn(id)
	for(new i=0;i<=WeaponNum;i++)
		give_item(id,WeaponList[i])

	BotOrigin[1] = BotOrigin[1] + 10 // So the player does not get stuck in the ground/body
	set_user_health(id,BotHP)
	set_user_armor(id,BotArmor)
	set_user_origin(id,BotOrigin)
#endif
#if  RespawnSystem == 2
	new Float:f_Origin[3]
	entity_get_vector(BotId,EV_VEC_origin,f_Origin)
	DispatchSpawn(id)
	user_kill(BotId)

	f_Origin[1] +=  15 // So the player does not get stuck in the ground/body
	entity_set_vector(id,EV_VEC_origin,f_Origin)
#endif
	return PLUGIN_CONTINUE
}

stock get_human_players() // This function finds out if any  players are on the server 
{ 
    new Humansplayers=0 
    for(new i=1;i<=g_MaxPlayers;i++) if(!is_user_bot(i) && !is_user_hltv(i)  && is_user_connected(i) || !is_user_bot(i) && !is_user_hltv(i)  && is_user_connecting(i) ) Humansplayers++ 
    return Humansplayers 
} 


stock get_human_alive() // This function finds out if any human players are alive 
{ 
	new HumansAlive 
	for(new i=1;i<=g_MaxPlayers;i++) if(!is_user_bot(i) && !is_user_hltv(i) && is_user_alive(i)) HumansAlive++ 
	return HumansAlive 
}
stock kill_bots(team) // This function is used to kill every bot on the Oposite team as the last surviving human 
{ 
	if(team == 0) 
		for(new i=1;i<=g_MaxPlayers;i++) if(is_user_bot(i)) user_kill(i,1); 
	if(team != 0) 
		for(new b=1;b<=g_MaxPlayers;b++) if(is_user_bot(b) && get_user_team(b) != team) user_kill(b,1) 
} 
stock ChangeBotName(id)    // This function is used to change the bots name 
{ 
	new Name[32]
	new BotNum

	for(new i=1;i <= g_MaxPlayers;i++)
	{
		BotNum++
		format(Name,31,"BOT%d",BotNum)
		if(!CBN_OrginalCheck(Name))
		{
			set_user_info(id,"name",Name)
			break
		}
		
	}
}
stock CBN_OrginalCheck(BotName[])
{
	new WasOrginal=0
	for(new i=1;i <= g_MaxPlayers;i++) if(is_user_bot(i))
	{
		new PlayerName[32]
		get_user_name(i,PlayerName,31)
		if(equal(BotName,PlayerName))
		{
			WasOrginal = 1 
			break
		}
	}
	return WasOrginal
}

stock get_autokillstring()
{
	if(get_cvar_num("amx_czbotautokill") == 0) 
        { 
		format(g_BotAutoKill,7,"off") 
		return PLUGIN_CONTINUE 
        }
	if(get_cvar_num("amx_czbotautokill") == 1) 
        { 
		format(g_BotAutoKill,7,"on") 
		return PLUGIN_CONTINUE 
        }
	if(get_cvar_num("amx_czbotautokill") == 2) 
        { 
		format(g_BotAutoKill,7,"Random") 
		return PLUGIN_CONTINUE 
        }
	if(get_cvar_num("amx_czbotautokill") == 3) 
        { 
		format(g_BotAutoKill,7,"Respawn") 
		return PLUGIN_CONTINUE 
        }
	return PLUGIN_CONTINUE 
}
stock change_autokill()
{
	if(get_cvar_num("amx_czbotautokill") != 3)
		set_cvar_num("amx_czbotautokill",(get_cvar_num("amx_czbotautokill")+1))
	else
		set_cvar_num("amx_czbotautokill",0)
	get_autokillstring()
}

stock get_botdiffstring() // Gets the Name/String instead of the number 
{ 
	if(get_cvar_num("bot_difficulty") == 0) 
        { 
		format(g_BotSkill,7,"Easy") 
		return PLUGIN_CONTINUE 
        } 
	if(get_cvar_num("bot_difficulty") == 1) 
        { 
		format(g_BotSkill,7,"Normal") 
		return PLUGIN_CONTINUE 
        } 
	if(get_cvar_num("bot_difficulty") == 2) 
        { 
		format(g_BotSkill,7,"Hard") 
		return PLUGIN_CONTINUE 
        } 
	if(get_cvar_num("bot_difficulty") == 3) 
	{ 
		format(g_BotSkill,7,"Expert") 
		return PLUGIN_CONTINUE 
	} 
	return PLUGIN_CONTINUE 
} 
stock change_botczlevel() // Increases the bot difficulty 
	{ 
	new Temp = get_cvar_num("bot_difficulty") 
	if(Temp == 3) 
		set_cvar_num("bot_difficulty",0) 
	else 
	{ 
		Temp++ 
		set_cvar_num("bot_difficulty",Temp) 
        } 
	get_botdiffstring() // Gets the name/string of the new value and stores it in g_BotSkill 
	} 

stock change_botchatter() // Increases the bot_chatter cvar by 1 ( in a sense, but its all done with strings) 
{ 
	new Temp[8] 
	get_cvar_string("bot_chatter",Temp,8) 
	if(equal(Temp,"off")) 
        { 
		set_cvar_string("bot_chatter","minimal") 
		get_cvar_string("bot_chatter",g_BotChatter,7) 
		return PLUGIN_CONTINUE 
	} 
	if(equal(Temp,"minimal")) 
        { 
		set_cvar_string("bot_chatter","radio") 
		get_cvar_string("bot_chatter",g_BotChatter,7) 
		return PLUGIN_CONTINUE 
	} 
	if(equal(Temp,"radio")) 
        { 
		set_cvar_string("bot_chatter","normal") 
		get_cvar_string("bot_chatter",g_BotChatter,7) 
		return PLUGIN_CONTINUE 
	} 
	if(equal(Temp,"normal")) 
        { 
		set_cvar_string("bot_chatter","off") 
		get_cvar_string("bot_chatter",g_BotChatter,7) 
		return PLUGIN_CONTINUE 
        } 
	return PLUGIN_CONTINUE 
} 
stock change_botjointeam() // This function toggels over the diffrent teams the bots can join 
	{ 
	new Temp[4] 
	get_cvar_string("bot_join_team",Temp,3) 
	if(equal(Temp,"any")) 
        { 
		set_cvar_string("bot_join_team","CT") 
		get_cvar_string("bot_join_team",g_BotsJoin,3) 
		return PLUGIN_CONTINUE 
        } 
	if(equal(Temp,"CT")) 
        { 
		set_cvar_string("bot_join_team","T") 
		get_cvar_string("bot_join_team",g_BotsJoin,3) 
		return PLUGIN_CONTINUE 
	} 
	if(equal(Temp,"T")) 
	{ 
		set_cvar_string("bot_join_team","any") 
		get_cvar_string("bot_join_team",g_BotsJoin,3) 
		return PLUGIN_CONTINUE 
	} 
	return PLUGIN_CONTINUE 
} 
stock kick_abot() // This function kicks a bot 
{ 
	if(get_cvar_num("amx_czbotchangename") == 1) 
         { 
		server_cmd("bot_kick BOT%d",g_BotCount) 
		return PLUGIN_CONTINUE 
         } 
	set_cvar_num("bot_quota",get_cvar_num("bot_quota")-1)
	
	return PLUGIN_CONTINUE 
}
stock toggel_cvar(const argument[], num)  // This function does 2 things: when toggel_cvar("myCvar",0) It will toggel the cvar, and store the string value new cvar value in g_Temp. With oggel_cvar("myCvar",1) It will only check the cvar and store the string value 
{ 
    if(num == 0) 
    { 
        if(get_cvar_num(argument) == 0) 
        { 
		set_cvar_num(argument,1) 
		format(g_Temp,3,"on") 
	} 
        else 
		{ 
		set_cvar_num(argument,0) 
		format(g_Temp,3,"off") 
		} 
	} 
	else if (num == 1) 
	{ 
		if(get_cvar_num(argument) == 0) 
			format(g_Temp,3,"off") 
		if(get_cvar_num(argument) == 1) 
			format(g_Temp,3,"on") 
	} 
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
