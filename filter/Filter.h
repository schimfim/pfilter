//
//  Filter.h
//  filter
//
//  Created by Frank Reine on 14.03.14.
//  Copyright (c) 2014 Frank Reine. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Filter : NSObject <NSCoding>

+ (void)newFilterWithImage:(UIImage*) theImage;
+ (UIImage*)processFilter:(UIImage*)anImage;
+ (NSMutableArray*)getFilters;
+ (void)setFilters:(NSMutableArray*)array;
+ (void)setCurrentFilter:(Filter*)nf;

@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) UIImage *image;

@end
