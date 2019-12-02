.data

extern ORIG_NvFBC_Create : qword, ORIG_NvFBC_Enable : qword,
	ORIG_NvFBC_GetSDKVersion : qword, ORIG_NvFBC_GetStatus : qword,
	ORIG_NvFBC_GetStatusEx : qword, ORIG_NvFBC_SetGlobalFlags : qword,
	ORIG_NvOptimusEnablement : qword

.code
PROXY_NvFBC_Create proc
jmp qword ptr [ORIG_NvFBC_Create]
PROXY_NvFBC_Create endp

PROXY_NvFBC_Enable proc
jmp qword ptr [ORIG_NvFBC_Enable]
PROXY_NvFBC_Enable endp

PROXY_NvFBC_GetSDKVersion proc
jmp qword ptr [ORIG_NvFBC_GetSDKVersion]
PROXY_NvFBC_GetSDKVersion endp

PROXY_NvFBC_GetStatus proc
jmp qword ptr [ORIG_NvFBC_GetStatus]
PROXY_NvFBC_GetStatus endp

PROXY_NvFBC_GetStatusEx proc
jmp qword ptr [ORIG_NvFBC_GetStatusEx]
PROXY_NvFBC_GetStatusEx endp

PROXY_NvFBC_SetGlobalFlags proc
jmp qword ptr [ORIG_NvFBC_SetGlobalFlags]
PROXY_NvFBC_SetGlobalFlags endp

PROXY_NvOptimusEnablement proc
jmp qword ptr [ORIG_NvOptimusEnablement]
PROXY_NvOptimusEnablement endp

end