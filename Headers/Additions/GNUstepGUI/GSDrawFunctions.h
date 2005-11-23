/** <title>GSDrawFunctions</title>

   <abstract>Useful/configurable drawing functions</abstract>

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
   Date: Jan 2004
   
   This file is part of the GNU Objective C User interface library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
   */

#ifndef _GNUstep_H_GSDrawFunctions
#define _GNUstep_H_GSDrawFunctions

#include <Foundation/NSGeometry.h>
// For gradient types
#include "AppKit/NSButtonCell.h"

@class NSColor;

@interface GSDrawFunctions : NSObject

+ (id) theme;
+ (void) setTheme: (id)theme;

+ (NSRect) drawButton: (NSRect)border : (NSRect)clip;
+ (NSRect) drawDarkButton: (NSRect)border : (NSRect)clip;
+ (NSRect) drawDarkBezel: (NSRect)border : (NSRect)clip;
+ (NSRect) drawLightBezel: (NSRect)border : (NSRect)clip;
+ (NSRect) drawGrayBezel: (NSRect)border : (NSRect)clip;
+ (NSRect) drawWhiteBezel: (NSRect)border : (NSRect)clip;
+ (NSRect) drawGroove: (NSRect)border : (NSRect)clip;
+ (NSRect) drawFramePhoto: (NSRect)border : (NSRect)clip;

+ (NSRect) drawGradientBorder: (NSGradientType)gradientType 
           inRect: (NSRect)border 
           withClip: (NSRect)clip;

- (NSRect) drawButton: (NSRect)border : (NSRect)clip;
- (NSRect) drawDarkButton: (NSRect)border : (NSRect)clip;
- (NSRect) drawDarkBezel: (NSRect)border : (NSRect)clip;
- (NSRect) drawLightBezel: (NSRect)border : (NSRect)clip;
- (NSRect) drawGrayBezel: (NSRect)border : (NSRect)clip;
- (NSRect) drawWhiteBezel: (NSRect)border : (NSRect)clip;
- (NSRect) drawGroove: (NSRect)border : (NSRect)clip;
- (NSRect) drawFramePhoto: (NSRect)border : (NSRect)clip;

- (NSRect) drawGradientBorder: (NSGradientType)gradientType 
           inRect: (NSRect)border 
           withClip: (NSRect)clip;

@end

#endif /* _GNUstep_H_GSDrawFunctions */
