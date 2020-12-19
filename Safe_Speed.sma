#include < amxmodx >
#include < fakemeta >
#include < ColorChat >

#pragma semicolon 1


static const

	PLUGIN[ ] =	"Safe_Speed",
	VERSION[ ] =	"1.1",
	AUTHOR[ ] =	"coderiz", // Rap^ update

	TAG[ ] =	"[D/C]";


new Float: g_flWarnTime[ 33 ];

new g_iWarnings[ 33 ];
new g_iBadFrame[ 33 ];


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, VERSION, FCVAR_SERVER );

	register_forward( FM_ClientPutInServer, "FwdClientPutInServer" );
	register_forward( FM_CmdStart, "FwdCmdStart" );
}

public FwdClientPutInServer( id )
{
	g_iWarnings[ id ] = 0;
}

public FwdmdStart( id, UC_Handle, iSeed )
{
	if( pev( id, pev_movetype)  != MOVETYPE_WALK )
	{
		return;
	}

	new Float: flForward;
	new Float: flSide;
	new Float: flVelocity[ 3 ];
	new iButtons;

	get_uc( UC_Handle, UC_ForwardMove, flForward );
	get_uc( UC_Handle, UC_SideMove, flSide );

	iButtons = get_uc( UC_Handle, UC_Buttons );

	if( ( iButtons & IN_LEFT) || ( iButtons & IN_RIGHT ) )
	{
		pev( id, pev_velocity, flVelocity );

		flVelocity[ 0 ] = flVelocity[ 0 ] * 0.8;
		flVelocity[ 1 ] = flVelocity[ 1 ] * 0.8;

		set_pev( id, pev_velocity, flVelocity );
	}

	if( flForward == 0.0 || flSide == 0.0)
	{
		g_iBadFrame[ id ] = 0;

		return;
	}

	if( floatabs( flForward ) != floatabs( flSide ) )
	{
		g_iBadFrame[ id ]++;

		if( g_iBadFrame[ id ] > 5 )
		{
			BadSpeedCvar( id );
		}
	}

	else
	{
		g_iWarnings[ id ] = 0;
		g_iBadFrame[ id ] = 0;
	}
}

public BadSpeedCvar( id )
{
	new Float: flVelocity[ 3 ];

	pev( id, pev_velocity, flVelocity );

	if( vector_length( flVelocity ) < 80.0 )
	{
		return;
	}

	flVelocity[ 0 ] = flVelocity[ 0 ] * 0.9;
	flVelocity[ 1 ] = flVelocity[ 1 ] * 0.9;

	set_pev( id, pev_velocity, flVelocity );

	if( get_gametime( ) - g_flWarnTime[ id ] < 5)
	{
		return;
	}

	g_flWarnTime[ id ] = get_gametime( );

	static szSounds[ 3 ][ ] =
	{
		"illegal command _comma detected",
		"fvox/warning",
		"you use illegal _comma command"
	};



	if( ++g_iWarnings[ id ] == 3 )
	{
		new szName[ 32 ];

		get_user_name( id, szName, charsmax( szName ) );

		server_cmd( "kick #%d ^"Joc necurat^"", get_user_userid( id ) );

		client_cmd( 0, "spk ^"%s^"", szSounds[ random( 3 ) ] );

		ColorChat( 0, GREEN, "%s^x03 %s^x01 a primit kick deoarece folosea CVar-uri ilegale.", TAG, szName );
	}

	else
	{
		client_cmd( id, "spk ^"%s^"", szSounds[ random( 3 ) ] );

		ColorChat( 0, GREEN, "%s^x01 CVar-uri ilegale detectate. Avertizmentul ^x04%d^x01/3.", TAG, ++g_iWarnings[ id ] );
	}

	SetUserLegalSettings( id );
}

stock SetUserLegalSettings( id )
{
	client_cmd( id, "developer 0" );
	client_cmd( id, "fps_max 101" );
	client_cmd( id, "fps_override 0.0" );
	client_cmd( id, "cl_sidespeed 400" );
	client_cmd( id, "cl_forwardspeed 400" );
	client_cmd( id, "cl_backspeed 400" );
	client_cmd( id, "cl_pitchspeed 225" );
	client_cmd( id, "cl_anglespeedkey 0.67" );
	client_cmd( id, "cl_movespeedkey 0.67" );
	client_cmd( id, "cl_pitchdown 89" );
	client_cmd( id, "cl_pitchup 89" );
	client_cmd( id, "cl_upspeed 320" );
	client_cmd( id, "cl_yawspeed 210" );
	client_cmd( id, "m_yaw 0.022" );
	client_cmd( id, "m_pitch 0.022" );
	client_cmd( id, "ex_interp 0.01" );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
