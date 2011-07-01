/*
 Copyright 2011 Twitter, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this work except in compliance with the License.
 You may obtain a copy of the License in the LICENSE file, or at:
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "ExampleAppDelegate.h"
#import "ExampleView.h"

@implementation ExampleAppDelegate

- (void)dealloc
{
	[window release];
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	CGRect b = CGRectMake(0, 0, 500, 450);
	
	window = [[NSWindow alloc] initWithContentRect:b 
										 styleMask:NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask 
										   backing:NSBackingStoreBuffered 
											 defer:NO];
	[window setMinSize:NSMakeSize(300, 250)];
	[window center];

	/*
	 TUINSView is the bridge between the standard AppKit NSView-based heirarchy and the TUIView-based heirarchy
	 */
	TUINSView *tuiContainer = [[TUINSView alloc] initWithFrame:b];
	[window setContentView:tuiContainer];
	[tuiContainer release];
	
	ExampleView *example = [[ExampleView alloc] initWithFrame:b];
	tuiContainer.rootView = example;
	[example release];
	
	[window makeKeyAndOrderFront:nil];
}

@end
