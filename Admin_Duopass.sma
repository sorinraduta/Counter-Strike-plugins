// Uncomment for SQL version
// #define USING_SQL

#include < amxmodx >
#include < amxmisc >

#if defined USING_SQL
  #include < sqlx >
#endif

#pragma semicolon 1

new PLUGINNAME[] = "AMX Mod X";

#define ADMIN_LOOKUP	(1<<0)
#define ADMIN_NORMAL	(1<<1)
#define ADMIN_STEAM	(1<<2)
#define ADMIN_IPADDR	(1<<3)
#define ADMIN_NAME	(1<<4)

enum _: eStuffs
{
	Key[ 32 ],
	PasswordField[ 32 ],
	Password[ 32 ],
	Flags[ 32 ],
	KeyType[ 32 ]
}

new Array: g_aAdmins;

new bool: g_iCaseSensitiveName[ 33 ];

new g_szFile[ 64 ];

new g_szLoopback[ 16 ];

new g_iAdminCount;

new amx_mode;
new amx_default_access;

public plugin_init( )
{
#if defined USING_SQL
	register_plugin( "Admin duopass Base (SQL)", AMXX_VERSION_STR, "AMXX Dev Team (Edit Rap^^)" );
#else
	register_plugin( "Admin duopass Base", AMXX_VERSION_STR, "AMXX Dev Team (Edit Rap^^)" );
#endif
	register_dictionary( "admin.txt" );
	register_dictionary( "common.txt" );
	
	amx_mode = register_cvar( "amx_mode", "1" );
	amx_default_access = register_cvar( "amx_default_access", "" );

	register_cvar( "amx_vote_ratio", "0.02" );
	register_cvar( "amx_vote_time", "10" );
	register_cvar( "amx_vote_answers", "1" );
	register_cvar( "amx_vote_delay", "60" );
	register_cvar( "amx_last_voting", "0" );
	register_cvar( "amx_show_activity", "2" );
	register_cvar( "amx_votekick_ratio", "0.40" );
	register_cvar( "amx_voteban_ratio", "0.40" );
	register_cvar( "amx_votemap_ratio", "0.40" );

	set_cvar_float( "amx_last_voting", 0.0 );

#if defined USING_SQL
	register_srvcmd( "amx_sqladmins", "adminSql" );
	register_cvar( "amx_sql_table", "admins" );
#endif
	register_cvar( "amx_sql_host", "127.0.0.1" );
	register_cvar( "amx_sql_user", "root" );
	register_cvar( "amx_sql_pass", "" );
	register_cvar( "amx_sql_db", "amx" );
	register_cvar( "amx_sql_type", "mysql" );

	register_concmd( "amx_reloadadmins", "ConCmdReload", ADMIN_CFG );
	register_concmd( "amx_addadmin", "ConCmdAddAdmin", ADMIN_RCON, "<name|auth> <accessflags> [password1] [password2] [authtype] - add specified player as an admin to users.ini" );
	
	g_aAdmins = ArrayCreate( 256, 1 );
	
	format( g_szLoopback, charsmax( g_szLoopback ), "amxauth%c%c%c%c", random_num( 'A', 'Z' ), random_num( 'A', 'Z' ), random_num( 'A', 'Z' ), random_num( 'A', 'Z' ) );

	register_clcmd( g_szLoopback, "AckSignal" );

	remove_user_flags( 0, read_flags( "z" ) );		// Remove 'user' flag from server rights
	
	get_configsdir( g_szFile, charsmax( g_szFile ) );
	
	server_cmd( "exec %s/amxx.cfg", g_szFile );		// Execute main configuration file
	server_cmd( "exec %s/sql.cfg", g_szFile );
	
#if defined USING_SQL
	server_cmd( "amx_sqladmins" );
#else
	format( g_szFile, charsmax( g_szFile ), "%s/users.ini", g_szFile );
	
	LoadSettings( g_szFile );				// Load admins accounts
#endif
}

public plugin_cfg( )
{
	set_task( 6.1, "DelayedLoad" );
}

public client_authorized( id )
{
	return get_pcvar_num( amx_mode ) ? AccessUser( id ) : PLUGIN_CONTINUE;
}

public client_connect( id )
{
	g_iCaseSensitiveName[ id ] = false;
}

public client_putinserver( id )
{
	if( !is_dedicated_server( ) && id == 1 )
	{
		return get_pcvar_num( amx_mode ) ? AccessUser( id ) : PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE;
}

public client_infochanged( id )
{
	if( !is_user_connected( id ) || !get_pcvar_num( amx_mode ) )
	{
		return PLUGIN_CONTINUE;
	}
	
	new szOldName[ 32 ];
	new szNewName[ 32 ];
	
	get_user_name( id, szOldName, charsmax( szOldName ) );
	get_user_info( id, "name", szNewName, charsmax( szNewName ) );
	
	if( g_iCaseSensitiveName[ id ] )
	{
		if( !equal( szNewName, szOldName ) )
		{
			AccessUser( id, szNewName );
		}
	}
	
	else
	{
		if( !equali( szNewName, szOldName ) )
		{
			AccessUser( id, szNewName );
		}
	}
	
	return PLUGIN_CONTINUE;
}

public ConCmdReload( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 1 ) )
	{
		return PLUGIN_HANDLED;
	}

	//strip original flags (patch submitted by mrhunt)
	remove_user_flags( 0, read_flags( "z" ) );
	
#if !defined USING_SQL

	g_iAdminCount = 0;
	
	LoadSettings( g_szFile );		// Re-Load admins accounts
	
	/*
	if( id != 0 )
	{
		if( AdminCount == 1 )
		{
			console_print( id, "[AMXX] %L", LANG_SERVER, "LOADED_ADMIN" );
		}
		
		else
		{
			console_print( id, "[AMXX] %L", LANG_SERVER, "LOADED_ADMINS", g_iAdminCount );
		}
	}*/
#else
	g_iAdminCount = 0;
	
	AdminSQL( );

	if( id != 0 )
	{
		if( AdminCount == 1 )
		{
			console_print( id, "[AMXX] %L", LANG_SERVER, "LOADED_ADMIN" );
		}
		
		else
		{
			console_print( id, "[AMXX] %L", LANG_SERVER, "LOADED_ADMINS", g_iAdminCount );
		}
	}
#endif

	new iPlayers[ 32 ];
	new szName[ 32 ];
	
	new iNum;
	new player;
	
	get_players( iPlayers, iNum );
	
	for( new i = 0; i < iNum; i++ )
	{
		player = iPlayers[ i ];
		
		get_user_name( player, szName, charsmax( szName ) );
		AccessUser( player, szName );
	}

	return PLUGIN_HANDLED;
}

public ConCmdAddAdmin( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 3 ) )
	{
		return PLUGIN_HANDLED;
	}
	
	new idtype = ADMIN_STEAM | ADMIN_LOOKUP;

	if( read_argc( ) >= 6 )
	{
		new szAuthType[ 16 ];
		
		read_argv( 5, szAuthType, charsmax( szAuthType ) );
		
		if(equali( szAuthType, "steam" ) || equali( szAuthType, "steamid" ) || equali( szAuthType, "auth" ) )
		{
			idtype = ADMIN_STEAM;
		}
		
		else if( equali( szAuthType, "ip" ) )
		{
			idtype = ADMIN_IPADDR;
		}
		
		else if( equali( szAuthType, "name" ) || equali( szAuthType, "nick" ) )
		{
			idtype = ADMIN_NAME;
			
			if( equali( szAuthType, "name" ) )
			{
				idtype |= ADMIN_LOOKUP;
			}
			
			else
			{
				console_print(id, "[%s] Unknown id type ^"%s^", use one of: steamid, ip, name", PLUGINNAME, szAuthType );
				
				return PLUGIN_HANDLED;
			}
		}
	}

	new szArg[ 33 ];
	
	new player = -1;
	
	read_argv( 1, szArg, charsmax( szArg ) );
	
	if( idtype & ADMIN_STEAM )
	{
		if( containi( szArg, "STEAM_0:" ) == -1 )
		{
			idtype |= ADMIN_LOOKUP;
			
			player = cmd_target( id, szArg, CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS );
		}
		
		else
		{
			new szSteamid[ 44 ];
			
			new iPlayers[ 32 ];
			
			new iNum;
			new iPlayer;
			
			get_players( iPlayers, iNum, "ch" );
			
			for( new i = 0; i < iNum; i++ )
			{
				iPlayer = iPlayers[ i ];
				
				get_user_authid( iPlayer, szSteamid, charsmax( szSteamid ) );
				
				if( !szSteamid[ 0 ] )
				{
					continue;
				}
				
				if( equal( szSteamid, szArg ) )
				{
					player = iPlayer;
					
					break;
				}
			}
			
			if( player < 1 )
			{
				idtype &= ~ADMIN_LOOKUP;
			}		
		}
	}
	
	else if( idtype & ADMIN_NAME )
	{
		player = cmd_target( id, szArg, CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS );
		
		if( player )
		{
			idtype |= ADMIN_LOOKUP;
		}
		
		else
		{
			idtype &= ~ADMIN_LOOKUP;
		}
	}
	
	else if( idtype & ADMIN_IPADDR )
	{
		new iLen = strlen( szArg );
		new iDots;
		new iChars;
		
		for( new i = 0; i < iLen; i++ )
		{
			if( szArg[ i ] == '.' )
			{
				if( !iChars || iChars > 3 )
				{
					break;
				}
				
				if( ++iDots > 3 )
				{
					break;
				}
				
				iChars = 0;
			}
			
			else
			{
				iChars++;
			}
			
			if( iDots != 3 || !iChars || iChars > 3 )
			{
				idtype |= ADMIN_LOOKUP;
				player = find_player( "dh", szArg );
			}
		}
	}
	
	if( idtype & ADMIN_LOOKUP && !player )
	{
		console_print( id, "%L", id, "CL_NOT_FOUND" );
		
		return PLUGIN_HANDLED;
	}
	
	new szFlags[ 64 ];
	new szPasswordField[ 64 ];
	new szPassword[ 64 ];
	
	read_argv( 2, szFlags, charsmax( szFlags ) );
	
	if( read_argc( ) >= 5 )
	{
		read_argv( 3, szPasswordField, charsmax( szPasswordField ) );
		read_argv (4, szPassword, charsmax( szPassword ) );
	}

	new szAuth[ 33 ];
	new szComment[ 33 ]; // name of player to pass to comment field
	
	if( idtype & ADMIN_LOOKUP )
	{
		get_user_name( player, szComment, charsmax( szComment ) );
		
		if( idtype & ADMIN_STEAM )
		{
			get_user_authid( player, szAuth, charsmax( szAuth ) );
		}
		
		else if( idtype & ADMIN_IPADDR)
		{
			get_user_ip( player, szAuth, charsmax( szAuth ) );
		}
		
		else if( idtype & ADMIN_NAME )
		{
			get_user_name( player, szAuth, charsmax( szAuth ) );
		}
	}
	
	else
	{
		copy( szAuth, charsmax( szAuth ), szArg );
	}
	
	new szType[ 16 ];
	new iLen;
	
	if( idtype & ADMIN_STEAM )
	{
		iLen += format( szType[ iLen ], charsmax( szType ) - iLen, "c" );
	}
	
	else if( idtype & ADMIN_IPADDR )
	{
		iLen += format( szType[ iLen ], charsmax( szType ) - iLen, "d" );
	}
	
	if( strlen( szPasswordField ) > 0 && strlen( szPassword ) > 0 )
	{
		iLen += format( szType[ iLen ], charsmax( szType ) - iLen, "a" );
	}
	
	else
	{
		iLen += format( szType[ iLen ], charsmax( szType ) - iLen, "e" );
	}
	
	AddAdmin( id, szAuth, szFlags, szPasswordField, szPassword, szType, szComment );
	ConCmdReload( id, ADMIN_CFG, 0 );

	if( player > 0 )
	{
		new szName[ 32 ];
		
		get_user_info( player, "name", szName, charsmax( szName ) );
		AccessUser( player, szName );
	}

	return PLUGIN_HANDLED;
}

AddAdmin( id, szAuth[ ], szAccessFlags[ ], szPasswordField[ ], szPassword[ ], szFlags[ ], szComment[ ]= "" )
{
#if defined USING_SQL
	new szError[ 128 ];
	
	new iErrno;

	new Handle: hInfo = SQL_MakeStdTuple( );
	new Handle: hSQL = SQL_Connect( hInfo, iErrno, szError, charsmax( szError ) );
	
	if( hSQL == Empty_Handle )
	{
		server_print( "[AMXX] %L", LANG_SERVER, "SQL_CANT_CON", szError );
		//backup to users.ini
#endif
		// Make sure that the users.ini file exists.

		if( !file_exists( g_szFile ) )
		{
			console_print( id, "[%s] File ^"%s^" doesn't exist.", PLUGINNAME, g_szFile );
			
			return;
		}

		// Make sure steamid isn't already in file.
		const SIZE = 63;
		
		new szTextLine[ 256 ];
		
		new iLineSteamid[ SIZE + 1 ];
		new iLinePassword[ SIZE + 1 ];
		new iLineAccessFlags[ SIZE + 1 ];
		new iLineFlags[ SIZE + 1 ];
		
		new iLine = 0;
		new iParsedParams;
		new iLen;
		
		// <name|ip|steamid> <password1> <password2> <access flags> <account flags>
		while( ( iLine = read_file( g_szFile, iLine, szTextLine, charsmax( szTextLine ), iLen ) ) )
		{
			if( iLen == 0 || equal( szTextLine, ";", 1 ) )
			{
				continue;
			}

			iParsedParams = parse( szTextLine, iLineSteamid, SIZE, iLinePassword, SIZE, iLineAccessFlags, SIZE, iLineFlags, SIZE );
			
			if( iParsedParams != 4 )
			{
				continue;	// Send warning/error?
			}
			
			if( containi( iLineFlags, szFlags) != -1 && equal( iLineSteamid, szAuth ) )
			{
				console_print( id, "[%s] %s already exists!", PLUGINNAME, szAuth );
				
				return;
			}
		}

		// If we came here, steamid doesn't exist in users.ini. Add it.
		new szLineToAdd[ 512 ];
		
		if( szComment[ 0 ] == 0 )
		{
			formatex( szLineToAdd, charsmax( szLineToAdd ), "^r^n^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^"", szAuth, szPasswordField, szPassword, szAccessFlags, szFlags );
		}
		
		else
		{
			formatex( szLineToAdd, charsmax( szLineToAdd ), "^r^n^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^" ; %s", szAuth, szPasswordField, szPassword, szAccessFlags, szFlags, szComment );
		}
		
		console_print( id, "Adding:^n%s", szLineToAdd );

		if( !write_file( g_szFile, szLineToAdd ) )
		{
			console_print( id, "[%s] Failed writing to %s!", PLUGINNAME, g_szFile );
		}
#if defined USING_SQL
	}
	
	new szTable[ 32 ];
	
	get_cvar_string( "amx_sql_table", szTable, charsmax( szTable ) );
	
	new Handle: hQuery = SQL_PrepareQuery( hSQL, "SELECT * FROM `%s` WHERE (`auth` = '%s')", szTable, szAuth );

	if( !SQL_Execute( hQuery ) )
	{
		SQL_QueryError( hQuery, iError, charsmax( iError ) );
		server_print( "[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", iError );
		console_print( id, "[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", iError );
	}
	
	else if( SQL_NumResults( hQuery ) )
	{
		console_print( id, "[%s] %s already exists!", PLUGINNAME, szAuth );
	}
	
	else
	{
		console_print( id, "Adding to database:^n^"%s^" ^"%s^" ^"%s^" ^"%s^"", szAuth, szPasswordField, szPassword, szAccessFlags, szFlags );
	
		SQL_QueryAndIgnore( hSQL, "REPLACE INTO `%s` (`auth`, `passwordfield`, `password`, `access`, `flags`) VALUES ('%s', '%s', '%s', '%s', '%s')", szTable, szAuth, szPasswordField, szPassword, szAccessFlags, szFlags );
	}
	
	SQL_FreeHandle( hQuery );
	SQL_FreeHandle( hSQL );
	SQL_FreeHandle( hInfo );
#endif
}

public DelayedLoad( )
{
	new szConfigFile[ 128 ];
	new szConfigDir[ 128 ];
	
	new szCurMap[ 64 ];
	
	new i;
	
	get_configsdir( szConfigDir, charsmax( szConfigDir ) );
	get_mapname( szCurMap, charsmax( szCurMap ) );
	
	while( szCurMap[ i ] != '_' && szCurMap[ i++ ] != '^0' )
	{
		/*do nothing*/
	}
	
	if( szCurMap[ i ] == '_' )
	{
		// this map has a prefix
		szCurMap[ i ] = '^0';
		
		formatex( szConfigFile, charsmax( szConfigFile ), "%s/maps/prefix_%s.cfg", szConfigDir, szCurMap );

		if( file_exists( szConfigFile ) )
		{
			server_cmd( "exec %s", szConfigFile );
		}
	}

	get_mapname( szCurMap, charsmax( szCurMap ) );
	formatex( szConfigFile, charsmax( szConfigFile ), "%s/maps/%s.cfg", szConfigDir, szCurMap );

	if( file_exists( szConfigFile ) )
	{
		server_cmd( "exec %s", szConfigFile );
	}
}

LoadSettings( szFileName[ ] )
{		
	new iFile = fopen( szFileName, "r" );
	
	if( iFile )
	{
		new szText[ 512 ];
		
		ArrayClear( g_aAdmins );
		
		while( !feof( iFile ) )
		{
			fgets( iFile, szText, charsmax( szText ) );
			
			trim( szText );
			
			// comment
			if( szText[ 0 ] == ';' || !szText[ 0 ] ) 
			{
				continue;
			}
			
			ArrayPushString( g_aAdmins, szText );

			g_iAdminCount++;
		}
		
		fclose( iFile );
	}

	if( g_iAdminCount == 1 )
	{
		server_print( "[AMXX] %L", LANG_SERVER, "LOADED_ADMIN" );
	}
	
	else
	{
		server_print( "[AMXX] %L", LANG_SERVER, "LOADED_ADMINS", g_iAdminCount );
	}
	
	return 1;
}

#if defined USING_SQL
public AdminSQL( )
{
	new szError[ 128 ]
	
	new szTable[ 32 ];
	
	new szType[ 12 ];
	
	new iErrno;
	
	new Handle: hInfo = SQL_MakeStdTuple( );
	new Handle: hSQL = SQL_Connect( hInfo, iErrno, szError, charsmax( szError ) );
	
	get_cvar_string( "amx_sql_table", szTable, charsmax( szTable ) );
	
	SQL_GetAffinity( szType, charsmax( szType ) );
	
	if( hSQL == Empty_Handle )
	{
		server_print( "[AMXX] %L", LANG_SERVER, "SQL_CANT_CON", szError );
		
		//backup to users.ini
		LoadSettings( g_szFile); // Load admins accounts
		
		return PLUGIN_HANDLED;
	}
	
	new Handle: hQuery;
	
	if( equali( szType, "sqlite" ) )
	{
		if( !sqlite_TableExists( hSQL, szTable ) )
		{
			SQL_QueryAndIgnore( hSQL, "CREATE TABLE %s ( auth TEXT NOT NULL DEFAULT '', passwordfield TEXT NOT NULL DEFAULT '', password TEXT NOT NULL DEFAULT '', access TEXT NOT NULL DEFAULT '', flags TEXT NOT NULL DEFAULT '' )", szTable );
		}
		
		hQuery = SQL_PrepareQuery( hSQL, "SELECT auth, passwordfield, password, access, flags FROM %s", szTable );
	}
	
	else
	{
		SQL_QueryAndIgnore( hSQL, "CREATE TABLE IF NOT EXISTS `%s` ( `auth` VARCHAR( 32 ) NOT NULL, `passwordfield` VARCHAR( 32 ) NOT NULL, `password` VARCHAR( 32 ) NOT NULL, `access` VARCHAR( 32 ) NOT NULL, `flags` VARCHAR( 32 ) NOT NULL ) COMMENT = 'AMX Mod X Admins'", szTable );
		
		hQuery = SQL_PrepareQuery( hSQL,"SELECT `auth`,`passwordfield`,`password`,`access`,`flags` FROM `%s`", szTable );
	}

	if( !SQL_Execute( hQuery ) )
	{
		SQL_QueryError( hQuery, szError, charsmax( szError ) );
		
		server_print( "[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", szError );
		
	}
	
	else if( !SQL_NumResults( hQuery ) )
	{
		server_print( "[AMXX] %L", LANG_SERVER, "NO_ADMINS" );
	}
	
	else
	{
		new szText[ 512 ];
		
		new szAuthData[ 64 ];
		new szPasswordField[ 64 ];
		new szPassword[ 64 ];
		
		new szAccess[ 32 ];
		new szFlags[ 32 ];
		
		/** do this incase people change the query order and forget to modify below */
		new iSQLAuth = SQL_FieldNameToNum( hQuery, "auth" );
		new iSQLPassField = SQL_FieldNameToNum( hQuery, "passwordfield" );
		new iSQLPass = SQL_FieldNameToNum( hQuery, "password" );
		new iSQLAccess = SQL_FieldNameToNum( hQuery, "access" );
		new iSQLFlags = SQL_FieldNameToNum( hQuery, "flags" );
		
		g_iAdminCount = 0
		
		while( SQL_MoreResults( hQuery ) )
		{
			SQL_ReadResult( hQuery, iSQLAuth, szAuthData, charsmax( szAuthData ) );
			SQL_ReadResult( hQuery, iSQLPassField, szPasswordField, charsmax( szPasswordField ) );
			SQL_ReadResult( hQuery, iSQLPass, szPassword, charsmax( szPassword ) );
			SQL_ReadResult( hQuery, iSQLAccess, szAccess, charsmax( szAccess ) );
			SQL_ReadResult( hQuery, iSQLFlags, szFlags, charsmax( szFlags) );
			
			formatex( szText, charsmax( szText ), "^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^"", szAuthData, szPassword, szPasswordField, szAccess, szFlags );
			
			ArrayPushString( g_aAdmins, szText );
			
			++AdminCount;
			
			SQL_NextRow( hQuery );
		}
	
		if( g_iAdminCount == 1 )
		{
			server_print( "[AMXX] %L", LANG_SERVER, "SQL_LOADED_ADMIN" );
		}
		else
		{
			server_print( "[AMXX] %L", LANG_SERVER, "SQL_LOADED_ADMINS", g_iAdminCount );
		}
		
		SQL_FreeHandle( hQuery );
		SQL_FreeHandle( hSQL );
		SQL_FreeHandle( hInfo );
	}
	
	return PLUGIN_HANDLED;
}
#endif

AccessUser( id, szUserName[ ] = "" )
{
	remove_user_flags( id );
	
	new szIP[ 32 ];
	new szAuthid[ 32 ];
	new szName[ 32 ];
	
	get_user_ip( id, szIP, charsmax( szIP ), 1 );
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );
	
	if( szUserName[ 0 ] )
	{
		copy( szName, charsmax( szName ), szUserName );
	}
	
	else
	{
		get_user_name( id, szName, charsmax( szName ) );
	}
	
	new iResult = GetAccess( id, szName, szAuthid, szIP );
	
	if( iResult & 1 )
	{
		client_cmd( id, "echo ^"* %L^"", id, "INV_PAS" );
	}
	
	if( iResult & 2 )
	{
		client_cmd( id, "%s", g_szLoopback );
		
		return PLUGIN_HANDLED;
	}
	
	if( iResult & 4 )
	{
		client_cmd( id, "echo ^"* %L^"", id, "PAS_ACC" );
	}
	
	if( iResult & 8 )
	{
		client_cmd( id, "echo ^"* %L^"", id, "PRIV_SET" );
	}
	
	return PLUGIN_CONTINUE;
}

GetAccess( id, szName[ ], szAuthid[ ], szIP[ ] )
{
	new szData[ 256 ];
	
	new szInfos[ eStuffs ];
	
	new iResult;
	new iIndex = -1;
	new iCount = ArraySize( g_aAdmins );
	
	g_iCaseSensitiveName[ id ] = false;
	
	for( new i = 0; i < iCount; ++i )
	{
		ArrayGetString( g_aAdmins, i, szData, charsmax( szData ) );
		GetAdminInfo( szData, szInfos );
		
		if( contain( szInfos[ KeyType ], "c" ) != -1 )
		{
			if( equal( szAuthid, szInfos[ Key ] ) )
			{
				iIndex = i;
				
				break;
			}
		}
		
		else if( contain( szInfos[ KeyType ], "d" ) != -1 )
		{
			new iLen = strlen( szInfos[ Key ] );
			
			if( szInfos[ Key ][ iLen - 1 ] == '.' )		/* check if this is not a xxx.xxx. format */
			{
				if( equal( szInfos[ Key ], szIP, iLen ) )
				{
					iIndex = i;
					
					break;
				}
			}						/* in other case an IP must just match */
			
			else if( equal( szIP, szInfos[ Key ] ) )
			{
				iIndex = i;
				
				break;
			}
		}
		
		else
		{
			if( contain( szInfos[ KeyType ], "k" ) != -1 )
			{
				if( szInfos[ KeyType ] & FLAG_TAG )
				{
					if( contain( szName, szInfos[ Key ] ) != -1 )
					{
						iIndex = i;
						
						g_iCaseSensitiveName[ id ] = true;
						
						break;
					}
				}
				
				else if( equal( szName, szInfos[ Key ] ) )
				{
					iIndex = i;
					
					g_iCaseSensitiveName[ id ] = true;
					
					break;
				}
			}
			
			else
			{
				if( contain( szInfos[ KeyType ], "b" ) != -1 )
				{
					if( containi( szName, szInfos[ Key ] ) != -1 )
					{
						iIndex = i;
						
						break;
					}
				}
				
				else if( equali( szName, szInfos[ Key ] ) )
				{
					iIndex = i;
					
					break;
				}
			}
		}
	}
	
	if( iIndex != -1 )
	{
		new iFlags = read_flags( szInfos[ Flags ] );
		
		if( contain( szInfos[ KeyType ], "e" ) != -1 )
		{
			iResult |= 8;
			
			set_user_flags( id, iFlags );
			
			log_amx( "Login: ^"%s<%d><%s><>^" became an admin (account ^"%s^") (access ^"%s^") (address ^"%s^")", szName, get_user_userid( id ), szAuthid, szInfos[ Key ], szInfos[ Flags ], szIP );
		}
		else 
		{
			new szUserPassword[ 32 ];
			
			get_user_info( id, szInfos[ PasswordField ], szUserPassword, charsmax( szUserPassword ) );

			if( equal( szUserPassword, szInfos[ Password ] ) )
			{
				iResult |= 12;
				
				set_user_flags( id, iFlags );
				
				log_amx( "Login: ^"%s<%d><%s><>^" became an admin (account ^"%s^") (access ^"%s^") (address ^"%s^")", szName, get_user_userid( id ), szAuthid, szInfos[ Key ], szInfos[ Flags ], szIP );
			} 
			
			else 
			{
				iResult |= 1;
				
				if( contain( szInfos[ KeyType ], "a" ) != -1 )
				{
					iResult |= 2;
					
					log_amx( "Login: ^"%s<%d><%s><>^" kicked due to invalid password (account ^"%s^") (address ^"%s^")", szName, get_user_userid( id ), szAuthid, szInfos[ Key ], szIP );
				}
			}
		}
	}
	
	else if( get_pcvar_float( amx_mode ) == 2.0 )
	{
		iResult |= 2;
	} 
	
	else 
	{
		new szDefAccess[ 32 ];
		
		get_pcvar_string( amx_default_access, szDefAccess, charsmax( szDefAccess ) );
		
		if( !strlen( szDefAccess ) )
		{
			copy( szDefAccess, charsmax( szDefAccess ), "z" );
		}
		
		new iDefAccess = read_flags( szDefAccess );
		
		if( iDefAccess )
		{
			iResult |= 8;
			
			set_user_flags( id, iDefAccess );
		}
	}
	
	return iResult;
}

public AckSignal( id )
{
	server_cmd( "kick #%d ^"%L^"", get_user_userid( id ), id, "NO_ENTRY" );
	
	return PLUGIN_HANDLED;
}

GetAdminInfo( szData[ ], szInfos[ eStuffs ] )
{
	parse( szData,
	szInfos[ Key ], charsmax( szInfos[ Key ] ),
	szInfos[ PasswordField ], charsmax( szInfos[ PasswordField ] ),
	szInfos[ Password ], charsmax( szInfos[ Password ] ),
	szInfos[ Flags ], charsmax( szInfos[ Flags ] ),
	szInfos[ KeyType ], charsmax( szInfos[ KeyType ] ) );
}
