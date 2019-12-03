#include "pch.h"
#include "nvfbcdefs.h"
#include <windows.h>

#ifdef _WIN64
#define LIBNAME ".\\NvFBC64_.dll"
#else
#define LIBNAME ".\\NvFBC_.dll"
#endif

HINSTANCE hLThis = 0;
extern "C" {
	FARPROC ORIG_NvFBC_Create, ORIG_NvFBC_Enable, ORIG_NvFBC_GetSDKVersion,
		ORIG_NvFBC_GetStatus, ORIG_NvFBC_GetStatusEx, ORIG_NvFBC_SetGlobalFlags,
		ORIG_NvOptimusEnablement;
}
NvFBC_CreateFunctionExType ORIG_NvFBC_CreateEx;
HINSTANCE hL = 0;

BOOL WINAPI DllMain(HINSTANCE hInst,DWORD reason,LPVOID)
{
	if (reason == DLL_PROCESS_ATTACH)
	{
		//hLThis = hInst;
		hL = LoadLibrary(LIBNAME);
		if (!hL) return false;
		ORIG_NvFBC_Create = GetProcAddress(hL, "NvFBC_Create");
		if (!ORIG_NvFBC_Create) return false;
		ORIG_NvFBC_CreateEx = (NvFBC_CreateFunctionExType)::GetProcAddress(hL, "NvFBC_CreateEx");
		if (!ORIG_NvFBC_CreateEx) return false;
		ORIG_NvFBC_Enable = GetProcAddress(hL, "NvFBC_Enable");
		if (!ORIG_NvFBC_Enable) return false;
		ORIG_NvFBC_GetSDKVersion = GetProcAddress(hL, "NvFBC_GetSDKVersion");
		if (!ORIG_NvFBC_GetSDKVersion) return false;
		ORIG_NvFBC_GetStatus = GetProcAddress(hL, "NvFBC_GetStatus");
		if (!ORIG_NvFBC_GetStatus) return false;
		ORIG_NvFBC_GetStatusEx = GetProcAddress(hL, "NvFBC_GetStatusEx");
		if (!ORIG_NvFBC_GetStatusEx) return false;
		ORIG_NvFBC_SetGlobalFlags = GetProcAddress(hL, "NvFBC_SetGlobalFlags");
		if (!ORIG_NvFBC_SetGlobalFlags) return false;
		ORIG_NvOptimusEnablement = GetProcAddress(hL, "NvOptimusEnablement");
		if (!ORIG_NvOptimusEnablement) return false;
	}
	if (reason == DLL_PROCESS_DETACH)
	{
		FreeLibrary(hL);
		return true;
	}

	return true;
}

NVFBCRESULT NVFBCAPI PROXY_NvFBC_CreateEx(NvFBCCreateParams* params) {
	if (params->dwPrivateDataSize == 0 && params->pPrivateData == NULL) {
		//Backup old values
		void* bkp_privdata = params->pPrivateData;
		NvU32 bkp_privdatasize = params->dwPrivateDataSize;
		// Inject private keys into structure
		params->dwPrivateDataSize = sizeof(magic);
		params->pPrivateData = &magic;
		// Invoke original function
		NVFBCRESULT res = ORIG_NvFBC_CreateEx(params);
		// Rollback private data changes in params structure
		params->pPrivateData = bkp_privdata;
		params->dwPrivateDataSize = bkp_privdatasize;
		return res;
	}
	else {
		return ORIG_NvFBC_CreateEx((void*)params);
	}
}