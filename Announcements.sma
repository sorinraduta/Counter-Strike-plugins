#include < amxmodx >
#include < engine >
#include < fakemeta>
#pragma semicolon 1

#define MAX_ANNOUNCEMENTS	64
#define MIN_TIME		60.0
#define MAX_TIME		80.0

static const
	
	PLUGIN[ ] =		"Announcements",
	VERSION[ ] =		"1.0",
	AUTHOR[ ] =		"Rap^^";


new g_szAnnouncements[ MAX_ANNOUNCEMENTS ][ 128 ];//array

new g_iCount;
new g_iAnnouncementEntity;
new g_iMsgSayText;


public plugin_init( )
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_cvar( PLUGIN, VERSION, FCVAR_SERVER );
	
	g_iMsgSayText = get_user_msgid( "SayText" );
}

public plugin_cfg( )
{
	new szFilePath[ 64 ];
	
	get_localinfo( "amxx_configsdir", szFilePath, charsmax( szFilePath ) );
	
	format( szFilePath, charsmax( szFilePath ), "%s/announcements.ini", szFilePath );
	
	if( file_exists( szFilePath ) )
	{
		new szAnnouncement[ 128 ];
		
		new iFile = fopen( szFilePath, "rt" );
		
		if( !iFile )
		{
			return;
		}
		
		//for( new i = 0; i < MAX_ANNOUNCEMENTS && !feof( iFile ); i++ )
		while( !feof( iFile ) && g_iCount < MAX_ANNOUNCEMENTS )
		{
			fgets( iFile, szAnnouncement, charsmax( szAnnouncement ) );
			
			if( !szAnnouncement[ 0 ]
			|| szAnnouncement[ 0 ] == ';'
			|| szAnnouncement[ 0 ] == ' '
			|| szAnnouncement[ 0 ] == 10 ) 
			{
				//i--;
				
				continue;
			}
			
			SetColor( szAnnouncement, charsmax( szAnnouncement ) );
			
			copy( g_szAnnouncements[ g_iCount++ ], charsmax( g_szAnnouncements[ ] ), szAnnouncement );
		}
		
		if( g_iCount )
		{
			CreateAnnouncementEntity( );
		}
		
		fclose( iFile );	
	}
	
	else
	{
		write_file( szFilePath, ";Announcements" );
		write_file( szFilePath, ";" );
		write_file( szFilePath, ";Culori:" );
		write_file( szFilePath, "; !n - Default" );
		write_file( szFilePath, "; !t - Culoarea echipei" );
		write_file( szFilePath, "; !g - Verde" );
	}
}

public ShowAnnouncement( )
{
	new iPlayers[ 32 ];
	
	new iNum;
	new player;
	
	static iCurrent = -1;
	
	if( iCurrent == g_iCount )
	{
		iCurrent = 0;
	}
	
	else
	{
		iCurrent++;
	}
	
	get_players( iPlayers, iNum, "ch" );

	for( new i = 0; i < iNum; i++ )
	{
		player = iPlayers[ i ];
		
		message_begin( MSG_ONE, g_iMsgSayText, { 0, 0, 0 }, player );
		write_byte( player );
		write_string( g_szAnnouncements[ iCurrent ] );
		message_end( );
	}
	
	entity_set_float( g_iAnnouncementEntity, EV_FL_nextthink, get_gametime( ) + random_float( MIN_TIME, MAX_TIME ) );
	
	return PLUGIN_CONTINUE;
}

public CreateAnnouncementEntity( )
{
	static iFailCount;
	
	g_iAnnouncementEntity = create_entity( "info_target" );
	
	if( !is_valid_ent( g_iAnnouncementEntity ) )
	{
		log_amx( "[ERROR] Failed to create announcement entity (%i/10)", ++iFailCount );
		
		if( iFailCount < 10 )
		{
			set_task( 1.0, "CreateAnnouncementEntity" );
		}
		
		else
		{
			log_amx( "[ERROR] Could not create announcement entity!" );
		}
		
		return;
	}
	
	entity_set_string( g_iAnnouncementEntity, EV_SZ_classname, "Announcement_Entity" );
	entity_set_float( g_iAnnouncementEntity, EV_FL_nextthink, get_gametime( ) + random_float( MIN_TIME, MAX_TIME ) );
	
	register_think( "Announcement_Entity", "ShowAnnouncement" );
}

stock SetColor( szString[ ], iLen )
{
	if( contain( szString, "!t" ) != -1
	|| contain( szString, "!g" ) != -1
	|| contain( szString, "!n" ) != -1 )
	{
		replace_all( szString, iLen, "!n", "^x01" );
		replace_all( szString, iLen, "!t", "^x03" );
		replace_all( szString, iLen, "!g", "^x04" );
		
		format( szString, iLen, "%s", szString );
	}
}
