#pragma once
#ifndef __PCMGR_CORERROR_H__
#define __PCMGR_CORERROR_H__

/* Minimal local shim: only the single constant mapphlp.cpp actually uses
   from the real (NETFXSDK-only) corerror.h. Value verified against the
   official corerror.h (COR_E_DLLNOTFOUND = EMAKEHR(0x1524), i.e.
   MAKE_HRESULT(SEVERITY_ERROR, FACILITY_URT=0x13, 0x1524) = 0x80131524). */

#ifndef COR_E_DLLNOTFOUND
#define COR_E_DLLNOTFOUND 0x80131524L
#endif

#endif /* __PCMGR_CORERROR_H__ */
