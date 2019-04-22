/*CVAR Checker
About:
This plugin checks client side cvars, for illegal values. You can add your own cvars in the .cfg file. If
a bad cvar value is found the user is presented with a menu where he can select updating the cvar to a accetable value or leave.

Requires amxmodx 1.60

FAQ)
Q) Can i only log offenses instead of public say and menu?
A) Check the LogOnly #define

Credits:
Ops in #AMXmod @ Quakenet for alot of help ( + AssKicR & CheesyPeteza ) 
*/

#include <amxmodx>
#include <engine>

#define debug 0
#define MAXPLAYERS 32
#define MAX_CVARS 128
#define Delay_start 20.0
#define Delay_restart 60.0
#define Menu_time 15


#define USE_MENU 1

#define CVAR_EQUALS 	0
#define CVAR_BIGER 	1
#define CVAR_SMALLER	2
#define CVAR_OTHERTHEN	3

#define LogOnly		0

new g_CvarsInList
new gs_CvarName[MAX_CVARS][32]
new g_CvarRule[MAX_CVARS]
new Float:gf_CvarBadValue[MAX_CVARS]
new Float:gf_CvarDefaultValue[MAX_CVARS]
new g_LastCvarChecked[MAXPLAYERS+1]
new g_MenuTimer[MAXPLAYERS+1]

new gs_LogFile[128]


public plugin_init() 
{
	register_plugin("CVAR Checker","1.0.1","EKS")
	
	//g_MaxPlayers = get_maxplayers()
	
	//register_srvcmd("hlg_conncommand","CmdConnCommand",ADMIN_RCON," - Mimics the hlg_conncommand HLGuard command")
	register_srvcmd("amx_checkcvar","CmdCheckCVAR",ADMIN_RCON," - Mimics the hlg_conncommand HLGuard command")
	
#if USE_MENU == 1
	register_menucmd(register_menuid("\yUpdate CVAR:"),1023,"Menu_UpdateCVAR")
#endif
	LoadConfigFile()
}
public CmdCheckCVAR()
{
	new ArgInfo[128],CvarName[32],sCvarBadValue[8],sCvarDefaultValue[8]
	//read_argv(1,ArgInfo,63)
	read_args(ArgInfo,127)

	
	parse(ArgInfo,CvarName,31,sCvarBadValue,7,sCvarDefaultValue,7)
	//gf_CvarBadValue[g_CvarsInList] 
	
	if(strlen(CvarName) == 0 || strlen(sCvarBadValue) == 0 || strlen(sCvarDefaultValue) == 0 || !GetCvarOption(sCvarBadValue[0],g_CvarsInList))
	{
		server_print("Bad listing in config file on cvar %s",CvarName)
		return PLUGIN_CONTINUE
	}
	sCvarBadValue[0] = '0'
	
	copy(gs_CvarName[g_CvarsInList],31,CvarName)
	gf_CvarBadValue[g_CvarsInList] = floatstr(sCvarBadValue)
	gf_CvarDefaultValue[g_CvarsInList] = floatstr(sCvarDefaultValue)

#if debug == 1
	server_print("CVAR Checker Debug - %s rule: %d BadValue: %.2f Def. Value: %.2f (%s)",gs_CvarName[g_CvarsInList],g_CvarRule[g_CvarsInList],gf_CvarBadValue[g_CvarsInList],gf_CvarDefaultValue[g_CvarsInList],sCvarBadValue)
#endif
	g_CvarsInList++
	return PLUGIN_CONTINUE
}
public CmdConnCommand()
{
	new CvarValueString[8],ArgInfo[64]
	read_argv(1,ArgInfo,63)
	
	remove_quotes(ArgInfo)
	
	parse(ArgInfo,gs_CvarName[g_CvarsInList],31,CvarValueString,7)
	gf_CvarBadValue[g_CvarsInList] = floatstr(CvarValueString)
	
	
	
#if debug == 1
	server_print("CVAR Checker Debug - %s accetable value %.2f (%s - Cvars in list: %d)",gs_CvarName[g_CvarsInList],gf_CvarBadValue[g_CvarsInList],ArgInfo,g_CvarsInList)
#endif
	g_CvarsInList++
}
#if USE_MENU == 1
public Task_ReShowMenu(id)
{
	g_MenuTimer[id]--
	if(g_MenuTimer[id] == 0)
	{
		new Name[32],Authid[35],LogD[128]
		get_user_name(id,Name,31)
		get_user_authid(id,Authid,34)
	
		client_print(0,print_chat,"CVAR Checker - %s did not make a choice in the menu and was kicked",Name)
		server_cmd("kick #%d Bad Cvar value, and no selection in menu",get_user_userid(id))	
		
		format(LogD,127,"%s<%s> did not make a choice in the menu and was kicked",Name,Authid)
		LogOffense(LogD)		
	}
	else
		Menu_ShowCVARMenu(id)
}

public Menu_UpdateCVAR(id,key)
{
	new Name[32],Authid[35],LogD[128]
	get_user_name(id,Name,31)
	get_user_authid(id,Authid,34)
	
	new CvarIndex = g_LastCvarChecked[id]
	
	if(key == 0) // selected update cvar
	{
		remove_task(id)
		client_print(0,print_chat,"CVAR Checker - %s chose to update his %s cvar",Name,gs_CvarName[CvarIndex])
		format(LogD,127,"%s<%s> chose to update his %s cvar",Name,Authid,gs_CvarName[CvarIndex])
		LogOffense(LogD)
		
		client_cmd(id,"%s %f",gs_CvarName[CvarIndex],gf_CvarDefaultValue[CvarIndex])
		CheckNextCvar(id)
	}
	else if(key == 1)// selected being kicked
	{
		remove_task(id)
		client_print(0,print_chat,"CVAR Checker - %s did not want to update %s and was kicked",Name,gs_CvarName[CvarIndex])
		server_cmd("kick #%d chose to be kicked",get_user_userid(id))	
		
		format(LogD,127,"%s<%s> chose to update his %s cvar",Name,Authid,gs_CvarName[CvarIndex])
		LogOffense(LogD)
	}
	else	// Made a wrong selection
		Menu_ShowCVARMenu(id)

	return PLUGIN_CONTINUE
}
public Menu_ShowCVARMenu(id)
{ 
#if debug == 1
	server_print("CvarName: %s : Id: %d LastIndex: %d",gs_CvarName[g_LastCvarChecked[id]],id,g_LastCvarChecked);
#endif
	new szMenuBody[151] 
	new len,keys 
	len = format(szMenuBody,255,"\yUpdate CVAR:^n %s has a illegal value, update it? (%d sec left)",gs_CvarName[g_LastCvarChecked[id]],g_MenuTimer[id])
	len += format(szMenuBody[len],150 - len,"^n\w 1. Yes") 
	len += format(szMenuBody[len],150 - len,"^n\w 2. No (Will be kicked)") 


	keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9) 
	show_menu( id, keys, szMenuBody, -1 ) 
	return PLUGIN_CONTINUE 
}
#endif

public client_putinserver(id)
{
	g_LastCvarChecked[id] = -1			// we set it to -1 since the CheckNextCvar() increases it to one
	if(!is_user_bot(id) && !is_user_hltv(id) && g_CvarsInList != 0)
	{
		set_task(Delay_start,"Task_DelayCvarCheck",id,_,_,"a",1)
	}
}
public client_disconnect(id)
{
	if(task_exists(id))
		remove_task(id)
}
public cvar_result_func(id,const cvar[],const value[])
{
	new Float:CvarValue= floatstr(value)
	new Index = g_LastCvarChecked[id]		// Save the index, for simplisity
	
	if(CheckCvarAgainstRule(CvarValue,gf_CvarBadValue[Index],g_CvarRule[Index]))
	{
	
		new Name[32],Authid[35],LogD[128]
		get_user_name(id,Name,31)
		get_user_authid(id,Authid,34)
		
		format(LogD,127,"%s<%s> had a illegal cvar value: %s (Bad value: %.2f New value: %.2f)",Name,Authid,cvar,CvarValue,gf_CvarBadValue[Index])
		LogOffense(LogD)
#if LogOnly == 0
		client_print(0,print_chat,"CVAR Checker - %s<%s> has a illegal cvar  value ( %s had the value %.2f )",Name,Authid,cvar,CvarValue)
		
		g_MenuTimer[id] = Menu_time		// We set the time the user has to make a selection in the menu
		Menu_ShowCVARMenu(id)
		set_task(1.0,"Task_ReShowMenu",id,_,_,"b")
#endif
	}
	else
	{
#if debug == 1
		client_print(id,print_chat,"%d)Cvar Checker - %s value %.2f",Index,cvar,CvarValue)
#endif
		if(g_CvarsInList > g_LastCvarChecked[id])
			CheckNextCvar(id)
		else
		{
			set_task(Delay_restart,"Task_DelayCvarCheck",id,_,_,"a",1)
		}
	}
}


public Task_DelayCvarCheck(id)
{
	g_LastCvarChecked[id] = -1
	CheckNextCvar(id)
}
stock CheckCvarAgainstRule(Float:CvarValue,Float:CvarBadValue,Rule)
{
	if(Rule == CVAR_EQUALS)
	{
		if(CvarValue == CvarBadValue)
			return 1
		else 
			return 0
	}
	else if(Rule == CVAR_BIGER)
	{
		if(CvarValue > CvarBadValue)
			return 1
		else 
			return 0		
	}
	else if(Rule == CVAR_SMALLER)
	{
		if(CvarValue < CvarBadValue)
			return 1
		else 
			return 0		
	}
	else if(Rule == CVAR_OTHERTHEN)
	{
		if(CvarValue != CvarBadValue)
			return 1
		else 
			return 0		
	}
	return 0
}
stock GetCvarOption(CvarOption[],CvarIndex)		// Converts the String text into a Int in the g_CvarRule
{
	if(CvarOption[0] == '=')
		g_CvarRule[CvarIndex] = CVAR_EQUALS
	else if(CvarOption[0] == '>')
		g_CvarRule[CvarIndex] = CVAR_BIGER
	else if(CvarOption[0] == '<')
		g_CvarRule[CvarIndex] = CVAR_SMALLER
	else if(CvarOption[0] == '!')
		g_CvarRule[CvarIndex] = CVAR_OTHERTHEN
	else return -1
	
	return 1
}
stock CheckNextCvar(id)
{
	g_LastCvarChecked[id]++
	if(g_LastCvarChecked[id] == g_CvarsInList)
		g_LastCvarChecked[id] = 0
	
	query_client_cvar(id,gs_CvarName[g_LastCvarChecked[id]],"cvar_result_func")
}
stock LoadConfigFile()
{
	new File[128]
	get_localinfo("amxx_basedir",File,127)
	format(File,127,"%s/configs/cvar_list.cfg",File)
	server_print("Loading Cvar checking Config file")
	server_cmd("exec %s",File)
	
	get_localinfo("amxx_basedir",gs_LogFile,127)
	new Date[20]
	get_time("%d-%m-%Y",Date,19)
	format(gs_LogFile,127,"%s/logs/cvar_%s.log",gs_LogFile,Date)
}

stock LogOffense(LogEntry[])
{
	new FullEntry[160]
	get_time("%H:%M:%S - ",FullEntry,11)
	add(FullEntry,159,LogEntry)
	server_print(FullEntry)
	write_file(gs_LogFile,FullEntry)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
