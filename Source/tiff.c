/* tiff - Functions for dealing with tiff images
   Copyright (C) 1996 Free Software Foundation, Inc.
   
   Written by:  Adam Fedor <fedor@colorado.edu>
   Date: Feb 1996
   
   This file is part of the GNUstep Application Kit Library.

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
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
   */ 

/* Code in NSTiffRead, NSTiffGetInfo, and NSTiffGetColormap 
   is derived from tif_getimage, by Sam Leffler. See the copyright below.
*/

/*
 * Copyright (c) 1991, 1992, 1993, 1994 Sam Leffler
 * Copyright (c) 1991, 1992, 1993, 1994 Silicon Graphics, Inc.
 *
 * Permission to use, copy, modify, distribute, and sell this software and 
 * its documentation for any purpose is hereby granted without fee, provided
 * that (i) the above copyright notices and this permission notice appear in
 * all copies of the software and related documentation, and (ii) the names of
 * Sam Leffler and Silicon Graphics may not be used in any advertising or
 * publicity relating to the software without the specific, prior written
 * permission of Sam Leffler and Silicon Graphics.
 * 
 * THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND, 
 * EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY 
 * WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  
 * 
 * IN NO EVENT SHALL SAM LEFFLER OR SILICON GRAPHICS BE LIABLE FOR
 * ANY SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND,
 * OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
 * WHETHER OR NOT ADVISED OF THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF 
 * LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE 
 * OF THIS SOFTWARE.
 */

#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>		/* for L_SET, etc definitions */
#include <AppKit/nsimage-tiff.h>

typedef struct {
  char* data;
  long  size;
  long  position;
  const char* mode;
  realloc_data_callback* realloc_data;
} chandle_t;

#ifdef HAVE_LIBTIFF

/* Client functions that provide reading/writing of data for libtiff */
static tsize_t
TiffHandleRead(thandle_t handle, tdata_t buf, toff_t count)
{
  chandle_t* chand = (chandle_t *)handle;
  printf("TiffHandleRead\n");
  if (chand->position >= chand->size)
    return 0;
  if (chand->position + count > chand->size)
    count = chand->size - chand->position;
  memcpy(buf, chand->data + chand->position, count);
  return count;
}

static tsize_t
TiffHandleWrite(thandle_t handle, tdata_t buf, toff_t count)
{
  chandle_t* chand = (chandle_t *)handle;
  printf("TiffHandleWrite\n");
  if (chand->mode == "r")
    return 0;
  if (chand->position + count > chand->size)
    {
      if (chand->realloc_data == NULL)
	return 0;
      chand->size = chand->position + count + 1;
      chand->data = chand->realloc_data(chand->data, chand->size);
      if (chand->data == NULL)
	return 0;
    }
  memcpy(chand->data + chand->position, buf, count);
  return count;
}

static toff_t
TiffHandleSeek(thandle_t handle, toff_t offset, int mode)
{
  chandle_t* chand = (chandle_t *)handle;
  printf("TiffHandleSeek\n");
  switch(mode) 
    {
    case SEEK_SET: chand->position = offset; break;
    case SEEK_CUR: chand->position += offset; break;
    case SEEK_END: 
      if (offset > 0 && chand->mode == "r")
	return 0;
      chand->position += offset; break;
      break;
    }
  return chand->position;
}

static int
TiffHandleClose(thandle_t handle)
{
  chandle_t* chand = (chandle_t *)handle;

  printf("TiffHandleClose\n");
  /* Presumably, we don't need the handle anymore */
  OBJC_FREE(chand);
  return 0;
}

static toff_t
TiffHandleSize(thandle_t handle)
{
  chandle_t* chand = (chandle_t *)handle;
  printf("TiffHandleSize\n");
  return chand->size;
}

static int
TiffHandleMap(thandle_t handle, tdata_t* data, toff_t* size)
{
  chandle_t* chand = (chandle_t *)handle;
  
  printf("TiffHandleMap\n");
  *data = chand->data;
  *size = chand->size;
    
  return 1;
}

static void
TiffHandleUnmap(thandle_t handle, tdata_t data, toff_t size)
{
  printf("TiffHandleUnmap\n");
  /* Nothing to unmap. */
}

/* Open a tiff from a stream. Returns NULL if can't read tiff information.  */
TIFF* 
NSTiffOpenData(char* data, long size, const char* mode,
			    realloc_data_callback* realloc_data)
{
  chandle_t* handle;
  printf("NSTiffOpenData\n");
  OBJC_MALLOC(handle, chandle_t, 1);
  handle->data = data;
  handle->position = 0;
  handle->size = size;
  handle->mode = mode;
  handle->realloc_data = realloc_data;
  return TIFFClientOpen("NSData", mode,
			(thandle_t)handle,
			TiffHandleRead, TiffHandleWrite,
			TiffHandleSeek, TiffHandleClose,
			TiffHandleSize,
			TiffHandleMap, TiffHandleUnmap);
}

int  
NSTiffClose(TIFF* image)
{
  TIFFClose(image);
  return 0;
}

/* Read some information about the image. Note that currently we don't
   determine numImages. */
NSTiffInfo *      
NSTiffGetInfo(int imageNumber, TIFF* image)
{
  NSTiffInfo* info;

  if (imageNumber >= 0 && !TIFFSetDirectory(image, imageNumber)) 
    {
      return NULL;
    }

  OBJC_MALLOC(info, NSTiffInfo, 1);
  memset(info, 0, sizeof(NSTiffInfo));
  if (imageNumber >= 0)
    info->imageNumber = imageNumber;
  
  TIFFGetField(image, TIFFTAG_IMAGEWIDTH, &info->width);
  TIFFGetField(image, TIFFTAG_IMAGELENGTH, &info->height);
  TIFFGetField(image, TIFFTAG_COMPRESSION, &info->compression);
  TIFFGetField(image, TIFFTAG_SUBFILETYPE, &info->subfileType);

  /* If the following tags aren't present then use the TIFF defaults. */
  TIFFGetFieldDefaulted(image, TIFFTAG_BITSPERSAMPLE, &info->bitsPerSample);
  TIFFGetFieldDefaulted(image, TIFFTAG_SAMPLESPERPIXEL, 
			&info->samplesPerPixel);
  TIFFGetFieldDefaulted(image, TIFFTAG_PLANARCONFIG, 
			&info->planarConfig);

  /* If TIFFTAG_PHOTOMETRIC is not present then assign a reasonable default.
     The TIFF 5.0 specification doesn't give a default. */
  if (!TIFFGetField(image, TIFFTAG_PHOTOMETRIC, &info->photoInterp)) 
    {
      switch (info->samplesPerPixel) 
	{
	case 1:
	  info->photoInterp = PHOTOMETRIC_MINISBLACK;
	  break;
	case 3: case 4:
	  info->photoInterp = PHOTOMETRIC_RGB;
	  break;
	default:
	  TIFFError(TIFFFileName(image),
		    "Missing needed \"PhotometricInterpretation\" tag");
	  return (0);
	}
      TIFFError(TIFFFileName(image),
		"No \"PhotometricInterpretation\" tag, assuming %s\n",
		info->photoInterp == PHOTOMETRIC_RGB ? "RGB" : "min-is-black");
    }

  return info;
}

#define READ_SCANLINE(sample) \
	if ( TIFFReadScanline( image, buf, row, sample ) < 0 ) { \
	    fprintf(stderr, "tiff: bad data read on line %d\n", row ); \
	    error = 1; \
	    break; \
	} \
	inP = buf;

/* Read an image into a data array.  The data array is assumed to have been
   already allocated to the correct size.

   Note that palette images are implicitly coverted to 24-bit contig
   direct color images. Thus the data array should be large 
   enough to hold this information. */
int
NSTiffRead(int imageNumber, TIFF* image, NSTiffInfo* info, char* data)
{
  int     i;
  int     row, col;
  int     maxval;
  int	  size;
  int	  line;
  int	  error = 0;
  u_char* inP;
  u_char* outP;
  u_char* buf;
  u_char* raster;
  NSTiffInfo* newinfo;
  NSTiffColormap* map;
  int scan_line_size;

  if (data == NULL)
    return -1;
	
  /* Make sure we're at the right image */
  if ((newinfo = NSTiffGetInfo(imageNumber, image)) == NULL)
    return -1;

  if (info)
    memcpy(info, newinfo, sizeof(NSTiffInfo));

  map = NULL;
  if ( newinfo->photoInterp == PHOTOMETRIC_PALETTE) 
    {
      map = NSTiffGetColormap(image);
      if (!map)
	return -1;
    }

  maxval = ( 1 << newinfo->bitsPerSample ) - 1;
  line   = ceil((float)newinfo->width * newinfo->bitsPerSample / 8.0);
  size   = ceil((float)line * newinfo->height * newinfo->samplesPerPixel );
  scan_line_size = TIFFScanlineSize(image);
  OBJC_MALLOC(buf, u_char, TIFFScanlineSize(image));
  
  raster = (u_char *)data;
  outP = raster;
  switch ( newinfo->photoInterp ) 
    {
    case PHOTOMETRIC_MINISBLACK:
    case PHOTOMETRIC_MINISWHITE:
      if (newinfo->planarConfig == PLANARCONFIG_CONTIG) 
	{
	  for ( row = 0; row < newinfo->height; ++row ) 
	    {
	      READ_SCANLINE(0)
		for ( col = 0; col < line*newinfo->samplesPerPixel; col++) 
		  *outP++ = *inP++;
	    }
	} 
      else 
	{
	  for (i = 0; i < newinfo->samplesPerPixel; i++)
	    for ( row = 0; row < newinfo->height; ++row ) 
	      {
		READ_SCANLINE(i)
		  for ( col = 0; col < line; col++) 
		    *outP++ = *inP++;
	      }
	}
      break;
    case PHOTOMETRIC_PALETTE:
      {
	for ( row = 0; row < newinfo->height; ++row ) 
	  {
	    READ_SCANLINE(0)
	      for ( col = 0; col < newinfo->width; col++) 
		{
		  *outP++ = map->red[*inP] / 256;
		  *outP++ = map->green[*inP] / 256;
		  *outP++ = map->blue[*inP] / 256;
		  inP++;
		}
	  }
	free(map->red);
	free(map->green);
	free(map->blue);
	free(map);
      }
      break;
    case PHOTOMETRIC_RGB:
      if (newinfo->planarConfig == PLANARCONFIG_CONTIG) 
	{
	  for ( row = 0; row < newinfo->height; ++row ) 
	    {
	      READ_SCANLINE(0)
		for ( col = 0; col < newinfo->width; col++) 
		  for (i = 0; i < newinfo->samplesPerPixel; i++)
		    *outP++ = *inP++;
	    }
	} 
      else 
	{
	  for (i = 0; i < newinfo->samplesPerPixel; i++)
	    for ( row = 0; row < newinfo->height; ++row ) 
	      {
		READ_SCANLINE(i)
		  for ( col = 0; col < newinfo->width; col++) 
		    *outP++ = *inP++;
	      }
	}
      break;
    default:
      TIFFError(TIFFFileName(image),
		"Can't read photometric %d", newinfo->photoInterp);
      break;
    }
    
  OBJC_FREE(newinfo);
  return error;
}

int  
NSWriteTiff(TIFF* image, NSTiffInfo* info, char* data)
{
  return 0;
}

/*------------------------------------------------------------------------*/

/* Many programs get TIFF colormaps wrong.  They use 8-bit colormaps
   instead of 16-bit colormaps.  This function is a heuristic to
   detect and correct this. */
static int
CheckAndCorrectColormap(NSTiffColormap* map)
{
  register int i;

  for (i = 0; i < map->size; i++)
    if ((map->red[i] > 255)||(map->green[i] > 255)||(map->blue[i] > 255))
      return 16;

#define	CVT(x)		(((x) * 255) / ((1L<<16)-1))
  for (i = 0; i < map->size; i++) 
    {
      map->red[i] = CVT(map->red[i]);
      map->green[i] = CVT(map->green[i]);
      map->blue[i] = CVT(map->blue[i]);
    }
  return 8;
}

/* Gets the colormap for the image if there is one. Returns a
   NSTiffColormap if one was found.
*/
NSTiffColormap *
NSTiffGetColormap(TIFF* image)
{
  NSTiffInfo* info;
  NSTiffColormap* map;

  /* Re-read the tiff information. We pass -1 as the image number which
     means just read the current image. */
  info = NSTiffGetInfo(-1, image);
  if (info->photoInterp != PHOTOMETRIC_PALETTE)
    return NULL;

  OBJC_MALLOC(map, NSTiffColormap, 1);
  map->size = 1 << info->bitsPerSample;

  if (!TIFFGetField(image, TIFFTAG_COLORMAP,
		    &map->red, &map->green, &map->blue)) 
    {
      TIFFError(TIFFFileName(image), "Missing required \"Colormap\" tag");
      OBJC_FREE(map);
      return NULL;
    }
  if (CheckAndCorrectColormap(map) == 8)
    TIFFWarning(TIFFFileName(image), "Assuming 8-bit colormap");

  free(info);
  return map;
}

#else /* HAVE_LIBTIFF */

TIFF* 
NSTiffOpenData(char* data, long size, const char* mode,
			    realloc_data_callback* realloc_data)
{
  return NULL;
}

int  
NSTiffClose(TIFF* image)
{
  return 0;
}

NSTiffInfo *      
NSTiffGetInfo(int imageNumber, TIFF* image)
{
  return NULL;
}

int
NSTiffRead(int imageNumber, TIFF* image, NSTiffInfo* info, char* data)
{
  return -1;
}

int  
NSTiffWrite(TIFF* image, NSTiffInfo* info, char* data)
{
  return -1;
}

NSTiffColormap *
NSTiffGetColormap(TIFF* image)
{
  return NULL;
}

#endif /* not HAVE_LIBTIFF */
