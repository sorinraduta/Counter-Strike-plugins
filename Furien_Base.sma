#include <amxmodx>
#include <cstrike>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>
#include <engine>

#pragma semicolon 1

#define PISTOL_WEAPONS_BIT	(1<<CSW_GLOCK18|1<<CSW_USP|1<<CSW_DEAGLE|1<<CSW_P228|1<<CSW_FIVESEVEN|1<<CSW_ELITE)
#define SHOTGUN_WEAPONS_BIT	(1<<CSW_M3|1<<CSW_XM1014)
#define SUBMACHINE_WEAPONS_BIT	(1<<CSW_TMP|1<<CSW_MAC10|1<<CSW_MP5NAVY|1<<CSW_UMP45|1<<CSW_P90)
#define RIFLE_WEAPONS_BIT	(1<<CSW_FAMAS|1<<CSW_GALIL|1<<CSW_AK47|1<<CSW_SCOUT|1<<CSW_M4A1|1<<CSW_SG550|1<<CSW_SG552|1<<CSW_AUG|1<<CSW_AWP|1<<CSW_G3SG1)
#define MACHINE_WEAPONS_BIT	(1<<CSW_M249)

#define PRIMARY_WEAPONS_BIT	(SHOTGUN_WEAPONS_BIT|SUBMACHINE_WEAPONS_BIT|RIFLE_WEAPONS_BIT|MACHINE_WEAPONS_BIT)
#define SECONDARY_WEAPONS_BIT	(PISTOL_WEAPONS_BIT)

new g_iMaxPlayers;

#define FIRST_PLAYER_ID		1
#define IsPlayer(%1)		(FIRST_PLAYER_ID <= %1 <= g_iMaxPlayers)
#define IsPrimaryWeapon(%1)	((1<<%1) & PRIMARY_WEAPONS_BIT)
#define IsSecondaryWeapon(%1)	((1<<%1) & SECONDARY_WEAPONS_BIT)

#define XO_WEAPONBOX		4
#define m_rgpPlayerItems_wpnbx_Slot5	39
#define IsWeaponBoxC4(%1)	(get_pdata_cbase(%1, m_rgpPlayerItems_wpnbx_Slot5, XO_WEAPONBOX) > 0)

#define ZERO 0
#define MAX_MONEY 16000

#define TASK_START 222222
#define	SWITCH_TASK		112233

#define TEAM_FURIEN	CS_TEAM_T
#define TEAM_AFURIEN	CS_TEAM_CT

#define HOSTNAME	"furien.disconnect.ro"
#define IP		"xx.xx.xx.xx"

static const PLUGIN[ ]		= "Furien Base";
static const VERSION[ ]		= "1.0";
static const AUTHOR[ ]		= "Rap";

new const g_szHH[ ][ ] =
{
	"00:00",
	"03:00",
	"05:00",
	"09:00",
	"12:00",
	"15:00",
	"18:00",
	"21:00"
};
new const g_szMPistols[7][ ] =
{
	"",
	"Glock",
	"Usp",
	"P228",
	"Deagle",
	"Fiveseven",
	"Elite"
};
new const g_szMWeapons[19][ ] =
{
	"",
	"M3",
	"XM1014",
	"TMP",
	"Mac10",
	"Mp5navy",
	"Ump45",
	"P90",
	"Galil",
	"Famas",
	"Scout",
	"M4a1",
	"Ak47",
	"Sg552",
	"Aug",
	"Awp",
	"G3sg1",
	"Sg550",
	"M249"
};
new const g_szPistols[7][ ] =
{
	"",
	"weapon_glock18",
	"weapon_usp",
	"weapon_p228",
	"weapon_deagle",
	"weapon_fiveseven",
	"weapon_elite"
};
new const g_szWeapons[19][ ] =
{
	"",
	"weapon_m3",
	"weapon_xm1014",
	"weapon_tmp",
	"weapon_mac10",
	"weapon_mp5navy",
	"weapon_ump45",
	"weapon_p90",
	"weapon_galil",
	"weapon_famas",
	"weapon_scout",
	"weapon_m4a1",
	"weapon_ak47",
	"weapon_sg552",
	"weapon_aug",
	"weapon_awp",
	"weapon_g3sg1",
	"weapon_sg550",
	"weapon_m249"
};
new const g_szCSWPistols[7] =
{
	ZERO,
	CSW_GLOCK18,
	CSW_USP,
	CSW_P228,
	CSW_DEAGLE,
	CSW_FIVESEVEN,
	CSW_ELITE
};
new const g_szCSWWeapons[19] =
{
	ZERO,
	CSW_M3,
	CSW_XM1014,
	CSW_TMP,
	CSW_MAC10,
	CSW_MP5NAVY,
	CSW_UMP45,
	CSW_P90,
	CSW_GALIL,
	CSW_FAMAS,
	CSW_SCOUT,
	CSW_M4A1,
	CSW_AK47,
	CSW_SG550,
	CSW_AUG,
	CSW_AWP,
	CSW_G3SG1,
	CSW_SG552,
	CSW_M249
};
new const g_szWeaponsBuyCommands[ ][ ] =
{
	"usp", "glock", "deagle", "p228", "elites",
	"fn57", "m3", "xm1014", "mp5", "tmp", "p90",
	"mac10", "ump45", "ak47", "galil", "famas",
	"sg552", "m4a1", "aug", "scout", "awp", "g3sg1",
	"sg550", "m249", "vest", "vesthelm", "flash",
	"hegren", "sgren", "defuser", "nvgs", "shield",
	"primammo", "secammo", "km45", "9x19mm", "nighthawk",
	"228compact", "fiveseven", "12gauge", "autoshotgun",
	"mp", "c90", "cv47", "defender", "clarion", "krieg552",
	"bullpup", "magnum", "d3au1", "krieg550", "buyammo1",
	"buyammo2", "buyequip"
};
new const g_szImportantBlocks[ ][ ] =
{
	"cl_autobuy", "cl_rebuy", "cl_setautobuy", "cl_setrebuy",
	"buy", "bUy", "buY", "bUY", "Buy", "BUy", "BuY", "BUY"
};
new PistPrice[7];
new WeapPrice[19];

new weapon_chosed[33];

new price_glock;
new price_usp;
new price_p228;
new price_deagle;
new price_fiveseven;
new price_elite;
new price_m3;
new price_xm1014;
new price_tmp;
new price_mac10;
new price_mp5navy;
new price_ump45;
new price_p90;
new price_galil;
new price_famas;
new price_scout;
new price_m4a1;
new price_ak47;
new price_sg550;
new price_aug;
new price_awp;
new price_g3sg1;
new price_sg552;
new price_m249;

new furien_speed;
new furien_gravity;

new bool: RoundStarted = false;

new g_ScoreAttrib;


public plugin_init( )
{
	new szHostName[101], szIP[51];

	get_cvar_string("hostname", szHostName, sizeof(szHostName) - 1);
	get_user_ip(0, szIP, sizeof(szIP) - 1, 1);

	if( containi(szHostName, HOSTNAME) != -1 && equal(IP, szIP) )
	{
		register_plugin(PLUGIN, VERSION, AUTHOR);

		register_event("HLTV", "EventNewRound", "a", "1=0", "2=0");
		register_event("DeathMsg", "EventDeathMsg", "a");
		register_event("CurWeapon", "EventCurWeapon", "be", "1=1");

		register_event("SendAudio", "SwitchTeams",  "a",  "1=0", "2=%!MRAD_ctwin");

		register_forward(FM_PlayerPreThink,	"FwdPreThink");

		RegisterHam(Ham_Spawn,	"player",	"HamPlayerSpawn",	1);
		RegisterHam(Ham_Touch,	"weaponbox",	"CWeaponBox_Touch");

		g_iMaxPlayers = get_maxplayers( );
		g_ScoreAttrib = get_user_msgid("ScoreAttrib");

		for( new i = 0; i < sizeof(g_szImportantBlocks); i++ )
			register_clcmd(g_szImportantBlocks[i], "BlockedCommand");

		register_clcmd("say /weapons", "PistolsMenu");

		price_glock	= register_cvar("furien_price_glock",	"1");
		price_usp	= register_cvar("furien_price_usp",	"1");
		price_p228	= register_cvar("furien_price_p228",	"1");
		price_deagle	= register_cvar("furien_price_deagle",	"1");
		price_fiveseven	= register_cvar("furien_price_fiveseven","1");
		price_elite	= register_cvar("furien_price_elite",	"1");
		price_m3	= register_cvar("furien_price_m3",	"1");
		price_xm1014	= register_cvar("furien_price_xm1014",	"1");
		price_tmp	= register_cvar("furien_price_tmp",	"1");
		price_mac10	= register_cvar("furien_price_mac10",	"1");
		price_mp5navy	= register_cvar("furien_price_mp5navy",	"1");
		price_ump45	= register_cvar("furien_price_ump45",	"1");
		price_p90	= register_cvar("furien_price_p90",	"1");
		price_galil	= register_cvar("furien_price_galil",	"1");
		price_famas	= register_cvar("furien_price_famas",	"1");
		price_scout	= register_cvar("furien_price_scout",	"1");
		price_m4a1	= register_cvar("furien_price_m4a1",	"1");
		price_ak47	= register_cvar("furien_price_ak47",	"1");
		price_sg550	= register_cvar("furien_price_sg550",	"1");
		price_aug	= register_cvar("furien_price_aug",	"1");
		price_awp	= register_cvar("furien_price_awp",	"1");
		price_g3sg1	= register_cvar("furien_price_g3sg1",	"1");
		price_sg552	= register_cvar("furien_price_sg552",	"1");
		price_m249	= register_cvar("furien_price_m249",	"1");

		furien_speed	= register_cvar("furien_speed",		"700");
		furien_gravity	= register_cvar("furien_gravity",	"400");
	}
	else
	{
		pause("ade");
	}
}
public BlockedCommand(id)
{
	return PLUGIN_HANDLED_MAIN;
}
public client_command(id)
{
	new sArg[13];
	if( read_argv(0, sArg, 12) > 11)
		return PLUGIN_CONTINUE;

	for( new i = 0; i < sizeof(g_szWeaponsBuyCommands); i++ )
	{
		if( equali(g_szWeaponsBuyCommands[i], sArg, 0) )
		{
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}
public EventNewRound( )
{
	if( task_exists(TASK_START) )
		remove_task(TASK_START);

	RoundStarted = false;

	set_task(get_cvar_float("mp_freezetime"), "taskStartR", TASK_START);
}
public EventDeathMsg( )
{
	new iKiller = read_data(1);
	new iVictim = read_data(2);

	if( iKiller == 0 || iKiller == iVictim )
		return PLUGIN_CONTINUE;

	new money = cs_get_user_money(iKiller);
	new Nmoney = ZERO;

	if( cs_get_user_team(iKiller) == TEAM_FURIEN )
		Nmoney += 500;

	else if( cs_get_user_team(iKiller) == TEAM_AFURIEN )
		Nmoney += 1000;

	if( is_user_vip(iKiller) )
		Nmoney += 500;

	if( isHappyHour( ) )
		Nmoney *= 2;

	cs_set_user_money(iKiller, clamp(money + Nmoney, ZERO, MAX_MONEY), 1);

	return PLUGIN_CONTINUE;
}
public EventCurWeapon(id)
{
	new iWeapon = read_data(2);

	if( cs_get_user_team(id) == TEAM_FURIEN )
	{
		if( IsPrimaryWeapon(iWeapon) || IsSecondaryWeapon(iWeapon) )
			engclient_cmd(id, "drop");

		set_user_maxspeed(id, get_pcvar_float(furien_speed));
	}
}
public FwdPreThink(id)
{
	if( !is_user_alive(id) )
		return PLUGIN_CONTINUE;

	if( cs_get_user_team(id) == TEAM_FURIEN )
	{
		new iWeapon = get_user_weapon(id);

		if( (iWeapon == CSW_KNIFE || is_user_vip(id)) && !isMoving(id) )
			fm_set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0);

		else
			fm_set_user_rendering(id);
	}
	return PLUGIN_CONTINUE;
}
public CWeaponBox_Touch(iWeaponBox, id)
{
	if( IsPlayer(id) )
	{
		if( !is_user_alive(id) )
		{
			return HAM_SUPERCEDE;
		}
		if( IsWeaponBoxC4(iWeaponBox) )
		{
			return HAM_IGNORED;
		}
		remove_entity(iWeaponBox);
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}
public HamPlayerSpawn(id)
{
	if( !is_user_alive(id) )
		return HAM_IGNORED;

	fm_strip_user_weapons(id);
	fm_set_user_rendering(id);

	weapon_chosed[id] = 0;

	if( cs_get_user_team(id) == TEAM_FURIEN )
	{
		fm_give_item(id, "weapon_knife");
		fm_give_item(id, "weapon_hegrenade");
		fm_give_item(id, "weapon_flashbang");
		fm_give_item(id, "weapon_flashbang");
	}
	else if( cs_get_user_team(id) == TEAM_AFURIEN )
	{
		set_user_footsteps(id, 0);
		fm_give_item(id, "weapon_knife");
		fm_give_item(id, "weapon_flashbang");
		fm_give_item(id, "weapon_smokegrenade");
		PistolsMenu(id);
	}
	if( is_user_vip(id) )
	{
		cs_set_user_defuse(id, 1, 255, 0, 100);
		new health = get_user_health(id);
		new armor = get_user_armor(id);

		set_user_health(id, health + 100);
		cs_set_user_armor(id, armor + 100, CS_ARMOR_VESTHELM);
	}
	if( !RoundStarted )
		set_task(get_cvar_float("mp_freezetime") + 0.01, "PlayerSpawn", id);

	else
		set_task(0.1, "PlayerSpawn", id);

	return HAM_IGNORED;
}
public PlayerSpawn(id)
{
	if( !is_user_alive(id) )
		return PLUGIN_CONTINUE;

	if( cs_get_user_team(id) == TEAM_FURIEN )
	{
		set_user_footsteps(id, 1);
		set_user_maxspeed(id, get_pcvar_float(furien_speed));
		set_user_gravity(id, get_pcvar_float(furien_gravity)/800);
	}
	if( is_user_vip(id) )
		set_user_scoreattrib(id, 4);

	return PLUGIN_CONTINUE;
}
public PistolsMenu(id)
{
	if( get_user_team(id) != 2 )
		return PLUGIN_HANDLED;

	switch( weapon_chosed[id] )
	{
		case 1:
		{
			WeaponMenu(id);

			return PLUGIN_HANDLED;
		}
		case 2:
		{
			client_print(id, print_center, "Ti-ai ales deja armele");

			return PLUGIN_HANDLED;
		}
	}
	GetWeapPrice( );

	new menu = menu_create("\rPistols Menu", "PistolsHandler");

	new callback = menu_makecallback("PCallback");

	new szI[3];
	new szFormat[101];

	for( new i = 1; i <= sizeof(g_szMPistols) - 1; i++)
	{
		formatex(szI, sizeof(szI) - 1, "%d", i);
		formatex(szFormat, sizeof(szFormat) - 1, "%s [\r%d$\w]", g_szMPistols[i], PistPrice[i]);

		menu_additem(menu, szFormat, szI, _, callback);
	}
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}
public PistolsHandler(id, menu, item)
{
	if( item == MENU_EXIT || !is_user_alive(id) )
	{
		menu_destroy(menu);
		return;
	}
	static  _access, info[4], callback;

	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	menu_destroy(menu);

	new Key = str_to_num(info);
	new money = cs_get_user_money(id);

	cs_set_user_money(id, money - PistPrice[Key]);

	fm_give_item(id, g_szPistols[Key]);

	cs_set_user_bpammo(id, g_szCSWPistols[Key], 100);

	weapon_chosed[id] = 1;

	WeaponMenu(id);
}
public PCallback(id, menu, item)
{
	static _access, info[4], callback;
	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);

	new Key = str_to_num(info);

	if( !is_user_alive(id) )
		return ITEM_DISABLED;

	if( PistPrice[Key] > cs_get_user_money(id) )
		return ITEM_DISABLED;

	return ITEM_ENABLED;
}
public WeaponMenu(id)
{
	GetWeapPrice( );

	new menu = menu_create("\rWeapon Menu", "WeaponHandler");

	new callback = menu_makecallback("WCallback");

	new szI[3];
	new szFormat[101];

	for( new i = 1; i <= sizeof(g_szMWeapons) - 1; i++)
	{
		formatex(szI, sizeof(szI) - 1, "%d", i);
		formatex(szFormat, sizeof(szFormat) - 1, "%s [\r%d$\w]", g_szMWeapons[i], WeapPrice[i]);

		menu_additem(menu, szFormat, szI, _, callback);
	}
	menu_display(id, menu);
}
public WeaponHandler(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id) )
	{
		menu_destroy(menu);
		return;
	}
	static  _access, info[4], callback;

	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	menu_destroy(menu);

	new Key = str_to_num(info);
	new money = cs_get_user_money(id);

	cs_set_user_money(id, money - WeapPrice[Key]);

	fm_give_item(id, g_szWeapons[Key]);

	cs_set_user_bpammo(id, g_szCSWWeapons[Key], 300);

	weapon_chosed[id] = 2;
}
public WCallback(id, menu, item)
{
	static _access, info[4], callback;
	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);

	new Key = str_to_num(info);

	if( !is_user_alive(id) )
		return ITEM_DISABLED;

	if( WeapPrice[Key] > cs_get_user_money(id) )
		return ITEM_DISABLED;

	return ITEM_ENABLED;
}
public SwitchTeams( )
{
	set_task(2.5, "TeamSwitch");
}
public TeamSwitch( )
{
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum, "ch");

	if( iNum )
	{
		new id;

		for( --iNum; iNum >= 0; iNum-- )
		{
			id = iPlayers[iNum];
			BeginDelayedTeamChange(id);
		}
	}
}
public BeginDelayedTeamChange(id)
{
	switch(id)
	{
		case  1..6:	set_task(0.1, "ChangeUserTeamWithDelay", id + SWITCH_TASK);
		case  7..13:	set_task(0.2, "ChangeUserTeamWithDelay", id + SWITCH_TASK);
		case  14..20:	set_task(0.3, "ChangeUserTeamWithDelay", id + SWITCH_TASK);
		case  21..26:	set_task(0.4, "ChangeUserTeamWithDelay", id + SWITCH_TASK);
		case  27..32:	set_task(0.5, "ChangeUserTeamWithDelay", id + SWITCH_TASK);
	}
}
public ChangeUserTeamWithDelay(id)
{
	id -= SWITCH_TASK;

	if( !IsUserOK(id) ) return PLUGIN_HANDLED;

	switch( cs_get_user_team(id) )
	{
		case TEAM_FURIEN:  cs_set_user_team(id, TEAM_AFURIEN);
		case TEAM_AFURIEN: cs_set_user_team(id, TEAM_FURIEN);
	}
	return PLUGIN_CONTINUE;
}
GetWeapPrice( )
{
	PistPrice[1]  = get_pcvar_num(price_glock);
	PistPrice[2]  = get_pcvar_num(price_usp);
	PistPrice[3]  = get_pcvar_num(price_p228);
	PistPrice[4]  = get_pcvar_num(price_deagle);
	PistPrice[5]  = get_pcvar_num(price_fiveseven);
	PistPrice[6]  = get_pcvar_num(price_elite);

	WeapPrice[1]  = get_pcvar_num(price_m3);
	WeapPrice[2]  = get_pcvar_num(price_xm1014);
	WeapPrice[3]  = get_pcvar_num(price_tmp);
	WeapPrice[4]  = get_pcvar_num(price_mac10);
	WeapPrice[5]  = get_pcvar_num(price_mp5navy);
	WeapPrice[6]  = get_pcvar_num(price_ump45);
	WeapPrice[7]  = get_pcvar_num(price_p90);
	WeapPrice[8]  = get_pcvar_num(price_galil);
	WeapPrice[9]  = get_pcvar_num(price_famas);
	WeapPrice[10] = get_pcvar_num(price_scout);
	WeapPrice[11] = get_pcvar_num(price_m4a1);
	WeapPrice[12] = get_pcvar_num(price_ak47);
	WeapPrice[13] = get_pcvar_num(price_sg550);
	WeapPrice[14] = get_pcvar_num(price_aug);
	WeapPrice[15] = get_pcvar_num(price_awp);
	WeapPrice[16] = get_pcvar_num(price_g3sg1);
	WeapPrice[17] = get_pcvar_num(price_sg552);
	WeapPrice[18] = get_pcvar_num(price_m249);
}
public taskStartR( )
{
	RoundStarted = true;
}
stock isMoving(id)
{
	new Float: fVelocity[3];
	entity_get_vector(id, EV_VEC_velocity, fVelocity);

	if( fVelocity[0] == ZERO
	 && fVelocity[1] == ZERO
	 && fVelocity[2] == ZERO )
		return false;

	return true;
}
stock set_user_scoreattrib(id, attrib = 0)
{
	message_begin(MSG_BROADCAST, g_ScoreAttrib, _, 0);
	write_byte(id);
	write_byte(attrib);
	message_end( );
}
stock bool: IsUserOK(id)
{
	if( is_user_connected(id) && !is_user_bot(id) )
		return true;

	return false;
}
stock bool: is_user_vip(id)
{
	if( get_user_flags(id) & read_flags("s") )
		return true;

	return false;
}
stock bool: isHappyHour( )
{
	new szTime[32];

	get_time("%H:%M", szTime, sizeof(szTime) - 1);

	for( new i = 0; i <= 7; i++ )
		if( strcmp(szTime, g_szHH[i]) == 0 )
			return true;

	return false;
}
