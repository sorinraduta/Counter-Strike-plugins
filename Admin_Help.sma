#include < amxmodx >

#pragma semicolon 1

#define HELPAMOUNT 10	// Numarul comenzilor pe pagina


static const

	PLUGIN[ ]	= "Admin_Help",
	AUTHOR[ ]	= "AMXX Dev Team"; // Rap^ update


public plugin_init( )
{
	register_plugin( PLUGIN, AMXX_VERSION_STR, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );

	register_concmd( "amx_help", "ConCmdHelp", 0, "<pagini> [numarul primei comenzi] - afiseaza informatii" );

	register_dictionary( "adminhelp.txt" );
}

public ConCmdHelp( id, iLevel, iCid )
{
	new szArg1[ 8 ];

	new iHelpAmount = HELPAMOUNT;
	new iFlags = get_user_flags( id );
	new iStart = read_argv( 1, szArg1, charsmax( szArg1 ) ) ? str_to_num( szArg1 ) : 1;

	if( iFlags > 0 && ( iFlags & ~ADMIN_USER ) )
	{
		iFlags |= ADMIN_ADMIN;
	}

	if( id == 0 && read_argc( ) == 3 )
	{
		iHelpAmount = read_argv( 2, szArg1, charsmax( szArg1 ) ) ? str_to_num( szArg1 ) : HELPAMOUNT;
	}

	new iClCmdsNum = get_concmdsnum( iFlags, id );

	clamp( iStart, 0, iClCmdsNum - 1 );

	console_print( id, "^n----- %L -----", id, "HELP_COMS" );

	new szInfo[ 128 ];

	new szCmd[ 32 ];

	new eFlags;
	new iEnd = iStart + iHelpAmount;

	if( iEnd > iClCmdsNum )
	{
		iEnd = iClCmdsNum;
	}

	for( new i = iStart; i < iEnd; i++ )
	{
		get_concmd( i, szCmd, charsmax( szCmd ), eFlags, szInfo, charsmax( szInfo ), iFlags, id );

		console_print( id, "%3d: %s %s", i, szCmd, szInfo );
	}

	console_print( id, "----- %L -----", id, "HELP_ENTRIES", iStart + 1, iEnd, iClCmdsNum );

	if( iEnd < iClCmdsNum )
	{
		console_print( id, "----- %L -----", id, "HELP_USE_MORE", iEnd + 1 );
	}

	else
	{
		console_print( id, "----- %L -----", id, "HELP_USE_BEGIN" );
	}

	return PLUGIN_HANDLED;
}
