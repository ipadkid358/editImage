#import <UIKit/UIKit.h>

int main(int argc, char **argv) {
    NSString *originPath;
    CGFloat sizeW = 0;
    CGFloat sizeH = 0;
    CGFloat radius = 0;
    CGFloat scale = 1;
    NSString *maskPath;
    NSString *destPath;
    CGFloat jpg = -1;
    BOOL force = YES;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    
    int c;
    while ((c = getopt(argc, argv, ":i:o:w:h:r:s:m:j:f")) != -1)
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
                BOOL isDir;
                if ([fileManager fileExistsAtPath:destPath isDirectory:&isDir] && isDir) destPath = [destPath stringByAppendingPathComponent:originPath.lastPathComponent];
                break;
            case 'w':
                sizeW = [NSString stringWithFormat:@"%s", optarg].floatValue;
                if (sizeW < 0) {
                    printf(" [-w] Width needs to be a positive number\n");
                    return 1;
                }
                break;
            case 'h':
                sizeH = [NSString stringWithFormat:@"%s", optarg].floatValue;
                if (sizeH < 0) {
                    printf(" [-h] Height needs to be a positive number\n");
                    return 1;
                }
                break;
            case 'r':
                radius = [NSString stringWithFormat:@"%s", optarg].floatValue;
                if (radius < 0) {
                    printf(" [-r] Radius needs to be a positive number\n");
                    return 1;
                }
                break;
            case 's':
                scale = [NSString stringWithFormat:@"%s", optarg].floatValue;
                if (scale <= 0) {
                    printf(" [-s] Scale needs to be a positive number\n");
                    return 1;
                }
                break;
            case 'm':
                maskPath = [NSString stringWithFormat:@"%s", optarg];
                if (![fileManager fileExistsAtPath:maskPath]) {
                    printf(" [-m] No file found at %s\n", maskPath.UTF8String);
                    return 1;
                }
                break;
            case 'j':
                jpg = [NSString stringWithFormat:@"%s", optarg].floatValue;
                if (jpg < 0 || jpg > 1) {
                    printf(" [-j] JPEG compression docs:\n"
                           "  The quality of the resulting JPEG image, expressed as a value from 0.0 to 1.0.\n"
                           "  The value 0.0 represents the maximum compression (or lowest quality) while the value 1.0 represents the least compression (or best quality).\n");
                    return 1;
                }
                break;
            case 'f':
                force = NO;
                break;
            case '?':
                printf("Usage: %s [OPTIONS]\n"
                       " Options:\n"
                       "   -i    Input image path\n"
                       "   -o    Path to put new image (overwrite old by default)\n"
                       "   -w    Width of new image (current width by default)\n"
                       "   -h    Height of new image (current height by default)\n"
                       "   -r    Radius to clip edges by (none by default)\n"
                       "   -s    Scale by factor of, 0 to 1 (none by default)\n"
                       "   -m    Mask to add to (none by default)\n"
                       "   -j    JPEG compression, 0 to 1 (PNG by default)\n"
                       "   -f    Force upscaling images\n", argv[0]);
                return 1;
                break;
        }
    
    if (radius && jpg > -1) printf("Warning: JPEGs don’t have alpha, applying a radius may cause a white or black background\n");
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
        printf(" [-i] Invalid file type\n");
        return 1;
    }
    
    CGSize origSize = image.size;
    CGFloat origScale = image.scale;
    CGFloat deviceScale = UIScreen.mainScreen.scale;
    
    CGFloat origW = origSize.width * origScale;
    CGFloat origH = origSize.height * origScale;
    CGFloat cSizeW = ((sizeW ? sizeW : origW)/deviceScale) * scale;
    CGFloat cSizeH = ((sizeH ? sizeH : origH)/deviceScale) * scale;
    
    if (force) {
        BOOL badSize = NO;
        if (sizeW > origW) {
            printf(" [-w] Invalid width of %ld, original is only %ld\n", lroundf(sizeW), lroundf(origW));
            badSize = YES;
        }
        if (sizeH > origH) {
            printf(" [-h] Invalid height of %ld, original is only %ld\n", lroundf(sizeH), lroundf(origH));
            badSize = YES;
        }
        if (scale > 1) {
            printf(" [-s] To shrink images, use a scale 0 to 1\n");
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
    
    if (maskPath) {
        UIImage *mask = [[UIImage alloc] initWithContentsOfFile:maskPath];
        if (!mask) {
            printf(" [-m] Invalid file type\n");
            return 1;
        }
        else [mask drawInRect:rect];
    }
    
    [image drawInRect:rect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *imageData;
    if (jpg > -1) imageData = UIImageJPEGRepresentation(newImage, jpg);
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
