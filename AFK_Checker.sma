#include < amxmodx >
#include < cstrike >
#include < hamsandwich >

#pragma semicolon	1

#define TASKID(%1)	(%1 + TASK_CHECK)
#define Add(%1,%2)	(%1 |= 1 << (%2 & 31))
#define Sub(%1,%2)	(%1 &= ~( 1 <<(%2 & 31)))
#define Get(%1,%2)	(%1 & 1 << (%2 & 31))


static const
	
	PLUGIN[ ] =	"AFK_Checker",
	VERSION[ ] =	"1.0",
	AUTHOR[ ] =	"Rap^^";


enum
{
	X = 0,
	Y,
	Z
};

new const CHECK_TIME =	5;
new const TASK_CHECK =	10223;

new g_iOldOrigin[ 33 ][ 3 ];
new g_iAFK[ 33 ];

new g_iConnected;
new g_iAlive;
new g_iCanChecked;
new g_iMaxPlayers;


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, VERSION, FCVAR_SERVER );
	
	register_clcmd( "say /back", "ClCmdBack" );
	register_clcmd( "say /start", "ClCmdStart" );
	new const szPlayer[ ] = "player";
	
	RegisterHam( Ham_Spawn, szPlayer, "FwdPlayerSpawn" );
	RegisterHam( Ham_Killed, szPlayer, "FwdPlayerKilled" );
	
	g_iMaxPlayers = get_maxplayers( );
}

public plugin_natives( )
{
	register_library( "afk_checker" );
	register_native( "is_user_afk", "_is_user_afk" );
}

public _is_user_afk( iPlugin, iParams )
{
	return g_iAFK[ get_param( 1 ) ] > 15 ? true : false;
}

public client_putinserver( id )
{
	new const szB[ ] = "b";
	
	Add( g_iConnected, id );
	Sub( g_iAlive, id );
	Sub( g_iCanChecked, id );
	
	set_task( float( CHECK_TIME ), "CheckAFK", TASKID( id ), _, _, szB );
}

public client_disconnect( id )
{
	if( task_exists( TASKID( id ) ) )
	{
		remove_task( TASKID( id ) );
	}
	
	Sub( g_iConnected, id );
	Sub( g_iAlive, id );
	Sub( g_iCanChecked, id );
}
public ClCmdStart( id )
{
	new const szB[ ] = "b";
	remove_task( TASKID( id ) );
	
	set_task( float( CHECK_TIME ), "CheckAFK", TASKID( id ), _, _, szB );
}
public ClCmdBack( id )
{
	if( cs_get_user_team( id ) != CS_TEAM_SPECTATOR )
	{
		client_print( id, print_center, "Doar spectatorii pot folosi aceasta comanda" );
		
		return PLUGIN_HANDLED;
	}
	
	cs_set_user_team( id, CS_TEAM_CT );
	
	client_print( id, print_center, "Ai fost reintrodus in joc" );
	
	return PLUGIN_HANDLED;
}

public FwdPlayerSpawn( id )
{
	Add( g_iAlive, id );
	Sub( g_iCanChecked, id );
	
	if( task_exists( TASKID( id ) ) )
	{
		remove_task( TASKID( id ) );
	}
	
	set_task( float( CHECK_TIME ), "TaskCanChecked", TASKID( id ) );
}

public FwdPlayerKilled( id )
{
	Sub( g_iAlive, id );
}

public CheckAFK( id )
{
	id -= TASK_CHECK;
	
	if( Get( g_iConnected, id )
	&& Get( g_iAlive, id )
	&& Get( g_iCanChecked, id ) )
	{
		new iNewOrigin[ 3 ];
		
		new iAFK;
		
		get_user_origin( id, iNewOrigin, X );
		
		if( iNewOrigin[ X ] == g_iOldOrigin[ id ][ X ]
		&& iNewOrigin[ Y ] == g_iOldOrigin[ id ][ Y ]
		&& iNewOrigin[ Z ] == g_iOldOrigin[ id ][ Z ] )
		{
			g_iAFK[ id ] += 5;
			
			if( g_iAFK[ id ] >= 100 )
			{
				iAFK = g_iAFK[ id ];
				
				if( get_playersnum( ) > g_iMaxPlayers - 2 )
				{
					if( iAFK >= 120 )
					{
						server_cmd( "kick #%d ^"Ai fost AFK, iar serverul este plin^"", get_user_userid( id ) );
					}
					
					else
					{
						client_print( id, print_center, "In %d secunde vei primi kick pentru ca esti AFK.", 120 - iAFK );
					}
				}
				
				else
				{
					if( iAFK >= 120 )
					{
						cs_set_user_team( id, CS_TEAM_SPECTATOR );
						
						client_print( id, print_center, "Ai fost mutat sectator pentru ca esti AFK." );
					}
					
					else
					{
						client_print( id, print_center, "In %d secunde vei fi mutat spectator pentru ca esti AFK.", 120 - iAFK );
					}
				}
				
				return PLUGIN_HANDLED;
			}
		}
		
		else
		{
			g_iAFK[ id ] = X;
			
			g_iOldOrigin[ id ][ X ] = iNewOrigin[ X ];
			g_iOldOrigin[ id ][ Y ] = iNewOrigin[ Y ];
			g_iOldOrigin[ id ][ Z ] = iNewOrigin[ Z ];
		}
	}
	
	return PLUGIN_HANDLED;
}

public TaskCanChecked( id )
{
	id -= TASK_CHECK;
	
	new iNewOrigin[ 3 ];
		
	get_user_origin( id, iNewOrigin );
	
	g_iOldOrigin[ id ][ X ] = iNewOrigin[ X ];
	g_iOldOrigin[ id ][ Y ] = iNewOrigin[ Y ];
	g_iOldOrigin[ id ][ Z ] = iNewOrigin[ Z ];
	
	Add( g_iCanChecked, id );
}
