//
//  Model3D.mm
//  ModelViewer
//
//  Created by MJ on 07.16.18.
//  Copyright © 2018 3d4medical. All rights reserved.
//

#import "Shader.h"

@interface Shader()
@end

@implementation Shader

+ (GLuint)compileShader:(NSString*)shaderFileName withDefs:(NSString *) defs withType:(GLenum)shaderType {
    NSString* shaderName = [[shaderFileName lastPathComponent] stringByDeletingPathExtension];
    NSString* shaderFileType = [shaderFileName pathExtension];
    
    NSLog(@"debug: shaderName=(%@), shaderFileTYpe=(%@)", shaderName, shaderFileType);
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:shaderFileType];
    NSLog(@"debug: shaderPath=(%@)", shaderPath);
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader (%@): %@", shaderFileName, error.localizedDescription);
        return 0;
    }
    GLuint shaderHandle = glCreateShader(shaderType);
    const char * shaderStringUTF8 = [shaderString UTF8String];
    GLint shaderStringLength = (GLint)[shaderString length];
    
    if (defs == nil) {
        glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    } else {
        const char* finalShader[2] = {[defs UTF8String],shaderStringUTF8};
        GLint finalShaderSizes[2] = {(GLint)[defs length], shaderStringLength};
        glShaderSource(shaderHandle, 2, finalShader, finalShaderSizes);
    }
    
    glCompileShader(shaderHandle);
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"Error compiling shader (%@): %@", shaderFileName, messageString);
        return 0;
    }
    
    return shaderHandle;
}

- (void)initialize
{
    GLuint vertexShader = [Shader compileShader:@"Shader.vertsh" withDefs:nil withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [Shader compileShader:@"Shader.fragsh" withDefs:nil withType:GL_FRAGMENT_SHADER];
    
    if ((vertexShader == 0) || (fragmentShader == 0)) {
        NSLog(@"Error: error compiling shaders");
        return;
    }
    
    GLuint programHandle = glCreateProgram();
    
    if (programHandle == 0) {
        NSLog(@"Error: can't create programe");
        return;
    }
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        return;
    }
    self.shaderProgramID = programHandle;
    if (0 < self.shaderProgramID)
    {
        self.vertexHandle = glGetAttribLocation(self.shaderProgramID, "a_Position");
        self.normalHandle = glGetAttribLocation(self.shaderProgramID, "a_Normal");
        self.textureCoordHandle = glGetAttribLocation(self.shaderProgramID, "a_TexCoord");
        self.texSampler2DHandle  = glGetUniformLocation(self.shaderProgramID,"u_Texture");
        self.mvpMatrixHandle = glGetUniformLocation(self.shaderProgramID, "u_ModelViewProjection");
        self.mvMatrixHandle = glGetUniformLocation(self.shaderProgramID,"u_ModelView");
        self.materialHandle = glGetUniformLocation(self.shaderProgramID,"u_MaterialParameters");
        self.lightingHandle = glGetUniformLocation(self.shaderProgramID,"u_LightingParameters");
        self.transparencyHandle = glGetUniformLocation(self.shaderProgramID, "u_transparency");
    }
}

@end
