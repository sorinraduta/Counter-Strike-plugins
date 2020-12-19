#include < amxmodx >
#include < amxmisc >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >
#include < ColorChat >

#pragma semicolon 1

#define AddSetting(%1,%2)	( g_iSettings[%1] |= %2 )
#define SubSetting(%1,%2)	( g_iSettings[%1] &= ~%2 )
#define GetSetting(%1,%2)	( g_iSettings[%1] & %2 )
#define Add(%1,%2)		( %1 |= 1 << (   %2 & 31 ) )
#define Sub(%1,%2)		( %1 &= ~( 1 <<( %2 & 31 ) ) )
#define Get(%1,%2)		( %1 & 1 << ( %2 & 31 ) )


static const

	PLUGIN[ ] =		"HideNSeek_War",
	VERSION[ ] =		"2.0",
	AUTHOR[ ] =		"Rap^^ & Askhanar",

	TAG[ ] =		"[D/C]";


enum _: iNumbers
{
	NULL = 0,
	ONE,
	TWO,
	THREE,
	FOUR,
	FIVE,
	SIX,
	SEVEN,
	EIGHT,
	NINE,
	TEN,
	ELEVEN,
	TWELVE,
	THIRTEEN,
	FOURTEEN,
	THIRTYTWO = 32,
	THIRTYTHREE
}

enum _: iParticipants
{
	FIRST = NULL,
	SECOND
};

enum _: iResults
{
	YES = NULL,
	NO
}

enum (+= 100)
{
	TASK_REMOVEMENU = 11011,
	TASK_SCORE,
	TASK_INFO,
	TASK_READY,
	TASK_READYINFO,
	TASK_TEAMNAME
}

enum
{
	CURRENT,
	NEXT
}

enum
{
	SOLO = NULL,
	TEAM,
	SOLO_DEFAULT,
	TEAM_DEFAULT
};

enum (<<= ONE)
{
	VOTE = ONE,
	WAITING,	//  WAITING FOR PLAYERS TO JOIN
	WF_TEAMNAME,	//  WAITING FOR PLAYERS TO CHOOSE THE NAME OF TEAM
	PF_CHOOSE,	//  PREPARE FOR CHOOSE ROUND
	CHOOSE_ROUND,	//  CHOOSE ROUND
	WF_CHOOSE,	//  WAITING FOR CHOOSES
	PF_KNIFE,	//  PREPARE FOR KNIFE ROUND
	KNIFE_ROUND,	//  KNIFE ROUND
	PF_WAR,		//  PREPARE FOR WAR
	ON, 		//  WAR ON
	CHAT_SPEC,	//  DEACTIVATE SPECTATOR'S CHAT
	CHAT_PART	//  DEACTIVATE PARTICIPANTS'S CHAT
}

new const g_szNumbers[ ][ ] =
{
	"0",
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"10",
	"11",
	"12",
	"13",
	"14"
};

new const g_szClose[ THIRTYTWO ]	= "Inchide";
new const g_szBack[ THIRTYTWO ]	= "Inapoi";
new const g_szCEH[ FIVE ]	= "ceh";
new const g_szCH[ FIVE ]		= "ch";
new const g_szB[ FIVE ]		= "b";
new const g_szK[ FIVE ]		= "k";
new const g_szYes[ FIVE ]	= "Da";
new const g_szNo[ FIVE ]		= "Nu";
new const g_szNotAvaible[ FIVE ]	= "N/A";
new const g_szBlank[ FIVE ]	= "";
new const MIN_CHARS		= 2;
new const MAX_CHARS		= 32;

new Float: g_flSpawnTime;

new bool: g_bReady[ iParticipants ];
new bool: g_bNamedTeam[ iParticipants ];

new bool: g_bChangeStage;

new CsTeams: g_iTeams[ iParticipants ];

new g_szNameSettings[ THIRTYTHREE ][ iParticipants ][ THIRTYTWO ];
new g_szTeamSettings[ THIRTYTHREE ][ iParticipants ][ THIRTYTWO ];

new g_szName[ iParticipants ][ THIRTYTWO ];

new g_szScore[ THIRTYTHREE * THREE ];

new g_iSettings[ THIRTYTWO ];

new g_iWarType[ THIRTYTHREE ];
new g_iMaxRounds[ THIRTYTHREE ];
new g_iPlayersNum[ THIRTYTHREE ];
new g_iChooses[ THIRTYTHREE ];

new g_iScore[ iParticipants ];
new g_iVotes[ iResults ];

new g_iWinner;
new g_iRounds;
new g_iProvoker;
new g_iCaused;
new g_iChallenged;
new g_iWar;
new g_iStage;
new g_iAction;
new g_iStartTime;
new g_iConnected;
new g_iAlive;
new g_iInWar;
new g_iIsReady;
new g_iShowScore;
new g_iShowInfo;
new g_iMenuLeader;

new g_iSyncHud1;
new g_iSyncHud2;
new g_iSyncHud3;

new g_iMaxPlayers;


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );

	new const szClCmdChoose[ ] = "ClCmdChoose";

	register_clcmd( "say /alege",	szClCmdChoose );
	register_clcmd( "say /choose",	szClCmdChoose );
	register_clcmd( "say /chooseparts",	"ClCmdChooseParts" );
	register_clcmd( "say", "ClCmdSay" );
	register_clcmd( "say /war", "ClCmdWar" );
	register_clcmd( "say /ready", "ClCmdReady" );
	register_clcmd( "say /teamname", "ClCmdTeamName" );
	register_clcmd( "Primul_nume", "FirstName" );
	register_clcmd( "Al_doilea_nume", "SecondName" );
	register_clcmd( "Prima_echipa", "FirstTeam" );
	register_clcmd( "A_doua_echipa", "SecondTeam" );
	register_clcmd( "Alege_numele_echipei", "ChooseTeamName" );

	new const szA[ ] = "a";

	register_event( "DeathMsg",	"EventDeathMsg",	szA );
	register_event( "HLTV",		"EventNewRound",	szA, "1=0", "2=0" );
	register_event( "SendAudio",	"EventTerroWin",	szA, "2=%!MRAD_terwin" );
	register_event( "SendAudio",	"EventCounterWin",	szA, "2=%!MRAD_ctwin" );

	register_logevent( "LogEventRoundEnd", TWO, "1=Round_End");

	new const szPlayer[ ] = "player";

	RegisterHam( Ham_Killed,	szPlayer, "FwdPlayerKilled" );
	RegisterHam( Ham_Spawn,		szPlayer, "FwdPlayerSpawn", true );

	g_iSyncHud1 = CreateHudSyncObj( );
	g_iSyncHud2 = CreateHudSyncObj( );
	g_iSyncHud3 = CreateHudSyncObj( );

	g_iMaxPlayers = get_maxplayers( );

	register_clcmd( "say /leader", "sayleader" );
}
public sayleader( id )
{
	new Prov[ 32 ];
	new Cau[ 32 ];

	get_user_name( g_iProvoker, Prov, charsmax( Prov ) );
	get_user_name( g_iCaused, Cau, charsmax( Cau ) );

	client_print( 0, print_chat, "PROVOKER: %s", Prov );
	client_print( 0, print_chat, "CAUSED: %s", Cau );
}

public plugin_natives( )
{
	register_library( "hnswar" );
	register_native( "get_war_stage", "_get_war_stage" );
}

public _get_war_stage( iPlugin, iParams )
{
	return g_iStage;
}

public client_putinserver( id )
{
	g_iChooses[ id ] = NULL;

	Add( g_iAction, id );
	Add( g_iConnected, id );
	Sub( g_iAlive, id );
	Sub( g_iInWar, id );
	Sub( g_iIsReady, id );
	Add( g_iShowScore, id );
	Add( g_iShowInfo, id );
	Add( g_iMenuLeader, id );

	ResetMenuOptions( id );
}

public client_disconnect( id )
{
	Sub( g_iConnected, id );
	Sub( g_iAlive, id );

	if( !Get( g_iInWar, id ) )
	{
		return PLUGIN_CONTINUE;
	}

	switch( g_iWar )
	{
		case SOLO, SOLO_DEFAULT:
		{
			StopWar( NULL, true );

			return PLUGIN_CONTINUE;
		}

		case TEAM, TEAM_DEFAULT:
		{
			new iLeader = GS_etLeader( id, true );

			if( !iLeader )
			{
				StopWar( NULL, true );

				return PLUGIN_CONTINUE;
			}

			else
			{
				g_iChooses[ iLeader ]++;

				ColorChat( iLeader, GREEN, "%s^x01 Un coechipier s-a deconectat. Poti folosi comanda^x03 /choose^x01 pentru a-l reintroduce in meci.", TAG );

				return PLUGIN_CONTINUE;
			}
		}
	}

	remove_task( id + TASK_TEAMNAME );
	remove_task( id + TASK_READY );

	return PLUGIN_CONTINUE;
}

public ClCmdChoose( id )
{
	if( id == g_iProvoker || id == g_iCaused )
	{
		ChooseAlliedMenu( id, false );

		return PLUGIN_HANDLED;
	}

	ColorChat( id, GREEN, "%s^x01 Nu poti folosi aceasta comanda.", TAG );

	return PLUGIN_HANDLED;
}

public ClCmdChooseParts( id )
{
	if( is_user_owner( id ) )
	{
		ChoosePartsMenu( id );

		return PLUGIN_HANDLED;
	}

	ColorChat( id, GREEN, "%s^x01 Nu poti folosi aceasta comanda.", TAG );

	return PLUGIN_HANDLED;
}

public ClCmdSay( id )
{
	static szArgs[ THIRTYTWO * SIX ];

	read_args( szArgs, charsmax( szArgs ) );

	if( !szArgs[ NULL ] )
	{
		return PLUGIN_CONTINUE;
	}

	remove_quotes( szArgs[ NULL ] );

	if( equal( szArgs, "/war", strlen( "/war" ) )
	|| equal( szArgs, "/ready", strlen( "/ready" ) )
	|| equal( szArgs, "/alege", strlen( "/alege" ) )
	|| equal( szArgs, "/choose", strlen( "/choose" ) ) )
	{
		return PLUGIN_CONTINUE;
	}

	if( g_iStage )
	{
		new CsTeams: iTeam = cs_get_user_team( id );

		if( iTeam == CS_TEAM_SPECTATOR )
		{
			if( !GetSetting( NULL, CHAT_SPEC ) )
			{
				new iPlayers[ THIRTYTWO ];

				new iNum;
				new player;

				get_players( iPlayers, iNum, g_szCEH );

				for( new i = NULL; i < iNum; i++ )
				{
					player = iPlayers[ i ];

					if( player == g_iProvoker || player == g_iCaused )
					{
						continue;
					}

					new szName[ THIRTYTWO ];

					get_user_name( id, szName, charsmax( szName ) );

					ColorChat( id, TEAM_COLOR, "%s^x01  :  %s", szName, szArgs );
				}

				return PLUGIN_HANDLED;
			}
		}

		else
		{
			if( !GetSetting( NULL, CHAT_PART ) )
			{
				ColorChat( id, GREY, "^x04%s^x01 Chat-ul este^x03 dezactivat^x01.", TAG );

				return PLUGIN_HANDLED;
			}
		}
	}

	return PLUGIN_CONTINUE;
}

public ClCmdWar( id )
{
	MainMenu( id );

	return PLUGIN_HANDLED;
}

public ClCmdReady( id )
{
	if( g_iStage != PF_CHOOSE && g_iStage != PF_KNIFE && g_iStage != PF_WAR )
	{
		ColorChat( id, GREEN, "%s^x01 Nu poti folosi aceasta comanda decat in etapele de pregatire.", TAG );

		return PLUGIN_HANDLED;
	}

	if( id == g_iProvoker )
	{
		Ready( g_iProvoker, FIRST );

		return PLUGIN_HANDLED;
	}

	else if( id == g_iCaused )
	{
		Ready( g_iCaused, SECOND );

		return PLUGIN_HANDLED;
	}

	ColorChat( id, GREEN, "%s^x01 Doar cei 2 care au pornit meciul pot folosi aceasta comanda.", TAG );

	return PLUGIN_HANDLED;
}

public ClCmdTeamName( id )
{
	client_cmd( id, "messagemode Alege_numele_echipei" );
}

public FirstName( id )
{
	new szArg[ THIRTYTWO ];

	read_argv( 1, szArg, charsmax( szArg ) );

	if( !is_right_lenght( id, szArg ) )
	{
		client_cmd( id, "messagemode Primul_nume" );

		return PLUGIN_HANDLED;
	}

	if( g_iStage )
	{
		copy( g_szName[ FIRST ], charsmax( g_szName[ ] ), szArg );
	}

	else
	{
		copy( g_szNameSettings[ id ][ FIRST ], charsmax( g_szNameSettings[ ][ ] ), szArg );
	}

	WarSettingsMenu( id, ONE );

	return PLUGIN_HANDLED;
}

public SecondName( id )
{
	new szArg[ THIRTYTWO ];

	read_argv( 1, szArg, charsmax( szArg ) );

	if( !is_right_lenght( id, szArg ) )
	{
		client_cmd( id, "messagemode Al_doilea_nume" );

		return PLUGIN_HANDLED;
	}

	if( g_iStage )
	{
		copy( g_szName[ SECOND ], charsmax( g_szName[ ] ), szArg );
	}

	else
	{
		copy( g_szNameSettings[ id ][ SECOND ], charsmax( g_szNameSettings[ ][ ] ), szArg );
	}

	WarSettingsMenu( id, ONE );

	return PLUGIN_HANDLED;
}

public FirstTeam( id )
{
	new szArg[ THIRTYTWO ];

	read_argv( 1, szArg, charsmax( szArg ) );

	if( !is_right_lenght( id, szArg ) )
	{
		client_cmd( id, "messagemode Prima_echipa" );

		return PLUGIN_HANDLED;
	}

	if( g_iStage )
	{
		copy( g_szName[ FIRST ], charsmax( g_szName[ ] ), szArg );
	}

	else
	{
		copy( g_szTeamSettings[ id ][ FIRST ], charsmax( g_szTeamSettings[ ][ ] ), szArg );
	}

	WarSettingsMenu( id, ONE );

	return PLUGIN_HANDLED;
}

public SecondTeam( id )
{
	new szArg[ THIRTYTWO ];

	read_argv( 1, szArg, charsmax( szArg ) );

	if( !is_right_lenght( id, szArg ) )
	{
		client_cmd( id, "messagemode A_doua_echipa" );

		return PLUGIN_HANDLED;
	}

	if( g_iStage )
	{
		copy( g_szName[ SECOND ], charsmax( g_szName[ ] ), szArg );
	}

	else
	{
		copy( g_szTeamSettings[ id ][ SECOND ], charsmax( g_szTeamSettings[ ][ ] ), szArg );
	}

	WarSettingsMenu( id, ONE );

	return PLUGIN_HANDLED;
}

public ChooseTeamName( id )
{
	new szArg[ THIRTYTWO ];

	read_argv( 1, szArg, charsmax( szArg ) );

	if( !is_right_lenght( id, szArg ) )
	{
		client_cmd( id, "messagemode Alege_numele_echipei" );

		return PLUGIN_HANDLED;
	}

	if( id != g_iProvoker && id != g_iCaused )
	{
		ColorChat( id, GREEN, "%s^x01 Doar cei 2 care au pornit meciul pot folosi aceasta optiune.", TAG );

		return PLUGIN_HANDLED;
	}

	if( g_iStage != WF_TEAMNAME )
	{
		ColorChat( NULL, GREEN, "%s^x01 Nu poti folosi aceasta comanda in stagiul curent.", TAG );

		return PLUGIN_HANDLED;
	}

	if( id == g_iProvoker )
	{
		NamedTeam( id, FIRST, szArg, charsmax( szArg ) );
	}

	else
	{
		NamedTeam( id, SECOND, szArg, charsmax( szArg ) );
	}

	return PLUGIN_HANDLED;
}

public EventNewRound( )
{
	if( !g_iStage )
	{
		return PLUGIN_CONTINUE;
	}

	if( g_bChangeStage )
	{
		new iNextStage = GetStage( NEXT );

		StartWar( iNextStage, false, false );
	}

	switch( g_iStage )
	{
		case WF_TEAMNAME:
		{
			set_task( float( ONE ), "TeamNameMessage", g_iProvoker + TASK_TEAMNAME, _, _, g_szB );
			set_task( float( ONE ), "TeamNameMessage", g_iCaused + TASK_TEAMNAME, _, _, g_szB );
		}

		case WF_CHOOSE:
		{
			ChooseAlliedMenu( g_iWinner, true );
		}
	}

	g_flSpawnTime = get_gametime( );

	return PLUGIN_CONTINUE;
}

public EventTerroWin( )
{
	if( g_iStage == ON )
	{
		if( ( get_gametime( ) - g_flSpawnTime ) < TEN + FIVE )
		{
			ColorChat( NULL, RED, "^x04%s^x01 Punctul a fost anulat (^x03spawn die^x01).", TAG );

			return PLUGIN_CONTINUE;
		}

		new iWinner = GetWinner( );

		g_iScore[ iWinner ]++;

		CheckWin( iWinner, true );
	}

	return PLUGIN_CONTINUE;
}

public EventCounterWin( )
{
	if( g_iStage )
	{
		new CsTeams: iAux;

		iAux = g_iTeams[ FIRST ];
		g_iTeams[ FIRST ] = g_iTeams[ SECOND ];
		g_iTeams[ SECOND ] = iAux;
	}
}

public LogEventRoundEnd( )
{
	g_iRounds++;
}

public EventDeathMsg( )
{
	new iKiller = read_data( ONE );
	new iVictim = read_data( TWO );

	if( !iKiller || iKiller == iVictim )
	{
		return PLUGIN_CONTINUE;
	}

	switch( g_iStage )
	{
		case CHOOSE_ROUND:
		{
			g_bChangeStage = true;

			g_iWinner = iKiller;//
			//ChooseAlliedMenu( iKiller, true );
		}

		case KNIFE_ROUND:
		{
			g_bChangeStage = true;
		}
	}

	return PLUGIN_CONTINUE;
}

public FwdPlayerKilled( id )
{
	Sub( g_iAlive, id );
}

public FwdPlayerSpawn( id )
{
	Add( g_iAlive, id );

	if( g_iStage )
	{
		if( Get( g_iInWar, id ) )
		{
			return  PLUGIN_CONTINUE;
		}

		user_silentkill( id );
		cs_set_user_team( id, CS_TEAM_SPECTATOR );

		ColorChat( id, GREEN, "%s^x01 Ai fost mutat^x03 spectator^x01.", TAG );
	}

	return  PLUGIN_CONTINUE;
}

public MainMenu( id )
{
	new iMenu = menu_create( "\dHide-N-Seek WAR\r D/C^n\wMeniu principal", "MainHandler", NULL );

	switch( g_iWarType[ id ] )
	{
		case SOLO, TEAM:
		{
			menu_additem( iMenu, "\yAlege un adversar^n", g_szNumbers[ ONE ], NULL );
		}

		case SOLO_DEFAULT, TEAM_DEFAULT:
		{
			if( g_iStage != WAITING )
			{
				menu_additem( iMenu, "\yPregateste meciul^n", g_szNumbers[ TWO ], NULL );
			}
		}
	}

	if( g_iStage )
	{
		if( is_user_owner( id ) || id == g_iProvoker || id == g_iCaused )
		{
			if( is_user_owner( id ) )
			{
				switch( g_iStage )
				{
					case WAITING:
					{
						menu_additem( iMenu, "\yPorneste meciul^n", g_szNumbers[ THREE ], NULL );
					}

					case PF_CHOOSE, PF_KNIFE, PF_WAR:
					{
						menu_additem( iMenu, "Sari peste incalzire", g_szNumbers[ FOUR ], NULL );
					}
				}

				menu_additem( iMenu, "Adauga/Retrage puncte", g_szNumbers[ FIVE ], NULL );
			}

			menu_additem( iMenu, "Opreste meciul^n",  g_szNumbers[ SIX ], NULL );
		}
	}

	menu_additem( iMenu, "Setari pentru\y meci", g_szNumbers[ SEVEN ], NULL );
	menu_additem( iMenu, "Setari pentru\y client", g_szNumbers[ EIGHT ], NULL );

	menu_setprop( iMenu, MPROP_EXITNAME, g_szClose );

	menu_display( id, iMenu, NULL );
}

public ChooseEnemyMenu( id )
{
	new iPlayers[ THIRTYTWO ];
	new szName[ THIRTYTWO ];

	new szUserID[ FIVE ];

	new iMenu;
	new iUserID;
	new iNum;
	new player;

	switch( g_iWarType[ id ] )
	{
		case SOLO:
		{
			iMenu = menu_create( "\dHide-N-Seek WAR\r D/C^n\wAlege adversarul", "ChooseEnemyHandler", NULL );
		}

		case TEAM:
		{
			iMenu = menu_create( "\dHide-N-Seek WAR\r D/C^n\wAlege liderul echipei adverse", "ChooseEnemyHandler", NULL );
		}
	}

	get_players( iPlayers, iNum, g_szCH );

	for( new i = NULL; i < iNum; i++ )
	{
		player = iPlayers[ i ];

		if( id == player )
		{
			continue;
		}

		iUserID = get_user_userid( player );

		get_user_name( player, szName, charsmax( szName ) );
		num_to_str( iUserID, szUserID, charsmax( szUserID ) );

		menu_additem( iMenu, szName, szUserID, NULL );
	}

	menu_setprop( iMenu, MPROP_EXITNAME, g_szBack );

	menu_display( id, iMenu, NULL );
}

public PointsMenu( id )
{
	new szAddFirstFormat[ THIRTYTWO ];
	new szAddSecondFormat[ THIRTYTWO ];
	new szSubFirstFormat[ THIRTYTWO ];
	new szSubSecondFormat[ THIRTYTWO ];
	new szActionFormat[ THIRTYTWO ];

	new iMenu;
	new iAction = Get( g_iAction, id );

	if( iAction )
	{
		iMenu = menu_create( "\dHide-N-Seek WAR\r D/C^n\wAdauga puncte", "PointsHandler", NULL );

		formatex( szAddFirstFormat, charsmax( szAddFirstFormat ), "Adauga -\r %s", g_szName[ FIRST ] );
		formatex( szAddSecondFormat, charsmax( szAddSecondFormat ), "Adauga -\r %s^n", g_szName[ SECOND ] );

		menu_additem( iMenu, szAddFirstFormat, g_szNumbers[ ONE ], NULL );
		menu_additem( iMenu, szAddSecondFormat, g_szNumbers[ TWO ], NULL );
		menu_additem( iMenu, "Actiune:\y Adauga", g_szNumbers[ FIVE ], NULL );
	}

	else
	{
		iMenu = menu_create( "\dHide-N-Seek WAR\r D/C^n\wRetrage puncte", "PointsHandler", NULL );

		formatex( szSubFirstFormat, charsmax( szSubFirstFormat ), "Retrage -\r %s", g_szName[ FIRST ] );
		formatex( szSubSecondFormat, charsmax( szSubSecondFormat ), "Retrage -\r %s^n", g_szName[ SECOND ] );

		menu_additem( iMenu, szSubFirstFormat, g_szNumbers[ THREE ], NULL );
		menu_additem( iMenu, szSubSecondFormat, g_szNumbers[ FOUR ], NULL );
		menu_additem( iMenu, "Actiune:\y Retrage", g_szNumbers[ FIVE ], NULL );
	}

	menu_display( id, iMenu, NULL );
}

public WarSettingsMenu( id, iPage )
{
	static szWarType[ ][ ] =
	{
		"Solo",
		"Echipe",
		"Solo prestabilit",
		"Echipe prestabilite"
	};

	new const szON[ ] = "Pornit";
	new const szOFF[ ] = "Oprit";

	new szWarTypeFormat[ THIRTYTWO ];
	new szKnifeReadyFormat[ THIRTYTWO ];
	new szKnifeRoundFormat[ THIRTYTWO ];
	new szWarReadyFormat[ THIRTYTWO ];
	new szMaxRoundsFormat[ THIRTYTWO ];
	new szSpecChatFormat[ THIRTYTWO + TEN ];
	new szPartChatFormat[ THIRTYTWO + TEN ];

	new iMenu = menu_create( "\dHide-N-Seek WAR\r D/C^n\wSetari pentru\y meci", "WarSettingsHandler", NULL );

	formatex( szWarTypeFormat, charsmax( szWarTypeFormat ), "Tip war:\y %s^n", szWarType[ g_iWarType[ id ] ] );
	formatex( szKnifeReadyFormat, charsmax( szKnifeReadyFormat ), "Pregatire pentru cutite:\y %s", GetSetting( id, PF_KNIFE ) ? g_szYes:g_szNo );
	formatex( szWarReadyFormat, charsmax( szWarReadyFormat ), "Pregatire generala:\y %s", GetSetting( id, PF_WAR ) ? g_szYes:g_szNo );
	formatex( szKnifeRoundFormat, charsmax( szKnifeRoundFormat ), "Runda de cutite:\y %s", GetSetting( id, KNIFE_ROUND ) ? g_szYes:g_szNo );
	formatex( szMaxRoundsFormat, charsmax( szMaxRoundsFormat ), "Runde maxime (MR):\y %d", g_iMaxRounds[ id ] );
	formatex( szSpecChatFormat, charsmax( szSpecChatFormat ), "Chat pentru spectatori:\y %s", GetSetting( id, CHAT_SPEC ) ? szON:szOFF );
	formatex( szPartChatFormat, charsmax( szPartChatFormat ), "Chat pentru participanti:\y %s", GetSetting( id, CHAT_PART ) ? szON:szOFF );

	menu_additem( iMenu, szWarTypeFormat, g_szNumbers[ ONE ], NULL );

	switch( g_iWarType[ id ] )
	{
		case SOLO:
		{
			menu_additem( iMenu, szKnifeReadyFormat, g_szNumbers[ THREE ], NULL );
			menu_additem( iMenu, szWarReadyFormat, g_szNumbers[ FOUR ], NULL );
			menu_additem( iMenu, szKnifeRoundFormat, g_szNumbers[ SIX ], NULL );
			menu_additem( iMenu, szMaxRoundsFormat, g_szNumbers[ EIGHT ], NULL );
			menu_additem( iMenu, szSpecChatFormat, g_szNumbers[ NINE ], NULL );
			menu_additem( iMenu, szPartChatFormat, g_szNumbers[ TEN ], NULL );
		}

		case TEAM:
		{
			new szChooseReadyFormat[ THIRTYTWO ];
			new szChooseRoundFormat[ THIRTYTWO ];
			new szPlayersNumFormat[ THIRTYTWO ];

			formatex( szChooseReadyFormat, charsmax( szChooseReadyFormat ), "Pregatire pentru alegeri:\y %s", GetSetting( id, PF_CHOOSE ) ? g_szYes:g_szNo );
			formatex( szChooseRoundFormat, charsmax( szChooseRoundFormat ), "Runda de alegeri:\y %s", GetSetting( id, CHOOSE_ROUND ) ? g_szYes:g_szNo );
			formatex( szPlayersNumFormat, charsmax( szPlayersNumFormat ), "Numar jucatori:\y %dv%d", g_iPlayersNum[ id ], g_iPlayersNum[ id ] );

			menu_additem( iMenu, szChooseReadyFormat, g_szNumbers[ TWO ], NULL );
			menu_additem( iMenu, szKnifeReadyFormat, g_szNumbers[ THREE ], NULL );
			menu_additem( iMenu, szWarReadyFormat, g_szNumbers[ FOUR ], NULL );
			menu_additem( iMenu, szChooseRoundFormat, g_szNumbers[ FIVE ], NULL );
			menu_additem( iMenu, szKnifeRoundFormat, g_szNumbers[ SIX ], NULL );
			menu_additem( iMenu, szPlayersNumFormat, g_szNumbers[ SEVEN ], NULL );
			menu_additem( iMenu, szMaxRoundsFormat, g_szNumbers[ EIGHT ], NULL );
			menu_additem( iMenu, szSpecChatFormat, g_szNumbers[ NINE ], NULL );
			menu_additem( iMenu, szPartChatFormat, g_szNumbers[ TEN ], NULL );
		}

		case SOLO_DEFAULT:
		{
			new szProvokerNameFormat[ THIRTYTWO ];
			new szCausedNameFormat[ THIRTYTWO ];

			if( g_iStage )
			{
				formatex( szProvokerNameFormat, charsmax( szProvokerNameFormat ), "Primul nume:\y %s", g_szName[ FIRST ] );
				formatex( szCausedNameFormat, charsmax( szCausedNameFormat ), "Al doilea nume:\y %s", g_szName[ SECOND ] );
			}

			else
			{
				formatex( szProvokerNameFormat, charsmax( szProvokerNameFormat ), "Primul nume:\y %s", g_szNameSettings[ id ][ FIRST ] );
				formatex( szCausedNameFormat, charsmax( szCausedNameFormat ), "Al doilea nume:\y %s", g_szNameSettings[ id ][ SECOND ] );
			}

			menu_additem( iMenu, szKnifeReadyFormat, g_szNumbers[ THREE ], NULL );
			menu_additem( iMenu, szWarReadyFormat, g_szNumbers[ FOUR ], NULL );
			menu_additem( iMenu, szKnifeRoundFormat, g_szNumbers[ SIX ], NULL );
			menu_additem( iMenu, szMaxRoundsFormat, g_szNumbers[ EIGHT ], NULL );
			menu_additem( iMenu, szSpecChatFormat, g_szNumbers[ NINE ], NULL );
			menu_additem( iMenu, szPartChatFormat, g_szNumbers[ TEN ], NULL );
			menu_additem( iMenu, szProvokerNameFormat, g_szNumbers[ ELEVEN ], NULL );
			menu_additem( iMenu, szCausedNameFormat, g_szNumbers[ TWELVE ], NULL );
		}

		case TEAM_DEFAULT:
		{
			new szChooseReadyFormat[ THIRTYTWO ];
			new szChooseRoundFormat[ THIRTYTWO ];
			new szPlayersNumFormat[ THIRTYTWO ];
			new szFirstTeamFormat[ THIRTYTWO ];
			new szSecondTeamFormat[ THIRTYTWO ];

			formatex( szChooseReadyFormat, charsmax( szChooseReadyFormat ), "Pregatire pentru alegeri:\y %s", GetSetting( id, PF_CHOOSE ) ? g_szYes:g_szNo );
			formatex( szChooseRoundFormat, charsmax( szChooseRoundFormat ), "Runda de alegeri:\y %s", GetSetting( id, CHOOSE_ROUND ) ? g_szYes:g_szNo );
			formatex( szPlayersNumFormat, charsmax( szPlayersNumFormat ), "Numar jucatori:\y %dv%d", g_iPlayersNum[ id ], g_iPlayersNum[ id ] );

			if( g_iStage )
			{
				formatex( szFirstTeamFormat, charsmax( szFirstTeamFormat ), "Prima echipa:\y %s", g_szName[ FIRST ] );
				formatex( szSecondTeamFormat, charsmax( szSecondTeamFormat ), "A doua ecihpa:\y %s", g_szName[ SECOND ] );
			}

			else
			{
				formatex( szFirstTeamFormat, charsmax( szFirstTeamFormat ), "Prima echipa:\y %s", g_szTeamSettings[ id ][ FIRST ] );
				formatex( szSecondTeamFormat, charsmax( szSecondTeamFormat ), "A doua ecihpa:\y %s", g_szTeamSettings[ id ][ SECOND ] );
			}

			menu_additem( iMenu, szChooseReadyFormat, g_szNumbers[ TWO ], NULL );
			menu_additem( iMenu, szKnifeReadyFormat, g_szNumbers[ THREE ], NULL );
			menu_additem( iMenu, szWarReadyFormat, g_szNumbers[ FOUR ], NULL );
			menu_additem( iMenu, szChooseRoundFormat, g_szNumbers[ FIVE ], NULL );
			menu_additem( iMenu, szKnifeRoundFormat, g_szNumbers[ SIX ], NULL );
			menu_additem( iMenu, szPlayersNumFormat, g_szNumbers[ SEVEN ], NULL );
			menu_additem( iMenu, szMaxRoundsFormat, g_szNumbers[ EIGHT ], NULL );
			menu_additem( iMenu, szSpecChatFormat, g_szNumbers[ NINE ], NULL );
			menu_additem( iMenu, szPartChatFormat, g_szNumbers[ TEN ], NULL );
			menu_additem( iMenu, szFirstTeamFormat, g_szNumbers[ THIRTEEN ], NULL );
			menu_additem( iMenu, szSecondTeamFormat, g_szNumbers[ FOURTEEN ], NULL );
		}
	}

	menu_setprop( iMenu, MPROP_BACKNAME, "Inapoi" );
	menu_setprop( iMenu, MPROP_NEXTNAME, "Inainte^n" );
	menu_setprop( iMenu, MPROP_EXITNAME, "Meniu principal" );

	menu_display( id, iMenu, iPage );
}

public ClientSettingsMenu( id )
{
	new szScoreFormat[ THIRTYTWO ];

	new szInfoFormat[ THIRTYTWO * TWO ];

	new iMenu = menu_create( "\dHide-N-Seek WAR\r D/C^n\wSetari pentru\y client", "ClientSettingsHandler", NULL );

	formatex( szScoreFormat, charsmax( szScoreFormat ), "Afiseaza scor:\y %s", Get( g_iShowScore, id ) ? g_szYes:g_szNo );
	formatex( szInfoFormat, charsmax( szInfoFormat ), "Afiseaza informatiile meciului:\y %s", Get( g_iShowInfo, id ) ? g_szYes:g_szNo );

	menu_additem( iMenu, szScoreFormat, g_szBlank, NULL );
	menu_additem( iMenu, szInfoFormat, g_szBlank, NULL );

	menu_setprop( iMenu, MPROP_EXITNAME, g_szBack );

	menu_display( id, iMenu, NULL );
}

public ChallengeMenu( id, iEnemy )
{
	new szTitle[ THIRTYTWO * SIX ];

	new szEnemyName[ THIRTYTWO ];

	new szEnemy[ FIVE ];

	get_user_name( iEnemy, szEnemyName, charsmax( szEnemyName ) );
	num_to_str( iEnemy, szEnemy, charsmax( szEnemy ) );

	switch( g_iWarType[ id ] )
	{
		case SOLO:
		{
			formatex( szTitle, charsmax( szTitle ), "\dHide-N-Seek WAR\r D/C^n\wInformatiile meciului:^nAdversar:\y %s^n\wTipul meciului:\y Solo^n\wRunda de cutite:\y %s^n\wRunde maxime (MR):\y %d",
			szEnemyName, GetSetting( id,  KNIFE_ROUND ) ? g_szYes:g_szNo, g_iMaxRounds[ id ] );
		}

		case TEAM:
		{
			formatex( szTitle, charsmax( szTitle ), "\dHide-N-Seek WAR\r D/C^n\wInformatiile meciului:^nLiderul echipei adverse:\y %s^n\wTipul meciului:\y Echipe^n\wRunda de alegeri:\y %s^n\wRunda de cutite:\y %s^n\wNumarul jucatorilor: %dv%d^n\wRunde maxime (MR):\y %d",
			szEnemyName, GetSetting( id, CHOOSE_ROUND ) ? g_szYes:g_szNo, GetSetting( id,  KNIFE_ROUND ) ? g_szYes:g_szNo, g_iPlayersNum[ id ], g_iPlayersNum[ id ], g_iMaxRounds[ id ] );
		}
	}

	new iMenu = menu_create( szTitle, "ChallengeHandler", NULL );

	menu_additem( iMenu, "Provoaca", szEnemy, NULL );
	menu_additem( iMenu, "Renunta", g_szBlank, NULL );

	menu_setprop( iMenu, MPROP_EXITNAME, g_szBack );

	menu_display( id, iMenu, NULL );
}

public AnswerMenu( id, iEnemy )
{
	new szTitle[ THIRTYTWO * SIX ];

	new szEnemyName[ THIRTYTWO ];

	new szEnemy[ FIVE ];

	get_user_name( iEnemy, szEnemyName, charsmax( szEnemyName ) );
	num_to_str( iEnemy, szEnemy, charsmax( szEnemy ) );

	switch( g_iWarType[ id ] )
	{
		case SOLO:
		{
			formatex( szTitle, charsmax( szTitle ), "\dHide-N-Seek WAR\r D/C^n\y%s\w te provoaca la un meci^nTipul meciului:\y Solo^n\wRunda de cutite:\y %s^n\wRunde maxime (MR):\y %d",
			szEnemyName, GetSetting( iEnemy,  KNIFE_ROUND ) ? g_szYes:g_szNo, g_iMaxRounds[ iEnemy ] );
		}

		case TEAM:
		{
			formatex( szTitle, charsmax( szTitle ), "\dHide-N-Seek WAR\r D/C^n\y%s\w te provoaca la un meci^nTipul meciului:\y Echipe^n\wRunda de alegeri:\y %s^n\wRunda de cutite:\y %s^n\wNumarul jucatorilor: %dv%d^n\wRunde maxime (MR):\y %d",
			szEnemyName, GetSetting( iEnemy, CHOOSE_ROUND ) ? g_szYes:g_szNo, GetSetting( iEnemy,  KNIFE_ROUND ) ? g_szYes:g_szNo, g_iPlayersNum[ iEnemy ], g_iPlayersNum[ iEnemy ], g_iMaxRounds[ iEnemy ] );
		}
	}

	new iMenu = menu_create( szTitle, "AnswerHandler", NULL );

	menu_additem( iMenu, "Accept", szEnemy, NULL );
	menu_additem( iMenu, "Refuz", szEnemy, NULL );

	menu_setprop( iMenu, MPROP_EXIT, MEXIT_NEVER );

	menu_display( id, iMenu, NULL );
}

public VoteMenu( id )
{
	new szTitle[ THIRTYTWO * FOUR ];

	new szProvokerName[ THIRTYTWO ];
	new szCausedName[ THIRTYTWO ];

	get_user_name( g_iProvoker, szProvokerName, charsmax( szProvokerName ) );
	get_user_name( g_iCaused, szCausedName, charsmax( szCausedName ) );

	formatex( szTitle, charsmax( szTitle ), "\dHide-N-Seek WAR\r D/C^n\y%s\w si\y %s\w vor sa inceapa un meci^nEsti de acord ?", szProvokerName, szCausedName );

	new iMenu = menu_create( szTitle, "VoteHandler", NULL );

	menu_additem( iMenu, g_szYes, g_szBlank, NULL );
	menu_additem( iMenu, g_szNo, g_szBlank, NULL );

	menu_setprop( iMenu, MPROP_EXIT, MEXIT_NEVER );

	menu_display( id, iMenu, NULL );
}

public ChooseAlliedMenu( id, bool: bAddChooses )
{
	if( !Get( g_iConnected, id ) )
	{
		return PLUGIN_HANDLED;
	}

	if( bAddChooses )
	{
		g_iChooses[ id ]++;
	}

	if( !g_iChooses[ id ] )
	{
		ColorChat( id, GREEN, "%s^x01 Nu ai acces la aceasta comanda.", TAG );

		return PLUGIN_HANDLED;
	}

	if( TeamFull( CS_TEAM_T ) && TeamFull( CS_TEAM_CT ) )
	{
		g_iChooses[ id ] = NULL;

		ForceChangeStage( );

		return PLUGIN_HANDLED;
	}

	new szName[ THIRTYTWO ];

	new szUserID[ FIVE ];

	new iMenu = menu_create( "\dHide-N-Seek WAR\r D/C^n\wAlege-ti un coechipier", "ChooseAlliedHandler", NULL );
	new iUserID;

	for( new i = ONE; i <= g_iMaxPlayers; i++ )
	{
		if( !Get( g_iConnected, i ) || Get( g_iInWar, i ) )
		{
			continue;
		}

		iUserID = get_user_userid( i );

		get_user_name( i, szName, charsmax( szName ) );
		num_to_str( iUserID, szUserID, charsmax( szUserID ) );

		menu_additem( iMenu, szName, szUserID, NULL );
	}

	menu_setprop( iMenu, MPROP_EXIT, MEXIT_NEVER );

	menu_display( id, iMenu, NULL );

	return PLUGIN_HANDLED;
}

public ChoosePartsMenu( id )
{
	new szName[ THIRTYTWO ];

	new szUserID[ FIVE ];

	new iMenu = menu_create( "\dHide-N-Seek WAR\r D/C^n\yAlege participantii", "ChoosePartsHandler", NULL );

	for( new i = ONE; i <= g_iMaxPlayers; i++ )
	{
		if( !Get( g_iConnected, i ) )
		{
			continue;
		}

		get_user_name( i, szName, charsmax( szName ) );

		num_to_str( get_user_userid( i ), szUserID, charsmax( szUserID ) );

		menu_additem( iMenu, szName, szUserID, NULL );
	}

	menu_setprop( iMenu, MPROP_EXITNAME, g_szClose );

	menu_display( id, iMenu, NULL );

	return PLUGIN_HANDLED;
}

public TransferMenu( id, player )
{
	new szTitle[ THIRTYTWO * FOUR ];

	new szLeader[ THIRTYTWO ];
	new szPlayerName[ THIRTYTWO ];

	new szPlayerID[ FIVE ];

	get_user_name( player, szPlayerName, charsmax( szPlayerName ) );

	formatex( szLeader, charsmax( szLeader ), "Lider:\y %s^n", Get( g_iMenuLeader, id ) ? g_szYes:g_szNo );
	formatex( szTitle, charsmax( szTitle ), "\dHide-N-Seek WAR\r D/C^n\wAlege actiunea pentru\y %s\w:", szPlayerName );
	num_to_str( player, szPlayerID, charsmax( szPlayerID ) );

	new iMenu = menu_create( szTitle, "TransferHandler", NULL );

	menu_additem( iMenu, szLeader, szPlayerID, NULL );
	menu_additem( iMenu, "Muta-l in prima echipa/primul jucator", szPlayerID, NULL );
	menu_additem( iMenu, "Muta-l in a doua echipa/al doilea jucator", szPlayerID, NULL );
	menu_additem( iMenu, "Scoate-l din meci", szPlayerID, NULL );
	menu_additem( iMenu, "Scoate-i pe toti din meci", szPlayerID, NULL );

	menu_setprop( iMenu, MPROP_EXITNAME, g_szBack );

	menu_display( id, iMenu, NULL );
}

public MainHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( iMenu );

		return PLUGIN_HANDLED;
	}

	new szData[ THIRTYTWO * TWO ];
	new szName[ THIRTYTWO * TWO ];

	new _access;
	new iCallback;

	menu_item_getinfo( iMenu, iItem, _access, szData, charsmax( szData ), szName, charsmax( szName ), iCallback );
	menu_destroy( iMenu );

	new iKey = str_to_num( szData );

	switch( iKey )
	{
		case ONE:
		{
			if( g_iStage )
			{
				ColorChat( id, GREEN, "%s^x01 Nu poti folosi aceasta optiune in timpul unui meci.", TAG );

				return PLUGIN_HANDLED;
			}

			if( g_iChallenged )
			{
				ColorChat( id, GREEN, "%s^x01 Altcineva a fost deja provocat.", TAG );

				return PLUGIN_HANDLED;
			}

			if( !EnoughPlayers( id ) )
			{
				ColorChat( id, GREEN, "%s^x01 Sunt prea putini jucatori conectati.", TAG );

				return PLUGIN_HANDLED;
			}

			ChooseEnemyMenu( id );
		}

		case TWO:
		{
			if( g_iStage )
			{
				ColorChat( id, GREEN, "%s^x01 Nu poti folosi aceasta optiune in timpul unui meci.", TAG );

				return PLUGIN_HANDLED;
			}

			if( !EnoughPlayers( id ) )
			{
				ColorChat( id, GREEN, "%s^x01 Sunt prea putini jucatori conectati.", TAG );

				return PLUGIN_HANDLED;
			}

			switch( g_iWarType[ id ] )
			{
				case SOLO_DEFAULT:
				{
					PrepareWar( g_szNameSettings[ id ][ FIRST ], g_szNameSettings[ id ][ SECOND ], NULL, NULL, id );
				}

				case TEAM_DEFAULT:
				{
					PrepareWar( g_szTeamSettings[ id ][ FIRST ], g_szTeamSettings[ id ][ SECOND ], NULL, NULL, id );
				}
			}

			StartWar( WAITING, true, false );

			return PLUGIN_HANDLED;
		}

		case THREE:
		{
			if( g_iStage != WAITING )
			{
				ColorChat( id, GREEN, "%s^x01 Nu poti folosi aceasta optiune decat in etapa de asteptare.", TAG );

				return PLUGIN_HANDLED;
			}

			new iPlayerNum = g_iPlayersNum[ NULL ];

			if( get_team_playersnum( g_iTeams[ FIRST ] ) != iPlayerNum || get_team_playersnum( g_iTeams[ SECOND ] ) != iPlayerNum )
			{
				ColorChat( id, GREEN, "%s^x01 Numarul de jucatori nu corespunde cu cerintele meciului.", TAG );

				return PLUGIN_HANDLED;
			}

			ForceChangeStage( );
		}

		case FOUR:
		{
			if( g_iStage != PF_KNIFE
			&& g_iStage != PF_WAR
			&& g_iStage != PF_CHOOSE )
			{
				ColorChat( id, GREEN, "%s^x01 Nu poti folosi aceasta optiune decat in etapele de pregatire.", TAG );

				return PLUGIN_HANDLED;
			}

			ForceChangeStage( );
		}

		case FIVE:
		{
			if( g_iStage != ON )
			{
				ColorChat( id, GREEN, "%s^x01 Nu poti folosi aceasta optiune decat in timpul meciului propriu-zis.", TAG );

				return PLUGIN_HANDLED;
			}

			PointsMenu( id );
		}

		case SIX:
		{
			if( !g_iStage || g_iStage == VOTE )
			{
				ColorChat( id, GREEN, "%s^x01 Nu poti folosi aceasta optiune decat in timpul unui meci.", TAG );

				return PLUGIN_HANDLED;
			}

			if( id != g_iProvoker && id != g_iCaused && !is_user_owner( id ) )
			{
				ColorChat( id, GREEN, "%s^x01 Doar cei 2 care au pornit meciul pot folosi aceasta optiune.", TAG );

				return PLUGIN_HANDLED;
			}

			StopWar( id, false );
		}

		case SEVEN:
		{
			WarSettingsMenu( id, NULL );
		}

		case EIGHT:
		{
			ClientSettingsMenu( id );
		}
	}

	return PLUGIN_HANDLED;
}

public ChooseEnemyHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		MainMenu( id );

		menu_destroy( iMenu );

		return PLUGIN_HANDLED;
	}

	if( g_iStage )
	{
		menu_destroy( iMenu );

		ColorChat( id, GREEN, "%s^x01 Nu poti folosi aceasta optiune in timpul unui meci.", TAG );

		return PLUGIN_HANDLED;
	}

	if( g_iChallenged )
	{
		menu_destroy( iMenu );

		ColorChat( id, GREEN, "%s^x01 Altcineva a fost deja provocat.", TAG );

		return PLUGIN_HANDLED;
	}

	if( !EnoughPlayers( id ) )
	{
		ColorChat( id, GREEN, "%s^x01 Sunt prea putini jucatori conectati.", TAG );

		return PLUGIN_HANDLED;
	}

	new szData[ THIRTYTWO * TWO ];
	new szName[ THIRTYTWO * TWO ];

	new _access;
	new iCallback;

	menu_item_getinfo( iMenu, iItem, _access, szData, charsmax( szData ), szName, charsmax( szName ), iCallback );
	menu_destroy( iMenu );

	new iUserID = str_to_num( szData );

	new player = find_player( g_szK, iUserID );

	if( !Get( g_iConnected, player ) )
	{
		ColorChat( id, GREEN, "%s^x01 Acest jucator nu mai este conectat.", TAG );

		return PLUGIN_HANDLED;
	}

	ChallengeMenu( id, player );

	return PLUGIN_HANDLED;
}

public PointsHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( iMenu );

		return PLUGIN_HANDLED;
	}

	if( g_iStage != ON )
	{
		menu_destroy( iMenu );

		ColorChat( id, GREEN, "%s^x01 Nu poti folosi aceasta optiune decat in timpul meciului propriu-zis.", TAG );

		return PLUGIN_HANDLED;
	}

	new szData[ THIRTYTWO * TWO ];
	new szName[ THIRTYTWO * TWO ];

	new _access;
	new iCallback;

	menu_item_getinfo( iMenu, iItem, _access, szData, charsmax( szData ), szName, charsmax( szName ), iCallback );
	menu_destroy( iMenu );
	get_user_name( id, szName, charsmax( szName ) );

	new iKey = str_to_num( szData );

	switch( iKey )
	{
		case ONE:
		{
			g_iScore[ FIRST ]++;

			ColorChat( NULL, GREEN, "%s^x03 %s^x01 a adaugat^x04 1^x01 punct %s^x03 %s^x01", TAG, szName, ( g_iWar == SOLO || g_iWar == SOLO_DEFAULT ) ? "lui":"echipei", g_szName[ FIRST ] );

			CheckWin( FIRST, false );
		}

		case TWO:
		{
			g_iScore[ SECOND ]++;

			ColorChat( NULL, GREEN, "%s^x03 %s^x01 a adaugat^x04 1^x01 punct %s^x03 %s^x01", TAG, szName, ( g_iWar == SOLO || g_iWar == SOLO_DEFAULT ) ? "lui":"echipei", g_szName[ SECOND ] );

			CheckWin( SECOND, false );
		}

		case THREE:
		{
			if( !g_iScore[ FIRST ] )
			{
				ColorChat( id, GREEN, "%s^x01 Scorul %s^x03 %s^x01 este deja minim.", TAG, ( g_iWar == SOLO || g_iWar == SOLO_DEFAULT ) ? "lui":"echipei", g_szName[ FIRST ] );

				return PLUGIN_HANDLED;
			}

			else
			{
				g_iScore[ FIRST ]--;

				ColorChat( NULL, GREEN, "%s^x03 %s^x01 a retras^x04 1^x01 punct %s^x03 %s^x01", TAG, szName, ( g_iWar == SOLO || g_iWar == SOLO_DEFAULT ) ? "lui":"echipei", g_szName[ FIRST ] );
			}
		}

		case FOUR:
		{
			if( !g_iScore[ SECOND ] )
			{
				ColorChat( id, GREEN, "%s^x01 Scorul %s^x03 %s^x01 este deja minim.", TAG, ( g_iWar == SOLO || g_iWar == SOLO_DEFAULT ) ? "lui":"echipei", g_szName[ SECOND ] );

				return PLUGIN_HANDLED;
			}

			else
			{
				g_iScore[ SECOND ]--;

				ColorChat( NULL, GREEN, "%s^x03 %s^x01 a retras^x04 1^x01 punct %s^x03 %s^x01", TAG, szName, ( g_iWar == SOLO || g_iWar == SOLO_DEFAULT ) ? "lui":"echipei", g_szName[ SECOND ] );
			}
		}

		case FIVE:
		{
			if( Get( g_iAction, id ) )
			{
				Sub( g_iAction, id );
			}

			else
			{
				Add( g_iAction, id );
			}
		}
	}

	EditScore( g_iStage );
	PointsMenu( id );

	return PLUGIN_HANDLED;
}

public WarSettingsHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		MainMenu( id );

		menu_destroy( iMenu );

		return PLUGIN_HANDLED;
	}

	new szData[ THIRTYTWO * TWO ];
	new szName[ THIRTYTWO * TWO ];

	new _access;
	new iCallback;

	menu_item_getinfo( iMenu, iItem, _access, szData, charsmax( szData ), szName, charsmax( szName ), iCallback );
	menu_destroy( iMenu );

	new iKey = str_to_num( szData );
	new iPage = floatround( float( iItem ) / 6.0001, floatround_floor );

	switch( iKey )
	{
		case ONE:
		{
			new iLastWarType;

			if( is_user_owner( id ) )
			{
				iLastWarType = TEAM_DEFAULT;
			}

			else
			{
				iLastWarType = TEAM;
			}

			if( g_iWarType[ id ]++ == iLastWarType )
			{
				g_iWarType[ id ] = SOLO;
			}
		}

		case TWO:
		{
			if( GetSetting( id, PF_CHOOSE) )
			{
				SubSetting( id, PF_CHOOSE );
			}

			else
			{
				AddSetting( id, PF_CHOOSE );
				AddSetting( id, CHOOSE_ROUND );
			}
		}

		case THREE:
		{
			if( GetSetting( id, PF_KNIFE ) )
			{
				SubSetting( id, PF_KNIFE );
			}

			else
			{
				AddSetting( id, PF_KNIFE );
				AddSetting( id, KNIFE_ROUND );
			}
		}

		case FOUR:
		{
			if( GetSetting( id, PF_WAR ) )
			{
				SubSetting( id, PF_WAR );
			}

			else
			{
				AddSetting( id, PF_WAR );
			}
		}

		case FIVE:
		{
			if( GetSetting( id, CHOOSE_ROUND ) )
			{
				SubSetting( id, PF_CHOOSE );
				SubSetting( id, CHOOSE_ROUND );
			}

			else
			{
				AddSetting( id, CHOOSE_ROUND );
			}
		}

		case SIX:
		{
			if( GetSetting( id, KNIFE_ROUND ) )
			{
				SubSetting( id, PF_KNIFE );
				SubSetting( id, KNIFE_ROUND );
			}

			else
			{
				AddSetting( id, KNIFE_ROUND );
			}
		}

		case SEVEN:
		{
			if( g_iPlayersNum[ id ]++ == FIVE )
			{
				g_iPlayersNum[ id ] = TWO;
			}
		}

		case EIGHT:
		{
			if( g_iMaxRounds[ id ]++ == THREE )
			{
				g_iMaxRounds[ id ] = ONE;
			}
		}

		case NINE:
		{
			if( GetSetting( id, CHAT_SPEC ) )
			{
				SubSetting( id, CHAT_SPEC );
			}

			else
			{
				AddSetting( id, CHAT_SPEC );
			}
		}

		case TEN:
		{
			if( GetSetting( id, CHAT_PART ) )
			{
				SubSetting( id, CHAT_PART );
			}

			else
			{
				AddSetting( id, CHAT_PART );
			}
		}

		case ELEVEN:
		{
			client_cmd( id, "messagemode Primul_nume" );
		}

		case TWELVE:
		{
			client_cmd( id, "messagemode Al_doilea_nume" );
		}

		case THIRTEEN:
		{
			client_cmd( id, "messagemode Prima_echipa" );
		}

		case FOURTEEN:
		{
			client_cmd( id, "messagemode A_doua_echipa" );
		}
	}

	WarSettingsMenu( id, iPage );

	return PLUGIN_HANDLED;
}

public ClientSettingsHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		MainMenu( id );

		menu_destroy( iMenu );

		return PLUGIN_HANDLED;
	}

	menu_destroy( iMenu );

	switch( iItem )
	{
		case NULL:
		{
			if( Get( g_iShowScore, id ) )
			{
				Sub( g_iShowScore, id );
			}

			else
			{
				Add( g_iShowScore, id );
			}
		}

		case ONE:
		{
			if( Get( g_iShowInfo, id ) )
			{
				Sub( g_iShowInfo, id );
			}

			else
			{
				Add( g_iShowInfo, id );
			}
		}
	}

	ClientSettingsMenu( id );

	return PLUGIN_HANDLED;
}

public ChallengeHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		ChooseEnemyMenu( id );

		menu_destroy( iMenu );

		return PLUGIN_HANDLED;
	}

	if( iItem == NULL )
	{
		if( g_iStage )
		{
			menu_destroy( iMenu );

			ColorChat( id, GREEN, "%s^x01 Nu poti folosi aceasta optiune in timpul unui meci.", TAG );

			return PLUGIN_HANDLED;
		}

		if( g_iChallenged )
		{
			menu_destroy( iMenu );

			ColorChat( id, GREEN, "%s^x01 Altcineva a fost deja provocat.", TAG );

			return PLUGIN_HANDLED;
		}

		new szData[ THIRTYTWO * TWO ];
		new szName[ THIRTYTWO * TWO ];

		new _access;
		new iCallback;

		menu_item_getinfo( iMenu, iItem, _access, szData, charsmax( szData ), szName, charsmax( szName ), iCallback );

		new iEnemy = str_to_num( szData );

		if( !Get( g_iConnected, iEnemy ) )
		{
			menu_destroy( iMenu );

			ColorChat( id, GREEN, "%s^x01 Acest jucator nu mai este conectat.", TAG );

			return PLUGIN_HANDLED;
		}

		new szEnemyName[ THIRTYTWO ];

		g_iChallenged = iEnemy;

		get_user_name( id, szName, charsmax( szName ) );
		get_user_name( iEnemy, szEnemyName, charsmax( szEnemyName ) );

		AnswerMenu( iEnemy, id );
		PrepareWar( szName, szEnemyName, id, iEnemy, id );
		StartWar( VOTE, false, false );

		set_task( float( TEN ), "RemoveMenu", iEnemy + TASK_REMOVEMENU );

		ColorChat( NULL, GREEN, "%s^x03 %s^x01 il provoaca pe^x03 %s^x01 la un meci.", TAG, szName, szEnemyName );
	}

	menu_destroy( iMenu );

	return PLUGIN_HANDLED;
}

public AnswerHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( iMenu );

		return PLUGIN_HANDLED;
	}

	new szData[ THIRTYTWO * TWO ];
	new szName[ THIRTYTWO * TWO ];

	new _access;
	new iCallback;

	menu_item_getinfo( iMenu, iItem, _access, szData, charsmax( szData ), szName, charsmax( szName ), iCallback );
	menu_destroy( iMenu );

	new iEnemy = str_to_num( szData );

	if( !Get( g_iConnected, iEnemy ) )
	{
		ColorChat( id, GREEN, "%s^x01 Cel care te-a provocat nu mai este conectat.", TAG );

		return PLUGIN_HANDLED;
	}

	new szEnemyName[ THIRTYTWO ];

	g_iChallenged = NULL;

	get_user_name( id, szName, charsmax( szName ) );
	get_user_name( iEnemy, szEnemyName, charsmax( szEnemyName ) );

	remove_task( id + TASK_REMOVEMENU );

	switch( iItem )
	{
		case NULL:
		{
			StartVote( );

			ColorChat( NULL, GREEN, "%s^x03 %s^x01 a acceptat meciul cu^x03 %s^x01.", TAG, szName, szEnemyName );

			return PLUGIN_HANDLED;
		}

		case ONE:
		{
			StopWar( NULL, false );

			ColorChat( NULL, GREEN, "%s^x03 %s^x01 a refuzat meciul cu^x03 %s^x01.", TAG, szName, szEnemyName );

			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_HANDLED;
}

public VoteHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( iMenu );

		return PLUGIN_HANDLED;
	}

	new szName[ THIRTYTWO ];

	get_user_name( id, szName, charsmax( szName ) );

	switch( iItem )
	{
		case NULL:
		{
			g_iVotes[ YES ]++;

			ColorChat( NULL, RED, "^x04%s^x03 %s^x01 a votat pentru.", TAG, szName );

			return PLUGIN_HANDLED;
		}

		case ONE:
		{
			g_iVotes[ NO ]++;

			ColorChat( NULL, RED, "^x04%s^x03 %s^x01 a votat impotriva.", TAG, szName );

			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_HANDLED;
}

public ChooseAlliedHandler( id, iMenu, iItem )
{
	if( id != g_iProvoker && id != g_iCaused )
	{
		menu_destroy( iMenu );

		ColorChat( id, GREEN, "%s^x01 Doar cei 2 care au pornit meciul pot folosi aceasta optiune.", TAG );

		return PLUGIN_HANDLED;
	}

	if( !g_iChooses[ id ] )
	{
		menu_destroy( iMenu );

		ColorChat( id, GREEN, "%s^x01 Nu poti folosi aceasta comanda.", TAG );

		return PLUGIN_HANDLED;
	}

	new szData[ THIRTYTWO * TWO ];
	new szName[ THIRTYTWO * TWO ];

	new szAlliedName[ THIRTYTWO ];

	new _access;
	new iCallback;

	menu_item_getinfo( iMenu, iItem, _access, szData, charsmax( szData ), szName, charsmax( szName ), iCallback );
	menu_destroy( iMenu );

	new iUserID = str_to_num( szData );
	new player = find_player( g_szK, iUserID );

	if( !Get( g_iConnected, player ) )
	{
		ColorChat( id, GREEN, "%s^x01 Acest jucator nu mai este conectat.", TAG );

		return PLUGIN_HANDLED;
	}

	new CsTeams: iTeam = cs_get_user_team( id );

	if( TeamFull( iTeam ) )
	{
		ColorChat( id, GREEN, "%s^x01 Sunt destui jucatori in aceasta echipa.", TAG );

		return PLUGIN_HANDLED;
	}

	get_user_name( id, szName, charsmax( szName ) );
	get_user_name( player, szAlliedName, charsmax( szAlliedName ) );
	cs_set_user_team( player, iTeam );

	Add( g_iInWar, player );
	g_iChooses[ id ]--;

	ColorChat( NULL, GREEN, "%s^x03 %s^x01 a fost ales de catre^x03 %s^x01.", TAG, szAlliedName, szName );

	if( g_iProvoker == id )
	{
		ChooseAlliedMenu( g_iCaused, true );
	}

	else
	{
		ChooseAlliedMenu( g_iProvoker, true );
	}

	return PLUGIN_HANDLED;
}

public ChoosePartsHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( iMenu );

		return PLUGIN_HANDLED;
	}

	if( !g_iStage )
	{
		menu_destroy( iMenu );

		ColorChat( id, GREEN, "%s^x01 Nu poti folosi aceasta optiune decat in timpul unui meci.", TAG );

		return PLUGIN_HANDLED;
	}

	new szData[ THIRTYTWO * TWO ];
	new szName[ THIRTYTWO * TWO ];

	new _access;
	new iCallback;

	menu_item_getinfo( iMenu, iItem, _access, szData, charsmax( szData ), szName, charsmax( szName ), iCallback );
	menu_destroy( iMenu );

	new iUserID = str_to_num( szData );

	new player = find_player( g_szK, iUserID );

	if( !Get( g_iConnected, player ) )
	{
		ChooseAlliedMenu( id, true );

		ColorChat( id, GREEN, "%s^x01 Acest jucator nu mai este conectat.", TAG );

		return PLUGIN_HANDLED;
	}

	TransferMenu( id, player );

	return PLUGIN_HANDLED;
}

public TransferHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		ChoosePartsMenu( id );

		menu_destroy( iMenu );

		return PLUGIN_HANDLED;
	}

	if( !g_iStage )
	{
		menu_destroy( iMenu );

		ColorChat( id, GREEN, "%s^x01 Nu poti folosi aceasta optiune decat in timpul unui meci.", TAG );

		return PLUGIN_HANDLED;
	}

	new szPlayerName[ THIRTYTWO ];
	new szData[ THIRTYTWO * TWO ];
	new szName[ THIRTYTWO * TWO ];

	new _access;
	new iCallback;

	menu_item_getinfo( iMenu, iItem, _access, szData, charsmax( szData ), szName, charsmax( szName ), iCallback );
	menu_destroy( iMenu );

	new player = str_to_num( szData );

	get_user_name( player, szPlayerName, charsmax( szPlayerName ) );

	switch( iItem)
	{
		case NULL:
		{
			if( Get( g_iMenuLeader, id ) )
			{
				Sub( g_iMenuLeader, id );
			}

			else
			{
				Add( g_iMenuLeader, id );
			}

			TransferMenu( id, player );

			return PLUGIN_HANDLED;
		}

		case ONE:
		{
			if( !Get( g_iConnected, player ) )
			{
				ColorChat( id, GREEN, "%s^x01 Acest jucator nu mai este conectat.", TAG );

				return PLUGIN_HANDLED;
			}

			if( get_team_playersnum( g_iTeams[ FIRST ] ) >= g_iPlayersNum[ NULL ] )
			{
				ColorChat( id, GREEN, "%s^x01 Sunt destui jucatori in aceasta echipa.", TAG );

				return PLUGIN_HANDLED;
			}

			if( !GS_etLeader( player, false ) || Get( g_iMenuLeader, id ) )
			{
				g_iProvoker = player;
			}

			Add( g_iInWar, player );

			cs_set_user_team( player, g_iTeams[ FIRST ] );

			ColorChat( id, RED, "^x04%s^x01 L-ai trimis pe^x03 %s^x01 la prima echipa/primul jucator.", TAG, szPlayerName );
		}

		case TWO:
		{
			if( !Get( g_iConnected, player ) )
			{
				ColorChat( id, GREEN, "%s^x01 Acest jucator nu mai este conectat.", TAG );

				return PLUGIN_HANDLED;
			}

			if( get_team_playersnum( g_iTeams[ SECOND ] ) >= g_iPlayersNum[ NULL ] )
			{
				ColorChat( id, GREEN, "%s^x01 Sunt destui jucatori in aceasta echipa.", TAG );

				return PLUGIN_HANDLED;
			}

			if( !GS_etLeader( player, false ) || Get( g_iMenuLeader, id ) )
			{
				g_iCaused = player;
			}

			Add( g_iInWar, player );

			cs_set_user_team( player, g_iTeams[ SECOND ] );

			ColorChat( id, RED, "^x04%s^x01 L-ai trimis pe^x03 %s^x01 la a doua echipa/al doilea jucator.", TAG, szPlayerName );
		}

		case THREE:
		{
			if( !Get( g_iConnected, player ) )
			{
				ColorChat( id, GREEN, "%s^x01 Acest jucator nu mai este conectat.", TAG );

				return PLUGIN_HANDLED;
			}

			if( cs_get_user_team( id ) == CS_TEAM_SPECTATOR )
			{
				ColorChat( id, GREEN, "%s^x01 Aceasta optiune nu se poate folosi pe spectatori.", TAG );

				return PLUGIN_HANDLED;
			}

			Sub( g_iInWar, player );

			cs_set_user_team( player, CS_TEAM_SPECTATOR );

			GS_etLeader( player, true );

			ColorChat( id, RED, "^x04%s^x01 L-ai scos pe^x03 %s^x01 din meci.", TAG, szPlayerName );
		}

		case FOUR:
		{
			if( get_team_playersnum( g_iTeams[ FIRST ] ) + get_team_playersnum( g_iTeams[ SECOND ] ) == NULL )
			{
				ColorChat( id, GREEN, "%s^x01 Trebuie sa fie mimin un terorist sau un ct pentru a folosi aceasta optiune.", TAG );

				return PLUGIN_HANDLED;
			}

			new iPlayers[ THIRTYTWO ];

			new iNum;

			get_players( iPlayers, iNum, g_szCH );

			for( new i = NULL; i < iNum; i++ )
			{
				player = iPlayers[ i ];

				Sub( g_iInWar, player );

				cs_set_user_team( player, CS_TEAM_SPECTATOR );
			}

			ColorChat( id, RED, "^x04%s^x01 Ai scos toti jucatorii din meci.", TAG );

			return PLUGIN_HANDLED;
		}
	}

	ChoosePartsMenu( id );

	return PLUGIN_HANDLED;
}

public StartVote( )
{
	new iPlayers[ THIRTYTWO ];

	new iNum;
	new player;

	arrayset( g_iVotes, NULL, sizeof g_iVotes );
	get_players( iPlayers, iNum, g_szCH );

	if( iNum == TWO )
	{
		new iCurrentStage = GetStage( CURRENT );

		StartWar( iCurrentStage, true, true );

		return PLUGIN_HANDLED;
	}

	for( new i = NULL; i < iNum; i++ )
	{
		player = iPlayers[ i ];

		if( player == g_iProvoker || player == g_iCaused )
		{
			continue;
		}

		VoteMenu( player );

		set_task( float( TEN ), "RemoveMenu", player + TASK_REMOVEMENU );
	}

	set_task( float( TEN ), "ShowVoteResults" );

	return PLUGIN_HANDLED;
}

public ShowVoteResults( )
{
	new szProvokerName[ THIRTYTWO ];
	new szCausedName[ THIRTYTWO ];

	new iYes = g_iVotes[ YES ];
	new iNo = g_iVotes[ NO ];

	get_user_name( g_iProvoker, szProvokerName, charsmax( szProvokerName ) );
	get_user_name( g_iCaused, szCausedName, charsmax( szCausedName ) );

	if( iYes > iNo )
	{
		new iCurrentStage = GetStage( CURRENT );

		StartWar( iCurrentStage, true, true );

		ColorChat( NULL, RED, "^x04%s^x03 %s^x01 si^x03 %s^x01 isi pot incepe meciul. Voturi pozitive:^x04 %d^x01/^x04%d^x01.", TAG, szProvokerName, szCausedName, iYes, iYes + iNo );
	}

	else
	{
		StopWar( NULL, false );

		ColorChat( NULL, RED, "^x04%s^x03 %s^x01 si^x03 %s^x01 nu isi pot incepe meciul. Voturi negative:^x04 %d^x01/^x04%d^x01.", TAG, szProvokerName, szCausedName, iNo, iYes + iNo );
	}
}

public ShowScore( TASK )
{
	new iPlayers[ THIRTYTWO ];

	new iNum;
	new player;

	get_players( iPlayers, iNum, g_szCH );

	for( new i = NULL; i < iNum; i++ )
	{
		player = iPlayers[ i ];

		if( Get( g_iShowScore, player ) )
		{
			if( Get( g_iAlive, player ) )
			{
				set_hudmessage( 84, 84, 84, -1.0, 0.02, NULL, float( SIX ), float( ONE ) );
			}

			else
			{
				set_hudmessage( 84, 84, 84, -1.0, 0.16, NULL, float( SIX ), float( ONE ) );
			}

			ShowSyncHudMsg( player, g_iSyncHud1, g_szScore );
		}
	}
}

public ShowInfo( TASK )
{
	new szInfoFormat[ THIRTYTWO * TEN ];

	new iPlayers[ THIRTYTWO ];

	new iLen;
	new iNum;
	new player;

	iLen  = formatex( szInfoFormat, charsmax( szInfoFormat ), "Informatii despre meci:^n^n" );
	iLen += formatex( szInfoFormat[ iLen ], charsmax( szInfoFormat ) - iLen, "Durata: %s^n", FormatTime( get_systime( ) - g_iStartTime ) );
	iLen += formatex( szInfoFormat[ iLen ], charsmax( szInfoFormat ) - iLen, "Runde de castigat (MR): %d^n", g_iMaxRounds[ NULL ] );
	iLen += formatex( szInfoFormat[ iLen ], charsmax( szInfoFormat ) - iLen, "Runde jucate: %d", g_iRounds );

	get_players( iPlayers, iNum, g_szCH );

	for( new i = NULL; i < iNum; i++ )
	{
		player = iPlayers[ i ];

		if( Get( g_iShowInfo, player ) )
		{
			if( cs_get_user_team( player ) == CS_TEAM_SPECTATOR )
			{
				set_hudmessage( 84, 84, 84, 0.45, 0.45, NULL, float( SIX ), float( ONE ) );
				ShowSyncHudMsg( player, g_iSyncHud2, szInfoFormat );
			}
		}
	}
}

public TeamNameMessage( id )
{
	id -= TASK_TEAMNAME;

	static const szTeamName[ ] = "Iti poti denumi echipa, tastand ^"/teamname^" in chat";

	set_hudmessage( 84, 84, 84, -1.0, 0.55, NULL, float( SIX ), float( ONE ) );
	ShowSyncHudMsg( id, g_iSyncHud2, szTeamName );
}

public ReadyMessage( id )
{
	id -= TASK_READY;

	static const szReadySolo[ ] = "Cand o sa fi pregatit, scrie ^"/ready^" in chat";
	static const szReadyTeam[ ] = "Cand o sa fiti pregatiti, scrie ^"/ready^" in chat";

	set_hudmessage( 84, 84, 84, -1.0, 0.55, NULL, float( SIX ), float( ONE ) );

	switch( g_iWar )
	{
		case SOLO, SOLO_DEFAULT:
		{
			ShowSyncHudMsg( id, g_iSyncHud2, szReadySolo );
		}

		case TEAM, TEAM_DEFAULT:
		{
			ShowSyncHudMsg( id, g_iSyncHud2, szReadyTeam );
		}
	}
}

public ReadyInfo( TASK )
{
	new szReadyInfo[ THIRTYTWO * THREE ];

	new szProvokerName[ THIRTYTHREE ];
	new szCausedName[ THIRTYTHREE ];

	get_user_name( g_iProvoker, szProvokerName, charsmax( szProvokerName ) );
	get_user_name( g_iCaused, szCausedName, charsmax( szCausedName ) );

	switch( g_iWar )
	{
		case SOLO, SOLO_DEFAULT:
		{
			formatex( szReadyInfo, charsmax( szReadyInfo ), "%s - %s^n%s - %s", szProvokerName, g_bReady[ FIRST ] ? "Pregatit":"Nepregatit", szCausedName, g_bReady[ SECOND ] ? "Pregatit":"Nepregatit" );
		}

		case TEAM, TEAM_DEFAULT:
		{
			formatex( szReadyInfo, charsmax( szReadyInfo ), "%s - %s^n%s - %s", szProvokerName, g_bReady[ FIRST ] ? "Pregatit":"Nepregatit", szCausedName, g_bReady[ SECOND ] ? "Pregatiti":"Nepregatiti" );
		}
	}

	set_hudmessage( 84, 84, 84, 0.04, 0.45, NULL, float( SIX ), float( ONE ) );
	ShowSyncHudMsg( NULL, g_iSyncHud3, szReadyInfo );
}

public RemoveMenu( id )
{
	id -= TASK_REMOVEMENU;

	if( id == g_iChallenged )
	{
		g_iChallenged = NULL;

		StopWar( NULL, false );

		if( !Get( g_iConnected, id ) )
		{
			ColorChat( NULL, GREEN, "%s^x03 Provocatul a iesit de pe server.", TAG );

			return PLUGIN_HANDLED;
		}


		new szName[ THIRTYTWO ];

		get_user_name( id, szName, charsmax( szName ) );

		ColorChat( NULL, GREEN, "%s^x03 %s^x01 nu a raspuns provocarii.", TAG, szName );
	}

	if( Get( g_iConnected, id ) )
	{
		show_menu( id, NULL, "^n", ONE );
	}

	return PLUGIN_HANDLED;
}

stock PrepareWar( const szFirstName[ ], const szSecondName[ ], iProvoker, iCaused, iHost )
{
	g_iProvoker = iProvoker;
	g_iCaused = iCaused;

	Add( g_iInWar, g_iProvoker );
	Add( g_iInWar, g_iCaused );

	g_iWar = g_iWarType[ iHost ];
	g_iMaxRounds[ NULL ] = g_iMaxRounds[ iHost ];
	g_iPlayersNum[ NULL ] = g_iPlayersNum[ iHost ];
	g_iSettings[ NULL ] = g_iSettings[ iHost ];

	copy( g_szName[ FIRST ], charsmax( g_szName[ ] ), szFirstName );
	copy( g_szName[ SECOND ], charsmax( g_szName[ ] ), szSecondName );

	arrayset( g_bReady, false, sizeof g_bReady );
	arrayset( g_bNamedTeam, false, sizeof g_bNamedTeam );

	g_iTeams[ FIRST ] = CS_TEAM_CT;
	g_iTeams[ SECOND ] = CS_TEAM_T;

	switch( g_iWar )
	{
		case SOLO ,SOLO_DEFAULT:
		{
			g_iPlayersNum[ NULL ] = ONE;

			SubSetting( NULL, PF_CHOOSE );
			SubSetting( NULL, CHOOSE_ROUND );
			SubSetting( NULL, WF_CHOOSE );
		}
	}
}

stock StartWar( iStage, bool: bRestart, bool: bTransfer )
{
	if( bRestart )
	{
		new iPlayers[ THIRTYTWO ];

		new iNum;
		new player;

		get_players( iPlayers, iNum, g_szCH );

		for( new i = NULL; i < iNum; i++ )
		{
			player = iPlayers[ i ];

			user_silentkill( player );
			cs_set_user_team( player, CS_TEAM_SPECTATOR );
		}

		server_cmd( "sv_restart 1" );
	}

	if( bTransfer )
	{
		cs_set_user_team( g_iProvoker, CS_TEAM_CT );
		cs_set_user_team( g_iCaused, CS_TEAM_T );
	}

	switch( iStage )
	{
		case PF_CHOOSE, PF_KNIFE, PF_WAR:
		{
			set_task( float( ONE ), "ReadyMessage", g_iProvoker + TASK_READY, _, _, g_szB );
			set_task( float( ONE ), "ReadyMessage", g_iCaused + TASK_READY, _, _, g_szB );
			set_task( float( ONE ), "ReadyInfo", TASK_READYINFO, _, _, g_szB );
		}

		case ON:
		{
			if( !task_exists( TASK_INFO ) )
			{
				set_task( float( ONE ), "ShowInfo", TASK_INFO, _, _, g_szB );

				g_iRounds = NULL;
				g_iStartTime = get_systime( );
			}
		}
	}

	remove_task( g_iProvoker + TASK_TEAMNAME );
	remove_task( g_iCaused + TASK_TEAMNAME );
	remove_task( g_iProvoker + TASK_READY );
	remove_task( g_iCaused + TASK_READY );
	remove_task( TASK_READYINFO );

	g_bChangeStage = false;
	g_iStage = iStage;

	EditScore( iStage );
}

stock StopWar( id, bool: bMessage )
{
	if( id )
	{
		new szName[ THIRTYTWO ];

		get_user_name( id, szName, charsmax( szName ) );

		ColorChat( NULL, GREEN, "%s^x03 %s^x01 a oprit meciul.", TAG, szName );
	}

	else if( bMessage )
	{
		ColorChat( NULL, GREEN, "%s^x01 Meciul a fost oprit.", TAG );
	}

	remove_task( g_iProvoker + TASK_READY );
	remove_task( g_iCaused + TASK_READY );
	remove_task( g_iProvoker + TASK_TEAMNAME );
	remove_task( g_iCaused + TASK_TEAMNAME );
	remove_task( TASK_READYINFO );
	remove_task( TASK_INFO );


	g_iProvoker = NULL;
	g_iCaused = NULL;
	g_iStage = NULL;
	g_iInWar = NULL;
	g_iWarType[ NULL ] = NULL;
	g_iMaxRounds[ NULL ] = NULL;
	g_iPlayersNum[ NULL ] = NULL;
	g_iSettings[ NULL ] = NULL;

	arrayset( g_iScore, NULL, sizeof( g_iScore ) );

	copy( g_szName[ FIRST ], charsmax( g_szName[ ] ), g_szNotAvaible );
	copy( g_szName[ SECOND ], charsmax( g_szName[ ] ), g_szNotAvaible );

	EditScore( NULL );
}

stock EditScore( iStage )
{
	switch( iStage )
	{
		case NULL:
		{
			remove_task( TASK_SCORE );

			return PLUGIN_HANDLED;
		}

		case VOTE:
		{
			return PLUGIN_HANDLED;
		}

		case ON:
		{
			formatex( g_szScore, charsmax( g_szScore ), "%s VS %s^n%d - %d", g_szName[ FIRST ], g_szName[ SECOND ], g_iScore[ FIRST ], g_iScore[ SECOND ] );
		}

		case WAITING:
		{
			formatex( g_szScore, charsmax( g_szScore ), "%s VS %s^nAsteptam jucatorii...", g_szName[ FIRST ], g_szName[ SECOND ] );
		}

		case WF_TEAMNAME:
		{
			formatex( g_szScore, charsmax( g_szScore ), "Asteptam denumirea echipelor..." );
		}

		case PF_CHOOSE:
		{
			formatex( g_szScore, charsmax( g_szScore ), "%s VS %s^nPregatire pentru alegeri", g_szName[ FIRST ], g_szName[ SECOND ] );
		}

		case CHOOSE_ROUND:
		{
			formatex( g_szScore, charsmax( g_szScore ), "%s VS %s^nRunda de alegeri", g_szName[ FIRST ], g_szName[ SECOND ] );
		}

		case WF_CHOOSE:
		{
			formatex( g_szScore, charsmax( g_szScore ), "%s VS %s^nAsteptam alegerile...", g_szName[ FIRST ], g_szName[ SECOND ] );
		}

		case PF_KNIFE:
		{
			formatex( g_szScore, charsmax( g_szScore ), "%s VS %s^nPregatire pentru cutite", g_szName[ FIRST ], g_szName[ SECOND ] );
		}

		case KNIFE_ROUND:
		{
			formatex( g_szScore, charsmax( g_szScore ), "%s VS %s^nRunda de cutite", g_szName[ FIRST ], g_szName[ SECOND ] );
		}

		case PF_WAR:
		{
			formatex( g_szScore, charsmax( g_szScore ), "%s VS %s^nPregatire", g_szName[ FIRST ], g_szName[ SECOND ] );
		}
	}

	if( !task_exists( TASK_SCORE ) )
	{
		set_task( float( ONE ), "ShowScore", TASK_SCORE, _, _, g_szB );
	}

	return PLUGIN_HANDLED;
}

stock Ready( id, iTeam )
{
	if( g_bReady[ GetTheOther( iTeam ) ] )
	{
		arrayset( g_bReady, false, sizeof g_bReady );

		remove_task( g_iProvoker + TASK_READY );
		remove_task( g_iCaused + TASK_READY );
		remove_task( TASK_READYINFO );

		ForceChangeStage( );

		ColorChat( NULL, GREEN, "^x04%s^x01 Ambele parti sunt pregatite.", TAG );

		return PLUGIN_HANDLED;
	}

	else if( g_bReady[ iTeam ] )
	{
		ColorChat( id, GREEN, "%s^x01 Ai folosit deja aceasta comanda.", TAG );

		return PLUGIN_HANDLED;
	}

	else
	{
		g_bReady[ iTeam ] = true;

		switch( g_iWar )
		{
			case SOLO, SOLO_DEFAULT:
			{
				ColorChat( NULL, RED, "^x04%s^x03 %s^x01 este pregatit.", TAG, g_szName[ iTeam ] );

				return PLUGIN_HANDLED;
			}

			case TEAM, TEAM_DEFAULT:
			{
				ColorChat( NULL, RED, "^x04%s^x01 Echipa^x03 %s^x01 este pregatita.", TAG, g_szName[ iTeam ] );

				return PLUGIN_HANDLED;
			}
		}
	}

	return PLUGIN_HANDLED;
}

stock NamedTeam( id, iTeam, szTeamName[ ], iLen )
{
	if( g_bNamedTeam[ iTeam ] )
	{
		ColorChat( id, GREEN, "%s^x01 Ai folosit deja aceasta comanda.", TAG );

		return PLUGIN_HANDLED;
	}

	copy( g_szName[ iTeam ], iLen, szTeamName );

	if( g_bNamedTeam[ GetTheOther( iTeam ) ] )
	{
		remove_task( g_iProvoker + TASK_TEAMNAME );
		remove_task( g_iCaused + TASK_TEAMNAME );

		ForceChangeStage( );
	}

	new szName[ THIRTYTWO ];

	g_bNamedTeam[ iTeam ] = true;

	get_user_name( id, szName, charsmax( szName ) );

	ColorChat( NULL, RED, "^x04%s^x03 %s^x01 si-a denumit echipa cu^x03 %s^x01.", TAG, szName, szTeamName );

	return PLUGIN_HANDLED;
}

stock GetWinner( )
{
	if( g_iTeams[ FIRST ] == _:CS_TEAM_T )
	{
		return FIRST;
	}

	return SECOND;
}

stock CheckWin( iTeam, bool: bRoundEnd )
{
	if( g_iScore[ iTeam ] >= g_iMaxRounds[ NULL ] )
	{
		Won( iTeam );

		return PLUGIN_HANDLED;
	}

	else if( bRoundEnd )
	{
		EditScore( g_iStage );

		set_hudmessage( 88, 88, 88, -1.0, -1.0, NULL, 0.0, 5.0, float( SIX ), 0.2, 1 );
		show_hudmessage( NULL, "%s castiga runda", g_szName[ iTeam ] );

		return PLUGIN_HANDLED;
	}

	return PLUGIN_HANDLED;
}

stock Won( iWinner )
{
	new iLooser = GetTheOther( iWinner );

	switch( g_iWar )
	{
		case SOLO, SOLO_DEFAULT:
		{
			ColorChat( NULL, RED, "^x04%s^x03 %s^x01 a castigat war-ul in fata lui^x03 %s^x01 cu^x04 %d^x01-^x04%d^x01.", TAG, g_szName[ iWinner ], g_szName[ iLooser ], g_iScore[ iWinner ], g_iScore[ iLooser ] );

			//top si prostii
		}

		case TEAM, TEAM_DEFAULT:
		{
			ColorChat( NULL, RED, "^x04%s^x01 Echipa^x03 %s^x01 a castigat war-ul in fata echipei^x03 %s^x01 cu^x04 %d^x01-^x04%d^x01.", TAG, g_szName[ iWinner ], g_szName[ iLooser ], g_iScore[ iWinner ], g_iScore[ iLooser ] );
		}
	}

	StopWar( NULL, false );
}

stock GetStage( iType )
{
	switch( iType )
	{
		case CURRENT:
		{
			switch( g_iWar )
			{
				case SOLO_DEFAULT, TEAM_DEFAULT:
				{
					return WAITING;
				}

				case TEAM:
				{
					return WF_TEAMNAME;
				}
			}

			for( new i = PF_CHOOSE; i <= PF_WAR; i *= TWO )
			{
				if( GetSetting( NULL, i ) )
				{
					return i;
				}
			}
		}

		case NEXT:
		{
			for( new i = g_iStage * TWO; i <= PF_WAR; i *= TWO)
			{
				if( GetSetting( NULL, i ) )
				{
					return i;
				}
			}
		}
	}

	return ON;
}

stock GS_etLeader( id, bool: bMessage )
{
	new iPlayers[ THIRTYTWO ];

	new iNum = get_user_teammates( id, iPlayers );
	new iLeader;
	new player;

	if( !iNum )
	{
		return NULL;
	}

	if( id == g_iProvoker )
	{
		iLeader = iPlayers[ random( iNum ) ];
		g_iProvoker = iLeader;

		if( bMessage )
		{
			ColorChat( iLeader, GREEN, "%s^x01 Tu esti acum noul lider al acestei echipe.", TAG );
		}
	}

	else if( id == g_iCaused )
	{
		iLeader = iPlayers[ random( iNum ) ];
		g_iCaused = iLeader;

		if( bMessage )
		{
			ColorChat( iLeader, GREEN, "%s^x01 Tu esti acum noul lider al acestei echipe.", TAG );
		}
	}

	else
	{
		for( new i = NULL; i < iNum; i++ )
		{
			player = iPlayers[ i ];

			if( player == g_iProvoker || player == g_iCaused )
			{
				iLeader = player;

				break;
			}
		}
	}

	g_iChooses[ id ] = g_iChooses[ iLeader ];

	return iLeader;
}

stock ResetMenuOptions( id )
{
	copy( g_szNameSettings[ id ][ FIRST ], charsmax( g_szNameSettings[ ][ ] ), g_szNotAvaible );
	copy( g_szNameSettings[ id ][ SECOND ], charsmax( g_szNameSettings[ ][ ] ), g_szNotAvaible );
	copy( g_szTeamSettings[ id ][ FIRST ], charsmax( g_szTeamSettings[ ][ ] ), g_szNotAvaible );
	copy( g_szTeamSettings[ id ][ SECOND ], charsmax( g_szTeamSettings[ ][ ] ), g_szNotAvaible );

	g_iWarType[ id ] = SOLO;
	g_iMaxRounds[ id ] = THREE;
	g_iPlayersNum[ id ] = TWO;

	SubSetting( id, PF_CHOOSE );
	AddSetting( id, CHOOSE_ROUND );
	AddSetting( id, WF_CHOOSE );
	SubSetting( id, PF_KNIFE );
	AddSetting( id, KNIFE_ROUND );
	AddSetting( id, PF_WAR );
	AddSetting( id, CHAT_SPEC );
	AddSetting( id, CHAT_PART );
}

stock ForceChangeStage( )
{
	g_bChangeStage = true;

	server_cmd( "sv_restart 1" );
}

stock GetTheOther( iCurrent )
{
	if( iCurrent == FIRST )
	{
		return SECOND;
	}

	return FIRST;
}

stock TeamFull( CsTeams: iTeam )
{
	if( get_team_playersnum( iTeam ) >= g_iPlayersNum[ NULL ] )
	{
		return true;
	}

	return false;
}

stock EnoughPlayers( id )
{
	switch( g_iWarType[ id ] )
	{
		case SOLO, SOLO_DEFAULT:
		{
			if( get_playersnum( ) >= TWO )
			{
				return true;
			}
		}

		case TEAM, TEAM_DEFAULT:
		{
			if( get_playersnum( ) >= g_iPlayersNum[ id ] * TWO)
			{
				return true;
			}
		}
	}

	return false;
}

stock bool: is_user_owner( id )
{
	if( get_user_flags( id ) & ADMIN_RCON )
	{
		return true;
	}

	return false;
}

stock get_user_teammates( id, iPlayers[ THIRTYTWO ] = NULL )
{
	new CsTeams: iTeam = cs_get_user_team( id );

	new iNum;

	for( new i = ONE; i <= g_iMaxPlayers; i++ )
	{
		if( !Get( g_iConnected, i ) )
		{
			continue;
		}

		if( cs_get_user_team( i ) == iTeam )
		{
			iPlayers[ iNum++ ] = i;
		}
	}

	return iNum;
}

stock get_team_playersnum( CsTeams: iTeam )
{
	new iNum;

	for( new i = NULL; i <= g_iMaxPlayers; i++ )
	{
		if( !Get( g_iConnected, i ) )
		{
			continue;
		}

		if( cs_get_user_team( i ) == iTeam )
		{
			iNum++;
		}
	}

	return iNum;
}

stock FormatTime( iSeconds )
{
	new bool: UseFormat;

	new szTime[ THIRTYTWO * TWO ];

	new iMinutes;
	new iHours;

	while( iSeconds >= 60 )
	{
		iSeconds -= 60;
		iMinutes++;
	}

	while( iMinutes >= 60 )
	{
		iMinutes -= 60;
		iHours++;
	}

	if( iSeconds )
	{
		formatex( szTime, charsmax( szTime ), "%i", iSeconds );

		UseFormat = true;
	}

	if( iMinutes )
	{
		if( UseFormat )
		{
			format( szTime, charsmax( szTime ), "%i m %s s", iMinutes, szTime );
		}

		else
		{
			formatex( szTime, charsmax( szTime ), "%i m", iMinutes);

			UseFormat = true;
		}
	}

	if( iHours )
	{
		if( UseFormat )
		{
			format( szTime, charsmax( szTime ), "%i o, %s", iHours, szTime );
		}

		else
		{
			formatex( szTime, charsmax( szTime ), "%i o", iHours );

			UseFormat = true;
		}
	}

	if( !UseFormat )
	{
		copy( szTime,  charsmax( szTime ), "Necunoscut" );
	}

	return  szTime;
}

stock is_right_lenght( id, szString[ ] )
{
	if( strlen( szString ) > MAX_CHARS )
	{
		ColorChat( id, RED, "^x04%s^x01 Numele poate avea maxim^x03 %d^x01 caractere.", TAG, MAX_CHARS );

		return false;
	}

	else if( strlen( szString ) < MIN_CHARS )
	{
		ColorChat( id, RED, "^x04%s^x01 Numele poate avea minim^x03 %d^x01 caractere.", TAG, MIN_CHARS );

		return false;
	}

	return true;
}

// TODO
// sa se poata opri war-ul de oricine daca se joaca de 1 ora+
// la echipe sa nu fie bug la nr de jucatori (prea putini pe sv)
// cum sa isi aleaga liderul coechipierii daca nu sunt alegeri
// choseparts buguit

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
