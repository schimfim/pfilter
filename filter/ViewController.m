//
//  ViewController.m
//  filter
//
//  Created by Frank Reine on 19.02.14.
//  Copyright (c) 2014 Frank Reine. All rights reserved.
//

#import "ViewController.h"
#import <CoreImage/CoreImage.h>
#import <UIKit/UIColor.h>
#import "Filter.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *theImage;
@property (weak, nonatomic) IBOutlet UIImageView *filterImage;
- (IBAction)chooseImage:(id)sender;
- (IBAction)scaleDown:(id)sender;
- (IBAction)scaleUp:(id)sender;
- (IBAction)applyCube:(id)sender;
- (IBAction)chooseFilter:(id)sender;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *filterActivity;

//@property (strong, nonatomic) Filter *theFilter;

@end

@implementation ViewController

UIImagePickerController *imagePicker;
UIImagePickerController *filterPicker;
Filter *theFilter;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    //theFilter = [[Filter alloc] init];
    //[theFilter updateCube];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)chooseImage:(id)sender {
    //UIImagePickerController *imagePicker;
    imagePicker = [UIImagePickerController new];
    imagePicker.sourceType=UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    imagePicker.delegate=self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)scaleDown:(id)sender {
    [self _scale:@0.5];
}

- (IBAction)scaleUp:(id)sender {
    [self _scale:@2.0];
}

- (IBAction)applyCube:(id)sender {
    //self.activity.hidden = NO;
    [self.activity startAnimating];
    [self performSelector: @selector(calcCube)
               withObject: nil
               afterDelay: 0];
}

- (void)calcCube {
    NSData* data = theFilter.theCube;
    NSNumber* size = theFilter.cubeSize;
    
    CIFilter *colorCube = [CIFilter filterWithName:@"CIColorCube"];
    [colorCube setValue:size forKey:@"inputCubeDimension"];
    // Set data for cube
    [colorCube setValue:data forKey:@"inputCubeData"];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *img=[[CIImage alloc] initWithImage:self.theImage.image];
    [colorCube setValue:img forKey:kCIInputImageKey];
    CIImage *result = [colorCube valueForKey:kCIOutputImageKey];
    CGRect extent = [result extent];
    CGImageRef cgImage = [context createCGImage:result fromRect:extent];
    
    UIImage *myNewImage = [UIImage imageWithCGImage:cgImage];
    self.theImage.image = myNewImage;
    [self.activity stopAnimating];

}

- (IBAction)chooseFilter:(id)sender {
    //UIImagePickerController *imagePicker;
    filterPicker = [UIImagePickerController new];
    filterPicker.sourceType=UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    filterPicker.delegate=self;
    [self presentViewController:filterPicker animated:YES completion:nil];
}

- (void)_scale:(NSNumber*)factor {
    CIImage *imageToFilter;
    CIContext *context = [CIContext contextWithOptions:nil];
    imageToFilter=[[CIImage alloc] initWithImage:self.theImage.image];
    
    // Scale
    CIFilter *activeFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
    [activeFilter setDefaults];
    [activeFilter setValue: factor forKey: @"inputScale"];
    
    [activeFilter setValue:imageToFilter forKey: @"inputImage"];
    CIImage *filteredImage=[activeFilter valueForKey: @"outputImage"];
    CGRect extent = [filteredImage extent];
    CGImageRef cgImage = [context createCGImage:filteredImage fromRect:extent];
    
    UIImage *myNewImage = [UIImage imageWithCGImage:cgImage];
    self.theImage.image = myNewImage;
}

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    UIImage *newImage = info[UIImagePickerControllerOriginalImage];
    //UIImage *scaledImage = [UIImage imageWithCGImage:newImage.CGImage scale:8.0 orientation:UIImageOrientationUp];
    if (picker == imagePicker) {
        self.theImage.image = newImage;
        //[self _scale:@0.125];
        
    }
    else {
        self.filterImage.image = newImage;
        // Analyze image in own thread
        [self.filterActivity startAnimating];
        [self performSelector: @selector(calcFilter)
                   withObject: newImage
                   afterDelay: 0];
    }
}

- (void)calcFilter {
		theFilter = [[Filter alloc] init];
		[theFilter initWithOrder:8];
    [theFilter analyzeWithImage:self.filterImage.image];
    [self.filterActivity stopAnimating];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
