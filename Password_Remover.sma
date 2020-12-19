#include <amxmodx>
#include <ColorChat>

#define PLUGIN "Password Remover"
#define VERSION "1.0"
#define KEYS ((1<<0) | (1<<1))
//								(c) 2012 www.disconnect.ro
#pragma semicolon 1

new cvar_toggle, cvar_tag;
new bool:VoteEnded = true, bool:YesAdded[32] = false;
new VOT_REMOVE;
new Yes, No;
new AddYes;
new sv_password;
new discname[32];

new const say_cmds[][] =
{
	"say /removepassword", "cmdAddYes",
	"say_team /removepassword", "cmdAddYes",
	"say /removepass", "cmdAddYes",
	"say_team /removepass", "cmdAddYes",
	"say /rp", "cmdAddYes",
	"say_team /rp", "cmdAddYes",
	"say /vote", "RemoveMenu"
};
//								(c) 2012 www.disconnect.ro
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Rap");
	
	cvar_toggle = register_cvar("pr_toggle", "1");
	cvar_tag = register_cvar("pr_tag", "[Password Auto-Remover]");
	VOT_REMOVE = register_menuid("VOT_REMOVE");
	register_menucmd(VOT_REMOVE, KEYS, "actionVote");
	for(new i = 0; i < sizeof(say_cmds); i += 2)
		register_clcmd(say_cmds[i], say_cmds[i+1]);
		
	sv_password = get_cvar_pointer("sv_password");
}
//								(c) 2012 www.disconnect.ro
public client_disconnect(id)
{
	new pass[32];
	get_pcvar_string(sv_password, pass, sizeof pass -1);

	if(get_pcvar_num(cvar_toggle) != 1 || equal(pass,"") )
	{
		return PLUGIN_HANDLED;
	}
	
	if(get_user_flags(id) & ADMIN_CVAR)
	{
		set_task(1.0,"CheckPlayers");
	}
	get_user_name(id, discname, sizeof discname -31);
	//YesAdded[id] = false;
	
	return PLUGIN_CONTINUE;
}
//
public client_connect(id)
{
	new conname[32];
	get_user_name(id, conname, sizeof conname -31);
	
	if(equal("conname", "discname"))
	{
		YesAdded[id] = true;
	}
	else YesAdded[id] = false;
	
	return PLUGIN_CONTINUE;
}
//								(c) 2012 www.disconnect.ro								(c) 2012 www.disconnect.ro
public CheckPlayers()
{
	if(get_pcvar_num(cvar_toggle) != 1)
	{
		return PLUGIN_HANDLED;
	}
	
	new PlayersNum, Players[32];
	new FoundPlayers = 0,AdminFound = 0;
	
	get_players(Players, PlayersNum, "ch");
	
	for(new i = 0; i < PlayersNum; i++)
	{
		if(get_user_flags(Players[i]) & ADMIN_CVAR)
		{
			AdminFound++;
		}
		else if(is_user_connected(Players[i]))
		{
			
			FoundPlayers++;
		}
	}
	if(FoundPlayers >= 1 && AdminFound == 0)
	{
		RemoveMenu();
		return PLUGIN_HANDLED;
	}
	else if( FoundPlayers <= 0 )
	{
	
		RemovePassword();
	}
	
	return PLUGIN_CONTINUE;
}
//								(c) 2012 www.disconnect.ro
public RemoveMenu()
{
	new PlayersNum, Players[32];
	
	get_players(Players, PlayersNum, "ch");
	
	new szMenu[1024], n;

	n = formatex(szMenu, 1023, "\rRemove Password Vote^n^n\yDoriti ca parola sa fie scoasa?^n^n");

	n += formatex(szMenu[n], 1023-n, "\w1. Da^n");

	n += formatex(szMenu[n], 1023-n, "2. Nu^n^n^n\rwww.disconnect.ro");
	
	for(new i = 0; i < PlayersNum; i++)
	{
		show_menu(Players[i], KEYS, szMenu, -1, "VOT_REMOVE");
	}
	
	new tag[32];
	get_pcvar_string(cvar_tag, tag, sizeof tag -1);
	
	ColorChat(0, GREEN, "%s^x01 Acum, nimeni, de pe server, nu mai are acces la^x03 scoaterea parolei^x01 !", tag);
	VoteEnded = false;

	set_task(10.0, "EndVot");
}
//								(c) 2012 www.disconnect.ro
public actionVote(id, key)
{
	new tag[32], name[32];
	get_pcvar_string(cvar_tag, tag, sizeof tag -1);
	get_user_name(id, name, sizeof name -1);
	
	switch(key)
	{
		case 0:
		{
			if(VoteEnded)
			{
				ColorChat(id, GREEN, "%s^x01 Votul s-a incheiat deja.", tag);
				return PLUGIN_HANDLED;
			}
			ColorChat(0, GREY, "^x04%s^x03 %s^x01 a votat^x03 pentru !", tag, name);
			Yes++;
			return PLUGIN_HANDLED;
		}
		case 1:
		{
			if(VoteEnded)
			{
				ColorChat(id, GREEN, "%s^x01 Votul s-a incheiat deja.", tag);
				return PLUGIN_HANDLED;
			}
			ColorChat(0, GREY, "^x04%s^x03 %s^x01 a votat^x03 impotriva !", tag, name);
			No++;
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}
//								(c) 2012 www.disconnect.ro
public EndVot()
{
	if(get_pcvar_num(cvar_toggle) != 1 || VoteEnded)
	{
		return PLUGIN_HANDLED;
	}
	
	new tag[32];
	get_pcvar_string(cvar_tag, tag, sizeof tag -1);
	
	if(Yes > No)
	{
		ColorChat(0, GREY, "^x04%s^x01 Votul a luat sfarsit. Parola v-a fi scoasa. (^x03%d Da^x01) (^x03%d Nu^x01)",tag, Yes, No);
		RemovePassword();
	}
	else
	{
		ColorChat(0, GREY, "^x04%s^x01 Votul a luat sfarsit. Parola nu v-a fi scoasa. (^x03%d Da^x01) (^x03%d Nu^x01)",tag, Yes, No);
	}
	Yes = 0;
	No = 0;
	
	VoteEnded = true;
	return PLUGIN_CONTINUE;
}
//								(c) 2012 www.disconnect.ro
public RemovePassword()
{
	if(get_pcvar_num(cvar_toggle) != 1)
	{
		return PLUGIN_HANDLED;
	}
	
	new tag[32];
	get_pcvar_string(cvar_tag, tag, sizeof tag -1);
	
	set_pcvar_string(sv_password, "");
	ColorChat(0, GREEN, "%s^x01 Parola a fost scoasa cu succes !", tag);
	
	return PLUGIN_HANDLED;
}
//								(c) 2012 www.disconnect.ro
public cmdAddYes(id)
{
	if(get_pcvar_num(cvar_toggle) != 1)
	{
		return PLUGIN_HANDLED;
	}
	
	new tag[32], pass[32];
	
	get_pcvar_string(cvar_tag, tag, sizeof tag -1);
	get_pcvar_string(sv_password, pass, sizeof pass -1);
	if(equal(pass,""))
	{
		ColorChat(id, GREEN, "%s^x01 Nu este nicio parola pe server.", tag);
		return PLUGIN_HANDLED;
	}
	
	new PlayersNum, Players[32];
	
	get_players(Players, PlayersNum, "ch");
	
	for(new i = 0; i < PlayersNum; i++)
	{
		if(get_user_flags(Players[i]) & ADMIN_CVAR)
		{
			ColorChat(id, GREY, "^x04%s^x01 Nu poti folosi aceasta comanda, cand pe server se afla un^x03 admin^x01 cu^x03 acces^x01 la scoaterea^x03 parolei^x01.", tag);
			return PLUGIN_HANDLED;
		}
	}
	if(!YesAdded[id])
	{
		AddYes++;
		YesAdded[id] = true;
		ColorChat(id, GREY, "^x04%s Tocmai ai votat pentru scoaterea parolei. Voturi necesare: (^x03%d^x01)", tag, PlayersNum);
	}
	if(AddYes == PlayersNum)
	{
		RemovePassword();
		ColorChat(0, GREEN, "%s^x01 Toti jucatorii au votat pentru scoaterea parolei.", tag);
		
		new PlayersNum2, Players2[32];
	
		get_players(Players2, PlayersNum2, "ch");
		
		for(new i = 0; i < PlayersNum2; i++)
		{
			YesAdded[Players2[i]] = false;
		}
	}
	return PLUGIN_HANDLED;
}
//								(c) 2012 www.disconnect.ro
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
