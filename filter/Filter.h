//
//  Filter.h
//  filter
//
//  Created by Frank Reine on 14.03.14.
//  Copyright (c) 2014 Frank Reine. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Filter : NSObject

- (void)updateCube;
- (void)analyzeWithImage:(UIImage*) theImage;

@property (strong, nonatomic) NSData *theCube;
@property (strong, nonatomic) NSNumber *cubeSize;

@end
