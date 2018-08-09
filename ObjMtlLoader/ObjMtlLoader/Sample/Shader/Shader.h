//
//  Model3D.h
//  ModelViewer
//
//  Created by MJ on 07.16.18.
//  Copyright © 2017 3d4medical. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>

@interface Shader : NSObject

@property (nonatomic) GLuint shaderProgramID;
@property (nonatomic) GLint vertexHandle;
@property (nonatomic) GLint normalHandle;
@property (nonatomic) GLint textureCoordHandle;
@property (nonatomic) GLint mvpMatrixHandle;
@property (nonatomic) GLint mvMatrixHandle;
@property (nonatomic) GLint lightingHandle;
@property (nonatomic) GLint materialHandle;
@property (nonatomic) GLint texSampler2DHandle;
@property (nonatomic) GLint transparencyHandle;

- (void)initialize;

@end
