/* Sublime AMXX Editor v4.2 */

#include <amxmodx>
#include <reapi>
#include <hamsandwich>

#define PLUGIN_NAME  	 "Weapon Reload Anim Fix"
#define PLUGIN_VERSION	 "v1.0 (8-20-20)"
#define PLUGIN_AUTHOR 	 "FEDERICOMB"

// #define CLIENT_COMMAND_TEST

const WEAPONS_SILENT_BIT_SUM = (1 << _:WEAPON_USP) | (1 << _:WEAPON_M4A1);

new const DEFAULT_MAXCLIP[] = {-1, 13, -1, 10, 1, 7, 1, 30, 30, 1, 30, 20, 25, 30, 35, 25, 12, 20, 10, 30, 100, 8, 30, 30, 20, 2, 7, 30, 30, -1, 50};

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	for(new WeaponIdType:iWeapon = WEAPON_P228, szWeapon[32]; iWeapon <= WEAPON_P90; ++iWeapon)
	{
		if(get_weaponname(_:iWeapon, szWeapon, charsmax(szWeapon)))
		{
			if((iWeapon == WEAPON_GLOCK) || (iWeapon == WEAPON_HEGRENADE) || (iWeapon == WEAPON_C4) || (iWeapon == WEAPON_SMOKEGRENADE) || (iWeapon == WEAPON_FLASHBANG) || (iWeapon == WEAPON_KNIFE))
			{
				continue;
			}

			if((iWeapon == WEAPON_XM1014) || (iWeapon == WEAPON_M3))
			{
				RegisterHam(Ham_Item_PostFrame, szWeapon, "OnHam__Shotgun_PostFrame", 0);
				RegisterHam(Ham_Weapon_WeaponIdle, szWeapon, "OnHam__Shotgun_WeaponIdle", 0);
			}
			else
			{
				RegisterHam(Ham_Item_PostFrame, szWeapon, "OnHam__Item_PostFrame", 0);
			}
		}
	}

	#if defined CLIENT_COMMAND_TEST
		register_clcmd("say /test", "OnClientCommand__Test");
	#endif
}

#if defined CLIENT_COMMAND_TEST
	public OnClientCommand__Test(const client)
	{
		new iWeaponEnt;
		new iRandMaxClip;
		new szWeaponName[32];
		new WeaponIdType:iRandWeap;

		do
		{
			iRandWeap = WeaponIdType:random_num(_:WEAPON_P228, _:WEAPON_P90);
		}
		while((iRandWeap == WEAPON_GLOCK) || (iRandWeap == WEAPON_HEGRENADE) || (iRandWeap == WEAPON_C4) || (iRandWeap == WEAPON_SMOKEGRENADE) || (iRandWeap == WEAPON_FLASHBANG) || (iRandWeap == WEAPON_KNIFE));

		do
		{
			iRandMaxClip = random(120) + 1;
		}
		while(iRandMaxClip == DEFAULT_MAXCLIP[_:iRandWeap]);

		get_weaponname(_:iRandWeap, szWeaponName, charsmax(szWeaponName));

		rg_remove_item(client, szWeaponName);
		iWeaponEnt = rg_give_item(client, szWeaponName);

		rg_set_iteminfo(iWeaponEnt, ItemInfo_iMaxClip, iRandMaxClip);

		rg_set_user_ammo(client, iRandWeap, iRandMaxClip);
		rg_set_user_bpammo(client, iRandWeap, 200);
	}
#endif

public OnHam__Shotgun_PostFrame(const weapon)
{
	static WeaponIdType:iWeaponId;
	static iWeaponMaxClip;

	iWeaponId = WeaponIdType:get_member(weapon, m_iId);
	iWeaponMaxClip = rg_get_iteminfo(weapon, ItemInfo_iMaxClip);

	if(iWeaponMaxClip != DEFAULT_MAXCLIP[_:iWeaponId])
	{
		static id;
		static iButton;

		id = get_member(weapon, m_pPlayer);
		iButton = get_entvar(id, var_button);
		
		if((iButton & IN_ATTACK) && (get_member(weapon, m_Weapon_flNextPrimaryAttack) <= 0.0))
		{
			return HAM_IGNORED;
		}
		
		if((iButton & IN_RELOAD) && (get_member(weapon, m_Weapon_iClip) >= iWeaponMaxClip))
		{
			set_entvar(id, var_button, (iButton & ~IN_RELOAD));
			set_member(weapon, m_Weapon_flNextPrimaryAttack, 0.5);
		}
	}

	return HAM_IGNORED;
}

public OnHam__Shotgun_WeaponIdle(const weapon)
{
	static WeaponIdType:iWeaponId;
	static iWeaponMaxClip;

	iWeaponId = WeaponIdType:get_member(weapon, m_iId);
	iWeaponMaxClip = rg_get_iteminfo(weapon, ItemInfo_iMaxClip);

	if(iWeaponMaxClip != DEFAULT_MAXCLIP[_:iWeaponId])
	{
		if(get_member(weapon, m_Weapon_flTimeWeaponIdle) > 0.0)
		{
			return HAM_IGNORED;
		}
		
		static id;
		static iClip;
		static iSpecialReload;
		
		id = get_member(weapon, m_pPlayer);
		iClip = get_member(weapon, m_Weapon_iClip);
		iSpecialReload = get_member(weapon, m_Weapon_fInSpecialReload);
		
		if(!iClip && !iSpecialReload)
		{
			return HAM_IGNORED;
		}
		
		if(iSpecialReload && (iClip >= iWeaponMaxClip))
		{
			SendWeaponAnimation(id, 4);
			
			set_member(weapon, m_Weapon_fInSpecialReload, 0);
			set_member(weapon, m_Weapon_flTimeWeaponIdle, 1.5);
		}
	}

	return HAM_IGNORED;
}

public OnHam__Item_PostFrame(const weapon)
{
	static WeaponIdType:iWeaponId;
	static iWeaponMaxClip;

	iWeaponId = WeaponIdType:get_member(weapon, m_iId);
	iWeaponMaxClip = rg_get_iteminfo(weapon, ItemInfo_iMaxClip);

	if(iWeaponMaxClip != DEFAULT_MAXCLIP[_:iWeaponId])
	{
		static id;
		static iButton;

		id = get_member(weapon, m_pPlayer);
		iButton = get_entvar(id, var_button);

		if(((iButton & IN_ATTACK) && get_member(weapon, m_Weapon_flNextPrimaryAttack) <= 0.0) || ((iButton & IN_ATTACK2) && get_member(weapon, m_Weapon_flNextSecondaryAttack) <= 0.0))
		{
			return HAM_IGNORED;
		}

		if((iButton & IN_RELOAD) && !get_member(weapon, m_Weapon_fInReload) && (get_member(weapon, m_Weapon_iClip) >= iWeaponMaxClip))
		{
			set_entvar(id, var_button, (iButton & ~IN_RELOAD));
			
			if( ((1 << _:iWeaponId) & WEAPONS_SILENT_BIT_SUM) && 
				(((iWeaponId == WEAPON_USP) && !(get_member(weapon, m_Weapon_iWeaponState) & WPNSTATE_USP_SILENCED)) || 
				((iWeaponId == WEAPON_M4A1) && !(get_member(weapon, m_Weapon_iWeaponState) & WPNSTATE_M4A1_SILENCED))) )
			{
				SendWeaponAnimation(id, (iWeaponId == WEAPON_USP) ? 8 : 7);
			}
			else
			{
				SendWeaponAnimation(id, 0);
			}
		}
	}

	return HAM_IGNORED;
}

stock SendWeaponAnimation(const id, const animation)
{
	set_entvar(id, var_weaponanim, animation);
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, _, id);
	write_byte(animation);
	write_byte(get_entvar(id, var_body));
	message_end();
}