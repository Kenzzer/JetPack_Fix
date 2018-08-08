#include "extension.h"
#include "CDetour/detours.h"

IGameConfig *g_pGameConf = nullptr;
CDetour *g_pdGetSharedPoseParameter = nullptr;

SMExt g_Ext;
SMEXT_LINK(&g_Ext);

class virtualgroup_t 
{
public:
	void *cache;
	CUtlVector< int > boneMap;				// maps global bone to local bone
	CUtlVector< int > masterBone;			// maps local bone to global bone
	CUtlVector< int > masterSeq;			// maps local sequence to master sequence
	CUtlVector< int > masterAnim;			// maps local animation to master animation
	CUtlVector< int > masterAttachment;	// maps local attachment to global
	CUtlVector< int > masterPose;			// maps local pose parameter to global
	CUtlVector< int > masterNode;			// maps local transition nodes to global
};

struct virtualsequence_t
{
	int	flags;
	int activity;
	int group;
	int index;
};

struct virtualgeneric_t
{
	int group;
	int index;
};

struct virtualmodel_t
{
    CThreadFastMutex m_Lock;
	CUtlVector<virtualsequence_t> m_seq;
	CUtlVector< virtualgeneric_t > m_anim;
	CUtlVector< virtualgeneric_t > m_attachment;
	CUtlVector< virtualgeneric_t > m_pose;
	CUtlVector< virtualgroup_t > m_group;
};

class CStudioHdr
{
public:
	void *m_pStudioHdr;
	mutable virtualmodel_t *m_pVModel;
	
	int GetSharedPoseParameter(int iSequence, int iLocalPose);
};

int CStudioHdr::GetSharedPoseParameter(int iSequence, int iLocalPose)
{
	if (m_pVModel == NULL)
	{
		return iLocalPose;
	}

	if (iLocalPose == -1)
		return iLocalPose;
	
	if (!m_pVModel->m_seq.IsValidIndex(iSequence))
		return iLocalPose;
	
	int group = m_pVModel->m_seq[iSequence].group;
	virtualgroup_t *pGroup = m_pVModel->m_group.IsValidIndex( group ) ? &m_pVModel->m_group[ group ] : NULL;

	return (pGroup && pGroup->masterPose.IsValidIndex( iLocalPose )) ? pGroup->masterPose[iLocalPose] : iLocalPose;
}

DETOUR_DECL_MEMBER2(CStudioHdr_GetSharedPoseParameter, int, int, iSequence, int, iLocalPose)
{
	CStudioHdr *studio = reinterpret_cast<CStudioHdr *>(this);
	return studio->GetSharedPoseParameter(iSequence, iLocalPose);
}

bool SMExt::SDK_OnLoad(char *error, size_t maxlength, bool late)
{
	char conf_error[255];
	if(!gameconfs->LoadGameConfigFile("poseparameter_fix", &g_pGameConf, conf_error, sizeof(conf_error)))
	{
		snprintf(error, maxlength, "FAILED TO LOAD GAMEDATA ERROR: %s", conf_error);
		return false;
	}
	
	CDetourManager::Init(g_pSM->GetScriptingEngine(), g_pGameConf);
	
	g_pdGetSharedPoseParameter = DETOUR_CREATE_MEMBER(CStudioHdr_GetSharedPoseParameter, "CStudioHdr::GetSharedPoseParameter");
	if (g_pdGetSharedPoseParameter != NULL)
		g_pdGetSharedPoseParameter->EnableDetour();
	
	return true;
}

void SMExt::SDK_OnUnload()
{
	gameconfs->CloseGameConfigFile(g_pGameConf);
	
	if (g_pdGetSharedPoseParameter != NULL) g_pdGetSharedPoseParameter->Destroy();
}