/* keypad login
About:
This plugin is used if you want admins to login via code instead of steamid, it also protects the nick of the "admin"

How to use:
Just edit users_keypad.ini
EKS abcdefghijklmnopqrstu 12345 // <First is nick /  seconds is his access rights / this is his code>

Plugin forum thread: http://www.amxmodx.org/forums/viewtopic.php?p=80466

Credits:
Ops in #AMXmodx @ Quakenet for alot of help ( + AssKicker & CheesyPeteza ) 
lille for idea of plugin
*/
#include <amxmodx>

#define MaxAdmins 40
#define CodeLength 5
#define MAXPLAYERS 32
#define BanTime 120.0
#define MaxLoginTries 3
#define VoteTime 30.0

new gs_AdminName[MaxAdmins][32]
new gs_AdminFlags[MaxAdmins][32]
new gs_AdminCode[MaxAdmins][CodeLength+1]
new g_AdminsLoaded	
new gs_CodeEntered[MAXPLAYERS]
new g_User[MAXPLAYERS]
new g_LoginTries[MAXPLAYERS]

public plugin_init()
{
	register_plugin("Keypad login","1.0.0","EKS")
	register_menucmd(register_menuid("\yKeyPad Login:"),1023,"MenuRegisterCode")
	LoadFile()
}
public MenuEnterCode(id)
{ 
	new szMenuBody[151] 
	new len,keys 
// MaxLoginTries
	if(g_LoginTries[id] == 0)
		len = format(szMenuBody,255,"\yKeyPad Login:^n Enter code")
	else
	{
		new TempString[CodeLength+1]
		new L = strlen(gs_CodeEntered[id])
		
		for(new i=0;i<L;++i) TempString[i] = '*'
		
		len = format(szMenuBody,255,"\yKeyPad Login:^n Try %d/%d : %s",g_LoginTries[id],MaxLoginTries,TempString)
	}	
	len += format(szMenuBody[len],150 - len,"^n\w 1. 1") 
	len += format(szMenuBody[len],150 - len,"^n\w 2. 2") 
	len += format(szMenuBody[len],150 - len,"^n\w 3. 3") 
	len += format(szMenuBody[len],150 - len,"^n\w 4. 4") 
	len += format(szMenuBody[len],150 - len,"^n\w 5. 5") 
	len += format(szMenuBody[len],150 - len,"^n\w 6. 6") 
	len += format(szMenuBody[len],150 - len,"^n\w 7. 7") 
	len += format(szMenuBody[len],150 - len,"^n\w 8. 8") 
	len += format(szMenuBody[len],150 - len,"^n\w 9. 9") 
	len += format(szMenuBody[len],150 - len,"^n\w 0. Change nick") 

	keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9) 
	show_menu( id, keys, szMenuBody, -1 ) 
	return PLUGIN_CONTINUE 
}
public MenuRegisterCode(id,key) // Called by ShowReadyMenu
{ 
	new StringLength = strlen(gs_CodeEntered[id])
	if(key <= 8)
	{	
		format(gs_CodeEntered[id],CodeLength+1,"%s%d",gs_CodeEntered[id],key+1)
		if(StringLength == (CodeLength-1)) CheckCode(id)
		else if(StringLength < CodeLength) MenuEnterCode(id)
	}
	else 
	{
		client_cmd(id,"name Player")
		setc(gs_CodeEntered[id],CodeLength+1,0)
	}
	return PLUGIN_CONTINUE
}
stock CheckCode(id)
{
	remove_task(id)
	if(equal(gs_AdminCode[g_User[id]],gs_CodeEntered[id]))
	{
		setc(gs_CodeEntered[id],CodeLength+1,0)
		set_user_flags(id,read_flags(gs_AdminFlags[g_User[id]]))
		
		new Name[32],Auth[35]
		get_user_name(id,Name,31)
		get_user_authid(id,Auth,34)
		
		client_print(0,print_chat,"[AMXX] %s has logged in as a admin",Name)
		log_amx("%s<%s> has logged in as a admin",Name,Auth,gs_CodeEntered[id])
	}
	else
	{
		new Name[32],Auth[35]
		get_user_name(id,Name,31)
		get_user_authid(id,Auth,34)
		log_amx("%s<%s> has entered the wrong code (Code entered: %s)",Name,Auth,gs_CodeEntered[id])
		
		client_print(id,print_chat,"[AMXX] You entered the wrong code (%d/%d tries)",g_LoginTries[id],MaxLoginTries)
		if(g_LoginTries[id] == MaxLoginTries)
		{
			client_print(0,print_chat,"[AMXX] %s has tried to login as a admin, but failed %d in a row and has been banned",Name,g_LoginTries[id])
			server_cmd("kick #%d You entered the wrong code",get_user_userid(id))
			server_cmd("banid %f %s",BanTime,Auth)
		}
		else StartLogin(id,g_User[id])
		
	}
	
}

stock IsAdminNick(Name[32])
{
	for(new i=0;i<=g_AdminsLoaded;i++)	if(equal(Name,gs_AdminName[i]))
	{
		return i
	}
	return 0
}

stock LoadFile()
{
	new AdminFile[128]
	get_localinfo("amxx_basedir",AdminFile,127)
	format(AdminFile,127,"%s/configs/users_keypad.ini",AdminFile)
	if(!file_exists(AdminFile))
	{
		log_amx("%s does not exist, Keypad plugin disabled",AdminFile)
		return PLUGIN_HANDLED
	}
	new CurrentLine,InfoFromFile[128],EndOfFile
	
	while(read_file(AdminFile,CurrentLine,InfoFromFile,127,EndOfFile) != 0 && g_AdminsLoaded<=MaxAdmins) 
	{
		if (!equal(InfoFromFile,"//",1) || !equal(InfoFromFile,";",1)) 
		{
			g_AdminsLoaded++
			parse(InfoFromFile,gs_AdminName[g_AdminsLoaded],31,gs_AdminFlags[g_AdminsLoaded],31,gs_AdminCode[g_AdminsLoaded],CodeLength+1)
			CurrentLine++
		}
	}
	return PLUGIN_CONTINUE 
}
public client_infochanged(id)
{
	if(get_user_flags(id) & ADMIN_KICK || !is_user_connected(id) || task_exists(id,1) || g_User[id] == -1) return PLUGIN_CONTINUE 
		
	new NewName[32],OldName[32]
	get_user_info(id,"name", NewName,31)
	get_user_name(id,OldName,31)
	
	if (!equal(OldName,NewName))
	{
		new IndexOfNick = IsAdminNick(NewName)
		if(IndexOfNick != 0) StartLogin(id,IndexOfNick)

	}
	return PLUGIN_CONTINUE 
}
stock StartLogin(id,IndexOfNick)
{
	remove_task(id)
	set_task(VoteTime,"Task_EndVote",id,_,_,"a",1)
	client_print(id,print_chat,"[AMXX] That nick is restriced, either login or use the menu to change nick")
	
	g_LoginTries[id]++
	g_User[id] = IndexOfNick
	setc(gs_CodeEntered[id],CodeLength+1,0)	
	MenuEnterCode(id)
}
public Task_EndVote(id)
{
	if(!(get_user_flags(id) & ADMIN_KICK))
	{
		new Name[32],Auth[35]
		get_user_name(id,Name,31)
		get_user_authid(id,Auth,34)
		log_amx("%s<%s>has failed to login witin %0.0f seconds",Name,Auth,VoteTime)
		client_print(0,print_chat,"[AMXX] %s has failed to login witin %0.0f seconds",Name,VoteTime)
		server_cmd("kick #%d You failed to enter the code in the due time",get_user_userid(id))
		server_cmd("banid %f %s",BanTime,Auth)
	}
}
public client_putinserver(id)
{
	if(get_user_flags(id) & ADMIN_KICK) return PLUGIN_CONTINUE
	set_task(45.0,"Task_CheckAfterJoin",id,_,_,"a",1)
	return PLUGIN_CONTINUE 	
}
public Task_CheckAfterJoin(id)
{
	new Name[32]
	get_user_name(id,Name,31)
	new IndexOfNick = IsAdminNick(Name)
	
	if(IndexOfNick != 0)
	{
		StartLogin(id,IndexOfNick)
		client_print(id,print_chat,"[AMXX] Your nick is restriced. Starting admin login progress")		
	}
	
}
public client_connect(id) 
{
	g_User[id] = -1
}
public client_disconnect(id) remove_task(id)