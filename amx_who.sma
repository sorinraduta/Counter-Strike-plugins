#include <amxmodx>
#include <amxmisc>

#pragma semicolon 1

#define MAX_GROUPS 8
#define MAX_ADMINS 9

static const PLUGIN[ ]		= "AMX WHO";
static const VERSION[ ]		= "1.0";
static const AUTHOR[ ]		= "Rap";


new g_szRangs[MAX_GROUPS][ ] =
{
	"Owners",
	"Co-owners",
	"Gods",
	"Moderators",
	"Administrators",
	"Helpers",
	"VIPs",
	"Slots"
};
new g_szFlags[MAX_GROUPS][ ] =
{
	"abcdefghijklmnopqrstu",
	"abcdefgijkmnopqrstu",
	"abcdefijmnopqrst",
	"bcdefijmopst",
	"bcdefijmot",
	"bceiot",
	"ab",
	"b"
};
new g_szAdmins[MAX_ADMINS][ ] =
{
	"Rappy O.o-",
	"sPuf ?",
	"Askhanar",
	"AZAEL !",
	"gLobe",
	"TheBeast",
	"Only",
	"fuzy",
};

new g_szFlagsValue[MAX_GROUPS];

public plugin_init( )
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_concmd("amx_who", "cmdWho", 0);
	register_concmd("admin_who", "cmdWho", 0);

	register_clcmd("say /who","cmdGoWho");
	register_clcmd("say /admin","cmdGoWho");
	register_clcmd("say /admins","cmdGoWho");

	for( new i = 0; i < MAX_GROUPS; i++ )
		g_szFlagsValue[i] = read_flags(g_szFlags[i]);
}
public cmdGoWho(id)
{
	client_cmd(id, "toggleconsole");
	cmdWho(id);

	return PLUGIN_HANDLED;
}
public cmdWho(id)
{
	console_print(id, "----- LISTA ADMINI -----");

	for( new i = 0; i < MAX_GROUPS; i++ )
	{
		console_print(id, "-----[%d]%s-----", i+1, g_szRangs[i]);

		for( new a = 0; a < MAX_ADMINS; a++ )
		{
			new target = cmd_target(id, g_szAdmins[a], 1);

			if(get_user_flags(target) == g_szFlagsValue[i])
			{
				console_print(id, "%s (%s)", get_name(target), is_user_connected(target) ? "ONLINE":"OFFLINE");
			}
		}
	}

	console_print(id, "----- LISTA ADMINI -----");

	return PLUGIN_HANDLED;
}
stock get_name(id)
{
	new szName[32];
	get_user_name(id, szName, sizeof szName -1);

	return szName;
}
