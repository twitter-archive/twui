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
  [_currentDragToReorderIndexPath release];
  _currentDragToReorderIndexPath = nil;
  [_previousDragToReorderIndexPath release];
  _previousDragToReorderIndexPath = nil;
}

/**
 * @brief Mouse up in a cell
 */
-(void)__mouseUpInCell:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event {
  BOOL animate = TRUE;
  
  // finalize drag to reorder if we have a drag index
  if(_currentDragToReorderIndexPath != nil){
    
    // notify our data source that the row must be reordered
    if(self.dataSource != nil && [self.dataSource respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)]){
      [self.dataSource tableView:self moveRowAtIndexPath:cell.indexPath toIndexPath:_currentDragToReorderIndexPath];
    }
    
    // animate the cell to the destination index path
    if(animate) [TUIView beginAnimations:NSStringFromSelector(_cmd) context:NULL];
    cell.frame = [self rectForRowAtIndexPath:_currentDragToReorderIndexPath];
    if(animate) [TUIView commitAnimations];
    
    // clear state
    [_currentDragToReorderIndexPath release];
    _currentDragToReorderIndexPath = nil;
    
  }
  
  [_previousDragToReorderIndexPath release];
  _previousDragToReorderIndexPath = nil;
  
}

/**
 * @brief A cell was dragged
 * 
 * If reordering is permitted by the table, this will begin a move operation.
 */
-(void)__mouseDraggedCell:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event {
  BOOL animate = TRUE;
  
  // make sure reordering is supported by our data source (this should probably be done only once somewhere)
  if(self.dataSource == nil || ![self.dataSource respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)]){
    return; // reordering is not supported by the data source
  }
  
  // determine if reordering this cell is permitted or not via our data source (this should probably be done only once somewhere)
  if(self.dataSource == nil || ![self.dataSource respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)] || ![self.dataSource tableView:self canMoveRowAtIndexPath:cell.indexPath]){
    return; // reordering is not permitted
  }
  
  // initialize defaults on the first drag
  if(_currentDragToReorderIndexPath == nil || _previousDragToReorderIndexPath == nil){
    [_currentDragToReorderIndexPath release];
    _currentDragToReorderIndexPath = [cell.indexPath retain];
    [_previousDragToReorderIndexPath release];
    _previousDragToReorderIndexPath = [cell.indexPath retain];
    return; // just initialize on the first one
  }
  
  CGPoint location = [[cell superview] localPointForEvent:event];
  CGRect visible = [self visibleRect];
  
  // dragged cell destination frame
  CGRect dest = CGRectMake(0, roundf(MAX(0, MIN(visible.origin.y + visible.size.height - cell.frame.size.height, location.y + visible.origin.y - offset.y))), self.bounds.size.width, cell.frame.size.height);
  // bring to front
  [[cell superview] bringSubviewToFront:cell];
  // move the cell
  cell.frame = dest;
  
  // determine the current index path the cell is occupying
  TUIFastIndexPath *currentPath;
  if((currentPath = [self indexPathForRowAtPoint:CGPointMake(location.x, location.y + visible.origin.y)]) != nil){
    // allow the delegate to revise the proposed index path if it wants to
    if(self.delegate != nil && [self.delegate respondsToSelector:@selector(tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:)]){
      currentPath = [self.delegate tableView:self targetIndexPathForMoveFromRowAtIndexPath:cell.indexPath toProposedIndexPath:currentPath];
    }
  }
  
  // make sure we have a valid current path before proceeding
  if(currentPath == nil) return;
  
  // note the previous path
  [_previousDragToReorderIndexPath release];
  _previousDragToReorderIndexPath = [_currentDragToReorderIndexPath retain];
  // note the current path
  [_currentDragToReorderIndexPath release];
  _currentDragToReorderIndexPath = [currentPath retain];
  
  // determine the current drag direction
  NSComparisonResult currentDragDirection = (_previousDragToReorderIndexPath != nil) ? [currentPath compare:_previousDragToReorderIndexPath] : NSOrderedSame;
  
  // ordered index paths for enumeration
  TUIFastIndexPath *fromIndexPath = nil;
  TUIFastIndexPath *toIndexPath = nil;
  
  if(currentDragDirection == NSOrderedAscending){
    fromIndexPath = currentPath;
    toIndexPath = _previousDragToReorderIndexPath;
  }else if(currentDragDirection == NSOrderedDescending){
    fromIndexPath = _previousDragToReorderIndexPath;
    toIndexPath = currentPath;
  }else{
    // same index path; nil
  }
  
  // we now have the final destination index path.  if it's not nil, update surrounding
  // cells to make room for the dragged cell
  if(currentPath != nil && fromIndexPath != nil && toIndexPath != nil){
    NSComparisonResult relativeDirection = [currentPath compare:cell.indexPath];
    
    // begin animations
    if(animate){
      [TUIView beginAnimations:NSStringFromSelector(_cmd) context:NULL];
    }
    
    for(int i = fromIndexPath.section; i <= toIndexPath.section; i++){
      TUIView *headerView;
      if(currentPath.section < i && i <= cell.indexPath.section){
        // the current index path is above this section and this section is at or
        // below the origin index path; shift our header down to make room
        if((headerView = [self headerViewForSection:i]) != nil){
          CGRect frame = [self rectForHeaderOfSection:i];
          headerView.frame = CGRectMake(frame.origin.x, frame.origin.y - cell.frame.size.height, frame.size.width, frame.size.height);
        }
      }else if(currentPath.section >= i && i > cell.indexPath.section){
        // the current index path is at or below this section and this section is
        // below the origin index path; shift our header up to make room
        if((headerView = [self headerViewForSection:i]) != nil){
          CGRect frame = [self rectForHeaderOfSection:i];
          headerView.frame = CGRectMake(frame.origin.x, frame.origin.y + cell.frame.size.height, frame.size.width, frame.size.height);
        }
      }else{
        // restore the header to it's normal position
        if((headerView = [self headerViewForSection:i]) != nil){
          headerView.frame = [self rectForHeaderOfSection:i];
        }
      }
    }
    
    [self enumerateIndexPathsFromIndexPath:fromIndexPath toIndexPath:toIndexPath withOptions:0 usingBlock:^(TUIFastIndexPath *indexPath, BOOL *stop) {
      TUITableViewCell *displacedCell;
      if((displacedCell = [self cellForRowAtIndexPath:indexPath]) != nil){
        TUIView *headerView = nil;
        CGRect frame = [self rectForRowAtIndexPath:indexPath];
        CGRect target;
        
        if([indexPath compare:currentPath] != NSOrderedAscending && [indexPath compare:cell.indexPath] == NSOrderedAscending){
          // the visited index path is above the origin and below the current index path;
          // shift the cell down by the height of the dragged cell
          target = CGRectMake(frame.origin.x, frame.origin.y - cell.frame.size.height, frame.size.width, frame.size.height);
        }else if([indexPath compare:currentPath] != NSOrderedDescending && [indexPath compare:cell.indexPath] == NSOrderedDescending){
          // the visited index path is below the origin and above the current index path;
          // shift the cell up by the height of the dragged cell
          target = CGRectMake(frame.origin.x, frame.origin.y + cell.frame.size.height, frame.size.width, frame.size.height);
        }else{
          // the visited cell is outside the affected range and should be returned to its
          // normal frame
          target = frame;
        }
        
        // only animate if we actually need to
        if(!CGRectEqualToRect(target, displacedCell.frame)){
          displacedCell.frame = target;
        }
        
      }
    }];
    
    // commit animations
    if(animate){
      [TUIView commitAnimations];
    }
    
  }
  
}

@end

