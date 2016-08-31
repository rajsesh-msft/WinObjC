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

#include <TestFramework.h>

#import <UIKit/UIKit.h>
#import "Starboard/SmartTypes.h"
#import "CALayerInternal.h"
#import "NullCompositor.h"

#include <windows.h>

static void initAutoLayout() {
    static bool initialized;

    if (!initialized) {
        SetCACompositor(new NullCompositor);
        initialized = true;
    }
}

// Should this be somewhere more accessible?
::std::ostream& operator<<(::std::ostream& os, const NSArray* ary) {
    for (int i = 0; i < [ary count]; i++) {
        NSObject* obj = [ary objectAtIndex:i];
        os << [[obj description] UTF8String] << "\n";
    }
    return os;
}

TEST(NSLayoutConstraint, VisualFormatLanguage) {
    initAutoLayout();

    UIView* topLevelView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    UIView* leftView = [UIView new];
    UIView* rightView = [UIView new];

    [topLevelView addSubview:leftView];
    [topLevelView addSubview:rightView];

    NSDictionary* metrics = @{ @"metric1" : @750, @"metric2" : @20 };

    NSArray* layoutConstraints =
        [NSLayoutConstraint constraintsWithVisualFormat:@"|-(>=10@metric1)-[leftView(rightView@1000)][rightView(metric2)]|"
                                                options:0
                                                metrics:metrics
                                                  views:NSDictionaryOfVariableBindings(leftView, rightView)];

    // Parse should be successful, and return a correct number of constraints.
    ASSERT_TRUE(layoutConstraints) << "constraintsWithVisualFormat returned nil!";
    ASSERT_EQ(5, [layoutConstraints count])
        << "constraintsWithVisualFormat returned incorrect number of constraints; returned constraints:\n"
        << ::testing::PrintToString(layoutConstraints);

    // Constraints should be returned in the order that they appear.
    NSLayoutConstraint* constraint = (NSLayoutConstraint*)[layoutConstraints objectAtIndex:0];
    ASSERT_EQ(750, constraint.priority) << "Constraints out of order.";
    constraint = (NSLayoutConstraint*)[layoutConstraints objectAtIndex:1];
    ASSERT_EQ(NSLayoutAttributeWidth, constraint.firstAttribute) << "Constraints out of order.";
    constraint = (NSLayoutConstraint*)[layoutConstraints objectAtIndex:2];
    ASSERT_EQ(constraint.firstItem, leftView) << "Constraints out of order.";
    ASSERT_EQ(constraint.secondItem, rightView) << "Constraints out of order.";
    constraint = (NSLayoutConstraint*)[layoutConstraints objectAtIndex:3];
    ASSERT_EQ(20, constraint.constant) << "Constraints out of order.";
    constraint = (NSLayoutConstraint*)[layoutConstraints objectAtIndex:4];
    ASSERT_EQ(0, constraint.constant) << "Constraints out of order.";

    // There are a few more modes of operation that aren't tested, since their operation is quite simple:
    //   * Vertical layout
    //   * NSLayoutFormat options
    //   * Metrics (though used in the test already)
}

TEST(NSLayoutConstraint, VisualFormatLanguageSyntax) {
    initAutoLayout();

    UIView* topLevelView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    UIView* leftView = [UIView new];
    UIView* rightView = [UIView new];
    UIView* danglingView = [UIView new];

    [topLevelView addSubview:leftView];
    [topLevelView addSubview:rightView];

    NSDictionary* metrics = @{ @"metric" : @1 };

    // Dangling view to (nonexistant) superview
    NSArray* layoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[danglingView]-|"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(danglingView)];

    EXPECT_FALSE(layoutConstraints) << "View with no superview; constraintWithVisualFormat shouldn't return constraints! Returned:\n"
                                    << ::testing::PrintToString(layoutConstraints);

    // Missing item in views
    layoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[noView(20)]"
                                                                options:0
                                                                metrics:nil
                                                                  views:NSDictionaryOfVariableBindings(leftView, rightView)];

    EXPECT_FALSE(layoutConstraints) << "View missing from views; constraintWithVisualFormat shouldn't return constraints! Returned:\n"
                                    << ::testing::PrintToString(layoutConstraints);

    // Missing item in views, but in metrics
    layoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[metric(20)]"
                                                                options:0
                                                                metrics:metrics
                                                                  views:NSDictionaryOfVariableBindings(leftView, rightView)];

    EXPECT_FALSE(layoutConstraints)
        << "View missing from views, but in metrics; constraintWithVisualFormat shouldn't return constraints! Returned:\n"
        << ::testing::PrintToString(layoutConstraints);

    // Missing item in metrics, but in views
    layoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[leftView(20@rightView)]"
                                                                options:0
                                                                metrics:metrics
                                                                  views:NSDictionaryOfVariableBindings(leftView, rightView)];

    EXPECT_FALSE(layoutConstraints)
        << "View missing from metrics, but in views; constraintWithVisualFormat shouldn't return constraints! Returned:\n"
        << ::testing::PrintToString(layoutConstraints);

    // Dangling constraint
    layoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[leftView(20)]-"
                                                                options:0
                                                                metrics:metrics
                                                                  views:NSDictionaryOfVariableBindings(leftView, rightView)];

    EXPECT_FALSE(layoutConstraints) << "Constraint left dangling; constraintWithVisualFormat shouldn't return constraints! Returned:\n"
                                    << ::testing::PrintToString(layoutConstraints);

    // Extra parens
    layoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[leftView((20))]"
                                                                options:0
                                                                metrics:metrics
                                                                  views:NSDictionaryOfVariableBindings(leftView, rightView)];

    EXPECT_FALSE(layoutConstraints) << "Extra parens in format; constraintWithVisualFormat shouldn't return constraints! Returned:\n"
                                    << ::testing::PrintToString(layoutConstraints);

    layoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[leftView()(20)]"
                                                                options:0
                                                                metrics:metrics
                                                                  views:NSDictionaryOfVariableBindings(leftView, rightView)];

    EXPECT_FALSE(layoutConstraints) << "Extra parens in format; constraintWithVisualFormat shouldn't return constraints! Returned:\n"
                                    << ::testing::PrintToString(layoutConstraints);

    layoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[leftView(20)]()"
                                                                options:0
                                                                metrics:metrics
                                                                  views:NSDictionaryOfVariableBindings(leftView, rightView)];

    EXPECT_FALSE(layoutConstraints) << "Extra parens in format; constraintWithVisualFormat shouldn't return constraints! Returned:\n"
                                    << ::testing::PrintToString(layoutConstraints);

    // Missing parens
    layoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[leftView(20]"
                                                                options:0
                                                                metrics:metrics
                                                                  views:NSDictionaryOfVariableBindings(leftView, rightView)];

    EXPECT_FALSE(layoutConstraints) << "Missing parens in format; constraintWithVisualFormat shouldn't return constraints! Returned:\n"
                                    << ::testing::PrintToString(layoutConstraints);

    // Priority out of bounds
    layoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[leftView(20@1001)]"
                                                                options:0
                                                                metrics:metrics
                                                                  views:NSDictionaryOfVariableBindings(leftView, rightView)];

    EXPECT_FALSE(layoutConstraints) << "Priority out of bounds; constraintWithVisualFormat shouldn't return constraints! Returned:\n"
                                    << ::testing::PrintToString(layoutConstraints);

    layoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[leftView(20@-1)]"
                                                                options:0
                                                                metrics:metrics
                                                                  views:NSDictionaryOfVariableBindings(leftView, rightView)];

    EXPECT_FALSE(layoutConstraints) << "Priority out of bounds; constraintWithVisualFormat shouldn't return constraints! Returned:\n"
                                    << ::testing::PrintToString(layoutConstraints);
}

TEST(NSLayoutConstraint, AddConstraints) {
    initAutoLayout();

    UIView* topLevelView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    UIView* leftView = [UIView new];
    UIView* rightView = [UIView new];
    UIView* danglingView = [UIView new];

    [topLevelView addSubview:leftView];
    [topLevelView addSubview:rightView];

    NSArray* layoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[leftView(rightView@1000)]-[rightView(10)]|"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(leftView, rightView)];

    ASSERT_TRUE(layoutConstraints) << "constraintsWithVisualFormat returned nil!";

    int numConstraints = [topLevelView.constraints count];

    [topLevelView addConstraints:layoutConstraints];

    EXPECT_EQ(numConstraints + [layoutConstraints count], [topLevelView.constraints count]) << "Not all constraints added to view:\n"
                                                                                            << ::testing::PrintToString(layoutConstraints);

    layoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[rightView][danglingView]"
                                                                options:0
                                                                metrics:nil
                                                                  views:NSDictionaryOfVariableBindings(leftView, rightView, danglingView)];

    ASSERT_TRUE(layoutConstraints) << "constraintsWithVisualFormat returned nil!";

    numConstraints = [topLevelView.constraints count];

    [topLevelView addConstraints:layoutConstraints];

    EXPECT_EQ(numConstraints, [topLevelView.constraints count]) << "Unrelated constraints added to view:\n"
                                                                << ::testing::PrintToString(layoutConstraints);
}
