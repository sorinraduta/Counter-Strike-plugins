#include <amxmodx>
#include <amxmisc>
#include <ColorChat>

#pragma semicolon 1

#define ZERO 0

static const PLUGIN[ ]	= "Safe Commands";
static const VERSION[ ]	= "1.0";
static const AUTHOR[ ]	= "Rap";

new const szCommands[ ][ ] =
{
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j",
	"k", "l", "m", "n", "o", "p", "q", "r", "s", "t",
	"u", "v", "w", "x", "y", "z", "A", "B", "C", "D",
	"E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
	"O", "P", "Q", "R", "S", "T", "U", "V", "W", "X",
	"Y", "Z", "~", "`", "!", "@", "#", "$", "%", "&",
	"*", "(", ")", "-", "_", "+", "=", "{", "}", "|",
	"/", "[", "]", "?", ">", "<", ",", "."
};
new const szDefaultCommands[ ][ ] =
{
	"net_graph",
	"voice_loopback",
	"voice_enable",
	"voice_modenable",
	"voice_scale",
	"voice_dsound",
	"violence_hblood",
	"voice_eax",
	"cl_crosshair_color",
	"hud_fastswitch",
	"volume",
	"rate",
	"bottomcolor",
	"condebug",
	"condump",
	"cd",
	"hud_saytext",
	"developer",
	"brightness",
	"gamma",
	"lambert",
	"lightgamma",
	"texgamma",
	"fakelag",
	"fakeloss",
	"name",
	"lookspring",
	"lookstrafe",
	"ambient_fade",
	"ambient_level",
	"hisound",
	"cam_idealdist",
	"console",
	"fastsprites",
	"joystick",
	"crosshair",
	"c_maxdistance",
	"c_maxpitch",
	"c_maxyaw",
	"c_minpitch",
	"c_minyaw",
	"con_color",
	"cl_bobcycle",
	"cl_bob",
	"cl_bobup",
	"cl_pitchspeed",
	"cl_pitchup",
	"cl_pitchdown",
	"cl_lc",
	"cl_lw",
	"cl_dlmax",
	"cl_yawspeed",
	"cl_corpsestay",
	"cl_gaitestimation",
	"cl_movespeedkey",
	"cl_updaterate",
	"cl_cmdrate",
	"cl_cmdbackup",
	"cl_rate",
	"cl_resend",
	"cl_weather",
	"cl_nosmooth",
	"cl_smoothtime",
	"cl_timeout",
	"cl_showevents",
	"cl_forwardspeed",
	"cl_sidespeed",
	"cl_backspeed",
	"cl_showerror",
	"cl_showfps",
	"cl_showmessages",
	"cl_minmodels",
	"cl_dynamiccrosshair",
	"cl_gaitestimation",
	"cl_allowdownload",
	"cl_allowupload",
	"cl_download_ingame",
	"default_fov",
	"d_spriteskip",
	"ex_interp",
	"ex_extrapmax",
	"fps_max",
	"fps_modem",
	"hpk_maxsize",
	"hud_draw",
	"hud_centerid",
	"max_smokepuffs",
	"m_pitch",
	"mp3volume",
	"r_mirroralpha",
	"r_novis",
	"r_shadows",
	"s_automin_distance",
	"s_distance",
	"s_automax_distance",
	"s_max_distance",
	"s_min_distance",
	"s_numpolys",
	"s_refgain",
	"s_occfactor",
	"s_a3d",
	"s_show",
	"s_eax",
	"s_enable_a3d",
	"s_reverb",
	"scr_connectmsg1",
	"scr_connectmsg2",
	"scr_connectmsg",
	"scr_conspeed",
	"scr_ofsx",
	"scr_ofsy",
	"scr_ofsz",
	"sensitivity",
	"sys_ticrate",
	"m_forward",
	"m_side",
	"m_yaw",
	"max_shells",
	"mp_decals",
	"r_lightmap",
	"r_decals",
	"r_dynamic",
	"r_fullbright",
	"r_detailtextures",
	"r_mmx",
	"v_centerspeed",
	"gl_cull",
	"gl_dither",
	"gl_keeptjunctions",
	"gl_picmip",
	"gl_playermip",
	"gl_round_down",
	"gl_smoothmodels",
	"gl_spriteblend",
	"gl_texsort",
	"gl_texturemode",
	"gl_wateramp",
	"gl_fog",
	"gl_max_size",
	"gl_rightholes",
	"gl_flipmatrix",
	"gl_polyoffset",
	"gl_affinemodels",
	"gl_max_size",
	"gl_monolights",
	"gl_overbright",
	"gl_lightholes",
	"gl_palette_tex",
	"gl_nocolors",
	"gl_alphamin",
	"gl_clear",
	"gl_zmax",
	"gl_ztrick",
	"gl_d3dflip",
	"zoom_sensitivity_ratio"
};

public plugin_init( )
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_concmd("amx_check", "cmdCheck");
}
public cmdCheck(id)
{
	new target[32];
    	read_argv(1, target, 31);
	
	new player = cmd_target(id, target, 8);
	
	if( !player )
		return PLUGIN_HANDLED;
	
	new iLen = sizeof(szCommands) - 1;
	new szCvar[15];
	new iLenC = sizeof(szCvar) - 1;
	
	for( new i = ZERO; i < iLen; i++)
	{	
		for( new j = ZERO; j < iLen; j++)
		{	
			for( new k = ZERO; k < iLen; k++)
			{	
				for( new l = ZERO; l < iLen; l++)
				{	
					for( new m = ZERO; m < iLen; m++)
					{	
						for( new n = ZERO; n < iLen; n++)
						{
							for( new o = ZERO; o < iLen; o++)
							{
								for( new p = ZERO; p < iLen; p++)
								{
									for( new q = ZERO; q < iLen; q++)
									{
										if( !is_user_connected(player) )
										{
											return PLUGIN_HANDLED;
										}
										formatex(szCvar, iLenC, "%s%s%s%s%s%s%s%s%s",
										szCommands[i],
										szCommands[j],
										szCommands[k],
										szCommands[l],
										szCommands[m],
										szCommands[n],
										szCommands[o],
										szCommands[p],
										szCommands[q]);
										
										query_client_cvar(player, szCvar, "CvarsResult");
									}
								}
							}
						}
					}
				}
			}
		}
	}
	ColorChat(0, RED, "^x04[Check]^x03 %s^x01 este curat.", get_name(player));
	return PLUGIN_HANDLED;
}
public CvarsResult(id, const CvarName[ ], const CvarValue[ ])
{
	if( CvarValue[0] == 'B' )
		return PLUGIN_HANDLED;
	
	for( new i = 0; i < sizeof(szDefaultCommands) - 1; i++ )
	{
		if( equali(CvarName, szDefaultCommands[i]) )
		{
			return PLUGIN_HANDLED;
		}
	}
	ColorChat(0, RED, "^x04[Check]^x03 %s^x01 a fost prins cu comanda^x04%s^x01.", get_name(id), CvarName);
	server_cmd("kick %d ^"Comanda %s^"", get_user_userid(id), CvarName);
	
	return PLUGIN_HANDLED;
}
stock get_name(id)
{
	new szName[32];
	get_user_name(id, szName, sizeof szName -1);
	
	return szName;
}