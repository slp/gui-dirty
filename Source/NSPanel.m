/*
   NSPanel.m

   Panel window class and related functions

   Copyright (C) 1996 Free Software Foundation, Inc.

   NSPanel implementation
   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996

   GSAlertPanel and alert panel functions implementation
   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: 1998

   GSAlertPanel and alert panel functions cleanup and improvements (scroll view)
   Author: Pascal J. Bourguignon <pjb@imaginet.fr>
   Date: 2000-03-08

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include <gnustep/gui/config.h>

#include <Foundation/NSBundle.h>
#include <Foundation/NSCoder.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSBox.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSScreen.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/IMLoading.h>
#include <AppKit/GMAppKit.h>

#include <AppKit/GMArchiver.h>


/*
   PJB:
             SMALL TUTORIAL FOR C PROGRAMMERS WHO NEVER LEARNED
              A HIGH LEVEL LANGUAGE SUCH AS PASCAL OR MODULA-2


    A boolean variable can be true or false.
    A condition can be true of false.
    A pointer can be null or not.
    A integer can be 0 or not.

    Therefore, it should be obvious to everybody that :
        - a pointer IS NOT a condition;
        - an integer IS NOT a condition;
        - there is no need to compare a boolean to YES to know if it is true.

    And, given the following declarations:

        BOOL      active;
        NSString* title;

    we should not write:           but we should write:

        if(active==YES){                if(active){
            wrong();                        right();
        }                               }

        if(active==NO){                 if(!active){
            wrong();                        right();
        }                               }

        if(title){                      if(title!=nil){
            wrong();                        right();
        }                               }

        if(!title){                     if(title==nil){
            wrong();                        right();
        }                               }


    Writting if(active==YES){
    is as ludicrulus as writting:  if(((((active==YES)==YES)==YES)==YES)==YES){

    Moreover, you must know that defining YES and NO like this:

        #ifndef YES
        #define YES		1
        #endif YES
        #ifndef NO
        #define NO		0
        #endif NO

    Is not portable. For example,  the native value for the mc680x0 of
    true is  not 1, but  255 (0xff). Hence,  with a naive C -> mc680x0
    compiler we  could have  (active==YES)==YES being wrong,  and this
    would be OK as for C.  No C standard define that (0==0) must be 1,
    only that (0==0)!=0.


    The right way of defining YES and NO is:

    #undef  YES
    #define YES ((BOOL)(0==0))
    #undef  NO
    #define NO  ((BOOL)(0!=0))



    void PleaseWrite(bool isBetter,void* pointer,int value)
    {
        if((!isBetter)&&(pointer!=NULL)||(value==0)){
            print("Right!\n");
        }
    }//PleaseWrite;


    void DontBeSilly(bool isSilly,void* pointer,int value)
    {
        if((isSilly!=true)&&(pointer)||(!value)){
            print("Wrong!!\n");
        }
    }//DontBeSilly;




    PS: Note  the comment  at the end  of each method  duplicating the
        name of the same. Very  handy, isn't it? With them, you always
        know to what method belongs a statement. And what if you're in
        the middle of a method  and neither the header nor this ending
        comment is  visible, you'll ask?  Well, obviously, if  THIS is
        the case, then your method  is definitely TOO long, and should
        be structured somewhat more.

*/



@implementation	NSPanel

/*
 * Class methods
 */
+ (void)initialize
{
  if (self == [NSPanel class])
    {
      [self setVersion:1];
    }
}//initialize;


/*
 * Instance methods
 */
- (id) init
{
  int style = NSTitledWindowMask | NSClosableWindowMask;

  return [self initWithContentRect: NSZeroRect
			 styleMask: style
			   backing: NSBackingStoreBuffered
			     defer: NO];
}//init;


- (void) _initDefaults
{
  [super _initDefaults];
  [self setReleasedWhenClosed: NO];
  [self setHidesOnDeactivate: YES];
  [self setExcludedFromWindowsMenu: YES];
}//initDefaults;


- (BOOL) canBecomeKeyWindow
{
  if (_becomesKeyOnlyIfNeeded)
    return NO;
  return YES;
}//canBecomeKeyWindow;

- (BOOL) canBecomeMainWindow
{
  return NO;
}//canBecomeMainWindow;


/*
 * If we receive an escape, close.
 */
- (void) keyDown: (NSEvent*)theEvent
{
  if ([@"\e" isEqual: [theEvent charactersIgnoringModifiers]] &&
    ([self styleMask] & NSClosableWindowMask) == NSClosableWindowMask)
    [self close];
  else
    [super keyDown: theEvent];
}//keyDown:;


/*
 * Determining the Panel's Behavior
 */
- (BOOL) isFloatingPanel
{
  return _isFloatingPanel;
}//isFloatingPanel;


- (void) setFloatingPanel: (BOOL)flag
{
  if (_isFloatingPanel != flag)
    {
      _isFloatingPanel = flag;
      if (flag == YES)
	{
	  [self setLevel: NSFloatingWindowLevel];
	}
      else
	{
	  [self setLevel: NSNormalWindowLevel];
	}
    }
}//setFloatingPanel:;


- (BOOL) worksWhenModal
{
  return _worksWhenModal;
}//worksWhenModal;


- (void) setWorksWhenModal: (BOOL)flag
{
  _worksWhenModal = flag;
}//setWorksWhenModal:;


- (BOOL) becomesKeyOnlyIfNeeded
{
  return _becomesKeyOnlyIfNeeded;
}//becomesKeyOnlyIfNeeded;


- (void) setBecomesKeyOnlyIfNeeded: (BOOL)flag
{
  _becomesKeyOnlyIfNeeded = flag;
}//setBecomesKeyOnlyIfNeeded:;


/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
}//encodeWithCoder:;


- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  return self;
}//initWithCoder:;


@end /* NSPanel */


////////////////////////////////////////////////////////////////////////
// GSAlertPanel

/*

 +--------------------------------------------------------------------------+
 |############################Title bar#####################################|
 +--------------------------------------------------------------------------+
 |       |           |   |    |                                             |
 |  ...........      |   |    |                                             |
 |  :       | :      |   |    |                                             |
 |--:  Icon | :----Title |    |                                             |
 |  :-------|-:          |    |                                             |
 |  :.........:          |    |                                             |
 |                       |    |
 |-===========================|=============~~~~~~=========================-|
 |                       s    |                                             |
 |                       s    |                                             |
 |    ...................s....|.........................................    |
 |    :Message           s                    s                        ;    |
 |    :                  s                    s                        :    |
 |    :                  s                    s                        :    |
 |----:                  s                    s                        :----|
 |    :~~~~~~~~~~~~~~~~~~s~~~~~~~~~~~~~~~~~~~~s~~~~~~~~~~~~~~~~~~~~~~~~:    |
 |    :                  s                    s                        :    |
 |    :..................s.............................................:    |
 |             |         s                                                  |
 |             |         s +-----------+   +-----------+   +-----------+    |
 |             |         s |  Altern   |---|  Cancel   |---|    OK     |----|
 |             |         s +-----------+   +-----------+   +-----------+    |
 |             |         s      |                 |             |           |
 +--------------------------------------------------------------------------+

    Apart from  the buttons and window  borders, '|' and  '-' mean not
    flexible, while '~' and 's' mean flexible.

    The global  window size  is determined by  the message  text field
    size.  which  is computed with  sizeToFit. However, if  the window
    would become larger  than the screen, then the  message text field
    is replaced with a scroll view containing the text.


    The strategy taken  in this new version of  GSAlertPanel is to let
    the icon,  the title  field and the  line (box view)  being placed
    automatically  by  resizing  the   window,  but  to  always  place
    explicitely the  message field (or  scroll view when  it's needed)
    and  the buttons  (that may  change of  width), the  whole  in the
    sizeToFitIfNeeded  method.  We're  doing  it separately  from  the
    setting  of the elements  (setTitle:...) because  we also  need to
    recompute the size of the window and position of the elements when
    dearchiving a panel, because  it could be dearchived and displayed
    on a much smaller screen  than originaly created, in which case we
    needed to embed  the message field into a  scroll view, and reduce
    the size of the window.


    Some rules (which are implemented in sizePanelToFit):
    =====================================================


    IF   the messageField is too big either vertically or horizontally and
         would make the window greater than the screen in any direction,
    THEN use a scroll view.


    The width of the window is the minimum of:
        =  the screen width,
        =  the maximum of:
              =  a minimum width of 362,
              =  the messageField width + 2=MessageHorzMargin,
              =  the sum of sizes of the buttons and their interspaces
                 and margins,
              =  the sum of sizes of the icon, title and their interspaces
                 and margin.


    The height of the window is the minimum of:
        =  the screen height (minus the title bar height of the window),
        =  the maximum of:
              =  a minimum height of 161.
              =  the sum of:
                    =  The height of the icon, the line and their interspaces.
                    =  The height of the messageField and its interspaces,
                       if present.
                    =  The height of the buttons and their interspaces,
                       if present.


    The size of the scroll view must be at minimum ScrollMinSize
    in each direction.

    The size of the messageField is a given (sizeToFit).

    The height of the scroll is the rest of the height of the window minus
    the height of the other elements.

    The width of the scroll is the rest of the width of the window minus the
    margins.

    ((wsize.width<=ssize.width)
     and ([messageField frame].size.width+2*MessageHorzMargin<=wsize.width))
    or ((wsize.width==ssize.width)
        and ([scroll frame].size.width=wsize.width-2*MessageHorzMargin));

    ...
*/



@class	GSAlertPanel;

static GSAlertPanel*	standardAlertPanel=nil;
static GSAlertPanel*	informationalAlertPanel=nil;
static GSAlertPanel*	criticalAlertPanel=nil;
static GSAlertPanel*	gmodelAlertPanel=nil;


@interface	GSAlertPanel:NSPanel
{
    NSButton*	    defButton;
    NSButton*	    altButton;
    NSButton*	    othButton;
    NSButton*	    icoButton;
    NSTextField*	titleField;
    NSTextField*	messageField;
    NSScrollView*   scroll;
    int		        result;
    BOOL            isGreen;  // we were unarchived and not resized.
    //PJB: I removed the active flag. Please see the isActivePanel method below.
}

// NSPanel methods:

    -(id)initWithContentRect:(NSRect)r
                   styleMask:(unsigned)m
                     backing:(NSBackingStoreType)b
                       defer:(BOOL)d
                      screen:(NSScreen*)s;
        /*
            POST:       result!=nil => result->isGreen.
        */

    -(id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver;
        /*
            POST:       result!=nil => result->isGreen.
        */


    -(int)runModal;
        /*
            POST:       !(sef->isGreen).
        */


// GSAlertPanel methods:

    -(void)setTitle:(NSString*)title
            message:(NSString*)message
                def:(NSString*)defaultButton
                alt:(NSString*)alternateButton
              other:(NSString*)otherButton;
        /*
            POST:       self->isGreen.
        */


    -(void)sizePanelToFit;
        /*
            POST:       !(sef->isGreen).
        */

    -(void)buttonAction:(id)sender;
    -(int)result;
    -(BOOL)isActivePanel;


/*
    Note: You definitely don't want to pass to clients
          an instance i such as i->isGreen.
*/


@end //GSAlertPanel.


////////////////////////////////////////////////////////////////////////


@implementation	GSAlertPanel

    static const float WTitleHeight=24.0;      // TODO: Check this value.
    static const float WinMinWidth=362.0;
    static const float WinMinHeight=161.0;
    static const float IconSide=48.0;
    static const float IconBottom=-56.0;       // from the top of the window.
    static const float IconLeft=8.0;
    static const float TitleBottom=-40.0;      // from the top of the window.
    static const float TitleLeft=64.0;
    static const float TitleMinRight=8.0;
    static const float LineHeight=2.0;
    static const float LineBottom=-66.0;       // from the top of the window.
    static const float LineLeft=0.0;
    static const float ScrollMinSize=48.0;     // in either direction.
    static const float MessageHorzMargin=8.0;  // 5 is too little margin.
    static const float MessageMinHeight=20.0;
    static const float MessageVertMargin=6.0;  // from the top of the buttons.
    static const float MessageTop=-72;         // from the top of the window;
    static const float ButtonBottom=8.0;       // from the bottom of the window.
    static const float ButtonMargin=8.0;
    static const float ButtonInterspace=10.0;
    static const float ButtonMinHeight=24.0;
    static const float ButtonMinWidth=72.0;

#define MessageFont [NSFont systemFontOfSize: 14.0]
// TODO: Check on NeXTSTEP, I think that the message font size is only 12.0.



// Class methods:

    +(void)initialize
    {
        if(self==[GSAlertPanel class]){
            [self setVersion:1];
        }
    }//initialize;


    +(id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
    {
        unsigned backingType=[unarchiver decodeUnsignedIntWithName:
                                             @"backingType"];
        unsigned styleMask=[unarchiver decodeUnsignedIntWithName:@"styleMask"];
        NSRect aRect=[unarchiver decodeRectWithName:@"frame"];
        NSPanel* panel=[[[GSAlertPanel allocWithZone:[unarchiver objectZone]]
                            initWithContentRect:aRect
                            styleMask:styleMask backing:backingType defer:YES]
                           autorelease];
        return panel;
    }//createObjectForModelUnarchiver:(;


    -(void)dealloc
    {
        if (self==standardAlertPanel){
            standardAlertPanel=nil;
        }
        if (self==informationalAlertPanel){
            informationalAlertPanel=nil;
        }
        if (self==criticalAlertPanel){
            criticalAlertPanel=nil;
        }
        [defButton release];
        [altButton release];
        [othButton release];
        [icoButton release];
        [titleField release];
        [messageField release];
        [scroll release];
        [super dealloc];
    }//dealloc;


    -(void)encodeWithModelArchiver:(GMArchiver*)archiver
    {
        [super encodeWithModelArchiver: archiver];
        [archiver encodeSize:[self frame].size withName: @"OriginalSize"];
        [archiver encodeObject: defButton withName: @"DefaultButton"];
        [archiver encodeObject: altButton withName: @"AlternateButton"];
        [archiver encodeObject: othButton withName: @"OtherButton"];
        [archiver encodeObject: icoButton withName: @"IconButton"];
        [archiver encodeObject: messageField withName: @"MessageField"];
        [archiver encodeObject: titleField withName: @"TitleField"];
        // PJB: I don't know but probably we must not change the order in
        //      which the elements are archived, without changing the version.
    }//encodeWithModelArchiver:;



    static NSScrollView* makeScrollViewWithRect(NSRect rect)
    {
        float lineHeight=[MessageFont boundingRectForFont].size.height;
        NSScrollView* scroll=[[NSScrollView alloc]initWithFrame:rect];
        [scroll setBorderType:NSLineBorder];
        [scroll setBackgroundColor:[NSColor lightGrayColor]];
        [scroll setHasHorizontalScroller:YES];
        [scroll setHasVerticalScroller:YES];
        [scroll setScrollsDynamically:YES];
        [scroll setLineScroll:lineHeight];
        [scroll setPageScroll:lineHeight*10.0];
        return(scroll);
    }//makeScrollViewWithRect;


    -(NSButton*)_makeButtonWithRect:(NSRect)rect
    {
        NSButton* button=[[NSButton alloc] initWithFrame:rect];
        [button setAutoresizingMask: NSViewMinXMargin | NSViewMaxYMargin];
        [button setButtonType: NSMomentaryPushButton];
        [button setTitle: @""];
        [button setTarget: self];
        [button setAction: @selector(buttonAction:)];
        [button setFont: [NSFont systemFontOfSize: 12.0]];
        return(button);
    }//_makeButtonWithRect;


#define useControl(control)  ([control superview]!=nil)

    static void setControl(NSView* content,id control,NSString* title)
    {
        if(title!=nil){
            if([control respondsToSelector:@selector(setTitle:)]){
                [control setTitle:title];
            }
            if([control respondsToSelector:@selector(setStringValue:)]){
                [control setStringValue:title];
            }
            [control sizeToFit];
            if(!useControl(control)){
                [content addSubview:control];
            }
        }else if(useControl(control)){
            [control removeFromSuperview];
        }
    }//setControl;



    -(id)initWithContentRect:(NSRect)r
                   styleMask:(unsigned)m
                     backing:(NSBackingStoreType)b
                       defer:(BOOL)d
                      screen:(NSScreen*)s
    {
        self=[super initWithContentRect:r
                    styleMask:m
                    backing:b
                    defer:d
                    screen:s];
        if(self!=nil){
            NSRect	    rect;
            NSImage*    image;
            NSBox*      box;
            NSView*     content=[self contentView];

            [self setTitle: @" "];

            // we're an ATTENTION panel, therefore:
            [self setHidesOnDeactivate:NO]; 
            [self setBecomesKeyOnlyIfNeeded:NO];

            // First, the subviews that will be positioned automatically.

            rect.size.height=IconSide;
            rect.size.width=IconSide;
            rect.origin.y=r.origin.y+r.size.height+IconBottom;
            rect.origin.x=IconLeft;
            icoButton=[[NSButton alloc] initWithFrame: rect];
            [icoButton setAutoresizingMask:NSViewMaxXMargin|NSViewMinYMargin];
            [icoButton setBordered: NO];
            [icoButton setEnabled: NO];
            [icoButton setImagePosition: NSImageOnly];
            image=[[NSApplication sharedApplication] applicationIconImage];
            [icoButton setImage: image];
            [content addSubview:icoButton];


            rect.size.height=20.0; // will be sized to fit anyway.
            rect.size.width=80.0;  // will be sized to fit anyway.
            rect.origin.y=r.origin.y+r.size.height+TitleBottom;
            rect.origin.x=TitleLeft;
            titleField=[[NSTextField alloc] initWithFrame: rect];
            [titleField setAutoresizingMask: NSViewMinYMargin];
            [titleField setEditable: NO];
            [titleField setSelectable: YES];
            [titleField setBezeled: NO];
            [titleField setDrawsBackground: NO];
            [titleField setStringValue: @""];
            [titleField setFont: [NSFont systemFontOfSize: 18.0]];

            rect.size.height=LineHeight;
            rect.size.width=r.size.width;
            rect.origin.y=r.origin.y+r.size.height+LineBottom;
            rect.origin.x=LineLeft;
            box=[[NSBox alloc] initWithFrame: rect];
            [box setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
            [box setTitlePosition: NSNoTitle];
            [box setBorderType: NSGrooveBorder];
            [content addSubview: box];
            RELEASE(box);


            // Then, make the subviews that'll be sized by sizePanelToFit;

            rect.size.height=20.0;
            rect.size.width=80.0;
            rect.origin.y=0.0;
            rect.origin.x=0.0;

            messageField=[[NSTextField alloc] initWithFrame:rect];
            [messageField setEditable: NO];
            [messageField setSelectable: YES];
            /*
                PJB:
                How do you  want the user to report an error  message if it is
                not selectable?  Any text visible on the  screen should always
                be selectable for a copy-and-paste. Hence, setSelectable:YES.
            */
            [messageField setBezeled: NO];
            [messageField setDrawsBackground: YES];
            [messageField setBackgroundColor: [NSColor lightGrayColor]];
            [messageField setAlignment: NSCenterTextAlignment];
            [messageField setStringValue: @""];
            [messageField setFont: MessageFont];

            defButton=[self _makeButtonWithRect:rect];
            [defButton setKeyEquivalent: @"\r"];
            [defButton setImagePosition: NSImageRight];
            [defButton setImage: [NSImage imageNamed: @"common_ret"]];

            altButton=[self _makeButtonWithRect:rect];
            othButton=[self _makeButtonWithRect:rect];

            rect.size.height=80.0;
            scroll=makeScrollViewWithRect(rect);

            result=NSAlertErrorReturn;
            isGreen=YES;
        }
        return self;
    }//initWithContentRect:styleMask:backing:defer:screen:;


    -(id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
    {
        self=[super initWithModelUnarchiver: unarchiver];
        if(self!=nil){
            // TODO: Remove the following line when NSPanel archiver method will be implemented.
            [self setBecomesKeyOnlyIfNeeded:NO];

            (void)[unarchiver decodeSizeWithName:@"OriginalSize"];
            defButton=[[unarchiver decodeObjectWithName:@"DefaultButton"]
                          retain];
            altButton=[[unarchiver decodeObjectWithName:@"AlternateButton"]
                          retain];
            othButton=[[unarchiver decodeObjectWithName:@"OtherButton"]
                          retain];
            icoButton=[[unarchiver decodeObjectWithName:@"IconButton"]
                          retain];
            messageField=[[unarchiver decodeObjectWithName:@"MessageField"]
                             retain];
            titleField=[[unarchiver decodeObjectWithName:@"TitleField"]
                           retain];
            scroll=makeScrollViewWithRect(NSMakeRect(0.0,0.0,80.0,80.0));
            result=NSAlertErrorReturn;
            isGreen=YES;
        }
        gmodelAlertPanel=self;
        return gmodelAlertPanel;
    }//initWithModelUnarchiver:;


    -(void)sizePanelToFit
    {
        NSRect      bounds;
        NSSize      ssize;              // screen size (corrected).
        NSSize      bsize;              // button size (max of the three).
        NSSize      wsize={0.0,0.0};    // window size (computed).
        NSScreen*   screen;
        NSView*     content;
        NSButton*   buttons[3];
        float       position=0.0;
        int         numberOfButtons;
        int         i;
        BOOL        needsScroll;
        BOOL        couldNeedScroll;

        screen=[self screen];
        if(screen==nil){
            screen=[NSScreen mainScreen];
        }
        ssize=[screen frame].size;
        ssize.height-=WTitleHeight;


        // Let's size the title.
        if(useControl(titleField)){
            NSRect rect=[titleField frame];
            float  width=TitleLeft+rect.size.width+TitleMinRight;
            if(wsize.width<width){
                wsize.width=width;
                // ssize.width<width => the title will be silently clipped.
            }
        }

        wsize.height=-LineBottom;


        // Let's count the buttons.
        bsize.width=ButtonMinWidth;
        bsize.height=ButtonMinHeight;
        buttons[0]=defButton;
        buttons[1]=altButton;
        buttons[2]=othButton;
        numberOfButtons=0;
        for(i=0;i<3;i++){
            if(useControl(buttons[i])){
                NSRect rect=[buttons[i] frame];
                if(bsize.width<rect.size.width){
                    bsize.width=rect.size.width;
                }
                if(bsize.height<rect.size.height){
                    bsize.height=rect.size.height;
                }
                numberOfButtons++;
            }
        }

        if(numberOfButtons>0){
            // (with NSGetAlertPanel, there could be zero buttons).
            float width=(bsize.width+ButtonInterspace)*numberOfButtons
                        -ButtonInterspace+ButtonMargin*2;
            // If the buttons are too wide or too high to fit in the screen,
            // then too bad! Thought it would be simple enough to put them
            // in the scroll view with the messageField.
            // TODO: See if we raise an exception here or if we let the
            //       QA people detect this kind of problem.
            if(wsize.width<width){
                wsize.width=width;
            }
            wsize.height+=ButtonBottom+bsize.height;
        }



        // Let's see the size of the messageField and how to place it.
        needsScroll=NO;
        couldNeedScroll=useControl(messageField);
        if(couldNeedScroll){
            NSRect rect=[messageField frame];
            float  width=rect.size.width+2*MessageHorzMargin;
            if(wsize.width<width){
                wsize.width=width;
            }
            // The title could be large too, without implying a scroll view.
            needsScroll=(ssize.width<width);
            // But only the messageField can impose a great height, therefore
            // we check it along in the next paragraph.
            wsize.height+=rect.size.height+2*MessageVertMargin;
        }else{
            wsize.height+=MessageVertMargin;
        }


        // Strategically placed here, we resize the window.
        if(ssize.height<wsize.height){
            wsize.height=ssize.height;
            needsScroll=couldNeedScroll;
        }else if(wsize.height<WinMinHeight){
            wsize.height=WinMinHeight;
        }
        if(needsScroll){
            wsize.width+=[NSScroller scrollerWidth]+4.0;
        }
        if(ssize.width<wsize.width){
            wsize.width=ssize.width;
        }else if(wsize.width<WinMinWidth){
            wsize.width=WinMinWidth;
        }
        [self setMaxSize:wsize];
        [self setMinSize:wsize];
        [self setContentSize:wsize];
        content=[self contentView];
        bounds=[content bounds];


        // Now we can place the buttons.
        if(numberOfButtons>0){
            position=bounds.origin.x+bounds.size.width-ButtonMargin;
            for(i=0;i<3;i++){
                if(useControl(buttons[i])){
                    NSRect rect;
                    position-=bsize.width;
                    rect.origin.x=position;
                    rect.origin.y=bounds.origin.y+ButtonBottom;
                    rect.size.width=bsize.width;
                    rect.size.height=bsize.height;
                    [buttons[i] setFrame:rect];
                    position-=ButtonInterspace;
                }
            }
        }


        // Finaly, place the message.
        if(useControl(messageField)){
            NSRect mrect=[messageField frame];
            if(needsScroll){
                NSRect srect;
                // The scroll view takes all the space that is available.
                srect.origin.x=bounds.origin.x+MessageHorzMargin;
                if(numberOfButtons>0){
                    srect.origin.y=bounds.origin.y+ButtonBottom
                            +bsize.height+MessageVertMargin;
                }else{
                    srect.origin.y=bounds.origin.y+MessageVertMargin;
                }
                srect.size.width=bounds.size.width-2*MessageHorzMargin;
                srect.size.height=bounds.origin.y+bounds.size.height
                        +MessageTop-srect.origin.y;
                [scroll setFrame:srect];
                if(!useControl(scroll)){
                    [content addSubview:scroll];
                }
                [messageField removeFromSuperview];
                mrect.origin.x=srect.origin.x+srect.size.width-mrect.size.width;
                mrect.origin.y=srect.origin.y+srect.size.height
                                             -mrect.size.height;
                [messageField setFrame:mrect];
                [scroll setDocumentView:messageField];
                [[scroll contentView]scrollToPoint:NSMakePoint(mrect.origin.x,
                        mrect.origin.y+mrect.size.height
                        -[[scroll contentView] bounds].size.height)];
                [scroll reflectScrolledClipView:[scroll contentView]];
            }else{
                float  vmargin;
                // We must center vertically the messageField because
                // the window has a minimum size, thus may be greated 
                // than expected.
                mrect.origin.x=bounds.origin.x+MessageHorzMargin;
                vmargin=bounds.size.height+LineBottom-mrect.size.height;
                if(numberOfButtons>0){
                    vmargin-=ButtonBottom+bsize.height;
                }
                vmargin/=2.0; // if negative, it'll bite up and down.
                mrect.origin.y=bounds.origin.y+vmargin;
                if(numberOfButtons>0){
                    mrect.origin.y+=ButtonBottom+bsize.height;
                }
                [messageField setFrame:mrect];
            }
        }else if(useControl(scroll)){
            [scroll removeFromSuperview];
        }

        isGreen=NO;
        [content display];
    }//sizePanelToFit;



    -(void)buttonAction:(id)sender
     {
        if(![self isActivePanel]){
            NSLog(@"alert panel buttonAction: when not in modal loop\n");
            return;
        }else if(sender==defButton){
            result=NSAlertDefaultReturn;
        }else if(sender==altButton){
            result=NSAlertAlternateReturn;
        }else if(sender==othButton){
            result=NSAlertOtherReturn;
        }else{
            NSLog(@"alert panel buttonAction: from unknown sender - x%x\n",
                  (unsigned)sender);
        }
        [[NSApplication sharedApplication] stopModal];
    }//buttonAction:;


    -(int)result
    {
        return result;
    }//result;


    -(BOOL)isActivePanel
    {
        return([[NSApplication sharedApplication]modalWindow]==self);
    }//isActivePanel;


    -(int)runModal
    {
        if(isGreen){
            [self sizePanelToFit];
        }
        [NSApp runModalForWindow: self];
        [self orderOut: self];
        return result;
    }//runModal;



    -(void)setTitle:(NSString*)title
            message:(NSString*)message
                def:(NSString*)defaultButton
                alt:(NSString*)alternateButton
              other:(NSString*)otherButton
    {
        NSView* content=[self contentView];
        setControl(content,titleField,title);
        // TODO: Remove the following line once NSView is corrected.
        [scroll setDocumentView:nil];
        [scroll       removeFromSuperview];
        [messageField removeFromSuperview];
        setControl(content,messageField,message);
        setControl(content,defButton,defaultButton);
        setControl(content,altButton,alternateButton);
        setControl(content,othButton,otherButton);
        if(useControl(defButton)){
            [self makeFirstResponder: defButton];
        }else{
            [self makeFirstResponder: self];
        }
        isGreen=YES;
        result=NSAlertErrorReturn;	/* If no button was pressed	*/
    }//setTitle:message:def:alt:other:;


@end /* GSAlertPanel */

//  END GSAlertPanel
////////////////////////////////////////////////////////////////////////



    /*
      These functions may be called "recursively". For example, from a
      timed event. Therefore, there  may be several alert panel active
      at  the  same  time,  but   only  the  first  one  will  be  THE
      standardAlertPanel,  which will  not be  released  once finished
      with, but which will be kept for future use.

               +---------+---------+---------+---------+---------+
               | std!=0  | std act | pan=std | pan=new | std=new |
               +---------+---------+---------+---------+---------+
         a:    |    F    |   N/A   |         |    X    |    X    |
               +---------+---------+---------+---------+---------+
         b:    |    V    |    F    |    X    |         |         |
               +---------+---------+---------+---------+---------+
         c:    |    V    |    V    |         |    X    |         |
               +---------+---------+---------+---------+---------+
    */


#define NEW_PANEL [[GSAlertPanel alloc]                                   \
        initWithContentRect: NSMakeRect(0.0,0.0,WinMinWidth,WinMinHeight) \
        styleMask: NSTitledWindowMask                                     \
        backing: NSBackingStoreRetained                                   \
        defer: YES                                                        \
        screen: nil]

    /*
            if(![GMModel loadIMFile:@"AlertPanel" owner:[GSAlertPanel alloc]]){
                NSLog(@"cannot open alert panel model file\n");
                return nil;
            }
    */

/*
    TODO: Check if this discrepancy is wanted and needed.
          If not, we could merge these parameters, even
          for the alert panel, setting its window title to "Alert".



*/

    static GSAlertPanel* getSomePanel(GSAlertPanel** instance,
                                      NSString* defaultTitle,
                                      NSString* title,
                                      NSString* message,
                                      NSString* defaultButton,
                                      NSString* alternateButton,
                                      NSString* otherButton)
    {
        GSAlertPanel*	panel;

        if((*instance)!=0){
            if([(*instance) isActivePanel]){       // c:
                panel=NEW_PANEL;

            }else{                                 // b:
                panel=(*instance);
            }
        }else{                                     // a:
            panel=NEW_PANEL;
            (*instance)=panel;
        }

        if(title==nil){
            title=defaultTitle;
        }

        if(defaultTitle!=nil){
            [panel setTitle:defaultTitle];
        }
        [panel setTitle: title
               message: message
               def: defaultButton
               alt: alternateButton
               other: otherButton];
        [panel sizePanelToFit];
        return panel;
    }//getSomePanel;


    id NSGetAlertPanel(NSString* title,
                       NSString* msg,
                       NSString* defaultButton,
                       NSString* alternateButton,
                       NSString* otherButton, ...)
    {
        va_list	        ap;
        NSString*	    message;

        va_start(ap,otherButton);
        message=[NSString stringWithFormat:msg arguments:ap];
        va_end(ap);

        return(getSomePanel(&standardAlertPanel,
#ifndef STRICT_OPENSTEP
                            @"Alert",
#else
                            @" ",
#endif
                            title,message,
                            defaultButton,alternateButton,otherButton));
    }//NSGetAlertPanel;



    int NSRunAlertPanel(NSString *title,
            NSString *msg,
            NSString *defaultButton,
            NSString *alternateButton,
            NSString *otherButton, ...)
    {
        va_list	        ap;
        NSString*	    message;
        GSAlertPanel*   panel;
        int             result;

        va_start(ap,otherButton);
        message=[NSString stringWithFormat:msg arguments:ap];
        va_end(ap);

        if(defaultButton==nil){
            defaultButton=@"OK";
        }

        panel=getSomePanel(&standardAlertPanel,
#ifndef STRICT_OPENSTEP
                           @"Alert",
#else
                           @" ",
#endif
                           title,message,
                           defaultButton,alternateButton,otherButton);
        result=[panel runModal];
        NSReleaseAlertPanel(panel);
        return(result);
    }//NSRunAlertPanel;


    int NSRunLocalizedAlertPanel(NSString *table,
                                 NSString *title,
                                 NSString *msg,
                                 NSString *defaultButton,
                                 NSString *alternateButton,
                                 NSString *otherButton, ...)
    {
        va_list	        ap;
        NSString*	    message;
        GSAlertPanel*   panel;
        int             result;
        NSBundle*       bundle=[NSBundle mainBundle];

        if(title==nil){
#ifndef STRICT_OPENSTEP
            title=@"Alert";
#else
            title=@" ";
#endif
        }

#define localize(string) if(string!=nil) \
        string=[bundle localizedStringForKey:string value:string table:table]

        localize(title);
        localize(defaultButton);
        localize(alternateButton);
        localize(otherButton);
        localize(msg);

#undef localize

        va_start(ap,otherButton);
        message=[NSString stringWithFormat:msg arguments:ap];
        va_end(ap);

        if(defaultButton==nil){
            defaultButton=@"OK";
        }

        panel=getSomePanel(&standardAlertPanel,@"Alert",//anyway,title!=nil.
                           title,message,
                           defaultButton,alternateButton,otherButton);
        result=[panel runModal];
        NSReleaseAlertPanel(panel);
        return(result);
    }//NSRunLocalizedAlertPanel;



    id NSGetCriticalAlertPanel(NSString* title,
                               NSString* msg,
                               NSString* defaultButton,
                               NSString* alternateButton,
                               NSString* otherButton, ...)
    {
        va_list	        ap;
        NSString*	    message;

        va_start(ap,otherButton);
        message=[NSString stringWithFormat:msg arguments:ap];
        va_end(ap);

        return(getSomePanel(&criticalAlertPanel,@"Critical",
                            title,message,
                            defaultButton,alternateButton,otherButton));
    }//NSGetCriticalAlertPanel;


    int NSRunCriticalAlertPanel(NSString *title,
                                NSString *msg,
                                NSString *defaultButton,
                                NSString *alternateButton,
                                NSString *otherButton, ...)
    {
        va_list	        ap;
        NSString*	    message;
        GSAlertPanel*   panel;
        int             result;

        va_start(ap,otherButton);
        message=[NSString stringWithFormat:msg arguments:ap];
        va_end(ap);

        panel=getSomePanel(&criticalAlertPanel,@"Critical",
                            title,message,
                            defaultButton,alternateButton,otherButton);
        result=[panel runModal];
        NSReleaseAlertPanel(panel);
        return(result);
    }//NSRunCriticalAlertPanel;


    id NSGetInformationalAlertPanel(NSString* title,
                                    NSString* msg,
                                    NSString* defaultButton,
                                    NSString* alternateButton,
                                    NSString* otherButton, ...)
    {
        va_list	        ap;
        NSString*	    message;

        va_start(ap,otherButton);
        message=[NSString stringWithFormat:msg arguments:ap];
        va_end(ap);

        return(getSomePanel(&informationalAlertPanel,
                            @"Information",
                            title,message,
                            defaultButton,alternateButton,otherButton));
    }//NSGetInformationalAlertPanel;


    int NSRunInformationalAlertPanel(NSString *title,
                NSString *msg,
                NSString *defaultButton,
                NSString *alternateButton,
                NSString *otherButton, ...)
     {
        va_list	        ap;
        NSString*	    message;
        GSAlertPanel*   panel;
        int             result;

        va_start(ap,otherButton);
        message=[NSString stringWithFormat:msg arguments:ap];
        va_end(ap);

        panel=getSomePanel(&informationalAlertPanel,
                            @"Information",
                            title,message,
                            defaultButton,alternateButton,otherButton);
        result=[panel runModal];
        NSReleaseAlertPanel(panel);
        return(result);
    }//NSRunInformationalAlertPanel;


    void NSReleaseAlertPanel(id alertPanel)
    {
        if((alertPanel!=standardAlertPanel)
         &&(alertPanel!=informationalAlertPanel)
         &&(alertPanel!=criticalAlertPanel)){
            [alertPanel release];
        }
    }//NSReleaseAlertPanel;



/*** NSPanel.m                        -- 2000-03-08 05:15:47 -- PJB ***/
