/* 
   GSTextStorage.m

   Implementation of concrete subclass of a string class with attributes

   Copyright (C) 1999 Free Software Foundation, Inc.

   Based on code by: ANOQ of the sun <anoq@vip.cybercity.dk>
   Written by: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: July 1999
   
   This file is part of GNUStep-gui

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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

/* Warning -	[-initWithString:attributes:] is the designated initialiser,
 *		but it doesn't provide any way to perform the function of the
 *		[-initWithAttributedString:] initialiser.
 *		In order to work youd this, the string argument of the
 *		designated initialiser has been overloaded such that it
 *		is expected to accept an NSAttributedString here instead of
 *		a string.  If you create an NSAttributedString subclass, you
 *		must make sure that your implementation of the initialiser
 *		copes with either an NSString or an NSAttributedString.
 *		If it receives an NSAttributedString, it should ignore the
 *		attributes argument and use the values from the string.
 */

#include <Foundation/NSAttributedString.h>
#include <Foundation/NSException.h>
#include <Foundation/NSRange.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSZone.h>
#include <AppKit/NSTextStorage.h>

#define		SANITY_CHECKS	0

#define	GSI_MAP_RETAIN_KEY(X)	
#define	GSI_MAP_RELEASE_KEY(X)	
#define	GSI_MAP_RETAIN_VAL(X)	
#define	GSI_MAP_RELEASE_VAL(X)	
#define	GSI_MAP_EQUAL(X,Y)	[(X).obj isEqualToDictionary: (Y).obj]
#define GSI_MAP_KTYPES	GSUNION_OBJ
#define GSI_MAP_VTYPES	GSUNION_INT

#include <base/GSIMap.h>

static NSLock		*attrLock = nil;
static GSIMapTable_t	attrMap;
static SEL		lockSel;
static SEL		unlockSel;
static IMP		lockImp;
static IMP		unlockImp;

#define	ALOCK()	if (attrLock != nil) (*lockImp)(attrLock, lockSel)
#define	AUNLOCK() if (attrLock != nil) (*unlockImp)(attrLock, unlockSel)

/*
 * Add a dictionary to the cache - if it was not already there, return
 * the copy added to the cache, if it was, count it and return retained
 * object that was there.
 */
static NSDictionary*
cacheAttributes(NSDictionary *attrs)
{
  GSIMapNode	node;

  ALOCK();
  node = GSIMapNodeForKey(&attrMap, (GSIMapKey)attrs);
  if (node == 0)
    {
      attrs = [attrs copy];
      GSIMapAddPair(&attrMap, (GSIMapKey)attrs, (GSIMapVal)(unsigned)1);
    }
  else
    {
      node->value.uint++;
      attrs = RETAIN(node->key.obj);
    }
  AUNLOCK();
  return attrs;
}

static void
unCacheAttributes(NSDictionary *attrs)
{
  GSIMapBucket       bucket;

  ALOCK();
  bucket = GSIMapBucketForKey(&attrMap, (GSIMapKey)attrs);
  if (bucket != 0)
    {
      GSIMapNode     node;

      node = GSIMapNodeForKeyInBucket(bucket, (GSIMapKey)attrs);
      if (node != 0)
	{
	  if (--node->value.uint == 0)
	    {
	      GSIMapRemoveNodeFromMap(&attrMap, bucket, node);
	      GSIMapFreeNode(&attrMap, node);
	    }
	}
    }
  AUNLOCK();
}



@interface GSTextStorage : NSTextStorage
{
  NSMutableString       *textChars;
  NSMutableArray        *infoArray;
}
@end

@interface	GSTextInfo : NSObject <GCFinalization>
{
@public
  unsigned	loc;
  NSDictionary	*attrs;
}

+ (GSTextInfo*) newWithZone: (NSZone*)z value: (NSDictionary*)a at: (unsigned)l;

@end

@implementation	GSTextInfo

/*
 * Called to record attributes at a particular location - the given attributes
 * dictionary must have been produced by 'cacheAttributes()' so that it is
 * already copied/retained and this method doesn't need to do it.
 */
+ (GSTextInfo*) newWithZone: (NSZone*)z value: (NSDictionary*)a at: (unsigned)l;
{
  GSTextInfo	*info = (GSTextInfo*)NSAllocateObject(self, 0, z);

  info->loc = l;
  info->attrs = a;
  return info;
}

- (Class) classForPortCoder
{
  return [self class];
}

- (void) dealloc
{
  [self gcFinalize];
  NSDeallocateObject(self);
}

- (NSString*) description
{
  return [NSString stringWithFormat: @"Attributes at %u are - %@",
    loc, attrs];
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(unsigned) at: &loc];
  [aCoder encodeValueOfObjCType: @encode(id) at: &attrs];
}

- (void) gcFinalize
{
  unCacheAttributes(attrs);
  DESTROY(attrs);
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  NSDictionary	*a;

  [aCoder decodeValueOfObjCType: @encode(unsigned) at: &loc];
  a = [aCoder decodeObject];
  attrs = cacheAttributes(a);
  return self;
}

- (id) replacementObjectForPortCoder: (NSPortCoder*)aCoder
{
  return self;
}

@end



static Class	infCls = 0;

static SEL infSel;
static SEL addSel;
static SEL cntSel;
static SEL insSel;
static SEL oatSel;
static SEL remSel;

static IMP	infImp;
static void	(*addImp)();
static unsigned (*cntImp)();
static void	(*insImp)();
static IMP	oatImp;
static void	(*remImp)();

#define	NEWINFO(Z,O,L)	((*infImp)(infCls, infSel, (Z), (O), (L)))
#define	ADDOBJECT(O)	((*addImp)(infoArray, addSel, (O)))
#define	INSOBJECT(O,I)	((*insImp)(infoArray, insSel, (O), (I)))
#define	OBJECTAT(I)	((*oatImp)(infoArray, oatSel, (I)))
#define	REMOVEAT(I)	((*remImp)(infoArray, remSel, (I)))

static inline NSDictionary *attrDict(GSTextInfo* info)
{
  return info->attrs;
}


static void _setup()
{
  if (infCls == 0)
    {
      NSMutableArray	*a;

      GSIMapInitWithZoneAndCapacity(&attrMap, NSDefaultMallocZone(), 32);

      infSel = @selector(newWithZone:value:at:);
      addSel = @selector(addObject:);
      cntSel = @selector(count);
      insSel = @selector(insertObject:atIndex:);
      oatSel = @selector(objectAtIndex:);
      remSel = @selector(removeObjectAtIndex:);

      infCls = [GSTextInfo class];
      infImp = [infCls methodForSelector: infSel];

      a = [NSMutableArray allocWithZone: NSDefaultMallocZone()];
      a = [a initWithCapacity: 1];
      addImp = (void (*)())[a methodForSelector: addSel];
      cntImp = (unsigned (*)())[a methodForSelector: cntSel];
      insImp = (void (*)())[a methodForSelector: insSel];
      oatImp = [a methodForSelector: oatSel];
      remImp = (void (*)())[a methodForSelector: remSel];
      RELEASE(a);
    }
}

static void
_setAttributesFrom(
  NSAttributedString *attributedString,
  NSRange aRange,
  NSMutableArray *infoArray)
{
  NSZone	*z = [infoArray zone];
  NSRange	range;
  NSDictionary	*attr;
  GSTextInfo	*info;
  unsigned	loc;

  /*
   * remove any old attributes of the string.
   */
  [infoArray removeAllObjects];

  if (aRange.length <= 0)
    return;

  attr = [attributedString attributesAtIndex: aRange.location
			      effectiveRange: &range];
  attr = cacheAttributes(attr);
  info = NEWINFO(z, attr, 0);
  ADDOBJECT(info);
  RELEASE(info);

  while ((loc = NSMaxRange(range)) < NSMaxRange(aRange))
    {
      attr = [attributedString attributesAtIndex: loc
				  effectiveRange: &range];
      attr = cacheAttributes(attr);
      info = NEWINFO(z, attr, loc - aRange.location);
      ADDOBJECT(info);
      RELEASE(info);
    }
}

inline static NSDictionary*
_attributesAtIndexEffectiveRange(
  unsigned int index,
  NSRange *aRange,
  unsigned int tmpLength,
  NSMutableArray *infoArray,
  unsigned int *foundIndex)
{
  unsigned	low, high, used, cnt, nextLoc;
  GSTextInfo	*found = nil;

  used = (*cntImp)(infoArray, cntSel);
  NSCAssert(used > 0, NSInternalInconsistencyException);
  high = used - 1;

  if (index >= tmpLength)
    {
      if (index == tmpLength)
	{
	  found = OBJECTAT(high);
	  if (foundIndex != 0)
	    {
	      *foundIndex = high;
	    }
	  if (aRange != 0)
	    {
	      aRange->location = found->loc;
	      aRange->length = tmpLength - found->loc;
	    }
	  return attrDict(found);
	}
      [NSException raise: NSRangeException
		  format: @"index is out of range in function "
			  @"_attributesAtIndexEffectiveRange()"];
    }
  
  /*
   * Binary search for efficiency in huge attributed strings
   */
  low = 0;
  while (low <= high)
    {
      cnt = (low + high) / 2;
      found = OBJECTAT(cnt);
      if (found->loc > index)
	{
	  high = cnt - 1;
	}
      else
	{
	  if (cnt >= used - 1)
	    {
	      nextLoc = tmpLength;
	    }
	  else
	    {
	      GSTextInfo	*inf = OBJECTAT(cnt + 1);

	      nextLoc = inf->loc;
	    }
	  if (found->loc == index || index < nextLoc)
	    {
	      //Found
	      if (aRange != 0)
		{
		  aRange->location = found->loc;
		  aRange->length = nextLoc - found->loc;
		}
	      if (foundIndex != 0)
		{
		  *foundIndex = cnt;
		}
	      return attrDict(found);
	    }
	  else
	    {
	      low = cnt + 1;
	    }
	}
    }
  NSCAssert(NO,@"Error in binary search algorithm");
  return nil;
}

@implementation GSTextStorage

#if	SANITY_CHECKS

#define	SANITY()	[self sanity]
	
- (void) sanity
{
  GSTextInfo	*info;
  unsigned	i;
  unsigned	l = 0;
  unsigned	len = [textChars length];
  unsigned	c = (*cntImp)(infoArray, cntSel);

  NSAssert(c > 0, NSInternalInconsistencyException);
  info = OBJECTAT(0);
  NSAssert(info->loc == 0, NSInternalInconsistencyException);
  for (i = 1; i < c; i++)
    {
      info = OBJECTAT(i);
      NSAssert(info->loc > l, NSInternalInconsistencyException);
      NSAssert(info->loc <= len, NSInternalInconsistencyException);
      l = info->loc;
    }
}
#else
#define	SANITY()	
#endif

/*
 * If we are multi-threaded, we must guard access to the uniquing set.
 */
+ (void) _becomeThreaded: (id)notification
{
  attrLock = [NSLock new];
  lockSel = @selector(lock);
  unlockSel = @selector(unlock);
  lockImp = [attrLock methodForSelector: lockSel];
  unlockImp = [attrLock methodForSelector: unlockSel];
}

+ (void) initialize
{
  _setup();

  if ([NSThread isMultiThreaded])
    {
      [self _becomeThreaded: nil];
    }
  else
    {
      [[NSNotificationCenter defaultCenter]
	addObserver: self
	   selector: @selector(_becomeThreaded:)
	       name: NSWillBecomeMultiThreadedNotification
	     object: nil];
    }
}

- (Class) classForPortCoder
{
  return [self class];
}

- (id) replacementObjectForPortCoder: (NSPortCoder*)aCoder
{
  return self;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
  [aCoder encodeValueOfObjCType: @encode(id) at: &textChars];
  [aCoder encodeValueOfObjCType: @encode(id) at: &infoArray];
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  self = [super initWithCoder: aCoder];
  [aCoder decodeValueOfObjCType: @encode(id) at: &textChars];
  [aCoder decodeValueOfObjCType: @encode(id) at: &infoArray];
  return self;
}

- (id) initWithString: (NSString*)aString
	   attributes: (NSDictionary*)attributes
{
  NSZone	*z = [self zone];

  self = [super initWithString: aString attributes: attributes];
  infoArray = [[NSMutableArray allocWithZone: z] initWithCapacity: 1];
  if (aString != nil && [aString isKindOfClass: [NSAttributedString class]])
    {
      NSAttributedString	*as = (NSAttributedString*)aString;

      aString = [as string];
      _setAttributesFrom(as, NSMakeRange(0, [aString length]), infoArray);
    }
  else
    {
      GSTextInfo	*info;

      if (attributes == nil)
        {
          attributes = [NSDictionary dictionary];
        }
      attributes = cacheAttributes(attributes);
      info = NEWINFO(z, attributes, 0);
      ADDOBJECT(info);
      RELEASE(info);
    }
  if (aString == nil)
    textChars = [[NSMutableString allocWithZone: z] init];
  else
    textChars = [aString mutableCopyWithZone: z];
  return self;
}

- (NSString*) string
{
  return AUTORELEASE([textChars copyWithZone: NSDefaultMallocZone()]);
}

- (NSDictionary*) attributesAtIndex: (unsigned)index
		     effectiveRange: (NSRange*)aRange
{
  unsigned	dummy;

  return _attributesAtIndexEffectiveRange(
    index, aRange, [textChars length], infoArray, &dummy);
}

/*
 *	Primitive method! Sets attributes and values for a given range of
 *	characters, replacing any previous attributes and values for that
 *	range.
 *
 *	Sets the attributes for the characters in aRange to attributes.
 *	These new attributes replace any attributes previously associated
 *	with the characters in aRange. Raises an NSRangeException if any
 *	part of aRange lies beyond the end of the receiver's characters.
 *	See also: - addAtributes: range: , - removeAttributes: range:
 */
- (void) setAttributes: (NSDictionary*)attributes
		 range: (NSRange)range
{
  unsigned	tmpLength, arrayIndex, arraySize;
  NSRange	effectiveRange;
  unsigned	afterRangeLoc, beginRangeLoc;
  NSDictionary	*attrs;
  NSZone	*z = [self zone];
  GSTextInfo	*info;

  if (range.length == 0)
    {
      NSWarnMLog(@"Attempt to set attribute for zero-length range", 0);
    }
  if (attributes == nil)
    {
      attributes = [NSDictionary dictionary];
    }
  attributes = cacheAttributes(attributes);
SANITY();
  tmpLength = [textChars length];
  GS_RANGE_CHECK(range, tmpLength);
  arraySize = (*cntImp)(infoArray, cntSel);
  beginRangeLoc = range.location;
  afterRangeLoc = NSMaxRange(range);
  if (afterRangeLoc < tmpLength)
    {
      /*
       * Locate the first range that extends beyond our range.
       */
      attrs = _attributesAtIndexEffectiveRange(
	afterRangeLoc, &effectiveRange, tmpLength, infoArray, &arrayIndex);
      if (attrs == attributes)
	{
	  /*
	   * The located range has the same attributes as us - so we can
	   * extend our range to include it.
	   */
	  if (effectiveRange.location < beginRangeLoc)
	    {
	      range.length += beginRangeLoc - effectiveRange.location;
	      range.location = effectiveRange.location;
	      beginRangeLoc = range.location;
	    }
	  if (NSMaxRange(effectiveRange) > afterRangeLoc)
	    {
	      range.length = NSMaxRange(effectiveRange) - range.location;
	      afterRangeLoc = NSMaxRange(range);
	    }
	}
      else if (effectiveRange.location > beginRangeLoc)
	{
	  /*
	   * The located range also starts at or after our range.
	   */
	  info = OBJECTAT(arrayIndex);
	  info->loc = afterRangeLoc;
	  arrayIndex--;
	}
      else if (effectiveRange.location < beginRangeLoc)
	{
	  /*
	   * The located range starts before our range.
	   * Create a subrange to go from our end to the end of the old range.
	   */
	  info = NEWINFO(z, cacheAttributes(attrs), afterRangeLoc);
	  arrayIndex++;
	  INSOBJECT(info, arrayIndex);
	  RELEASE(info);
	  arrayIndex--;
	}
    }
  else
    {
      arrayIndex = arraySize - 1;
    }
  
  /*
   * Remove any ranges completely within ours
   */
  while (arrayIndex > 0)
    {
      info = OBJECTAT(arrayIndex-1);
      if (info->loc < beginRangeLoc)
	break;
      REMOVEAT(arrayIndex);
      arrayIndex--;
    }

  /*
   * Use the location/attribute info in the current slot if possible,
   * otherwise, add a new slot and use that.
   */
  info = OBJECTAT(arrayIndex);
  if (info->loc >= beginRangeLoc || info->attrs == attributes)
    {
      info->loc = beginRangeLoc;
      unCacheAttributes(info->attrs);
      RELEASE(info->attrs);
      info->attrs = attributes;
    }
  else
    {
      arrayIndex++;
      info = NEWINFO(z, attributes, beginRangeLoc);
      INSOBJECT(info, arrayIndex);
      RELEASE(info);
    }
  
SANITY();
  [self edited: NSTextStorageEditedAttributes
	 range: range
changeInLength: 0];
}

- (void) replaceCharactersInRange: (NSRange)range
		       withString: (NSString*)aString
{
  unsigned	tmpLength, arrayIndex, arraySize;
  NSRange	effectiveRange;
  NSDictionary	*attrs;
  GSTextInfo	*info;
  int		moveLocations;
  unsigned	start;

SANITY();
  if (aString == nil)
    {
      aString = @"";
    }
  tmpLength = [textChars length];
  GS_RANGE_CHECK(range, tmpLength);
  if (range.location == tmpLength)
    {
      /*
       * Special case - replacing a zero length string at the end
       * simply appends the new string and attributes are inherited.
       */
      [textChars appendString: aString];
      goto finish;
    }

  arraySize = (*cntImp)(infoArray, cntSel);
  if (arraySize == 1)
    {
      /*
       * Special case - if the string has only one set of attributes
       * then the replacement characters will get them too.
       */
      [textChars replaceCharactersInRange: range withString: aString];
      goto finish;
    }

  /*
   * Get the attributes to associate with our replacement string.
   * Should be those of the first character replaced.
   * If the range replaced is empty, we use the attributes of the
   * previous character (if possible).
   */
  if (range.length == 0 && range.location > 0)
    start = range.location - 1;
  else
    start = range.location;
  attrs = _attributesAtIndexEffectiveRange(start, &effectiveRange,
    tmpLength, infoArray, &arrayIndex);

  arrayIndex++;
  if (NSMaxRange(effectiveRange) < NSMaxRange(range))
    {
      /*
       * Remove all range info for ranges enclosed within the one
       * we are replacing.  Adjust the start point of a range that
       * extends beyond ours.
       */
      info = OBJECTAT(arrayIndex);
      if (info->loc < NSMaxRange(range))
	{
	  int	next = arrayIndex + 1;

	  while (next < arraySize)
	    {
	      GSTextInfo	*n = OBJECTAT(next);
	      if (n->loc <= NSMaxRange(range))
		{
		  REMOVEAT(arrayIndex);
		  arraySize--;
		  info = n;
		}
	      else
		{
		  break;
		}
	    }
	}
      info->loc = NSMaxRange(range);
SANITY();
    }

  moveLocations = [aString length] - range.length;
  if (effectiveRange.location == range.location
    && (moveLocations + range.length) == 0)
    {
      /*
       * If we are replacing a range with a zero length string and the
       * range we are using matches the range replaced, then we must
       * remove it from the array to avoid getting a zero length range.
       */
      arrayIndex--;
      REMOVEAT(arrayIndex);
      arraySize--;
    }

SANITY();
  /*
   * Now adjust the positions of the ranges following the one we are using.
   */
  while (arrayIndex < arraySize)
    {
      info = OBJECTAT(arrayIndex);
      info->loc += moveLocations;
      arrayIndex++;
    }
  [textChars replaceCharactersInRange: range withString: aString];

finish:
SANITY();
  [self edited: NSTextStorageEditedCharacters
         range: range
changeInLength: [aString length] - range.length];
}

- (void) dealloc
{
  RELEASE(textChars);
  RELEASE(infoArray);
  [super dealloc];
}

@end
