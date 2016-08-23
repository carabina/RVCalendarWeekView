//
//  RVWeekView.m
//  RVCalendarWeekView
//
//  Created by Badchoice on 22/8/16.
//  Copyright © 2016 revo. All rights reserved.
//

#import "RVWeekView.h"

#import "NSDate+Easy.h"
#import "RVCollection.h"

#define MAS_SHORTHAND
#import "Masonry.h"

// Collection View Reusable Views
#import "MSGridline.h"
#import "MSTimeRowHeaderBackground.h"
#import "MSDayColumnHeaderBackground.h"
#import "MSEventCell.h"
#import "MSDayColumnHeader.h"
#import "MSTimeRowHeader.h"
#import "MSCurrentTimeIndicator.h"
#import "MSCurrentTimeGridline.h"

#define MSEventCellReuseIdentifier        @"MSEventCellReuseIdentifier"
#define MSDayColumnHeaderReuseIdentifier  @"MSDayColumnHeaderReuseIdentifier"
#define MSTimeRowHeaderReuseIdentifier    @"MSTimeRowHeaderReuseIdentifier"

@implementation RVWeekView

//================================================
#pragma mark - Init
//================================================
-(id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

-(void)setup{
    
    self.daysToShowOnScreen = 6;
    self.weekFlowLayout = [[MSCollectionViewCalendarLayout alloc] init];
    self.weekFlowLayout.delegate = self;
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:self.weekFlowLayout];
    self.collectionView.dataSource                      = self;
    self.collectionView.delegate                        = self;
    self.collectionView.directionalLockEnabled          = YES;
    self.collectionView.showsVerticalScrollIndicator    = NO;
    self.collectionView.showsHorizontalScrollIndicator  = NO;    
    
    [self addSubview:self.collectionView];
    [self.collectionView makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(self.height);
        make.width.equalTo(self.width);
        make.left.equalTo(self.left);
        make.top.equalTo(self.top);
    }];
    
        
    self.weekFlowLayout.sectionLayoutType = MSSectionLayoutTypeHorizontalTile;
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    [self.collectionView registerClass:MSEventCell.class forCellWithReuseIdentifier:MSEventCellReuseIdentifier];
    [self.collectionView registerClass:MSDayColumnHeader.class forSupplementaryViewOfKind:MSCollectionElementKindDayColumnHeader withReuseIdentifier:MSDayColumnHeaderReuseIdentifier];
    [self.collectionView registerClass:MSTimeRowHeader.class forSupplementaryViewOfKind:MSCollectionElementKindTimeRowHeader withReuseIdentifier:MSTimeRowHeaderReuseIdentifier];
    
    // These are optional. If you don't want any of the decoration views, just don't register a class for them.
    [self.weekFlowLayout registerClass:MSCurrentTimeIndicator.class forDecorationViewOfKind:MSCollectionElementKindCurrentTimeIndicator];
    [self.weekFlowLayout registerClass:MSCurrentTimeGridline.class forDecorationViewOfKind:MSCollectionElementKindCurrentTimeHorizontalGridline];
    [self.weekFlowLayout registerClass:MSGridline.class forDecorationViewOfKind:MSCollectionElementKindVerticalGridline];
    [self.weekFlowLayout registerClass:MSGridline.class forDecorationViewOfKind:MSCollectionElementKindHorizontalGridline];
    [self.weekFlowLayout registerClass:MSTimeRowHeaderBackground.class forDecorationViewOfKind:MSCollectionElementKindTimeRowHeaderBackground];
    [self.weekFlowLayout registerClass:MSDayColumnHeaderBackground.class forDecorationViewOfKind:MSCollectionElementKindDayColumnHeaderBackground];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    self.weekFlowLayout.sectionWidth = self.layoutSectionWidth;
}

-(void)forceReload{
    [self groupEventsByDays];
    [self.weekFlowLayout invalidateLayoutCache];
    [self.collectionView reloadData];
}

- (CGFloat)layoutSectionWidth
{
    // Default to 254 on iPad.
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        NSLog(@"Width : %f",self.frame.size.height);
        return (self.frame.size.width - 50) / self.daysToShowOnScreen;
        //return 254.0;
    }
    
    // Otherwise, on iPhone, fit-to-width.
    CGFloat width               = CGRectGetWidth(self.collectionView.bounds);
    CGFloat timeRowHeaderWidth  = self.weekFlowLayout.timeRowHeaderWidth;
    CGFloat rightMargin         = self.weekFlowLayout.contentMargin.right;
    
    return (width - timeRowHeaderWidth - rightMargin);
}

//================================================
#pragma mark - Set Events
//================================================
-(void)setEvents:(NSArray *)events{
    mEvents = events;
    [self groupEventsByDays];
}

-(void)groupEventsByDays{
    mDays = [mEvents groupBy:@"StartDate.toDateString"].mutableCopy;
    
    NSDate* date = NSDate.yesterday;
    for(int i = 0; i<30; i++){
        if(![mDays.allKeys containsObject:date.toDateString]){
            [mDays setObject:@[] forKey:date.toDateString];
        }
        date = [date addDay];
    }    
}

//================================================
#pragma mark - CollectionView Datasource
//================================================
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{   
    return mDays.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSString* day = [mDays.allKeys.sort objectAtIndex:section];
    return [mDays[day] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MSEventCell *cell   = [collectionView dequeueReusableCellWithReuseIdentifier:MSEventCellReuseIdentifier forIndexPath:indexPath];
    NSString* day       = [mDays.allKeys.sort objectAtIndex:indexPath.section];
    cell.akEvent        = [mDays[day] objectAtIndex:indexPath.row];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *view;
    if (kind == MSCollectionElementKindDayColumnHeader) {
        MSDayColumnHeader *dayColumnHeader = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:MSDayColumnHeaderReuseIdentifier forIndexPath:indexPath];
        NSDate *day                 = [self.weekFlowLayout dateForDayColumnHeaderAtIndexPath:indexPath];
        NSDate *currentDay          = [self currentTimeComponentsForCollectionView:self.collectionView layout:self.weekFlowLayout];
        
        NSDate *startOfDay          = [[NSCalendar currentCalendar] startOfDayForDate:day];
        NSDate *startOfCurrentDay   = [[NSCalendar currentCalendar] startOfDayForDate:currentDay];
        
        dayColumnHeader.day         = day;
        dayColumnHeader.currentDay  = [startOfDay isEqualToDate:startOfCurrentDay];
        
        view = dayColumnHeader;
    } else if (kind == MSCollectionElementKindTimeRowHeader) {
        MSTimeRowHeader *timeRowHeader = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:MSTimeRowHeaderReuseIdentifier forIndexPath:indexPath];
        timeRowHeader.time = [self.weekFlowLayout dateForTimeRowHeaderAtIndexPath:indexPath];
        view = timeRowHeader;
    }
    return view;
}


//================================================
#pragma mark - Week Flow Delegate
//================================================
- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout dayForSection:(NSInteger)section
{
    NSString* day   = [mDays.allKeys.sort objectAtIndex:section];
    return [NSDate parse:[day append:@" 00:00:00"]];
}

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout startTimeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* day   = [mDays.allKeys.sort objectAtIndex:indexPath.section];
    AKEvent* ev     = [mDays[day] objectAtIndex:indexPath.row];
    return ev.StartDate;
}

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout endTimeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* day   = [mDays.allKeys.sort objectAtIndex:indexPath.section];
    AKEvent* ev     = [mDays[day] objectAtIndex:indexPath.row];
    return ev.EndDate;
}

- (NSDate *)currentTimeComponentsForCollectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout
{
    return NSDate.date;
}


//================================================
#pragma mark - Collection view delegate
//================================================
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    MSEventCell* cell = (MSEventCell*)[collectionView cellForItemAtIndexPath:indexPath];
    NSLog(@"Event selected: %@ / %@ ", cell.akEvent.title, cell.akEvent.StartDate);
}

//================================================
#pragma mark - Dealloc
//================================================
-(void)dealloc{
    self.collectionView.dataSource  = nil;
    self.collectionView.delegate    = nil;
    self.collectionView             = nil;
    self.weekFlowLayout.delegate    = nil;
    self.weekFlowLayout             = nil;
    mDays                           = nil;
}

@end
