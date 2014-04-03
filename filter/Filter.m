//
//  Filter.m
//  filter
//
//  Created by Frank Reine on 14.03.14.
//  Copyright (c) 2014 Frank Reine. All rights reserved.
//

#import "Filter.h"

@interface Filter()

@property (nonatomic, strong) NSNumber *order;
@property (strong, nonatomic) NSArray *hues;
@property (strong, nonatomic) NSMutableArray *distm;
@property (strong, nonatomic) NSData *theCube;
@property (strong, nonatomic) NSNumber *cubeSize;

@end

@implementation Filter

static Filter *currentFilter;
static NSMutableArray *filters;

CGFloat match[8] = {0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.825};
CGFloat focus = 17.863032796;
//CGFloat focus = 4.0;

/* 
	Public interface
*/
- (void)initWithOrder:(int)anOrder {
	self.order = @(anOrder);
	self.cubeSize = @(8);
}

- (void) updateCube {
    // todo: this should be kept in a singleton filter manager!
    unsigned int size = self.cubeSize.intValue;
    long cubeDataSize = size * size * size * sizeof (float) * 4;
    float *cubeData = (float *)malloc (cubeDataSize);
    float *c = cubeData;
    
    UIColor *col;
    CGFloat h,newh,s,v,r,g,b,rn,gn,bn,alpha;
    
    NSLog(@"Update cube --------");


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

+ (void)setCurrentFilter:(Filter*)nf {
    currentFilter = nf;
}

+ (void)setFilters:(NSMutableArray*)array {
    filters = [NSMutableArray arrayWithArray:array];
}

+ (void)newFilterWithImage:(UIImage*) theImage {
    Filter *nf = [[Filter alloc] init];
    [nf initWithOrder:8];
    nf.hues = [nf getRawData:theImage];
    [nf initFilter];
    [nf updateCube];
    [Filter addFilter:nf];
    [Filter setCurrentFilter:nf];
    nf.image = theImage;
    // todo: thumbnail
    nf.text = @"Some Filter";
}

+ (NSMutableArray*)getFilters {
		if(filters == nil)
			filters = [NSMutableArray new];
		return filters;
}

+ (void)addFilter:(Filter*)f {
    NSMutableArray *filts = [Filter getFilters];
    [filts addObject:f];
    NSLog(@"Num filters:%lu", (unsigned long)[filts count]);
}

/*
 Filter Processor
 */
+ (UIImage*)processFilter:(UIImage*)anImage {
		return [currentFilter processFilter:anImage];
}

- (UIImage*)processFilter:(UIImage*)anImage {

    CIFilter *colorCube = [CIFilter filterWithName:@"CIColorCube"];
    [colorCube setValue:self.cubeSize forKey:@"inputCubeDimension"];
    // Set data for cube
    [colorCube setValue:self.theCube forKey:@"inputCubeData"];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *img=[[CIImage alloc] initWithImage:anImage];
    [colorCube setValue:img forKey:kCIInputImageKey];
    CIImage *result = [colorCube valueForKey:kCIOutputImageKey];
    CGRect extent = [result extent];
    CGImageRef cgImage = [context createCGImage:result fromRect:extent];
    
    UIImage *myNewImage = [UIImage imageWithCGImage:cgImage];
    
    return myNewImage;
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
    NSMutableArray *hue_data = [NSMutableArray new];
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
    int sample = 1000;
    for (int i=0, byteIndex = 0 ; byteIndex < width * height * 4; i++, byteIndex += 4*sample)
    {
        r = (float)rawData[byteIndex]/255;
        g = (float)rawData[byteIndex+1]/255;
        b = (float)rawData[byteIndex+2]/255;
        col = [UIColor colorWithRed:r green:g blue:b alpha:1.0f];
        [col getHue:&h saturation:&s brightness:&v alpha:&alpha];
        hue_data[i] = [NSNumber numberWithFloat:h];
    }
    
    // sort hue_data
    NSLog(@"Start sorting colors...");
    //NSArray* hue_sorted = [hue_data sortedArrayUsingFunction:floatSort context:NULL];
    // todo: sort mutable array in place?
    [hue_data sortUsingSelector:@selector(compare:)];

    NSLog(@"...done.");
    
    // select percentiles
    NSMutableArray* centers = [NSMutableArray new];
    long n_hues = hue_data.count;
    long step = n_hues/(self.order.intValue +1);
    for(long i=0,idx=(step-1); i<self.order.intValue && idx<n_hues; i++,idx+=step)
        centers[i] = hue_data[idx];
    
    NSLog(@"%@",[centers componentsJoinedByString:@", "]);
    
    return centers;
}

- (NSArray *)actWithDist:(NSArray*)dist {
    NSMutableArray* memb = [NSMutableArray new];
    double d;
    for(int i = 0; i<self.order.intValue; i++) {
        d = ((NSNumber*)[dist objectAtIndex:i]).floatValue;
        [memb addObject:[NSNumber numberWithDouble:pow(cos(d*2*M_PI)/2.0+0.5,focus)]];
    }
    return memb;
}

- (CGFloat)calcHueWithHue:(CGFloat)hue {
    NSMutableArray* dist = [NSMutableArray new];
    CGFloat newh = hue;
    for(int i=0;i<self.order.intValue;i++) {
        [dist addObject:[NSNumber numberWithDouble:[self rdist:hue From:match[i]]]];
    }
    NSArray* memb = [self actWithDist:dist];
    for(int i=0; i<self.order.intValue; i++) {
        newh -= ((NSNumber*)memb[i]).floatValue * [self.distm[i] floatValue];
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
    self.distm = [NSMutableArray new];
    for(int i = 0; i<self.order.intValue; i++) {
        from = [self.hues[i] floatValue];
        //d = [NSNumber numberWithFloat:[self rdist:match[i] From:from]];
        [self.distm addObject:[NSNumber numberWithFloat:[self rdist:match[i] From:from]]];
    }
}

/*
 NSCoder interface
 */

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.hues forKey:@"hues"];
    [coder encodeObject:self.image forKey:@"image"];
    [coder encodeObject:self.text forKey:@"text"];
}

-( id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init]))
	{
        self.hues = [coder decodeObjectForKey:@"hues"];
        self.image = [coder decodeObjectForKey:@"image"];
        self.text = [coder decodeObjectForKey:@"text"];
 	}
	return self;
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