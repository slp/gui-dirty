/* 
   nsimage-tiff.h 

   Functions for dealing with tiff images

   Copyright (C) 1996 Free Software Foundation, Inc.
   
   Written by:  Adam Fedor <fedor@colorado.edu>
   Date: Feb 1996
   
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
/*
    Warning:  This header file should not be used for reading and
    writing tiff files.  You should use the NSImage and NSBitmapImageRep
    classes for general reading/writting of tiff files.
*/

#ifndef _GNUstep_H_tiff
#define _GNUstep_H_tiff

#ifdef HAVE_TIFF
#include <tiffio.h>
#else
#define TIFF void
#endif
#include <sys/types.h>

/* Structure to store common information about a tiff. */
typedef struct {
    u_long  imageNumber;
    u_long  subfileType;
    u_long  width;
    u_long  height;
    u_short bitsPerSample;    /* number of bits per data channel */
    u_short samplesPerPixel;  /* number of channels per pixel */
    u_short planarConfig;     /* meshed or separate */
    u_short photoInterp;      /* photometric interpretation of bitmap data, */
    u_short compression;
    int     numImages;	      /* number of images in tiff */
    int     error;
} NSTiffInfo; 

typedef struct {
    u_int    size;
    u_short *red;
    u_short *green;
    u_short *blue;
} NSTiffColormap;

typedef char* realloc_data_callback(char* data, long size);

extern TIFF* NSTiffOpenData(char* data, long size, const char* mode,
			    realloc_data_callback* realloc_data);
extern int   NSTiffClose(TIFF* image);

extern int   NSTiffWrite(TIFF* image, NSTiffInfo* info, char* data);
extern int   NSTiffRead(int imageNumber, TIFF* image, NSTiffInfo* info, 
			char* data);
extern NSTiffInfo* NSTiffGetInfo(int imageNumber, TIFF* image);

extern NSTiffColormap* NSTiffGetColormap(TIFF* image);

#endif // _GNUstep_H_tiff

