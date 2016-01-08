//******************************************************************************
//
// Copyright (c) 2015 Microsoft Corporation. All rights reserved.
//
// This code is licensed under the MIT License (MIT).
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//******************************************************************************

#import <Foundation/NSObject.h>

@class NSDate;

@protocol NSLocking

/**
@Status Interoperable
*/
- (void)lock;

/**
@Status Interoperable
*/
- (void)unlock;
@end

FOUNDATION_EXPORT_CLASS
@interface NSLock : NSObject <NSLocking>
@property (copy) NSString* name;

- (BOOL)tryLock;
- (BOOL)lockBeforeDate:(NSDate*)value;

@end

FOUNDATION_EXPORT_CLASS
@interface NSCondition : NSObject <NSLocking>
- (void)broadcast;
- (void)signal;

- (void)wait;
- (BOOL)waitUntilDate:(NSDate*)limit;

@property (nonatomic, copy) NSString* name;
@end

#import <Foundation/NSConditionLock.h>
#import <Foundation/NSRecursiveLock.h>
