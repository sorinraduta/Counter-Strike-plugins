#include <amxmodx>
#include <fakemeta>
#include <engine>

#define PLUGIN	"Swarm Defealer"
#define VERSION	"1.0"
#define AUTHOR	"Rap^^"

new const g_szClassName[ ] = "DefealerSwarm";
new g_iSprite;

new UserInSwarm[33];


public plugin_init( )
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say /swarm", "cmdSwarm");

	register_touch(g_szClassName,		"worldspawn", "FwdTouchEntity");
	register_think(g_szClassName,		"FwdThinkEntity");
	register_forward(FM_PlayerPostThink,	"FwdPlayerPostThink");
}
public plugin_precache( )
{
	g_iSprite = precache_model("sprites/Swarm.spr");
}
public cmdSwarm(id)
{
	new Float: flOrigin[3];

	pev(id, pev_origin, flOrigin);

	new iEntity = create_entity("info_target");

	if( iEntity > 0 )
	{
		entity_set_string(iEntity, EV_SZ_classname, g_szClassName);

		entity_set_origin(iEntity, flOrigin);

		entity_set_int(iEntity, EV_INT_movetype, MOVETYPE_TOSS);
		entity_set_int(iEntity, EV_INT_solid, SOLID_BBOX);

		entity_set_float(iEntity, EV_FL_nextthink, get_gametime( ) + 21.5);
		entity_set_float(iEntity, EV_FL_gravity, 0.5);
		entity_set_float(iEntity, EV_FL_friction, 0.8);

		dllfunc(DLLFunc_Spawn, iEntity);

		new Float: fMins[3], Float: fMaxs[3];
		for( new i; i < 3; i++ )
		{
			fMins[i] = -175.0;
			fMaxs[i] = 175.0;
		}
		engfunc(EngFunc_SetSize, iEntity, fMins, fMaxs);

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_FIREFIELD);
		engfunc(EngFunc_WriteCoord, flOrigin[0]);
		engfunc(EngFunc_WriteCoord, flOrigin[1]);
		engfunc(EngFunc_WriteCoord, flOrigin[2] + 50);
		write_short(120); //100 150
		write_short(g_iSprite);
		write_byte(150); //100 10
		write_byte(TEFIRE_FLAG_ALPHA);
		write_byte(1000);
		message_end( );
	}
}
public FwdPlayerPostThink(id)
{
	if( UserInSwarm[id] )
		UserInSwarm[id] = false;
}
public FwdTouchEntity(iEntity, id)
{
	if( !is_valid_ent(iEntity) )
		return PLUGIN_CONTINUE;

	UserInSwarm[id] = true;

	return PLUGIN_CONTINUE;
}
public FwdThinkEntity(iEntity)
{
	if( !is_valid_ent(iEntity) )
		return PLUGIN_CONTINUE;

	remove_entity(iEntity);

	return PLUGIN_CONTINUE;
}
