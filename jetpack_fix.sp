#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>

public Plugin myinfo = 
{
    name = "[TF2] Jet Pack Fix",
    author	= "Benoist3012",
    description	= "Fixes the notorious crash \"server_srv.so!CStudioHdr::GetSharedPoseParameter(int, int) const\".",
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

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strcmp(classname, "tf_viewmodel") == 0)
		DHookEntity(g_hHookGetSequenceGroundSpeed, false, entity); 
}

public MRESReturn Hook_GetSequenceGroundSpeed(int iVM, Handle hReturn, Handle hParams)
{
	/*
	// Enable this if the above code creates bogus anim
	Address pStudioHdr = DHookGetParam(hParams, 1);
	int iSequence = DHookGetParam(hParams, 2);
	
	if (iSequence < 0) // Invalid sequence number, ignore..
	{
		DHookSetReturn(hReturn, 0.0);
		return MRES_Supercede;
	}
	
	// Info extracted from CStudioHdr::GetNumSeq( void ) ref: https://github.com/alliedmodders/hl2sdk/blob/fd71bdcb174866524c2bdf4847f93d6ca5ce9c69/public/studio.cpp#L904
	Address pVModel = view_as<Address>(LoadFromAddress(pStudioHdr + view_as<Address>(1 * 4), NumberType_Int32));
	if (pVModel == Address_Null) // We have problem if this is null
	{
		DHookSetReturn(hReturn, 0.0);
		return MRES_Supercede;
	}
	
	int iTotalSequence = LoadFromAddress(pStudioHdr + view_as<Address>(5 * 4), NumberType_Int32);
	if (iSequence >= iTotalSequence) // Invalid sequence skip
	{
		DHookSetReturn(hReturn, 0.0);
		return MRES_Supercede;
	}
	*/
	
	DHookSetReturn(hReturn, 0.0);
	return MRES_Supercede;
	
	//return MRES_Ignored;
}
