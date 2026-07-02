#pragma once
#ifndef __PCMGR_MSCOREE_H__
#define __PCMGR_MSCOREE_H__

/*
 * Minimal local reconstruction of the .NET Framework CLR hosting headers
 * (mscoree.h / Metahost.h) covering only what mapphlp.cpp / msup.cpp use.
 *
 * The real headers ship with the .NET Framework SDK (NETFXSDK), which is
 * not installed in this build environment. Interface vtable order, method
 * signatures and GUIDs below were verified against Microsoft's own
 * MIDL-generated header (dotnet/coreclr src/pal/prebuilt/inc/{mscoree,metahost}.h),
 * the independent Wine reimplementation (include/mscoree.idl), and the
 * machine-generated windows-rs bindings (Win32/System/ClrHosting) - all three
 * agree, so the vtable layout here should be ABI-compatible with the real
 * mscoree.dll shipped on this machine.
 */

#include <unknwn.h>
#include <oaidl.h>

struct IHostControl;
struct ICLRControl;

#define PCMGR_DEFINE_GUID(name, l, w1, w2, b1, b2, b3, b4, b5, b6, b7, b8) \
    EXTERN_C const GUID DECLSPEC_SELECTANY name = { l, w1, w2, { b1, b2, b3, b4, b5, b6, b7, b8 } }

PCMGR_DEFINE_GUID(IID_ICLRMetaHost,     0xD332DB9E, 0xB9B3, 0x4125, 0x82, 0x07, 0xA1, 0x48, 0x84, 0xF5, 0x32, 0x16);
PCMGR_DEFINE_GUID(CLSID_CLRMetaHost,    0x9280188D, 0x0E8E, 0x4867, 0xB3, 0x0C, 0x7F, 0xA8, 0x38, 0x84, 0xE8, 0xDE);
PCMGR_DEFINE_GUID(IID_ICLRRuntimeInfo,  0xBD39D1D2, 0xBA2F, 0x486A, 0x89, 0xB0, 0xB4, 0xB0, 0xCB, 0x46, 0x68, 0x91);
PCMGR_DEFINE_GUID(IID_ICLRRuntimeHost,  0x90F1A06C, 0x7712, 0x4762, 0x86, 0xB5, 0x7A, 0x5E, 0xBA, 0x6B, 0xDB, 0x02);
PCMGR_DEFINE_GUID(CLSID_CLRRuntimeHost, 0x90F1A06E, 0x7712, 0x4762, 0x86, 0xB5, 0x7A, 0x5E, 0xBA, 0x6B, 0xDB, 0x02);
PCMGR_DEFINE_GUID(IID_ICLRControl,      0x9065597E, 0xD1A1, 0x4FB2, 0xB6, 0xBA, 0x7E, 0x1F, 0xCE, 0x23, 0x0F, 0x61);
PCMGR_DEFINE_GUID(IID_ICLRGCManager,    0x54D9007E, 0xA8E2, 0x4885, 0xB7, 0xBF, 0xF9, 0x98, 0xDE, 0xEE, 0x4F, 0x2A);

STDAPI CLRCreateInstance(REFCLSID clsid, REFIID riid, LPVOID *ppInterface);
typedef HRESULT (STDAPICALLTYPE *CLRCreateInstanceFnPtr)(REFCLSID clsid, REFIID riid, LPVOID *ppInterface);

typedef HRESULT ( __stdcall *CallbackThreadSetFnPtr )( void);
typedef HRESULT ( __stdcall *CallbackThreadUnsetFnPtr )( void);

MIDL_INTERFACE("BD39D1D2-BA2F-486a-89B0-B4B0CB466891")
ICLRRuntimeInfo : public IUnknown
{
public:
    virtual HRESULT STDMETHODCALLTYPE GetVersionString(
        /* [size_is][out] */ LPWSTR pwzBuffer,
        /* [out][in] */ DWORD *pcchBuffer) = 0;

    virtual HRESULT STDMETHODCALLTYPE GetRuntimeDirectory(
        /* [size_is][out] */ LPWSTR pwzBuffer,
        /* [out][in] */ DWORD *pcchBuffer) = 0;

    virtual HRESULT STDMETHODCALLTYPE IsLoaded(
        /* [in] */ HANDLE hndProcess,
        /* [retval][out] */ BOOL *pbLoaded) = 0;

    virtual HRESULT STDMETHODCALLTYPE LoadErrorString(
        /* [in] */ UINT iResourceID,
        /* [size_is][out] */ LPWSTR pwzBuffer,
        /* [out][in] */ DWORD *pcchBuffer,
        /* [lcid][in] */ LONG iLocaleID) = 0;

    virtual HRESULT STDMETHODCALLTYPE LoadLibrary(
        /* [in] */ LPCWSTR pwzDllName,
        /* [retval][out] */ HMODULE *phndModule) = 0;

    virtual HRESULT STDMETHODCALLTYPE GetProcAddress(
        /* [in] */ LPCSTR pszProcName,
        /* [retval][out] */ LPVOID *ppProc) = 0;

    virtual HRESULT STDMETHODCALLTYPE GetInterface(
        /* [in] */ REFCLSID rclsid,
        /* [in] */ REFIID riid,
        /* [retval][iid_is][out] */ LPVOID *ppUnk) = 0;

    virtual HRESULT STDMETHODCALLTYPE IsLoadable(
        /* [retval][out] */ BOOL *pbLoadable) = 0;

    virtual HRESULT STDMETHODCALLTYPE SetDefaultStartupFlags(
        /* [in] */ DWORD dwStartupFlags,
        /* [in] */ LPCWSTR pwzHostConfigFile) = 0;

    virtual HRESULT STDMETHODCALLTYPE GetDefaultStartupFlags(
        /* [out] */ DWORD *pdwStartupFlags,
        /* [size_is][out] */ LPWSTR pwzHostConfigFile,
        /* [out][in] */ DWORD *pcchHostConfigFile) = 0;

    virtual HRESULT STDMETHODCALLTYPE BindAsLegacyV2Runtime( void) = 0;

    virtual HRESULT STDMETHODCALLTYPE IsStarted(
        /* [out] */ BOOL *pbStarted,
        /* [out] */ DWORD *pdwStartupFlags) = 0;
};

typedef void ( __stdcall *RuntimeLoadedCallbackFnPtr )(
    ICLRRuntimeInfo *pRuntimeInfo,
    CallbackThreadSetFnPtr pfnCallbackThreadSet,
    CallbackThreadUnsetFnPtr pfnCallbackThreadUnset);

MIDL_INTERFACE("D332DB9E-B9B3-4125-8207-A14884F53216")
ICLRMetaHost : public IUnknown
{
public:
    virtual HRESULT STDMETHODCALLTYPE GetRuntime(
        /* [in] */ LPCWSTR pwzVersion,
        /* [in] */ REFIID riid,
        /* [retval][iid_is][out] */ LPVOID *ppRuntime) = 0;

    virtual HRESULT STDMETHODCALLTYPE GetVersionFromFile(
        /* [in] */ LPCWSTR pwzFilePath,
        /* [size_is][out] */ LPWSTR pwzBuffer,
        /* [out][in] */ DWORD *pcchBuffer) = 0;

    virtual HRESULT STDMETHODCALLTYPE EnumerateInstalledRuntimes(
        /* [retval][out] */ IEnumUnknown **ppEnumerator) = 0;

    virtual HRESULT STDMETHODCALLTYPE EnumerateLoadedRuntimes(
        /* [in] */ HANDLE hndProcess,
        /* [retval][out] */ IEnumUnknown **ppEnumerator) = 0;

    virtual HRESULT STDMETHODCALLTYPE RequestRuntimeLoadedNotification(
        /* [in] */ RuntimeLoadedCallbackFnPtr pCallbackFunction) = 0;

    virtual HRESULT STDMETHODCALLTYPE QueryLegacyV2RuntimeBinding(
        /* [in] */ REFIID riid,
        /* [retval][iid_is][out] */ LPVOID *ppUnk) = 0;

    virtual HRESULT STDMETHODCALLTYPE ExitProcess(
        /* [in] */ INT32 iExitCode) = 0;
};

/* ICLRMetaHostPolicy is referenced (as an unused pointer) in mapphlp.cpp but
   no method on it is ever called, so an opaque forward declaration suffices. */
struct ICLRMetaHostPolicy;

typedef HRESULT ( __stdcall *FExecuteInAppDomainCallback )( void *cookie);

MIDL_INTERFACE("90F1A06C-7712-4762-86B5-7A5EBA6BDB02")
ICLRRuntimeHost : public IUnknown
{
public:
    virtual HRESULT STDMETHODCALLTYPE Start( void) = 0;

    virtual HRESULT STDMETHODCALLTYPE Stop( void) = 0;

    virtual HRESULT STDMETHODCALLTYPE SetHostControl(
        /* [in] */ IHostControl *pHostControl) = 0;

    virtual HRESULT STDMETHODCALLTYPE GetCLRControl(
        /* [out] */ ICLRControl **pCLRControl) = 0;

    virtual HRESULT STDMETHODCALLTYPE UnloadAppDomain(
        /* [in] */ DWORD dwAppDomainId,
        /* [in] */ BOOL fWaitUntilDone) = 0;

    virtual HRESULT STDMETHODCALLTYPE ExecuteInAppDomain(
        /* [in] */ DWORD dwAppDomainId,
        /* [in] */ FExecuteInAppDomainCallback pCallback,
        /* [in] */ void *cookie) = 0;

    virtual HRESULT STDMETHODCALLTYPE GetCurrentAppDomainId(
        /* [out] */ DWORD *pdwAppDomainId) = 0;

    virtual HRESULT STDMETHODCALLTYPE ExecuteApplication(
        /* [in] */ LPCWSTR pwzAppFullName,
        /* [in] */ DWORD dwManifestPaths,
        /* [in] */ LPCWSTR *ppwzManifestPaths,
        /* [in] */ DWORD dwActivationData,
        /* [in] */ LPCWSTR *ppwzActivationData,
        /* [out] */ int *pReturnValue) = 0;

    virtual HRESULT STDMETHODCALLTYPE ExecuteInDefaultAppDomain(
        /* [in] */ LPCWSTR pwzAssemblyPath,
        /* [in] */ LPCWSTR pwzTypeName,
        /* [in] */ LPCWSTR pwzMethodName,
        /* [in] */ LPCWSTR pwzArgument,
        /* [out] */ DWORD *pReturnValue) = 0;
};

MIDL_INTERFACE("9065597E-D1A1-4fb2-B6BA-7E1FCE230F61")
ICLRControl : public IUnknown
{
public:
    virtual HRESULT STDMETHODCALLTYPE GetCLRManager(
        /* [in] */ REFIID riid,
        /* [out] */ void **ppObject) = 0;

    virtual HRESULT STDMETHODCALLTYPE SetAppDomainManagerType(
        /* [in] */ LPCWSTR appDomainManagerAssembly,
        /* [in] */ LPCWSTR appDomainManagerType) = 0;
};

typedef enum COR_GC_STAT_TYPES
{
    COR_GC_COUNTS      = 1,
    COR_GC_MEMORYUSAGE = 2
} COR_GC_STAT_TYPES;

typedef struct COR_GC_STATS
{
    DWORD  Flags;
    SIZE_T ExplicitGCCount;
    SIZE_T GenCollectionsTaken[3];
    SIZE_T CommittedKBytes;
    SIZE_T ReservedKBytes;
    SIZE_T Gen0HeapSizeKBytes;
    SIZE_T Gen1HeapSizeKBytes;
    SIZE_T Gen2HeapSizeKBytes;
    SIZE_T LargeObjectHeapSizeKBytes;
    SIZE_T KBytesPromotedFromGen0;
    SIZE_T KBytesPromotedFromGen1;
} COR_GC_STATS;

MIDL_INTERFACE("54D9007E-A8E2-4885-B7BF-F998DEEE4F2A")
ICLRGCManager : public IUnknown
{
public:
    virtual HRESULT STDMETHODCALLTYPE Collect(
        /* [in] */ LONG Generation) = 0;

    virtual HRESULT STDMETHODCALLTYPE GetStats(
        /* [out][in] */ COR_GC_STATS *pStats) = 0;

    virtual HRESULT STDMETHODCALLTYPE SetGCStartupLimits(
        /* [in] */ DWORD SegmentSize,
        /* [in] */ DWORD MaxGen0Size) = 0;
};

#undef PCMGR_DEFINE_GUID

#endif /* __PCMGR_MSCOREE_H__ */
