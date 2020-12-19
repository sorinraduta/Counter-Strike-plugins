#include < amxmodx >
#include < fakemeta >

#pragma semicolon 1


static const

	PLUGIN[ ]	= "Spec model bug fix",
	VERSION[ ]	= "0.01",
	AUTHOR[ ]	= "Rap^^";


new const g_szModels[ ][ ] =
{
	"models/player/arctic/arctic.mdl",
	"models/player/gign/gign.mdl",
	"models/player/gsg9/gsg9.mdl",
	"models/player/guerilla/guerilla.mdl",
	"models/player/leet/leet.mdl",
	"models/player/sas/sas.mdl",
	"models/player/terror/terror.mdl",
	"models/player/urban/urban.mdl",
	"models/player/vip/vip.mdl"
};


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( PLUGIN, AUTHOR, FCVAR_SERVER );
	
	register_forward( FM_SetModel, "SetModel", 0 );
}

public SetModel( iEntity, szModel[ ] )
{
	for( new i = 0; i < sizeof g_szModels; i++ )
	{
		if( equal( szModel, g_szModels[ i ] ) )
		{
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}