#pragma once

typedef unsigned long      NvU32; /* 0 to 4294967295                         */

/**
 * \ingroup NVFBC
 * Macro to define the NVFBC API version corresponding to this distribution.
 */
#define NVFBC_DLL_VERSION 0x70

 /**
  * \ingroup NVFBC
  * Calling Convention
  */
#define NVFBCAPI __stdcall

  /**
   * \ingroup NVFBC
   * Macro to construct version numbers for parameter structs.
   */
#define NVFBC_STRUCT_VERSION(typeName, ver) (NvU32)(sizeof(typeName) | ((ver)<<16) | (NVFBC_DLL_VERSION << 24))

typedef enum _NVFBCRESULT
{
	NVFBC_SUCCESS = 0,
	NVFBC_ERROR_GENERIC = -1,                     /**< Unexpected failure in NVFBC. */
	NVFBC_ERROR_INVALID_PARAM = -2,               /**< One or more of the paramteres passed to NvFBC are invalid [This include NULL pointers]. */
	NVFBC_ERROR_INVALIDATED_SESSION = -3,         /**< NvFBC session is invalid. Client needs to recreate session. */
	NVFBC_ERROR_PROTECTED_CONTENT = -4,           /**< Protected content detected. Capture failed. */
	NVFBC_ERROR_DRIVER_FAILURE = -5,              /**< GPU driver returned failure to process NvFBC command. */
	NVFBC_ERROR_CUDA_FAILURE = -6,              /**< CUDA driver returned failure to process NvFBC command. */
	NVFBC_ERROR_UNSUPPORTED = -7,              /**< API Unsupported on this version of NvFBC. */
	NVFBC_ERROR_HW_ENC_FAILURE = -8,             /**< HW Encoder returned failure to process NVFBC command. */
	NVFBC_ERROR_INCOMPATIBLE_DRIVER = -9,         /**< NVFBC is not compatible with this version of the GPU driver. */
	NVFBC_ERROR_UNSUPPORTED_PLATFORM = -10,       /**< NVFBC is not supported on this platform. */
	NVFBC_ERROR_OUT_OF_MEMORY = -11,             /**< Failed to allocate memory. */
	NVFBC_ERROR_INVALID_PTR = -12,             /**< A NULL pointer was passed. */
	NVFBC_ERROR_INCOMPATIBLE_VERSION = -13,       /**< An API was called with a parameter struct that has an incompatible version. Check dwVersion field of paramter struct. */
	NVFBC_ERROR_OPT_CAPTURE_FAILURE = -14,        /**< Desktop Capture failed. */
	NVFBC_ERROR_INSUFFICIENT_PRIVILEGES = -15,   /**< User doesn't have appropriate previlages. */
	NVFBC_ERROR_INVALID_CALL = -16,               /**< NVFBC APIs called in wrong sequence. */
	NVFBC_ERROR_SYSTEM_ERROR = -17,               /**< Win32 error. */
	NVFBC_ERROR_INVALID_TARGET = -18,             /**< The target adapter idx can not be used for NVFBC capture. It may not correspond to an NVIDIA GPU, or may not be attached to desktop. */
	NVFBC_ERROR_NVAPI_FAILURE = -19,              /**< NvAPI Error */
	NVFBC_ERROR_DYNAMIC_DISABLE = -20,            /**< NvFBC is dynamically disabled. Cannot continue to capture */
	NVFBC_ERROR_IPC_FAILURE = -21,                /**< NVFBC encountered an error in state management */
	NVFBC_ERROR_CURSOR_CAPTURE_FAILURE = -22,     /**< Hardware cursor capture failed */
} NVFBCRESULT;


typedef struct _NvFBCCreateParams
{
	NvU32  dwVersion;              /**< [in]  Struct version. Set to NVFBC_CREATE_PARAMS_VER. */
	NvU32  dwInterfaceType;        /**< [in]  ID of the NVFBC interface Type being requested. */
	NvU32  dwMaxDisplayWidth;      /**< [out] Max. display width allowed. */
	NvU32  dwMaxDisplayHeight;     /**< [out] Max. display height allowed. */
	void* pDevice;                /**< [in]  Device pointer. */
	void* pPrivateData;           /**< [in]  Private data [optional].  */
	NvU32  dwPrivateDataSize;      /**< [in]  Size of private data. */
	NvU32  dwInterfaceVersion;     /**< [in]  Version of the capture interface. */
	void* pNvFBC;                 /**< [out] A pointer to the requested NVFBC object. */
	NvU32  dwAdapterIdx;           /**< [in]  Adapter Ordinal corresponding to the display to be grabbed. If pDevice is set, this parameter is ignored. */
	NvU32  dwNvFBCVersion;         /**< [out] Indicates the highest NvFBC interface version supported by the loaded NVFBC library. */
	void* cudaCtx;                /**< [in]  CUDA context created using cuD3D9CtxCreate with the D3D9 device passed as pDevice. Only used for NvFBCCuda interface.
											  It is mandatory to pass a valid D3D9 device if cudaCtx is passed. The call will fail otherwise.
											  Client must release NvFBCCuda object before destroying the cudaCtx. */
	void* pPrivateData2;           /**< [in]  Private data [optional].  */
	NvU32  dwPrivateData2Size;      /**< [in]  Size of private data. */
	NvU32  dwReserved[55];         /**< [in]  Reserved. Should be set to 0. */
	void* pReserved[27];          /**< [in]  Reserved. Should be set to NULL. */
}NvFBCCreateParams;
#define NVFBC_CREATE_PARAMS_VER_1 NVFBC_STRUCT_VERSION(NvFBCCreateParams, 1)
#define NVFBC_CREATE_PARAMS_VER_2 NVFBC_STRUCT_VERSION(NvFBCCreateParams, 2)
#define NVFBC_CREATE_PARAMS_VER NVFBC_CREATE_PARAMS_VER_2

typedef NVFBCRESULT(NVFBCAPI* NvFBC_CreateFunctionExType)  (void* pCreateParams);