#include < amxmodx >
#include < amxmisc >
#include < sockets >
#include < ColorChat >

#pragma semicolon 1

#define TASK_CHANGE	10223
#define TASK_CLOSE	10323
#define TASK_DISPLAY	10423
#define	ADD_OTHER	15


static const

	PLUGIN[ ] =			"Gametracker_Stats",
	VERSION[ ] =			"1.4.9",
	AUTHOR[ ] =			"Askhanar"; // Rap^ update


new const g_szTag[ ] =			"[D/C]";
new const g_szHost[ ] =			"www.gametracker.com";
new const g_szPlayer[ ] =		"/player";

new const g_szServerNotFound[ ] =	"No Statistics Available";
new const g_szPlayerNotFound[ ] =	"Player Not Found";
new const g_szPlayerSearchFor[ ] =	"Player Search for";

new g_szRequest[ 33 ][ 128 ];
new g_szData[ 33 ][ 4096 ];
new g_szName[ 33 ][ 32 ];
new g_szFirstSeen[ 33 ][ 15 ];
new g_szLastSeen[ 33 ][ 25 ];

new g_szServerIP[ 32 ];

new g_iMinutesPlayed[ 33 ];
new g_iSocket[ 33 ];
new g_iPacketNum[ 33 ];
new g_iError[ 33 ];


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );

	new const szHookSay[ ] = "HookSay";

	register_clcmd( "say",		szHookSay );
	register_clcmd( "say_team",	szHookSay );

	register_clcmd( "gt_stats", "ClCmdGTStats" );

	get_user_ip( 0, g_szServerIP, charsmax( g_szServerIP ), 0 );
}

public HookSay( id )
{
	static szArgs[ 192 ];

	read_args( szArgs, charsmax( szArgs ) );

	if( !szArgs[ 0 ] )
	{
		return PLUGIN_CONTINUE;
	}

	remove_quotes( szArgs );

	if( equal( szArgs, "/gtstats", strlen( "/gtstats" ) )
	|| equal( szArgs, "/time", strlen( "/time" ) )
	|| equal( szArgs, "/ore", strlen( "/ore" ) )
	|| equal( szArgs, "/gt", strlen( "/gt" ) ) )
	{
		static szCommand[ 192 ];
		static szLeft[ 192 ];

		strbreak( szArgs, szLeft, charsmax( szLeft ), szCommand, charsmax( szCommand ) );

		trim( szCommand );

		format( szCommand, charsmax( szCommand ), "gt_stats %s", szCommand );

		client_cmd( id, szCommand );

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public ClCmdGTStats( id )
{
	new szFirstArg[ 32 ];

    	read_argv( 1, szFirstArg, charsmax( szFirstArg ) );

	if( equali( szFirstArg, "" ) )
	{
		ColorChat( id, GREEN, "%s^x01 Utilizare: /ore <nume>", g_szTag );
	}

	else
	{
		new iPlayer = cmd_target( id, szFirstArg, 8 );

		if( !iPlayer  )
		{
			ColorChat( id, GREEN, "%s^x01 Jucatorul '%s' nu este conectat.", g_szTag, szFirstArg );

			return PLUGIN_HANDLED;
		}

		get_user_name( iPlayer, g_szName[ id ], charsmax( g_szName[ ] ) );
		ReplaceName( id, true );
		BeginShowingStats( id, g_szName[ id ] );
	}

	return PLUGIN_HANDLED;
}

public BeginShowingStats( id, const szName[ ] )
{
	if( g_iSocket[ id ] > 0 )
	{
		socket_close( g_iSocket[ id ] );
	}

	g_iSocket[ id ] = socket_open( g_szHost, 80, SOCKET_TCP, g_iError[ id ] );

	if( g_iError[ id ] == 0 && g_iSocket[ id ] > 0 )
	{
		formatex( g_szRequest[ id ], charsmax( g_szRequest[ ] ), "GET %s/%s/%s HTTP/1.1^r^nHost: %s^r^n^r^n", g_szPlayer, szName, g_szServerIP, g_szHost );

		socket_send( g_iSocket[ id ], g_szRequest[ id ], sizeof( g_szRequest[ ] ) );

		g_iPacketNum[ id ] = 0;

		set_task( 0.1, "TaskChange", id + TASK_CHANGE, _, _, "b", 0 );
		set_task( 3.1, "TaskClose", id + TASK_CLOSE );

		ColorChat( id, GREEN, "%s^x01 Te rugam sa astepti pana cand^x03 GameTracker^x01 va raspunde...", g_szTag );

	}

	else
	{
		switch( g_iError[ id ] )
		{
			case 1:	log_amx( "[ERROR] Unable to create socket." );
			case 2:	log_amx( "[ERROR] Unable to connect to hostname." );
			case 3:	log_amx( "[ERROR] Unable to connect to the HTTP port." );

		}

		ColorChat( id, GREEN, "%s^x01 A aparut o eroare in timpul stabilirii conexiunii.", g_szTag );

		return PLUGIN_HANDLED;
	}

	remove_task( id + TASK_DISPLAY );
	set_task( 3.0, "TaskDisplay", id + TASK_DISPLAY );

	return PLUGIN_CONTINUE;

}

public TaskChange( id )
{
	id -= TASK_CHANGE;

	if( !is_user_connected( id ) )
	{
		return;
	}

	if( socket_change( g_iSocket[ id ], 0 ) )
	{

		if( socket_recv( g_iSocket[ id ], g_szData[ id ], sizeof( g_szData[ ] ) ) )
		{
			if( ++g_iPacketNum[ id ] == 1 )
			{
				if( containi( g_szData[ id ], g_szServerNotFound ) != -1 )
				{
					ColorChat( id, GREEN, "%s^x01 Acest server nu se afla in baza de date^x03 GameTracker^x01.", g_szTag );

					TaskClose( id + TASK_CLOSE );

					return;
				}

				if( containi( g_szData[ id ], g_szPlayerNotFound ) != -1 || containi( g_szData[ id ], g_szPlayerSearchFor ) != -1 )
				{
					ReplaceName( id, false );

					ColorChat( id, GREEN, "%s^x01 Jucatorul '%s' nu a fost gasit in baza de date^x03 GameTracker^x01.", g_szTag, g_szName[ id ] );

					TaskClose( id + TASK_CLOSE );

					return;
				}
			}

			static iDataStart;

			iDataStart = containi( g_szData[ id ], "First Seen:" );

			if( iDataStart != -1 )
			{
				iDataStart += strlen( "First Seen:" );
				iDataStart += ADD_OTHER;

				copy( g_szFirstSeen[ id ], charsmax( g_szFirstSeen[ ] ), g_szData[ id ][ iDataStart ] );

				g_szFirstSeen[ id ][ 12 ] = EOS;

				Translate( g_szFirstSeen[ id ], charsmax( g_szFirstSeen[ ] ) );
			}

			iDataStart = containi( g_szData[ id ], "Last Seen:" );

			if( iDataStart != -1 )
			{
				iDataStart += strlen( "Last Seen:" );
				iDataStart += ADD_OTHER;

				copy( g_szLastSeen[ id ], charsmax( g_szLastSeen[ ] ), g_szData[ id ][ iDataStart ] );

				if( containi( g_szLastSeen[ id ], "Online Now" ) != -1 )
				{
					g_szLastSeen[ id ][ 10 ] = EOS;
				}

				else
				{
					new j = 0;

					while( ( g_szLastSeen[ id ][ j ] != 'A' && g_szLastSeen[ id ][ j ] != 'P' ) && g_szLastSeen[ id ][ j + 1 ] != 'M' )
					{
						j++;
					}

					g_szLastSeen[ id ][ j + 2 ] = EOS;
				}

				Translate( g_szLastSeen[ id ], charsmax( g_szLastSeen[ ] ) );
			}

			if( containi( g_szLastSeen[ id ], "Online Now" ) != -1 )
			{

				new iAllStats = containi( g_szData[ id ], "ALL TIME STATS" );

				if( iAllStats != -1 )
				{
					format( g_szData[ id ], charsmax( g_szData[ ] ), "%s", g_szData[ id ][ iAllStats ] );
				}
			}

			iDataStart = containi( g_szData[ id ], "Minutes Played:" );

			if( iDataStart != -1 )
			{
				iDataStart += strlen( "Minutes Played:" );
				iDataStart += ADD_OTHER;

				g_iMinutesPlayed[ id ] = str_to_num( g_szData[ id ][ iDataStart ] );
			}
		}
	}

}

public TaskClose( id )
{
	id -= TASK_CLOSE;

	if( !is_user_connected( id ) )
	{
		return;
	}

	remove_task( id + TASK_CHANGE );
	remove_task( id + TASK_DISPLAY );

	socket_close( g_iSocket[ id ] );

	g_iSocket[ id ] = 0;
	g_iPacketNum[ id ] = 0;
	g_iError[ id ] = 0;

	copy( g_szData[ id ], charsmax( g_szData[ ] ), "" );

}

public TaskDisplay( id )
{
	id -= TASK_DISPLAY;

	if( !is_user_connected( id ) )
	{
		return;
	}

	ColorChat( id, GREEN, "%s Conexiunea cu^x03 GameTracker^x01 a fost realizata.", g_szTag );

	GTStatsMenu( id );
}


public GTStatsMenu( id )
{
	new szMenuName[ 256 ], iLen;

	ReplaceName( id, false );

	iLen = format( szMenuName, charsmax( szMenuName ), "\w Statistici GameTracker:\r %s^n^n", g_szName[ id ] );
	iLen += format( szMenuName[ iLen ], charsmax( szMenuName ) - iLen, "\w Prima vizita:\r %s^n", g_szFirstSeen[ id ] );
	iLen += format( szMenuName[ iLen ], charsmax( szMenuName ) - iLen, "\w Ultima vizita:\r %s^n", g_szLastSeen[ id ] );
	iLen += format( szMenuName[ iLen ], charsmax( szMenuName ) - iLen, "\w Minute jucate:\r %s \w(\r%s\w)^n", g_iMinutesPlayed[ id ], GetPlayedTime( g_iMinutesPlayed[ id ] ) );

	new iMenu = menu_create( szMenuName, "GTStatsMenuHandler");

	menu_additem( iMenu, "\wApasa pe \r1\w pentru a vedea statisticile in\y MOTD^n\wStatistici luate direct de pe:\r        www.gametracker.com", "", 0 );

	menu_display( id, iMenu, 0 );
}

public GTStatsMenuHandler( id, iMenu, iItem)
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( iMenu );

		return;
	}

	menu_destroy( iMenu );

	ReplaceName( id, true );

	new szCustomURL[ 128 ];

	formatex( szCustomURL, charsmax( szCustomURL ), "http://%s%s/%s/%s/", g_szHost, g_szPlayer, g_szName[ id ], g_szServerIP );

	show_motd( id, szCustomURL );

	GTStatsMenu( id );
}

GetPlayedTime( const iTime )
{
	new bool: UseFormat = false;

	new szTime[ 64 ];

	new iSeconds = iTime * 60;
	new iMinutes = 0;
	new iHours = 0;

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
		formatex( szTime,  charsmax( szTime ), "%i s", iSeconds );

		UseFormat = true;
	}

	if( iMinutes )
	{
		if( UseFormat )
		{
			format( szTime,  charsmax( szTime ), "%i m, %s", iMinutes,  szTime );
		}

		else
		{
			formatex( szTime,  charsmax( szTime ), "%i m", iMinutes);

			UseFormat = true;
		}
	}

	if( iHours )
	{
		if( UseFormat )
		{
			format( szTime,  charsmax( szTime ), "%i o, %s", iHours,  szTime );
		}

		else
		{
			formatex( szTime,  charsmax( szTime ), "%i o", iHours );

			UseFormat = true;
		}
	}

	if( !UseFormat )
	{
		copy( szTime,  charsmax( szTime ), "Necunoscut" );
	}

	return  szTime;
}

Translate( szDate[ ], iLen )
{
	if( contain( szDate, "," ) )
	{
		new szDay[ 32 ];
		new szMonth[ 32 ];
		new szYear[ 32 ];

		strtok( szDate, szMonth, charsmax( szMonth ), szYear, charsmax( szYear ), ',', 1 );
		strbreak( szDate, szMonth, charsmax( szMonth ), szDay, charsmax( szDay ) );

		format( szDate, iLen, "%s %s. %s", szDay, szMonth, szYear );

		replace( szDate, iLen, "Jan", "Ian" );
		replace( szDate, iLen, "May.", "Mai" );
		replace( szDate, iLen, "Jun", "Iun" );
		replace( szDate, iLen, "Jul", "Iul" );
		replace( szDate, iLen, "Nov", "Noi" );
	}

	else
	{
		replace( szDate, iLen, "Today", "Astazi" );
		replace( szDate, iLen, "Yesterday", "Ieri" );
	}
}

ReplaceName( id, const bool: bSafe = true )
{
	if( bSafe )
	{
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "#", "%23" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "?", "%3F" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), ":", "%3A" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), ";", "%3B" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "/", "%2F" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), ",", "%2C" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "$", "%24" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "@", "%40" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "+", "%2B" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "=", "%3D" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "®", "Â®" );
	}

	else
	{
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "%23", "#" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "%3F", "?" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "%3A", ":" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "%3B", ";" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "%2F", "/" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "%2C", "," );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "%24", "$" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "%40", "@" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "%2B", "+" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "%3D", "=" );
		replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "Â®", "®" );

	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
