//
//  UIImage+Scale.m
//  filter
//
//  Created by Frank Reine on 04.04.14.
//  Copyright (c) 2014 Frank Reine. All rights reserved.
//

#import "UIImage+Scale.h"

@implementation UIImage (Scale)

// from: http://iosdevelopertips.com/graphics/how-to-scale-an-image-using-an-objective-c-category.html
- (UIImage*)scaleToSize:(CGSize)size
{
    // Create a bitmap graphics context
    // This will also set it as the current context
    UIGraphicsBeginImageContext(size);
    
    // Draw the scaled image in the current context
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    // Create a new image from current context
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // Pop the current context from the stack
    UIGraphicsEndImageContext();
    
    // Return our new scaled image
    return scaledImage;
}

// adapted from: http://stackoverflow.com/a/20896594
- (UIImage *)scaleWithMaxDimension:(CGFloat)maxDimension
{
    if (fmax(self.size.width, self.size.height) <= maxDimension) {
        // return copy
        UIImage *newImage = [UIImage imageWithCGImage:self.CGImage];
        return newImage;
    }
    
    CGFloat aspect = self.size.width / self.size.height;
    CGSize newSize;
    
    if (self.size.width > self.size.height) {
        newSize = CGSizeMake(maxDimension, maxDimension / aspect);
    } else {
        newSize = CGSizeMake(maxDimension * aspect, maxDimension);
    }
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    CGRect newImageRect = CGRectMake(0.0, 0.0, newSize.width, newSize.height);
    [self drawInRect:newImageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
