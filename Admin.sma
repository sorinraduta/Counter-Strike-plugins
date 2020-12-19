#include < amxmodx >
#include < amxmisc >
#include < ColorChat >

#pragma semicolon 1


static const

	PLUGIN[ ]	= "Admin",
	VERSION[ ]	= "0.1a",
	AUTHOR[ ]	= "Rap^^",
	TAG[ ]		= "[D/C]";


enum Admin
{
	CURRENT,
	SUSPENDED,
	EX
};

enum _: eStuffs
{
	Nick[ 32 ],
	Authid[ 32 ],
	Password[ 32 ],
	PasswordField[ 32 ],
	Warns[ 32 ],
	Start[ 32 ],
	Suspend[ 32 ],
	Stop[ 32 ],
	Rank
}

new const g_szAdmins[ ][ ] =
{
	"Owner",
	"Supervisor",
	"Moderator",
	"Administrator",
	"Helper",
	"VIP",
	"Slot"
};

new const g_szFlags[ ][ ] =
{
	"abcdefghijklmnopqrstu",	//  OWNER
	"abcdefghijkmnopqrst",		//  SUPERVISOR
	"abcdefghijkmnopqrs",		//  MODERATOR
	"abcdefhijkmnopqr",		//  ADMINISTRATOR
	"abcehijkmnopq",		//  HELPER
	"ab",				//  VIP
	"b"				//  SLOT
};

new Array: g_aCurrentAdmins;
new Array: g_aSuspendedAdmins;
new Array: g_aExAdmins;

new g_szAdminsFile[ 100 ];
new g_szExAdminsFile[ 100 ];

new g_szLoopback[ 32 ];

new g_iAdminCount[ 7 ];


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );

	format( g_szLoopback, charsmax( g_szLoopback ), "amxauth%c%c%c%c", random_num('A', 'Z'), random_num('A', 'Z'), random_num('A', 'Z'), random_num('A', 'Z') );

	register_concmd( "amx_reloadadmins", "ConCmdReload", ADMIN_CFG );

	new szClCmdAmxWho[ ] = "ClCmdAmxWho";
	new szClCmdAdmin[ ] = "ClCmdAdmin";

	register_clcmd( "amx_who",	szClCmdAmxWho );
	register_clcmd( "admin_who",	szClCmdAmxWho );
	register_clcmd( "say /admin",	szClCmdAdmin );
	register_clcmd( "say /admins",	szClCmdAdmin );
	register_clcmd( "say /who",	szClCmdAdmin );
	register_clcmd( g_szLoopback,	"ClCmdAckSignal" );

	remove_user_flags( 0, read_flags( "z" ) );

	g_aCurrentAdmins = ArrayCreate( 256, 1 );
	g_aSuspendedAdmins = ArrayCreate( 256, 1 );
	g_aExAdmins = ArrayCreate( 256, 1 );
}

public plugin_cfg( )
{
	new szConfigDirector[ 64 ];

	get_localinfo( "amxx_configsdir", szConfigDirector, charsmax( szConfigDirector ) );

	formatex( g_szAdminsFile, charsmax( g_szAdminsFile ), "%s/Admins.ini", szConfigDirector );
	formatex( g_szExAdminsFile, charsmax( g_szExAdminsFile ), "%s/ExAdmins.ini", szConfigDirector );

	UpdateAdminList( );
	UpdateExAdminList( );
}

public client_authorized( id )
{
	return AccessUser( id );
}

public client_putinserver( id ) //  In cazul in care cel care se conecteaza este creatorul unui new game
{
	if( !is_dedicated_server( ) && id == 1 )
	{
		return AccessUser( id );
	}

	return PLUGIN_CONTINUE;
}

public client_infochanged(id)
{
	if( !is_user_connected( id ) )
	{
		return PLUGIN_CONTINUE;
	}

	new szNewName[ 32 ];
	new szOldName[ 32 ];

	get_user_name( id, szOldName, charsmax( szOldName ) );
	get_user_info( id, "name", szNewName, charsmax( szNewName ) );

	if( !equali( szNewName, szOldName ) )
	{
		AccessUser( id, szNewName );
	}

	return PLUGIN_CONTINUE;
}

public ConCmdReload( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 1 ) )
	{
		return PLUGIN_HANDLED;
	}

	remove_user_flags( 0, read_flags( "z" ) );

	admins_flush( );

	UpdateAdminList( );
	UpdateExAdminList( );

	new iPlayers[ 32 ];

	new iNum;
	new player;

	get_players( iPlayers, iNum );

	for( new i = 0; i < iNum; i++ )
	{
		player = iPlayers[ i ];

		AccessUser( player );
	}

	console_print( id, "%s Lista de admini a fost actualizata", TAG );

	return PLUGIN_HANDLED;
}

public ClCmdAmxWho( id )
{
	console_print( id, "%s Pentru a vedea listele de admini, tasteaza in chat /admini", TAG );

	ClCmdAdmin( id );

	return PLUGIN_HANDLED;
}

public ClCmdAdmin( id )
{
	new iMenu = menu_create( "Lista adminilor", "MainHandler", 0 );

	menu_additem( iMenu, "Admini online",		"", 0 );
	menu_additem( iMenu, "Admini curenti",		"", 0 );
	menu_additem( iMenu, "Admini suspendati",	"", 0 );
	menu_additem( iMenu, "Fosti admini",		"", 0 );

	menu_setprop( iMenu, MPROP_EXITNAME, "Iesire" );
	menu_display( id, iMenu, 0 );

	return PLUGIN_HANDLED;
}

public OnlineAdmins( id )
{
	new szName[ 32 ];
	new szAdmin[ 32 ];
	new iPlayers[ 32 ];

	new iNum;
	new iCount;
	new player;

	new iMenu = menu_create( "Admini online", "ShowOnlineHandler", 0 );

	get_players( iPlayers, iNum, "ch" );

	for( new i = 0; i < sizeof g_szFlags; i++ )
	{
		for( new j = 0; j < iNum; j++ )
		{
			player = iPlayers[ j ];

			if( get_user_flags( player ) == read_flags( g_szFlags[ i ] ) )
			{
				get_user_name( player, szName, charsmax( szName ) );
				formatex( szAdmin, charsmax( szAdmin ), "\y[%s]\w %s", g_szAdmins[ i ], szName );

				menu_additem( iMenu, szAdmin, szName );

				iCount++;
			}
		}
	}

	if( !iCount )
	{
		ClCmdAdmin( id );

		ColorChat( id, GREEN, "%s^x01 Momentan nu este niciun admin online.", TAG );

		return PLUGIN_HANDLED;
	}


	menu_setprop( iMenu, MPROP_EXITNAME, "Inapoi" );
	menu_display( id, iMenu, 0 );

	return PLUGIN_HANDLED;
}

public CurrentsAdmins( id )
{
	new szTemp[ 32 ];

	new iMenu = menu_create( "Admini curenti", "CurrentHandler", 0 );

	for( new i = 0; i < sizeof g_szAdmins; i++ )
	{
		formatex( szTemp, charsmax( szTemp ), "%s \y(\r%d\y)", g_szAdmins[ i ], g_iAdminCount[ i ] );

		menu_additem( iMenu, szTemp );
	}

	menu_setprop( iMenu, MPROP_EXITNAME, "Inapoi" );
	menu_display( id, iMenu, 0 );
}

public SuspendedAdmins( id )
{
	new szTemp[ 256 ];

	new szItem[ 64 ];

	new szInfos[ eStuffs ];

	new iMenu = menu_create( "Admini suspendati", "ShowSuspendedHandler", 0 );

	new iArraySize = ArraySize( g_aSuspendedAdmins );

	for( new i = 0; i < iArraySize; i++ )
	{
		ArrayGetString( g_aSuspendedAdmins, i, szTemp, charsmax( szTemp ) );

		GetAdminInfo( szTemp, szInfos );

		formatex( szItem, charsmax( szItem ), "\y[%s]\w %s", g_szAdmins[ szInfos[ Rank ] ], szInfos[ Nick ] );

		menu_additem( iMenu, szItem, szInfos[ Nick ] );
	}

	if( !iArraySize )
	{
		ClCmdAdmin( id );

		ColorChat( id, GREEN, "%s^x01 Nu exista niciun admin suspendat.", TAG );

		return PLUGIN_HANDLED;
	}

	menu_setprop( iMenu, MPROP_EXITNAME, "Inapoi" );
	menu_display( id, iMenu, 0 );

	return PLUGIN_HANDLED;
}

public ExAdmins( id )
{
	new szTemp[ 256 ];

	new szItem[ 64 ];

	new szInfos[ eStuffs ];

	new iMenu = menu_create( "Fosti admini", "ShowExHandler", 0 );

	new iArraySize = ArraySize( g_aExAdmins );

	for( new i = 0; i < iArraySize; i++ )
	{
		ArrayGetString( g_aExAdmins, i, szTemp, charsmax( szTemp ) );

		GetAdminInfo( szTemp, szInfos );

		formatex( szItem, charsmax( szItem ), "\y[%s]\w %s", g_szAdmins[ szInfos[ Rank ] ], szInfos[ Nick ] );

		menu_additem( iMenu, szItem, szInfos[ Nick ] );
	}

	if( !iArraySize )
	{
		ClCmdAdmin( id );

		ColorChat( id, GREEN, "%s^x01 Nu exista niciun fost admin.", TAG );

		return PLUGIN_HANDLED;
	}

	menu_setprop( iMenu, MPROP_EXITNAME, "Inapoi" );
	menu_display( id, iMenu, 0 );

	return PLUGIN_HANDLED;
}

public CurrentRank( id, iRank )
{
	new szTemp[ 256 ];

	new szTitle[ 40 ];

	new szInfos[ eStuffs ];

	new iCount;

	formatex( szTitle, charsmax( szTitle ), "Admini curenti (\r%s\y)", g_szAdmins[ iRank ] );

	new iMenu = menu_create( szTitle, "ShowCurrentHandler", 0 );

	new iArraySize = ArraySize( g_aCurrentAdmins );

	for( new i = 0; i < iArraySize; i++ )
	{
		ArrayGetString( g_aCurrentAdmins, i, szTemp, charsmax( szTemp ) );

		GetAdminInfo( szTemp, szInfos );

		if( szInfos[ Rank ] == iRank )
		{
			menu_additem( iMenu, szInfos[ Nick ], szInfos[ Nick ] );

			iCount++;
		}
	}

	if( !iCount )
	{
		CurrentsAdmins( id );

		ColorChat( id, GREEN, "%s^x01 Momentan nu exista niciun^x03 %s^x01.", TAG, g_szAdmins[ iRank ] );//

		return PLUGIN_HANDLED;
	}

	menu_setprop( iMenu, MPROP_EXITNAME, "Inapoi" );
	menu_display( id, iMenu, 0 );

	return PLUGIN_HANDLED;
}

public MainHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( iMenu );

		return PLUGIN_HANDLED;
	}

	switch( iItem )
	{
		case 0:
		{
			OnlineAdmins( id );
		}

		case 1:
		{
			CurrentsAdmins( id );
		}

		case 2:
		{
			SuspendedAdmins( id );
		}

		case 3:
		{
			ExAdmins( id );
		}
	}

	return PLUGIN_HANDLED;
}

public ShowOnlineHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( iMenu );

		ClCmdAdmin( id );

		return PLUGIN_HANDLED;
	}

	new szData[ 32 ];

	new szName[ 6 ];

	new iAccess;
	new iCallback;

	menu_item_getinfo( iMenu, iItem, iAccess, szData, charsmax( szData ), szName, charsmax( szName ), iCallback );

	ShowInfo( id, szData, CURRENT );

	menu_display( id, iMenu, 0 );

	return PLUGIN_HANDLED;
}

public ShowCurrentHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( iMenu );

		CurrentsAdmins( id );

		return PLUGIN_HANDLED;
	}

	new szData[ 32 ];

	new szName[ 6 ];

	new iAccess;
	new iCallback;

	menu_item_getinfo( iMenu, iItem, iAccess, szData, charsmax( szData ), szName, charsmax( szName ), iCallback );

	ShowInfo( id, szData, CURRENT );

	menu_display( id, iMenu, 0 );

	return PLUGIN_HANDLED;
}

public ShowSuspendedHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( iMenu );

		ClCmdAdmin( id );

		return PLUGIN_HANDLED;
	}

	new szData[ 32 ];

	new szName[ 6 ];

	new iAccess;
	new iCallback;

	menu_item_getinfo( iMenu, iItem, iAccess, szData, charsmax( szData ), szName, charsmax( szName ), iCallback );

	ShowInfo( id, szData, SUSPENDED );

	menu_display( id, iMenu, 0 );

	return PLUGIN_HANDLED;
}

public ShowExHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( iMenu );

		ClCmdAdmin( id );

		return PLUGIN_HANDLED;
	}

	new szData[ 32 ];

	new szName[ 6 ];

	new iAccess;
	new iCallback;

	menu_item_getinfo( iMenu, iItem, iAccess, szData, charsmax( szData ), szName, charsmax( szName ), iCallback );

	ShowInfo( id, szData, EX );

	menu_display( id, iMenu, 0 );

	return PLUGIN_HANDLED;
}

public CurrentHandler( id, iMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( iMenu );

		ClCmdAdmin( id );

		return PLUGIN_HANDLED;
	}

	CurrentRank( id, iItem );

	return PLUGIN_HANDLED;
}

GetAdminInfo( szData[ ], szInfos[ eStuffs ] )
{
	new szRank[ 5 ];

	parse( szData,
	szInfos[ Nick ], charsmax( szInfos[ Nick ] ),
	szInfos[ Authid ], charsmax( szInfos[ Authid ] ),
	szInfos[ PasswordField ], charsmax( szInfos[ PasswordField ] ),
	szInfos[ Password ], charsmax( szInfos[ Password ] ),
	szInfos[ Warns ], charsmax( szInfos[ Warns ] ),
	szInfos[ Start ], charsmax( szInfos[ Start ] ),
	szInfos[ Suspend ], charsmax( szInfos[ Suspend ] ),
	szInfos[ Stop ], charsmax( szInfos[ Stop ] ),
	szRank, charsmax( szRank ) );

	szInfos[ Rank ] = str_to_num( szRank );
}

GetAdminInfoWithName( szAdminName[ ], szInfos[ eStuffs ], Admin: iType )
{
	new Array: aArray;

	new szData[ 256 ];

	switch( iType )
	{
		case CURRENT:
		{
			aArray = g_aCurrentAdmins;
		}

		case SUSPENDED:
		{
			aArray = g_aSuspendedAdmins;
		}

		case EX:
		{
			aArray = g_aExAdmins;
		}
	}

	new iArraySize = ArraySize( aArray );

	for( new i = 0; i < iArraySize; i++ )
	{
		ArrayGetString( aArray, i, szData, charsmax( szData ) );

		GetAdminInfo( szData, szInfos );

		if( equal( szAdminName, szInfos[ Nick ] ) )
		{
			break;
		}
	}
}

ShowInfo( id, szAdminName[ ], Admin: iType )
{
	new szMOTD[ 2500 ];

	new szInfos[ eStuffs ];

	GetAdminInfoWithName( szAdminName, szInfos, iType );

	new iLen = formatex( szMOTD, sizeof szMOTD - 1, "<html>" );
	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "<style type=^"text/css^">" );
	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "body{background-image:url(^"http://i52.tinypic.com/qoukhx.png^");font-family:Tahoma;font-size:15px;color:#FFFFFF;}" );
	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "table{font-family:Tahoma;font-size:10px;color:#FFFFFF;}" );
	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "</style>" );
	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "<body>" );
	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "<br><center><b><font face=^"Verdana^" size=^"4^" color=^"#B80000^">" );
	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "Informatii admin:" );
	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "<br></font><font face=^"Verdana^" size=^"3^">" );
	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "%s", szAdminName );
	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "</font><br><br></center>" );
	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "<table align=center width=65%% cellpadding=1 cellspacing=0>" );
	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "<tr><th width=13%%><th width=13%%>" );

	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "<tr align=center><td>Rang</td><td>%s</td>", g_szAdmins[ szInfos[ Rank ] ] );
	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "<tr align=center><td>STEAMID</td><td>%s</td>", szInfos[ Authid ] );

	if( iType == CURRENT )
	{
		iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "<tr align=center><td>Warn-uri</td><td>%s</td>", szInfos[ Warns ] );
	}

	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "<tr align=center><td>Data primirii adminului</td><td>%s</td>", szInfos[ Start ] );

	if( iType == SUSPENDED )
	{
		iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "<tr align=center><td>Data expirarii suspendarii</td><td>%s</td>", szInfos[ Suspend ] );
	}

	if( iType == EX )
	{
		iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "<tr align=center><td>Data stergerii adminului</td><td>%s</td>", szInfos[ Stop ] );
	}

	else
	{
		iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "<tr align=center><td>Data expirarii adminului</td><td>%s</td>", szInfos[ Stop ] );
	}
	//iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "" );

	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "</table>" );
	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "<center><br><br><br>" );
	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "Admin system v0.1a" );
	iLen += format( szMOTD[ iLen ], sizeof szMOTD - iLen - 1, "</center></body></html>" );

	show_motd( id, szMOTD, "asdasdas" );
}

AccessUser( id, szName[ ] = "" )
{
	remove_user_flags( id );

	new szUserAuthid[ 32 ];
	new szUserName[ 32 ];

	get_user_authid( id, szUserAuthid, charsmax( szUserAuthid ) );

	if( szName[ 0 ] )
	{
		copy( szUserName, charsmax( szUserName ), szName );
	}

	else
	{
		get_user_name( id, szUserName, charsmax( szUserName ) );
	}

	if( GetAccess( id, szUserName, szUserAuthid ) )
	{
		console_print( id, "%s Admin acceptat", TAG );

		return PLUGIN_CONTINUE;
	}

	else
	{
		new iFlags = read_flags( "z" );

		set_user_flags( id, iFlags );
	}

	return PLUGIN_HANDLED;
}

GetAccess( id, szUserName[ ], szUserAuthid[ ] )
{
	new szData[ 256 ];

	new szUserPassword[ 32 ];

	new szInfos[ eStuffs ];

	new iArraySize = ArraySize( g_aCurrentAdmins );

	for( new i = 0; i < iArraySize; i++ )
	{
		ArrayGetString( g_aCurrentAdmins, i, szData, charsmax( szData ) );

		GetAdminInfo( szData, szInfos );

		get_user_info( id, szInfos[ PasswordField ], szUserPassword, charsmax( szUserPassword ) );

		if( equali( szUserName, szInfos[ Nick ] ) )
		{
			if( equali( szUserAuthid, szInfos[ Authid ] ) )
			{
				if( equali( szUserPassword, szInfos[ Password ] ) )
				{
					new iFlags = read_flags( g_szFlags[ szInfos[ Rank ] ] );

					set_user_flags( id, iFlags );

					return true;
				}

				WrongAdmin( id );

				return false;

			}

			WrongAdmin( id );
		}
	}

	return false;
}

UpdateAdminList( )
{
	new iFile = fopen( g_szAdminsFile, "rt" );

	if( !iFile )
	{
		return;
	}

	new szData[ 256 ];

	new iPlayers[ 32 ];

	new szInfos[ eStuffs ];

	new player;
	new iNum;
	new iRank = -1;

	ArrayClear( g_aCurrentAdmins );
	ArrayClear( g_aSuspendedAdmins );
	arrayset( g_iAdminCount, 0, sizeof g_iAdminCount );

	while( !feof( iFile ) )
	{
		fgets( iFile, szData, charsmax( szData ) );
		trim( szData );

		if( !szData[ 0 ] || szData[ 0 ] == ';' || ( szData[ 0 ] == '/' && szData[ 1 ] == '/' ) )
		{
			continue;
		}

		if( szData[ 0 ] == '[' )
		{
			iRank++;

			continue;
		}

		format( szData, charsmax( szData ), "%s ^"%d^"", szData, iRank );

		GetAdminInfo( szData, szInfos );

		if( szInfos[ Suspend ][ 0 ] )
		{
			ArrayPushString( g_aSuspendedAdmins, szData );
		}

		else
		{
			ArrayPushString( g_aCurrentAdmins, szData );

			g_iAdminCount[ iRank ]++;
		}
	}

	fclose( iFile );

	get_players( iPlayers, iNum, "ch" );

	for( new i = 0; i < iNum; i++ )
	{
		player = iPlayers[ i ];

		AccessUser( player );
	}
}

UpdateExAdminList( )
{
	new iFile = fopen( g_szExAdminsFile, "rt" );

	if( !iFile )
	{
		return;
	}

	new szData[ 256 ];

	ArrayClear( g_aExAdmins );

	while( !feof( iFile ) )
	{
		fgets( iFile, szData, charsmax( szData ) );
		trim( szData );

		if( !szData[ 0 ] || szData[ 0 ] == ';' || ( szData[ 0 ] == '/' && szData[ 1 ] == '/' ) )
		{
			continue;
		}

		ArrayPushString( g_aExAdmins, szData );
	}

	fclose( iFile );
}

public ClCmdAckSignal( id )
{
	server_cmd( "kick #%d ^"Acest nume este rezervat^"", get_user_userid( id ) );

	return PLUGIN_HANDLED;
}

WrongAdmin( id )
{
	client_cmd( id, "%s", g_szLoopback );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
