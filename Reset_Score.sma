#include <amxmodx>
#include <cstrike>
#include <fun>

#pragma semicolon 1

static const PLUGIN[ ]		= "Reset Score";
static const VERSION[ ]		= "1.0";
static const AUTHOR[ ]		= "Rap^^";

new reset_tag;


public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say /resetscore", "cmdResetScore");
	register_clcmd("say /restartscore", "cmdResetScore");
	register_clcmd("say /rs", "cmdResetScore");

	reset_tag = register_cvar("reset_tag", "[ResetScore]");
}
public reset_score(id)
{
	cs_set_user_deaths(id, 0);
	set_user_frags(id, 0);
	cs_set_user_deaths(id, 0);
	set_user_frags(id, 0);

	client_print(id, print_chat, "%s Scorul tau a fost resetat.", tag( ));
}
stock tag( )
{
	new szTag[32];
	get_pcvar_string(reset_tag, szTag, sizeof szTag -1);

	return szTag;
}
