#ifndef _SM_EXTENSION_H_INCLUDED_
	#define _SM_EXTENSION_H_INCLUDED_
#pragma once

#include "smsdk_ext.h"

class SMExt : public SDKExtension
{
	public: // SDKExtension
		virtual bool SDK_OnLoad(char *error, size_t maxlength, bool late);
		virtual void SDK_OnUnload();
};

#endif