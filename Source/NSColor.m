/* 
   NSColor.m

   The colorful color class

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

#include <gnustep/gui/NSColor.h>
#include <gnustep/gui/NSColorPrivate.h>
#include <gnustep/gui/NSView.h>

// Class variables
BOOL gnustep_gui_ignores_alpha = YES;
// Common colors
NSColor *gnustep_gui_black = nil;
NSColor *gnustep_gui_blue = nil;
NSColor *gnustep_gui_brown = nil;
NSColor *gnustep_gui_clear = nil;
NSColor *gnustep_gui_cyan = nil;
NSColor *gnustep_gui_dark_gray = nil;
NSColor *gnustep_gui_gray = nil;
NSColor *gnustep_gui_green = nil;
NSColor *gnustep_gui_light_gray = nil;
NSColor *gnustep_gui_magenta = nil;
NSColor *gnustep_gui_orange = nil;
NSColor *gnustep_gui_purple = nil;
NSColor *gnustep_gui_red = nil;
NSColor *gnustep_gui_white = nil;
NSColor *gnustep_gui_yellow = nil;

// Global strings
NSString *NSCalibratedWhiteColorSpace = @"NSCalibratedWhiteColorSpace";
NSString *NSCalibratedBlackColorSpace = @"NSCalibratedBlackColorSpace";
NSString *NSCalibratedRGBColorSpace = @"NSCalibratedRGBColorSpace";
NSString *NSDeviceWhiteColorSpace = @"NSDeviceWhiteColorSpace";
NSString *NSDeviceBlackColorSpace = @"NSDeviceBlackColorSpace";
NSString *NSDeviceRGBColorSpace = @"NSDeviceRGBColorSpace";
NSString *NSDeviceCMYKColorSpace = @"NSDeviceCMYKColorSpace";
NSString *NSNamedColorSpace = @"NSNamedColorSpace";
NSString *NSCustomColorSpace = @"NSCustomColorSpace";

// Global gray values
const float NSBlack = 0;
const float NSDarkGray = .333;
const float NSGray = 0.5;
const float NSLightGray = .667;
const float NSWhite = 1;

@implementation NSColor

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSColor class])
    {
      // Set the version number
      [self setVersion:2];

      // ignore alpha by default
      gnustep_gui_ignores_alpha = YES;
    }
}

//
// Creating an NSColor from Component Values
//
+ (NSColor *)colorWithCalibratedHue:(float)hue
			 saturation:(float)saturation
			 brightness:(float)brightness
			      alpha:(float)alpha
{
  NSColor *c;

  c = [[[NSColor alloc] init] autorelease];
  [c setColorSpaceName: NSCalibratedRGBColorSpace];
  [c setActiveComponent: GNUSTEP_GUI_HSB_ACTIVE];
  [c setHue: hue];
  [c setSaturation: saturation];
  [c setBrightness: brightness];
  [c setAlpha: alpha];

  return c;
}

+ (NSColor *)colorWithCalibratedRed:(float)red
			      green:(float)green
			       blue:(float)blue
			      alpha:(float)alpha
{
  NSColor *c;

  c = [[[NSColor alloc] init] autorelease];
  [c setColorSpaceName: NSCalibratedRGBColorSpace];
  [c setActiveComponent: GNUSTEP_GUI_RGB_ACTIVE];
  [c setRed: red];
  [c setGreen: green];
  [c setBlue: blue];
  [c setAlpha: alpha];

  return c;
}

+ (NSColor *)colorWithCalibratedWhite:(float)white
				alpha:(float)alpha
{
  NSColor *c;

  c = [[[NSColor alloc] init] autorelease];
  [c setColorSpaceName: NSCalibratedWhiteColorSpace];
  [c setActiveComponent: GNUSTEP_GUI_WHITE_ACTIVE];
  [c setWhite: white];
  [c setAlpha: alpha];

  return c;
}

+ (NSColor *)colorWithCatalogName:(NSString *)listName
			colorName:(NSString *)colorName
{
  return nil;
}

+ (NSColor *)colorWithDeviceCyan:(float)cyan
			 magenta:(float)magenta
			  yellow:(float)yellow
			   black:(float)black
			   alpha:(float)alpha
{
  NSColor *c;

  c = [[[NSColor alloc] init] autorelease];
  [c setColorSpaceName: NSDeviceCMYKColorSpace];
  [c setActiveComponent: GNUSTEP_GUI_CMYK_ACTIVE];
  [c setCyan: cyan];
  [c setMagenta: magenta];
  [c setYellow: yellow];
  [c setBlack: black];
  [c setAlpha: alpha];

  return c;
}

+ (NSColor *)colorWithDeviceHue:(float)hue
		     saturation:(float)saturation
		     brightness:(float)brightness
			  alpha:(float)alpha
{
  NSColor *c;

  c = [[[NSColor alloc] init] autorelease];
  [c setColorSpaceName: NSDeviceRGBColorSpace];
  [c setActiveComponent: GNUSTEP_GUI_HSB_ACTIVE];
  [c setHue: hue];
  [c setSaturation: saturation];
  [c setBrightness: brightness];
  [c setAlpha: alpha];

  return c;
}

+ (NSColor *)colorWithDeviceRed:(float)red
			  green:(float)green
			   blue:(float)blue
			  alpha:(float)alpha
{
  NSColor *c;

  c = [[[NSColor alloc] init] autorelease];
  [c setColorSpaceName: NSDeviceRGBColorSpace];
  [c setActiveComponent: GNUSTEP_GUI_RGB_ACTIVE];
  [c setRed: red];
  [c setGreen: green];
  [c setBlue: blue];
  [c setAlpha: alpha];

  return c;
}

+ (NSColor *)colorWithDeviceWhite:(float)white
			    alpha:(float)alpha
{
  NSColor *c;

  c = [[[NSColor alloc] init] autorelease];
  [c setColorSpaceName: NSDeviceWhiteColorSpace];
  [c setActiveComponent: GNUSTEP_GUI_WHITE_ACTIVE];
  [c setWhite: white];
  [c setAlpha: alpha];

  return c;
}

//
// Creating an NSColor With Preset Components
//
+ (NSColor *)blackColor
{
  if (!gnustep_gui_black)
    {
      gnustep_gui_black = [self colorWithCalibratedWhite: NSBlack alpha: 1.0];
      [gnustep_gui_black retain];
    }
  return gnustep_gui_black;
}

+ (NSColor *)blueColor
{
  if (!gnustep_gui_blue)
    {
      gnustep_gui_blue = [self colorWithCalibratedRed:0
			       green:0
			       blue:1.0
			       alpha:1.0];
      [gnustep_gui_blue retain];
    }
  return gnustep_gui_blue;
}

+ (NSColor *)brownColor
{
  if (!gnustep_gui_brown)
    {
      gnustep_gui_brown = [self colorWithCalibratedRed:0.6
				green:0.4
				blue:0.2
				alpha:1.0];
      [gnustep_gui_brown retain];
    }
  return gnustep_gui_brown;
}

+ (NSColor *)clearColor
{
  if (!gnustep_gui_clear)
    {
      gnustep_gui_clear = [self colorWithCalibratedWhite: NSBlack alpha: 1.0];
      [gnustep_gui_clear retain];
      [gnustep_gui_clear setClear:YES];
    }
  return gnustep_gui_clear;
}

+ (NSColor *)cyanColor
{
  // Why does OpenStep say RGB color space instead of CMYK?
  if (!gnustep_gui_cyan)
    {
      gnustep_gui_cyan = [self colorWithCalibratedRed:0
			       green:1.0
			       blue:1.0
			       alpha:1.0];
      [gnustep_gui_cyan retain];
    }
  return gnustep_gui_cyan;
#if 0
  return [self colorWithCalibratedCyan: 1.0
	       magenta:0
	       yellow:0
	       black:0
	       alpha:1.0];
#endif
}

+ (NSColor *)darkGrayColor
{
  if (!gnustep_gui_dark_gray)
    {
      gnustep_gui_dark_gray = [self colorWithCalibratedWhite: NSDarkGray 
				    alpha: 1.0];
      [gnustep_gui_dark_gray retain];
    }
  return gnustep_gui_dark_gray;
}

+ (NSColor *)grayColor
{
  if (!gnustep_gui_gray)
    {
      gnustep_gui_gray = [self colorWithCalibratedWhite: NSGray 
				    alpha: 1.0];
      [gnustep_gui_gray retain];
    }
  return gnustep_gui_gray;
}

+ (NSColor *)greenColor
{
  if (!gnustep_gui_green)
    {
      gnustep_gui_green = [self colorWithCalibratedRed:0
				green:1.0
				blue:0
				alpha:1.0];
      [gnustep_gui_green retain];
    }
  return gnustep_gui_green;
}

+ (NSColor *)lightGrayColor
{
  if (!gnustep_gui_light_gray)
    {
      gnustep_gui_light_gray = [self colorWithCalibratedWhite: NSLightGray 
				    alpha: 1.0];
      [gnustep_gui_light_gray retain];
    }
  return gnustep_gui_light_gray;
}

+ (NSColor *)magentaColor
{
  // Why does OpenStep say RGB color space instead of CMYK?
  if (!gnustep_gui_magenta)
    {
      gnustep_gui_magenta = [self colorWithCalibratedRed:1.0
				  green:0
				  blue:1.0
				  alpha:1.0];
      [gnustep_gui_magenta retain];
    }
  return gnustep_gui_magenta;
#if 0
  return [self colorWithCalibratedCyan:0
	       magenta:1.0
	       yellow:0
	       black:0
	       alpha:1.0];
#endif
}

+ (NSColor *)orangeColor;
{
  if (!gnustep_gui_orange)
    {
      gnustep_gui_orange = [self colorWithCalibratedRed:1.0
				 green:0.5
				 blue:0
				 alpha:1.0];
      [gnustep_gui_orange retain];
    }
  return gnustep_gui_orange;
}

+ (NSColor *)purpleColor;
{
  if (!gnustep_gui_purple)
    {
      gnustep_gui_purple = [self colorWithCalibratedRed:0.5
				 green:0
				 blue:0.5
				 alpha:1.0];
      [gnustep_gui_purple retain];
    }
  return gnustep_gui_purple;
}

+ (NSColor *)redColor;
{
  if (!gnustep_gui_red)
    {
      gnustep_gui_red = [self colorWithCalibratedRed:1.0
			      green:0
			      blue:0
			      alpha:1.0];
      [gnustep_gui_red retain];
    }
  return gnustep_gui_red;
}

+ (NSColor *)whiteColor;
{
  if (!gnustep_gui_white)
    {
      gnustep_gui_white = [self colorWithCalibratedWhite: NSWhite alpha: 1.0];
      [gnustep_gui_white retain];
    }
  return gnustep_gui_white;
}

+ (NSColor *)yellowColor
{
  // Why does OpenStep say RGB color space instead of CMYK?
  if (!gnustep_gui_yellow)
    {
      gnustep_gui_yellow = [self colorWithCalibratedRed:1.0
				 green:1.0
				 blue:0
				 alpha:1.0];
      [gnustep_gui_yellow retain];
    }
  return gnustep_gui_yellow;
#if 0
  return [self colorWithCalibratedCyan:0
	       magenta:0
	       yellow:1.0
	       black:0
	       alpha:1];
#endif
}

//
// Ignoring Alpha Components
//
+ (BOOL)ignoresAlpha
{
  return gnustep_gui_ignores_alpha;
}

+ (void)setIgnoresAlpha:(BOOL)flag
{
  gnustep_gui_ignores_alpha = flag;
}

//
// Copying and Pasting
//
+ (NSColor *)colorFromPasteboard:(NSPasteboard *)pasteBoard
{
  return nil;
}

////////////////////////////////////////////////////////////
//
// Instance methods
//
- init
{
  [super init];

  colorspace_name = @"";
  catalog_name = @"";
  color_name = @"";
  return self;
}

//
// Retrieving a Set of Components
//
- (void)getCyan:(float *)cyan
	magenta:(float *)magenta
	 yellow:(float *)yellow
	black:(float *)black
	  alpha:(float *)alpha
{
  // Only set what is wanted
  // If not a CMYK color then you get bogus values
  if (cyan)
    *cyan = CMYK_component.cyan;
  if (magenta)
    *magenta = CMYK_component.magenta;
  if (yellow)
    *yellow = CMYK_component.yellow;
  if (black)
    *black = CMYK_component.black;
  if (alpha)
    *alpha = alpha_component;
}

- (void)getHue:(float *)hue
    saturation:(float *)saturation
    brightness:(float *)brightness
	 alpha:(float *)alpha
{
  // Only set what is wanted
  // If not an HSB color then you get bogus values
  if (hue)
    *hue = HSB_component.hue;
  if (saturation)
    *saturation = HSB_component.saturation;
  if (brightness)
    *brightness = HSB_component.brightness;
  if (alpha)
    *alpha = alpha_component;
}

- (void)getRed:(float *)red
	 green:(float *)green
	  blue:(float *)blue
	 alpha:(float *)alpha
{
  // Only set what is wanted
  // If not an RGB color then you get bogus values
  if (red)
    *red = RGB_component.red;
  if (green)
    *green = RGB_component.green;
  if (blue)
    *blue = RGB_component.blue;
  if (alpha)
    *alpha = alpha_component;
}

- (void)getWhite:(float *)white
	   alpha:(float *)alpha
{
  // Only set what is wanted
  // If not a grayscale color then you get bogus values
  if (white)
    *white = white_component;
  if (alpha)
    *alpha = alpha_component;
}

//
// Retrieving Individual Components
//
- (float)alphaComponent
{
  return alpha_component;
}

- (float)blackComponent
{
  return CMYK_component.black;
}

- (float)blueComponent
{
  return RGB_component.blue;
}

- (float)brightnessComponent
{
  return HSB_component.brightness;
}

- (NSString *)catalogNameComponent
{
  return catalog_name;
}

- (NSString *)colorNameComponent
{
  return color_name;
}

- (float)cyanComponent
{
  return CMYK_component.cyan;
}

- (float)greenComponent
{
  return RGB_component.green;
}

- (float)hueComponent
{
  return HSB_component.hue;
}

- (NSString *)localizedCatalogNameComponent
{
  // +++ how do we localize?
  return catalog_name;
}

- (NSString *)localizedColorNameComponent
{
  // +++ how do we localize?
  return color_name;
}

- (float)magentaComponent
{
  return CMYK_component.magenta;
}

- (float)redComponent
{
  return RGB_component.red;
}

- (float)saturationComponent
{
  return HSB_component.saturation;
}

- (float)whiteComponent
{
  return white_component;
}

- (float)yellowComponent
{
  return CMYK_component.yellow;
}

//
// Converting to Another Color Space
//
- (NSString *)colorSpaceName
{
  return colorspace_name;
}

- (NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace
{
  return nil;
}

- (NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace
			       device:(NSDictionary *)deviceDescription
{
  return nil;
}

//
// Changing the Color
//
- (NSColor *)blendedColorWithFraction:(float)fraction
			      ofColor:(NSColor *)aColor
{
  return nil;
}

- (NSColor *)colorWithAlphaComponent:(float)alpha
{
  return nil;
}

//
// Copying and Pasting
//
- (void)writeToPasteboard:(NSPasteboard *)pasteBoard
{}

//
// Drawing
//
- (void)drawSwatchInRect:(NSRect)rect
{}

- (void)set
{
}

//
// Destroying
//
- (void)dealloc
{
  [super dealloc];
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  // Version 1
  [aCoder encodeValueOfObjCType: "f" at: &RGB_component.red];
  [aCoder encodeValueOfObjCType: "f" at: &RGB_component.green];
  [aCoder encodeValueOfObjCType: "f" at: &RGB_component.blue];
  [aCoder encodeValueOfObjCType: "f" at: &alpha_component];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_clear];

  // Version 2
  [aCoder encodeObject: colorspace_name];
  [aCoder encodeObject: catalog_name];
  [aCoder encodeObject: color_name];
  [aCoder encodeValueOfObjCType: "f" at: &CMYK_component.cyan];
  [aCoder encodeValueOfObjCType: "f" at: &CMYK_component.magenta];
  [aCoder encodeValueOfObjCType: "f" at: &CMYK_component.yellow];
  [aCoder encodeValueOfObjCType: "f" at: &CMYK_component.black];
  [aCoder encodeValueOfObjCType: "f" at: &HSB_component.hue];
  [aCoder encodeValueOfObjCType: "f" at: &HSB_component.saturation];
  [aCoder encodeValueOfObjCType: "f" at: &HSB_component.brightness];
  [aCoder encodeValueOfObjCType: "f" at: &white_component];
  [aCoder encodeValueOfObjCType: "i" at: &active_component];
}

- initWithCoder:aDecoder
{
  NSString *s;
  [super initWithCoder:aDecoder];

  // Version 1
  [aDecoder decodeValueOfObjCType: "f" at: &RGB_component.red];
  [aDecoder decodeValueOfObjCType: "f" at: &RGB_component.green];
  [aDecoder decodeValueOfObjCType: "f" at: &RGB_component.blue];
  [aDecoder decodeValueOfObjCType: "f" at: &alpha_component];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_clear];

  // Get our class name
  s = [NSString stringWithCString: object_get_class_name(self)];

  // Version 2
  if ([aDecoder versionForClassName: s] > 1)
    {
      colorspace_name = [aDecoder decodeObject];
      catalog_name = [aDecoder decodeObject];
      color_name = [aDecoder decodeObject];
      [aDecoder decodeValueOfObjCType: "f" at: &CMYK_component.cyan];
      [aDecoder decodeValueOfObjCType: "f" at: &CMYK_component.magenta];
      [aDecoder decodeValueOfObjCType: "f" at: &CMYK_component.yellow];
      [aDecoder decodeValueOfObjCType: "f" at: &CMYK_component.black];
      [aDecoder decodeValueOfObjCType: "f" at: &HSB_component.hue];
      [aDecoder decodeValueOfObjCType: "f" at: &HSB_component.saturation];
      [aDecoder decodeValueOfObjCType: "f" at: &HSB_component.brightness];
      [aDecoder decodeValueOfObjCType: "f" at: &white_component];
      [aDecoder decodeValueOfObjCType: "i" at: &active_component];
    }

  return self;
}

@end

//
// Private methods
//
@implementation NSColor (GNUstepPrivate)

- (void)setColorSpaceName:(NSString *)str
{
  colorspace_name = str;
}

- (void)setCatalogName:(NSString *)str
{
  catalog_name = str;
}

- (void)setColorName:(NSString *)str
{
  color_name = str;
}

// RGB component values
- (void)setRed:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  RGB_component.red = value;
}

- (void)setGreen:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  RGB_component.green = value;
}

- (void)setBlue:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  RGB_component.blue = value;
}

// CMYK component values
- (void)setCyan:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  CMYK_component.cyan = value;
}

- (void)setMagenta:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  CMYK_component.magenta = value;
}

- (void)setYellow:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  CMYK_component.yellow = value;
}

- (void)setBlack:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  CMYK_component.black = value;
}

// HSB component values
- (void)setHue:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  HSB_component.hue = value;
}

- (void)setSaturation:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  HSB_component.saturation = value;
}

- (void)setBrightness:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  HSB_component.brightness = value;
}

// Grayscale
- (void)setWhite:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  white_component = value;
}

- (void)setAlpha:(float)value
{
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  alpha_component = value;
}

- (void)setActiveComponent:(int)value
{
  active_component = value;
}

- (void)setClear:(BOOL)flag
{
  is_clear = flag;
}

@end
