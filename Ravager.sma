#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>

#pragma semicolon 1

static const PLUGIN[ ]	= "Ravenger Class";
static const VERSION[ ]	= "1.0";
static const AUTHOR[ ]	= "Rap^^";

new RavengerJump[33];

public plugin_init( )
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("megajump", "cmdMegaJump");

	register_forward(FM_PlayerPreThink, "FwdPlayerPreThink");
	RegisterHam(Ham_TakeDamage, "player", "HamTakeDamage");
}
public client_putinserver(id)
{
	RavengerJump[id] = 0;
}
public cmdMegaJump(id)
{
	new Float: fVelocity[3];

	entity_get_vector(id, EV_VEC_velocity, fVelocity);
	fVelocity[2] = 450.0;
	entity_set_vector(id, EV_VEC_velocity, fVelocity);

	set_task(0.1, "taskMJump", id);

	return PLUGIN_HANDLED;
}
public taskMJump(id)
{
	RavengerJump[id] = 2;
}
public FwdPlayerPreThink(id)
{
	if( RavengerJump[id] )
	{
		if( (get_entity_flags(id) & FL_ONGROUND) )
		{
			if( RavengerJump[id] == 2 )
			{
				RavengerJump[id] = 0;
				set_pev(id, pev_gravity, 1.0);

				return PLUGIN_CONTINUE;
			}
			set_pev(id, pev_gravity, 1.0);
			RavengerJump[id] = 0;

			return PLUGIN_CONTINUE;
		}
		RavengerJump[id] = 1;
		new Float: fVelocity[3];

		entity_get_vector(id, EV_VEC_velocity, fVelocity);

		if( fVelocity[2] < 0 )
			set_pev(id, pev_gravity, 3.0);

	}
	return PLUGIN_CONTINUE;
}
public HamTakeDamage(id)
{
	if( RavengerJump[id] )
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
