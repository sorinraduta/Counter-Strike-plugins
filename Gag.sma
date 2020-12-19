#include < amxmodx >
#include < amxmisc >
#include < cstrike >
#include < fakemeta >
#include < ColorChat >

#pragma semicolon 1

#define MAX_STORED 100
#define MAX_INTRODUCTIONS 5
#define TASK_HASGAG 55125


static const

	PLUGIN[ ]	= "Disconnect_Gag",
	VERSION[ ]	= "1.0",
	AUTHOR[ ]	= "Rap^^",
	TAG[ ]		= "[D/C]";


new const g_szIntroductions[ MAX_INTRODUCTIONS ][ 5 ] =
{
	"ba",
	"ma",
	"fa",
	"auzi",
	"cf"
};

enum _:Storage
{
	Name[ 32 ],
	Authid[ 32 ],
	IP[ 32 ],
	Duration
}

new g_szGagsStored[ MAX_STORED ][ Storage ];

new g_iSlot[ 33 ];

new g_szFile[ 32 ];

new g_iTotalGags;
new g_iLastWriter;
new g_iGagEntity;
new g_iSyncHud;


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );
	
	new const szHookChat[ ] = "HookChat";
	
	register_clcmd( "say",		szHookChat );
	register_clcmd( "say_team",	szHookChat );
	register_clcmd( "say /gag",	"ClCmdGag" );
	register_clcmd( "say /gaglist",	"ClCmdGagList" );
	
	register_concmd( "amx_gag", "ConCmdGag", ADMIN_SLAY, "<nume> <nume/durata> <durata>" );
	register_concmd( "amx_ungag", "ConCmdUnGag", ADMIN_SLAY, "<nume> <nume>" );
	
	register_forward( FM_ClientUserInfoChanged, "FwdClientUserInfoChanged" );
	register_forward( FM_Think, "FwdThink" );
	
	g_iGagEntity = CreateEntity( );
	g_iSyncHud = CreateHudSyncObj( );
	
	if( g_iTotalGags )
	{
		set_pev( g_iGagEntity, pev_nextthink, get_gametime( ) + 1.0 );
	}
}

public plugin_precache( )
{
	get_localinfo( "amxx_configsdir", g_szFile, charsmax( g_szFile ) );
	
	format( g_szFile, charsmax( g_szFile ), "%s/Gag.ini", g_szFile );

	new iFile = fopen( g_szFile, "rt" );
	
	if( !iFile )
	{
		return;
	}

	new szData[ 128 ];
	
	new szName[ 32 ];
	new szAuthid[ 32 ];
	new szIP[ 32 ];
	new szDuration[ 32 ];
	
	new iFreeSlot;
	
	while( !feof( iFile ) && ( g_iTotalGags < MAX_STORED ) )
	{
		fgets( iFile, szData, charsmax( szData ) );
		trim( szData );
		
		if( !szData[ 0 ] || szData[ 0 ] == ';' || ( szData[ 0 ] == '/' && szData[ 1 ] == '/' ) )
		{
			continue;
		}
		
		parse( szData, szName, charsmax( szName ), szAuthid, charsmax( szAuthid ),
		szIP, charsmax( szIP ), szDuration, charsmax( szDuration ) );
		
		g_iTotalGags++;
		
		iFreeSlot = CheckFreeSlot( );
		
		if( !iFreeSlot )
		{
			log_amx( "%s Numarul maxim de gag-uri active a fost atins.", TAG );
			
			continue;
		}
		
		copy( g_szGagsStored[ iFreeSlot ][ Name ], 31, szName );
		copy( g_szGagsStored[ iFreeSlot ][ Authid ], 31, szAuthid );
		copy( g_szGagsStored[ iFreeSlot ][ IP ], 31, szIP );
		
		g_szGagsStored[ iFreeSlot ][ Duration ] = str_to_num( szDuration );
	}
	
	fclose( iFile );
}

public plugin_end( )
{
	delete_file( g_szFile );
	
	new iFile = fopen( g_szFile, "wt" );
	
	if( !g_iTotalGags )
	{
		return;
	}
	
	new szData[ 128 ];
	
	for( new i = 1; i < MAX_STORED; i++ )
	{
		if( g_szGagsStored[ i ][ Name ][ 0 ] == EOS )
		{
			continue;
		}
		
		if( g_szGagsStored[ i ][ Duration ] )
		{
			formatex( szData, charsmax( szData ), "^"%s^" ^"%s^" ^"%s^" ^"%d^"^n",
			g_szGagsStored[ i ][ Name ],
			g_szGagsStored[ i ][ Authid ],
			g_szGagsStored[ i ][ IP ],
			g_szGagsStored[ i ][ Duration ] );
			
			fputs( iFile, szData );
		}
	}
	
	fclose( iFile );
}

public client_putinserver( id )
{
	new szName[ 32 ];
	new szAuthid[ 32 ];
	new szIP[ 32 ];
	
	get_user_name( id, szName, charsmax( szName ) );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );
	get_user_ip( id, szIP, charsmax( szIP ), 0 );

	g_iSlot[ id ] = 0;
	
	for( new i = 1; i < MAX_STORED; i++ )
	{
		if( equal( g_szGagsStored[ i ][ Name ], szName, strlen( szName ) )
		|| equal( g_szGagsStored[ i ][ Authid ], szAuthid, strlen( szAuthid ) )
		|| equal( g_szGagsStored[ i ][ IP ], szIP, strlen( szIP ) ) )
		{	
			g_iSlot[ id ] = i;
		}
	}
}

public client_disconnect( id )
{
	if( task_exists( id + TASK_HASGAG ) )
	{
		remove_task( id + TASK_HASGAG );
	}
	
	g_iSlot[ id ] = 0;
}

public HookChat( id )
{
	if( g_szGagsStored[ g_iSlot[ id ] ][ Duration ] )
	{
		if( task_exists( id + TASK_HASGAG ) )
		{
			remove_task( id + TASK_HASGAG );
		}
		
		YouHaveGag( id + TASK_HASGAG );
		
		set_task( 1.0, "YouHaveGag", id + TASK_HASGAG, "", 0, "a", 4 );
		
		return PLUGIN_HANDLED;
	}
	
	new szMessage[ 192 ];
	new szLeft[ 32 ];
	new szRight[ 32 ];
	new szName[ 32 ];
	
	new iGaged;
	
	read_args( szMessage, charsmax( szMessage ) );
	remove_quotes( szMessage );
	
	if( equali( szMessage, "" ) || equali( szMessage,  "/gag" ) )
	{
		return PLUGIN_CONTINUE;
	}
	
	g_iLastWriter = id;
	
	strbreak( szMessage, szName, charsmax( szName ), szRight, charsmax( szRight ) );
	
	iGaged = find_player( "bl", szName );
	
	if( g_szGagsStored[ g_iSlot[ iGaged ] ][ Duration ] )
	{
		AnnounceIsGaged( id, iGaged );
		
		return PLUGIN_CONTINUE;
	}
	
	strbreak( szMessage, szLeft, charsmax( szLeft ), szRight, charsmax( szRight ) );
	
	trim( szRight );
	
	strbreak( szRight, szName, charsmax( szName ), szRight, charsmax( szRight ) );
	
	iGaged = find_player( "bl", szName );
	
	if( g_szGagsStored[ g_iSlot[ iGaged ] ][ Duration ] )
	{
		for( new i = 0; i < sizeof g_szIntroductions; i++ )
		{
			if( equali( szLeft, g_szIntroductions[ i ], charsmax( g_szIntroductions[ ] ) ) )
			{
				AnnounceIsGaged( id, iGaged );
				
				return PLUGIN_CONTINUE;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public ConCmdGag( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}

	new szFirstPlayer[ 32 ];
	new szSecondPlayer[ 32 ];
	new szDuration[ 32 ];
	
	new iFirstPlayer;
	new iSecondPlayer;
	new iDuration;
	
	read_argv( 1, szFirstPlayer, charsmax( szFirstPlayer ) );
	read_argv( 2, szSecondPlayer, charsmax( szSecondPlayer ) );
	read_argv( 3, szDuration, charsmax( szDuration ) );
	
	iFirstPlayer = cmd_target( id, szFirstPlayer, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
	
	if( equal( szDuration, "", 0 ) )
	{
		if( equali( szSecondPlayer, "" ) )
		{
			iDuration = 5;
		}
		
		else if( is_str_num( szSecondPlayer ) )
		{
			read_argv( 2, szDuration, charsmax( szDuration ) );
			
			iDuration = str_to_num( szDuration );
		}
		
		else
		{
			iSecondPlayer = cmd_target( id, szSecondPlayer, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
			
			iDuration = 5;
	
			Gag( id, iFirstPlayer, iDuration, 0 );
			Gag( id, iSecondPlayer, iDuration, 0 );
			
			return PLUGIN_HANDLED;
		}
	}
	
	else
	{
		iSecondPlayer = cmd_target( id, szSecondPlayer, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
		
		iDuration = str_to_num( szDuration );
		
		iDuration = clamp( iDuration, 1, 10 );
	
		Gag( id, iFirstPlayer, iDuration, 0 );
		Gag( id, iSecondPlayer, iDuration, 0 );
		
		return PLUGIN_HANDLED;
	}
	
	iDuration = clamp( iDuration, 1, 10 );
	
	Gag( id, iFirstPlayer, iDuration, 0 );
	
	return PLUGIN_HANDLED;
}

public ConCmdUnGag( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}
	
	new szFirstPlayer[ 32 ];
	new szSecondPlayer[ 32 ];
	
	new iFirstPlayer;
	new iSecondPlayer;
	
	read_argv( 1, szFirstPlayer, charsmax( szFirstPlayer ) );
	read_argv( 2, szSecondPlayer, charsmax( szSecondPlayer ) );
	
	iFirstPlayer = cmd_target( id, szFirstPlayer, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
	
	UnGag( id, iFirstPlayer );
	
	if( !equali( szSecondPlayer, "" ) )
	{
		iSecondPlayer = cmd_target( id, szSecondPlayer, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
		
		UnGag( id, iSecondPlayer );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmdGag( id )
{
	if( !is_user_connected( g_iLastWriter ) )
	{
		ColorChat( id, GREEN, "%s^x01 Cel care a scris ultimul in chat s-a deconectat.", TAG );
		
		return PLUGIN_HANDLED;
	}
	
	new szMenu[ 128 ];
	new szGagedName[ 32 ];
	
	get_user_name( g_iLastWriter, szGagedName, charsmax( szGagedName ) );
	
	formatex( szMenu, charsmax( szMenu ), "\wDoresti sa ii dai gag jucatorului\y %s\w ?", szGagedName );
	
	new iMenu = menu_create( szMenu, "GagHandler", 0 );
	
	menu_additem( iMenu, "Da", szGagedName, 0 );
	menu_additem( iMenu, "Nu", szGagedName, 0 );
	
	menu_setprop( iMenu, MPROP_EXIT, MEXIT_NEVER );
	menu_display( id, iMenu );
	
	return PLUGIN_HANDLED;
}
/*
public ClCmdGagList( id )
{
	new szBuffer[ 2368 ];
	new iLen;
	new iCount;
	
	iLen = format( szBuffer[ iLen ], charsmax( szBuffer ) - iLen,"<STYLE>body{background-color:#000000; font-family:Tahoma; font-size:12px; color:#FFFFFF;}table{border-style:solid; border-width:1px; border-color:#FFFFFF; font-family:Tahoma; font-size:10px; color:#FFFFFF; }</STYLE><table align=center width=28%% cellpadding=1 cellspacing=0");
	iLen += format( szBuffer[ iLen ], charsmax( szBuffer ) - iLen, "<tr align=center bgcolor=#292929><th width=5%% > # <th width=15%%> Nume <th width=8%%> Durata");	
	
	for( new i = 1; i < MAX_STORED; i++ )
	{				
			if( containi( g_szGagsStored[ i ][ Name ], "<") != -1 )
			{
				replace( g_szGagsStored[ i ][ Name ], 31, "<", "&lt;");
			}
			
			if( containi( g_szGagsStored[ i ][ Name ], ">") != -1 )
			{
				replace( g_szGagsStored[ i ][ Name ], 31, ">", "&gt;");
			}
			
			if( i == g_iSlot[ id ] )
			{
				iLen += format( szBuffer[ iLen ], charsmax( szBuffer ) - iLen, "<tr align=center bgcolor=#2D2D2D><td> %d <td> %s <td> %d", ( i + 1 ), g_szGagsStored[ i ][ Name ], g_szGagsStored[ i ][ Duration ] );
			}
			
			else
			{
				iLen += format( szBuffer[ iLen ], charsmax( szBuffer ) - iLen, "<tr align=center bgcolor=#000000><td> %d <td> %s <td> %d", ( i + 1 ), g_szGagsStored[ i ][ Name ], g_szGagsStored[ i ][ Duration ] );
			}
			
			iCount++;
	}
	
	iLen += format( szBuffer[ iLen ], charsmax( szBuffer ) - iLen, "</table>" );

	show_motd( id, szBuffer, "Gag list" );
}
*/
public ClCmdGagList( id )
{
	new szBuffer[ 2368 ];
	new iLen;
	new iCount;
	
	iLen = format( szBuffer[ iLen ], charsmax( szBuffer ) - iLen,"<STYLE>body{background-color:#000000; font-family:Tahoma; font-size:12px; color:#FFFFFF;}table{border-style:solid; border-width:1px; border-color:#FFFFFF; font-family:Tahoma; font-size:10px; color:#FFFFFF; }</STYLE><table align=center width=28%% cellpadding=1 cellspacing=0");
	iLen += format( szBuffer[ iLen ], charsmax( szBuffer ) - iLen, "<tr align=center bgcolor=#292929><th width=5%% > # <th width=15%%> Nume <th width=8%%> Durata");	
	
	for( new i = 1; i < MAX_STORED; i++ )
	{	
		if( g_szGagsStored[ i ][ Duration ] )
		{			
			if( containi( g_szGagsStored[ i ][ Name ], "<") != -1 )
			{
				replace( g_szGagsStored[ i ][ Name ], 31, "<", "&lt;");
			}
			
			if( containi( g_szGagsStored[ i ][ Name ], ">") != -1 )
			{
				replace( g_szGagsStored[ i ][ Name ], 31, ">", "&gt;");
			}
			
			if( i == g_iSlot[ id ] )
			{
				iLen += format( szBuffer[ iLen ], charsmax( szBuffer ) - iLen, "<tr align=center bgcolor=#2D2D2D><td> %d <td> %s <td> %d", ( i + 1 ), g_szGagsStored[ i ][ Name ], g_szGagsStored[ i ][ Duration ] );
			}
			
			else
			{
				iLen += format( szBuffer[ iLen ], charsmax( szBuffer ) - iLen, "<tr align=center bgcolor=#000000><td> %d <td> %s <td> %d", ( i + 1 ), g_szGagsStored[ i ][ Name ], g_szGagsStored[ i ][ Duration ] );
			}
			
			iCount++;
		}
	}
	
	iLen += format( szBuffer[ iLen ], charsmax( szBuffer ) - iLen, "</table>" );
	
	if( iCount )
	{
		show_motd( id, szBuffer, "Gag list" );
	}
	
	else
	{
		ColorChat( id, GREEN, "%s^x01 Momentan nu eisxta gag-uri active.", TAG );
	}
}

public FwdClientUserInfoChanged( id )
{
	if( g_szGagsStored[ g_iSlot[ id ] ][ Duration ] )
	{
		static const szName[ ] = "name";
		
		static szOldName[ 32 ];
		static szNewName[ 32 ];
		
		pev( id, pev_netname, szOldName, charsmax( szOldName ) );
		
		if( szOldName[ 0 ] )
		{ 
			get_user_info( id, szName, szNewName, charsmax( szNewName ) );
			
			if( !equal( szOldName, szNewName ) )
			{
				console_print( id, "%^x01 Nu iti poti schimba numele cand ai gag.", TAG );
				
				set_user_info( id, szName, szOldName );
				
				return FMRES_HANDLED;
			} 
		}
	}
	
	return FMRES_IGNORED;
}

public FwdThink( iEntity )
{
	if( iEntity != g_iGagEntity )
	{
		return PLUGIN_CONTINUE;
	}
	
	new id;
	
	g_iTotalGags = 0;
	
	for( new i = 1; i < MAX_STORED; i++ )
	{	
		if( g_szGagsStored[ i ][ Duration ] )
		{
			//ColorChat( 0, GREEN, "CACA1 %d", g_szGagsStored[ i ][ Duration ] );
			id = find_player( "bl", g_szGagsStored[ i ][ Name ] );
			
			//ColorChat( 0, GREEN, "%s^x01 %s %d", TAG, g_szGagsStored[ i ][ Name ], i );
			
			if( --g_szGagsStored[ i ][ Duration ] <= 0 )
			{
				//ColorChat( 0, GREEN, "CACA2 %d", g_szGagsStored[ i ][ Duration ] );
				if( is_user_connected( id ) )
				{
					UnGag( 0, id );
					
					ColorChat( 0, GetTeamColor( id ), "^x04%s^x01 Gag-ul lui^x03 %s^x01 a expirat.", TAG, g_szGagsStored[ i ][ Name ] );
				}
				
				else
				{
					ColorChat( 0, GREEN, "%s^x01 Gag-ul lui^x04 %s^x01 a expirat.", TAG, g_szGagsStored[ i ][ Name ] );
				}
				
				ClearSlot( i );
				
				continue;
			}
			
			g_iTotalGags++;
		}
	}
	
	if( g_iTotalGags )
	{
		set_pev( iEntity, pev_nextthink, get_gametime( ) + 1.0 );
	}
	
	return PLUGIN_CONTINUE;
}

public GagHandler( id, iMenu, iItem )
{
	new _access;
	new iCallback;
	new iGaged;
	
	new szData[ 64 ];
	new szName[ 64 ];
	
	menu_item_getinfo( iMenu, iItem, _access, szData, charsmax( szData ), szName, charsmax( szName ), iCallback );
	menu_destroy( iMenu );
	
	iGaged = find_player( "bl", szData );
	
	if( !iGaged )
	{
		ColorChat( id, GREEN, "%s^x01 Jucatorul nu mai este conectat.", TAG );
		
		return PLUGIN_HANDLED;
	}
	
	if( iItem == 0 )
	{
		Gag( id, iGaged, 5, 0 );
	}
	
	return PLUGIN_HANDLED;
}

stock Gag( iAdmin, iGaged, iDuration, iSlot )
{
	if( !iGaged )
	{
		return PLUGIN_HANDLED;
	}
	
	if( g_szGagsStored[ g_iSlot[ iGaged ] ][ Duration ] )
	{
		console_print( iAdmin, "%s Jucatorul deja are gag.", TAG );
		
		return PLUGIN_HANDLED;
	}
	
	if( iAdmin )
	{
		new iFreeSlot = CheckFreeSlot( );
		
		if( !iFreeSlot )
		{
			console_print( iAdmin, "%s Numarul maxim de gag-uri active a fost atins.", TAG );
			
			return PLUGIN_HANDLED;
		}
		
		new szAdminName[ 32 ];
		
		get_user_name( iAdmin, szAdminName, charsmax( szAdminName ) );
		get_user_name( iGaged, g_szGagsStored[ iFreeSlot ][ Name ], 31 );
		get_user_authid( iGaged, g_szGagsStored[ iFreeSlot ][ Authid ], 31 );
		get_user_ip( iGaged, g_szGagsStored[ iFreeSlot ][ IP ], 31, 0 );
		
		g_iSlot[ iGaged ] = iFreeSlot;
		g_szGagsStored[ g_iSlot[ iGaged ] ][ Duration ] = iDuration * 60;
		
		console_print( iAdmin, "%s %s a primit gag pentru %d minut%s.", TAG, g_szGagsStored[ iFreeSlot ][ Name ], iDuration, iDuration == 1 ? "":"e" );
		ColorChat( 0, GetTeamColor( iGaged ), "^x04%s^x01 ADMIN^x04 %s^x01: Gag^x03 %s^x01 pentru^x03 %d^x01 minut%s.", TAG, szAdminName, g_szGagsStored[ iFreeSlot ][ Name ], iDuration, iDuration == 1 ? "":"e" );   
	}
	
	//if( !g_iSlot[ iGaged ] )
	else
	{
		g_iSlot[ iGaged ] = iSlot;
	}
	
	if( !g_iTotalGags )
	{
		set_pev( g_iGagEntity, pev_nextthink, get_gametime( ) + 1.0 );
	}
	
	return PLUGIN_HANDLED;
}

stock UnGag( iAdmin, iGaged )
{
	if( !iGaged )
	{
		return PLUGIN_HANDLED;
	}
	
	if( iAdmin )
	{
		if( !g_szGagsStored[ g_iSlot[ iGaged ] ][ Duration ] )
		{
			console_print( iAdmin, "%s Jucatorul nu are gag", TAG );
			
			return PLUGIN_HANDLED;
		}
		
		new szAdminName[ 32 ];
		new szGagedName[ 32 ];
		
		get_user_name( iAdmin, szAdminName, charsmax( szAdminName ) );
		get_user_name( iGaged, szGagedName, charsmax( szGagedName ) );
		
		ClearSlot( g_iSlot[ iGaged ] );
		
		console_print( iAdmin, "%s %s a primit ungag.", TAG, szGagedName );
		ColorChat( 0, GetTeamColor( iGaged ), "^x04%s^x01 ADMIN^x04 %s^x01: Ungag^x03 %s", TAG, szAdminName, szGagedName );
	}
	
	g_iSlot[ iGaged ] = 0;
	
	return PLUGIN_HANDLED;
}

public AnnounceIsGaged( id, iGaged )
{
	new szGagedName[ 32 ];
	
	get_user_name( iGaged, szGagedName, charsmax( szGagedName ) );
	
	ColorChat( id, GREEN, "%s^x01 Jucatorul^x04 %s^x01 are gag.", TAG, szGagedName );
}

public YouHaveGag( id )
{
	id -= TASK_HASGAG;
	
	new iDuration = g_szGagsStored[ g_iSlot[ id ] ][ Duration ];
	
	if( iDuration )
	{
		set_hudmessage( 255, 117, 117, -1.0, 0.23, 0, 0.0, 1.0, 0.1, 0.2, -1 );
		ShowSyncHudMsg( id, g_iSyncHud, "Mai ai gag inca %d secund%s", iDuration, iDuration == 1 ? "a":"e" );
	}
	
	else
	{
		if( task_exists( id + TASK_HASGAG ) )
		{
			remove_task( id + TASK_HASGAG );
		}
		
		set_hudmessage( 255, 117, 117, -1.0, 0.23, 0, 0.0, 4.0, 0.1, 0.2, -1 );
		ShowSyncHudMsg( id, g_iSyncHud, "Gag-ul a expirat" );
	}
}

stock Color: GetTeamColor( id )
{
	switch( cs_get_user_team( id ) )
	{
		case CS_TEAM_T:
		{
			return RED;
		}
		
		case CS_TEAM_CT:
		{
			return BLUE;
		}
		
		default:
		{
			return GREY;
		}
	}
	
	return GREY;
}

stock CreateEntity( )
{
	new iInfoTarget = engfunc( EngFunc_AllocString, "info_target" );
	new iEntity = engfunc( EngFunc_CreateNamedEntity, iInfoTarget );
	
	return iEntity;
}

stock ClearSlot( iSlot )
{
	g_szGagsStored[ iSlot ][ Name ][ 0 ] = EOS;
	g_szGagsStored[ iSlot ][ Authid ][ 0 ] = EOS;
	g_szGagsStored[ iSlot ][ IP ][ 0 ] = EOS;
	g_szGagsStored[ iSlot ][ Duration ] = 0;
}

stock CheckFreeSlot( )
{
	for( new i = 1; i < MAX_STORED; i++ )
	{
		if( g_szGagsStored[ i ][ Name ][ 0 ] == EOS )
		{
			return i;
		}
	}
	
	return 0;
}
