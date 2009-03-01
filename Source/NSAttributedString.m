/** <title>NSAttributedStringAdditions</title>

   <abstract>Categories which add capabilities to NSAttributedString</abstract>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: July 1999
   Modifications: Fred Kiefer <FredKiefer@gmx.de>
   Date: June 2000
   
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

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSError.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSRange.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>

#include "AppKit/NSAttributedString.h"
#include "AppKit/NSDocumentController.h"
#include "AppKit/NSParagraphStyle.h"
#include "AppKit/NSPasteboard.h"
#include "AppKit/NSTextAttachment.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSFileWrapper.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSFontManager.h"
// For the colour name spaces
#include "AppKit/NSGraphics.h"

#include "GNUstepGUI/GSTextConverter.h"
#include "GSGuiPrivate.h"

/* Cache class pointers to avoid the expensive lookup by string. */ 
static Class dictionaryClass = nil;
static Class stringClass = nil;

/* A character set containing characters that separate words.  */
static NSCharacterSet *wordBreakCSet = nil;
/* A character set containing characters that are legal within words.  */
static NSCharacterSet *wordCSet = nil;
/* Character sets containing characters that are white space and
   not white space */
static NSCharacterSet *whiteCSet = nil;
static NSCharacterSet *nonWhiteCSet = nil;
/* A String containing the attachment character */
static NSString *attachmentString = nil;


/* This function initializes all the previous cached values. */
static void cache_init_real(void)
{
  NSMutableCharacterSet *m;
  NSCharacterSet *cset;
  unichar ch = NSAttachmentCharacter;
  
  /* Initializes Class pointer cache */
  dictionaryClass = [NSDictionary class];
  stringClass = [NSString class];
  
  /* Initializes wordBreakCSet */
  m = [NSMutableCharacterSet new];
  cset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  [m formUnionWithCharacterSet: cset];
  cset = [NSCharacterSet punctuationCharacterSet];
  [m formUnionWithCharacterSet: cset];
  cset = [NSCharacterSet controlCharacterSet];
  [m formUnionWithCharacterSet: cset];
  cset = [NSCharacterSet illegalCharacterSet];
  [m formUnionWithCharacterSet: cset];
  [m addCharactersInString: @"<>"];
  [m removeCharactersInString: @"_"];
  wordBreakCSet = [m copy];
  RELEASE (m);
  
  /* Initializes wordCSet */
  wordCSet = [[wordBreakCSet invertedSet] copy];

  /* Initializes white space and non-white space character sets */
  whiteCSet = [[NSCharacterSet whitespaceCharacterSet] copy];
  nonWhiteCSet = [[whiteCSet invertedSet] copy];
  
  /* Initializes attachmentString */
  attachmentString = [stringClass stringWithCharacters: &ch length: 1];
  RETAIN (attachmentString);  
}

/* This inline function calls cache_init_real () the first time it is
   invoked, and does nothing afterwards.  Thus we get both speed
   (cache_init is inlined and only compares a pointer to nil when the
   cache has been initialized) and limit memory consumption (we are
   not copying everywhere the real initialization code, which is in
   cache_real_init (), which is not inlined.).*/
static inline void cache_init(void)
{
  if (dictionaryClass == nil)
    {
      cache_init_real ();
    }
}

/* Return the class that handles format from the first bundle it finds */
static 
Class converter_bundles(NSString *format, BOOL producer)
{
  Class converter_class = Nil;
  NSEnumerator *benum;
  NSString *dpath;

  /* Find the bundle paths */
  benum = [NSStandardLibraryPaths() objectEnumerator];
  while ((dpath = [benum nextObject]))
    {
      NSEnumerator *direnum;
      NSString *path;
      dpath = [dpath stringByAppendingPathComponent: @"Bundles"];
      dpath = [dpath stringByAppendingPathComponent: @"TextConverters"];
      if ([[NSFileManager defaultManager] fileExistsAtPath: dpath])
        direnum = [[NSFileManager defaultManager] enumeratorAtPath: dpath];
      else
        direnum = nil;
      while (direnum && (path = [direnum nextObject]))
	{
	  Class bclass;
	  NSString *full_path;
	  NSBundle *aBundle;
	  if ([[path pathExtension] isEqual: @"bundle"] == NO)
	    continue;
	  full_path = [dpath stringByAppendingPathComponent: path];
	  aBundle = [NSBundle bundleWithPath: full_path];
	  if (aBundle && ((bclass = [aBundle principalClass])))
	    {
	      if ([bclass respondsToSelector: 
			    @selector(classForFormat: producer: )])
		{
		  converter_class = (Class)[bclass classForFormat: format
						   producer: producer];
		}
	      else
		{
		  NSString *converter_name;
		  if (producer)
		    {
		      converter_name
			= [format stringByAppendingString: @"Producer"];
		    }
		  else
		    {
		      converter_name
			= [format stringByAppendingString: @"Consumer"];
		    }
		  converter_class = [aBundle classNamed: converter_name];
		}
	    }	 
	  if (converter_class)
	    break;
	}
      if (converter_class)
	break;
    }
  return converter_class;
}

/*
  Return a suitable converter for the text format supplied as argument.
  If producer is YES a class capable of writting that format is returned,
  otherwise a class able to read the format is returned.
 */
static Class converter_class(NSString *format, BOOL producer)
{
  static NSMutableDictionary *p_classes = nil;
  static NSMutableDictionary *c_classes = nil;
  Class found;

  if (producer)
    {
      if (p_classes == nil)
	p_classes = [NSMutableDictionary new];

      found = [p_classes objectForKey: format];
      if (found == Nil)
        {
	  found = converter_bundles(format, producer);
	  if (found != Nil)
	    NSDebugLog(@"Found converter %@ for format %@", found, format);
	  if (found != Nil)
	    [p_classes setObject: found forKey: format];
	}
      return found;
    }
  else 
    {
      if (c_classes == nil)
	c_classes = [NSMutableDictionary new];

      found = [c_classes objectForKey: format];
      if (found == Nil)
        {
	  found = converter_bundles(format, producer);
	  if (found != Nil)
	    NSDebugLog(@"Found converter %@ for format %@", found, format);
	  if (found != Nil)
	    [c_classes setObject: found forKey: format];
	}
      return found;
    }

  return Nil;
}

static inline NSError*
create_error(int code, NSString* desc)
{
  return [NSError errorWithDomain: @"NSAttributedString"
                  code: code 
                  userInfo: [NSDictionary 
                                dictionaryWithObjectsAndKeys: desc,
                                NSLocalizedDescriptionKey, nil]];
}

@implementation NSAttributedString (AppKit)

+ (NSArray *) textFileTypes
{
  // FIXME
  return [self textUnfilteredFileTypes];
}

+ (NSArray *) textPasteboardTypes
{
  // FIXME
  return [self textUnfilteredPasteboardTypes];
}

+ (NSArray *) textUnfilteredFileTypes
{
  return [NSArray arrayWithObjects: @"txt",  @"rtf", @"rtfd", @"html", nil];
}

+ (NSArray *) textUnfilteredPasteboardTypes
{
  return [NSArray arrayWithObjects: NSStringPboardType, NSRTFPboardType, 
		  NSRTFDPboardType, NSHTMLPboardType, nil];
}

+ (NSArray *) textTypes
{
  // FIXME
  return [self textUnfilteredTypes];
}

+ (NSArray *) textUnfilteredTypes
{
  return [NSArray arrayWithObjects: @"public.plain-text",
		  @"public.rtf",
		  @"com.apple.rtfd",
		  @"public.html",
		  /*
		  @"public.xml",
		  @"com.apple.webarchive",
		  @"com.microsoft.word.doc",
		  @"com.microsoft.word.wordml",
		  @"org.openxmlformats.wordprocessingml.document",
		  @"org.oasis-open.opendocument.text",
		  @"com.apple.traditional-mac-plain-text",
		  */
		  nil];
}

+ (NSAttributedString *) attributedStringWithAttachment: 
                                            (NSTextAttachment *)attachment
{
  NSDictionary *attributes;

  cache_init ();

  attributes = [dictionaryClass dictionaryWithObject: attachment
				forKey: NSAttachmentAttributeName];
  
  return AUTORELEASE ([[self alloc] initWithString: attachmentString
				    attributes: attributes]);
}

- (BOOL) containsAttachments
{
  NSRange aRange;

  cache_init ();

  aRange = [[self string] rangeOfString: attachmentString];

  if (aRange.length > 0)
    {
      return YES;
    }
  else
    {
      return NO;
    }
}

- (NSDictionary *) fontAttributesInRange: (NSRange)range
{
  NSDictionary	*all;
  static SEL	sel = 0;
  IMP		objForKey;
  id		objects[8];
  id		keys[8];
  int		count = 0;

  if (NSMaxRange(range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -fontAttributesInRange: "];
    }
  all = [self attributesAtIndex: range.location
	      effectiveRange: &range];

  if (sel == 0)
    {
      sel = @selector (objectForKey: );
    }
  objForKey = [all methodForSelector: sel];
  
#define NSATT_GET_ATTRIBUTE(attribute) \
  keys[count] = attribute; \
  objects[count] = (*objForKey) (all, sel, keys[count]); \
  if (objects[count] != nil) count++; 

  NSATT_GET_ATTRIBUTE (NSFontAttributeName);
  NSATT_GET_ATTRIBUTE (NSForegroundColorAttributeName);
  NSATT_GET_ATTRIBUTE (NSBackgroundColorAttributeName);
  NSATT_GET_ATTRIBUTE (NSUnderlineStyleAttributeName);
  NSATT_GET_ATTRIBUTE (NSSuperscriptAttributeName);
  NSATT_GET_ATTRIBUTE (NSBaselineOffsetAttributeName);
  NSATT_GET_ATTRIBUTE (NSKernAttributeName);
  NSATT_GET_ATTRIBUTE (NSLigatureAttributeName);

#undef NSATT_GET_ATTRIBUTE

  cache_init ();
  
  return [dictionaryClass dictionaryWithObjects: objects
			  forKeys: keys
			  count: count];
}

- (NSDictionary*) rulerAttributesInRange: (NSRange)range
{
  id style;

  cache_init ();

  if (NSMaxRange (range) > [self length])
    {
      [NSException raise: NSRangeException
		   format: @"RangeError in method -rulerAttributesInRange: "];
    }
  
  style = [self attribute: NSParagraphStyleAttributeName
		atIndex: range.location
		effectiveRange: &range];

  if (style != nil)
    {
      return [dictionaryClass dictionaryWithObject: style
			      forKey: NSParagraphStyleAttributeName];
    }
  
  return [dictionaryClass dictionary];
}

- (NSUInteger) lineBreakByHyphenatingBeforeIndex: (NSUInteger)location
				     withinRange: (NSRange)aRange
{
  // FIXME
  return [self lineBreakBeforeIndex: location
                      withinRange: aRange];
}

- (NSUInteger) lineBreakBeforeIndex: (NSUInteger)location
			withinRange: (NSRange)aRange
{
  NSString *str = [self string];
  unsigned length = [str length];
  NSRange scanRange;
  NSRange startRange;
  
  cache_init ();

  if (NSMaxRange (aRange) > length || location > length)
    {
      [NSException raise: NSRangeException
	format: @"RangeError in method -lineBreakBeforeIndex: withinRange: "];
    }

  if (!NSLocationInRange (location, aRange))
    {
      return NSNotFound;
    }
  
  scanRange = NSMakeRange (aRange.location, location - aRange.location);
  startRange = [str rangeOfCharacterFromSet: wordBreakCSet
		    options: NSBackwardsSearch | NSLiteralSearch
		    range: scanRange];
  while (startRange.length > 0 && startRange.location > 0
    && [str characterAtIndex: startRange.location] == '\''
    && [wordCSet characterIsMember: 
      [str characterAtIndex: startRange.location-1]])
    {
      location = startRange.location - 1;
      scanRange = NSMakeRange (0, location);
      startRange = [str rangeOfCharacterFromSet: wordBreakCSet
	options: NSBackwardsSearch|NSLiteralSearch range: scanRange];
    }
  if (startRange.length == 0)
    {
      return NSNotFound;
    }
  else
    {
      return NSMaxRange (startRange);
    }
}

- (NSRange) doubleClickAtIndex: (unsigned)location
{
  NSString *str = [self string];
  unsigned length = [str length];
  NSRange  scanRange;
  NSRange  startRange;
  NSRange  endRange;
  NSCharacterSet *breakCSet;

  cache_init ();

  if (location > length)
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -doubleClickAtIndex: "];
    }

  /*
   * Double clicking on a white space character selects all surrounding
   * white space. Otherwise, if the location lies between words, a double
   * click selects only the character actually clicked on.
   */
  if ([whiteCSet characterIsMember: [str characterAtIndex: location]])
    {
      breakCSet = nonWhiteCSet;
    }
  else if ([wordBreakCSet characterIsMember: [str characterAtIndex: location]])
    {
      if (location == 0 || location == length - 1
	|| [str characterAtIndex: location] != '\''
	|| ! [wordCSet characterIsMember: [str characterAtIndex: location - 1]]
	|| ! [wordCSet characterIsMember: [str characterAtIndex: location + 1]])
	{
	  return NSMakeRange(location, 1);
	}
      breakCSet = wordBreakCSet;
    }
  else
    {
      breakCSet = wordBreakCSet;
    }

  scanRange = NSMakeRange (0, location);
  startRange = [str rangeOfCharacterFromSet: breakCSet
				    options: NSBackwardsSearch|NSLiteralSearch
				      range: scanRange];
  /*
   * Don't treat single quotes embedded within a word as break characters.
   * Note: The loop condition is always false when breakCSet==nonWhiteSetCSet.
   */
  while (startRange.length > 0
    && startRange.location > 0 && startRange.location < length - 1
    && [str characterAtIndex: startRange.location] == '\''
    && [wordCSet characterIsMember: 
      [str characterAtIndex: startRange.location - 1]]
    && [wordCSet characterIsMember: 
      [str characterAtIndex: startRange.location + 1]])
    {
      location = startRange.location - 1;
      scanRange = NSMakeRange (0, location);
      startRange = [str rangeOfCharacterFromSet: wordBreakCSet
	options: NSBackwardsSearch|NSLiteralSearch range: scanRange];
    }

  scanRange = NSMakeRange (location, length - location);
  endRange = [str rangeOfCharacterFromSet: breakCSet
				  options: NSLiteralSearch
				    range: scanRange];
  /*
   * Don't treat single quotes embedded within a word as break characters.
   * Note: The loop condition is always false when breakCSet==nonWhiteSetCSet.
   */
  while (endRange.length > 0
    && endRange.location > 0 && endRange.location < length - 1
    && [str characterAtIndex: endRange.location] == '\''
    && [wordCSet characterIsMember: 
      [str characterAtIndex: endRange.location - 1]]
    && [wordCSet characterIsMember: 
      [str characterAtIndex: endRange.location + 1]])
    {
      location = endRange.location + 1;
      scanRange = NSMakeRange (location, length - location);
      endRange = [str rangeOfCharacterFromSet: wordBreakCSet
	options: NSLiteralSearch range: scanRange];
    }

  if (startRange.length == 0)
    {
      location = 0;
    }
  else
    {
      location = NSMaxRange (startRange);
    }

  if (endRange.length == 0)
    {
      length = length - location;
    }
  else
    {
      length = endRange.location - location;
    }
  return NSMakeRange (location, length);
}

- (unsigned) nextWordFromIndex: (unsigned)location
		       forward: (BOOL)isForward
{
  NSString *str = [self string];
  unsigned length = [str length];
  NSRange range;

  if (location > length)
    {
      [NSException raise: NSRangeException
	format: @"RangeError in method -nextWordFromIndex: forward: "];
    }

  /* Please note that we consider ' a valid word separator.  This is
     what Emacs does and is perfectly correct.  If you want to change
     the word separators, the right approach is to use a different
     character set for word separators - the following code should be
     unchanged whatever characters you use to separate words.  */
  cache_init ();

  if (isForward)
    {
      /* What we want to do is: move forward to the next chunk of word
	 separator characters, skip them all, and return the location
	 just after them.  */

      if (location == length)
	{
	  return length;
	}

      /* Move forward to the next word-separator.  */
      range = NSMakeRange (location, length - location);
      range = [str rangeOfCharacterFromSet: wordBreakCSet
		                   options: NSLiteralSearch
                          	     range: range];
      if (range.location == NSNotFound)
	{
	  return length;
	}
      /* rangeOfCharacterFromSet: options: range: only returns the range
	 of the first word-separator character ... we want to skip
	 them all!  So we need to search again, this time for the
	 first non-word-separator character, and return the first such
	 character.  */
      range = NSMakeRange (range.location, length - range.location);
      range = [str rangeOfCharacterFromSet: wordCSet
		                   options: NSLiteralSearch
                          	     range: range];
      if (range.location == NSNotFound)
	{
	  return length;
	}

      return range.location;
    }
  else
    {
      /* What we want to do is: move backward to the next chunk of
	 non-word separator characters, skip them all, and return the
	 location just at the beginning of the chunk.  */

      if (location == 0)
	{
	  return 0;
	}

      /* Move backward to the next non-word separator.  */
      range = NSMakeRange (0, location);
      range = [str rangeOfCharacterFromSet: wordCSet
		                   options: NSBackwardsSearch | NSLiteralSearch
		                     range: range];
      if (range.location == NSNotFound)
	{
	  return 0;
	}

      /* rangeOfCharacterFromSet: options: range: only returns the range
	 of the first non-word-separator character ... we want to skip
	 them all!  So we need to search again, this time for the
	 first word-separator character. */
      range = NSMakeRange (0, range.location);
      range = [str rangeOfCharacterFromSet: wordBreakCSet
		                   options: NSBackwardsSearch | NSLiteralSearch
                          	     range: range];
      if (range.location == NSNotFound)
	{
	  return 0;
	}
      
      return NSMaxRange (range);
    }
}

- (id) initWithRTFDFileWrapper: (NSFileWrapper *)wrapper
            documentAttributes: (NSDictionary **)dict
{
  NSAttributedString *new;

  if (wrapper == nil)
    {
      RELEASE (self);
      return nil;
    }

  new = [converter_class(@"RTFD", NO) 
			parseFile: wrapper
			documentAttributes: dict
			class: [self class]];
  // We do not return self but the newly created object
  RELEASE (self);
  return RETAIN (new); 
}

- (id) initWithRTFD: (NSData*)data
 documentAttributes: (NSDictionary**)dict
{
  NSAttributedString *new;

  if (data == nil)
    {
      RELEASE (self);
      return nil;
    }

  new = [converter_class(@"RTFD", NO)
			parseData: data
			documentAttributes: dict
			class: [self class]];
  // We do not return self but the newly created object
  RELEASE (self);
  return RETAIN (new); 
}

- (id) initWithRTF: (NSData *)data
  documentAttributes: (NSDictionary **)dict
{
  NSAttributedString *new;

  if (data == nil)
    {
      RELEASE (self);
      return nil;
    }

  new = [converter_class(@"RTF", NO) 
			parseData: data
			documentAttributes: dict
			class: [self class]];
  // We do not return self but the newly created object
  RELEASE (self);
  return RETAIN (new); 
}

- (id) initWithHTML: (NSData *)data
 documentAttributes: (NSDictionary **)dict
{
  return [self initWithHTML: data
	       baseURL: nil
	       documentAttributes: dict];
}

- (id) initWithHTML: (NSData *)data
            baseURL: (NSURL *)base
 documentAttributes: (NSDictionary **)dict
{
  NSDictionary *options = nil;

  if (base != nil)
    options = [NSDictionary dictionaryWithObject: base
					  forKey: NSBaseURLDocumentOption];

  return [self initWithHTML: data
		    options: options
               documentAttributes: dict];
}

- (id) initWithHTML: (NSData *)data
            options: (NSDictionary *)options
 documentAttributes: (NSDictionary **)dict
{
  if (data == nil)
    {
      RELEASE (self);
      return nil;
    }

  // FIXME: Not implemented
  return self;
}

- (id) initWithDocFormat: (NSData *)data
      documentAttributes: (NSDictionary **)dict
{
  NSAttributedString *new;

  if (data == nil)
    {
      RELEASE (self);
      return nil;
    }

  new = [converter_class(@"DOC", NO)
			parseData: data
			documentAttributes: dict
			class: [self class]];
  // We do not return self but the newly created object
  RELEASE (self);
  return RETAIN (new); 
}

- (id) initWithData: (NSData *)data
            options: (NSDictionary *)options
 documentAttributes: (NSDictionary **)dict
              error: (NSError **)error
{
  NSString *type = [options objectForKey: NSDocumentTypeDocumentOption];

  if (data == nil)
    {
      *error = create_error(0, NSLocalizedString(@"No data specified for data loading.", 
                                                 @"Error description"));
      RELEASE(self);
      return nil;
    }

  if (type == nil)
    {
      // FIXME: try to determine type
      *error = create_error(0, NSLocalizedString(@"No type specified for data.", 
                                                 @"Error description"));
      RELEASE(self);
      return nil;
    }

  if ([type isEqualToString: NSDocFormatTextDocumentType])
    {
      return [self initWithDocFormat: data
                   documentAttributes: dict];
    }
  else if ([type isEqualToString: NSHTMLTextDocumentType]
           || [type isEqualToString: @"public.html"]
           || [type isEqualToString: @"html"])
    {
      return [self initWithHTML: data
                   options: options
                   documentAttributes: dict];
    }
  else if ([type isEqualToString: NSRTFDTextDocumentType]
           || [type isEqualToString: @"com.apple.rtfd"]
           || [type isEqualToString: @"rtfd"])
    {
      return [self initWithRTFD: data
                   documentAttributes: dict];
    }
  else if ([type isEqualToString: NSRTFTextDocumentType]
           || [type isEqualToString: @"public.rtf"]
           || [type isEqualToString: @"rtf"])
    {
      return [self initWithRTF: data
                   documentAttributes: dict];
    }
  else if ([type isEqualToString: NSPlainTextDocumentType]
           || [type isEqualToString: @"public.plain-text"]
           || [type isEqualToString: @"text"])
    {
      NSStringEncoding encoding = [[options objectForKey: @"CharacterEncoding"] 
				      intValue];
      NSDictionary *defaultAttrs = [options objectForKey: @"DefaultAttributes"];
      NSString *str = [[NSString alloc] initWithData: data 
                                        encoding: encoding];

      self = [self initWithString: str
                   attributes: defaultAttrs];
      RELEASE(str);
      return self;
    }

  *error = create_error(0, NSLocalizedString(@"Could not load data.", 
                                             @"Error description"));
  RELEASE(self);
  return nil;
}

- (id) initWithPath: (NSString *)path
 documentAttributes: (NSDictionary **)dict
{
  BOOL isDir = NO;

  if (path == nil)
    {
      RELEASE (self);
      return nil;
    }

  if ([[NSFileManager defaultManager]
          fileExistsAtPath: path isDirectory: &isDir] && isDir)
    {
      // FIXME: This expects the file to be RTFD
      NSFileWrapper *fw;

      fw = [[NSFileWrapper alloc] initWithPath: path];
      AUTORELEASE (fw);
  
      return [self initWithRTFDFileWrapper: fw documentAttributes: dict];
    }
  else
   {
     return [self initWithURL:  [NSURL fileURLWithPath: path]
		  documentAttributes: dict];
   }
}

- (id) initWithURL: (NSURL *)url 
documentAttributes: (NSDictionary **)dict
{
  NSError *error = nil;
  NSDictionary *options = [NSDictionary dictionaryWithObject: [url baseURL]
                                        forKey: NSBaseURLDocumentOption];

  return [self initWithURL: url
               options: options
               documentAttributes: dict
               error: &error];
}

- (id) initWithURL: (NSURL *)url
           options: (NSDictionary *)options
documentAttributes: (NSDictionary **)dict
             error: (NSError **)error
{
  NSData *data = [url resourceDataUsingCache: YES];

  if (data == nil)
    {
      *error = create_error(0, NSLocalizedString(@"Could not load data from URL.", 
                                                 @"Error description"));
      RELEASE(self);
      return nil;
    }

  // Pass on baseURL
  if (options == nil)
    options = [NSDictionary dictionaryWithObject: [url baseURL]
					  forKey: NSBaseURLDocumentOption];
  else if ([options objectForKey: NSBaseURLDocumentOption] == nil)
    {
      options = AUTORELEASE([options mutableCopy]);
      [(NSMutableDictionary*)options setObject: [url baseURL]
                             forKey: NSBaseURLDocumentOption];
    }

  return [self initWithData: data
               options: options
               documentAttributes: dict
               error: error];
}

- (NSData *) RTFFromRange: (NSRange)range
       documentAttributes: (NSDictionary *)dict
{
  return [converter_class(@"RTF", YES) 
			 produceDataFrom: 
			   [self attributedSubstringFromRange: range]
			 documentAttributes: dict];
}

- (NSData *) RTFDFromRange: (NSRange)range
	documentAttributes: (NSDictionary *)dict
{
  return [converter_class(@"RTFD", YES)  
			 produceDataFrom: 
			   [self attributedSubstringFromRange: range]
			 documentAttributes: dict];
}

- (NSFileWrapper *) RTFDFileWrapperFromRange: (NSRange)range
			  documentAttributes: (NSDictionary *)dict
{
  return [converter_class(@"RTFD", YES)
			 produceFileFrom: 
			   [self attributedSubstringFromRange: range]
			 documentAttributes: dict];
}

- (NSData *) docFormatFromRange: (NSRange)range
             documentAttributes: (NSDictionary *)dict
{
  // FIXME
  return nil;
}

- (NSData *) dataFromRange: (NSRange)range
        documentAttributes: (NSDictionary *)dict
                     error: (NSError **)error
{
  NSString *type = [dict objectForKey: NSDocumentTypeDocumentOption];

  if (type == nil)
    {
      *error = create_error(0, NSLocalizedString(@"No type specified for data.", 
                                                 @"Error description"));
      return nil;
    }

  if ([type isEqualToString: NSDocFormatTextDocumentType])
    {
      return [self docFormatFromRange: range
                   documentAttributes: dict];
    }
  else if ([type isEqualToString: NSHTMLTextDocumentType])
    {
      // FIXME
    }
  else if ([type isEqualToString: NSRTFDTextDocumentType])
    {
      return [self RTFDFromRange: range
                   documentAttributes: dict];
    }
  else if ([type isEqualToString: NSRTFTextDocumentType])
    {
      return [self RTFFromRange: range
                   documentAttributes: dict];
    }
  else if ([type isEqualToString: NSPlainTextDocumentType])
    {
      NSStringEncoding encoding = [[dict objectForKey: @"CharacterEncoding"] 
                                      intValue];
      
      if (!encoding)
        encoding = [NSString defaultCStringEncoding];
      return [[self string] dataUsingEncoding: encoding];
    }

  *error = create_error(0, NSLocalizedString(@"Could not create data for type.", 
                                             @"Error description"));
  return nil;
}

- (NSFileWrapper *) fileWrapperFromRange: (NSRange)range
                      documentAttributes: (NSDictionary *)dict
                                   error: (NSError **)error
{
  NSFileWrapper *wrapper;
  NSData *data;

  // FIXME: This wont work for directory bundles.
  data = [self dataFromRange: range
	  documentAttributes: dict
		       error: error];
  if (data != nil)
    {
      wrapper = [[NSFileWrapper alloc] initRegularFileWithContents: data];
      return AUTORELEASE(wrapper);
    }

  if (*error == nil)
      *error = create_error(0, NSLocalizedString(@"Could not create data for type.",
                                                 @"Error description"));

  return nil;
}

- (NSRange) itemNumberInTextList: (NSTextList *)list
                         atIndex: (unsigned)location
{
  // FIXME
  return NSMakeRange(NSNotFound, 0);
}

- (NSRange) rangeOfTextBlock: (NSTextBlock *)block
                     atIndex: (unsigned)location
{
  // FIXME
  return NSMakeRange(NSNotFound, 0);
}

- (NSRange) rangeOfTextList: (NSTextList *)list
                    atIndex: (unsigned)location
{
  // FIXME
  return NSMakeRange(NSNotFound, 0);
}

- (NSRange) rangeOfTextTable: (NSTextTable *)table
                     atIndex: (unsigned)location
{
  // FIXME
  return NSMakeRange(NSNotFound, 0);
}

@end

@implementation NSMutableAttributedString (AppKit)
- (void) superscriptRange: (NSRange)range
{
  id value;
  int sValue;
  NSRange effRange;
  
  if (NSMaxRange (range) > [self length])
    {
      [NSException raise: NSRangeException
		   format: @"RangeError in method -superscriptRange: "];
    }
  
  // We take the value from the first character and use it for the whole range
  value = [self attribute: NSSuperscriptAttributeName
		  atIndex: range.location
	   effectiveRange: &effRange];

  if (value != nil)
    {
      sValue = [value intValue] + 1;
    }
  else
    {
      sValue = 1;
    }
  

  [self addAttribute: NSSuperscriptAttributeName
	value: [NSNumber numberWithInt: sValue]
	range: range];
}

- (void) subscriptRange: (NSRange)range
{
  id value;
  int sValue;
  NSRange effRange;

  if (NSMaxRange (range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -subscriptRange: "];
    }

  // We take the value form the first character and use it for the whole range
  value = [self attribute: NSSuperscriptAttributeName
		atIndex: range.location
		effectiveRange: &effRange];

  if (value != nil)
    {
      sValue = [value intValue] - 1;
    }
  else
    {
      sValue = -1;
    }

  [self addAttribute: NSSuperscriptAttributeName
	value: [NSNumber numberWithInt: sValue]
	range: range];
}

- (void) unscriptRange: (NSRange)range
{
  if (NSMaxRange (range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -unscriptRange: "];
    }

  [self removeAttribute: NSSuperscriptAttributeName
	range: range];
}

- (void) applyFontTraits: (NSFontTraitMask)traitMask
		   range: (NSRange)range
{
  NSFont *font;
  unsigned loc = range.location;
  NSRange effRange;
  NSFontManager *fm = [NSFontManager sharedFontManager];

  if (NSMaxRange (range) > [self length])
    {
      [NSException raise: NSRangeException
		   format: @"RangeError in method -applyFontTraits: range: "];
    }

  while (loc < NSMaxRange (range))
    {
      font = [self attribute: NSFontAttributeName
		   atIndex: loc
		   effectiveRange: &effRange];

      if (font != nil)
	{
	  font = [fm convertFont: font
		     toHaveTrait: traitMask];

	  if (font != nil)
	    {
	      [self addAttribute: NSFontAttributeName
		    value: font
		    range: NSIntersectionRange (effRange, range)];
	    }
	}
      loc = NSMaxRange(effRange);
    }
}

- (void) setAlignment: (NSTextAlignment)alignment
		range: (NSRange)range
{
  id		value;
  unsigned	loc = range.location;
  
  if (NSMaxRange(range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -setAlignment: range: "];
    }

  while (loc < NSMaxRange(range))
    {
      BOOL	copiedStyle = NO;
      NSRange	effRange;
      NSRange	newRange;

      value = [self attribute: NSParagraphStyleAttributeName
		      atIndex: loc
	       effectiveRange: &effRange];
      newRange = NSIntersectionRange (effRange, range);

      if (value == nil)
	{
	  value = [NSMutableParagraphStyle defaultParagraphStyle];
	}
      else
	{
	  value = [value mutableCopy];
	  copiedStyle = YES;
	}

      [value setAlignment: alignment];

      [self addAttribute: NSParagraphStyleAttributeName
		   value: value
		   range: newRange];
      if (copiedStyle == YES)
	{
	  RELEASE(value);
	}
      loc = NSMaxRange (effRange);
    }
}

- (void) fixAttributesInRange: (NSRange)range
{
  [self fixFontAttributeInRange: range];
  [self fixParagraphStyleAttributeInRange: range];
  [self fixAttachmentAttributeInRange: range];
}

static NSString *lastFont = nil;
static NSCharacterSet *lastSet = nil;
static NSMutableDictionary *cachedCSets = nil;

- (NSFont*)_substituteFontWithName: (NSString*)fontName 
                              font: (NSFont*)baseFont
{
  return [[NSFontManager sharedFontManager] convertFont: baseFont 
                                            toFace: fontName];
}

- (NSFont*)_substituteFontFor: (unichar)uchar 
                         font: (NSFont*)baseFont 
                     fromList: (NSArray *)fonts
{
  unsigned int count;
  unsigned int i;
      
  if (cachedCSets == nil)
    {
      cachedCSets = [NSMutableDictionary new];
    }

  count = [fonts count];
  for (i = 0; i < count; i++)
    {
      NSFont *newFont;
      NSString *fName;
      NSCharacterSet *newSet;

      fName = [fonts objectAtIndex: i];
      newSet = [cachedCSets objectForKey: fName];
      if (newSet == nil)
        { 
          newFont = [self _substituteFontWithName: fName font: baseFont];
          newSet = [newFont coveredCharacterSet];
          if ((newSet != nil) && ([cachedCSets count] < 10))
            {
              [cachedCSets setObject: newSet forKey: fName];
            }
        } 
      else
        {
          newFont = nil;
        }
      
      if ([newSet characterIsMember: uchar])
        {
          ASSIGN(lastFont, fName);
          ASSIGN(lastSet, newSet);
          if (newFont != nil)
            {
              return newFont;
            }
          else
            {
              return [self _substituteFontWithName: fName font: baseFont];      
            }
        }
    }

  return nil;
}

- (NSFont*)_substituteFontFor: (unichar)uchar font: (NSFont*)baseFont
{
  NSFont *subFont;

  // Caching one font may lead to the selected substitution font not being
  // from the prefered list, although there is one there with this character.
  if (lastSet && [lastSet characterIsMember: uchar])
    {
      return [self _substituteFontWithName: lastFont font: baseFont];
    }

  subFont = [self _substituteFontFor: uchar 
                  font: baseFont 
                  fromList: [NSFont preferredFontNames]];
  if (subFont != nil)
    {
      return subFont;
    }

  subFont = [self _substituteFontFor: uchar font: baseFont fromList: 
                      [[NSFontManager sharedFontManager] availableFonts]];
  if (subFont != nil)
    {
      return subFont;
    }
  
  return nil;
}

- (void) fixFontAttributeInRange: (NSRange)range
{
  NSString *string;
  NSFont *font;
  NSCharacterSet *charset = nil;
  NSRange fontRange = NSMakeRange(NSNotFound, 0);
  unsigned int i;
  unsigned int lastMax;
  unsigned int start;
  unichar chars[64];
  CREATE_AUTORELEASE_POOL(pool);
  
  if (NSMaxRange (range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -fixFontAttributeInRange: "];
    }
  // Check for each character if it is supported by the 
  // assigned font
  
  /*
  Note that this needs to be done on a script basis. Per-character checks
  are difficult to do at all, don't give reasonable results, and would have
  really poor performance.
  */
  string = [self string];
  lastMax = range.location;
  start = lastMax;
  for (i = range.location; i < NSMaxRange(range); i++)
    {
      unichar uchar;
  
      if (i >= lastMax)
        {
          unsigned int dist;
          
          start = lastMax;
          dist = MIN(64, NSMaxRange(range) - start);
          lastMax = start + dist;
          [string getCharacters: chars range: NSMakeRange(start, dist)];
        }
      uchar = chars[i - start];
      
      if (!NSLocationInRange(i, fontRange))
        {
          font = [self attribute: NSFontAttributeName
                       atIndex: i
                       effectiveRange: &fontRange];
          charset = [font coveredCharacterSet];
        }
      
      if (charset != nil && ![charset characterIsMember: uchar]
          && (uchar > 31))
        {
          // Find a replacement font
          NSFont *subFont;
          
          subFont = [self _substituteFontFor: uchar font: font];
          if (subFont != nil)
            {
              // Set substitution font permanently
              [self addAttribute: NSFontAttributeName
                    value: subFont
                    range: NSMakeRange(i, 1)];
            }
        }
    }
  
  RELEASE(pool);
}

- (void) fixParagraphStyleAttributeInRange: (NSRange)range
{
  NSString *str = [self string];
  unsigned loc = range.location;
  NSRange r;

  if (NSMaxRange (range) > [self length])
    {
      [NSException raise: NSRangeException
	format: @"RangeError in method -fixParagraphStyleAttributeInRange: "];
    }

  while (loc < NSMaxRange (range))
    {
      NSParagraphStyle	*style;
      NSRange		found;
      unsigned		end;

      /* Extend loc to take in entire paragraph if necessary.  */
      r = [str lineRangeForRange: NSMakeRange (loc, 1)];
      end = NSMaxRange (r);

      /* Get the style in effect at the paragraph start.  */
      style = [self attribute: NSParagraphStyleAttributeName
		    atIndex: r.location
		    longestEffectiveRange: &found
		    inRange: r];
      if (style == nil)
	{
	  /* No style found at the beginning of paragraph.  found is
             the range without the style set.  */
	  if ((NSMaxRange (found) + 1) < end)
	    {
	      /* There is a paragraph style for part of the paragraph. Set
	      this style for the entire paragraph.

	      Since NSMaxRange(found) + 1 is outside the longest effective
	      range for the nil style, it must be non-nil.
	      */
	      style = [self attribute: NSParagraphStyleAttributeName
			      atIndex: NSMaxRange(found) + 1
			      effectiveRange: NULL];
	      [self addAttribute: NSParagraphStyleAttributeName
		    value: style
		    range: r];
	    }
	  else
	    {
	      /* All the paragraph without a style ... too bad, fixup
		 the whole paragraph using the default paragraph style.  */
	      [self addAttribute: NSParagraphStyleAttributeName
		    value: [NSParagraphStyle defaultParagraphStyle]
		    range: r];
	    }
	}
      else
	{
	  if (NSMaxRange (found) < end)
	    {
	      /* Not the whole paragraph has the same style ... add
		 the style found at the beginning to the remainder of
		 the paragraph.  */
	      found.location = NSMaxRange (found);
	      found.length = end - found.location;
	      [self addAttribute: NSParagraphStyleAttributeName
		    value: style
		    range: found];
	    }
	}
      
      /* Move on to the next paragraph.  */
      loc = end;
    }
}

- (void) fixAttachmentAttributeInRange: (NSRange)range
{
  NSString *string = [self string];
  unsigned location = range.location;
  unsigned end = NSMaxRange (range);

  cache_init ();

  if (end > [self length])
    {
      [NSException raise: NSRangeException
	format: @"RangeError in method -fixAttachmentAttributeInRange: "];
    }

  // Check for attachments with the wrong character
  while (location < end)
    {
      NSDictionary	*attr;
      NSRange		eRange;

      attr = [self attributesAtIndex: location  effectiveRange: &eRange];
      if ([attr objectForKey: NSAttachmentAttributeName] != nil)
	{
	  unichar	buf[eRange.length];
	  unsigned	pos = 0;
	  unsigned	start = eRange.location;

	  // Leave only one character with the attachment
	  [string getCharacters: buf  range: eRange];
	  while (pos < eRange.length && buf[pos] != NSAttachmentCharacter)
	    pos++;
	  if (pos)
	    [self removeAttribute: NSAttachmentAttributeName
		  range: NSMakeRange (start, pos)];
	  pos++;
	  if (pos < eRange.length)
	    [self removeAttribute: NSAttachmentAttributeName
		  range: NSMakeRange (start + pos, eRange.length - pos)];
	}
      location = NSMaxRange (eRange);
    }

  // Check for attachment characters without attachments
  location = range.location;
  while (location < end)
    {
      NSRange eRange = [string rangeOfString: attachmentString
			      options: NSLiteralSearch 
			      range: NSMakeRange (location, end - location)];
      NSTextAttachment *attachment;

      if (!eRange.length)
        break;

      attachment = [self attribute: NSAttachmentAttributeName
			 atIndex: eRange.location
			 effectiveRange: NULL];

      if (attachment == nil)
        {
          [self deleteCharactersInRange: NSMakeRange (eRange.location, 1)];
          eRange.length--;
          end--;
        }

      location = NSMaxRange (eRange);
    }
}

- (void) updateAttachmentsFromPath: (NSString *)path
{
  NSString *string = [self string];
  unsigned location = 0;
  unsigned end = [string length];

  cache_init ();

  while (location < end)
    {
      NSRange range = [string rangeOfString: attachmentString
			      options: NSLiteralSearch 
			      range: NSMakeRange (location, end - location)];
      NSTextAttachment *attachment;
      NSFileWrapper *fileWrapper;

      if (!range.length)
	break;

      attachment = [self attribute: NSAttachmentAttributeName
			 atIndex: range.location
			 effectiveRange: NULL];
      fileWrapper = [attachment fileWrapper];

      // FIXME: Is this the correct thing to do?
      [fileWrapper updateFromPath: [path stringByAppendingPathComponent: 
					     [fileWrapper filename]]];
      location = NSMaxRange (range);
    }
}

- (BOOL) readFromURL: (NSURL *)url
             options: (NSDictionary *)options
  documentAttributes: (NSDictionary**)documentAttributes
{
  return [self readFromURL: url
               options: options
               documentAttributes: documentAttributes
               error: NULL];
}

- (BOOL) readFromURL: (NSURL *)url
             options: (NSDictionary *)options
  documentAttributes: (NSDictionary **)documentAttributes
               error: (NSError **)error
{
  NSAttributedString *attr;

  attr = [[NSAttributedString alloc] 
                 initWithURL: url
		     options: options
	  documentAttributes: documentAttributes
		       error: error];
  if (attr != nil)
    {
      [self setAttributedString: attr];
      RELEASE(attr);
      return YES; 
    }

  return NO;
}

- (BOOL) readFromData: (NSData *)data
              options: (NSDictionary *)options
   documentAttributes: (NSDictionary **)documentAttributes
{
  return [self readFromData:  data
               options: options
               documentAttributes: documentAttributes
               error: NULL];
}

- (BOOL) readFromData: (NSData *)data
              options: (NSDictionary *)options
   documentAttributes: (NSDictionary **)documentAttributes
                error: (NSError **)error
{
  NSAttributedString *attr;

  attr = [[NSAttributedString alloc] 
             initWithData: data
             options: options
             documentAttributes: documentAttributes
             error: error];
  if (attr)
    {
      [self setAttributedString: attr];
      RELEASE(attr);
      return YES;
    }

  return NO;
}

- (void) setBaseWritingDirection: (NSWritingDirection)writingDirection
                           range: (NSRange)range
{
	[self setAttributes: [NSDictionary dictionaryWithObject: 
                                         [NSNumber numberWithInt: writingDirection]
													forKey: @"WritingDirection"]
				  range: range];
}

@end
