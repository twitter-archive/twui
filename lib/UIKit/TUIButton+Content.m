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

#import "TUIButton.h"

@interface TUIButtonContent : NSObject
{
	NSString *title;
	TUIColor *titleColor;
	TUIColor *shadowColor;
	TUIImage *image;
	TUIImage *backgroundImage;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) TUIColor *titleColor;
@property (nonatomic, retain) TUIColor *shadowColor;
@property (nonatomic, retain) TUIImage *image;
@property (nonatomic, retain) TUIImage *backgroundImage;

@end

@implementation TUIButtonContent

@synthesize title;
@synthesize titleColor;
@synthesize shadowColor;
@synthesize image;
@synthesize backgroundImage;

- (void)dealloc
{
	[title release];
	[titleColor release];
	[shadowColor release];
	[image release];
	[backgroundImage release];
	[super dealloc];
}

@end


@implementation TUIButton (Content)

- (TUIButtonContent *)_contentForState:(TUIControlState)state
{
	id key = [NSNumber numberWithInteger:state];
	TUIButtonContent *c = [_contentLookup objectForKey:key];
	if(!c) {
		c = [[TUIButtonContent alloc] init];
		[_contentLookup setObject:c forKey:key];
		[c release];
	}
	return c;
}

- (void)setTitle:(NSString *)title forState:(TUIControlState)state
{
	[[self _contentForState:state] setTitle:title];
	[self setNeedsDisplay];
}

- (void)setTitleColor:(TUIColor *)color forState:(TUIControlState)state
{
	[[self _contentForState:state] setTitleColor:color];
	[self setNeedsDisplay];
}

- (void)setTitleShadowColor:(TUIColor *)color forState:(TUIControlState)state
{
	[[self _contentForState:state] setShadowColor:color];
	[self setNeedsDisplay];
}

- (void)setImage:(TUIImage *)i forState:(TUIControlState)state
{
	[[self _contentForState:state] setImage:i];
	[self setNeedsDisplay];
}

- (void)setBackgroundImage:(TUIImage *)i forState:(TUIControlState)state
{
	[[self _contentForState:state] setBackgroundImage:i];
	[self setNeedsDisplay];
}

- (NSString *)titleForState:(TUIControlState)state
{
	return [[self _contentForState:state] title];
}

- (TUIColor *)titleColorForState:(TUIControlState)state
{
	return [[self _contentForState:state] titleColor];
}

- (TUIColor *)titleShadowColorForState:(TUIControlState)state
{
	return [[self _contentForState:state] shadowColor];
}

- (TUIImage *)imageForState:(TUIControlState)state
{
	return [[self _contentForState:state] image];
}

- (TUIImage *)backgroundImageForState:(TUIControlState)state
{
	return [[self _contentForState:state] backgroundImage];
}

- (NSString *)currentTitle
{
	return [self titleForState:self.state];
}

- (TUIColor *)currentTitleColor
{
	return [self titleColorForState:self.state];
}

- (TUIColor *)currentTitleShadowColor
{
	return [self titleShadowColorForState:self.state];
}

- (TUIImage *)currentImage
{
	return [self imageForState:self.state];
}

- (TUIImage *)currentBackgroundImage
{
	return [self backgroundImageForState:self.state];
}

@end
