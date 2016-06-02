//
//  ViewController.m
//  infojobOCR
//
//  Created by Paolo Tagliani on 08/06/12.
//  Copyright (c) 2012 26775. All rights reserved.
//
#import "ViewController.h"
#import "ImageProcessingImplementation.h"
#import "UIImage+operation.h"
#import "TesseractOCR/TesseractOCR.h"
#import "TesseractOCR/UIImage+G8Filters.h"

/*self add*/
#import "MAImagePickerController.h"
#import "MBProgressHUD.h"


@interface ViewController ()


@end

@implementation ViewController


@synthesize takenImage;
@synthesize process;
@synthesize resultView;
@synthesize imageProcessor;
@synthesize read;
@synthesize processedImage;
@synthesize rotateButton;
@synthesize Histogrambutton;
@synthesize FilterButton;
@synthesize BinarizeButton;
@synthesize originalButton;



- (void)viewDidLoad
{
    [super viewDidLoad];
    imageProcessor= [[ImageProcessingImplementation alloc]  init];
    
    // Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getImageNotification:) name:@"sendImage" object:nil];

}


- (void)getImageNotification:(NSNotification *)notification
{
    NSDictionary *dic = [notification userInfo];
    self.takenImage = [UIImage imageWithData:[dic objectForKey:@"imageData"]];
    
    if (takenImage) {
        takenImage = [takenImage rotate:UIImageOrientationLeft];
        self.resultView.image=[self takenImage];
        self.processedImage=[self takenImage];
        process.hidden=NO;
        BinarizeButton.hidden=NO;
        Histogrambutton.hidden=NO;
        FilterButton.hidden=NO;
        rotateButton.hidden=YES;
        self.read.hidden=NO;
        originalButton.hidden=NO;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidUnload
{
    [self setResultView:nil];
    [self setProcess:nil];
    [self setRead:nil];
    [self setRotateButton:nil];
    [self setRotateButton:nil];
    [self setHistogrambutton:nil];
    [self setFilterButton:nil];
    [self setBinarizeButton:nil];
    [self setOriginalButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    
    if(interfaceOrientation == UIInterfaceOrientationPortrait) return YES;
    else return NO;
}

- (IBAction)Pre:(id)sender {
    
    NSLog(@"Dimension taken image: %f x %f",takenImage.size.width, takenImage.size.height);
    self.processedImage=[imageProcessor processImage:[self takenImage]];
    self.resultView.image=[self processedImage];
    NSLog(@"Dimension processed image: %f x %f",takenImage.size.width, takenImage.size.height);
}

- (IBAction)OCR:(id)sender {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    __block NSString *readed;
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        readed = [self myORC:processedImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [[[UIAlertView alloc] initWithTitle:@""
                                        message:readed
                                       delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:@"OK", nil] show];
        });
    });
    
    NSLog(@"%@",readed);
}

- (NSString *)myORC:(UIImage *)image{
    G8Tesseract *tesseract = [[G8Tesseract alloc]init] ;
    // 2
    tesseract.language = @"eng";//"eng+fra+chi_sim"      @"eng+chi-sim";

    // 3
    tesseract.engineMode = G8OCREngineModeTesseractOnly;//.TesseractCubeCombined

    // 4
    tesseract.pageSegmentationMode = G8PageSegmentationModeAuto;

    // 5
    tesseract.maximumRecognitionTime = 30.0;

    // 6
    tesseract.image = [self.processedImage g8_blackAndWhite];
    [tesseract recognize];
    
    NSString *text = tesseract.recognizedText;
    
//    textBlock(text);
    
    return text;
}

/**
 *	图片旋转
 *
 */
- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

- (IBAction)PreRotation:(id)sender {
    
    self.processedImage=[imageProcessor processRotation:[self processedImage]];
    self.resultView.image=[self processedImage];
}

- (IBAction)PreHistogram:(id)sender {
    
    self.processedImage=[imageProcessor processHistogram:[self processedImage]];
    self.resultView.image=[self processedImage];
}

- (IBAction)PreFilter:(id)sender {
    
    self.processedImage=[imageProcessor processFilter:[self processedImage]];
    self.resultView.image=[self processedImage];
}

- (IBAction)PreBinarize:(id)sender {
    
    self.processedImage=[imageProcessor processBinarize:[self processedImage]];
    self.resultView.image=[self processedImage];
}

- (IBAction)returnOriginal:(id)sender {
    
    self.processedImage=[self takenImage ];
    self.resultView.image= [self takenImage];
}

#pragma mark - take photo
- (IBAction)TakePhoto:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"选取照片"                                                                 delegate: self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照", @"从相册中选择", nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    imagePicker = [[MAImagePickerController alloc] init];
    
    if(buttonIndex != actionSheet.cancelButtonIndex)
    {
        if (buttonIndex == 0) {
            [imagePicker setSourceType:MAImagePickerControllerSourceTypeCamera];
        } else if (buttonIndex == 1) {
            [imagePicker setSourceType:MAImagePickerControllerSourceTypePhotoLibrary];
        }
        
        [imagePicker setDelegate:self];
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:imagePicker];
        
        [self presentViewController:navigationController animated:YES completion:nil];
    }
    
    else [self dismissModalViewControllerAnimated:YES];
    
    
}

- (UIView*)CreateOverlay{
    
    UIView *overlay= [[UIView alloc]
                      initWithFrame:CGRectMake
                      (0, 0, self.view.frame.size.width, self.view.frame.size.height*0.10)];//width equal and height 15%
    overlay.backgroundColor=[UIColor blackColor];
    overlay.alpha=0.5;
    
    return overlay;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    [picker dismissModalViewControllerAnimated:YES];
    
    //I take the coordinate of the cropping
    CGRect croppedRect = [[info objectForKey:UIImagePickerControllerCropRect] CGRectValue];
    
    UIImage *original = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    //original = [self fixOrientation:original];//图片旋转
    
    //也是图片旋转
    UIImage *rotatedCorrectly;
    if (original.imageOrientation != UIImageOrientationUp){
        rotatedCorrectly = [original rotate:original.imageOrientation];
    } else {
        rotatedCorrectly = original;
    }


    
    UIImage *scaledImage = [self scaleImage:rotatedCorrectly maxDimension: 1240];
    
    
    CGImageRef ref = CGImageCreateWithImageInRect(scaledImage.CGImage, croppedRect);
    self.takenImage = [UIImage imageWithCGImage:ref];
    self.resultView.image = [self takenImage];
    self.processedImage = [self takenImage];
    process.hidden = NO;
    BinarizeButton.hidden = NO;
    Histogrambutton.hidden = NO;
    FilterButton.hidden = NO;
    rotateButton.hidden = YES;
    self.read.hidden = NO;
    originalButton.hidden = NO;
    
}

/**
 *	图片清晰度处理
 */
- (UIImage *)scaleImage:(UIImage *) image maxDimension:(CGFloat) maxDimension{
    CGSize scaledSize = CGSizeMake(maxDimension, maxDimension);
    CGFloat scaleFactor;
    if (image.size.width > image.size.height) {
        scaleFactor = image.size.height / image.size.width;
        scaledSize.width = maxDimension;
        scaledSize.height = scaledSize.width * scaleFactor;
    } else {
        scaleFactor = image.size.width / image.size.height;
        scaledSize.height = maxDimension;
        scaledSize.width = scaledSize.height * scaleFactor;
    }
    
    UIGraphicsBeginImageContext(scaledSize);
    [image drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
    
}

@end
