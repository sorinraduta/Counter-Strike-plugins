#include < amxmodx >
#include < fakemeta >
#include < ColorChat >

#pragma semicolon 1


static const
	
	PLUGIN[ ] =	"Perfect_Bhop",
	VERSION[ ] =	"1.0",
	AUTHOR[ ] =	"Askhanar";	//  Little edit by Rap^


new g_iPerfectBhopCount[ 33 ];
new g_iBhopFrames[ 33 ];
new g_iUserFlags[ 33 ];


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, VERSION, FCVAR_SERVER );
	
	register_forward( FM_PlayerPreThink, "FwdPlayerPreThink" );
}

public FwdPlayerPreThink( id )
{
	if( is_user_alive( id ) )
	{
		new iFlags = pev( id, pev_flags );
		new iMoveType = pev( id, pev_movetype );
		
		if( iFlags  & FL_ONGROUND )
		{	
			if( g_iBhopFrames[ id ] < 99 )
			{
				g_iBhopFrames[ id ]++;
			}
		}
		
		if( iMoveType == MOVETYPE_FLY )
		{
			CheckPerfectBhops( id );
			
			g_iBhopFrames[ id ] = 0;
			g_iPerfectBhopCount[ id ] = 0;
		}
		
		if( ( g_iUserFlags[ id ] & FL_ONGROUND ) && !( iFlags & FL_ONGROUND ) )
		{
			if( g_iBhopFrames[ id ] == 1 )
			{
				g_iPerfectBhopCount[ id ]++;
				
				CheckPerfectBhops( id );
			}
			
			else
			{
				CheckPerfectBhops( id );
				
				g_iPerfectBhopCount[ id ] = 0;
			}
			
			g_iBhopFrames[ id ] = 0;
		}
		
		if( g_iUserFlags[ id ] & FL_ONGROUND  &&  iFlags & FL_ONGROUND )
		{
			CheckPerfectBhops( id );
			
			g_iPerfectBhopCount[ id ] = 0;
		}
		
		g_iUserFlags[ id ] = iFlags;
	}
}

public CheckPerfectBhops( id )
{
	if( g_iPerfectBhopCount[ id ] >= 15 )
	{
		new iPlayers[ 32 ], iNum, player, szName[ 32 ];
		
		get_players( iPlayers, iNum, "ch" );
		get_user_name( id, szName, charsmax( szName ) );
		
		for( new i = 0; i < iNum; i++ )
		{
			player = iPlayers[ i ];
			
			if( !( get_user_flags( player ) & read_flags( "z" ) ) )
			{
				ColorChat( id, RED, "^x04[D/C]^x03 %s^x01 a facut^x03 %i^x01 bhop-uri perfecte.", szName, g_iPerfectBhopCount[ id ] );		
			}
		}
	}
}
