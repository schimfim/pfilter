//
//  Filter.m
//  filter
//
//  Created by Frank Reine on 14.03.14.
//  Copyright (c) 2014 Frank Reine. All rights reserved.
//

#import "Filter.h"

@interface Filter()

@property (strong, nonatomic) NSArray *hues;

@end

@implementation Filter

int order = 8;
CGFloat match[8] = {0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.825};
CGFloat distm[8];
CGFloat focus = 17.863032796;
//CGFloat focus = 4.0;

- (void) updateCube {
    // Allocate memory
    const unsigned int size = 8;
    self.cubeSize = @(size);
    long cubeDataSize = size * size * size * sizeof (float) * 4;
    float *cubeData = (float *)malloc (cubeDataSize);
    float *c = cubeData;
    
    UIColor *col;
    CGFloat h,newh,s,v,r,g,b,rn,gn,bn,alpha;
    
    NSLog(@"Update cube --------");
    //for(int di=0; di<order; di++) {
    //    NSLog(@"dist[%i]=%f", di, distm[di]);
    //}

    [self initFilter];

    // Populate cube with a simple gradient going from 0 to 1
    for (int z = 0; z < size; z++){
        b = ((double)z)/(size-1); // Blue value
        for (int y = 0; y < size; y++){
            g = ((double)y)/(size-1); // Green value
            for (int x = 0; x < size; x ++){
                r = ((double)x)/(size-1); // Red value
                //printf("%.4f %.4f %.4f - ",r,g,b);
                // Convert RGB to HSV
                col = [UIColor colorWithRed:r green:g blue:b alpha:1.0f];
                [col getHue:&h saturation:&s brightness:&v alpha:&alpha];
                newh = [self calcHueWithHue:h];
                //NSLog(@"r=%f g=%f b=%f - h=%f new=%f - s=%f v=%f", r,g,b,h,newh,s,v);
                col = [UIColor colorWithHue:newh saturation:s brightness:v alpha:alpha];
                [col getRed:&rn green:&gn blue:&bn alpha:&alpha];
                // Calculate premultiplied alpha values for the cube
                //printf("%.4f %.4f %.4f\n",rn,gn,bn);
                c[0] = rn;
                c[1] = gn;
                c[2] = bn;
                c[3] = 1.0;
                c += 4; // advance our pointer into memory for the next color value
            }
        }
    }
    // Create memory with the cube data
    self.theCube = [NSData dataWithBytes:cubeData length:cubeDataSize];

    //self.theCube = [NSData dataWithBytesNoCopy:cubeData
    //                                    length:cubeDataSize];
}

- (void)analyzeWithImage:(UIImage*) theImage {
    
    NSArray* centers = [self getRawData:theImage];
    self.hues = [NSArray arrayWithArray:centers];
    [self updateCube];
}

// Internal

/*
    getRawData
    Taken from:
    http://brandontreb.com/image-manipulation-retrieving-and-updating-pixel-values-for-a-uiimage
*/
- (NSArray*)getRawData:(UIImage*) theImage {
    // Get raw data
    CGImageRef imageRef = [theImage CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = malloc(height * width * 4);
    NSArray *hue_data = [NSArray new];
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    // Transform
    NSLog(@"Start color transform...");
    UIColor *col;
    CGFloat r,g,b,h,s,v,alpha;
    int byteIndex = 0;
    int sample = 1000;
    for (byteIndex = 0 ; byteIndex < width * height * 4; byteIndex += 4*sample)
    {
        r = (float)rawData[byteIndex]/255;
        g = (float)rawData[byteIndex+1]/255;
        b = (float)rawData[byteIndex+2]/255;
        col = [UIColor colorWithRed:r green:g blue:b alpha:1.0f];
        [col getHue:&h saturation:&s brightness:&v alpha:&alpha];
        hue_data = [hue_data arrayByAddingObject:[NSNumber numberWithFloat:h]];
        
    }
    
    // sort hue_data
    NSLog(@"Start sorting colors...");
    //NSArray* hue_sorted = [hue_data sortedArrayUsingFunction:floatSort context:NULL];
    NSArray* hue_sorted = [hue_data sortedArrayUsingSelector:@selector(compare:)];

    NSLog(@"...done.");
    
    // select percentiles
    NSArray* centers = [NSArray new];
    int n_hues = [hue_sorted count];
    int step = n_hues/(order+1);
    for(int i=0,idx=(step-1); i<order && idx<n_hues; i++,idx+=step)
        centers = [centers arrayByAddingObject:[hue_sorted objectAtIndex:idx]];
    
    NSLog(@"%@",[centers componentsJoinedByString:@", "]);
    
    return centers;
}

- (NSArray *)actWithDist:(NSArray*)dist {
    NSMutableArray* memb = [NSMutableArray new];
    double d;
    for(int i = 0; i<order; i++) {
        d = ((NSNumber*)[dist objectAtIndex:i]).floatValue;
        [memb addObject:[NSNumber numberWithDouble:pow(cos(d*2*M_PI)/2.0+0.5,focus)]];
    }
    return memb;
}

- (CGFloat)calcHueWithHue:(CGFloat)hue {
    NSMutableArray* dist = [NSMutableArray new];
    CGFloat newh = hue;
    for(int i=0;i<order;i++) {
        [dist addObject:[NSNumber numberWithDouble:[self rdist:hue From:match[i]]]];
    }
    NSArray* memb = [self actWithDist:dist];
    for(int i=0; i<order; i++) {
        newh -= ((NSNumber*)memb[i]).floatValue * distm[i];
    }
    if(newh < 0.0) {
        newh += 1.0;
        //NSLog(@"newh+1=%f", newh);
    }
    if(newh > 1.0) {
        newh -= 1.0;
        //NSLog(@"newh-1=%f", newh);
    }
    
    return newh;
}

// Internal calculations

// distance vector
/*
NSMutableArray* dist = [NSMutableArray new];
CGFloat newh = hue;
for(int i=0;i<order;i++) {
    [dist addObject:[NSNumber numberWithDouble:[self rdist:hue From:match[i]]]];
}
*/

- (CGFloat)rdist:(CGFloat)x From:(CGFloat)h {
    double d = x - h;
    if (fabs(d) > 0.5) {
        d -= d / fabs(d);
    }
    return d;
}

- (void)initFilter {
    float from;
    for(int i = 0; i<order; i++) {
        //from = ((NSNumber*)_hues[i]).floatValue;
        from = [self.hues[i] floatValue];
        distm[i] = [self rdist:match[i] From:from];
    }
}

@end

// Fanny liebt Katzen.
/*
 # calc hue
 dist = [rdist(hn,hue) for hue in fdef.match]
 f = act(dist, fdef.focus)
 hn -= sum([fc*d for (fc,d) in zip(f,fdef.distm)])

 def act(dist, focus):
 f = [(cos(d*2*pi)/2+0.5)**focus for d in dist]
 return f
 
 def update(self):
 self.distm = [rdist(hm,hh) for (hm,hh) in zip(self.match, self.hues)]
 self.focus = calc_focus(self.order)
 
 def rdist(x,h):
 d = x - h
 if abs(d) > 0.5:
 d = d - d/abs(d)
 return d
 
 def calc_focus(n):
 delta = 1.0/n/2
 gain = 0.5
 f = log(gain)/log(0.5*cos(2*pi*delta)+0.5)
 return f
 
*/