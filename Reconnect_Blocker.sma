#include < amxmodx >
#include < cstrike>
#include < ColorChat >

#pragma semicolon 1

#define MAX_STORED 64
#define TASK_CLEAR 13311

static const
	
	PLUGIN[ ] =	"Reconnect_Blocker",
	VERSION[ ] =	"1.0",
	AUTHOR[ ] =	"Rap^^";


enum Storage
{
	IP[ 32 ],
	Name[ 32 ],
	Steamid[ 32 ],
	Team
};

new g_szStored[ MAX_STORED ][ Storage ];

new g_iTeam[ 33 ];


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, VERSION, FCVAR_SERVER );
	
	register_event( "TeamInfo", "EventTeamInfo", "a" );
}

public client_putinserver( id )
{	
	new szIP[ 32 ];
	new szName[ 32 ];
	new szSteamid[ 32 ];
	
	get_user_ip( id, szIP, charsmax( szIP ), 0 );
	get_user_name( id, szName, charsmax( szName ) );
	get_user_authid( id, szSteamid, charsmax( szSteamid ) );
	
	g_iTeam[ id ] = 0;
	
	for( new i = 0; i < MAX_STORED; i++ )
	{
		if( equal( g_szStored[ i ][ IP ], szIP, strlen( szIP ) )
		|| equal( g_szStored[ i ][ Name ], szName, strlen( szName ) )
		|| equal( g_szStored[ i ][ Steamid ], szSteamid, strlen( szSteamid ) ) )
		{
			if( task_exists( i + TASK_CLEAR ) )
			{
				remove_task( i + TASK_CLEAR );
			}
			
			new iParam[ 1 ];
			
			iParam[ 0 ] = i;
			
			set_task( 1.5, "Reconnected", id, iParam, sizeof iParam );
			
			return PLUGIN_CONTINUE;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public client_disconnect( id )
{
	if( 1 <= g_iTeam[ id ] <= 2 )
	{
		for( new i = 0; i < MAX_STORED; i++ )
		{
			if( g_szStored[ i ][ IP ][ 0 ] == EOS )
			{
				get_user_ip( id, g_szStored[ i ][ IP ], 31, 0 );
				get_user_name( id, g_szStored[ i ][ Name ], 31 );
				get_user_authid( id, g_szStored[ i ][ Steamid ], 31 );
				g_szStored[ i ][ Team ] = g_iTeam[ id ];
				
				set_task( 10.0, "Clear", i + TASK_CLEAR );
				
				break;
				
			}
		}
	}
	g_iTeam[ id ] = 0;
}

public EventTeamInfo( )
{
	new szTeam[ 32 ];
	
	new id = read_data( 1 );
	
	read_data( 2, szTeam, charsmax( szTeam ) );
	
	if( !is_user_connected( id ) )
	{
		return PLUGIN_HANDLED;
	}
	
	switch( szTeam[ 0 ] )
	{
		case 'U':
		{
			g_iTeam[ id ] = 0;
		}
		case 'T':
		{
			g_iTeam[ id ] = 1;
		}
		
		case 'C':
		{
			g_iTeam[ id ] = 2;
		}
		
		case 'S':
		{
			g_iTeam[ id ] = 3;
		}
	}
	
	return PLUGIN_HANDLED;
}

public Clear( iSlot )
{
	remove_task( iSlot );
	
	iSlot -= TASK_CLEAR;
	
	g_szStored[ iSlot ][ IP ][ 0 ] = EOS;
	g_szStored[ iSlot ][ Name ][ 0 ] = EOS;
	g_szStored[ iSlot ][ Steamid ][ 0 ] = EOS;
	g_szStored[ iSlot ][ Team ] = 0;
}

public Reconnected( iParam[ ], id )
{
	new iSlot = iParam[ 0 ];
	
	if( is_user_connected( id ) )
	{
		if( _: cs_get_user_team( id ) != g_szStored[ iSlot ][ Team ] )
		{
			ColorChat( 0, GREEN, "[D/C]^x03 %d - %d", _: cs_get_user_team( id ), g_szStored[ iSlot ][ Team ] );
			
			cs_set_user_team( id, CsTeams: g_szStored[ iSlot ][ Team ] );
			/*
			switch( g_szStored[ iSlot ][ Team ] )
			{
				case 1:
				{
					cs_set_user_team( id, CS_TEAM_T );
				}
				
				case 2:
				{
					cs_set_user_team( id, CS_TEAM_CT );
				}
			}
			*/
			ColorChat( 0, GREEN, "[D/C]^x03 %s^x01 a fost mutat la vechea echipa deoarece a folosit comanda^x03 retry^x01.", g_szStored[ iSlot ][ Name ] );
		}
	}
	
	Clear( iSlot + TASK_CLEAR);
}