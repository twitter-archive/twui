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

#import "TUITableView+Cell.h"

@implementation TUITableView (Cell)

/**
 * @brief Mouse down in a cell
 */
-(void)__mouseDownInCell:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event {
  [_referenceDragToReorderIndexPath release];
  _referenceDragToReorderIndexPath = [cell.indexPath retain];
  [_currentDragToReorderIndexPath release];
  _currentDragToReorderIndexPath = [cell.indexPath retain];
  [_previousDragToReorderIndexPath release];
  _previousDragToReorderIndexPath = [cell.indexPath retain];
}

/**
 * @brief Mouse up in a cell
 */
-(void)__mouseUpInCell:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event {
  [_referenceDragToReorderIndexPath release];
  _referenceDragToReorderIndexPath = nil;
  [_currentDragToReorderIndexPath release];
  _currentDragToReorderIndexPath = nil;
  [_previousDragToReorderIndexPath release];
  _previousDragToReorderIndexPath = nil;
}

/**
 * @brief A cell was dragged
 * 
 * If reordering is permitted by the table, this will begin a move operation.
 */
-(void)__mouseDraggedCell:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event {
  
  // determine if reordering this cell is permitted or not via our delegate
  if(self.delegate == nil || ![self.delegate respondsToSelector:@selector(tableView:allowsReorderingOfRowAtIndexPath:)] || ![self.delegate tableView:self allowsReorderingOfRowAtIndexPath:cell.indexPath]){
    return; // reordering cells is not permitted
  }
  
  CGPoint location = [[cell superview] localPointForEvent:event];
  CGRect visible = [self visibleRect];
  
  // dragged cell destination frame
  CGRect dest = CGRectMake(0, roundf(MAX(0, MIN(visible.origin.y + visible.size.height - cell.frame.size.height, location.y + visible.origin.y - offset.y))), self.bounds.size.width, cell.frame.size.height);
  
  // determine the current index path the cell is occupying
  TUIFastIndexPath *currentPath;
  if((currentPath = [self indexPathForRowAtPoint:CGPointMake(location.x, location.y + visible.origin.y)]) != nil){
    // allow the delegate to revise the proposed index path if it wants to
    if(self.delegate != nil && [self.delegate respondsToSelector:@selector(tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:)]){
      currentPath = [self.delegate tableView:self targetIndexPathForMoveFromRowAtIndexPath:cell.indexPath toProposedIndexPath:currentPath];
    }
  }
  
  // note the previous path
  [_previousDragToReorderIndexPath release];
  _previousDragToReorderIndexPath = [_currentDragToReorderIndexPath retain];
  
  // determine the current drag direction
  NSComparisonResult currentDragDirection = (_previousDragToReorderIndexPath != nil) ? [currentPath compare:_previousDragToReorderIndexPath] : NSOrderedSame;
  
  // we now have the final destination index path.  if it's not nil, update surrounding
  // cells to make room for the dragged cell
  if(currentPath != nil && (_currentDragToReorderIndexPath == nil || ![currentPath isEqual:_currentDragToReorderIndexPath])){
    TUIFastIndexPath *previousPath = (_currentDragToReorderIndexPath == nil) ? cell.indexPath : _currentDragToReorderIndexPath;
    
    // determine whether we're above or below the original index path and handle the
    // reordering accodringly
    if(currentDragDirection == NSOrderedAscending){
      NSLog(@"Above: %@", currentPath);
      CGFloat adjust = ([currentPath compare:cell.indexPath] == NSOrderedDescending) ? 1 : 0;
      
      int irow = currentPath.row;
      for(int i = currentPath.section; i < [self numberOfSections]; i++){
        for(int j = irow; j < [self numberOfRowsInSection:i]; j++){
          TUIFastIndexPath *path = [TUIFastIndexPath indexPathForRow:j inSection:i];
          TUITableViewCell *displacedCell;
          if([path isEqual:_previousDragToReorderIndexPath]){
            goto done; // stop when we hit the original row
          }else if((displacedCell = [self cellForRowAtIndexPath:path]) != nil){
            CGRect frame = [self rectForRowAtIndexPath:path];
            displacedCell.frame = CGRectMake(frame.origin.x, frame.origin.y - cell.frame.size.height, frame.size.width, frame.size.height);
          }
        }
        irow = 0;
      }
      
    }else if(currentDragDirection == NSOrderedDescending){
      NSLog(@"Below: %@ (%@)", currentPath, _previousDragToReorderIndexPath);
      CGFloat adjust = ([currentPath compare:cell.indexPath] == NSOrderedDescending) ? 0 : 1;
      
      int irow = _previousDragToReorderIndexPath.row;
      for(int i = _previousDragToReorderIndexPath.section; i < [self numberOfSections]; i++){
        for(int j = irow; j < [self numberOfRowsInSection:i]; j++){
          TUIFastIndexPath *path = [TUIFastIndexPath indexPathForRow:j inSection:i];
          TUITableViewCell *displacedCell;
          if((displacedCell = [self cellForRowAtIndexPath:path]) != nil){
            CGRect frame = [self rectForRowAtIndexPath:path];
            displacedCell.frame = CGRectMake(frame.origin.x, frame.origin.y + (cell.frame.size.height * adjust), frame.size.width, frame.size.height);
          }
          if([path isEqual:currentPath]){
            goto done; // stop when we hit the current row
          }
        }
        irow = 0;
      }
      
    }
    
  }
  
done:
  // note the current path
  [_currentDragToReorderIndexPath release];
  _currentDragToReorderIndexPath = [currentPath retain];
  
  // bring to front
  [[cell superview] bringSubviewToFront:cell];
  // move the cell
  cell.frame = dest;
  
}

@end

