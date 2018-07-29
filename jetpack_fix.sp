#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>

int g_iPyroArms = -1;

public Plugin myinfo = 
{
    name = "[TF2] Jet Pack Fix",
    author	= "Benoist3012",
    description	= "Fix the notorious crash \"server_srv.so!CStudioHdr::GetSharedPoseParameter(int, int) const\".",
    version = "0.1",
    url = "https://steamcommunity.com/id/Benoist3012/"
}

Handle g_hHookGetSequenceGroundSpeed;

public void OnPluginStart()
{
	Handle hGameData = LoadGameConfigFile("jetpack_fix");
	if (hGameData == null) SetFailState("Could not find jetpack_fix gamedata!");
	
	int iOffset = GameConfGetOffset(hGameData, "CBaseAnimating::GetSequenceGroundSpeed");
	g_hHookGetSequenceGroundSpeed = DHookCreate(iOffset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, Hook_GetSequenceGroundSpeed); 
	if (g_hHookGetSequenceGroundSpeed == null)
	{
		SetFailState("Failed to create dHook CBaseAnimating::GetSequenceGroundSpeed");
	}
	DHookAddParam(g_hHookGetSequenceGroundSpeed, HookParamType_Int);
	DHookAddParam(g_hHookGetSequenceGroundSpeed, HookParamType_Int);
	
	delete hGameData;
	
	// Late load
	int iVM = INVALID_ENT_REFERENCE;
	while ((iVM = FindEntityByClassname(iVM, "tf_viewmodel")) != -1)
	{
		DHookEntity(g_hHookGetSequenceGroundSpeed, false, iVM); 
	}
}

public void OnMapStart()
{
	g_iPyroArms = PrecacheModel("models/weapons/c_models/c_pyro_arms.mdl");
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strcmp(classname, "tf_viewmodel") == 0)
		DHookEntity(g_hHookGetSequenceGroundSpeed, false, entity); 
}

public MRESReturn Hook_GetSequenceGroundSpeed(int iVM, Handle hReturn, Handle hParams)
{
	int iJetPack = GetEntPropEnt(iVM, Prop_Send, "m_hWeapon");
	if (iJetPack > MaxClients)
	{
		int iModelIndex = GetEntProp(iVM, Prop_Send, "m_nModelIndex");
		
		if (iModelIndex != g_iPyroArms) // Could also check if the arms are the sniper's but we don't know if it will crash with more classes later on, so it's safer to check if it's not hold by a pyro
		{
			char sClassName[64];
			GetEntityClassname(iJetPack, sClassName, sizeof(sClassName));
			
			if (strcmp(sClassName, "tf_weapon_rocketpack") == 0) // Could check the item index definition but we don't know if valve will add skin varient of that weapon so it is probably safer to look for the classname
			{
				DHookSetReturn(hReturn, 0.0);
				return MRES_Supercede;
			}
		}
	}
	return MRES_Ignored;
}