#include < amxmodx >
#include < cstrike >
#include < fakemeta >
#include < engine >
#include < hamsandwich >

#pragma semicolon 1

#define Set(%1,%2)			(%1 |= 1 << (%2 & 31))
#define Sub(%1,%2)			(%1 &= ~(1 << (%2 & 31)))
#define Get(%1,%2)			(%1 & 1 << (%2 & 31))


static const

	PLUGIN[ ] =		"HideNSeek_Disconnect",
	VERSION[ ] =		"1.0",
	AUTHOR[ ] =		"Rap^^";


new const g_szCH[ ] =		"ch";
new const g_szACEH[ ] =		"aceh";
new const g_szTERRORIST[ ] =	"TERRORIST";
new const g_szCT[ ] =		"CT";
new const g_szHostageEntity[ ] =	"hostage_entity";
new const g_szWeaponStrip[ ] =	"player_weaponstrip";

new const NULL =			0;

new bool: g_bRoundEnd;

new g_iConnected;
new g_iAlive;
new g_iMaxPlayers;

new g_iMsgTeamInfo;

new g_iSyncHud;


public plugin_precache( )
{
	CreateHostage( );
}

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, VERSION, FCVAR_SERVER );
	
	register_logevent( "LogEventRoundStart", 2, "1=Round_Start" );
	register_logevent( "LogEventRoundEnd", 2, "1=Round_End" );
	
	new const szPlayer[ ] = "player";
	
	RegisterHam( Ham_Spawn,		szPlayer,	"FwdPlayerSpawn", true );
	RegisterHam( Ham_Killed,	szPlayer,	"FwdPlayerKilled", true );
	RegisterHam( Ham_TakeDamage,	szPlayer,	"FwdTakeDamage", false );
	
	g_iMaxPlayers = get_maxplayers( );
	
	new g_iHostagePos	= get_user_msgid( "HostagePos" );
	g_iMsgTeamInfo		= get_user_msgid( "TeamInfo" );
	
	set_msg_block( g_iHostagePos, BLOCK_SET );
	
	g_iSyncHud = CreateHudSyncObj( );
}

public plugin_unpause( )
{
	CreateHostage( );
	UpdateInfo( );
}

public client_putinserver( id )
{
	Set( g_iConnected, id );
	Sub( g_iAlive, id );
}

public client_disconnect( id )
{
	Sub( g_iConnected, id );
	Sub( g_iAlive, id );
}

public LogEventRoundStart( )
{
	g_bRoundEnd = false;
}

public LogEventRoundEnd( )
{
	new CsTeams: iWinner = CS_TEAM_CT;
	
	new szMessage[ 128 ];
	
	new iHiders[ 32 ];
	new iSeekers[ 32 ];
	
	new iHidersNum;
	new iSeekersNum;
	
	g_bRoundEnd = true;
	
	get_players( iHiders, iHidersNum, g_szACEH, g_szTERRORIST );
	get_players( iSeekers, iSeekersNum, g_szACEH, g_szCT );
	
	if( !iHidersNum && !iSeekersNum )
	{
		return PLUGIN_CONTINUE;
	}
	
	if( iHidersNum )
	{
		iWinner = CS_TEAM_T;
	}
	
	switch( iWinner )
	{
		case CS_TEAM_T:
		{
			new Float: flFrags;
			
			for( new id = 1; id <= g_iMaxPlayers; id++ )
			{
				if( !Get( g_iConnected, id ) || !Get( g_iAlive, id ) )
				{
					continue;
				}
				
				if( cs_get_user_team( id ) == CS_TEAM_T )
				{
					pev( id, pev_frags, flFrags );
					set_pev( id, pev_frags, flFrags + 5 );
				}
			}
			
			formatex( szMessage, charsmax( szMessage ), "Runda castigata de echipa Hiders" );
		}
		
		case CS_TEAM_CT:
		{
			set_task( 0.1, "SwapTeams" );
			
			formatex( szMessage, charsmax( szMessage ), "Runda castigata de echipa Seekers" );
		}
		
	}
	
	set_hudmessage( 88, 88, 88, -1.0, 0.40, NULL, 6.0, 5.0, 0.1, 0.2, -1 );
	ShowSyncHudMsg( NULL, g_iSyncHud, szMessage );
	
	return PLUGIN_CONTINUE;
}

public FwdPlayerSpawn( id ) 
{
	Set( g_iAlive, id );
	
	GiveGear( id );
}

public FwdPlayerKilled( id )
{
	Sub( g_iAlive, id );
}

public FwdTakeDamage( id, iInflictor, iAttacker, Float: flDamage, iDamageBits )
{
	if( !iAttacker || id == iAttacker
	|| !Get( g_iConnected, id ) || !Get( g_iConnected, iAttacker )
	|| cs_get_user_team( id ) == cs_get_user_team( iAttacker ) )
	{
		return HAM_IGNORED;
	}
	
	if( g_bRoundEnd )
	{
		SetHamParamFloat( 4, 0.0 );
		
		client_print( iAttacker, print_center, "Prea tarziu, runda deja s-a terminat" );
		
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public SwapTeams( )
{
	new iPlayers[ 32 ];
	
	new iNum;
	new player;
	
	get_players( iPlayers, iNum, g_szCH );
	
	for( new i = NULL; i < iNum; i++ )
	{
		player = iPlayers[ i ];
		
		switch( cs_get_user_team( player ) )
		{
			case CS_TEAM_T:
			{
				cs_set_user_team( player, CS_TEAM_CT );
			
				eMakeTeamInfo( player, g_szTERRORIST );
			}
			
			case CS_TEAM_CT:
			{
				cs_set_user_team( player, CS_TEAM_T );
			
				eMakeTeamInfo( player, g_szCT );
			}
		}
	}
}

public MessageHostagePos( const iMsgid, const iMsgDest, const id )
{
	return PLUGIN_HANDLED;
}

stock CreateHostage( )
{
	new iHostage;
	new iHostageEntity = engfunc( EngFunc_AllocString, g_szHostageEntity );
	
	do
	{
		iHostage = engfunc( EngFunc_CreateNamedEntity, iHostageEntity );
	}
	while( !pev_valid( iHostage ) );
	
	engfunc( EngFunc_SetOrigin, iHostage, Float: { 0.0, 0.0, -55000.0 } );
	engfunc( EngFunc_SetSize, iHostage, Float: { -1.0, -1.0, -1.0 }, Float: { 1.0, 1.0, 1.0 } );
	dllfunc( DLLFunc_Spawn, iHostage );
}

stock GiveGear( id )
{
	if( !Get( g_iConnected, id ) || !Get( g_iAlive, id ) )
	{
		return PLUGIN_HANDLED;
	}
	
	fm_strip_user_weapons( id );
	
	switch( cs_get_user_team( id ) )
	{
		case CS_TEAM_T:
		{
			fm_give_item( id, "weapon_knife" );
			fm_give_item( id, "weapon_smokegrenade" );
			fm_give_item( id, "weapon_flashbang" );
			cs_set_user_bpammo( id, CSW_FLASHBANG, 2 );
		}
		
		case CS_TEAM_CT:
		{
			fm_give_item( id, "weapon_knife" );
		}
	}
	
	return PLUGIN_HANDLED;
}

stock UpdateInfo( )
{
	g_iConnected = NULL;
	g_iAlive = NULL;
	
	for( new i = 1; i < g_iMaxPlayers; i++ )
	{
		if( is_user_connected( i ) )
		{
			Set( g_iConnected, i );
			
			if( is_user_alive( i ) )
			{
				Set( g_iAlive, i );
			}
		}
	}
}

stock eMakeTeamInfo( id, const szTeam[ ] )
{
	emessage_begin( MSG_ALL, g_iMsgTeamInfo );
	ewrite_byte( id );
	ewrite_string( szTeam );
	emessage_end( );
}

stock fm_strip_user_weapons( id ) 
{
	new iEnt = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, g_szWeaponStrip ) );

	if( !pev_valid( iEnt ) )
	{
		return NULL;
	}

	dllfunc( DLLFunc_Spawn, iEnt );
	dllfunc( DLLFunc_Use, iEnt, id );
	engfunc( EngFunc_RemoveEntity, iEnt );

	return 1;
}

stock fm_give_item( id, const szItem[ ] ) 
{
	if( !equal( szItem, "weapon_", 7 )
	&& !equal( szItem, "ammo_", 5 )
	&& !equal( szItem, "item_", 5 ) )
	{
		return NULL;
	}

	new iEnt = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, szItem ) );

	if( !pev_valid( iEnt ) )
	{
		return NULL;
	}

	new Float: flOrigin[ 3 ];

	pev( id, pev_origin, flOrigin );
	set_pev( iEnt, pev_origin, flOrigin );
	set_pev( iEnt, pev_spawnflags, pev( iEnt, pev_spawnflags ) | SF_NORESPAWN );
	dllfunc( DLLFunc_Spawn, iEnt );

	new iSave = pev( iEnt, pev_solid );

	dllfunc( DLLFunc_Touch, iEnt, id );

	if( pev( iEnt, pev_solid ) != iSave )
	{
		return iEnt;
	}

	engfunc( EngFunc_RemoveEntity, iEnt );

	return -1;
}
