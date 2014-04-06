//
//  UIImage+Scale.h
//  filter
//
//  Created by Frank Reine on 04.04.14.
//  Copyright (c) 2014 Frank Reine. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Scale)

- (UIImage*)scaleToSize:(CGSize)size;
- (UIImage *)scaleWithMaxDimension:(CGFloat)maxDimension;

@end
