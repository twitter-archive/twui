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

#import "TUITableViewSectionHeader.h"

@implementation TUITableViewSectionHeader

/**
 * @brief Determine if this header is currently pinned to the viewport
 * 
 * This method should return TRUE whenever the header is not occupying
 * it's normal frame and is overlaping row content.
 */
-(BOOL)isPinnedToViewport {
  return _isPinnedToViewport;
}

/**
 * @brief Specify whether this header is currently pinned to the viewport
 * @note You should not need to set this property directly, it is managed
 * by the table view.
 */
-(void)setPinnedToViewport:(BOOL)pinned {
  if(_isPinnedToViewport != pinned){
    if(pinned) [self headerWillBecomePinned];
    else [self headerWillBecomeUnpinned];
  }
  _isPinnedToViewport = pinned;
}

/**
 * @brief The header will become pinned
 * 
 * Subclasses may override this method to change the appearance of the header
 * when it becomes pinned to the viewport.
 */
-(void)headerWillBecomePinned {
  [self setNeedsDisplay];
}

/**
 * @brief The header will become unpinned
 * 
 * Subclasses may override this method to change the appearance of the header
 * when it becomes unpinned from the viewport.
 */
-(void)headerWillBecomeUnpinned {
  [self setNeedsDisplay];
}

@end
