/* 
   NSFontPrivate.h

   Private methods for the font class.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: September 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSFontPrivate
#define _GNUstep_H_NSFontPrivate

#include <gnustep/gui/NSFont.h>

@interface NSFont (GNUstepPrivate)

- (void)setFamilyName:(NSString *)familyName;
- (void)setFontName:(NSString *)fontName;
- (void)setPointSize:(float)value;
- (NSFontTraitMask)traits;
- (void)setTraits:(NSFontTraitMask)traits;
- (int)weight;
- (void)setWeight:(int)value;
- (NSString *)typeface;
- (void)setTypeface:(NSString *)str;

@end

#endif /* _GNUstep_H_NSFontPrivate */
