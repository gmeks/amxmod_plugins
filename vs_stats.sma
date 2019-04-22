/* Vampire slayer stats
This plugin generates stats for Vampire slayer, it records who the best player for each
class is. And who knocked down who( and if someone steals his kill), the plugin can allso 
annouche diffrent actions based on amx_showstats.

Install:
in amxx.cfg
amx_showstats
( Just add the value to untill you get what you want. Everything is 63)
1 = Shows when someone knocks a vampire down
2 = Shows when someone stackes a vampire
4 = Shows when someone steals someone else kill ( If someone stakes a vamp that someone else knocked down)
8 = Shows MOTD with the stats
16 = Shows a hud message at map end
32 = Show spesial stakings ( Like Kill stealing or crossbow in the hart)

Usage:
say /stats

Forum thread: http://www.amxmodx.org/forums/viewtopic.php?p=56881

Credits:
Ops in #AMXmod @ Quakenet for alot of help ( + AssKicker & CheesyPeteza )
NiThuJu for helping testing and suggestions

Known isssues:
1) The plugin does not accuratly assess when a vampire gets knocked down, the time before he gets resurected
2) The plugin does not know when a new round begins, and uses a hack to rest round based arrays
3) If you change the mp_timelimit after the plugin loads, the mapend stats will not display properly
4) Any settings to amx_showstats will take 1 mapchange to be become effective

Todo:
1) Add a proper way to detect once a new round beggins( This will not happen untill routetwo replyes to my forum pm)
2) Add player spesfic stats( So a player can find out stats about himself )
3) Add some sort of logging that would allow a third party tool to generate webstats
4) Whatever someone might suggest
5) Add internal system for remembering what team/class player has, so it does not have to check it so often.

Changelog:
 1.0.0
 	- Changed: Optimised generation of stats
 	- Fixed: Rune time error in event_DeathMsg()
 	
 1.0.2
 	- Changed: No longer assumed maxplayers from define ( might create bugs)
 	
 1.0.1
 	- Changed: Some text ( Thx to NiThuJu )

 1.0.0
	- First release

*/ 

#include <amxmodx>
#include <amxmisc>
#include <engine>

#define MAXPLAYERS 32			// You should lower the value to match your maxplayers ( If you have a 16 player server, you can halfen the cpu used to Generates stats )
#define KnockDownTime 3.0
#define SafeStringCompare 1		// (DONT CHANGE) If the plugin should use safe string comparision. ( Safe means that it compares the entire Team/classs string instead of just 1 char. 1 char is ALOT faster but might break in upcomming VS releases

new g_UserInfo[MAXPLAYERS+1]
new g_KnockDown[3][MAXPLAYERS+1]
new g_Staker[MAXPLAYERS+1]
new g_StakeStealer[MAXPLAYERS+1]
new g_TopPlayer[3][4][MAXPLAYERS+1]
new g_Damage[3][MAXPLAYERS+1]
new g_showstats
new g_MaxPlayers
new gs_Message[2048]

public plugin_init()
{
	register_plugin("VS Stats","1.0.0","EKS")
	register_event("Damage", "event_Damage", "b")
	register_event("DeathMsg", "event_DeathMsg", "a")

	register_event("ResetHUD", "event_ResetHUD", "b")	// this is a hack to fix the fact that the plugin needs to know when  a new round is started || InitHUD
	register_concmd("say /stats","ShowStats",0," - Show Vampire Slayer stats")
	register_cvar("amx_showstats","63")
	g_showstats = get_cvar_num("amx_showstats")
	g_MaxPlayers = get_maxplayers()
	
	new Float:TaskTime = float(get_timeleft()) - 10.0
	set_task(TaskTime,"task_ShowStats",1+32);

}

public event_DeathMsg()
{
	new attacker = read_data(1)
	new victim = read_data(2)
	
	if(attacker == 0 )
		return PLUGIN_CONTINUE

	g_TopPlayer[get_team_int(attacker)][get_class_int(attacker)][attacker]++
	if(get_team_int(victim) != 1)
		return PLUGIN_CONTINUE
	
/*	
	new KillerWeaponId,Clip,Ammo
	KillerWeaponId = get_user_weapon(attacker,Clip,Ammo);
	
	if(!is_stacke_weapon(KillerWeaponId))
		return PLUGIN_CONTINUE
*/
	new AttackerName[32],VictimName[32]
	
	get_user_name(attacker,AttackerName,31)
	get_user_name(victim,VictimName,31)

	if(g_UserInfo[victim] == attacker)
	{
		if(g_showstats & 2)
		client_print(0,3,"[AMXX] %s has staked %s",AttackerName,VictimName)
		g_Staker[attacker]++
	}
	else if(g_UserInfo[victim] != attacker && g_UserInfo[victim])
	{	
		new OrginalKill[32]
		g_StakeStealer[attacker]++
		get_user_name(g_UserInfo[victim],OrginalKill,31)
		if(g_showstats & 32)
			client_print(0,3,"[AMXX] %s has staked %s while stealing %s kill",AttackerName,VictimName,OrginalKill)
	}
	else if(g_UserInfo[victim] == 0)
	{
		g_Staker[attacker]++
		new WIndex,D1,D2
		WIndex = get_user_weapon(attacker,D1,D2)

		if(g_showstats & 32 && WIndex == 21)
			client_print(0,3,"[AMXX] %s was crossbowed by %s",VictimName,AttackerName)

		else if(g_showstats & 32)
			client_print(0,3,"[AMXX] %s has lifestaked %s",AttackerName,VictimName)
	}
	g_UserInfo[victim] = -1
	return PLUGIN_CONTINUE
}
public event_Damage() 
{
	new victim = read_data(0);
	new attacker = get_user_attacker(victim)
	new damage = read_data(2);
	
	if(attacker == 0 || victim == 0 || attacker == victim || !damage || g_UserInfo[victim] == -1)
		return PLUGIN_CONTINUE
	g_Damage[get_team_int(attacker)][attacker] = g_Damage[get_team_int(attacker)][attacker] + damage

/*
	new KillerWeaponId,Clip,Ammo
	KillerWeaponId = get_user_weapon(attacker,Clip,Ammo);
*/
	new AttackerName[32],VictimName[32]
	get_user_name(attacker,AttackerName,31)
	get_user_name(victim,VictimName,31)
	
	new victimhp = get_user_health(victim)
	if(victimhp <= 0 && !g_UserInfo[victim] && get_team_int(victim) == 1) // && !is_stacke_weapon(KillerWeaponId)
	{
		if(g_showstats & 1)
			client_print(0,3,"[AMXX] %s knocked down %s",AttackerName,VictimName)
		
		g_UserInfo[victim] = attacker
		new parm[1]
		parm[0] = victim
		set_task(KnockDownTime,"reset_knockdown",victim,parm,1,"a",1)
		g_KnockDown[2][attacker]++
		g_KnockDown[1][victim]++
		return PLUGIN_CONTINUE
	}
/*	if(victimhp <= 0 && is_stacke_weapon(KillerWeaponId))
	{
		if(g_showstats & 8)
			client_print(0,3,"[AMXX] %s has staked %s",AttackerName,VictimName)
		g_UserInfo[victim] = 0
		return PLUGIN_CONTINUE
	}
*/
	return PLUGIN_CONTINUE
}
public task_ShowStats() 
{
	if(g_showstats & 16)
	{
		GenStats()
		set_hudmessage(255, 0, 0, 0.05, 0.1, 0, 6.0, 6.0, 0.5, 4.0,2) 
		show_hudmessage(0,gs_Message)
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE 
}

public ShowStats(id) 
{
	if(g_showstats & 8)
	{
		GenStats()

		show_motd(id,gs_Message,"VS Player Stats") 
//		set_hudmessage(255, 0, 0, 0.05, 0.1, 0, 6.0, 6.0, 0.5, 2.0,2) 
//		show_hudmessage(id,Message)
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE 
}

public reset_knockdown(parm[])
{
	remove_task(parm[0])
	g_UserInfo[parm[0]] = 0
}
stock is_stacke_weapon(WeaponID)	// This function is used check if the user is using a stake gun
{
	if(WeaponID == 23 || WeaponID == 18 || WeaponID == 34)
		return 1
	return 0
}
public client_connect(id)
{
	g_KnockDown[1][id] = 0
	g_KnockDown[0][id] = 0
	g_UserInfo[id] = 0
	g_StakeStealer[id] = 0
	g_Staker[id] = 0
	g_Damage[1][id] = 1
	g_Damage[2][id] = 1
	for(new i=1;i<=3;i++)
	{
		g_TopPlayer[1][i][id] = 0
		g_TopPlayer[2][i][id] = 0
	}
}

stock GenStats()
{
	for(new i=1;i<=g_MaxPlayers;i++) if(is_user_connected(i))
	{
		if(g_Staker[0] < g_Staker[i])
			g_Staker[0] = i

		if(g_KnockDown[1][0] > g_KnockDown[0][i])
			g_KnockDown[1][0] = i

		if(g_KnockDown[2][0] > g_KnockDown[1][i])
			g_KnockDown[2][0] = i

		if(g_StakeStealer[0] > g_StakeStealer[i])
			g_StakeStealer[0] = i

		if(g_TopPlayer[1][1][i] > g_TopPlayer[1][1][0])
			g_TopPlayer[1][1][0] = i

		if(g_TopPlayer[1][2][i] > g_TopPlayer[1][2][0])
			g_TopPlayer[1][2][0] = i

		if(g_TopPlayer[1][3][i] > g_TopPlayer[1][3][0])
			g_TopPlayer[1][3][0] = i

		if(g_TopPlayer[2][1][i] > g_TopPlayer[2][1][0])
			g_TopPlayer[2][1][0] = i
	
		if(g_TopPlayer[2][2][i] > g_TopPlayer[2][2][0])
			g_TopPlayer[2][2][0] = i

		if(g_TopPlayer[2][3][i] > g_TopPlayer[2][3][0])
			g_TopPlayer[2][3][0] = i

		if(g_Damage[1][i] > g_Damage[1][0])
			g_Damage[1][0] = i

		if(g_Damage[2][i] > g_Damage[2][0])
			g_Damage[2][0] = i
	}
	new len
	new Staker[32],StakerAuth[35]
	new StakeStealer[32],StakeStealerAuth[35]
	new Fatherd[32],FatherdAuth[35]
	new Molly[32],MollyAuth[35]
	new Eightball[32],EightballAuth[35]
	new Louis[32],LouisAuth[35]
	new Nina[32],NinaAuth[35]
	new Edgar[32],EdgarAuth[35]

	new KnockDown[3][32],KnockDownAuth[3][35]
	new Damage[3][32],DamageAuth[3][35]

	if(g_TopPlayer[1][1][0] != 0)
	{
		get_user_name(g_TopPlayer[1][1][0],Louis,31)
		get_user_authid(g_TopPlayer[1][1][0],LouisAuth,34)
	}
	else
	{
		format(Louis,31,"Nobody")	
	}
	if(g_TopPlayer[1][1][0] != 0)
	{
		get_user_name(g_TopPlayer[1][1][0],Louis,31)
		get_user_authid(g_TopPlayer[1][1][0],LouisAuth,34)
	}
	else
	{
		format(Louis,31,"Nobody")		
	}
	if(g_TopPlayer[1][2][0] != 0)
	{
		get_user_name(g_TopPlayer[2][1][0],Nina,31)
		get_user_authid(g_TopPlayer[2][1][0],NinaAuth,34)
	}
	else
	{
		format(Nina,31,"Nobody")	
	}
	if(g_TopPlayer[1][3][0] != 0)
	{
		get_user_name(g_TopPlayer[1][3][0],Edgar,31)
		get_user_authid(g_TopPlayer[1][3][0],EdgarAuth,34)
	}
	else
	{
		format(Edgar,31,"Nobody")	
	}
	if(g_TopPlayer[2][1][0] != 0)
	{
		get_user_name(g_TopPlayer[2][1][0],Fatherd,31)
		get_user_authid(g_TopPlayer[2][1][0],FatherdAuth,34)
	}
	else
	{
		format(Fatherd,31,"Nobody")
	}
	if(g_TopPlayer[2][2][0] != 0)
	{
		get_user_name(g_TopPlayer[2][2][0],Molly,31)
		get_user_authid(g_TopPlayer[2][2][0],MollyAuth,34)
	}
	else
	{
		format(Molly,31,"Nobody")
	}
	if(g_TopPlayer[2][3][0] != 0)
	{
		get_user_name(g_TopPlayer[2][3][0],Eightball,31)
		get_user_authid(g_TopPlayer[2][3][0],EightballAuth,34)
	}
	else
	{
		format(Eightball,31,"Nobody")
	}
	
	if(g_Staker[0] != 0)
	{
		get_user_name(g_Staker[0],Staker,31)
		get_user_authid(g_Staker[0],StakerAuth,34)
	}
	else
	{
		format(Staker,31,"Nobody")
	}
	if(g_KnockDown[1][0] != 0)
	{
		get_user_name(g_KnockDown[1][0],KnockDown[1],31)
		get_user_authid(g_KnockDown[1][0],KnockDownAuth[1],34)
	}
	else
	{
		format(KnockDown[1],31,"Nobody")
	}
	if(g_KnockDown[2][0] != 0)
	{
		get_user_name(g_KnockDown[2][0],KnockDown[2],31)
		get_user_authid(g_KnockDown[2][0],KnockDownAuth[2],34)
	}
	else
	{
		format(KnockDown[2],31,"Nobody")
	}
	if(g_Damage[1][0] != 0)
	{
		get_user_name(g_Damage[1][0],Damage[1],31)
		get_user_authid(g_Damage[1][0],DamageAuth[1],34)
	}
	else
	{
		format(g_Damage[1],31,"Nobody")
	}
	if(g_Damage[2][0] != 0)
	{
		get_user_name(g_Damage[2][0],Damage[2],31)
		get_user_authid(g_Damage[2][0],DamageAuth[2],34)
	}
	else
	{
		format(Damage[2],31,"Nobody")
	}
	if(g_StakeStealer[0] != 0)
	{
		get_user_name(g_StakeStealer[0],StakeStealer,31)
		get_user_authid(g_StakeStealer[0],StakeStealerAuth,34)
	}
	else
	{
		format(StakeStealer,31,"Nobody")
	}

	len = format(gs_Message,2047,"Vampire slayer Stats^n") 
	len += format(gs_Message[len],2047 - len,"Slayer Info:^n")
	len += format(gs_Message[len],2047 - len,"^n")
	len += format(gs_Message[len],2047 - len,"Top Staker: %s<%s> (%d)^n",Staker,StakerAuth,g_Staker[g_Staker[0]])
	len += format(gs_Message[len],2047 - len,"Top Vampire downknocker: %s<%s> (%d)^n",KnockDown[2],KnockDownAuth[2],g_KnockDown[2][g_KnockDown[2][0]])
	len += format(gs_Message[len],2047 - len,"Top Damage dealer: %s<%s> (%d)^n",Damage[2],DamageAuth[2],g_Damage[2][g_Damage[2][0]])
	len += format(gs_Message[len],2047 - len,"Top Kill stealer: %s<%s> (%d)^n",StakeStealer,StakeStealerAuth,g_Staker[g_Staker[0]])
	len += format(gs_Message[len],2047 - len,"^n")
	len += format(gs_Message[len],2047 - len,"Top Father: %s<%s> (%d)^n",Fatherd,FatherdAuth,g_TopPlayer[2][1][g_TopPlayer[2][1][0]])
	len += format(gs_Message[len],2047 - len,"Top Molly: %s<%s> (%d)^n",Molly,MollyAuth,g_TopPlayer[2][2][g_TopPlayer[2][2][0]])
	len += format(gs_Message[len],2047 - len,"Top Eightball: %s<%s> (%d)^n",Eightball,MollyAuth,g_TopPlayer[2][3][g_TopPlayer[2][3][0]])
	len += format(gs_Message[len],2047 - len,"^n")
	len += format(gs_Message[len],2047 - len,"Vampire Info:^n")
	len += format(gs_Message[len],2047 - len,"^n")
	len += format(gs_Message[len],2047 - len,"Most Knocked down: %s<%s> (%d)^n",KnockDown[1],KnockDownAuth[1],g_KnockDown[1][g_KnockDown[1][0]])
	len += format(gs_Message[len],2047 - len,"Top Damage dealer: %s<%s> (%d)^n",Damage[1],DamageAuth[1],g_Damage[1][g_Damage[1][0]])
	len += format(gs_Message[len],2047 - len,"^n")
	len += format(gs_Message[len],2047 - len,"Top Louis: %s<%s> (%d)^n",Louis,LouisAuth,g_TopPlayer[1][2][g_TopPlayer[1][2][0]])
	len += format(gs_Message[len],2047 - len,"Top Nina: %s<%s> (%d)^n",Nina,NinaAuth,g_TopPlayer[1][2][g_TopPlayer[1][2][0]])
	len += format(gs_Message[len],2047 - len,"Top Edgar: %s<%s> (%d)^n",Edgar,EdgarAuth,g_TopPlayer[1][3][g_TopPlayer[1][3][0]])
}


public event_ResetHUD(id)
{
	g_UserInfo[id] = 0
}

#if SafeStringCompare == 1
stock get_class_int(id)
{
	new Class[10]
	get_user_info(id,"model",Class,9)
	if(equal(Class,"fatherd") || equal(Class,"louis"))
		return 1
	if(equal(Class,"molly") || equal(Class,"nina"))
		return 2
	if(equal(Class,"eightball") || equal(Class,"edgar"))
		return 3
	return 0
}
stock get_team_int(id)
{
	new TeamString[8]
	get_user_team(id,TeamString,7)
	if(equali(TeamString,"VAMPIRE"))
		return 1
	if(equali(TeamString,"SLAYER"))
		return 2
	return 0
}
#else
stock get_class_int(id)
{
	new Class[1]
	get_user_info(id,"model",Class,0)
	if(equal(Class,"f") || equal(Class,"l"))
		return 1
	if(equal(Class,"m") || equal(Class,"n"))
		return 2
	if(equal(Class,"e") || equal(Class,"e"))
		return 3
	return 0
}
stock get_team_int(id)
{
	new TeamString[1]
	get_user_team(id,TeamString,0)
	if(equali(TeamString,"V"))
		return 1
	if(equali(TeamString,"S"))
		return 2
	return 0
}
#endif