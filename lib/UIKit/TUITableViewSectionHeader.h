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

#import "TUIView.h"

/**
 * @brief An optional base for section header views
 * 
 * A view used as a section header may optionally extend this class,
 * in which case the view will recieve messages about header state.
 */
@interface TUITableViewSectionHeader : TUIView {
  
  BOOL  _isPinnedToViewport;
  
}

-(void)headerWillBecomePinned;
-(void)headerWillBecomeUnpinned;

@property (readwrite, assign, getter=isPinnedToViewport) BOOL pinnedToViewport;

@end
