#include < amxmodx >
#include < amxmisc >
#include < ColorChat >

#pragma semicolon 1


static const
	
	PLUGIN[ ] =	"Merry_Xmas",
	VERSION[ ] =	"1.0",
	AUTHOR[ ] =	"Rap^^",
	
	TAG[ ] =	"[TAG]",
	MIN_TIME =	1;


new bool: CanSend[ 33 ];
new szFilePath[ 64 ];


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );
	
	register_clcmd( "say /scrisoare", "CmdScrisoare" );
	
	get_configsdir( szFilePath, charsmax( szFilePath ) );
	
	format( szFilePath, charsmax( szFilePath ), "%s/scrisori_primite.ini", szFilePath );
	
	if( !file_exists( szFilePath ) )
	{
		write_file( szFilePath, ";Aici se afla toti copii care i-au scris mosului" );
		write_file( szFilePath, "" );
	}
}

public client_connect( id )
{
	CanSend[ id ] = true;
}
public CmdScrisoare( id )
{
	if( get_user_time( id, 1 ) < ( 60 * MIN_TIME ) )
	{
		ColorChat( id, GREEN, "%s^x01 Trebuie sa stai^x04 %d^x01 minut%s pe server ca sa iti trimitem scrisoarea.", TAG, MIN_TIME, MIN_TIME == 1 ? "":"e" );
		
		return PLUGIN_HANDLED;
	}
	
	if( !CanSend[ id ] )
	{
		ColorChat( id, RED, "^x04%s^x01 Nu ii poti trimite decat o scrisoare^x03 Mosului^x01.", TAG );
				
		return PLUGIN_HANDLED;
	}
	
	new szName[ 32 ];
	
	get_user_name( id, szName, charsmax( szName ) );
	
	if( file_exists( szFilePath ) )
	{
		new szData[ 128 ];
		
		new iFile = fopen( szFilePath, "rt" );
		
		if( !iFile )
		{
			return PLUGIN_HANDLED;
		}
		
		while( !feof( iFile ) )
		{
			fgets( iFile, szData, charsmax( szData ) );
			
			trim( szData );
			
			if( equal( szData, szName, strlen( szName ) ) )
			{
				ColorChat( id, RED, "^x04%s^x01 Nu ii poti trimite decat o scrisoare^x03 Mosului^x01.", TAG );
				
				return PLUGIN_HANDLED;
			}
		}
	}
	
	write_file( szFilePath, szName );
	
	CanSend[ id ] = false;
	
	ColorChat( id, RED, "^x04%s^x01 Scrisoarea ta catre^x03 Mos Craciun^x01 a fost trimisa", TAG );
	ColorChat( id, RED, "^x04%s^x01 Maine vei afla daca ai fost cumite.", TAG );
	
	return PLUGIN_HANDLED;
}