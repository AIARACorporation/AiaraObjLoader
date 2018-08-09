//
//  Model3D.mm
//  ModelViewer
//
//  Created by MJ on 07.16.18.
//  Copyright © 2018 3d4medical. All rights reserved.
//

#import "Texture2D.h"
#import <UIKit/UIKit.h>

@interface Texture2D()
- (BOOL)loadImage:(NSString*)filename;
- (BOOL)loadImageWithFilePath:(NSString*)filePath;
@end

@implementation Texture2D

+ (id) initializeWithName:(NSString*)name
{
    Texture2D* texture = [Texture2D alloc];
    [texture initialize:name];
    return texture;
}

+ (id) initializeWithPath:(NSString*)path
{
    Texture2D* texture = [Texture2D alloc];
    [texture initializeWithPath:path];
    return texture;
}

- (void) initialize:(NSString*)fileName
{
    if (NO == [self loadImage:fileName])
    {
        NSLog(@"Failed to load texture image from file %@", fileName);
        return;
    }
}

- (void) initializeWithPath:(NSString *)filePath
{
    if (NO == [self loadImageWithFilePath:filePath])
    {
        NSLog(@"Failed to load texture image from file %@", filePath);
        return;
    }
}

- (void)dealloc
{
}


//------------------------------------------------------------------------------
#pragma mark - Private methods

- (BOOL)loadImage:(NSString*)filename
{
    BOOL ret = YES;
    NSString *extension = [filename pathExtension];
    NSString *fileName = [filename stringByDeletingPathExtension];
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:extension];
    [self setupWithFilePath:path];
    return ret;
}

- (BOOL)loadImageWithFilePath:(NSString *)filePath
{
    BOOL ret = YES;
    [self setupWithFilePath:filePath];
    return ret;
}

- (void)setupWithFilePath:(NSString *)filePath {
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    
    if (!image) {
        NSLog(@"Failed load image at path %@", filePath);
        exit(1);
    }
    
    [self setupWithImage:image];
    [self loadTextureToBuffer];
}

- (void)setupWithImage:(UIImage *)image {
    
    CGImageRef imageRef = [image CGImage];
    _width = (GLsizei)CGImageGetWidth(imageRef);
    _height = (GLsizei)CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSUInteger numberOfComponentsInColor = 4;
    
    // calloc ~ malloc, but calloc is used for arrays with initial 0 value for each element
    _data = (unsigned char *) calloc(self.height * self.width * numberOfComponentsInColor,
                                         sizeof(unsigned char));
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * self.width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(self.data, self.width, self.height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, self.width, self.height), imageRef);
}

- (void)loadTextureToBuffer {
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.width, self.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, self.data);
    glGenerateMipmap(GL_TEXTURE_2D);
    
    // Parameters
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindTexture(GL_TEXTURE_2D, 0);
    free(self.data);
    
    self.textureID = textureID;
}

@end
