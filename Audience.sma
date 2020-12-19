#include < amxmodx >
#include < fakemeta >
#include < engine >

#pragma semicolon 1

#define ShowList(%1)		( g_iSeeList |= 1 << ( %1 & 31 ) )
#define HideList(%1)		( g_iSeeList &= ~( 1 <<( %1 & 31 ) ) )
#define SeeList(%1)		( g_iSeeList & 1 << ( %1 & 31 ) )


static const

	PLUGIN[ ] =		"Audience",
	VERSION[ ] =		"1.0",
	AUTHOR[ ] =		"Fatalis/Rap^^";


new g_szName[ 33 ][ 32 ];

new g_iMaxPlayers;
new g_iSeeList;
new g_iAudienceEntity;


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, VERSION, FCVAR_SERVER );
	
	register_clcmd( "say /speclist", "cmdList", -1, "" );
	register_clcmd( "say /audience", "cmdList", -1, "" );
	
	g_iMaxPlayers = get_maxplayers( );
}

public plugin_cfg( )
{
	CreateAudienceEntity( );
}

public CreateAudienceEntity( )
{
	static iFailCount;
	
	g_iAudienceEntity = create_entity( "info_target" );
	
	if( !is_valid_ent( g_iAudienceEntity ) )
	{
		log_amx( "[ERROR] Failed to create audience entity (%i/10)", ++iFailCount );
		
		if( iFailCount < 10 )
		{
			set_task( 1.0, "CreateAudienceEntity" );
		}
		
		else
		{
			log_amx( "[ERROR] Could not create audience entity!" );
		}
		
		return;
	}
	
	entity_set_string( g_iAudienceEntity, EV_SZ_classname, "Audience_Entity" );
	entity_set_float( g_iAudienceEntity, EV_FL_nextthink, get_gametime( ) + 1.0);
	
	register_think( "Audience_Entity", "ShowAudience" );
}

public client_putinserver( id )
{
	get_user_name( id, g_szName[ id ], charsmax( g_szName[ ] ) );
	
	ShowList( id );
}

public client_infochanged( id )
{
	static const szName[ 10 ] = "name";
	
	get_user_info( id, szName, g_szName[ id ], charsmax( g_szName[ ] ) );
}

public cmdList( id )
{
	if( SeeList( id ) )
	{
		client_print( id, print_center, "Lista spectatorilor a fost dezactivata");
		
		HideList( id );
	}
	
	else
	{
		client_print( id, print_center, "Lista spectatorilor a fost activata");
		
		ShowList( id );
	}
	
	return PLUGIN_HANDLED;
}

public ShowAudience( iEntity )
{
	if( iEntity != g_iAudienceEntity )
	{
		return PLUGIN_HANDLED;
	}
	
	static szHud[ 1102 ];	//32 * 33 + 50
	
	static bool: bSend;
	
	for( new iAlive = 1; iAlive <= g_iMaxPlayers; iAlive++ )
	{
		new bool: bSendTo[ 33 ];
		
		bSend = false;
		
		if( !is_user_alive( iAlive ) )
		{
			continue;
		}
		
		bSendTo[ iAlive ] = true;
		
		format( szHud, 50, "Spectatorii lui %s:", g_szName[ iAlive ] );
		
		for( new iDead = 1; iDead <= g_iMaxPlayers; iDead++ )
		{
			if( is_user_connected( iDead ) )
			{
				if( is_user_alive( iDead ) || is_user_bot( iDead ) )
				{
					continue;
				}
				
				if( pev( iDead, pev_iuser2 ) == iAlive )
				{
					add( szHud, charsmax( szHud ), "^n", 0 );
					add( szHud, charsmax( szHud ), g_szName[ iDead ], 0 );
					
					bSend = true;

					bSendTo[ iDead ] = true;
				}
			}
		}
		
		if( bSend == true )
		{
			for( new i = 1; i <= g_iMaxPlayers; i++ )
			{
				if( bSendTo[ i ] == true && SeeList( i ) )
				{
					set_hudmessage( 84, 84, 84, 0.75, 0.15, 0, 0.0, 1.1, 0.0, 0.0, -1 );
					show_hudmessage( i, szHud );
				}
			}
		}
	}
	
	entity_set_float( g_iAudienceEntity, EV_FL_nextthink, get_gametime( ) + 1.0);
	
	return PLUGIN_CONTINUE;
}
