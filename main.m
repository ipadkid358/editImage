int main(int argc, char **argv) {
    NSString *originPath = nil;
    CGFloat sizeW = 0;
    CGFloat sizeH = 0;
    CGFloat radius = 0;
    NSString *destPath = nil;
    BOOL jpg = YES;
    BOOL force = YES;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    
    int c;
    while ((c = getopt(argc, argv, ":i:o:w:h:r:jf")) != -1)
        switch(c) {
            case 'i':
                originPath = [NSString stringWithFormat:@"%s", optarg];
                if (![fileManager fileExistsAtPath:originPath]) {
                    printf(" [-i] No file found at %s\n", originPath.UTF8String);
                    return 1;
                }
                break;
            case 'o':
                destPath = [NSString stringWithFormat:@"%s", optarg];
                break;
            case 'w':
                sizeW = [NSString stringWithFormat:@"%s", optarg].floatValue;
                break;
            case 'h':
                sizeH = [NSString stringWithFormat:@"%s", optarg].floatValue;
                break;
            case 'r':
                radius = [NSString stringWithFormat:@"%s", optarg].floatValue;
                break;
            case 'j':
                jpg = YES;
                break;
            case 'f':
                force = NO;
                break;
            case '?':
                printf("Usage: %s [OPTIONS]\n"
                       " Options:\n"
                       "   -i    Input image path\n"
                       "   -o    Path to write new image to (overwrite old by default)\n"
                       "   -w    Width of new image (current width by default)\n"
                       "   -h    Height of new image (current height by default)\n"
                       "   -r    Radius to clip edges by (none by default)\n"
                       "   -j    JPEG compression (PNG by default)\n"
                       "   -f    Force upscaling images\n", argv[0]);
                exit(-1);
                break;
        }
    
    if (radius && jpg) printf("Warning: JPEGs don’t have alpha, applying a radius may cause a white or black background\n");
    BOOL samePath = !destPath;
    if ([fileManager isWritableFileAtPath:destPath]) {
        printf("Write-permission denied\n");
        return 1;
    }
    if (!originPath) {
        printf(" [-i] Input file is a required argument\n");
        return 1;
    }
    
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:originPath];
    if (!image) {
        printf("Invalid file type\n");
        return 1;
    }
    
    CGSize origSize = image.size;
    CGFloat origScale = image.scale;
    CGFloat deviceScale = UIScreen.mainScreen.scale;
    
    CGFloat origW = origSize.width * origScale;
    CGFloat origH = origSize.height * origScale;
    CGFloat cSizeW = sizeW ? sizeW/deviceScale : origW;
    CGFloat cSizeH = sizeH ? sizeH/deviceScale : origH;
    
    if (force) {
        BOOL badSize = NO;
        if (sizeW > origW) {
            printf("Invalid width of %ld, original is only %ld\n", lroundf(sizeW), lroundf(origW));
            badSize = YES;
        }
        if (sizeH > origH) {
            printf("Invalid height of %ld, original is only %ld\n", lroundf(sizeH), lroundf(origH));
            badSize = YES;
        }
        if (badSize) {
            printf(" Use -f to force upscaling\n");
            return 1;
        }
    }
    
    CGRect rect = CGRectMake(0, 0, cSizeW, cSizeH);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(cSizeW, cSizeH), NO, 0);
    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius] addClip];
    [image drawInRect:rect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *imageData;
    if (jpg) imageData = UIImageJPEGRepresentation(newImage, 1);
    else imageData = UIImagePNGRepresentation(newImage);
    
    if (samePath) {
        destPath = originPath;
        [fileManager removeItemAtPath:destPath error:NULL];
    }
    if (![imageData writeToFile:destPath atomically:YES]) {
        printf("Failed to write to file\n");
        return 1;
    }
    return 0;
}
