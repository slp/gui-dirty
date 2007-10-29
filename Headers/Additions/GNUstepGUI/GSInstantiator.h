/* 
   GSNibCompatibility.h

   Copyright (C) 1997, 1999 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2002
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

#ifndef _GNUstep_H_GSInstantiator
#define _GNUstep_H_GSInstantiator

#include <Foundation/NSObject.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSNibConnector.h>

// instantiator
@protocol GSInstantiator
- (id) instantiateObject: (id)object;
@end

// informal protocol
@interface NSNibConnector (NibInstantiation)
- (void) instantiateWithInstantiator: (id<GSInstantiator>)instantiator;
@end

#endif /* _GNUstep_H_GSNibCompatibility */
