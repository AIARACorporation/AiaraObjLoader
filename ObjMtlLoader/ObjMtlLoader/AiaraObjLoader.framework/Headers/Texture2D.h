//
//  Model3D.h
//  ModelViewer
//
//  Created by MJ on 07.16.18.
//  Copyright © 2017 3d4medical. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <GLKit/GLKit.h>

@interface Texture2D : NSObject

@property (nonatomic, readonly) int width;
@property (nonatomic, readonly) int height;
@property (nonatomic, readonly) int channels;
@property (nonatomic, readwrite) int textureID;

@property (nonatomic, readonly) unsigned char* data;

+ (id) initializeWithName:(NSString*)name;
+ (id) initializeWithPath:(NSString*)path;

@end
