#include < amxmodx >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >
#include < hnswar >
#include < bits >

#pragma semicolon 1

#define is_user_valid_alive(%1)		(0 < %1 <= g_iMaxPlayers && Get(g_iAlive,%1))


static const
	
	PLUGIN[ ] =			"HideNSeek_Require",
	VERSION[ ] =			"1.0",
	AUTHOR[ ] =			"Rap^^";


new const g_szBuyCommands[ ][ ] =
{
	"usp", "glock", "deagle", "p228", "elites",
	"fn57", "m3", "xm1014", "mp5", "tmp", "p90",
	"mac10", "ump45", "ak47", "galil", "famas",
	"sg552", "m4a1", "aug", "scout", "awp", "g3sg1",
	"sg550", "m249", "vest", "vesthelm", "flash",
	"hegren", "sgren", "defuser", "nvgs", "shield",
	"primammo", "secammo", "km45", "9x19mm", "nighthawk",
	"228compact", "fiveseven", "12gauge", "autoshotgun",
	"mp", "c90", "cv47", "defender", "clarion",
	"krieg552", "bullpup", "magnum", "d3au1", "krieg550"
};

new const g_szEntityClassNames[ ][ ] =
{
	"func_door",
	"func_door_rotating",
	"func_vip_safetyzone",
	"func_escapezone",
	"func_bomb_target",
	"info_bomb_target",
	"monster_scientist",
	"armoury_entity"
};

new const g_szPopDogClassName[ ] =	"PopDog_Entity";
new const g_szPopDogSprite[ ] =		"sprites/popdog.spr";
new const g_szKnifeModel_v[ ] =		"models/v_knife.mdl";
new const g_szKnifeModel_p[ ] =		"models/p_knife.mdl";

new const MAX_RGB =			255;
new const HIDE_MONEY =			(1<<5);

new Float: g_flPopDogOrigin[ 3 ] =	{ 128.031585, 447.918457, 800.185778 };
new Float: g_flPopDogAngle[ 3 ] =	{ 0.0, 90.0, 0.0 };

new Float: g_flPopDogScale =		0.902;

new CsTeams: g_iTeam[ 33 ];

new g_szName[ 33 ][ 32 ];

new hns_semiclip;

new g_iConnected;
new g_iAlive;
new g_iSolid;
new g_iRestoreSolid;
new g_iShowKnife;
new g_iMaxPlayers;

new g_iMsgHideWeapon;
new g_iMsgScreenFade;
new g_iMsgTextMsg;

new g_iSyncHud;


public plugin_precache( )
{
	precache_model( g_szPopDogSprite );
	
	register_forward( FM_Spawn, "FwdSpawn" );
}

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );
	
	new const szClCmdHandle[ ] = "ClCmdHandle";
	
	register_clcmd( "buy",			szClCmdHandle );
	register_clcmd( "buyammo1",		szClCmdHandle );
	register_clcmd( "buyammo2",		szClCmdHandle );
	register_clcmd( "buyequip",		szClCmdHandle );
	register_clcmd( "cl_autobuy",		szClCmdHandle );
	register_clcmd( "cl_rebuy",		szClCmdHandle );
	register_clcmd( "cl_setautobuy",	szClCmdHandle );
	register_clcmd( "cl_setrebuy",		szClCmdHandle );
	register_clcmd( "say /knife",	"ClCmdKnife" );
	
	hns_semiclip = register_cvar( "hns_semiclip", "1", 0, 0.0 );
	
	new const szB[ ] = "b";
	
	register_event( "CurWeapon",	"EventCurWeapon", szB, "1=1");
	
	register_logevent( "LogEventRoundStart", 2, "1=Round_Start" );
	
	new const szPlayer[ ] = "player";
	
	RegisterHam( Ham_Spawn,		szPlayer,	"FwdPlayerSpawn", true );
	RegisterHam( Ham_Killed,	szPlayer,	"FwdPlayerKilled", true );
	
	register_forward( FM_AddToFullPack,		"FwdAddToFullPackPost", true );
	register_forward( FM_CmdStart,			"FwdCmdStart" );
	register_forward( FM_GetGameDescription,	"FwdGetGameDescription", false );
	register_forward( FM_PlayerPreThink,		"FwdPlayerPreThink", false );
	register_forward( FM_PlayerPostThink,		"FwdPlayerPostThink", false );
	register_forward( FM_TraceLine,			"FwdTraceLine", true );
	
	g_iMaxPlayers = get_maxplayers( );
	
	g_iMsgHideWeapon = get_user_msgid( "HideWeapon" );
	g_iMsgScreenFade = get_user_msgid( "ScreenFade" );
	g_iMsgTextMsg	= get_user_msgid( "TextMsg" );
	
	register_message( g_iMsgHideWeapon,	"MessageHideWeapon" );
	register_message( g_iMsgScreenFade,	"MessageScreenFade" );
	register_message( g_iMsgTextMsg,	"MessageTextMsg" );
	
	g_iSyncHud = CreateHudSyncObj( );
	
	ReplacePopDog( );
}

public client_putinserver( id )
{
	Set( g_iConnected, id );
	Set( g_iShowKnife, id );
	Sub( g_iAlive, id );
	
	get_user_name( id, g_szName[ id ], charsmax( g_szName[ ] ) );
}

public client_disconnect( id )
{
	Sub( g_iConnected, id );
	Sub( g_iAlive, id );
}

public client_command( id )
{
	new szArg[ 13 ];
	
	if( read_argv( 0, szArg, 12 ) > 11 )
	{
		return PLUGIN_CONTINUE;
	}
	
	for( new i = 0; i < sizeof g_szBuyCommands; i++ )
	{
		if( equali( g_szBuyCommands[ i ], szArg, 0 ) )
		{
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public client_infochanged( id )
{
	static const szName[ 10 ] = "name";
	
	get_user_info( id, szName, g_szName[ id ], charsmax( g_szName[ ] ) );
}

public ClCmdHandle( id )
{
	return PLUGIN_HANDLED;
}

public ClCmdKnife( id )
{
	if( cs_get_user_team( id ) != CS_TEAM_T )
	{
		client_print( id, print_center, "Nu poti folosi aceasta comanda" );
		
		return PLUGIN_HANDLED;
	}
	
	if( Get( g_iShowKnife, id ) ) 
	{
		Sub( g_iShowKnife, id );
		
		client_print( id, print_center, "Cutitul este acum ascuns" );
	}
	
	else
	{
		Set( g_iShowKnife, id );
		
		client_print( id, print_center, "Cutitul este acum vizibil" );
	}
	
	EventCurWeapon( id );
	
	return PLUGIN_HANDLED;
}

public EventCurWeapon( id )
{
	if( !knife_in_hand( id ) )
	{
		return PLUGIN_CONTINUE;
	}
	
	if( cs_get_user_team( id ) == CS_TEAM_T )
	{
		if( Get( g_iShowKnife, id ) )
		{
			set_pev( id, pev_viewmodel2, g_szKnifeModel_v );
			set_pev( id, pev_weaponmodel2, g_szKnifeModel_p );
		}
		
		else
		{
			set_pev( id, pev_viewmodel2, "" );
			set_pev( id, pev_weaponmodel2, "" );
		}
	}
	
	return PLUGIN_CONTINUE;
}

public LogEventRoundStart( )
{
	new iEntity = -1;
	
	while( ( iEntity = engfunc( EngFunc_FindEntityByString, iEntity, "classname", "func_breakable" ) ) )
	{	
		set_pev( iEntity, pev_solid, SOLID_NOT );
		set_pev( iEntity, pev_takedamage, 0.0 );
	}
}

public FwdPlayerSpawn( id ) 
{
	Set( g_iAlive, id );
}

public FwdPlayerKilled( id )
{
	Sub( g_iAlive, id );
}

public FwdAddToFullPackPost( iEs, iE, iEnt, iHost, iHostFlags, player, pSet )
{
	if( player )
	{
		if( Get( g_iSolid, iHost ) && Get( g_iSolid, iEnt ) )
		{
			if( g_iTeam[ iHost ] == g_iTeam[ iEnt ] )
			{
				set_es( iEs, ES_Solid, SOLID_NOT );
			}
		}
	}
	
	return FMRES_IGNORED;
}

public FwdCmdStart( id, ucHandle, iSeed )
{
	if( !Get( g_iAlive, id ) )
	{
		return FMRES_IGNORED;
	}
	
	if( !knife_in_hand( id ) )
	{
		return FMRES_IGNORED;
	}
	
	static iButton;
	
	new CsTeams: iTeam = cs_get_user_team( id );
	
	switch( iTeam )
	{
		case CS_TEAM_T:
		{
			static iStage;
			
			iStage = get_war_stage( );
			
			if( iStage == CHOOSE_ROUND || iStage == KNIFE_ROUND )
			{
				return FMRES_IGNORED;
			}
			
			iButton = get_uc( ucHandle, UC_Buttons );
			
			if( iButton & IN_ATTACK )
			{
				iButton &= ~IN_ATTACK;
			}
			
			if( iButton & IN_ATTACK2 )
			{
				iButton &= ~IN_ATTACK2;
			}
			
			set_uc( ucHandle, UC_Buttons, iButton );
			
			return FMRES_SUPERCEDE;
		}
		
		case CS_TEAM_CT:
		{
			iButton = get_uc( ucHandle, UC_Buttons );
			
			if( iButton & IN_ATTACK )
			{
				iButton &= ~IN_ATTACK;
				iButton |= IN_ATTACK2;
			}
			
			set_uc( ucHandle, UC_Buttons, iButton );
			
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public FwdGetGameDescription( )
{
	forward_return( FMV_STRING, "HideNSeek" );
	
	return FMRES_SUPERCEDE;
}

public FwdPlayerPreThink( id )
{
	if( Get( g_iAlive, id ) )
	{
		static iTarget;
		static iBody;
		
		get_user_aiming( id, iTarget, iBody, 9999 );
		
		if( is_user_valid_alive( iTarget ) )
		{
			new CsTeams: iTargetTeam = cs_get_user_team( iTarget );
			
			switch( iTargetTeam )
			{
				case CS_TEAM_T:
				{
					set_hudmessage( 200, 10, 10, -1.0, -1.0, 0, 6.0, 0.1, 0.0, 0.0, -1 );
					ShowSyncHudMsg( id, g_iSyncHud, "Hider: %s", g_szName[ iTarget ] );
				}
				
				case CS_TEAM_CT:
				{
					set_hudmessage( 10, 10, 200, -1.0, -1.0, 0, 6.0, 0.1, 0.0, 0.0, -1 );
					ShowSyncHudMsg( id, g_iSyncHud, "Seeker: %s", g_szName[ iTarget ] );
				}
			}
		}
	}
	
	static LastThink;
	static i;
	
	if( id < LastThink )
	{
		for( i = 1; i <= g_iMaxPlayers; i++ )
		{
			if( !is_user_valid_alive( i ) )
			{
				Sub( g_iSolid, i );
				
				continue;
			}
			
			g_iTeam[ i ] = cs_get_user_team( i );
			
			pev( i, pev_solid ) == SOLID_SLIDEBOX ? Set( g_iSolid, i ) : Sub( g_iSolid, i );
		}
	}
	
	LastThink = id;
	
	if( !Get( g_iSolid, id ) || !get_pcvar_num( hns_semiclip ) )
	{
		return FMRES_IGNORED;
	}
	
	for( i = 1; i <= g_iMaxPlayers; i++ )
	{
		if( !Get( g_iSolid, i ) || Get( g_iRestoreSolid, i ) || id == i )
		{
			continue;
		}
		
		if( g_iTeam[ id ] == g_iTeam[ i ] )
		{
			set_pev( i, pev_solid, SOLID_NOT );
			
			Set( g_iRestoreSolid, i);
		}
	}
	
	return FMRES_IGNORED;
}

public FwdPlayerPostThink( id )
{
	static i;
	
	for( i = 1; i <= g_iMaxPlayers; i++ )
	{
		if( Get( g_iRestoreSolid, i ) )
		{
			set_pev( i, pev_solid, SOLID_SLIDEBOX );
			
			Sub( g_iRestoreSolid, i );
		}
	}
	
	return FMRES_IGNORED;
}

public FwdSpawn( iEntity )
{
	if( !pev_valid( iEntity ) )
	{
		return FMRES_IGNORED;
	}
	
	new szClassName[ 32 ];
	
	pev( iEntity, pev_classname, szClassName, charsmax( szClassName ) );
	
	for( new i = 0; i < sizeof g_szEntityClassNames; i++ )
	{
		if( equal( szClassName, g_szEntityClassNames[ i ] ) )
		{
			engfunc( EngFunc_RemoveEntity, iEntity );
			
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public FwdTraceLine( Float: vStart[ 3 ], Float: vEnd[ 3 ], iFlags, id, iTrace )
{
	if( !Get( g_iAlive, id ) )
	{
		return FMRES_IGNORED;
	}
	
	if( !knife_in_hand( id ) )
	{
		return FMRES_IGNORED;
	}
	
	new Float: flFraction;
	
	get_tr2( iTrace, TR_flFraction, flFraction );
	
	if( flFraction >= 1.0 )
	{
		return FMRES_IGNORED;
	}
	
	new iHit = get_tr2( iTrace, TR_pHit );
	
	if( !is_user_valid_alive( iHit ) || g_iTeam[ id ] != g_iTeam[ iHit ] || fm_entity_range( id, iHit ) > 48.0 )
	{
		return FMRES_IGNORED;
	}
	
	new Float: flStart[ 3 ];
	new Float: flView_ofs[ 3 ];
	new Float: flDirection[ 3 ];
	new Float: tlStart[ 3 ];
	new Float: tlEnd[ 3 ];
	
	pev( id, pev_origin, flStart);
	pev( id, pev_view_ofs, flView_ofs);
	
	vec_add( flStart, flView_ofs, flStart );
	velocity_by_aim( id, 22, flDirection );
	vec_add( flDirection, flStart, tlStart );
	velocity_by_aim( id, 48, flDirection );
	vec_add( flDirection, flStart, tlEnd );
	
	engfunc( EngFunc_TraceLine, tlStart, tlEnd, iFlags|DONT_IGNORE_MONSTERS, iHit, 0 );
	
	new tHit = get_tr2( 0, TR_pHit );
	
	if( !is_user_valid_alive( tHit ) || g_iTeam[ id ] != g_iTeam[ iHit ] )
	{
		return FMRES_IGNORED;
	}
	
	set_tr2( iTrace, TR_AllSolid, get_tr2( 0, TR_AllSolid ) );
	set_tr2( iTrace, TR_StartSolid, get_tr2( 0, TR_StartSolid ) );
	set_tr2( iTrace, TR_InOpen, get_tr2( 0, TR_InOpen ) );
	set_tr2( iTrace, TR_InWater, get_tr2( 0, TR_InWater ) );
	set_tr2( iTrace, TR_iHitgroup, get_tr2( 0, TR_iHitgroup ) );
	set_tr2( iTrace, TR_pHit, tHit );
	
	return FMRES_IGNORED;
}

public MessageHideWeapon( const iMsgid, const iMsgDest, const id )
{
	set_msg_arg_int( 1, ARG_BYTE, get_msg_arg_int( 1 ) | HIDE_MONEY );
	
	return PLUGIN_CONTINUE;
}

public MessageScreenFade( const iMsgid, const iMsgDest, const id )
{
	if( get_msg_arg_int( 4 ) == MAX_RGB
	&& get_msg_arg_int( 5 ) == MAX_RGB
	&& get_msg_arg_int( 6 ) == MAX_RGB )
	{
		if( cs_get_user_team( id ) == CS_TEAM_T )
		{
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public MessageTextMsg( const iMsgid, const iMsgDest, const id )
{
	static szMessage[ 32 ];
	
	get_msg_arg_string( 2, szMessage, charsmax( szMessage ) );
	
	if( equal( szMessage, "#Terrorists_Win" )
	|| equal( szMessage, "#CTs_Win" )
	|| equal( szMessage, "#Hostages_Not_Rescued" ) )
	{
		set_msg_arg_string( 2, "" );
	}
}

public ReplacePopDog( )
{
	static iFailCount;
	
	new g_iPopDog = CreateEntity( );
	
	if( !pev_valid( g_iPopDog ) )
	{
		log_amx( "[ERROR] Failed to create Pop Dog entity (%i/10)", ++iFailCount );
		
		if( iFailCount < 10 )
		{
			set_task( 1.0, "ReplacePopDog" );
		}
		
		else
		{
			log_amx( "[ERROR] Could not create Pop Dog entity." );
		}
		
		return;
	}
	
	set_pev( g_iPopDog, pev_classname, g_szPopDogClassName ); 
	set_pev( g_iPopDog, pev_origin, g_flPopDogOrigin );
	set_pev( g_iPopDog, pev_angles, g_flPopDogAngle );
	set_pev( g_iPopDog, pev_scale, g_flPopDogScale );
	
	engfunc( EngFunc_SetModel, g_iPopDog, g_szPopDogSprite );
}

stock Float: fm_entity_range( iEnt, iEnt2 )
{
	new Float: flOrigin[ 3 ];
	new Float: flOrigin2[ 3 ];
	
	pev( iEnt, pev_origin, flOrigin );
	pev( iEnt2, pev_origin, flOrigin2 );
	
	return get_distance_f( flOrigin, flOrigin2 );
}

stock bool: knife_in_hand( id )
{
	if( is_user_connected( id ) && Get( g_iAlive, id ) )
	{
		new iClip;
		new iAmmo;
		
		if( get_user_weapon( id, iClip, iAmmo ) == CSW_KNIFE )
		{
			return true;
		}
	}
	
	return false;
}

stock CreateEntity( )
{
	new iInfoTarget = engfunc( EngFunc_AllocString, "info_target" );
	new iEntity = engfunc( EngFunc_CreateNamedEntity, iInfoTarget );
	
	return iEntity;
}

stock vec_add( Float: in1[ 3 ], Float: in2[ 3 ], Float: out[ 3 ] )
{
	out[ 0 ] = in1[ 0 ] + in2[ 0 ];
	out[ 1 ] = in1[ 1 ] + in2[ 1 ];
	out[ 2 ] = in1[ 2 ] + in2[ 2 ];
}
