/* Voicecom SpeakAll
About:
This plugin allows someone to speak to everyone on the server like sv_alltalk 1, but keeping the "old" voicecom ( +voicerecord )
speaking only to the team.
You can also only allow admins to use this option, via the sv_voiceall cvar

Usage:
+voiceall <- Client side bind to speak to everyone

Modules required:
Engine

FAQ)
Q) Will thils plugin mess with gag plugins?
A) No it should not

Plugin forum thread: http://www.amxmodx.org/forums/viewtopic.php?p=66527

Install:
1)Install plugin like any other.
Add sv_voiceall to amx.cfg
sv_voiceall <0/1/2>	 	0 = Disabled / 1 = Everyone can use the option | 2 = Admins are the only once that can use it

Credits:
Ops in #AMXmod @ Quakenet for alot of help ( + AssKicker & CheesyPeteza ) 
LizardKing For testing & idea

Changelog:
  1.1.3 (15.6.2005)
  	- Fixed: Posible fix for runetime error
  
  1.1.2 (19.11.2004)
	 - Added: A #define to disable the buildt in limit of 1 speaking at the time
	 
  1.1.1 (20.10.2004)
	 - Fixed: Ppl being able to do +voiceall and disconnect witch would result in players nobody being able to to speak
  
  1.1.0 (14.10.2004)
	 - Added: A message every 5th round in CS/CZ telling users about this plugin
	 - Added: sv_voiceall cvar ( 0 = Disabled / 1 = Everyone can use the option | 2 = Admins are the only once that can use it )
	 - Added: Option to advertise the plugin ( check the #define MOD  ) ( Default it will tell everyone about the option every 420 sec )
	 	
  1.0.0 (13.10.2004)
	 - First public Release

Todo:
Figure out a way check when someone is using voicecom (via +voicerecord )
*/

#include <amxmodx>
#include <amxmisc>
#include <engine>

#define MOD 2 // 0 = No mod spefic code(Used to tell users about this plugin) | 1 = CZERO/CSTRIKE | 2 = Tells all users about it every 420 sec
#define Only1AtATime 1

#if Only1AtATime == 1	
new g_IsSomeoneSpeaking
#endif
new g_VoiceAll

public plugin_init()
{
	register_plugin("Voicecom SpeakAll ","1.1.3","EKS")
	register_clcmd("+voiceall","cmd_SpeakALL",0," - Enables players to speak to everyone via voicecomm")
	register_clcmd("-voiceall","cmd_SpeakALLStop",0," - Enables players to speak to everyone via voicecomm")

	register_cvar("sv_voiceall","1")
}
#if Only1AtATime == 1	
public client_disconnect(id) if(g_IsSomeoneSpeaking == id) g_IsSomeoneSpeaking = 0
#endif

public plugin_cfg()
{
	g_VoiceAll = get_cvar_num("sv_voiceall")
#if MOD == 1	
	register_logevent("Event_RoundStart", 2, "0=World triggered", "1=Round_Start")
#else
	if(g_VoiceAll == 1)set_task(420.0,"Task_TellUsers",128,_,_,"b")
#endif	
}

public cmd_SpeakALL(id)
{
	if(g_VoiceAll == 0 || g_VoiceAll == 2 && !(get_user_flags(id) & ADMIN_KICK)) return PLUGIN_HANDLED
#if Only1AtATime == 1	
	if(g_IsSomeoneSpeaking)
	{
		new Name[32]
		get_user_name(g_IsSomeoneSpeaking,Name,31)
		client_print(id,print_chat,"%s is allready speaking",Name)
		return PLUGIN_HANDLED
	}
	g_IsSomeoneSpeaking = id
#endif
	new Name[32]
	get_user_name(id,Name,31)
	client_cmd(id,"+voicerecord")
	if(get_speak(id) != SPEAK_MUTED) set_speak(id,SPEAK_ALL)
	client_print(0,print_chat,"%s is speaking to everyone",Name)
	return PLUGIN_HANDLED
}
public cmd_SpeakALLStop(id)
{
#if Only1AtATime == 1
	if(g_IsSomeoneSpeaking != id) return PLUGIN_HANDLED
	g_IsSomeoneSpeaking = 0	
#endif	
	if(is_user_connected(id))
	{
		client_cmd(id,"-voicerecord")
		if(get_speak(id) != SPEAK_MUTED) set_speak(id,SPEAK_NORMAL)
	}
	return PLUGIN_HANDLED
}

#if MOD == 1
new g_Round
public Event_RoundStart()
{
	if(g_Round == 0)
	{	
		client_print(0,print_chat,"[AMXX] If you want to speak to everyone on the server via voicecom, bind a button to +voiceall")
		g_Round = 5
	}
	else g_Round--
}
#else 
public Task_TellUsers()
{
	client_print(0,print_chat,"[AMXX] If you want to speak to everyone on the server via voicecom, bind a button to +voiceall")
}
#endif