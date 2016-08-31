//******************************************************************************
//
// Copyright (c) 2015 Microsoft Corporation. All rights reserved.
//
// Copyright (c) 2008-2009 Apple Inc. All rights reserved.
//
// @APPLE_APACHE_LICENSE_HEADER_START@
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// @APPLE_APACHE_LICENSE_HEADER_END@
//
//******************************************************************************

#include <TestFramework.h>
#import <UIKit/UIKit.h>
#include <dispatch/dispatch.h>
#include "dispatch_test.h"

//
// Verify that dispatch timers do not drift, that is to say, increasingly
// stray from their intended interval.
//
// The jitter of the event handler is defined to be the amount of time
// difference between the actual and expected timing of the event handler
// invocation. The drift is defined to be the amount that the jitter changes
// over time.
//
// Important: be sure to use the same clock when comparing actual and expected
// values. Skew between different clocks is to be expected.
//

extern int gettimeofday(struct timeval* tp, void* tzp);

static dispatch_source_t s_timer;

@interface LocalTestHelper : NSObject
+ (void)stopTest:(NSNumber*)delayInSec;
+ (void)stopTestAfterDelay:(DWORD)delayInSec;
@end
@implementation LocalTestHelper
+ (void)stopTest:(NSNumber*)delayInSec {
    [NSThread sleepForTimeInterval:[delayInSec intValue]];
    dispatch_source_cancel(s_timer);
    dispatch_release(s_timer);
    test_stop();
}
+ (void)stopTestAfterDelay:(DWORD)delayInSec {
    [NSThread detachNewThreadSelector:@selector(stopTest:) toTarget:self withObject:[NSNumber numberWithInt:delayInSec]];
}
@end

TEST(Dispatch, DispatchDrift) {
    __block uint32_t count = 0;
    __block double last_jitter = 0;

    // interval is 1/10th of a second
    uint64_t interval = NSEC_PER_SEC / 10;
    double interval_d = (double)interval / (double)NSEC_PER_SEC;

    // for 25 seconds
    unsigned int target = 25 / interval_d;

    __block double first = 0;
    __block double jittersum = 0;
    __block double driftsum = 0;

    test_start("Timer drift test");

    s_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    test_ptr_notnull("DISPATCH_SOURCE_TYPE_TIMER", s_timer);

    dispatch_source_set_event_handler(s_timer,
                                      ^{
                                          struct timeval now_tv;
                                          gettimeofday(&now_tv, NULL);
                                          double now = now_tv.tv_sec + ((double)now_tv.tv_usec / (double)USEC_PER_SEC);

                                          if (first == 0) {
                                              first = now;
                                          }

                                          double goal = first + interval_d * count;
                                          double jitter = goal - now;
                                          double drift = jitter - last_jitter;

                                          count += dispatch_source_get_data(s_timer);
                                          jittersum += jitter;
                                          driftsum += drift;

                                          LOG_INFO("%4d: jitter %f, drift %f\n", count, jitter, drift);

                                          if (count >= target) {
                                              /* In WINOBJC, our timers are currently based upon 10ms resolution. */
                                              test_double_less_than("average jitter", fabs(jittersum) / (double)count, 0.01);
                                              test_double_less_than("average drift", fabs(driftsum) / (double)count, 0.0001);
                                              [LocalTestHelper stopTestAfterDelay:0];
                                          }
                                          last_jitter = jitter;
                                      });

    struct timeval now_tv;
    struct timespec now_ts;

    gettimeofday(&now_tv, NULL);
    now_ts.tv_sec = now_tv.tv_sec;
    now_ts.tv_nsec = now_tv.tv_usec * NSEC_PER_USEC;

    dispatch_source_set_timer(s_timer, dispatch_walltime(&now_ts, interval), interval, 0);

    dispatch_resume((dispatch_object_t)s_timer);

    [LocalTestHelper stopTestAfterDelay:5];
    test_block_until_stopped();
}
