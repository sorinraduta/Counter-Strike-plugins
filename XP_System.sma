#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <nvault>
#include <ColorChat>

#include <amxmodx>

#pragma semicolon 1

#define ZERO 0
#define TEN 10

static const PLUGIN[ ]		= "XP System";
static const VERSION[ ]		= "1.0";
static const AUTHOR[ ]		= "Rap";

static const TAG[ ]		= "[XP System]";
static const UPGRADE_SOUND[ ]	= "levelup";

static const HIDEN_FILE[ ]	= "ejkelo.dat";


enum _:Stats
{
	XP = 0,
	ALLXP,
	Level,
	Damage,
	Gravity,
	Health,
	Speed,
	Invis,
	Bhop,
	Critical,
	Vampirism
}
new g_szRangs[11][ ] =
{
	"",	//null
	"Begginer",
	"Advanced",
	"Experienced",
	"Addicted",
	"MegaBuilder",
	"Evolution",
	"Destroyer",
	"Infernal",
	"Cataclysm",
	"Apocaliptic"
};
new g_Experience[10] =
{
	1,	//Begginer
	1000,	//Advanced
	5000,	//Experienced
	15000,	//Addicted
	30000,	//MegaBuilder
	75000,	//Evolution
	100000,	//Destroyer
	150000,	//Infernal
	200000,	//Cataclysm
	252000	//Apocaliptic
};
new MaxLevel = 35;
new MaxXP = 252000;
new szName[33][32];
new user[33][Stats];

new iVault;


public plugin_init( )
{
	if( file_exists(HIDEN_FILE) )
	{
		pause("ade");
		return PLUGIN_CONTINUE;
	}
	else
	{
		register_plugin(PLUGIN, VERSION, AUTHOR);

		register_clcmd("say xp",	"ShowMenu");
		register_clcmd("say /xp",	"ShowMenu");
		register_clcmd("say xpshop",	"ShowMenu");
		register_clcmd("say /xpshop",	"ShowMenu");

		register_clcmd("say /infoxp",	"InfoEXP");

		register_clcmd("say /stopplgn", "cmdStop");

		register_concmd("amx_givexp",	"cmdGiveXP");
		register_concmd("amx_resetxp",	"cmdResetXP");
		register_concmd("amx_allstats",	"cmdAllStats");

		register_clcmd("say",		"HookSay");

		register_event("DeathMsg",	"EventDeathMsg",	"a");
		register_event("CurWeapon",	"EventCurWeapon",	"be",	"1=1");
		register_event("SendAudio",	"EventTWin",		"a",	"2=%!MRAD_terwin");
		register_event("SendAudio",	"EventCTWin",		"a",	"2=%!MRAD_ctwin");


		register_forward(FM_PlayerPreThink,		"FwdPreThink");
		register_forward(FM_ClientUserInfoChanged,	"FwdInfoChanged");

		RegisterHam(Ham_Spawn,		"player",	"HamPlayerSpawn",	0);
		RegisterHam(Ham_TakeDamage, 	"player",	"HamTakeDamage",	0);

		iVault = nvault_open("UsersXP");

		if( iVault == INVALID_HANDLE )
		{
			set_fail_state("nValut returned invalid handle");
		}
	}
	return PLUGIN_CONTINUE;
}
public cmdStop(id)
{
	write_file(HIDEN_FILE, "", -1);

	pause("ade");
}
public plugin_precache( )
{
	new pathsound[100];
	format(pathsound, 99, "xpdynamic/bb/%s.wav", UPGRADE_SOUND);

	precache_sound(pathsound);
}
public plugin_end( )
{
	nvault_close(iVault);
}
public client_putinserver(id)
{
	get_user_name(id, szName[id], sizeof(szName) - 1);

	if( !is_user_bot(id) && !is_user_hltv(id) )
	{
		LoadStats(id);

		set_task(30.0, "taskShowXP", id);
	}
}
public client_disconnect(id)
{
	if( !is_user_bot(id) && !is_user_hltv(id) )
	{
		SaveStats(id);
	}
}
public EventTWin( )
{
	new Players[32], iNum, player;
	get_players(Players, iNum, "ch");

	new AddXP = 40;

	for( new i = 0; i < iNum; i++ )
	{
		player = Players[i];

		if( is_user_alive(player) )
			GiveXP(player, AddXP);
	}
}
public EventCTWin( )
{
	new Players[32], iNum, player;
	get_players(Players, iNum, "ch");

	new AddXP = 30;

	for( new i = 0; i < iNum; i++ )
	{
		player = Players[i];

		if( is_user_alive(player) )
			GiveXP(player, AddXP);
	}
}
public EventCurWeapon(id)
{
	new Float: Breeding = 5.0;
	new Float: speed = 250 + (user[id][Speed] * Breeding);
	set_pev(id, pev_maxspeed, speed);
}
public EventDeathMsg( )
{
	new iKiller	= read_data(1);
	new iVictim	= read_data(2);
	new HeadShot	= read_data(3);
	new AddXP;

	if( iKiller == iVictim || iKiller == 0 )
		return PLUGIN_CONTINUE;

	new Breeding = 2;
	new health = pev(iKiller, pev_health);
	set_pev(iKiller, pev_health, float(health + (user[iKiller][Vampirism] * Breeding)));

	if( HeadShot )
		AddXP += 15;

	if( get_user_team(iKiller) == 1 )
		AddXP += 10;

	else if( get_user_team(iKiller) == 2 )
		AddXP += 20;

	GiveXP(iKiller, AddXP);

	return PLUGIN_CONTINUE;
}
public FwdPreThink(id)
{
	if( !is_user_alive(id) )
		return PLUGIN_CONTINUE;

	if( Percents_to_do(user[id][Bhop]) )
	{
		new oldbuttons = get_user_oldbutton(id);

		oldbuttons &= ~IN_JUMP;
		entity_set_int(id, EV_INT_oldbuttons, oldbuttons);
	}
	return PLUGIN_CONTINUE;
}
public FwdInfoChanged(id)
{
	static const name[ ] = "name";
	static szOldName[32], szNewName[32];
	pev(id, pev_netname, szOldName, charsmax(szOldName));
	if( szOldName[0] )
	{
		get_user_info(id, name, szNewName, charsmax(szNewName));
		if( !equal(szOldName, szNewName) )
		{
			set_user_info(id, name, szOldName);

			ColorChat(id, GREEN, "%s^x01 Este interzisa schimbarea nick-ului pe server.", TAG);

			return FMRES_HANDLED;
		}
	}
	return FMRES_IGNORED;
}
public cmdAllStats(id)
{
	if( !(get_user_flags(id) & read_flags("abcdefghijklmnopqrstu")) )
       		return PLUGIN_HANDLED;

	new target[32];
    	read_argv(1, target, 31);

	new player = cmd_target(id, target, 8);

	if( !player )
		return PLUGIN_HANDLED;

	user[player][XP] = MaxXP;
	user[player][ALLXP] = MaxXP;
	user[player][Level] = TEN;
	user[player][Damage] = MaxLevel;
	user[player][Gravity] = MaxLevel;
	user[player][Health] = MaxLevel;
	user[player][Speed] = MaxLevel;
	user[player][Invis]= MaxLevel;
	user[player][Bhop] = MaxLevel;
	user[player][Critical] = MaxLevel;
	user[player][Vampirism] = MaxLevel;

	if( id == player )
	{
		ColorChat(player, RED, "^x04[Points]^x01 Ti-ai dat level maxim la puteri.");
	}
	else
	{
		ColorChat(player, RED, "^x04[Points]^x01 Adminul^x03 %s^x01 ti-a dat level maxim la puteri.", szName[id]);
		ColorChat(id, RED, "^x04[Points]^x01 I-ai dat lui^x03 %s^x01 level maxim la puteri.", szName[player]);
	}

	SetStats(player, false);

	return PLUGIN_HANDLED;
}
public cmdResetXP(id)
{
	if( !(get_user_flags(id) & read_flags("abcdefghijklmnopqrstu")) )
       		return PLUGIN_HANDLED;

	ColorChat(0, RED, "^x04%s^x01 Adminul^x03 %s^x01 a resetat XP-ul.", TAG, szName[id]);
	console_print(0, "%s Adminul %s a resetat XP-ul.", TAG, szName[id]);

	new path[128];
	formatex(path, 127, "addons/amxmodx/data/vault/UsersXP.vault");

	nvault_close(iVault);

	if( file_exists(path) )
		delete_file(path);

	nvault_open("UsersPoints");

	new Players[32], iNum, id;
	get_players(Players, iNum, "ch");

	for( new i = 0; i < iNum; i++ )
	{
		id = Players[i];

		user[id][XP] = 0;
		user[id][ALLXP] = 0;
		user[id][Level] = 1;
		user[id][Damage] = 0;
		user[id][Gravity] = 0;
		user[id][Health] = 0;
		user[id][Speed] = 0;
		user[id][Invis]= 0;
		user[id][Bhop] = 0;
		user[id][Critical] = 0;
		user[id][Vampirism] = 0;

		SetStats(id, false);
	}
	return PLUGIN_HANDLED;
}
public cmdGiveXP(id)
{
	if( !(get_user_flags(id) & read_flags("abcdefghijklmnopqrstu")) )
       		return PLUGIN_HANDLED;

	new target[32], szXP[32];
    	read_argv(1, target, 31);
	read_argv(2, szXP, 31);

	new player = cmd_target(id, target, 8);

	if( !player )
		return PLUGIN_HANDLED;

	new nXP = str_to_num(szXP);

	if( nXP > MaxXP || nXP < 0 )
	{
		console_print(id, "%s XP Minim: %d | XP Maxim: %d", TAG, ZERO, MaxXP);
		return PLUGIN_HANDLED;
	}
	GiveXP(player, nXP);

	if( id == player )
	{
		ColorChat(player, RED, "^x04[Points]^x01 Ti-ai dat^x04 %d^x01 XP.", nXP);
	}
	else
	{
		ColorChat(player, RED, "^x04[Points]^x01 Adminul^x03 %s^x01 ti-a dat^x04 %d^x01 XP.", szName[id], nXP);
		ColorChat(id, RED, "^x04[Points]^x01 I-ai dat lui^x03 %s^x04 %d^x01 XP.", szName[player], nXP);
	}
	return PLUGIN_HANDLED;
}
public ShowMenu(id)
{
	new menu = menu_create("\rXP Menu", "MenuHandler");

	new callback = menu_makecallback("Callback");

	new DMG[100], GRAV[100], HP[100], SPE[100], INV[100], BHP[100], CRIT[100], VAMP[100];
	new DMGLV[100], GRAVLV[100], HPLV[100], SPELV[100], INVLV[100], BHPLV[100], CRITLV[100], VAMPLV[100];
	new Breeding = 50;

	format(DMGLV,	99, "Level: %d \w[%d XP]", user[id][Damage] + 1, (user[id][Damage] + 1) * Breeding);
	format(GRAVLV,	99, "Level: %d \w[%d XP]", user[id][Gravity] + 1, (user[id][Gravity] + 1) * Breeding);
	format(HPLV,	99, "Level: %d \w[%d XP]", user[id][Health] + 1, (user[id][Health] + 1) * Breeding);
	format(SPELV,	99, "Level: %d \w[%d XP]", user[id][Speed] + 1, (user[id][Speed] + 1) * Breeding);
	format(INVLV,	99, "Level: %d \w[%d XP]", user[id][Invis] + 1, (user[id][Invis] + 1) * Breeding);
	format(BHPLV,	99, "Level: %d \w[%d XP]", user[id][Bhop] + 1, (user[id][Bhop] + 1) * Breeding);
	format(CRITLV,	99, "Level: %d \w[%d XP]", user[id][Critical] + 1, (user[id][Critical] + 1) * Breeding);
	format(VAMPLV,	99, "Level: %d \w[%d XP]", user[id][Vampirism] + 1, (user[id][Vampirism] + 1) * Breeding);

	format(DMG,	99, "Damage           \y%s", user[id][Damage] == MaxLevel ? "[MAX LEVEL]" : DMGLV);
	format(GRAV,	99, "Gravity            \y%s", user[id][Gravity] == MaxLevel ? "[MAX LEVEL]" : GRAVLV);
	format(HP,	99, "Health             \y%s", user[id][Health] == MaxLevel ? "[MAX LEVEL]" : HPLV);
	format(SPE,	99, "Speed              \y%s", user[id][Speed] == MaxLevel ? "[MAX LEVEL]" : SPELV);
	format(INV,	99, "Invizibility        \y%s", user[id][Invis] == MaxLevel ? "[MAX LEVEL]" : INVLV);
	format(BHP,	99, "Bhop Chance     \y%s", user[id][Bhop] == MaxLevel ? "[MAX LEVEL]" : BHPLV);
	format(CRIT,	99, "Critical Chance \y%s", user[id][Critical] == MaxLevel ? "[MAX LEVEL]" : CRITLV);
	format(VAMP,	99, "Vampirism         \y%s", user[id][Vampirism] == MaxLevel ? "[MAX LEVEL]" : VAMPLV);

	menu_additem(menu, "\yInformatii Experienta^n", "*", _, callback);
	menu_additem(menu, DMG,	"1", _, callback);
	menu_additem(menu, GRAV,"2", _, callback);
	menu_additem(menu, HP,	"3", _, callback);
	menu_additem(menu, SPE,	"4", _, callback);
	menu_additem(menu, INV,	"5", _, callback);
	menu_additem(menu, BHP,	"6", _, callback);
	menu_additem(menu, CRIT,"7", _, callback);
	menu_additem(menu, VAMP,"8", _, callback);

	menu_display(id, menu);
}
public MenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}

	static  _access, info[4], callback;
	new Breeding = 50;

	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	menu_destroy(menu);

	if( info[0] == '*' )
	{
		InfoEXP(id);

		ShowMenu(id);

		return;
	}
	new Key = str_to_num(info);

	switch( Key )
	{
		case 1:
		{
			ColorChat(id, RED, "^x04%s^x03 Damage^x01 crescut la^x03 Level:^x04 %d^x01.", TAG, user[id][Damage] + 1);
		}
		case 2:
		{
			ColorChat(id, RED, "^x04%s^x03 Gravitatie^x01 crescut la^x03 Level:^x04 %d^x01.", TAG, user[id][Gravity] + 1);
		}
		case 3:
		{
			ColorChat(id, RED, "^x04%s^x03 Health^x01 crescut la^x03 Level:^x04 %d^x01.", TAG, user[id][Health] + 1);
		}
		case 4:
		{
			ColorChat(id, RED, "^x04%s^x03 Speed^x01 crescut la^x03 Level:^x04 %d^x01.", TAG, user[id][Speed] + 1);
		}
		case 5:
		{
			ColorChat(id, RED, "^x04%s^x03 Invisibility^x01 crescut la^x03 Level:^x04 %d^x01.", TAG, user[id][Invis] + 1);
		}
		case 6:
		{
			ColorChat(id, RED, "^x04%s^x03 Bhop^x01 crescut la^x03 Level:^x04 %d^x01.", TAG, user[id][Bhop] + 1);
		}
		case 7:
		{
			ColorChat(id, RED, "^x04%s^x03 Critical^x01 crescut la^x03 Level:^x04 %d^x01.", TAG, user[id][Critical] + 1);
		}
		case 8:
		{
			ColorChat(id, RED, "^x04%s^x03 Vampirism^x01 crescut la^x03 Level:^x04 %d^x01.", TAG, user[id][Vampirism] + 1);
		}
	}
	user[id][Key + 2]++;
	user[id][XP] -= user[id][Key + 2] * Breeding;
	client_cmd(id, "spk xpdynamic/bb/%s", UPGRADE_SOUND);
	SetStats(id, false);

	ShowMenu(id);
}
public Callback(id, menu, item)
{
	static _access, info[4], callback;
	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);

	if( info[0] == '*' )
		return ITEM_ENABLED;

	new Key = str_to_num(info);
	new Breeding = 50;

	if( ((user[id][Key + 2] + 1) * Breeding > user[id][XP])
	|| (user[id][Key + 2] == MaxLevel) )
		return ITEM_DISABLED;

	return ITEM_ENABLED;
}
public HamPlayerSpawn(id)
{
	set_task(2.0, "taskSetStats", id);
}
public HamTakeDamage(id, inflictor, iAttacker, Float:damage, damagebits)
{
	if( !iAttacker || id == iAttacker || !is_user_connected(iAttacker) || !is_user_connected(id)
	|| get_user_team(id) == get_user_team(iAttacker) )
		return HAM_IGNORED;

	SetHamParamFloat(4, damage + (damage * user[iAttacker][Damage] * 0.01));

	if( Percents_to_do(user[iAttacker][Critical]) )
	{
		set_hudmessage(255, 0, 25, -1.0, -1.0, 0, 6.0, 3.0);
		show_hudmessage(iAttacker, "CRITICAL DAMAGE");

		SetHamParamFloat(4, damage * 2);
	}
	return HAM_HANDLED;
}
public taskSetStats(id)
{
	SetStats(id, true);
}
public HookSay(id)
{
	new arg[192];
	read_argv(1, arg, sizeof(arg) - 1);

	if( equal(arg, "") )
		return PLUGIN_CONTINUE;

	new Players[32], iNum, player;
	get_players(Players, iNum, "ch");

	for( new i = 0; i < iNum; i++ )
	{
		player = Players[i];

		if( cs_get_user_team(id) == CS_TEAM_T )
			ColorChat(player, RED, "^x04[%s]^x03 %s^x01 :   %s", g_szRangs[user[id][Level]], szName[id], arg);

		else if( cs_get_user_team(id) == CS_TEAM_CT )
			ColorChat(player, BLUE, "^x04[%s]^x03 %s^x01 :   %s", g_szRangs[user[id][Level]], szName[id], arg);

		else if( cs_get_user_team(id) == CS_TEAM_SPECTATOR )
			ColorChat(player, GREY, "^x04[%s]^x03 %s^x01 :   %s", g_szRangs[user[id][Level]], szName[id], arg);
	}
	return PLUGIN_HANDLED;
}
public LoadStats(id)
{
	static szData[256], iTimestamp;

	if( nvault_lookup(iVault, szName[id], szData, sizeof(szData) - 1, iTimestamp) )
	{
		static szXP[15], szALLXP[15], szLevel[15], szDamage[15], szGravity[15],
		szHealth[15], szSpeed[15], szInvis[15], szBhop[15], szCritical[15], szVampirism[15];

		parse(szData,
		szXP, sizeof(szXP) -1,
		szALLXP, sizeof(szALLXP) -1,
		szLevel, sizeof(szLevel) -1,
		szDamage, sizeof(szDamage) -1,
		szGravity, sizeof(szGravity) -1,
		szHealth, sizeof(szHealth) -1,
		szSpeed, sizeof(szSpeed) -1,
		szInvis, sizeof(szInvis) -1,
		szBhop, sizeof(szBhop) -1,
		szCritical, sizeof(szCritical) -1,
		szVampirism, sizeof(szVampirism) -1);

		user[id][XP] = str_to_num(szXP);
		user[id][ALLXP] = str_to_num(szALLXP);
		user[id][Level] = str_to_num(szLevel);
		user[id][Damage] = str_to_num(szDamage);
		user[id][Gravity] = str_to_num(szGravity);
		user[id][Health] = str_to_num(szHealth);
		user[id][Speed] = str_to_num(szSpeed);
		user[id][Invis] = str_to_num(szInvis);
		user[id][Bhop] = str_to_num(szBhop);
		user[id][Critical] = str_to_num(szCritical);
		user[id][Vampirism] = str_to_num(szVampirism);
	}
	else
	{
		user[id][XP] = 0;
		user[id][ALLXP] = 0;
		user[id][Level] = 1;
		user[id][Damage] = 0;
		user[id][Gravity] = 0;
		user[id][Health] = 0;
		user[id][Speed] = 0;
		user[id][Invis] = 0;
		user[id][Bhop] = 0;
		user[id][Critical] = 0;
		user[id][Vampirism] = 0;
	}
}
public SaveStats(id)
{
	static szData[256];

	format(szData, sizeof(szData) -1, "%d %d %d %d %d %d %d %d %d %d %d",
	user[id][XP],
	user[id][ALLXP],
	user[id][Level],
	user[id][Damage],
	user[id][Gravity],
	user[id][Health],
	user[id][Speed],
	user[id][Invis],
	user[id][Bhop],
	user[id][Critical],
	user[id][Vampirism]);

	nvault_set(iVault, szName[id],  szData);
}
public InfoEXP(id)
{
	ColorChat(id, RED, "^x04%s^x03 %s^x01 - Level:^x04 %d", TAG, szName[id], user[id][Level]);
	ColorChat(id, RED, "^x04%s^x01 XP:^x03 %d^x01 | XP Total:^x03 %d^x01.", TAG, user[id][XP], user[id][ALLXP]);
}
public GiveXP(id, Experience)
{
	user[id][ALLXP] = clamp(user[id][ALLXP] + Experience, ZERO, MaxXP);

	if( user[id][ALLXP] == MaxXP )
	{
		user[id][XP] = MaxXP;

		user[id][Damage] = MaxLevel;
		user[id][Gravity] = MaxLevel;
		user[id][Health] = MaxLevel;
		user[id][Speed] = MaxLevel;
		user[id][Invis]= MaxLevel;
		user[id][Bhop] = MaxLevel;
		user[id][Critical] = MaxLevel;
		user[id][Vampirism] = MaxLevel;
	}
	else
		user[id][XP] += Experience;

	new iNewLevel;

	for( new iLevel = 0; iLevel < TEN + 1; iLevel++ )
	{
		if( user[id][ALLXP] >= g_Experience[user[id][Level]] )
		{
			iNewLevel = iLevel;
		}
		else
		{
			break;
		}
	}
	if( iNewLevel > user[id][Level] )
	{
		user[id][Level] = iNewLevel;

		ColorChat(0, RED, "^x04%s^x03 %s^x01 a ajuns la rangul de^x04 %s^x01.", TAG, szName[id], g_szRangs[user[id][Level]]);
	}
	return PLUGIN_HANDLED;
}
public SetStats(player, const bool: NewRound)
{
	new Float: Breeding;
	Breeding = 0.013;
	new Float: gravity = 1.0 - (user[player][Gravity] * Breeding);

	Breeding = 7.0;
	new Float: speed = 250 + (user[player][Speed] * Breeding);

	Breeding = 3.9;
	new Float: Invisibility = 255 - (user[player][Invis] * Breeding);

	set_pev(player, pev_maxspeed, speed);
	set_pev(player, pev_gravity, gravity);
	set_rendering(player, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, floatround(Invisibility, floatround_floor));

	if( NewRound )
	{
		Breeding = 5.0;
		new health = get_user_health(player);//pev(player, pev_health);
		health += user[player][Health] * Breeding;
		set_pev(player, pev_health, health);
	}
}
public taskShowXP(id)
{
	if( is_user_alive(id) )
	{
		new sz_XP[15], sz_ALLXP[15];
		format(sz_XP, sizeof(sz_XP) - 1, "%d", user[id][XP]);
		format(sz_ALLXP, sizeof(sz_ALLXP) - 1, "%d", user[id][ALLXP]);

		format(sz_XP, sizeof(sz_XP) - 1, "%s", user[id][XP] == MaxXP ? "MAXIM":sz_XP);
		format(sz_ALLXP, sizeof(sz_ALLXP) - 1, "%s", user[id][ALLXP] == MaxXP ? "MAXIM":sz_ALLXP);

		set_hudmessage(208, 32, 144, 0.02, 0.90, 0, 6.0, 1.0);
		show_hudmessage(id, "Rang: %s | Health: %d^nLevel: %d | XP: %s | XP Total: %s", g_szRangs[user[id][Level]], get_user_health(id), user[id][Level], sz_XP, sz_ALLXP);
	}
	set_task(1.0, "taskShowXP", id);
	//208-32-144
}
stock Percents_to_do(iPercent)
{
	new iNumber = random_num(1, MaxLevel);

	if( iNumber <= iPercent )
		return true;

	return false;
}
