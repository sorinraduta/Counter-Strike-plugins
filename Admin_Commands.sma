#include < amxmodx >
#include < amxmisc >
#include < cstrike >

#pragma semicolon 1

#define OLD_CONNECTION_QUEUE 10


static const

	PLUGIN[ ]	= "Admin_Commands",
	AUTHOR[ ]	= "AMXX Dev Team", // Rap^ update
	TAG[ ]		= "[D/C]";


new const g_szAddCvar[ ] = "amx_cvar add %s";

new Float: g_flFlooding[ 33 ] = { 0.0, ... };

new Float: g_iPauseAble;

new bool: g_iPaused;
new bool: g_iPauseAllowed = false;

new g_szNames[ OLD_CONNECTION_QUEUE ][ 32 ];
new g_szSteamIDs[ OLD_CONNECTION_QUEUE ][ 32 ];
new g_szIPs[ OLD_CONNECTION_QUEUE ][ 32 ];

new g_iFloodNum[ 33 ] = { 0, ... };

new g_iAccess[ OLD_CONNECTION_QUEUE ];

new g_iLastSize;
new g_iPauseCon;

new pausable;
new rcon_password;


public plugin_init( )
{
	register_plugin( PLUGIN, AMXX_VERSION_STR, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );

	register_clcmd( "amx_rcon",		"ClCmdRcon",		ADMIN_RCON,	"<comanda>" );
	register_clcmd( "amx_showrcon",		"ClCmdShowRcon",	ADMIN_RCON,	"<comanda>" );
	register_clcmd( "pauseAck",		"ClCmdLBack" );

	register_concmd( "slay",		"ConCmdSlay",		ADMIN_SLAY,	"- slay tintei" );
	register_concmd( "slap",		"ConCmdSlap",		ADMIN_SLAY,	"- slap tintei" );
	register_concmd( "kick",		"ConCmdKick",		ADMIN_KICK,	"- kick tintei" );
	register_concmd( "amx_t",		"ConCmdAmxT",		ADMIN_SLAY,	"<nume/#userid>" );
	register_concmd( "amx_ct",		"ConCmdAmxCT",		ADMIN_SLAY,	"<nume/#userid>" );
	register_concmd( "amx_spec",		"ConCmdAmxSpec",	ADMIN_SLAY,	"<nume/#userid>" );
	register_concmd( "amx_switch",		"ConCmdAmxSwitch",	ADMIN_SLAY,	"<nume/#userid> <nume/#userid>" );
	register_concmd( "amx_swap",		"ConCmdAmxSwap",	ADMIN_SLAY,	"- schimba echipele" );
	register_concmd( "amx_slay",		"ConCmdAmxSlay",	ADMIN_SLAY,	"<nume/#userid>" );
	register_concmd( "amx_slap",		"ConCmdAmxSlap",	ADMIN_SLAY,	"<nume/#userid> [daune]" );
	register_concmd( "amx_slayteam",	"ConCmdAmxSlayTeam",	ADMIN_SLAY,	"<1/2/3/[@]T/[@]CT/[@]ALL>" );
	register_concmd( "amx_slapteam",	"ConCmdAmxSlapTeam",	ADMIN_SLAY,	"<1/2/3/[@]T/[@]CT/[@]ALL>" );
	register_concmd( "amx_nick",		"ConCmdAmxNick",	ADMIN_SLAY,	"<nume/#userid> <nume nou>" );
	register_concmd( "amx_kick",		"ConCmdAmxKick",	ADMIN_KICK,	"<nume/#userid> [motiv]" );
	register_concmd( "amx_leave",		"ConCmdAmxLeave",	ADMIN_KICK,	"<tag> [tag] [tag] [tag]" );
	register_concmd( "amx_pause",		"ConCmdAmxPause",	ADMIN_CVAR,	"- pune/scoate pauza jocului" );
	register_concmd( "amx_cvar",		"ConCmdAmxCvar",	ADMIN_CVAR,	"<cvar> [valoare]" );
	register_concmd( "amx_map",		"ConCmdAmxMap",		ADMIN_MAP,	"<harta>" );
	register_concmd( "amx_cfg",		"ConCmdAmxCfg",		ADMIN_CFG,	"<fila>" );
	register_concmd( "amx_last",		"ConCmdAmxLast",	ADMIN_BAN,	"- informatiile ulimilor deconectati" );
	register_concmd( "amx_plugins",		"ConCmdAmxPlugins",	ADMIN_ALL );
	register_concmd( "amx_modules",		"ConCmdAmxModules",	ADMIN_ALL );

	register_dictionary( "admincmd.txt" );
	register_dictionary( "common.txt" );
	register_dictionary( "adminhelp.txt" );

	pausable = get_cvar_pointer( "pausable" );
	rcon_password = get_cvar_pointer( "rcon_password" );
}

public plugin_cfg( )
{
	server_cmd( g_szAddCvar, "rcon_password" );
	server_cmd( g_szAddCvar, "amx_show_activity" );
	server_cmd( g_szAddCvar, "amx_mode" );
	server_cmd( g_szAddCvar, "amx_password_field" );
	server_cmd( g_szAddCvar, "amx_default_access" );
	server_cmd( g_szAddCvar, "amx_reserved_slots" );
	server_cmd( g_szAddCvar, "amx_reservation" );
	server_cmd( g_szAddCvar, "amx_sql_table" );
	server_cmd( g_szAddCvar, "amx_sql_host" );
	server_cmd( g_szAddCvar, "amx_sql_user" );
	server_cmd( g_szAddCvar, "amx_sql_pass" );
	server_cmd( g_szAddCvar, "amx_sql_db" );
	server_cmd( g_szAddCvar, "amx_sql_type" );
}

public client_disconnect( id )
{
	if( !is_user_bot( id ) )
	{
		InsertInfo( id );
	}
}

public ClCmdRcon( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szArg[ 128 ];

	new szAuthid[ 32 ];
	new szName[ 32 ];

	read_args( szArg, charsmax( szArg ) );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );
	get_user_name( id, szName, charsmax( szName ) );

	log_amx( "Cmd: ^"%s <%d><%s><>^" server console (cmdline ^"%s^")", szName, get_user_userid( id ), szAuthid, szArg );

	console_print( id, "[D/C] %L", id, "COM_SENT_SERVER", szArg );
	server_cmd( "%s", szArg );

	return PLUGIN_HANDLED;
}

public ClCmdShowRcon( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szPassword[ 64 ];

	get_pcvar_string( rcon_password, szPassword, charsmax( szPassword ) );

	if( !szPassword[ 0 ] )
	{
		ClCmdRcon( id, iLevel, iCid );
	}

	else
	{
		new szArgs[ 128 ];

		read_args( szArgs, charsmax( szArgs ) );
		client_cmd( id, "rcon_password %s", szPassword );
		client_cmd( id, "rcon %s", szArgs );
	}

	return PLUGIN_HANDLED;
}

public ClCmdLBack( )
{
	if( !g_iPauseAllowed )
	{
		return PLUGIN_CONTINUE;
	}

	new szPaused[ 25 ];

	format( szPaused, charsmax( szPaused ), "%L", g_iPauseCon, g_iPaused ? "UNPAUSED" : "PAUSED" );
	set_cvar_float( "pausable", g_iPauseAble );
	console_print( g_iPauseCon, "%s Server %s", TAG, szPaused );

	g_iPauseAllowed = false;

	g_iPaused = !g_iPaused;

	return PLUGIN_HANDLED;
}

public ConCmdSlay( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 1 ) )
	{
		return PLUGIN_HANDLED;
	}

	new iTarget;
	new iBody;
	new iMaxPlayers = get_maxplayers( ) + 1;

	get_user_aiming( id, iTarget, iBody, 9999 ); //distanta poate fi mai mare!?

	if( 0 < iTarget < iMaxPlayers && is_user_alive( iTarget ) )
	{
		Slay( id, iTarget );
	}

	return PLUGIN_HANDLED;
}

public ConCmdSlap( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 1 ) )
	{
		return PLUGIN_HANDLED;
	}

	new iTarget;
	new iBody;
	new iMaxPlayers = get_maxplayers( ) + 1;

	get_user_aiming( id, iTarget, iBody, 9999 ); //distanta poate fi mai mare!?

	if( 0 < iTarget < iMaxPlayers && is_user_alive( iTarget ) )
	{
		Slap( id, iTarget );
	}

	return PLUGIN_HANDLED;
}

public ConCmdKick( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 1 ) )
	{
		return PLUGIN_HANDLED;
	}

	new iTarget;
	new iBody;
	new iMaxPlayers = get_maxplayers( ) + 1;

	get_user_aiming( id, iTarget, iBody, 9999 ); //distanta poate fi mai mare?

	if( 0 < iTarget < iMaxPlayers && is_user_alive( iTarget ) )
	{
		Kick( id, iTarget );
	}

	return PLUGIN_HANDLED;
}

public ConCmdAmxT( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szArg[ 32 ];

	read_argv( 1, szArg, charsmax( szArg ) );

	new iPlayer = cmd_target( id, szArg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );

	if( !iPlayer )
	{
		return PLUGIN_HANDLED;
	}

	if( cs_get_user_team( iPlayer ) == CS_TEAM_T )
	{
		console_print( id, "%s Jucatorul  este deja terorist.", TAG );

		return PLUGIN_HANDLED;
	}

	new szName[ 32 ];
	new szAuthid[ 32 ];
	new szPlayerName[ 32 ];
	new szPlayerAuthid[ 32 ];

	if( is_user_alive( iPlayer ) )
	{
		user_silentkill( iPlayer );
	}

	get_user_name( id, szName, charsmax( szName ) );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );
	get_user_name( iPlayer, szPlayerName, charsmax( szPlayerName ) );
	get_user_authid( iPlayer, szPlayerAuthid, charsmax( szPlayerAuthid ) );

	cs_set_user_team( iPlayer, CS_TEAM_T );

	log_amx( "Cmd: ^"%s <%d><%s><>^" transfer ^"%s <%d><%s><>^" to terrorists team.", szName, get_user_userid( id ), szAuthid, szPlayerName, get_user_userid( iPlayer ), szPlayerAuthid );

	client_print( 0, print_chat, "ADMIN %s: transfer %s to terrorists", szName, szPlayerName );

	console_print( id, "ADMIN %s: transfer %s to terrorists", szName, szPlayerName );

	return PLUGIN_HANDLED;
}

public ConCmdAmxCT( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szArg[ 32 ];

	read_argv( 1, szArg, charsmax( szArg ) );

	new iPlayer = cmd_target( id, szArg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );

	if( !iPlayer )
	{
		return PLUGIN_HANDLED;
	}

	if( cs_get_user_team( iPlayer ) == CS_TEAM_CT )
	{
		console_print( id, "%s Jucatorul  este deja counter-terorist.", TAG );

		return PLUGIN_HANDLED;
	}

	new szName[ 32 ];
	new szAuthid[ 32 ];
	new szPlayerName[ 32 ];
	new szPlayerAuthid[ 32 ];

	if( is_user_alive( iPlayer ) )
	{
		user_silentkill( iPlayer );
	}

	get_user_name( id, szName, charsmax( szName ) );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );
	get_user_name( iPlayer, szPlayerName, charsmax( szPlayerName ) );
	get_user_authid( iPlayer, szPlayerAuthid, charsmax( szPlayerAuthid ) );

	cs_set_user_team( iPlayer, CS_TEAM_CT );

	log_amx( "Cmd: ^"%s <%d><%s><>^" transfer ^"%s <%d><%s><>^" to counter-terrorists team.", szName, get_user_userid( id ), szAuthid, szPlayerName, get_user_userid( iPlayer ), szPlayerAuthid );

	client_print( 0, print_chat, "ADMIN %s: transfer %s to counter-terrorists", szName, szPlayerName );

	console_print( id, "ADMIN %s: transfer %s to counter-terrorists", szName, szPlayerName );

	return PLUGIN_HANDLED;
}

public ConCmdAmxSpec( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szArg[ 32 ];

	read_argv( 1, szArg, charsmax( szArg ) );

	new iPlayer = cmd_target( id, szArg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );

	if( !iPlayer )
	{
		return PLUGIN_HANDLED;
	}

	if( cs_get_user_team( iPlayer ) == CS_TEAM_SPECTATOR )
	{
		console_print( id, "%s Jucatorul  este deja spectator.", TAG );

		return PLUGIN_HANDLED;
	}

	new szName[ 32 ];
	new szAuthid[ 32 ];
	new szPlayerName[ 32 ];
	new szPlayerAuthid[ 32 ];

	if( is_user_alive( iPlayer ) )
	{
		user_silentkill( iPlayer );
	}

	get_user_name( id, szName, charsmax( szName ) );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );
	get_user_name( iPlayer, szPlayerName, charsmax( szPlayerName ) );
	get_user_authid( iPlayer, szPlayerAuthid, charsmax( szPlayerAuthid ) );

	cs_set_user_team( iPlayer, CS_TEAM_SPECTATOR );

	log_amx( "Cmd: ^"%s <%d><%s><>^" transfer ^"%s <%d><%s><>^" to spectators team.", szName, get_user_userid( id ), szAuthid, szPlayerName, get_user_userid( iPlayer ), szPlayerAuthid );

	client_print( 0, print_chat, "ADMIN %s: transfer %s to spectators", szName, szPlayerName );

	console_print( id, "ADMIN %s: transfer %s to spectators", szName, szPlayerName );

	return PLUGIN_HANDLED;
}

public ConCmdAmxSwitch( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szArg[ 32 ];
	new szArg2[ 32 ];

	read_argv( 1, szArg, charsmax( szArg ) );
	read_argv( 2, szArg2, charsmax( szArg2 ) );

	new iPlayer = cmd_target( id, szArg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
	new iPlayer2 = cmd_target( id, szArg2, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );

	if( !iPlayer || !iPlayer2 )
	{
		return PLUGIN_HANDLED;
	}

	new szName[ 32 ];
	new szAuthid[ 32 ];
	new szPlayerName[ 32 ];
	new szPlayerAuthid[ 32 ];
	new szPlayer2Name[ 32 ];
	new szPlayer2Authid[ 32 ];

	if( is_user_alive( iPlayer ) )
	{
		user_silentkill( iPlayer );
	}

	if( is_user_alive( iPlayer2 ) )
	{
		user_silentkill( iPlayer2 );
	}

	get_user_name( id, szName, charsmax( szName ) );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );
	get_user_name( iPlayer, szPlayerName, charsmax( szPlayerName ) );
	get_user_authid( iPlayer, szPlayerAuthid, charsmax( szPlayerAuthid ) );
	get_user_name( iPlayer2, szPlayer2Name, charsmax( szPlayer2Name ) );
	get_user_authid( iPlayer2, szPlayer2Authid, charsmax( szPlayer2Authid ) );

	new CsTeams: iTeam = cs_get_user_team( iPlayer );
	new CsTeams: iTeam2 = cs_get_user_team( iPlayer2 );

	cs_set_user_team( iPlayer, iTeam2 );
	cs_set_user_team( iPlayer2, iTeam );

	log_amx( "Cmd: ^"%s <%d><%s><>^" switched ^"%s's <%d><%s><>^" and ^"%s's <%d><%s><>^" teams.",
	szName, get_user_userid( id ), szAuthid, szPlayerName, get_user_userid( iPlayer ), szPlayerAuthid, szPlayer2Name, get_user_userid( iPlayer2 ), szPlayer2Authid );

	client_print( 0, print_chat, "ADMIN %s: switched %s's and %s's teams ", szName, szPlayerName, szPlayer2Name );

	console_print( id, "ADMIN %s: switched %s's and %s's teams ", szName, szPlayerName, szPlayer2Name );

	return PLUGIN_HANDLED;
}

public ConCmdAmxSwap( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 1 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szName[ 32 ];
	new szAuthid[ 32 ];
	new iPlayers[ 32 ];

	new iNum;
	new iPlayer;

	get_players( iPlayers, iNum, "ch" );

	for( new i = 0; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];

		if( is_user_alive( iPlayer ) )
		{
			user_silentkill( iPlayer );
		}

		switch( cs_get_user_team( iPlayer ) )
		{
			case CS_TEAM_T:
			{
				cs_set_user_team( iPlayer, CS_TEAM_CT );
			}

			case CS_TEAM_CT:
			{
				cs_set_user_team( iPlayer, CS_TEAM_T );
			}
		}
	}

	get_user_name( id, szName, charsmax( szName ) );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );

	log_amx( "Cmd: ^"%s <%d><%s><>^" swap the teams.", szName, get_user_userid( id ), szAuthid );

	client_print( 0, print_chat, "ADMIN %s: swap the teams ", szName );

	console_print( id, "ADMIN %s: swap the teams ", szName );

	return PLUGIN_HANDLED;
}

public ConCmdAmxSlay( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szArg[ 32 ];

	read_argv( 1, szArg, charsmax( szArg ) );

	new iSlayed = cmd_target( id, szArg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE );

	if( !iSlayed )
	{
		return PLUGIN_HANDLED;
	}

	Slay( id, iSlayed );

	return PLUGIN_HANDLED;
}

public ConCmdAmxSlap( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szArg[ 32 ];

	read_argv( 1, szArg, charsmax( szArg ) );

	new iSlapped = cmd_target( id, szArg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE );

	if( !iSlapped )
	{
		return PLUGIN_HANDLED;
	}

	Slap( id, iSlapped );

	return PLUGIN_HANDLED;
}

public ConCmdAmxSlayTeam( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szName[ 32 ];

	new szTeam[ 5 ];

	read_argv( 1, szTeam, charsmax( szTeam ) );
	get_user_name( id, szName, charsmax( szName ) );

	if( equali( szTeam, "1" ) || equali( szTeam, "T" ) || equali( szTeam, "@T" ) )
	{
		SlayTeam( CS_TEAM_T );

		client_print( 0, print_chat, "ADMIN %s: slay terrorists", szName );
	}

	else if( equali( szTeam, "2" ) || equali( szTeam, "CT" ) || equali( szTeam, "@CT" ) )
	{
		SlayTeam( CS_TEAM_CT );

		client_print( 0, print_chat, "ADMIN %s: slay counter-terrorists", szName );
	}

	else if( equali( szTeam, "3" ) || equali( szTeam, "ALL" ) || equali( szTeam, "@ALL" ) )
	{
		SlayTeam( CS_TEAM_T );
		SlayTeam( CS_TEAM_CT );

		client_print( 0, print_chat, "ADMIN %s: slay all players", szName );
	}

	return PLUGIN_HANDLED;
}

public ConCmdAmxSlapTeam( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szName[ 32 ];

	new szTeam[ 5 ];
	new szPower[ 4 ];

	read_argv( 1, szTeam, charsmax( szTeam ) );
	read_argv( 2, szPower, charsmax( szPower ) );
	get_user_name( id, szName, charsmax( szName ) );

	new iDamage = max( 0, str_to_num( szPower ) );

	if( equali( szTeam, "1" ) || equali( szTeam, "T" ) || equali( szTeam, "@T" ) )
	{
		SlapTeam( CS_TEAM_T, iDamage );

		client_print( 0, print_chat, "ADMIN %s: slap terrorists", szName );
	}

	else if( equali( szTeam, "2" ) || equali( szTeam, "CT" ) || equali( szTeam, "@CT" ) )
	{
		SlapTeam( CS_TEAM_CT, iDamage );

		client_print( 0, print_chat, "ADMIN %s: slap counter-terrorists", szName );
	}

	else if( equali( szTeam, "3" ) || equali( szTeam, "ALL" ) || equali( szTeam, "@ALL" ) )
	{
		SlapTeam( CS_TEAM_T, iDamage );
		SlapTeam( CS_TEAM_CT, iDamage );

		client_print( 0, print_chat, "ADMIN %s: slap all players", szName );
	}

	return PLUGIN_HANDLED;
}

public ConCmdAmxNick( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 3 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szArg[ 32 ];
	new szNewName[ 32 ];
	new szName[ 32 ];
	new szAuthid[ 32 ];
	new szPlayerName[ 32 ];
	new szPlayerAuthid[ 32 ];

	read_argv( 1, szArg, charsmax( szArg ) );
	read_argv( 2, szNewName, charsmax( szNewName ) );

	new iPlayer = cmd_target( id, szArg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );

	if( !iPlayer )
	{
		return PLUGIN_HANDLED;
	}

	get_user_name( id, szName, charsmax( szName ) );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );
	get_user_name( iPlayer, szPlayerName, charsmax( szPlayerName ) );
	get_user_authid( iPlayer, szPlayerAuthid, charsmax( szPlayerAuthid ) );

	client_cmd( iPlayer, "name ^"%s^"", szNewName );

	log_amx( "Cmd: ^"%s <%d><%s><>^" change nick to ^"%s^" ^"%s <%d><%s><>^"", szName, get_user_userid( id ), szAuthid, szNewName, szPlayerName, get_user_userid( iPlayer ), szPlayerAuthid );

	show_activity_key( "ADMIN_NICK_1", "ADMIN_NICK_2", szName, szPlayerName, szNewName );

	console_print( id, "[D/C] %L", id, "CHANGED_NICK", szPlayerName, szNewName );

	return PLUGIN_HANDLED;
}

public ConCmdAmxKick( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szArg[ 32 ];

	read_argv( 1, szArg, charsmax( szArg ) );

	new iKicked = cmd_target( id, szArg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );

	if( !iKicked )
	{
		return PLUGIN_HANDLED;
	}

	Kick( id, iKicked );

	return PLUGIN_HANDLED;
}

public ConCmdAmxLeave( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szlTags[ 4 ][ 32 ];

	new szlReason[ 128 ];

	new szNick[ 32 ];
	new szName[ 32 ];
	new szAuthid[ 32 ];

	new iRes;
	new iCount = 0;
	new ilTagsNum = 0;
	new iArgNum = read_argc( );
	new iMaxPlayers = get_maxplayers( ) + 1;

	for( new i = 1; i < 5; ++i )
	{
		if( i < iArgNum )
		{
			read_argv( i, szlTags[ ilTagsNum++ ], charsmax( szlTags[ ] ) );
		}

		else
		{
			szlTags[ ilTagsNum++ ][ 0 ] = 0;
		}
	}

	for( new j = 1; j < iMaxPlayers; ++j )
	{
		if( !is_user_connected( j ) && !is_user_connecting( j ) )
		{
			continue;
		}

		get_user_name( j, szNick, charsmax( szNick ) );

		iRes = HasTag( szNick, szlTags, ilTagsNum );

		if( iRes != -1 )
		{
			console_print( id, "[D/C] %L", id, "SKIP_MATCH", szNick, szlTags[ iRes ] );

			continue;
		}

		if( get_user_flags( j ) & ADMIN_IMMUNITY )
		{
			console_print( id, "[D/C] %L", id, "SKIP_IMM", szNick );

			continue;
		}

		console_print( id, "[D/C] %L", id, "KICK_PL", szNick );

		if( is_user_bot( j ) )
		{
			server_cmd( "kick #%d", get_user_userid( j ) );
		}

		else
		{
			format( szlReason, charsmax( szlReason ), "%L", j, "YOU_DROPPED" );

			server_cmd( "kick #%d ^"%s^"", get_user_userid( j ), szlReason );
		}

		iCount++;
	}

	get_user_name( id, szName, charsmax( szName ) );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );

	log_amx( "Kick: ^"%s <%d><%s><>^" leave some group (tag1 ^"%s^") (tag2 ^"%s^") (tag3 ^"%s^") (tag4 ^"%s^")", szName, get_user_userid( id ), szAuthid, szlTags[ 0 ], szlTags[ 1 ], szlTags[ 2 ], szlTags[ 3 ] );

	show_activity_key( "ADMIN_LEAVE_1", "ADMIN_LEAVE_2", szName, szlTags[ 0 ], szlTags[ 1 ], szlTags[ 2 ], szlTags[ 3 ] );

	console_print( id, "[D/C] %L", id, "KICKED_CLIENTS", iCount );

	return PLUGIN_HANDLED;
}

public ConCmdAmxPause( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 1 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szName[ 32 ];
	new szAuthid[ 32 ];

	new iSlayer = id;

	get_user_name( id, szName, charsmax( szName ) );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );

	if( pausable != 0 )
	{
		g_iPauseAble = get_pcvar_float( pausable );
	}

	if( !iSlayer )
	{
		iSlayer = find_player( "h" );
	}

	if( !iSlayer )
	{
		console_print( id, "[D/C] %L", id, "UNABLE_PAUSE" );

		return PLUGIN_HANDLED;
	}

	new iMaxPlayers = get_maxplayers( );

	g_iPauseAllowed = true;
	g_iPauseCon = id;

	set_cvar_float( "pausable", 1.0 );

	for( new i = 1; i <= iMaxPlayers; i++ )
	{
		if( is_user_connected( i ) && !is_user_bot( i ) )
		{
			show_activity_id( i, id, szName, "%L server", i, g_iPaused ? "UNPAUSE" : "PAUSE" );
		}
	}

	client_cmd( iSlayer, "pause;pauseAck" );

	log_amx( "Cmd: ^"%s<%d><%s><>^" %s server", szName, get_user_userid( id ), szAuthid, g_iPaused ? "unpause" : "pause" );

	console_print( id, "[D/C] %L", id, g_iPaused ? "UNPAUSING" : "PAUSING" );

	return PLUGIN_HANDLED;
}

public ConCmdAmxCvar( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szArg2[ 64 ];

	new szArg[ 32 ];

	new iPointer;

	read_argv( 1, szArg, charsmax( szArg ) );
	read_argv( 2, szArg2, charsmax( szArg ) );

	if( equal( szArg, "add" ) && ( get_user_flags( id ) & ADMIN_RCON ) )
	{
		if( ( iPointer = get_cvar_pointer( szArg2 ) ) != 0 )
		{
			new iFlags = get_pcvar_flags( iPointer );

			if( !( iFlags & FCVAR_PROTECTED ) )
			{
				set_pcvar_flags( iPointer, iFlags | FCVAR_PROTECTED );
			}
		}

		return PLUGIN_HANDLED;
	}

	if( ( iPointer = get_cvar_pointer( szArg ) ) == 0 )
	{
		console_print( id, "[D/C] %L", id, "UNKNOWN_CVAR", szArg );

		return PLUGIN_HANDLED;
	}

	if( OnlyRcon( szArg ) && !( get_user_flags( id ) & ADMIN_RCON ) )
	{
		if( !( equali( szArg,"sv_password" ) && ( get_user_flags( id ) & ADMIN_PASSWORD ) ) )
		{
			console_print( id, "[D/C] %L", id, "CVAR_NO_ACC" );

			return PLUGIN_HANDLED;
		}
	}

	if( read_argc( ) < 3 )
	{
		get_pcvar_string( iPointer, szArg2, charsmax( szArg2 ) );

		console_print( id, "[D/C] %L", id, "CVAR_IS", szArg, szArg2 );

		return PLUGIN_HANDLED;
	}

	new szCvarValue[ 64 ];

	new szName[ 32 ];
	new szAuthid[ 32 ];

	new iMaxPlayers = get_maxplayers( );

	get_user_name( id, szName, charsmax( szName ) );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );

	for( new i = 1; i <= iMaxPlayers; i++ )
	{
		if( is_user_connected( i ) && !is_user_bot( i ) )
		{
			if( get_pcvar_flags( iPointer ) & FCVAR_PROTECTED || equali( szArg, "rcon_password" ) )
			{
				formatex( szCvarValue, charsmax( szCvarValue ), "*** %L ***", i, "PROTECTED" );
			}

			else
			{
				copy( szCvarValue, charsmax( szCvarValue ), szArg2 );
			}

			show_activity_id( i, id, szName, "%L", i, "SET_CVAR_TO", "", szArg, szCvarValue );
		}
	}

	set_cvar_string( szArg, szArg2 );

	log_amx( "Cmd: ^"%s <%d><%s><>^" set cvar (name ^"%s^") (value ^"%s^")", szName, get_user_userid( id ), szAuthid, szArg, szArg2 );

	console_print( id, "[D/C] %L", id, "CVAR_CHANGED", szArg, szArg2 );

	return PLUGIN_HANDLED;
}

public ConCmdAmxCfg( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szArg[ 128 ];

	read_argv( 1, szArg, charsmax( szArg ) );

	if( !file_exists( szArg ) )
	{
		console_print( id, "[D/C] %L", id, "FILE_NOT_FOUND", szArg );

		return PLUGIN_HANDLED;
	}

	new szName[ 32 ];
	new szAuthid[ 32 ];

	get_user_name( id, szName, charsmax( szName ) );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );

	server_cmd( "exec %s", szArg );

	log_amx( "Cmd: ^"%s <%d><%s><>^" execute cfg (file ^"%s^")", szName, get_user_userid( id ), szAuthid, szArg );

	show_activity_key( "ADMIN_CONF_1", "ADMIN_CONF_2", szName, szArg );

	console_print( id, "[D/C] Executing file ^"%s^"", szArg );

	return PLUGIN_HANDLED;
}

public ConCmdAmxMap( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szArg[ 32 ];

	new iArgLen = read_argv( 1, szArg, charsmax( szArg ) );

	if( !is_map_valid( szArg ) )
	{
		console_print( id, "[D/C] %L", id, "MAP_NOT_FOUND" );

		return PLUGIN_HANDLED;
	}

	new szName[ 32 ];
	new szAuthid[ 32 ];

	new szModName[ 10 ];

	get_modname( szModName, charsmax( szModName ) );

	if( !equal( szModName, "zp") )
	{
		message_begin( MSG_ALL, SVC_INTERMISSION );
		message_end( );
	}

	get_user_name( id, szName, charsmax( szName ) );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );

	set_task( 2.0, "ChangeMap", 0, szArg, iArgLen + 1 );

	log_amx( "Cmd: ^"%s <%d><%s><>^" changelevel ^"%s^"", szName, get_user_userid( id ), szAuthid, szArg );

	show_activity_key( "ADMIN_MAP_1", "ADMIN_MAP_2", szName, szArg );

	return PLUGIN_HANDLED;
}

public ConCmdAmxLast( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 1 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szName[ 32 ];
	new szAuthid[ 32 ];
	new szIP[ 32 ];
	new szFlags[ 32 ];

	new iAccess;

	console_print( id, "%19s %20s %15s %s", "Nick", "Steamid", "IP", "Rang" );

	for( new i = 0; i < g_iLastSize; i++ )
	{
		GetInfo( i, szName, charsmax( szName ), szAuthid, charsmax( szAuthid ), szIP, charsmax( szIP ), iAccess );

		get_flags( iAccess, szFlags, charsmax( szFlags ) );

		console_print( id, "%19s %20s %15s %s", szName, szAuthid, szIP, szFlags );
	}

	console_print( id, "%d deconectar%s salvat%s.", g_iLastSize, g_iLastSize == 1 ? "e":"i", g_iLastSize == 1 ? "a":"e" );

	return PLUGIN_HANDLED;
}

public ConCmdAmxPlugins( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 1 ) )
	{
		return PLUGIN_HANDLED;
	}

	if( id == 0 )
	{
		server_cmd( "amxx plugins" );
		server_exec( );

		return PLUGIN_HANDLED;
	}

	new szName[ 32 ];
	new szVersion[ 32 ];
	new szAuthor[ 32 ];
	new szFileName[ 32 ];
	new szStatus[ 32 ];
	new szlName[ 32 ];
	new szlVersion[ 32 ];
	new szlAuthor[ 32 ];
	new szlFile[ 32 ];
	new szlStatus[ 32 ];

	format( szlName, charsmax( szlName ), "%L", id, "NAME" );
	format( szlVersion, charsmax( szlVersion ), "%L", id, "VERSION" );
	format( szlAuthor, charsmax( szlAuthor ), "%L", id, "AUTHOR" );
	format( szlFile, charsmax( szlFile ), "%L", id, "FILE" );
	format( szlStatus, charsmax( szlStatus ), "%L", id, "STATUS" );

	new szTemp[ 96 ];

	new iStartid = 0;
	new iEndid;
	new iRunning = 0;
	new iNum = get_pluginsnum( );

	if( read_argc( ) > 1 )
	{
		read_argv( 1, szTemp, charsmax( szTemp ) );
		iStartid = str_to_num( szTemp ) - 1;
	}

	iEndid = min( iStartid + 10, iNum );

	console_print( id, "----- %L -----", id, "LOADED_PLUGINS" );
	console_print( id, "%-18.17s %-11.10s %-17.16s %-16.15s %-9.8s", szlName, szlVersion, szlAuthor, szlFile, szlStatus );

	new i = iStartid;

	while( i < iEndid )
	{
		get_plugin( i++, szFileName, charsmax( szFileName ), szName, charsmax( szName ), szVersion, charsmax( szVersion ), szAuthor, charsmax( szAuthor ), szStatus, charsmax( szStatus ) );
		console_print( id, "%-18.17s %-11.10s %-17.16s %-16.15s %-9.8s", szName, szVersion, szAuthor, szFileName, szStatus );

		if( szStatus[ 0 ] == 'd' || szStatus[ 0 ] == 'r' )
		{
			iRunning++;
		}
	}

	console_print( id, "%L", id, "PLUGINS_RUN", iEndid - iStartid, iRunning );
	console_print( id, "----- %L -----", id, "HELP_ENTRIES", iStartid + 1, iEndid, iNum );

	if( iEndid < iNum )
	{
		formatex( szTemp, charsmax( szTemp ), "----- %L -----", id, "HELP_USE_MORE", iEndid + 1 );
		replace_all( szTemp, charsmax( szTemp ), "amx_help", "amx_plugins" );
		console_print( id, "%s", szTemp );
	}

	else
	{
		formatex( szTemp, charsmax( szTemp ), "----- %L -----", id, "HELP_USE_BEGIN" );
		replace_all( szTemp, charsmax( szTemp ), "amx_help", "amx_plugins" );
		console_print( id, "%s", szTemp );
	}

	return PLUGIN_HANDLED;
}

public ConCmdAmxModules( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 1 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szName[ 32 ];
	new szVersion[ 32 ];
	new szAuthor[ 32 ];
	new szStatus[ 32 ];
	new szlName[ 32 ];
	new szlVersion[ 32 ];
	new szlAuthor[ 32 ];
	new szlStatus[ 32 ];

	new iStatus;

	format( szlName, charsmax( szlName ), "%L", id, "NAME" );
	format( szlVersion, charsmax( szlVersion ), "%L", id, "VERSION" );
	format( szlAuthor, charsmax( szlAuthor ), "%L", id, "AUTHOR" );
	format( szlStatus, charsmax( szlStatus ), "%L", id, "STATUS" );

	new iNum = get_modulesnum( );

	console_print( id, "%L:", id, "LOADED_MODULES" );
	console_print( id, "%-23.22s %-11.10s %-20.19s %-11.10s", szlName, szlVersion, szlAuthor, szlStatus );

	for( new i = 0; i < iNum; i++ )
	{
		get_module( i, szName, charsmax( szName ), szAuthor, charsmax( szAuthor ), szVersion, charsmax( szVersion ), iStatus );

		switch( iStatus )
		{
			case module_loaded:
			{
				copy( szStatus, 15, "running" );
			}

			default:
			{
				new szUnknown[ ] = "unknown";

				copy( szStatus, 15, "bad load" );
				copy( szName, charsmax( szName ), szUnknown );
				copy( szAuthor, charsmax( szAuthor ), szUnknown );
				copy( szVersion, charsmax( szVersion ), szUnknown );
			}
		}

		console_print( id, "%-23.22s %-11.10s %-20.19s %-11.10s", szName, szVersion, szAuthor, szStatus );
	}

	console_print( id, "%L", id, "NUM_MODULES", iNum );

	return PLUGIN_HANDLED;
}

public ChangeMap( szMap[ ] )
{
	server_cmd( "changelevel %s", szMap );
}

stock Slay( id, iSlayed )
{
	user_kill( iSlayed );

	new szName[ 32 ];
	new szAuthid[ 32 ];
	new szSlayedName[ 32 ];
	new szSlayedAuthid[ 32 ];

	get_user_name( id, szName, charsmax( szName ) );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );
	get_user_name( iSlayed, szSlayedName, charsmax( szSlayedName ) );
	get_user_authid( iSlayed, szSlayedAuthid, charsmax( szSlayedAuthid ) );

	log_amx( "Cmd: ^"%s <%d><%s><>^" slay ^"%s <%d><%s><>^"", szName, get_user_userid( id ), szAuthid, szSlayedName, get_user_userid( iSlayed ), szSlayedAuthid );

	show_activity_key( "ADMIN_SLAY_1", "ADMIN_SLAY_2", szName, szSlayedName );

	console_print( id, "[D/C] %L", id, "CLIENT_SLAYED", szSlayedName );
}

stock Slap( id, iSlapped )
{
	new Float: flGameTime = get_gametime( );

	if( g_flFlooding[ id ] > flGameTime )
	{
		if( g_iFloodNum[ id ] >= 6 )
		{
			client_print( id, print_center, "Te rugam sa te opresti din a face abuz de slap" );
			client_print( id, print_notify, "%s Te rugam sa te opresti din a face abuz de slap.", TAG );

			g_flFlooding[ id ] = flGameTime + 1.0;

			return PLUGIN_HANDLED;
		}

		g_iFloodNum[ id ]++;
	}

	else if( g_iFloodNum[ id ] )
	{
		g_iFloodNum[ id ] = 0;
	}

	g_flFlooding[ id ] = flGameTime + 1.0;

	new szName[ 32 ];
	new szAuthid[ 32 ];
	new szSlappedName[ 32 ];
	new szSlappedAuthid[ 32 ];
	new szPower[ 32 ];

	read_argv( 2, szPower, charsmax( szPower ) );

	new iDamage = max( 0, str_to_num( szPower ) );

	user_slap( iSlapped, iDamage );

	get_user_name( id, szName, charsmax( szName ) );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );
	get_user_name( iSlapped, szSlappedName, charsmax( szSlappedName ) );
	get_user_authid( iSlapped, szSlappedAuthid, charsmax( szSlappedAuthid ) );

	log_amx( "Cmd: ^"%s <%d><%s><>^" slap with %d damage ^"%s <%d><%s><>^"", szName, get_user_userid( id ), szAuthid, iDamage, szSlappedName, get_user_userid( iSlapped ), szSlappedAuthid );

	show_activity_key( "ADMIN_SLAP_1", "ADMIN_SLAP_2", szName, szSlappedName, iDamage );

	console_print( id, "[D/C] %L", id, "CLIENT_SLAPED", szSlappedName, iDamage );

	return PLUGIN_HANDLED;
}

stock Kick( id, iKicked )
{
	new szName[ 32 ];
	new szAuthid[ 32 ];
	new szKickedName[ 32 ];
	new szKickedAuthid[ 32 ];
	new szReason[ 32 ];

	new iKickedUserid;

	get_user_name( id, szName, charsmax( szName ) );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );
	get_user_name( iKicked, szKickedName, charsmax( szKickedName ) );
	get_user_authid( iKicked, szKickedAuthid, charsmax( szKickedAuthid ) );
	iKickedUserid = get_user_userid( iKicked );
	read_argv( 2, szReason, charsmax( szReason ) );
	remove_quotes( szReason );

	log_amx( "Kick: ^"%s <%d><%s><>^" kick ^"%s <%d><%s><>^" (Reason: ^"%s^")", szName, get_user_userid( id ), szAuthid, szKickedName, iKickedUserid, szKickedAuthid, szReason );

	show_activity_key( "ADMIN_KICK_1", "ADMIN_KICK_2", szName, szKickedName );

	if( is_user_bot( iKicked ) )
	{
		server_cmd( "kick #%d", iKickedUserid );
	}

	else
	{
		if( szReason[ 0 ] )
		{
			server_cmd( "kick #%d ^"%s^"", iKickedUserid, szReason );
		}

		else
		{
			server_cmd( "kick #%d", iKickedUserid );
		}
	}

	console_print( id, "[D/C] Client ^"%s^" kicked", szKickedName );
}

stock SlayTeam( CsTeams: iTeam )
{
	new iMaxPlayers = get_maxplayers( );

	for( new id = 1; id <= iMaxPlayers; id++ )
	{
		if( !is_user_connected( id ) || !is_user_alive( id ) || cs_get_user_team( id ) != iTeam )
		{
			continue;
		}

		user_silentkill( id );
	}
}

stock SlapTeam( CsTeams: iTeam, iDamage )
{
	new iMaxPlayers = get_maxplayers( );

	for( new id = 1; id <= iMaxPlayers; id++ )
	{
		if( !is_user_connected( id ) || !is_user_alive( id ) || cs_get_user_team( id ) != iTeam )
		{
			continue;
		}

		user_slap( id, iDamage, 1 );
	}
}

stock bool: OnlyRcon( const szName[ ] )
{
	new iPointer = get_cvar_pointer( szName );

	if( iPointer && get_pcvar_flags( iPointer ) & FCVAR_PROTECTED )
	{
		return true;
	}

	return false;
}

stock HasTag( szName[ ], szTags[ 4 ][ 32 ], iTagsNum )
{
	for( new i = 0; i < iTagsNum; ++i )
	{
		if( contain( szName, szTags[ i ] ) != -1 )
		{
			return i;
		}
	}

	return -1;
}

stock InsertInfo( id )
{
	if( g_iLastSize >= sizeof g_szSteamIDs )
	{
		for( new i = 1; i < sizeof  g_szSteamIDs; i++ )
		{
			copy( g_szNames[ i - 1 ], charsmax( g_szNames[ ] ), g_szNames[ i ] );
			copy( g_szIPs[ i - 1 ], charsmax( g_szIPs[ ] ), g_szIPs[ i ] );
			copy( g_szSteamIDs[ i - 1 ], charsmax( g_szSteamIDs[ ] ), g_szSteamIDs[ i ] );

			g_iAccess[ i - 1 ] = g_iAccess[ i ];
		}

		g_iLastSize = min( g_iLastSize, sizeof g_szSteamIDs - 1 );
	}

	get_user_authid( id, g_szSteamIDs[ g_iLastSize ], charsmax( g_szSteamIDs[ ] ) );
	get_user_name( id, g_szNames[ g_iLastSize ], charsmax( g_szNames[ ] ) );
	get_user_ip( id, g_szIPs[ g_iLastSize ], charsmax( g_szIPs[ ] ), 1 );

	g_iAccess[ g_iLastSize ] = get_user_flags( id );

	++g_iLastSize;
}
/*
stock InsertInfo( id )
{
	if( g_iSize > 0 )
	{
		new szIP[ 32 ];
		new szAuthid[ 32 ];

		new iLast = 0;

		get_user_ip( id, szIP, charsmax( szIP ), 1 );
		get_user_authid( id, szAuthid, charsmax( szAuthid ) );

		if( g_iSize < sizeof g_szSteamIDs )
		{
			iLast = g_iSize - 1;
		}

		else
		{
			iLast = g_iTracker - 1;

			if( iLast < 0 )
			{
				iLast = g_iSize - 1;
			}
		}

		if( equal( szAuthid, g_szSteamIDs[ iLast ] ) && equal( szIP, g_szIPs[ iLast ] ) )
		{
			get_user_name( id, g_szNames[ iLast ], charsmax( g_szNames[ ] ) );

			g_iAccess[ iLast ] = get_user_flags( id );

			return;
		}
	}

	new iTarget = 0;

	if( g_iSize < sizeof g_szSteamIDs )
	{
		iTarget = g_iSize;

		++g_iSize;
	}

	else
	{
		iTarget = g_iTracker;

		++g_iTracker;

		if( g_iTracker == sizeof g_szSteamIDs )
		{
			g_iTracker = 0;
		}
	}

	get_user_authid( id, g_szSteamIDs[ iTarget ], charsmax( g_szSteamIDs[ ] ) );
	get_user_name( id, g_szNames[ iTarget ], charsmax( g_szNames[ ] ) );
	get_user_ip( id, g_szIPs[ iTarget ], charsmax( g_szIPs[ ] ), 1 );

	g_iAccess[ iTarget ] = get_user_flags( id );
}
*/
stock GetInfo( i, szName[ ], iNameLen, szAuthid[ ], iAuthidLen, szIP[ ], iIPLen, &iAccess )
{
	if( i >= g_iLastSize )
	{
		abort( AMX_ERR_NATIVE, "GetInfo: Out of bounds (%d:%d)", i, g_iLastSize );
	}

	copy( szName, iNameLen, g_szNames[ i ] );
	copy( szAuthid, iAuthidLen, g_szSteamIDs[ i ] );
	copy( szIP, iIPLen, g_szIPs[ i ] );

	iAccess = g_iAccess[ i ];
}
