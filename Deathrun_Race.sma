#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <ColorChat>

#pragma semicolon 1

#define COOLDOWN	10
#define ZERO		0
#define TASK		1337
#define TOTAL		1234

native mw_get_user_lifes(id);
native mw_set_user_lifes(id, lifes);

static const

	PLUGIN[ ] =		"Deathrun Race",
	VERSION[ ] =		"0.0.1",
	AUTHOR[ ] =		"Rap^^",

	TAG[ ] =		"[Deathrun Race]";


new g_iProvoker;
new g_iGuest;

new g_iEnemy[33];
new g_iTempEnemy[33];

new g_iBet[33];
new g_iBetAmount[33];

new g_iMenuCooldown[33];
new g_iRaceCooldown;

new cvar_maxbet;
new cvar_winner_price;

new SyncHud;


public plugin_init( )
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say",		"HookSay");
	register_clcmd("say /race",	"cmdRace");

	register_concmd("amx_bet",	"cmdBet");

	cvar_maxbet = register_cvar("race_maxbet", "15");
	cvar_winner_price = register_cvar("race_winner_price", "10");

	register_event("HLTV", "EventNewRound", "a", "1=0", "2=0");
	register_event("DeathMsg", "EventDeathMsg", "a");

	SyncHud = CreateHudSyncObj( );
}

public client_disconnect(id)
{
	new iEnemy = g_iEnemy[id];

	if( iEnemy )
	{
		Winner(iEnemy);

		return PLUGIN_CONTINUE;
	}

	new iTempEnemy = g_iTempEnemy[id];

	if( iTempEnemy )
	{
		ResetData(id, iTempEnemy);
	}

	return PLUGIN_CONTINUE;
}

public EventNewRound( )
{
	ResetData(TOTAL);
}

public EventDeathMsg( )
{
	new iKiller = read_data(1);
	new iVictim = read_data(2);

	if( get_user_team(iKiller) == 2 && get_user_team(iVictim) == 1 )
	{
		new iEnemyKiller = g_iEnemy[iKiller];

		if( iEnemyKiller )
		{
			Winner(iKiller);
		}
	}

	else if( get_user_team(iVictim) == 2 )
	{
		new iEnemyVictim = g_iEnemy[iVictim];

		if( iEnemyVictim )
		{
			Winner(iEnemyVictim);
		}
	}
}

public cmdRace(id)
{
	if( !is_user_alive(id) )
	{
		ColorChat(id, GREEN, "%s^x01 Nu poti folosi aceasta comanda cand esti mort.", TAG);

		return PLUGIN_HANDLED;
	}

	if( get_user_team(id) == 1 )
	{
		ColorChat(id, RED, "^x04%s^x01 Nu poti folosi aceasta comanda cand esti^x03 TERO^x01.", TAG);

		return PLUGIN_HANDLED;
	}

	if( g_iTempEnemy[id] )
	{
		ColorChat(id, RED, "^x04%s^x01 Inca nu poti folosi aceasta comanda.", TAG);

		return PLUGIN_HANDLED;
	}

	ShowProvokerMenu(id);

	return PLUGIN_HANDLED;
}

public cmdBet(id)
{
	new szTarget[32], szBetAmount[5];

    	read_argv(1, szTarget, charsmax(szTarget));
	read_argv(2, szBetAmount, charsmax(szBetAmount));

	if( equali(szBetAmount, "") )
	{
		ColorChat(id, GREEN, "%s^x01 Folosire: /bet^x03 <nume>^x04 <vieti>", TAG);

		return PLUGIN_HANDLED;
	}

	new player = cmd_target(id, szTarget, 8);
	new iBetAmount = str_to_num(szBetAmount);

	if( (g_iProvoker == player || g_iGuest == player) && g_iRaceCooldown )
	{
		if( g_iProvoker == id || g_iGuest == id )
		{
			ColorChat(id, GREEN, "%s^x01 Nu poti paria pe cursa in care esti.", TAG);

			return PLUGIN_HANDLED;
		}

		new iMaxBet = get_pcvar_num(cvar_maxbet);

		if( g_iBetAmount[id] )
		{
			ColorChat(id, GREEN, "%s^x01 Nu poti paria pe mai multi in acelasi timp.", TAG);

			return PLUGIN_HANDLED;
		}

		if( iBetAmount == ZERO )
		{
			ColorChat(id, GREEN, "%s^x01 Poti paria minim^x04 1^x01 viata.", TAG, iMaxBet);

			return PLUGIN_HANDLED;
		}

		if( iBetAmount > iMaxBet )
		{
			ColorChat(id, GREEN, "%s^x01 Poti paria maxim^x04 %d^x01 vieti.", TAG, iMaxBet);

			return PLUGIN_HANDLED;
		}

		if( iBetAmount > mw_get_user_lifes(id) )
		{
			ColorChat(id, GREEN, "%s^x01 Nu ai^x04 %d^x01 vieti pentru a le paria.", TAG, iBetAmount);

			return PLUGIN_HANDLED;
		}

		g_iBet[id] = player;
		g_iBetAmount[id] = iBetAmount;

		ColorChat(0, GREEN, "%s^x03 %s^x01 a pariat pe^x03 %s^x04 %d^x01 vi%s.", TAG, get_name(id), get_name(player), iBetAmount, iBetAmount == 1 ? "ata":"eti");
	}

	return PLUGIN_HANDLED;
}

public ShowProvokerMenu(id)
{
	new iMenu = menu_create("\dRace \yProvoker \dMenu", "ProvokerHandler", 0);
	new callback = menu_makecallback("Callback");

	new iPlayers[32], iNum, player, szInfo[5];

	get_players(iPlayers, iNum, "aceh", "CT");

	for( new i = 0; i < iNum; i++ )
	{
		player = iPlayers[i];

		num_to_str(i + 1, szInfo, charsmax(szInfo));

		menu_additem(iMenu, get_name(player), szInfo, _, callback);
	}

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public Callback(id, menu, item)
{
	static _access, info[4], callback;
	menu_item_getinfo(menu, item, _access, info, charsmax(info), _, _, callback);

	new iPlayers[32], iNum, player;
	new iKey = str_to_num(info);

	get_players(iPlayers, iNum, "aceh", "CT");

	player = iPlayers[iKey - 1];

	if( g_iEnemy[player] || player == id)
	{
		return ITEM_DISABLED;
	}

	return ITEM_ENABLED;
}

public ProvokerHandler(id, iMenu, item)
{
	if( item == MENU_EXIT )
	{
		menu_destroy(iMenu);

		return PLUGIN_HANDLED;
	}

	if( g_iRaceCooldown )
	{
		ColorChat(id, GREEN, "%s^x01 Cineva deja a fost provocat la o cursa.", TAG);

		return PLUGIN_HANDLED;
	}

	if( g_iTempEnemy[id] )
	{
		ColorChat(id, RED, "^x04%s^x01 Deja ai provocat pe cineva la o cursa.", TAG);

		return PLUGIN_HANDLED;
	}

	new data[6], name[64];
	new _access, callback;

	menu_item_getinfo(iMenu, item, _access, data, 5, name, 63, callback);

	new iKey = str_to_num(data);

	new iPlayers[32], iNum, player;

	get_players(iPlayers, iNum, "aceh", "CT");

	player = iPlayers[iKey - 1];

	if( g_iEnemy[player] )
	{
		ColorChat(id, GREEN, "%s^x03 %s^x01 este deja intr-o cursa.", TAG, get_name(player));

		return PLUGIN_HANDLED;
	}

	if( g_iTempEnemy[player] )
	{
		ColorChat(id, RED, "^x04%s^x01 Momentan,^x03 %s^x01 raspunde la o alta provocare.", TAG, get_name(player));

		return PLUGIN_HANDLED;
	}

	if( is_user_ok(player) )
	{
		g_iMenuCooldown[player] = COOLDOWN;

		g_iTempEnemy[id] = player;
		g_iTempEnemy[player] = id;

		ColorChat(id, GREEN, "%s^x01 L-ai provocat pe^x03 %s^x01 la o cursa.", TAG, get_name(player));

		ShowGuestMenu(player);
	}

	return PLUGIN_HANDLED;
}

public ShowGuestMenu(id)
{
	if( g_iMenuCooldown[id]-- && is_user_ok(id) )
	{
		new szTitle[160];

		formatex(szTitle, charsmax(szTitle), "\dRace\y Guest\d Menu^n\r%s\w te provoaca la o cursa^n^nMai ai\y %d\w secunde sa raspunzi", get_name(g_iTempEnemy[id]), g_iMenuCooldown[id]);

		new iMenu = menu_create(szTitle, "GuestHandler", 0);

		menu_additem(iMenu, "Accept", "1");
		menu_additem(iMenu, "Refuz", "2");

		menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER);
		menu_display(id, iMenu, 0);

		set_task(1.0, "ShowGuestMenu", id);
	}

	else
	{
		new iProvoker = g_iTempEnemy[id];

		ColorChat(iProvoker, GREEN, "%s^x03 %s^x01 nu ti-a raspuns provocare.", TAG, get_name(id));

		RemoveMenu(id);

		ResetData(iProvoker, id);
	}

	return PLUGIN_HANDLED;
}

public GuestHandler(id, iMenu, item)
{
	new data[6], name[64];
	new _access, callback;

	menu_item_getinfo(iMenu, item, _access, data, 5, name, 63, callback);

	new iKey = str_to_num(data);

	if( task_exists(id) )
	{
		remove_task(id);
	}

	if( g_iRaceCooldown )
	{
		ColorChat(id, GREEN, "%s^x01 Inca nu poti incepe o cursa.", TAG);

		return PLUGIN_HANDLED;
	}

	new iProvoker = g_iTempEnemy[id];

	switch( iKey )
	{
		case 1:
		{
			ColorChat(iProvoker, GREEN, "%s^x03 %s^x01 ti-a acceptat provocarea.", TAG, get_name(id));

			g_iProvoker = iProvoker;
			g_iGuest = id;

			PrepareRace( );
		}

		case 2:
		{
			ColorChat(iProvoker, GREEN, "%s^x03 %s^x01 nu ti-a acceptat provocarea.", TAG, get_name(id));

			ResetData(iProvoker, id);
		}
	}

	RemoveMenu(id);

	return PLUGIN_HANDLED;
}

public StartRace( )
{
	if( is_user_ok(g_iProvoker) && is_user_ok(g_iGuest) )
	{
		set_hudmessage(80, 80, 80, -1.0, 0.20, 0, 0.0, 5.0, 0.0, 0.0, -1);
		ShowSyncHudMsg(0, SyncHud, "%s si %s au inceput cursa^nUrati-le noroc", get_name(g_iProvoker), get_name(g_iGuest));
	}

	ResetData(g_iProvoker, g_iGuest);
}

public PrepareRace( )
{
	if( !is_user_ok(g_iProvoker) && !is_user_ok(g_iGuest) )
	{
		ResetData(g_iProvoker, g_iGuest);

		return PLUGIN_HANDLED;
	}

	g_iRaceCooldown = COOLDOWN;

	g_iEnemy[g_iProvoker] = g_iGuest;
	g_iEnemy[g_iGuest] = g_iProvoker;

	set_hudmessage(80, 80, 80, -1.0, 0.20, 0, 0.0, 5.0, 0.0, 0.0, -1);
	ShowSyncHudMsg(0, SyncHud, "%s si %s vor incepe in scurt timp o cursa.^nAveti %d secunde sa pariati pe unul dintre ei.", get_name(g_iProvoker), get_name(g_iGuest), g_iRaceCooldown + 5);

	ExecuteHamB(Ham_CS_RoundRespawn, g_iProvoker);
	ExecuteHamB(Ham_CS_RoundRespawn, g_iGuest);

	Freeze(g_iProvoker);
	Freeze(g_iGuest);

	set_task(5.0, "taskBetTime", TASK);

	return PLUGIN_HANDLED;
}

public taskBetTime(T_A_S_K)
{
	if( --g_iRaceCooldown > ZERO )
	{
		set_hudmessage(80, 80, 80, -1.0, 0.20, 0, 0.0, 1.0, 0.0, 0.0, -1);
		ShowSyncHudMsg(0, SyncHud, "Mai aveti %d secunde pentru a paria pe %s sau pe %s^nFolositi comanda ^"/bet <nume> <vieti>^"", g_iRaceCooldown, get_name(g_iProvoker), get_name(g_iGuest));

		set_task(1.0, "taskBetTime", TASK);
	}

	else
	{
		StartRace( );
	}
}

Winner(iWinner)
{
	new iPlayers[32], iNum, player, iBetAmount;
	new iLooser = g_iEnemy[iWinner];

	ColorChat(0, GREEN, "%s^x03 %s^x01 a castigat cursa in fata lui^x03 %s^x01.", TAG, get_name(iWinner), get_name(iLooser));
	ColorChat(iWinner, GREEN, "%s^x01 Ai primit^x04 %d^x01 vieti pentru castigarea cursei.", TAG, get_pcvar_num(cvar_winner_price));

	add_user_lives(iWinner, get_pcvar_num(cvar_winner_price));

	get_players(iPlayers, iNum, "ch");

	for( new i = 0; i < iNum; i++ )
	{
		player = iPlayers[i];

		iBetAmount = g_iBetAmount[player];

		if( g_iBet[player] == iWinner )
		{
			ColorChat(player, GREEN, "%s^x01 Ai castigat^x04 %d^x01 vieti in pariul pus pe^x03 %s^x01.", TAG, iBetAmount * 2, get_name(iWinner));

			add_user_lives(player, iBetAmount * 2);
		}

		if( g_iBet[player] == iLooser )
		{
			ColorChat(player, GREEN, "%s^x01 Ai pierdut^x04 %d^x01 vieti in pariul pus pe^x03 %s^x01.", TAG, iBetAmount, get_name(iLooser));

			sub_user_lives(player, iBetAmount);
		}
	}

	g_iEnemy[iWinner] = ZERO;
	g_iEnemy[iLooser] = ZERO;
}

public HookSay(id)
{
	static szArgs[192];

	read_args(szArgs, charsmax(szArgs) );

	if( !szArgs[0] )
	{
		return PLUGIN_CONTINUE;
	}

	new szCommand[15];

	remove_quotes(szArgs);

	if( equal(szArgs, "/bet", strlen("/bet" )) )
	{
		replace(szArgs, charsmax(szArgs), "/", "");

		formatex(szCommand, charsmax(szCommand), "amx_%s", szArgs);

		client_cmd(id, szCommand);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

ResetData(iProvoker, iGuest = TOTAL)
{
	switch( iProvoker )
	{
		case TOTAL:
		{
			new iPlayers[32], iNum, player;

			get_players(iPlayers, iNum, "ch");

			for( new i = 0; i < iNum; i++ )
			{
				player = iPlayers[i];

				if( task_exists(player) )
				{
					remove_task(player);
				}

				if( task_exists(TASK) )
				{
					remove_task(TASK);
				}

				g_iEnemy[player] = ZERO;
				g_iTempEnemy[player] = ZERO;

				g_iBet[player] = ZERO;
				g_iBetAmount[player] = ZERO;

				g_iMenuCooldown[player] = ZERO;

				RemoveMenu(player);
			}

			g_iRaceCooldown = ZERO;
		}

		default:
		{
			if( is_user_alive(iProvoker) )
			{
				Freeze(iProvoker, ZERO);
			}

			if( is_user_alive(iGuest) )
			{
				Freeze(iGuest, ZERO);
			}

			g_iTempEnemy[iProvoker] = ZERO;
			g_iTempEnemy[iGuest] = ZERO;

			g_iMenuCooldown[iProvoker] = ZERO;
			g_iMenuCooldown[iGuest] = ZERO;
		}
	}
}

stock add_user_lives(id, iLives)
{
	return mw_set_user_lifes(id, mw_get_user_lifes(id) + iLives);
}

stock sub_user_lives(id, iLives)
{
	return mw_set_user_lifes(id, clamp(mw_get_user_lifes(id) - iLives, 0));
}

stock Freeze(id, freeze = 1)
{
	set_pev(id, pev_flags, freeze == 1 ? pev(id, pev_flags) | FL_FROZEN : pev(id, pev_flags) & ~FL_FROZEN);
}

stock RemoveMenu(id)
{
	show_menu(id, 0, "^n", 1);
}

stock bool: is_user_ok(id)
{
	if( is_user_connected(id) && is_user_alive(id) )
	{
		return true;
	}

	return false;
}

stock get_name(id)
{
	new szName[32];

	get_user_name(id, szName, charsmax(szName));

	return szName;
}
