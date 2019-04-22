/*
Voicecomm ban
About:
This plugin is used to restric access to voicecomm to the users that abuse it, it saves ppl who are banned from using voicecomm in a text file. Witch is loaded
on mapchange.

Usage:
amx_banvoice <nick/userid>
amx_unbanvoice <nick/userid>

Modules required:
Engine

FAQ)
Q) Can i use this plugin on a lan server?
A) No.

Plugin forum thread: http://www.amxmodx.org/forums/viewtopic.php?p=80462

Credits:
Ops in #AMXmodx @ Quakenet for alot of help ( + AssKicR & CheesyPeteza )
SirTiger for idea of plugin

Changelog 
 1.0.4
 	- Fixed: Runetime error when clients disconnects sometimes

 1.0.3
 	- Added: Extra check to make sure players are fully connectedæ
 	
 1.0.2
	- Fixed: Plugin no longer does anything against Bots/hltv When they join/disconnect
	
 1.0.1
 	- Added: Console echo to the admin console when he bans/unbans the client
 	- Added: If the server reaches max voicecomm  bans it also warns in amxx logs
 	
 1.0.0
 	- First release
*/

#include <amxmodx>
#include <amxmisc>
#include <engine>

#define MAXBANS 120
#define MAXPLAYERS 32

new gs_BannedId[MAXBANS+1][35]
new g_NumberOfBans
new gs_BannedFile[128]

public plugin_init()
{
	register_plugin("Voicecomm ban","1.0.4","EKS")
	
	get_localinfo("amxx_basedir",gs_BannedFile,127)
	format(gs_BannedFile,127,"%s/data/voicecomm_banned.txt",gs_BannedFile)
	
	register_concmd("amx_banvoice","CMD_BanVoiceComm",ADMIN_KICK,"<nick/userid> Bans the user from using voicecomm") 
	register_concmd("amx_unbanvoice","CMD_UnBanVoiceComm",ADMIN_KICK,"<nick/userid> unBans the user from using voicecomm")	
	ReadBanFile()
}
public CMD_BanVoiceComm(id,level,cid) 
{ 
	if(!cmd_access (id,level,cid,1)) return PLUGIN_HANDLED
	new arg[32],VictimID
	
	read_argv(1,arg,31) 
	VictimID = cmd_target(id,arg,8)	
	if ((get_user_flags(VictimID) & ADMIN_IMMUNITY) && VictimID != id ) { return PLUGIN_HANDLED; } // This code is kind of "long", its job is to. Stop actions against admins with immunity, Stop actions action if the user lacks access, or is a bot/hltv
	new SteamID[35],VName[32]
	get_user_authid(VictimID,SteamID,34)
	get_user_name(VictimID,VName,31)
	
	if(CompareSteamId(SteamID))
	{
		console_print(id,"[AMXX] %s is allready banned from using voicecomm",VName)
		return PLUGIN_HANDLED
	}
	else if(g_NumberOfBans == MAXBANS)
	{
		console_print(id,"[AMXX] The server has reached the maximum number of banned ppl via voicecomm. A server admins needs to reconfigure this plugin")
		log_amx("The server has reached the maximum number of banned ppl via voicecomm. A server admins needs to reconfigure this plugin")
		return PLUGIN_HANDLED		
	}
	new AdminName[32],AdminAuthid[35]
	
	BanSteamID(SteamID)
	
	set_speak(VictimID, SPEAK_MUTED)
	
	get_user_name(id,AdminName,31)
	get_user_authid(id,AdminAuthid,34)
	
	switch(get_cvar_num("amx_show_activity"))   
	{ 
		case 2:   client_print(0,print_chat,"ADMIN %s: Has banned %s from using the voicecomm",AdminName,VName)
   		case 1:   client_print(0,print_chat,"ADMIN: %s was banned from using voiceomm",VName)
	}
	log_amx("%s<%s> has banned %s<%s> from using voicecomm",AdminName,AdminAuthid,VName,SteamID)
	console_print(id,"[AMXX] %s was banned from using voiceomm",VName)
	return PLUGIN_HANDLED
}
public CMD_UnBanVoiceComm(id,level,cid) 
{ 
	if(!cmd_access (id,level,cid,1)) return PLUGIN_HANDLED
	new arg[32],VictimID
	
	read_argv(1,arg,31) 
	VictimID = cmd_target(id,arg,8)	
	if ((get_user_flags(VictimID) & ADMIN_IMMUNITY) && VictimID != id ) { return PLUGIN_HANDLED; } // This code is kind of "long", its job is to. Stop actions against admins with immunity, Stop actions action if the user lacks access, or is a bot/hltv
	new SteamID[35],VName[32]
	get_user_authid(VictimID,SteamID,34)
	get_user_name(VictimID,VName,31)
	
	if(!CompareSteamId(SteamID))
	{
		console_print(id,"[AMXX] %s is not banned",VName)
		return PLUGIN_HANDLED
	}
	new AdminName[32],AdminAuthid[35]
	
	UnBanSteamID(SteamID)
	
	set_speak(VictimID, SPEAK_NORMAL)
	
	get_user_name(id,AdminName,31)
	get_user_authid(id,AdminAuthid,34)
	
	switch(get_cvar_num("amx_show_activity"))   
	{ 
		case 2:   client_print(0,print_chat,"ADMIN %s: Has unbanned %s from using the voicecomm",AdminName,VName)
   		case 1:   client_print(0,print_chat,"ADMIN: %s was unbanned from using voiceomm",VName)
	}
	log_amx("%s<%s> has unbanned %s<%s> from using voicecomm",AdminName,AdminAuthid,VName,SteamID)
	console_print(id,"[AMXX] %s was unbanned from using voiceomm",VName)
	return PLUGIN_HANDLED
}
public client_putinserver(id)
{
	new SteamID[35]
	get_user_authid(id,SteamID,34)	
	
	if(!is_user_bot(id) && !is_user_hltv(id))
	{
		if(CompareSteamId(SteamID))
		{
			new Name[32]
			get_user_name(id,Name,31)
			client_print(id,print_chat,"[AMXX] %s is banned from using voicecomm",Name)
			client_print(id,print_chat,"[AMXX] You have been banned from using voicecomm on this server")
			
			set_speak(id, SPEAK_MUTED)
		}
		else
			set_speak(id, SPEAK_NORMAL)
	}
}
stock UnBanSteamID(SteamID[])
{
	if(g_NumberOfBans == 1)
	{
		delete_file(gs_BannedFile)
		setc(gs_BannedId[1],34,0)
		g_NumberOfBans--
		return PLUGIN_CONTINUE
	}
	new Ban2Remove
	for(new i=1;i<=g_NumberOfBans;i++)	// We now find the index of the ban in the array
	{
		if(equal(SteamID,gs_BannedId[i]))
		{
			Ban2Remove = i
			break
		}
	}
	if(Ban2Remove == g_NumberOfBans) // If the ban we are removing is the last ban, we dont have to move strings around.
	{
		setc(gs_BannedId[Ban2Remove],34,0)
		g_NumberOfBans--
		WriteBanFile()
		return PLUGIN_CONTINUE
	}
	format(gs_BannedId[Ban2Remove],34,"%s",gs_BannedId[g_NumberOfBans])
	setc(gs_BannedId[g_NumberOfBans],34,0)
	g_NumberOfBans--
	WriteBanFile()
	return PLUGIN_CONTINUE
}
stock BanSteamID(SteamID[])
{
	g_NumberOfBans++
	format(gs_BannedId[g_NumberOfBans],34,"%s",SteamID)
	WriteBanFile()
}
stock WriteBanFile()
{
	if(file_exists(gs_BannedFile)) delete_file(gs_BannedFile)
	for(new i=0;i<=g_NumberOfBans;i++)
	{
		write_file(gs_BannedFile,gs_BannedId[i],-1)
	}	
}

stock CompareSteamId(SteamID[])
{
	for(new i=1;i<=g_NumberOfBans;i++)
	{
		if(equal(SteamID,gs_BannedId[i]))
			return 1
	}
	return 0
}
stock ReadBanFile()
{
	if(!file_exists(gs_BannedFile)) return PLUGIN_CONTINUE
	
	new InfoFromFile[40],EOF
	for(new i=0;read_file(gs_BannedFile,i,InfoFromFile,40,EOF) != 0 && i<= MAXBANS;i++)
	{
		if(strlen(InfoFromFile) >= 4)		// We make sure there is at least 4 vail chars before we accept the ban.
		{
			g_NumberOfBans++
			format(gs_BannedId[g_NumberOfBans],34,"%s",InfoFromFile)
		}
	}
	server_print("[AMXX] loaded %d bans from %s",g_NumberOfBans,gs_BannedFile)
	return PLUGIN_CONTINUE
}