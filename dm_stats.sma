/*
About:
This plugin is for the servers that want ingame stats for their Deathmatch servers, it shows the stats via hudmessage

Credits: Ops in #AMXmod @ Quakenet for alot of help ( + AssKicR  & CheesyPeteza ) 

required modules: Engine

FAQ)
Q) Is there any way to configure this plugin? 
A) Not realy, it works out of the box. If alot of ppl use it, i may add more options/features


*/

#include <amxmodx>
#include <engine>

#define MAXPLAYERS 32

new g_MaxPlayers
new gs_Name[MAXPLAYERS+1][32]

// Arrays used for for public stats
new g_KillStreak[MAXPLAYERS+1]		// How many kills a user has in a row.
new g_DeathCount[MAXPLAYERS+1]		// Amount of death pr round
new g_KillCount[MAXPLAYERS+1]
new g_DmgGiven[MAXPLAYERS+1]
new g_DmgTaken[MAXPLAYERS+1]
// Used for personaly stats
new g_PKillerStats[MAXPLAYERS+1][MAXPLAYERS+1]
/*
g_PDStats[Index of player][Index of killer]
[0] == Amount of times killed
*/
new gs_PubStats[150]
new gs_PrivStats[250]

public plugin_init()
{
	register_plugin("Deathmatch Stats", "1.0.1" ,"EKS")
	
	g_MaxPlayers = get_maxplayers()
	
	register_event("DeathMsg","Event_DeathMsg","a")
	register_event("Damage","Event_Damage","b")
	register_event("SendAudio","Event_EndRound","a","2=%!MRAD_terwin","2=%!MRAD_ctwin","2=%!MRAD_rounddraw")
	register_logevent("Event_RoundStarted",2,"0=World triggered","1=Round_Start" )
}
public Event_EndRound()
{
	ShowStatsAll()
}
public plugin_end()
{
	ShowStatsAll()
}
stock GenPrivStats(id)
{
	format(gs_PrivStats,249,"Persons you have killed:^n")
	g_PKillerStats[id][0] = 0
	for(new i=1;i<=g_MaxPlayers;i++) if(g_PKillerStats[id][i])
	{
		g_PKillerStats[id][0]++
		format(gs_PrivStats,249,"%s  %s x%d^n",gs_PrivStats,gs_Name[i],g_PKillerStats[id][i])
	}
}
stock GenPublicStats()
{
	setc(gs_PubStats,149,0)
	new MostKilled=0
	new MostDied=0
	new DmgGiven=0
	new DmgTaken=0
	
	for(new i=1;i<=g_MaxPlayers;i++) if(is_user_connected(i))
	{
		if(g_DeathCount[i] > g_DeathCount[MostDied])
			MostDied=i
		if(g_KillCount[i] > g_KillCount[MostKilled])
			MostKilled=i
		if(g_DmgTaken[i] > g_DmgTaken[DmgTaken])
			DmgTaken=i
		if(g_DmgGiven[i] > g_DmgGiven[DmgGiven])
			DmgGiven=i
	}
	if(MostDied == 0 && MostKilled == 0)
		return 0
	else
	{
		format(gs_PubStats,149,"Most killed: %s %d^nMost Damage taken: %s %d^n^nBest killer: %s %d^nMost Damage given: %s %d",gs_Name[MostDied],g_DeathCount[MostDied],gs_Name[DmgTaken],g_DmgTaken[DmgTaken],gs_Name[MostKilled],g_KillCount[MostKilled],gs_Name[DmgGiven],g_DmgGiven[DmgGiven])
		return 1
	}
	return 0
}
public Event_RoundStarted()
{
	ShowStatsAll()
	for(new i=1;i<=g_MaxPlayers;i++) 
	{
		g_DeathCount[i] = 0
		g_DeathCount[i] = 0
		g_KillCount[i] = 0
		g_DmgGiven[i] = 0
		g_DmgTaken[i] = 0
		g_KillStreak[i] = 0
		
		for(new b=1;b<=g_MaxPlayers;b++) 
			g_PKillerStats[i][b] = 0
	}
}
public client_putinserver(id)
{
	for(new b=1;b<=g_MaxPlayers;b++) 
		g_PKillerStats[id][b] = 0
	g_DeathCount[id] = 0
	g_DeathCount[id] = 0
	g_KillCount[id] = 0
	g_DmgGiven[id] = 0
	g_DmgTaken[id] = 0
	g_KillStreak[id] = 0
}
public Event_Damage()
{
	new victim = read_data(0)
	new OrgDmg = read_data(2)
	new attacker = get_user_attacker(victim)
	
	if(OrgDmg == 0 || victim == 0 || attacker == 0 || victim == attacker ) return PLUGIN_CONTINUE

	if(attacker <= g_MaxPlayers)
		g_DmgGiven[attacker] += OrgDmg
		
	g_DmgTaken[victim] += OrgDmg
	return PLUGIN_CONTINUE
}
public Event_DeathMsg()
{
    // Gather information
    new killerweapon[33], killerweaponid, killerweaponammo, killerweaponclip
    new killerhealth,bulletsleft[50]
    new linec[129]

    new killer = read_data(1)
    new victim = read_data(2)

    // In case of self-kill, continue
    g_DeathCount[victim]++
    g_KillStreak[victim] = 0	// Reset the kills in a row on the victi
    
    if (killer == victim || killer == 0) return PLUGIN_CONTINUE
    g_KillCount[killer]++
    g_PKillerStats[killer][victim]++
    g_KillStreak[killer]++		// Increase the kills in a row on the killer
    
    
    killerhealth = get_user_health(killer)
    killerweaponid = get_user_weapon(killer,killerweaponclip,killerweaponammo)
    get_weaponname(killerweaponid,killerweapon,32)
    replace(killerweapon,31,"weapon_","") // Remove the "weapon_" part from weaponname
    killerweaponclip-- // Fix for 'one too many bullet in clip when displaying

    if (killerweaponclip >= 0)  // Determine if there are bullets left, if so check if bullet or bullets
    {
        if (killerweaponclip > 1) 
        	format(bulletsleft, 49, " (%d bullets left in clip)", killerweaponclip)
        else
        	format(bulletsleft, 49, " (1 bullet left in clip)")
    }
    else 
    {
        format(killerweapon, 32, "")
    }
    format(linec, 127, "%s has %d HP left after killing you with the %s%s", gs_Name[killer], killerhealth, killerweapon, bulletsleft)
    client_print(victim,print_chat,linec)
    // ---------------- We are now done showing info to the dead player, we now show the killer how many kills he in a row
    if(g_KillStreak[killer] >= 2)
    {
	    format(bulletsleft,49,"You have killed %d ppl in a row",g_KillStreak[killer])
	    HudMessage(killer,bulletsleft)
    }
    return PLUGIN_CONTINUE
}
public client_infochanged(id)
{
	get_user_info(id,"name", gs_Name[id],31)
}
stock ShowStatsAll()
{
	new ShowStats = GenPublicStats()
	if(ShowStats == 1)
	{
		set_hudmessage(255, 255, 0, 0.03, 0.24, 0, 0.0, 0.0, 4.0, 10.0,1)
		show_hudmessage(0,gs_PubStats)
		for(new i=1;i<=g_MaxPlayers;i++) if(is_user_connected(i) && ( g_KillCount[i] > 0 || g_DeathCount[i] > 0))
		{
			GenKDRatio(g_KillCount[i],g_DeathCount[i])
			GenPrivStats(i)
			if(g_PKillerStats[i][0])
			{
				set_hudmessage(255, 255, 0, 0.70, 0.50, 0, 0.0, 2.0, 4.0, 10.0,2)
				show_hudmessage(i,gs_PrivStats)	
			}

			format(gs_PrivStats,249,"You have killed %d and died %d times(%s KD)^nYou dealth out %d Damage and took %d",g_KillCount[i],g_DeathCount[i],gs_PubStats,g_DmgGiven[i],g_DmgTaken[i])
			set_hudmessage(255, 255, 0, 0.03, 0.50, 0, 0.0, 0.0, 4.0, 10.0,3)
			show_hudmessage(i,gs_PrivStats)	
		}
	}
}
stock FindBestkiller()
{
	new IKiller 	// Contains the index of the kill
	new FKiller 	// Contains the number of frags
	for(new i=1;i<=g_MaxPlayers;i++) if(is_user_connected(i) && g_KillStreak[i])
	{
		if(g_KillStreak[i] > FKiller)
		{
			FKiller = g_KillStreak[i]
			IKiller = i
		}
	}
	return IKiller
}
stock GenKDRatio(Kills,Death)
{
	new Float:KD
	if(Kills == 0 || Death == 0)
	{
		format(gs_PubStats,149,"%d:%d",Kills,Death)
	}
	else if(Kills > 1 && Death == 1)
	{
		format(gs_PubStats,149,"%d:1",Kills)
	}
	else if(Kills == 1 && Death > 1)
	{
		format(gs_PubStats,149,"1:%d",Death)
	}
	else if(Kills == Death)
	{
		format(gs_PubStats,149,"1:1")
	}	
	else
	{
		if(Kills > Death)
		{
			KD = float(Kills) / float(Death)
			format(gs_PubStats,149,"%.2f:1",KD)
			replace(gs_PubStats,149,".00","")
			//format(gs_PubStats,149,"%d:1",KD)
		}
		else if(Kills < Death)
		{
			KD = float(Death) / float(Kills)
			format(gs_PubStats,149,"1:%.2f",KD)
			replace(gs_PubStats,149,".00","")
			//format(gs_PubStats,149,"1:%d",KD)
		}
	}
}
stock HudMessage(id,message[])
{
	set_hudmessage(200, 100, 0, 0.03, 0.60, 0, 0.0, 0.0, 0.0, 4.0,4)
	show_hudmessage(id, message)
}
