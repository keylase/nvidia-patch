#include "pch.h"
#include "nvfbcdefs.h"

#ifdef _WIN64
#define LIBNAME TEXT(".\\NvFBC64_.dll")
#else
#define LIBNAME TEXT(".\\NvFBC_.dll")
#endif

#define ENV_NVFBC_DUMPDIR TEXT("NVFBCWRP_DUMP_DIR")
#define ENV_NVFBC_PRIVDATA_FILE TEXT("NVFBCWRP_PRIVDATA_FILE")
#define NVFBC_PRIVDATA_DUMP_PREFIX TEXT("pd_")

extern "C" {
	FARPROC ORIG_NvFBC_Create, ORIG_NvFBC_Enable, ORIG_NvFBC_GetSDKVersion,
		ORIG_NvFBC_GetStatus, ORIG_NvFBC_GetStatusEx, ORIG_NvFBC_SetGlobalFlags,
		ORIG_NvOptimusEnablement;
}
NvFBC_CreateFunctionExType ORIG_NvFBC_CreateEx;

// Default magic code which is passed as pPrivateData
// and enables NvFBC to work on GeForce
DWORD default_magic[] = { 0xAEF57AC5, 0x401D1A39, 0x1B856BBE, 0x9ED0CEBA };
void* magic = default_magic;
NvU32 magic_size = sizeof(default_magic);

TCHAR* dumpPath = NULL;

TCHAR* getEnvVar(const TCHAR* name, DWORD size = MAX_PATH) {
	TCHAR* buf = NULL;
	try {
		buf = new TCHAR[size];
	}
	catch (std::bad_alloc&) {
		return NULL;
	}
	DWORD ret = GetEnvironmentVariable(name, buf, size);
	if (ret != 0 && size > ret) {
		return buf;
	}
	else {
		delete buf;
		return NULL;
	}
}

std::tuple<NvU32, void*> tryGetMagic() {
	TCHAR* filename = getEnvVar(ENV_NVFBC_PRIVDATA_FILE);
	if (!filename) {
		return { 0, NULL };
	}
	
	HANDLE hFile = INVALID_HANDLE_VALUE;
	hFile = CreateFile(filename,
		GENERIC_READ,
		FILE_SHARE_READ,
		NULL,
		OPEN_EXISTING,
		FILE_ATTRIBUTE_NORMAL,
		NULL);
	delete filename;
	if (hFile == INVALID_HANDLE_VALUE) {
		return { 0, NULL };
	}
	
	LARGE_INTEGER size;
	LARGE_INTEGER zero;
	zero.QuadPart = 0;
	if (!SetFilePointerEx(hFile, zero, &size, FILE_END)) {
		CloseHandle(hFile);
		return { 0, NULL };
	}
	if (size.HighPart) {
		CloseHandle(hFile);
		return { 0, NULL };
	}
	if (!SetFilePointerEx(hFile, zero, NULL, FILE_BEGIN)) {
		CloseHandle(hFile);
		return { 0, NULL };
	}

	char* buf = NULL;
	try {
		buf = new char[size.LowPart];
	}
	catch (std::bad_alloc&)
	{
		CloseHandle(hFile);
		return { 0, NULL };
	}
	DWORD bytes_read = 0;
	if (ReadFile(hFile, buf, size.LowPart, &bytes_read, NULL) &&
	  bytes_read == size.LowPart) {
		CloseHandle(hFile);
		return { size.LowPart, buf };
	}
	else {
		CloseHandle(hFile);
		delete buf;
		return { 0, NULL };
	}
}


BOOL WINAPI DllMain(HINSTANCE hInst,DWORD reason,LPVOID)
{
	HINSTANCE hL = 0;
	if (reason == DLL_PROCESS_ATTACH)
	{
		hL = LoadLibrary(LIBNAME);
		if (!hL) return false;

		// DllMain calls are serialized by system on process level, so we are clear
		// to set required variables.
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

		// Check dump settings
		if (TCHAR* dumpDirName = getEnvVar(ENV_NVFBC_DUMPDIR))
		{
			dumpPath = dumpDirName;
		}

		// Check external magic file
		NvU32 new_magic_size;
		void* new_magic;
		std::tie(new_magic_size, new_magic) = tryGetMagic();
		if (new_magic) {
			magic = new_magic;
			magic_size = new_magic_size;
		}
	}
	if (reason == DLL_PROCESS_DETACH && hL)
	{
		FreeLibrary(hL);
		if (dumpPath) {
			delete dumpPath;
			dumpPath = NULL;
		}
		if (magic != default_magic) {
			delete magic;
			magic = NULL;
		}
		return true;
	}

	return true;
}

void tryDumpPrivateData(NvU32 size, void* data)
{
	TCHAR szTmpFilename[MAX_PATH];
	if (dumpPath && GetTempFileName(dumpPath, NVFBC_PRIVDATA_DUMP_PREFIX, 0, szTmpFilename) != 0) {
		// Privdata spying enabled and tempfile created.
		// Attempt to dump private data.
		HANDLE hTempFile = INVALID_HANDLE_VALUE;
		hTempFile = CreateFile((LPTSTR)szTmpFilename,
			GENERIC_WRITE,
			0,
			NULL,
			CREATE_ALWAYS,
			FILE_ATTRIBUTE_NORMAL,
			NULL);
		if (hTempFile != INVALID_HANDLE_VALUE) {
			// File is open, dumping data.
			WriteFile(hTempFile, data, size, NULL, NULL);
			CloseHandle(hTempFile);
		}
	}
}

NVFBCRESULT NVFBCAPI PROXY_NvFBC_CreateEx(NvFBCCreateParams* params) {
	if (params->dwPrivateDataSize == 0 && params->pPrivateData == NULL) {
		//Backup old values
		void* bkp_privdata = params->pPrivateData;
		NvU32 bkp_privdatasize = params->dwPrivateDataSize;
		// Inject private keys into structure
		params->dwPrivateDataSize = magic_size;
		params->pPrivateData = magic;
		// Invoke original function
		NVFBCRESULT res = ORIG_NvFBC_CreateEx(params);
		// Rollback private data changes in params structure
		params->pPrivateData = bkp_privdata;
		params->dwPrivateDataSize = bkp_privdatasize;
		return res;
	}
	else {
		if (params->dwPrivateDataSize > 0 && params->pPrivateData != NULL) {
			tryDumpPrivateData(params->dwPrivateDataSize, params->pPrivateData);
		}
		return ORIG_NvFBC_CreateEx((void*)params);
	}
}