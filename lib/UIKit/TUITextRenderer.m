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

#import "TUITextRenderer.h"
#import "TUITextRenderer+Event.h"
#import "TUIFont.h"
#import "TUIColor.h"
#import "TUIKit.h"
#import "CoreText+Additions.h"

@implementation TUITextRenderer

@synthesize attributedString;
@synthesize frame;
@synthesize view;
@synthesize hitRange;
@synthesize shadowColor;
@synthesize shadowOffset;
@synthesize shadowBlur;
@synthesize verticalAlignment;

- (void)_resetFrame
{
	if(_ct_frame) {
		CFRelease(_ct_frame);
		_ct_frame = NULL;
	}
	if(_ct_path) {
		CGPathRelease(_ct_path);
		_ct_path = NULL;
	}
}

- (void)_resetFramesetter
{
	if(_ct_framesetter) {
		CFRelease(_ct_framesetter);
		_ct_framesetter = NULL;
	}
	
	[self _resetFrame];
}

- (void)dealloc
{
	[attributedString release];
	[self _resetFramesetter];
	[hitRange release];
	[shadowColor release];
	[super dealloc];
}

- (void)_buildFrameWithEffectiveFrame:(CGRect)effectiveFrame
{
	_ct_path = CGPathCreateMutable();
	CGPathAddRect((CGMutablePathRef)_ct_path, NULL, effectiveFrame);
	_ct_frame = CTFramesetterCreateFrame(_ct_framesetter, CFRangeMake(0, 0), _ct_path, NULL);
}

- (void)_buildFrame
{
	if(!_ct_path) {
		[self _buildFrameWithEffectiveFrame:frame];
		
		// TUITextVerticalAlignmentTop is easy since that's how Core Text always draws. For Middle and Bottom we have to shift the CTFrame down.
		if(verticalAlignment != TUITextVerticalAlignmentTop) {
			CGRect effectiveFrame = frame;
			
			CGSize size = AB_CTFrameGetSize(_ct_frame);
			if(verticalAlignment == TUITextVerticalAlignmentMiddle) {
				effectiveFrame.origin.y -= size.height / 2;
			} else if(verticalAlignment == TUITextVerticalAlignmentBottom) {
				effectiveFrame.origin.y -= size.height;
			}
			
			effectiveFrame = CGRectIntegral(effectiveFrame);
			
			[self _resetFrame];
			[self _buildFrameWithEffectiveFrame:effectiveFrame];
		}
	}
}

- (void)_buildFramesetter
{
	if(!_ct_framesetter) {
		_ct_framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributedString);
	}
	
	[self _buildFrame];
}

- (CTFramesetterRef)ctFramesetter
{
	[self _buildFramesetter];
	return _ct_framesetter;
}

- (CTFrameRef)ctFrame
{
	[self _buildFramesetter];
	return _ct_frame;
}

- (CGPathRef)ctPath
{
	[self _buildFramesetter];
	return _ct_path;
}

- (CFIndex)_clampToValidRange:(CFIndex)index
{
	if(index < 0) return 0;
	CFIndex max = [attributedString length] - 1;
	if(index > max) return max;
	return index;
}

- (NSRange)_wordRangeAtIndex:(CFIndex)index
{
	return [attributedString doubleClickAtIndex:[self _clampToValidRange:index]];
}

- (NSRange)_lineRangeAtIndex:(CFIndex)index
{
	return [[attributedString string] lineRangeForRange:NSMakeRange(index, 0)];
}

- (NSRange)_paragraphRangeAtIndex:(CFIndex)index
{
	return [[attributedString string] paragraphRangeForRange:NSMakeRange(index, 0)];
}

- (CFRange)_selectedRange
{
	CFIndex first, last;
	if(_selectionStart <= _selectionEnd) {
		first = _selectionStart;
		last = _selectionEnd;
	} else {
		first = _selectionEnd;
		last = _selectionStart;
	}
	
	if(_selectionAffinity != TUITextSelectionAffinityCharacter) {
		NSRange fr = {0,0};
		NSRange lr = {0,0};
		
		switch(_selectionAffinity) {
			case TUITextSelectionAffinityCharacter:
				// do nothing
				break;
			case TUITextSelectionAffinityWord:
				fr = [self _wordRangeAtIndex:first];
				lr = [self _wordRangeAtIndex:last];
				break;
			case TUITextSelectionAffinityLine:
				fr = [self _lineRangeAtIndex:first];
				lr = [self _lineRangeAtIndex:last];
				break;
			case TUITextSelectionAffinityParagraph:
				fr = [self _paragraphRangeAtIndex:first];
				lr = [self _paragraphRangeAtIndex:last];
				break;
		}
		
		first = fr.location;
		last = lr.location + lr.length;
	}

	return CFRangeMake(first, last - first);
}

- (NSRange)selectedRange
{
	return ABNSRangeFromCFRange([self _selectedRange]);
}

- (void)setSelection:(NSRange)selection
{
	_selectionAffinity = TUITextSelectionAffinityCharacter;
	_selectionStart = selection.location;
	_selectionEnd = selection.location + selection.length;
	[view setNeedsDisplay];
}

- (NSString *)selectedString
{
	return [[attributedString string] substringWithRange:[self selectedRange]];
}

- (void)draw
{
	[self drawInContext:TUIGraphicsGetCurrentContext()];
}

- (void)drawInContext:(CGContextRef)context
{
	if(attributedString) {
		CGContextSaveGState(context);
		
		CTFrameRef f = [self ctFrame];
		
		if(_flags.preDrawBlocksEnabled && !_flags.drawMaskDragSelection) {
			[self.attributedString enumerateAttribute:TUIAttributedStringPreDrawBlockName inRange:NSMakeRange(0, [self.attributedString length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
				if(value == NULL) return;
				
				CGContextSaveGState(context);
				
				CFIndex rectCount = 100;
				CGRect rects[rectCount];
				CFRange r = {range.location, range.length};
				AB_CTFrameGetRectsForRangeWithAggregationType(f, r, (AB_CTLineRectAggregationType)[[self.attributedString attribute:TUIAttributedStringBackgroundFillStyleName atIndex:range.location effectiveRange:NULL] integerValue], rects, &rectCount);
				TUIAttributedStringPreDrawBlock block = value;
				block(self.attributedString, range, rects, rectCount);
				
				CGContextRestoreGState(context);
			}];
		}
		
		if(_flags.backgroundDrawingEnabled && !_flags.drawMaskDragSelection) {
			CGContextSaveGState(context);
			
			[self.attributedString enumerateAttribute:TUIAttributedStringBackgroundColorAttributeName inRange:NSMakeRange(0, [self.attributedString length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
				if(value == NULL) return;
				
				CGColorRef color = (CGColorRef) value;
				CGContextSetFillColorWithColor(context, color);
				
				CFIndex rectCount = 100;
				CGRect rects[rectCount];
				CFRange r = {range.location, range.length};
				AB_CTFrameGetRectsForRangeWithAggregationType(f, r, (AB_CTLineRectAggregationType)[[self.attributedString attribute:TUIAttributedStringBackgroundFillStyleName atIndex:range.location effectiveRange:NULL] integerValue], rects, &rectCount);
				for(CFIndex i = 0; i < rectCount; ++i) {
					CGRect r = rects[i];
					r = CGRectInset(r, -2, -1);
					r = CGRectIntegral(r);
					if(r.size.width > 1)
						CGContextFillRect(context, r);
				}
			}];
			
			CGContextRestoreGState(context);
		}
		
		if(hitRange && !_flags.drawMaskDragSelection) {
			// draw highlight
			CGContextSaveGState(context);
			
			NSRange _r = [hitRange rangeValue];
			CFRange r = {_r.location, _r.length};
			CFIndex nRects = 10;
			CGRect rects[nRects];
			AB_CTFrameGetRectsForRange(f, r, rects, &nRects);
			for(int i = 0; i < nRects; ++i) {
				CGRect rect = rects[i];
				rect = CGRectInset(rect, -2, -1);
				rect.size.height -= 1;
				rect = CGRectIntegral(rect);
				TUIColor *color = [TUIColor colorWithWhite:1.0 alpha:1.0];
				[color set];
				CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 8, color.CGColor);
				CGContextFillRoundRect(context, rect, 10);
			}
			
			CGContextRestoreGState(context);
		}
		
		CFRange selectedRange = [self _selectedRange];
		
		if(selectedRange.length > 0) {
			[[NSColor selectedTextBackgroundColor] set];
			// draw (or mask) selection
			CFIndex rectCount = 100;
			CGRect rects[rectCount];
			AB_CTFrameGetRectsForRange(f, selectedRange, rects, &rectCount);
			if(_flags.drawMaskDragSelection) {
				CGContextClipToRects(context, rects, rectCount);
			} else {
				for(CFIndex i = 0; i < rectCount; ++i) {
					CGRect r = rects[i];
					r = CGRectIntegral(r);
					if(r.size.width > 1)
						CGContextFillRect(context, r);
				}
			}
		}
		
		CGContextSetTextMatrix(context, CGAffineTransformIdentity);
		
		if(shadowColor)
			CGContextSetShadowWithColor(context, shadowOffset, shadowBlur, shadowColor.CGColor);

		CTFrameDraw(f, context); // draw actual text
				
		CGContextRestoreGState(context);
	}
}

- (CGSize)size
{
	if(attributedString) {
		return AB_CTFrameGetSize([self ctFrame]);
	}
	return CGSizeZero;
}

- (CGSize)sizeConstrainedToWidth:(CGFloat)width
{
	if(attributedString) {
		CGRect oldFrame = frame;
		self.frame = CGRectMake(0.0f, 0.0f, width, 1000000.0f);

		CGSize size = [self size];
		
		self.frame = oldFrame;
		
		return size;
	}
	return CGSizeZero;
}

- (void)setAttributedString:(NSAttributedString *)a
{
	[a retain];
	[attributedString release];
	attributedString = a;
	
	[self _resetFramesetter];
}

- (void)setFrame:(CGRect)f
{
	frame = f;
	[self _resetFrame];
}

- (void)reset
{
	[self _resetFramesetter];
}

- (CGRect)firstRectForCharacterRange:(CFRange)range
{
	CFIndex rectCount = 1;
	CGRect rects[rectCount];
	AB_CTFrameGetRectsForRange([self ctFrame], range, rects, &rectCount);
	if(rectCount > 0) {
		return rects[0];
	}
	return CGRectZero;
}

- (NSArray *)rectsForCharacterRange:(CFRange)range
{
	CFIndex rectCount = 100;
	CGRect rects[rectCount];
	AB_CTFrameGetRectsForRange([self ctFrame], range, rects, &rectCount);
	
	NSMutableArray *wrappedRects = [NSMutableArray arrayWithCapacity:rectCount];
	for(CFIndex i = 0; i < rectCount; i++) {
		[wrappedRects addObject:[NSValue valueWithRect:rects[i]]];
	}
	
	return [[wrappedRects copy] autorelease];
}

- (BOOL)backgroundDrawingEnabled
{
	return _flags.backgroundDrawingEnabled;
}

- (void)setBackgroundDrawingEnabled:(BOOL)enabled
{
	_flags.backgroundDrawingEnabled = enabled;
}

- (BOOL)preDrawBlocksEnabled
{
	return _flags.preDrawBlocksEnabled;
}

- (void)setPreDrawBlocksEnabled:(BOOL)enabled
{
	_flags.preDrawBlocksEnabled = enabled;
}

- (void)setVerticalAlignment:(TUITextVerticalAlignment)alignment
{
	if(verticalAlignment == alignment) return;
	
	verticalAlignment = alignment;
	
	[self _resetFrame];
}

@end
