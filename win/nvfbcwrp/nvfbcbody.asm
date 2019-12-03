IFDEF RAX
ptrsz equ <qword>
ELSE
.486
.model flat, c
ptrsz equ <dword>
ENDIF
.data
extern ORIG_NvFBC_Create : ptrsz, ORIG_NvFBC_Enable : ptrsz,
	ORIG_NvFBC_GetSDKVersion : ptrsz, ORIG_NvFBC_GetStatus : ptrsz,
	ORIG_NvFBC_GetStatusEx : ptrsz, ORIG_NvFBC_SetGlobalFlags : ptrsz,
	ORIG_NvOptimusEnablement : ptrsz

.code
PROXY_NvFBC_Create proc
jmp ptrsz ptr [ORIG_NvFBC_Create]
PROXY_NvFBC_Create endp

PROXY_NvFBC_Enable proc
jmp ptrsz ptr [ORIG_NvFBC_Enable]
PROXY_NvFBC_Enable endp

PROXY_NvFBC_GetSDKVersion proc
jmp ptrsz ptr [ORIG_NvFBC_GetSDKVersion]
PROXY_NvFBC_GetSDKVersion endp

PROXY_NvFBC_GetStatus proc
jmp ptrsz ptr [ORIG_NvFBC_GetStatus]
PROXY_NvFBC_GetStatus endp

PROXY_NvFBC_GetStatusEx proc
jmp ptrsz ptr [ORIG_NvFBC_GetStatusEx]
PROXY_NvFBC_GetStatusEx endp

PROXY_NvFBC_SetGlobalFlags proc
jmp ptrsz ptr [ORIG_NvFBC_SetGlobalFlags]
PROXY_NvFBC_SetGlobalFlags endp

PROXY_NvOptimusEnablement proc
jmp ptrsz ptr [ORIG_NvOptimusEnablement]
PROXY_NvOptimusEnablement endp

end