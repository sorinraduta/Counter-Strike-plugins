#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <ColorChat>

#pragma semicolon			1


#define ZERO				0

#define MIN_PLAYERS			8
#define MAX_CTROUNDS			2
#define MAX_ZONES			3
#define MAX_MAPS			5

#define TASK_TEAMS			1234
#define TASK_CHOOSE			4321


static const

	PLUGIN[ ] =			"B Rush Manager",
	VERSION[ ] =			"0.0.1",
	AUTHOR[ ] =			"Rap^^",

	TAG[ ] =			"[B Rush]";


new const g_szZonesClassName[ ]	=	"ZoneCN";
new const g_szInfoTarget[ ] =		"info_target";
new const g_szZonesModel[ ] =		"models/gib_skull.mdl";

new const g_szMaps[MAX_MAPS][ ] =
{
	"de_dust",
	"de_dust2",
	"de_inferno",
	"de_nuke",
	"de_tuscan"
};

new const Float: g_flDustMins[MAX_ZONES][3] =
{
	{-1280.4, 2271.4, -192.4},	// sub pod
	{-768.0, 1343.5, 31.5},		// tunel pod
	{575.5, 895.9, 31.5}		// tunel X
};

new const Float: g_flDustMaxs[MAX_ZONES][3] =
{
	{-896.5, 2303.9, -47.5},	// sub pod
	{-255.9, 1472.4, 192.4},	// tunel pod
	{704.4, 1152.0, 192.4}		// tunel X
};

new const Float: g_flDust2Mins[MAX_ZONES][3] =
{
	{-480.4, 1583.9, -128.4},	// poarta mid
	{-0.0, 1407.5, -0.4},		// scara
	{543.5, 239.9, -0.4}		// poarta lung
};

new const Float: g_flDust2Maxs[MAX_ZONES][3] =
{
	{-287.5, 1679.9, 32.4},		// poarta mid
	{64.0, 1600.4, 351.0},		// scara
	{736.4, 336.0, 160.4}		// poarta lung
};

new const Float: g_flInfernoMins[MAX_ZONES - 1][3] =
{
	{2433.5, 1583.9, 159.5},	// usa
	{1727.5, 1247.9, 159.5}		// arcada
};

new const Float: g_flInfernoMaxs[MAX_ZONES - 1][3] =
{
	{2494.4, 1600.0, 254.4},	// usa
	{1920.4, 1472.0, 288.4}		// arcada
};

new const Float: g_flNukeMins[MAX_ZONES][3] =
{
	{31.5, -1184.0, -416.4},	// usa
	{255.9, -1088.4, -384.4},	// cabana
	{-831.6, -1536.0, -416.4}	// afara
};

new const Float: g_flNukeMaxs[MAX_ZONES][3] =
{
	{128.4, -1151.9, -287.5},	// usa
	{320.0, -991.5, -296.5},	// cabana
	{256.4, -1391.9, 127.4}		// afara
};

new const Float: g_flTuscanMins[MAX_ZONES][3] =
{
	{-832.0, 31.5, 143.5}, 		// Z
	{839.5, 1312.0, 79.5},		// canal
	{-192.0, 671.5, 79.5}		// patrat
};

new const Float: g_flTuscanMaxs[MAX_ZONES][3] =
{
	{-575.9, 288.4, 703.4},		// Z
	{1080.4, 1440.0, 184.4},	// canal
	{-63.9, 800.4, 223.4}		// patrat
};

enum
{
	TERO = 1,
	CT,
	SPEC
}

new g_iMenuON;
new g_iBRushON;
new g_iCTRounds;
new g_iWrongKills;
new g_iChooseTime;
new g_iChooses;

new g_iFrags[33];

new SyncHud;
new SyncHud2;

//new g_MsgIDBombPickUp;


public plugin_init( )
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say !brush",	"cmdBRush");
	register_clcmd("say /brush",	"cmdBRush");
	register_clcmd("chooseteam",	"cmdHandle");

	register_event("HLTV",		"EventNewRound",	"a", "1=0", "2=0");
	register_event("DeathMsg",	"EventDeathMsg",	"a");
	register_event("SendAudio",	"EventTeroWin", 	"a", "2&%!MRAD_terwin");
	register_event("SendAudio",	"EventCTWin",		"a", "2&%!MRAD_ctwin");

	register_forward(FM_SetModel,	"SetModel",		1);

	register_logevent("LogEventGotBomb", 3, "2=Spawned_With_The_Bomb");
	register_logevent("LogEventGotBomb", 3, "2=Got_The_Bomb");

	register_message(get_user_msgid("ShowMenu"), "MessageShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "MessageVGUIMenu");

	SyncHud = CreateHudSyncObj( );
	SyncHud2 = CreateHudSyncObj( );

	// g_MsgIDBombPickUp = get_user_msgid("BombPickup");
}

public plugin_precache( )
{
	precache_model(g_szZonesModel);
}

public client_disconnect(id)
{
	if( g_iMenuON == id )
	{
		g_iMenuON = ZERO;
	}

	if( g_iBRushON )
	{
		new CsTeams: iTeam = cs_get_user_team(id);

		if( iTeam == CS_TEAM_T || iTeam == CS_TEAM_CT )
		{
			if( get_playersnum( ) < MIN_PLAYERS )
			{
				StopBRush( );

				server_cmd("sv_restart 1");

				ColorChat(0, GREEN, "%s^x01 Prea putini jucatori pentru a continua^x03 B Rush^x01ul.", TAG);

				return PLUGIN_CONTINUE;
			}

			new iRandom = GetRandomPlayer(SPEC);

			cs_set_user_team(iRandom, cs_get_user_team(id));
		}
	}

	return PLUGIN_CONTINUE;
}

public client_command(id)
{
	if( g_iBRushON )
	{
		static szCommand[10];
		static const szJoinCommand[10] = "jointeam";

		read_argv(0, szCommand, charsmax(szCommand));

		if( equal(szCommand, szJoinCommand))
		{
			console_print(id, "%s Nu este permisa comanda jointeam in timpul B Rushului.", TAG);

			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public EventNewRound( )
{
	if( g_iBRushON == 2 )
	{
		new iPlayers[32], iNum, player, iTNum, iCTNum;

		get_players(iPlayers, iNum, "ech", "TERRORIST");

		iTNum = iNum;

		get_players(iPlayers, iNum, "ech", "CT");

		iCTNum = iNum;

		if( iTNum + iCTNum < MIN_PLAYERS )
		{
			StopBRush( );

			server_cmd("sv_restart 1");

			ColorChat(ZERO, GREEN, "%s^x01 Prea putini jucatori pentru a continua^x03 B-Rush^x01ul.", TAG);

			return PLUGIN_CONTINUE;
		}

		get_players(iPlayers, iNum, "ach");

		for( new i = ZERO; i < iNum; i++ )
		{
			player = iPlayers[i];

			g_iFrags[player] = ZERO;
		}

		g_iWrongKills = 0;
	}

	return PLUGIN_CONTINUE;
}

public EventDeathMsg( )
{
	if( g_iBRushON == 2 )
	{
		new iKiller = read_data(1);
		new iVictim = read_data(2);

		if( cs_get_user_team(iVictim) == CS_TEAM_CT )
		{
			if( iKiller == iVictim || iKiller == 0
			|| cs_get_user_team(iKiller) == CS_TEAM_CT )
			{
				g_iWrongKills++;

				return PLUGIN_CONTINUE;
			}
		}

		g_iFrags[iKiller]++;
	}

	return PLUGIN_CONTINUE;
}

public EventTeroWin( )
{
	if( g_iBRushON == 2 )
	{
		g_iCTRounds = ZERO;

		set_task(1.0, "CheckFrags");
	}
}

public EventCTWin( )
{
	if( g_iBRushON )
	{
		if( ++g_iCTRounds >= MAX_CTROUNDS )
		{
			new iPlayers[32], iNum, player, szFinalMsg[416];

			formatex(szFinalMsg, charsmax(szFinalMsg), "Harta a fost castigata de catre:^n");

			get_players(iPlayers, iNum, "ech", "CT");

			for( new i = ZERO; i < iNum; i++ )
			{
				player = iPlayers[i];

				add(szFinalMsg, charsmax(szFinalMsg), "^n");
				add(szFinalMsg, charsmax(szFinalMsg), get_name(player));
			}

			add(szFinalMsg, charsmax(szFinalMsg), "^n^nFelicitari tuturor paricipantilor^nUrmatoarea mapa se va vota in 5 secunde");

			set_hudmessage(80, 80, 80, -1.0, 0.20, 0, 0.0, 15.0, 0.0, 0.0, -1);
			ShowSyncHudMsg(0, SyncHud, "%s", szFinalMsg);

			StopBRush( );

			set_task(5.0, "MapChoose");
		}
	}
}

public MessageShowMenu(Msgid, Dest, id)
{
	if( !ShouldAutojoin(id) )
	{
		return PLUGIN_CONTINUE;
	}

	static szTeamSelect[ ] = "#Team_Select";
	static szMenuTextCode[sizeof(szTeamSelect)];

	get_msg_arg_string(4, szMenuTextCode, sizeof(szMenuTextCode) - 1);

	if( !equal(szMenuTextCode, szTeamSelect) )
	{
		return PLUGIN_CONTINUE;
	}

	static ParamMenuMsgid[2];

	ParamMenuMsgid[0] = Msgid;

	set_task(0.1, "ForceTeamJoin", id, ParamMenuMsgid, sizeof(ParamMenuMsgid));

	return PLUGIN_HANDLED;
}

public MessageVGUIMenu(Msgid, Dest, id)
{
	if( get_msg_arg_int(1) != 2 || !ShouldAutojoin(id) )
	{
		return PLUGIN_CONTINUE;
	}

	static ParamMenuMsgid[2];

	ParamMenuMsgid[0] = Msgid;

	set_task(0.1, "ForceTeamJoin", id, ParamMenuMsgid, sizeof(ParamMenuMsgid));

	return PLUGIN_HANDLED;
}

public cmdBRush(id)
{
	if( get_user_flags(id) & read_flags("a") )
	{
		if( !g_iMenuON )
		{
			g_iMenuON = id;

			MainMenu(id);

			return PLUGIN_HANDLED;
		}

		if( g_iMenuON != id )
		{
			ColorChat(id, GREEN, "%s^x01 Cineva foloseste deja meniul de^x03 B Rush^x01.", TAG);
		}
	}

	return PLUGIN_HANDLED;
}

public MainMenu(id)
{
	new iMenu = menu_create("\dB Rush Menu \yby Rap^^", "MainHandler", 0);
	new callback = menu_makecallback("Callback");

	menu_additem(iMenu, "Start B-Rush", "1", _, callback);
	menu_additem(iMenu, "Stop B-Rush^n^n", "2", _, callback);
	menu_additem(iMenu, "\rCredite", "3", _, callback);

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public Callback(id, menu, item)
{
	static _access, info[4], callback;
	menu_item_getinfo(menu, item, _access, info, charsmax(info), _, _, callback);

	new iKey = str_to_num(info);

	if( iKey == 1 && g_iBRushON
	 || iKey == 2 && !g_iBRushON )
	{
		return ITEM_DISABLED;
	}

	return ITEM_ENABLED;
}

public MainHandler(id, iMenu, item)
{
	if( item == MENU_EXIT )
	{
		g_iMenuON = ZERO;

		menu_destroy(iMenu);

		return PLUGIN_HANDLED;
	}

	new data[6], name[64];
	new _access, callback;

	menu_item_getinfo(iMenu, item, _access, data, 5, name, 63, callback);

	new iKey = str_to_num(data);

	switch( iKey )
	{
		case 1:
		{
			if( get_playersnum( ) < MIN_PLAYERS )
			{
				ColorChat(id, GREEN, "%s^x01 Sunt prea putini jucatori pe server (^x03Minim %d^x01).", TAG, MIN_PLAYERS);

				MainMenu(id);

				return PLUGIN_HANDLED;
			}

			g_iMenuON = ZERO;

			StartBRush( );
		}

		case 2:
		{
			g_iMenuON = ZERO;

			StopBRush( );

			server_cmd("sv_restart 1");
		}

		case 3:
		{
			ShowCredits(id);

			MainMenu(id);
		}
	}

	return PLUGIN_HANDLED;
}

public ChooseMenu(id)
{
	id -= TASK_CHOOSE;

	if( g_iChooses )
	{
		if( --g_iChooseTime )
		{
			new szMenu[192];

			formatex(szMenu, sizeof(szMenu) - 1, "\dB Rush\r Choose \dMenu \yby Rap^^^n^n\wMai ai\d %d\w secunde sa alegi\d %d\w jucator%s",
			g_iChooseTime, g_iChooses, g_iChooses == 1 ? "":"i");

			new iMenu = menu_create(szMenu, "ChooseHandler", ZERO);
			new iPlayers[32], iNum, player, szInfo[5];

			get_players(iPlayers, iNum, "ech", "TERRORIST");

			for( new i = 0; i < iNum; i++ )
			{
				player = iPlayers[i];

				num_to_str(i + 1, szInfo, charsmax(szInfo));

				menu_additem(iMenu, get_name(player), szInfo);
			}

			menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER);
			menu_display(id, iMenu);

			set_task(1.0, "ChooseMenu", id + TASK_CHOOSE);
		}

		else
		{
			RemoveMenu(id);

			AutoChoose( );
		}
	}

	else
	{
		RemoveMenu(id);

		server_cmd("sv_restart 1");
	}

	return PLUGIN_HANDLED;
}

public ChooseHandler(id, iMenu, item)
{
	new data[6], name[64];
	new _access, callback;

	menu_item_getinfo(iMenu, item, _access, data, 5, name, 63, callback);

	new iKey = str_to_num(data);

	if( task_exists(id + TASK_CHOOSE) )
	{

		remove_task(id + TASK_CHOOSE);
	}

	g_iChooses--;

	new iPlayers[32], iNum;

	get_players(iPlayers, iNum, "ech", "TERRORIST");

	cs_set_user_team(iPlayers[iKey - 1], CS_TEAM_CT);

	ChooseMenu(id + TASK_CHOOSE);

	return PLUGIN_HANDLED;
}

public cmdHandle(id)
{
	if( g_iBRushON )
	{
		ColorChat(id, GREEN, "%s^x01 Nu este permisa aceasta comanda in timpul^x03 B Rush^x01ului.", TAG);

		return PLUGIN_HANDLED_MAIN;
	}

	return PLUGIN_CONTINUE;
}

public LogEventGotBomb(id)
{
	if( g_iBRushON )
	{
		engclient_cmd(id, "drop", "weapon_c4");
	}
}

public SetModel(iEnt, szModel[ ])
{
	if( g_iBRushON )
	{
		/*if( equal(szModel, "models/w_backpack.mdl") )
		{
			engfunc(EngFunc_RemoveEntity, iEnt);

			message_begin(MSG_ALL, g_MsgIDBombPickUp);
			message_end( );
		}*/

		if( equal(szModel, "models/w_flashbang.mdl") )
		{
			engfunc(EngFunc_RemoveEntity, iEnt);
		}
	}
}

public StartBRush( )
{
	new iPlayers[32], iNum, player;
	get_players(iPlayers, iNum, "ch");

	for( new i = ZERO; i < iNum; i++ )
	{
		player = iPlayers[i];

		user_silentkill(player);
		cs_set_user_team(player, CS_TEAM_SPECTATOR);
	}

	g_iBRushON = 1;

	ChooseTeams(true);
	RevealZones( );
}

public StopBRush( )
{
	if( task_exists(TASK_TEAMS) )
	{
		remove_task(TASK_TEAMS);
	}

	server_cmd("mp_roundtime 1.75");
	server_cmd("mp_freezetime 0");
	server_cmd("mp_startmoney 16000");
	server_cmd("mp_autoteambalance 1");

	g_iBRushON = ZERO;

	DeleteZones( );

	ColorChat(0, GREEN, "%s^x01 B-Rush-ul a fost oprit.", TAG);
}

public ChooseTeams(bool: bReset)
{
	static iNumber, iRandomPlayer;
	static szTeroTeam[352], szCTTeam[352];

	if( bReset )
	{
		iNumber = 1;

		formatex(szTeroTeam, charsmax(szTeroTeam), "Echipa Terrorist:^n");
		formatex(szCTTeam, charsmax(szCTTeam), "Echipa Counter-Terrorist:^n");

		set_hudmessage(80, 80, 80, -1.0, 0.20, 0, 0.0, 0.0, 0.0, 5.0, -1);
		ShowSyncHudMsg(0, SyncHud, "In 5 secunde vor incepe alegerile (RANDOM)");

		set_task(5.0, "ChooseTeams");

		return PLUGIN_HANDLED;
	}

	switch( iNumber )
	{
		case 1..5:
		{
			iRandomPlayer = GetRandomPlayer(SPEC);

			cs_set_user_team(iRandomPlayer, CS_TEAM_T);

			add(szTeroTeam, charsmax(szTeroTeam), "^n");
			add(szTeroTeam, charsmax(szTeroTeam), get_name(iRandomPlayer));
		}

		case 6..MIN_PLAYERS:
		{
			iRandomPlayer = GetRandomPlayer(SPEC);

			cs_set_user_team(iRandomPlayer, CS_TEAM_CT);

			add(szCTTeam, charsmax(szCTTeam), "^n");
			add(szCTTeam, charsmax(szCTTeam), get_name(iRandomPlayer));
		}

		case MIN_PLAYERS + 1:
		{
			server_cmd("mp_buytime 0.15");
			server_cmd("mp_roundtime 1");
			server_cmd("mp_freezetime 3");
			server_cmd("mp_forcecamera 2");
			server_cmd("mp_forcechasecam 2");
			server_cmd("mp_startmoney 800");
			server_cmd("mp_autoteambalance 0");
			server_cmd("mp_friendlyfire 0");
			server_cmd("mp_timelimit 0");
			server_cmd("mp_timeleft 0");

			server_cmd("sv_restart 5");

			g_iBRushON = 2;

			return PLUGIN_HANDLED;
		}
	}

	iNumber++;

	set_hudmessage(80, 80, 80, 0.20, 0.30, 0, 0.0, 0.0, 0.0, 10.0, 1);
	ShowSyncHudMsg(0, SyncHud, "%s", szTeroTeam);

	set_hudmessage(80, 80, 80, 0.60, 0.30, 0, 0.0, 0.0, 0.0, 10.0, 2);
	ShowSyncHudMsg(0, SyncHud2, "%s", szCTTeam);

	set_task(2.0, "ChooseTeams");

	return PLUGIN_HANDLED;
}

public CheckFrags( )
{
	new iPlayers[32], iNum, player;
	new iFrags, iMaxFrags, iBestFrager;

	get_players(iPlayers, iNum, "ch");

	for( new i = ZERO; i < iNum; i++ )
	{
		player = iPlayers[i];

		switch( cs_get_user_team(player) )
		{
			case CS_TEAM_T:
			{
				iFrags = g_iFrags[player];

				if( iFrags > ZERO )
				{
					cs_set_user_team(player, CS_TEAM_CT);

					if( iFrags > iMaxFrags )
					{
						iMaxFrags = iFrags;
						iBestFrager = player;
					}
				}
			}

			case CS_TEAM_CT:
			{
				cs_set_user_team(player, CS_TEAM_T);
			}
		}
	}

	if( iMaxFrags == ZERO )
	{
		g_iChooses = 3;

		AutoChoose( );

		return PLUGIN_HANDLED;
	}

	g_iChooses = (g_iFrags[iBestFrager] + g_iWrongKills) - 1;

	g_iChooseTime = 10;

	ChooseMenu(iBestFrager + TASK_CHOOSE);

	return PLUGIN_HANDLED;
}

public MapChoose( )
{
	new szMap[32], szVote[64];

	get_mapname(szMap, charsmax(szMap));

	formatex(szVote, charsmax(szVote), "amx_votemap");

	for( new i = 0; i < MAX_MAPS; i++ )
	{
		if( equali(szMap, g_szMaps[i]) )
		{
			continue;
		}

		add(szVote, charsmax(szVote), " ");
		add(szVote, charsmax(szVote), g_szMaps[i]);
	}

	server_cmd(szVote);
}

public ForceTeamJoin(MenuMsgid[ ], id)
{
	static iMsgBlock, iMsgid;
	static szJoinTeam[ ] = "jointeam";

	iMsgid = MenuMsgid[0];
	iMsgBlock = get_msg_block(iMsgid);

	set_msg_block(iMsgid, BLOCK_SET);
	engclient_cmd(id, szJoinTeam, "6");
	set_msg_block(iMsgid, iMsgBlock);
}

AutoChoose( )
{
	if( g_iChooses-- )
	{
		cs_set_user_team(GetRandomPlayer(TERO), CS_TEAM_CT);

		AutoChoose( );
	}

	else
	{
		server_cmd("sv_restart 1");
	}

	return PLUGIN_HANDLED;
}

RevealZones( )
{
	new szMap[33];

	get_mapname(szMap, charsmax(szMap));

	switch( szMap[3] )
	{
		case 'd':
		{
			switch( szMap[7] )
			{
				case EOS:
				{
					if( equali(szMap, g_szMaps[0]) )
					{
						for( new i = 0; i < MAX_ZONES; i++ )
						{
							CreateZone(g_flDustMins[i], g_flDustMaxs[i]);
						}
					}
				}

				case '2':
				{
					if( equali(szMap, g_szMaps[1]) )
					{
						for( new i = 0; i < MAX_ZONES; i++ )
						{
							CreateZone(g_flDust2Mins[i], g_flDust2Maxs[i]);
						}
					}
				}
			}
		}

		case 'i':
		{
			if( equali(szMap, g_szMaps[2]) )
			{
				for( new i = 0; i < MAX_ZONES - 1; i++ )
				{
					CreateZone(g_flInfernoMins[i], g_flInfernoMaxs[i]);
				}
			}
		}

		case 'n':
		{
			if( equali(szMap, g_szMaps[3]) )
			{
				for( new i = 0; i < MAX_ZONES; i++ )
				{
					CreateZone(g_flNukeMins[i], g_flNukeMaxs[i]);
				}
			}
		}

		case 't':
		{
			if( equali(szMap, g_szMaps[4]) )
			{
				for( new i = 0; i < MAX_ZONES; i++ )
				{
					CreateZone(g_flTuscanMins[i], g_flTuscanMaxs[i]);
				}
			}
		}
	}
}

CreateZone(const Float: flMins[3], const Float: flMaxs[3])
{
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, g_szInfoTarget));

	if( !pev_valid(iEnt) )
	{
		return PLUGIN_CONTINUE;
	}

	set_pev(iEnt, pev_classname, g_szZonesClassName);
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY);
	set_pev(iEnt, pev_solid, SOLID_BBOX);
	set_pev(iEnt, pev_effects, pev(iEnt, pev_effects) | EF_NODRAW);
	engfunc(EngFunc_SetModel, iEnt, g_szZonesModel);
	engfunc(EngFunc_SetSize, iEnt, flMins, flMaxs);

	return PLUGIN_CONTINUE;
}

DeleteZones( )
{
	new iEnt = -1;

	while( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", g_szZonesClassName)) )
	{
		engfunc(EngFunc_RemoveEntity, iEnt);
	}
}

RemoveMenu(id)
{
	show_menu(id, 0, "^n", 1);
}

GetRandomPlayer(iTeam)
{
	new iWPlayers[32], iWNum = 0;

	switch( iTeam )
	{
		case SPEC:
		{
			new iPlayers[32], iNum, player;

			get_players(iPlayers, iNum, "ch");

			for( new i = 0; i < iNum; i++ )
			{
				player = iPlayers[i];

				if( cs_get_user_team(player) == CS_TEAM_SPECTATOR )
				{
					iWPlayers[iWNum] = player;
					iWNum++;
				}
			}
		}

		case TERO:
		{
			get_players(iWPlayers, iWNum, "ech", "TERRORIST");
		}

		case CT:
		{
			get_players(iWPlayers, iWNum, "ech", "CT");
		}
	}

	return iWPlayers[random(iWNum)];
}

ShowCredits(id)
{
	set_hudmessage(80, 80, 80, -1.0, 0.40, 0, 0.0, 0.0, 0.0, 8.0, -1);
	ShowSyncHudMsg(id, SyncHud, "Credite B-Rush Manager by RapZzw3rR:^n^nAskhanar^nTheBeast^nfuzy^nAZAEL!^nbomm^nTrufy^nMzU");
}

stock get_name(id)
{
	new szName[32];

	get_user_name(id, szName, charsmax(szName));

	return szName;
}

stock bool: ShouldAutojoin(id)
{
	return ( !get_user_team(id) && !task_exists(id) && g_iBRushON > ZERO );
}
