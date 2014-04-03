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
- (IBAction)applyFilter:(id)sender;
- (IBAction)chooseFilter:(id)sender;
- (IBAction)saveImage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *filterActivity;
@property (weak, nonatomic) IBOutlet UITableView *filterTable;

//@property (strong, nonatomic) Filter *theFilter;

@end

@implementation ViewController

UIImagePickerController *imagePicker;
UIImagePickerController *filterPicker;
UIImage *origImage;

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self loadFilters];
    //[self.filterTable reloadData];
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

- (IBAction)applyFilter:(id)sender {
    [self.activity startAnimating];
    [self performSelector: @selector(calcCube)
               withObject: nil
               afterDelay: 0];
}

- (void)calcCube {
    UIImage *myNewImage = [Filter processFilter:origImage];
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

- (IBAction)saveImage {
    UIImageWriteToSavedPhotosAlbum(self.theImage.image, nil, nil, nil);
}

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    UIImage *newImage = info[UIImagePickerControllerOriginalImage];
    if (picker == imagePicker) {
        self.theImage.image = newImage;
        origImage = newImage;
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
    [Filter newFilterWithImage:self.filterImage.image];
    [self.filterActivity stopAnimating];
    NSInteger row = [[Filter getFilters] count] - 1; // todo: use property
    row = 0;
    //[self.filterTable reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
    [self.filterTable reloadData];
    [self saveFilters];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
 TableView protocols
 */

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[Filter getFilters] count];
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return @"Filter";
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	Filter *filt = [Filter getFilters][indexPath.row];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	cell.textLabel.text = filt.text;
	cell.imageView.image = filt.image;
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	Filter *filt = [Filter getFilters][indexPath.row];
	[Filter setCurrentFilter:filt];
    self.filterImage.image = filt.image;
}

/*
 Archiving methods
 */
- (NSString*) getFullFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *savePath = [paths objectAtIndex:0];
    return [savePath stringByAppendingPathComponent: @"filters.arch"];
}

- (void)saveFilters
{
    NSString *filePath = [self getFullFilePath];
    //NSData *theData = [NSKeyedArchiver archivedDataWithRootObject:[Filter getFilters]];
    [NSKeyedArchiver archiveRootObject:[Filter getFilters] toFile:filePath];
}

- (void)loadFilters {
    NSString *filePath = [self getFullFilePath];
    NSMutableArray *filts = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    [Filter setFilters:filts];
}

@end
