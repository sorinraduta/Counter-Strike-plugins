#include < amxmodx >
#include < engine >
#include < hamsandwich >

#pragma semicolon 1

#define Set(%1,%2)			(%1 |= 1 << (%2 & 31))
#define Sub(%1,%2)			(%1 &= ~(1 << (%2 & 31)))
#define Get(%1,%2)			(%1 & 1 << (%2 & 31))


static const
	
	PLUGIN[ ] =			"Non_Player_Character",
	VERSION[ ] =			"1.0",
	AUTHOR[ ] =			"Rap^^";


new const g_szNPCClassName[ ] =		"NPC_Entity";
new const g_szWeaponClassName[ ] =	"Knife_Entity";
new const g_szNPCModel[ ] =		"models/player/gign/gign.mdl";

new const NULL =				0;
new const MIN_DISTANCE =			75;
new const MAX_DISTANCE =			9999;

new Float: g_flMins[ 3 ] =		{ -16.0, -16.0, -36.0 };
new Float: g_flMaxs[ 3 ] =		{ 16.0, 16.0, 36.0 };
new Float: g_flOrigin[ 3 ] =		{ 127.0, 760.0, -92.0 };
new Float: g_flAngle[ 3] = 		{ 0.0, -90.0, 0.0 };

new Float: g_flCooldown[ 33 ];

new g_iMenu;
new g_iNPC;
new g_iAlive;

new g_iSyncHud;


public plugin_prechace( )
{
	precache_model( g_szNPCModel );
}

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, VERSION, FCVAR_SERVER );
	
	new const szClCmdRegulament[ ] = "ClCmdRegulament";
	
	register_clcmd( "say /reguli",		szClCmdRegulament );
	register_clcmd( "say /regulament",	szClCmdRegulament );
	register_clcmd( "say /rules",		"ClCmdRules" );
	
	new const szPlayer[ ] = "player";
	
	RegisterHam( Ham_Spawn,		szPlayer,	"FwdPlayerSpawn", true );
	RegisterHam( Ham_Killed,	szPlayer,	"FwdPlayerKilled", true );
	
	g_iSyncHud = CreateHudSyncObj( );
	
	CreateNPC( );
}

public plugin_cfg( )
{
	new szConfigDir[ 64 ];
	new szFilePath[ 64 ];
	
	get_localinfo( "amxx_configsdir", szConfigDir, charsmax( szConfigDir ) );
	
	formatex( szFilePath, charsmax( szFilePath ), "%s/NPC.ini", szConfigDir );
	
	if( file_exists( szFilePath ) )
	{
		new szData[ 512 ];
		
		new szOption[ 256 ];
		new szLocation[ 256 ];
		
		new iFile = fopen( szFilePath, "rt" );
		
		if( !iFile )
		{
			return;
		}
		
		g_iMenu = menu_create( "NPC informativ", "MenuHandler", NULL );
		
		while( !feof( iFile ) )
		{
			fgets( iFile, szData, charsmax( szData ) );
			
			if( !szData[ NULL ]
			|| szData[ NULL ] == ';'
			|| szData[ NULL ] == ' '
			|| szData[ NULL ] == 10 ) 
			{
				continue;
			}
			
			parse( szData, szOption, charsmax( szOption ), szLocation, charsmax( szLocation ) );
			
			menu_additem( g_iMenu, szOption, szLocation, NULL );
		}
		
		menu_setprop( g_iMenu, MPROP_EXITNAME, "Inchide" );
		
		fclose( iFile );	
	}
	
	else
	{
		write_file( szFilePath, ";Non-Player Character" );
		write_file( szFilePath, ";" );
		write_file( szFilePath, ";Structura: ^"optiune^" ^"numele fisierului .html din folderul configs/NPC^"" );
		write_file( szFilePath, ";Exemplu: ^"Regulament server^" ^"regulament^"" );
		
		formatex( szFilePath, charsmax( szFilePath ), "%s/NPC", szConfigDir );
		
		mkdir( szFilePath );
	}
}

public client_putinserver( id )
{
	Sub( g_iAlive, id );
}

public client_disconnect( id )
{
	Sub( g_iAlive, id );
}

public FwdPlayerSpawn( id )
{
	Set( g_iAlive, id );
}

public FwdPlayerKilled( id )
{
	Sub( g_iAlive, id );
}

public client_PreThink( id )
{
	if( !Get( g_iAlive, id ) )
	{
		return;
	}
	
	static iTarget;
	static iBody;
	
	get_user_aiming( id, iTarget, iBody, MAX_DISTANCE );
	
	if( iTarget == g_iNPC )
	{
		if( get_user_button( id ) & IN_USE && get_entity_distance( id, iTarget ) < MIN_DISTANCE )
		{
			static Float: flGameTime;
			
			flGameTime = get_gametime( );
			
			if( flGameTime - 1.0 > g_flCooldown[ id ] )
			{
				menu_display( id, g_iMenu, NULL );
				
				g_flCooldown[ id ] = flGameTime;
			}
		}
		
		set_hudmessage( 88, 88, 255, -1.0, -1.0, 0, 6.0, 0.0, 0.1, 0.0, -1 );
		ShowSyncHudMsg( id, g_iSyncHud, "- NPC informativ -" );
	}
}

public CreateNPC( )
{
	static iFailCount;
	
	g_iNPC = create_entity( "info_target" );
	
	if( !is_valid_ent( g_iNPC ) )
	{
		log_amx( "[ERROR] Failed to create NPC (%i/10)", ++iFailCount );
		
		if( iFailCount < 10 )
		{
			set_task( 1.0, "CreateNPC" );
		}
		
		else
		{
			log_amx( "[ERROR] Could not create NPC!" );
		}
		
		return;
	}
	
	GiveKnife( g_iNPC );
	
	entity_set_string( g_iNPC, EV_SZ_classname, g_szNPCClassName ); 
	entity_set_origin( g_iNPC, g_flOrigin );
	entity_set_vector( g_iNPC, EV_VEC_angles, g_flAngle );
	entity_set_float( g_iNPC, EV_FL_takedamage, 0.0 );
	entity_set_model( g_iNPC, g_szNPCModel );
	entity_set_int( g_iNPC, EV_INT_movetype, MOVETYPE_PUSHSTEP );
	entity_set_int( g_iNPC, EV_INT_solid, SOLID_BBOX );
	entity_set_size( g_iNPC, g_flMins, g_flMaxs );
	
	UTIL_PlayAnimation( g_iNPC, 1 );
}

public MenuHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{	
		return PLUGIN_HANDLED;
	}
	
	new szHTML[ 96 ];
	
	new szData[ 64 ];
	new szName[ 64 ];
	
	new iCallback;
	new _access;
	
	menu_item_getinfo( iMenu, iItem, _access, szData, charsmax( szData ), szName, charsmax( szName ), iCallback );
	
	formatex( szHTML, charsmax( szHTML ), "addons/amxmodx/configs/NPC/%s.html", szData );
	
	show_motd( id, szHTML );
	
	return PLUGIN_HANDLED;
}

public ClCmdRules( id )
{
	show_motd( id, "addons/amxmodx/configs/NPC/rules.html" );
}

public ClCmdRegulament( id )
{
	show_motd( id, "addons/amxmodx/configs/NPC/regulament.html" );
}

public GiveKnife( iEntity )
{
	new iKnifeEntity = create_entity( "info_target" );
	
	entity_set_string( iKnifeEntity, EV_SZ_classname, g_szWeaponClassName );
	entity_set_int( iKnifeEntity, EV_INT_movetype, MOVETYPE_FOLLOW );
	entity_set_int( iKnifeEntity, EV_INT_solid, SOLID_NOT );
	entity_set_edict( iKnifeEntity, EV_ENT_aiment, iEntity );
	entity_set_model( iKnifeEntity, "models/p_knife.mdl" ) ;
}

stock UTIL_PlayAnimation( index, iSequence, Float: flFramerate = 1.0 )
{
	entity_set_float( index, EV_FL_animtime, get_gametime( ) );
	entity_set_float( index, EV_FL_framerate,  flFramerate );
	entity_set_float( index, EV_FL_frame, 0.0 );
	entity_set_int( index, EV_INT_sequence, iSequence );
} 
