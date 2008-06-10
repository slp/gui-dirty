/* 
   NSSound.h

   Load, manipulate and play sounds

   Copyright (C) 2002 Free Software Foundation, Inc.

   Written by:  Enrico Sersale <enrico@imago.ro>
   Date: Jul 2002
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

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

#ifndef _GNUstep_H_NSSound
#define _GNUstep_H_NSSound

#include <Foundation/NSObject.h>
#include <Foundation/NSBundle.h>

@class NSArray;
@class NSData;
@class NSMutableData;
@class NSPasteboard;
@class NSString;
@class NSURL;

@interface NSSound : NSObject <NSCoding, NSCopying>
{		
  NSString *_name;
  NSString *_uniqueIdentifier;	
  BOOL _onlyReference;
  id _delegate;	
	
  NSData *_data;
  float _samplingRate;
  float _frameSize;
  long _dataLocation;
  long _dataSize;
  long _frameCount;
  int _channelCount;	
  int _dataFormat;
}

//
// Creating an NSSound 
//
- (id)initWithContentsOfFile:(NSString *)path byReference:(BOOL)byRef;
- (id)initWithContentsOfURL:(NSURL *)url byReference:(BOOL)byRef;
- (id)initWithData:(NSData *)data;
- (id)initWithPasteboard:(NSPasteboard *)pasteboard;

//
// Playing
//
- (BOOL)pause;
- (BOOL)play; 
- (BOOL)resume;
- (BOOL)stop;
- (BOOL)isPlaying;

//
// Working with pasteboards 
//
+ (BOOL)canInitWithPasteboard:(NSPasteboard *)pasteboard;
+ (NSArray *)soundUnfilteredPasteboardTypes;
- (void)writeToPasteboard:(NSPasteboard *)pasteboard;

//
// Working with delegates 
//
- (id)delegate;
- (void)setDelegate:(id)aDelegate;

//
// Naming Sounds 
//
+ (id)soundNamed:(NSString *)name;
+ (NSArray *)soundUnfilteredFileTypes;
- (NSString *)name;
- (BOOL)setName:(NSString *)aName;

@end

//
// Methods Implemented by the Delegate 
//
@interface NSObject (NSSoundDelegate)

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool;

@end


@interface NSBundle (NSSoundAdditions)

- (NSString *)pathForSoundResource:(NSString *)name;

@end

#endif // _GNUstep_H_NSSound

