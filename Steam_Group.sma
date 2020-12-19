#include < amxmodx >
#include < sockets >
#include < ColorChat >

#pragma semicolon	1

#define ZERO		0

#define TASK_VERIFY	1111
#define TASK_CLOSE	2222

#define ADD_OTHER	9

static const

	PLUGIN[ ] =		"Steam Group",
	VERSION[ ] =		"1.0",
	AUTHOR[ ] =		"Rap^^";


new const g_szTag[ ] =		"[Steam Group]";
new const g_szHost[ ] =		"steamcommunity.com";
new const g_szGroup[ ] =		"/groups";
new const g_szDisconnect[ ] =	"disconnectro";

new const g_szError[ ] =		"No group could be retrieved for the given URL.";

new g_szRequest[ 33 ][ 128 ];
new g_szData[ 33 ][ 4096 ];
new g_iSocket[ 33 ];
new g_iPacketNum[ 33 ];
new g_iError[ 33 ];


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	register_clcmd( "say /group", "cmdGroup" );
	register_clcmd( "say /grup", "cmdGroup" );
}

public cmdGroup( id )
{
	if( g_iSocket[ id ] > ZERO )
	{
		socket_close( g_iSocket[ id ] );
	}
	
	g_iSocket[ id ] = socket_open( g_szHost, 80, SOCKET_TCP, g_iError[ id ] );
	
	if( g_iError[ id ] == ZERO && g_iSocket[ id ] > ZERO )
	{
		
		formatex( g_szRequest[ id ], sizeof g_szRequest[ ] -1, "GET %s/%s HTTP/1.1^r^nHost: %s^r^n^r^n", g_szGroup, g_szDisconnect, g_szHost );
		
		socket_send( g_iSocket[ id ], g_szRequest[ id ], sizeof g_szRequest[ ] );
		
		g_iPacketNum[ id ] = ZERO;
		
		set_task( 0.1, "VerifySocket", id + TASK_VERIFY, _, _, "b", ZERO );
		set_task( 10.0, "CloseSocket", id + TASK_CLOSE );
		
		ColorChat( id, GREEN, "%s^x01 Waiting for^x04 SteamCommunity^x01 to response...", g_szTag );
	}
	
	else
	{
		switch( g_iError[ id ] )
		{
			case 1:
			{
				log_amx( "[ERROR] Unable to create socket." );
			}
			
			case 2:
			{
				log_amx( "[ERROR] Unable to connect to hostname." );
			}
			
			case 3:
			{
				log_amx( "[ERROR] Unable to connect to the HTTP port." );
			}
		} 
		
		ColorChat( id, GREEN, "%s^x01 An error occuered while trying to establish connection.", g_szTag );
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_HANDLED;
}

public VerifySocket( id )
{
	id -= TASK_VERIFY;
	
	if( !is_user_connected( id ) )
	{
		CloseSocket( id, true );
		
		return;
	}
	
	if( socket_change( g_iSocket[ id ], ZERO ) )
	{
		static iDataStart;
		static iDataStop;
		
		static szMembers[ 16 ];
		static szInGame[ 16 ];
		static szOnline[ 16 ];
		
		if( socket_recv( g_iSocket[ id ], g_szData[ id ], sizeof g_szData[ ] ) )
		{
			if( ++g_iPacketNum[ id ] == 1 )
			{
				if( containi( g_szData[ id ], g_szError ) != -1 )
				{
					ColorChat( id, GREEN, "%s^x01 Current group was not found on^x04 SteamCommunity^x01 database.", g_szTag );
					
					CloseSocket( id + TASK_CLOSE, true );
					
					return;
				}
			}
			
			iDataStart = containi( g_szData[ id ], "<span class=^"count ^">" );
			
			if( iDataStart != -1 )
			{
				iDataStart += strlen( "<span class=^"count ^">" );
				
				copy( szMembers, sizeof szMembers -1, g_szData[ id ][ iDataStart ] );
				
				iDataStop = containi( szMembers, "<" );
				
				szMembers[ iDataStop ] = '^0';
			}
			
			iDataStart = containi( g_szData[ id ], "<div class=^"membercount ingame^">" );
			
			if( iDataStart != -1 )
			{
				iDataStart += strlen( "<div class=^"membercount ingame^">" );
				iDataStart += strlen( "<div class=^"count ^">" );
				
				iDataStart += ADD_OTHER;
				
				copy( szInGame, sizeof szInGame -1, g_szData[ id ][ iDataStart ] );
				
				iDataStop = containi( szInGame, "<" );
				
				szInGame[ iDataStop ] = '^0';
			}
			
			iDataStart = containi( g_szData[ id ], "<div class=^"membercount online^">" );
			
			if( iDataStart != -1 )
			{
				iDataStart += strlen( "<div class=^"membercount online^">" );
				iDataStart += strlen( "<div class=^"count ^">" );
				
				iDataStart += ADD_OTHER;
				
				copy( szOnline, sizeof szOnline -1, g_szData[ id ][ iDataStart ] );
				
				iDataStop = containi( szOnline, "<" );
				
				szOnline[ iDataStop ] = '^0';
				
				ColorChat( ZERO, NORMAL, "%s Disconnect community Steam group:", g_szTag );
				ColorChat( ZERO, GREY, "^x01%s^x03 %s Members.", g_szTag, szMembers );
				ColorChat( ZERO, NORMAL, "%s^x04 %s InGame.", g_szTag, szInGame );
				ColorChat( ZERO, BLUE, "^x01%s^x03 %s Online.", g_szTag, szOnline );
			}
		}
		
		//CloseSocket( id + TASK_CLOSE, true );
	}
}

public CloseSocket( id, bool: bMsg )
{
	id -= TASK_CLOSE;
	
	if( bMsg && is_user_connected( id ) )
	{
		ColorChat( id, GREEN, "%s^x03 SteamCommunity^x01 has no responsed.", g_szTag );
	}
	
	if( task_exists( id + TASK_VERIFY ) )
	{
		remove_task( id + TASK_VERIFY );
	}
	
	if( task_exists( id + TASK_CLOSE ) )
	{
		remove_task( id + TASK_CLOSE );
	}
	
	socket_close( g_iSocket[ id ] );
	
	g_iSocket[ id ] = ZERO;
	
	g_iPacketNum[ id ] = ZERO;
	g_iError[ id ] = ZERO;
	
	copy( g_szData[ id ], sizeof g_szData[ ] -1, "" );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
