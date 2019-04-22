/*
Maps.ini Generator

About:
This plugin generates maps.ini based on your mapcycle.txt file. It normaly 
generates the file one pr. server startup, but can easly generate a maps.ini 
on every mapchange. This is controled by the cvar amx_genmapsfile

Usage:
Install the plugin like you install any other plugins.
It generates the maps.ini based on what file it finds in the
hlds cvar "mapcyclefile"

Forum topic: http://www.amxmodx.org/forums/viewtopic.php?t=357

Credits:
Got loads of help from all ops in #amxmod @ Quakenet.

Changelog:
 1.1.7 ( 26.05.2004 )
	- Change: Plugin now gets the base dir, instead of having it hard coded

 1.1.6 ( 21.03.2004 )
	- Fixed NS style mapcycle.txt ( Thx to CheesyPeteza for saving me time on this )
	- If the mapcycle file has comments they are no longer read ( line starts with // )
	- Plugin now contains debug code, can be enable by changing the #define
 
 1.1.5 ( 18.03.2004 )
	- Fixed gMapsFile not refering to the configs folder.

 1.1.4 ( 18.03.2004 )
	- Changed gMapsFile to point to the amxx folder instead of amx.

 1.1.3 ( 09.03.2004 )
	- Changed so it uses the AMXmodX include file.

 1.1.2 ( 20.02.2004 )
	- Removed a debug line ( in server console)

 1.1.1 ( 18.02.2004 )
	- InfoR & InfoW no longer registered as a Global
	- Now checks the amx_genmapsfile cvar in plugin_init and check if it has the value -1

 1.1.0 ( 06.02.2004 )
	- No longer generates maps.ini on every mapchange with amx_genmapsfile 1
	- Reads the mapcyclefile cvar to check what file to generate from.
	- Minor code cleanup, should be simpler to read now.

 1.0.0
	- First release

*/
#include <amxmodx> 

#define debug 0

new gMapcyclefile[32]="mapcycle.txt" 		// File it reads from
new gMapsFile[32]="addons/amxx/configs/maps.ini" 	// File it generates from

public plugin_init() { 
	register_plugin("Maps.ini creator","1.1.7","EKS") 
	register_cvar("amx_genmapsfile","1")
	if (get_cvar_num("amx_genmapsfile") == -1)
		return PLUGIN_HANDLED
	
	get_localinfo("amxx_basedir",gMapsFile,31)
	format(gMapsFile,31,"%s/configs/maps.ini",gMapsFile)
	set_task(8.0,"CheckVARS")
	return PLUGIN_CONTINUE
	}

public MakeMapsFile(){ 
	if (file_exists(gMapsFile)) 
	    delete_file(gMapsFile)
	new EndOfFile = 1
	new CurrentLine = 0 
	new InfoR[32],InfoW[32]	
	while(read_file(gMapcyclefile,CurrentLine,InfoR,31,EndOfFile) != 0 ) {
#if debug == 1
		server_cmd("echo [AMX] Maps.ini Gen: Reading %s from %s",InfoR,gMapcyclefile)
#endif
		if (!equal(InfoR,"//",1)) {
			parse(InfoR, InfoR, 127)
#if debug == 1
			server_cmd("echo [AMX] Maps.ini Gen: After parse: %s",InfoR)
#endif
			format(InfoW,32,"%s %s",InfoR,InfoR)
#if debug == 1
			server_cmd("echo [AMX] Maps.ini Gen: Writing| %s to ",InfoW,gMapsFile)
#endif
			write_file(gMapsFile,InfoW,-1)
			}
		CurrentLine = CurrentLine + 1
		}
	return PLUGIN_HANDLED
	}
public CheckVARS(){
	if (get_cvar_num("amx_genmapsfile") == 1) {
		get_cvar_string("mapcyclefile",gMapcyclefile,31)
#if debug == 1
		server_print("AMX is going to generate %s based on %s ( 1 time Generation )  ",gMapsFile,gMapcyclefile)
#endif
		set_cvar_num("amx_genmapsfile",-1)
		MakeMapsFile()
		return PLUGIN_CONTINUE
		}
	if (get_cvar_num("amx_genmapsfile") == 2) {
		get_cvar_string("mapcyclefile",gMapcyclefile,31)
#if debug == 1
		server_print("AMX is going to generate %s based on %s ( Every mapchange )  ",gMapsFile,gMapcyclefile)
#endif
		MakeMapsFile()
		return PLUGIN_CONTINUE
		}
	return PLUGIN_HANDLED
}