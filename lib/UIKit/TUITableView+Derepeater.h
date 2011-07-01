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

/*
 Some bit-rot here, Twitter for Mac feature that used this is currently on ice
 */

@class TUITableView;

@interface TUITableView (Derepeater)

@property (nonatomic, assign) BOOL derepeaterEnabled; // default is NO

@end

@protocol ABDerepeaterTableViewCell

@required

- (TUIView *)derepeaterView;
- (id)derepeaterIdentifier; // returned object should implement isEqual:

@end
