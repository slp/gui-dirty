/* 
   NSPrintOperation.h

   Description...

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

#ifndef _GNUstep_H_NSPrintOperation
#define _GNUstep_H_NSPrintOperation

#include <AppKit/stdappkit.h>
#include <AppKit/NSView.h>
#include <AppKit/NSPrintInfo.h>
#include <AppKit/NSPrintPanel.h>
#include <Foundation/NSData.h>

@interface NSPrintOperation : NSObject

{
  // Attributes
}

//
// Creating and Initializing an NSPrintOperation Object
//
+ (NSPrintOperation *)EPSOperationWithView:(NSView *)aView
				insideRect:(NSRect)rect
toData:(NSMutableData *)data;
+ (NSPrintOperation *)EPSOperationWithView:(NSView *)aView	
				insideRect:(NSRect)rect
toData:(NSMutableData *)data
				printInfo:(NSPrintInfo *)aPrintInfo;
+ (NSPrintOperation *)EPSOperationWithView:(NSView *)aView	
				insideRect:(NSRect)rect
toPath:(NSString *)path
				printInfo:(NSPrintInfo *)aPrintInfo;
+ (NSPrintOperation *)printOperationWithView:(NSView *)aView;
+ (NSPrintOperation *)printOperationWithView:(NSView *)aView
				   printInfo:(NSPrintInfo *)aPrintInfo;
- (id)initEPSOperationWithView:(NSView *)aView
		    insideRect:(NSRect)rect
toData:(NSMutableData *)data
		    printInfo:(NSPrintInfo *)aPrintInfo;
- (id)initWithView:(NSView *)aView
	 printInfo:(NSPrintInfo *)aPrintInfo;

//
// Setting the Print Operation
//
+ (NSPrintOperation *)currentOperation;
+ (void)setCurrentOperation:(NSPrintOperation *)operation;

//
// Determining the Type of Operation
//
- (BOOL)isEPSOperation;

//
// Controlling the User Interface
//
- (NSPrintPanel *)printPanel;
- (BOOL)showPanels;
- (void)setPrintPanel:(NSPrintPanel *)panel;
- (void)setShowPanels:(BOOL)flag;

//
// Managing the DPS Context
//
- (NSDPSContext *)createContext;
- (NSDPSContext *)context;
- (void)destroyContext;

//
// Page Information
//
- (int)currentPage;
- (NSPrintingPageOrder)pageOrder;
- (void)setPageOrder:(NSPrintingPageOrder)order;

//
// Running a Print Operation
//
- (void)cleanUpOperation;
- (BOOL)deliverResult;
- (BOOL)runOperation;

//
// Getting the NSPrintInfo Object
//
- (NSPrintInfo *)printInfo;
- (void)setPrintInfo:(NSPrintInfo *)aPrintInfo;

//
// Getting the NSView Object
//
- (NSView *)view;

@end

#endif // _GNUstep_H_NSPrintOperation
