#include < amxmodx >
#include < amxmisc >
#include < cstrike >
#include < ColorChat >

#pragma semicolon 1

#define TASK_REFRESH 11234

static const

	PLUGIN[ ]	= "Admin_Chat",
	VERSION[ ]	= "1.0",
	AUTHOR[ ]	= "Rap^^",
	TAG[ ]		= "[D/C]";


new bool: g_bAnnounced;


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );
	
	register_clcmd( "say", "ClCmdSay", ADMIN_CHAT, "@<mesaj> - afiseaza un anunt in HUD" );
	register_clcmd( "say_team", "ClCmdSayTeam", ADMIN_ALL, "@<mesaj> - raporteaza un jucator/comunica cu ceilalti admini" );
	
	register_concmd( "amx_say", "ConCmdAmxSay", ADMIN_CHAT, "<mesaj> - afiseaza un anunt in chat" );
}

public ClCmdSay( id )
{
	if( !access( id, ADMIN_CHAT ) )
	{
		return PLUGIN_CONTINUE;
	}
	
	new szMessage[ 192 ];
	
	read_argv( 1, szMessage, charsmax( szMessage ) );
	
	if( szMessage[ 0 ] != '@' )
	{
		return PLUGIN_CONTINUE;
	}
	
	if( g_bAnnounced )
	{
		ColorChat( id, GREEN, "%s^x01 Un anunt este deja afisat.", TAG );
		
		return PLUGIN_HANDLED;
	}
	
	read_args( szMessage, charsmax( szMessage ) );
	
	remove_quotes( szMessage );

	new szName[ 32 ];
	new szAuthid[ 32 ];
	
	new iUserid;
	
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );
	
	get_user_name( id, szName, charsmax( szName ) );
	
	iUserid = get_user_userid( id );
	
	log_amx( "Anunt HUD: ^"%s <%d><%s><>^" - ^"%s^"", szName, iUserid, szAuthid, szMessage[ 1 ] );
	log_message( "Anunt HUD: ^"%s <%d><%s><>^" - ^"%s^"", szName, iUserid, szAuthid, szMessage[ 1 ] );
	
	set_hudmessage( 150, 10, 20, -1.0, 0.4, 0, 6.0, 6.0, 0.5, 0.15, -1 );
	show_hudmessage( 0, "Anunt %s:^n%s", szName, szMessage[ 1 ] );
	
	set_task( 6.0, "TaskRefreshAnnounce", TASK_REFRESH );
	
	g_bAnnounced = true;

	return PLUGIN_HANDLED;
}

public ClCmdSayTeam( id )
{
	new szMessage[ 192 ];
	
	read_argv( 1, szMessage, charsmax( szMessage ) );
	
	if( szMessage[ 0 ] != '@' )
	{
		return PLUGIN_CONTINUE;
	}
	
	new szName[ 32 ];
	new iPlayers[ 32 ];
	
	new iNum;
	new player;
	
	read_args( szMessage, charsmax( szMessage ) );
	
	remove_quotes( szMessage );
	
	replace( szMessage, charsmax( szMessage ), "@", "" );
	
	get_user_name( id, szName, charsmax( szName ) );
	
	get_players( iPlayers, iNum, "ch" );
	
	if( is_user_admin( id ) )
	{
		new szAuthid[ 32 ];
		
		new iUserid;
		
		get_user_authid( id, szAuthid, charsmax( szAuthid ) );
		
		iUserid = get_user_userid( id );
		
		log_amx( "Admin chat: ^"%s <%d><%s><>^" - ^"%s^"", szName, iUserid, szAuthid, szMessage );
		log_message( "Admin chat: ^"%s <%d><%s><>^" - ^"%s^"", szName, iUserid, szAuthid, szMessage );
		
		for( new i = 0; i < iNum; i++ )
		{
			player = iPlayers[ i ];
			
			if( get_user_flags( player ) & ADMIN_CHAT )
			{
				ColorChat( player, GetUserColor( id ), "^x04(ADMIN CHAT)^x03 %s^x01 :  %s", szName, szMessage );
			}
		}
	}
	
	else
	{
		new szReported[ 32 ];
		new szReason[ 32 ];
		
		strbreak( szMessage, szReported, charsmax( szReported ), szReason, charsmax( szReason ) );
		
		new iReported = cmd_target( id, szReported, 8 );
		
		if( !iReported )
		{
			ColorChat( id, GREEN, "%s^x01 Jucatorul nu este conectat.", TAG );
			
			return PLUGIN_HANDLED;
		}
		
		if( id == iReported )
		{
			ColorChat( id, GREEN, "%s^x01 Nu te poti raporta pe tine.", TAG );
			
			return PLUGIN_HANDLED;
		}
		
		if( is_user_admin( iReported ) )
		{
			ColorChat( id, GREEN, "%s^x01 Jucatorul raportat este admin. Te rugam sa il reclami pe forum:^x04 forum.disconnect.ro^x01.", TAG );
			
			return PLUGIN_HANDLED;
		}
		
		if( equal( szReason, "" ) )
		{
			ColorChat( id, GREEN, "%s^x01 Pentru a raporta trebuie sa specifici si un motiv.", TAG );
			
			return PLUGIN_HANDLED;
		}
		
		new bool: bSended = false;
		
		get_user_name( iReported, szReported, charsmax( szReported ) );
		
		for( new i = 0; i < iNum; ++i )
		{
			player = iPlayers[ i ];
			
			if( get_user_flags( player ) & ADMIN_CHAT )
			{
				ColorChat( player, GREEN, "%s^x03 %s^x01 a fost raportat de catre^x03 %s^x01. Motiv:^x03 %s^x01.", TAG, szReported, szName, szReason );
				
				bSended = true;
			}
		}
		
		if( bSended )
		{
			ColorChat( id, GREEN, "%s^x01 Raportul tau a fost trimis.", TAG );
		}
		
		else
		{
			ColorChat( id, GREEN, "%s^x01 Nu se afla niciun admin pe server pentru a putea trimite un raport.", TAG );
		}
	}
	
	return PLUGIN_HANDLED;
}

public ConCmdAmxSay( id, iLevel, iCid )
{
	if( !cmd_access( id, iLevel, iCid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}
	
	new szMessage[ 192 ];
	
	new szName[ 32 ];
	new szAuthid[ 32 ];
	
	new iUserid;
	
	read_args( szMessage, charsmax( szMessage ) );
	
	remove_quotes( szMessage );
	
	get_user_authid( id, szAuthid, charsmax( szAuthid ) );
	
	get_user_name( id, szName, charsmax( szName ) );
	
	iUserid = get_user_userid( id );
	
	ColorChat( 0, GetUserColor( id ), "^x04(Anunt)^x03 %s^x01 :  %s", szName, szMessage );
	console_print( id, "(Anunt) %s :  %s", szName, szMessage );
	
	log_amx( "Anunt chat: ^"%s <%d><%s><>^" - ^"%s^"", szName, iUserid, szAuthid, szMessage );
	log_message( "Anunt chat: ^"%s <%d><%s><>^" - ^"%s^"", szName, iUserid, szAuthid, szMessage );
	
	return PLUGIN_HANDLED;
}

public TaskRefreshAnnounce( )
{
	g_bAnnounced = false;
}

stock Color: GetUserColor( id )
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
		
		case CS_TEAM_SPECTATOR:
		{
			return GREY;
		}
	}
	
	return NORMAL;
}
